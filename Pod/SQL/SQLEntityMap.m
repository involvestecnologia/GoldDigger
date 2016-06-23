//
//  SQLEntityMap.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/5/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <GoldDigger/GDGEntity.h>
#import "GDGRelation.h"
#import "SQLEntityMap.h"
#import "SQLTableSource.h"
#import "GDGColumn.h"
#import "GDGBelongsToRelation.h"
#import "GDGHasManyRelation.h"
#import "SQLQuery.h"
#import "GDGHasOneRelation.h"
#import "SQLEntityQuery.h"
#import "GDGEntity_Package.h"
#import "GDGHasManyThroughRelation.h"

@implementation SQLEntityMap

@synthesize entityClass = _entityClass;

+ (instancetype)mapWithDictionary:(NSDictionary *)fromToDictionary from:(SQLTableSource *)source to:(Class)class
{
	NSMutableDictionary *mutableFromTo = [NSMutableDictionary dictionaryWithCapacity:source.columns.count];
	for (GDGColumn *column in source.columns)
		mutableFromTo[column.name] = column;

	for (NSString *key in fromToDictionary.keyEnumerator)
	{
		id value = mutableFromTo[fromToDictionary[key]];

		if ([value isKindOfClass:[GDGColumn class]])
		{
			mutableFromTo[key] = value;

			[mutableFromTo removeObjectForKey:[value name]];
		}
	}

	SQLEntityMap *map = [[self alloc] init];
	map.entityClass = class;
	map.source = source;
	map.fromToDictionary = [NSDictionary dictionaryWithDictionary:mutableFromTo];

	return map;
}

- (NSString *)propertyFromMappedValue:(id)mappedValue
{
	if ([mappedValue isKindOfClass:[NSString class]])
		mappedValue = [self.source.columns find:^BOOL(GDGColumn *column) {
			return [column.name isEqualToString:mappedValue];
		}];

	return [super propertyFromMappedValue:mappedValue];
}

#pragma mark - Quering

- (SQLTableSource *)table
{
	SQLTableSource *table = self.source;
	return [table copy];
}

- (SQLEntityQuery *)query
{
	return [[SQLEntityQuery alloc] initWithEntityMap:self].select(@[@"id"]);
}

#pragma mark - Relation mapping

- (void)hasOne:(NSString *)relationName config:(void (^)(GDGHasOneRelation *))tap
{
	GDGHasOneRelation *relation = [[GDGHasOneRelation alloc] initWithName:relationName map:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)hasMany:(NSString *)relationName config:(void (^)(GDGHasManyRelation *))tap
{
	GDGHasManyRelation *relation = [[GDGHasManyRelation alloc] initWithName:relationName map:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)hasMany:(NSString *)relationName through:(SQLTableSource *)table config:(void (^)(GDGHasManyThroughRelation *))tap
{
	GDGHasManyThroughRelation *relation = [[GDGHasManyThroughRelation alloc] initWithName:relationName map:self];
	relation.relationSource = table;

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)belongsTo:(NSString *)relationName config:(void (^)(GDGBelongsToRelation *))tap
{
	GDGBelongsToRelation *relation = [[GDGBelongsToRelation alloc] initWithName:relationName map:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)synthesizeRelation:(GDGRelation *)relation
{
	[self addFromToMappings:@{relation.name : relation}];
	[self->_entityClass addAfterSetHandler:^(GDGEntity *entity, NSString *string) {
		// TODO handle relation after setting
	} forProperty:relation.name];
}

#pragma mark - Convenience

- (NSString *)columnNameForProperty:(NSString *)propertyName
{
	return [[self columnForProperty:propertyName] name];
}

- (NSString *)propertyFromColumnName:(NSString *)columnName
{
	NSString *propertyName = nil;

	for (NSString *key in self.fromToDictionary.keyEnumerator)
		if ([[self.fromToDictionary[key] name] isEqualToString:columnName])
		{
			propertyName = key;
			break;
		}

	return propertyName;
}

- (GDGColumn *)columnForProperty:(NSString *)propertyName
{
	return self.fromToDictionary[propertyName];
}

- (GDGRelation *)relationForProperty:(NSString *)relationName
{
	return self.fromToDictionary[relationName];
}

@end
