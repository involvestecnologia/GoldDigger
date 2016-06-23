//
//  GDGEntityMap.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/21/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGEntityMap.h"

@interface GDGEntityMap ()

@property (strong, nonatomic) NSMapTable *reverseFromToTable;

@end

@implementation GDGEntityMap

+ (instancetype)mapWithDictionary:(NSDictionary *)fromToDictionary
                             from:(id <GDGSource>)source
							   to:(Class)entityClass
{
	GDGEntityMap *settings = [[self alloc] init];
	settings->_source = source;
	settings->_entityClass = entityClass;
	settings.fromToDictionary = fromToDictionary;

	return settings;
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

#pragma mark - Place

- (void)addFromToMappings:(NSDictionary *)dictionary
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:_fromToDictionary];
	[mutableDictionary addEntriesFromDictionary:dictionary];

	self.fromToDictionary = [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

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

#pragma mark - Retrieve

- (NSArray *)mappedValuesFromProperties:(NSArray <NSString *> *)properties
{
	return [properties map:^id(NSString *propertyName) {
		return [self mappedValueFromProperty:propertyName];
	}];
}

- (id)mappedValueFromProperty:(NSString *)propertyName
{
	return _fromToDictionary[propertyName];
}

- (NSString *)propertyFromMappedValue:(id)mappedValue
{
	return [_reverseFromToTable objectForKey:mappedValue];
}

#pragma mark - Subscripting

- (id)objectForKeyedSubscript:(NSString *)key
{
	return [self mappedValueFromProperty:key];
}

@end
