//
//  GDGMapping.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/5/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <MapKit/MapKit.h>
#import "GDGRelation.h"
#import "GDGMapping.h"
#import "GDGColumn.h"
#import "GDGBelongsToRelation.h"
#import "GDGHasManyRelation.h"
#import "GDGHasOneRelation.h"
#import "GDGEntity.h"
#import "GDGRecord_Package.h"
#import "GDGHasManyThroughRelation.h"
#import "GDGTable.h"
#import "GDGValueTransformer.h"

@interface GDGMapping ()

@property (strong, nonatomic) NSMapTable *reverseFromToTable;

@end

@implementation GDGMapping

@synthesize entityClass = _entityClass;

+ (instancetype)mappingWithDictionary:(NSDictionary *)fromToDictionary from:(GDGTable *)table to:(Class)class
{
	return [[self alloc] initWithDictionary:fromToDictionary from:table to:class];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *__nonnull)fromToDictionary
                              from:(GDGTable *__nonnull)table
                                to:(Class)class
{
	NSArray *columns = table.columns;
	NSMutableDictionary *mutableFromTo = [NSMutableDictionary dictionaryWithCapacity:columns.count];

	for (GDGColumn *column in columns)
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

	if (self = [super init])
	{
		_entityClass = class;
		_table = table;

		self.fromToDictionary = [NSDictionary dictionaryWithDictionary:mutableFromTo];
	}

	return self;
}

- (void)setFromToDictionary:(NSDictionary *)fromToDictionary
{
	_fromToDictionary = fromToDictionary ? : @{};

	NSMapTable *reverseFromToTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory
	                                                           valueOptions:NSPointerFunctionsWeakMemory
	                                                               capacity:fromToDictionary.count];

	for (id key in fromToDictionary)
		[reverseFromToTable setObject:key forKey:fromToDictionary[key]];

	_reverseFromToTable = reverseFromToTable;
}

#pragma mark - Relation mapping

- (void)hasOne:(NSString *)relationName tap:(void (^)(GDGHasOneRelation *))tap
{
	GDGHasOneRelation *relation = [[GDGHasOneRelation alloc] initWithName:relationName mapping:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)hasMany:(NSString *)relationName tap:(void (^)(GDGHasManyRelation *))tap
{
	GDGHasManyRelation *relation = [[GDGHasManyRelation alloc] initWithName:relationName mapping:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)hasMany:(NSString *)relationName through:(GDGTable *)table tap:(void (^)(GDGHasManyThroughRelation *))tap
{
	GDGHasManyThroughRelation *relation = [[GDGHasManyThroughRelation alloc] initWithName:relationName mapping:self];
	relation.relationSource = table;

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)belongsTo:(NSString *)relationName tap:(void (^)(GDGBelongsToRelation *))tap
{
	GDGBelongsToRelation *relation = [[GDGBelongsToRelation alloc] initWithName:relationName mapping:self];

	[self synthesizeRelation:relation];

	tap(relation);
}

- (void)synthesizeRelation:(GDGRelation *)relation
{
	[self addFromToMappings:@{ relation.name : relation }];

	[self->_entityClass addAfterSetHandler:^(GDGRecord *entity, NSString *string) {
		// TODO handle relation after setting
	} forProperty:relation.name];
}

#pragma mark - Value transforming

- (void)addValueTransformerMappings:(NSDictionary *)dictionary
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:_valueTransformerDictionary];
	[mutableDictionary addEntriesFromDictionary:dictionary];

	self.valueTransformerDictionary = [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

- (void)setValueTransformer:(NSValueTransformer *)transformer forProperties:(NSArray *)propertyNames
{
	NSMutableDictionary *transformerMappings = [NSMutableDictionary dictionaryWithCapacity:propertyNames.count];

	for (NSString *propertyName in propertyNames)
		transformerMappings[propertyName] = transformer;

	[self addValueTransformerMappings:transformerMappings];
}

- (void)addFromToMappings:(NSDictionary *)dictionary
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:_fromToDictionary];
	[mutableDictionary addEntriesFromDictionary:dictionary];

	self.fromToDictionary = [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

#pragma mark - Accessing

- (NSArray *)mappedValuesFromProperties:(NSArray <NSString *> *)properties
{
	return [properties map:^id(NSString *propertyName) {
		return [self mappedValueFromProperty:propertyName];
	}];
}

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

- (NSString *)propertyFromMappedValue:(id)mappedValue
{
	if ([mappedValue isKindOfClass:[NSString class]])
		mappedValue = [self.table.columns find:^BOOL(GDGColumn *column) {
			return [column.name isEqualToString:mappedValue];
		}];

	return [_reverseFromToTable objectForKey:mappedValue];
}

- (GDGColumn *)columnForProperty:(NSString *)propertyName
{
	return self.fromToDictionary[propertyName];
}

- (GDGRelation *)relationForProperty:(NSString *)relationName
{
	return self.fromToDictionary[relationName];
}

- (id)mappedValueFromProperty:(NSString *)propertyName
{
	return _fromToDictionary[propertyName];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
	return [self mappedValueFromProperty:key];
}

@end
