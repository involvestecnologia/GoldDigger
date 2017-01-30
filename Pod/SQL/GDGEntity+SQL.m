//
//  GDGEntity+SQL.m
//  GoldDigger
//
//  Created by Felipe Lobo on 5/4/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <objc/runtime.h>
#import "GDGEntity+SQL.h"
#import "SQLEntityQuery.h"
#import "SQLEntityMap.h"
#import "SQLTableSource.h"
#import "GDGColumn.h"
#import "GDGRelation.h"
#import "GDGCondition+Entity.h"
#import "GDGEntity_Package.h"
#import "GDGHasManyThroughRelation.h"

@implementation GDGEntity (SQL)

+ (SQLEntityMap *)db
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Required"
	                               reason:@"[GDGEntity+SQL db] throws that 'db' method should be overrided before using any of the categories methods"
	                             userInfo:nil];
}

+ (void)autoFillProperties:(NSArray <NSString *> *)propertyNames
{
	void (^getHandler)(GDGEntity *, NSString *) = ^(GDGEntity *entity, NSString *propertyName) {
		if ([entity.id compare:@0] == NSOrderedDescending && ![entity.filledProperties containsObject:propertyName] && ![entity.changedProperties containsObject:propertyName])
		{
			[entity fillProperties:@[propertyName]];
			[entity.filledProperties addObject:propertyName];
		}
	};

	void (^setHandler)(GDGEntity *, NSString *) = ^(GDGEntity *entity, NSString *propertyName) {
		if (![entity.filledProperties containsObject:propertyName])
			[entity.filledProperties addObject:propertyName];

		if (![entity.changedProperties containsObject:propertyName])
			[entity.changedProperties addObject:propertyName];
	};

	void (^afterSetHandler)(GDGEntity *, NSString *) = ^(GDGEntity *entity, NSString *propertyName) {
		[[entity.class db][propertyName] hasBeenSetOnEntity:entity];
	};

	for (NSString *propertyName in propertyNames)
	{
		[self addBeforeGetHandler:getHandler forProperty:propertyName];
		[self addBeforeSetHandler:setHandler forProperty:propertyName];

		if ([[self db][propertyName] isKindOfClass:[GDGRelation class]])
			[self addAfterSetHandler:afterSetHandler forProperty:propertyName];
	}
}

#pragma mark - Fill

+ (void)fill:(NSArray <GDGEntity *> *)entities withProperties:(NSArray *)properties
{
	NSArray <NSNumber *> *ids = [[entities map:^id(GDGEntity *object) {
		return object.id;
	}] sort];

	NSArray *sortedEntities = [entities sortBy:@"id"];

	NSMutableArray<NSString *> *projection = [[NSMutableArray alloc] initWithCapacity:properties.count];
	NSMutableArray<NSString *> *relations = [NSMutableArray array];

	for (id property in properties)
	{
		if ([property isKindOfClass:[NSDictionary class]])
			[relations addObject:property];
		else
		{
			id entry = self.db.fromToDictionary[property];

			if ([entry isKindOfClass:[GDGRelation class]])
				[relations addObject:property];
			else
				[projection addObject:property];
		}
	}

	if (projection.count > 0)
	{

		SQLEntityQuery *query = self.db.query.clearProjection
				.select([NSArray arrayWithArray:projection])
				.where(^(GDGCondition *builder) {
					builder.prop(@"id").in(ids);
				}).asc(@"id");

		NSArray <NSDictionary *> *entries = [self.db.table eval:query];

		if (entries.count == 0)
			@throw [NSException exceptionWithName:@"Query Evaluation Inconsistency"
			                               reason:@"[GDGEntity+SQL -fill:withProperties:] throws that properties query "
					                               @"evaluation should never get nil evalutation. You may have mapped "
					                               @"something that is not a property or something that is not a column."
			                             userInfo:nil];

		for (unsigned int i = 0; i < ids.count; ++i)
		{
			NSDictionary *entry = entries[i];
			GDGEntity *entity = sortedEntities[i];

			for (NSString *key in entry.keyEnumerator)
			{
				NSString *propertyName = [self.db propertyFromColumnName:key];

				NSValueTransformer *transformer = self.db.valueTransformerDictionary[propertyName];
				id value = transformer ? [transformer transformedValue:entry[key]] : entry[key];

				[entity setValue:value forKeyPath:propertyName];
				[entity.changedProperties removeObject:propertyName];
			}
		}
	}

	NSArray *relationProperties = nil;
	NSString *relationName = nil;

	for (id rel in relations)
	{
		if ([rel isKindOfClass:[NSDictionary class]])
		{
			relationName = [(NSDictionary *) rel allKeys].lastObject;
			relationProperties = rel[relationName];
		}
		else
		{
			relationName = rel;
			relationProperties = nil;
		}

		[self.db.fromToDictionary[relationName] fill:entities selecting:relationProperties];
	}
}

- (void)fillProperties:(NSArray *)properties
{
	[self.class fill:@[self] withProperties:properties];
}

#pragma mark - Materialize

+ (instancetype)entityFromQuery:(SQLEntityQuery *)query
{
	return [self entitiesFromQuery:query.copy.limit(1)].lastObject;
}

+ (NSArray <__kindof GDGEntity *> *)entitiesFromQuery:(SQLEntityQuery *)query
{
	NSArray <NSDictionary *> *evaluatedEntries = [self.db.table eval:query];
	NSMutableArray <GDGEntity *> *mutableEntities = [NSMutableArray array];

	GDGEntity *entity = nil;

	for (NSDictionary *entry in evaluatedEntries)
	{
		entity = [self entity];

		for (NSString *key in entry.keyEnumerator)
		{
			NSString *propertyName = [self.db propertyFromColumnName:key];

			NSValueTransformer *transformer = self.db.valueTransformerDictionary[propertyName];
			id value = transformer ? [transformer transformedValue:entry[key]] : entry[key];

			[entity setValue:value forKeyPath:propertyName];
			[entity.changedProperties removeObject:propertyName];
		}

		[mutableEntities addObject:entity];
	}

	NSDictionary *pulledRelations = query.pulledRelations;
	for (NSString *key in pulledRelations.keyEnumerator)
		[self.db.fromToDictionary[key] fill:mutableEntities selecting:pulledRelations[key]];

	return [NSArray arrayWithArray:mutableEntities];
}

#pragma mark - Persistence

- (BOOL)save:(NSError **)error
{
	SQLEntityMap *db = [self class].db;

	BOOL saved, exists = db.query.withId(self.id).count > 0;

	if (exists && self.changedProperties.count == 0)
		return YES;

	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:self.changedProperties.count + 1];
	NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:self.changedProperties.count];

	GDGColumn *primaryKey = db.fromToDictionary[@"id"];
	NSMutableArray *relations = @[].mutableCopy;

	if (self.id != nil)
	{
		[values addObject:self.id];
		[columns addObject:@"id"];
	}

	for (NSString *key in db.fromToDictionary.keyEnumerator)
	{
		if (![self.changedProperties containsObject:key])
			continue;

		id mapped = db.fromToDictionary[key];

		if ([mapped isKindOfClass:[GDGRelation class]])
		{
			[relations addObject:mapped];
			continue;
		}

		NSString *propertyName = key;

		[columns addObject:[db columnNameForProperty:propertyName]];

		NSValueTransformer *transformer = db.valueTransformerDictionary[propertyName];
		id value = transformer ? [transformer reverseTransformedValue:[self valueForKeyPath:propertyName]]
				: [self valueForKeyPath:propertyName];

		[values addObject:value ?: [NSNull null]];
	}

	if (exists)
	{
		[values addObject:self.id];
		saved = [db.table update:columns params:values error:error];
	}
	else
		saved = [db.table insert:columns params:values error:error];

	if (!exists && primaryKey.isAutoIncrement)
		self.id = [db.table lastInsertedId];

	for (GDGRelation *relation in relations)
		[relation save:self error:NULL];

	if (saved)
		[self.changedProperties removeAllObjects];

	return saved;
}

- (BOOL)delete:(NSError **)error
{
	return [[self class].db.table delete:self.id error:error];
}

#pragma mark - Props

- (NSMutableArray *)filledProperties
{
	NSMutableArray *filledProperties = objc_getAssociatedObject(self, _cmd);
	if (!filledProperties)
	{
		filledProperties = [NSMutableArray array];
		objc_setAssociatedObject(self, _cmd, filledProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return filledProperties;
}

- (NSMutableArray *)changedProperties
{
	NSMutableArray *changedProperties = objc_getAssociatedObject(self, _cmd);
	if (!changedProperties)
	{
		changedProperties = [NSMutableArray array];
		objc_setAssociatedObject(self, _cmd, changedProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return changedProperties;
}

@end
