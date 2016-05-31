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
#import "GDGEntity+SQL.h"
#import "SQLEntityQuery.h"

@implementation SQLEntityMap

@synthesize entityClass = _entityClass;

+ (instancetype)mapWithDictionary:(NSDictionary *)fromToDictionary from:(id <SQLSource>)source to:(Class)class
{
	SQLTableSource *table = (SQLTableSource *) source;

	NSMutableDictionary *mutableFromTo = [NSMutableDictionary dictionaryWithCapacity:table.columns.count];
	for (GDGColumn *column in table.columns)
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
	return self.source;
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
//		[relation]
	} forProperty:relation.name];
}

#pragma mark - Convenience

- (NSString *)columnNameForProperty:(NSString *)propertyName
{
	return [[self columnForProperty:propertyName] name];
}

- (NSString *)propertyFromColumnName:(NSString *)columnName
{
	__block NSString *propertyName = nil;

	[self.fromToDictionary each:^(id key, id value) {
		if ([[value name] isEqualToString:columnName])
			propertyName = key;
	}];

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
