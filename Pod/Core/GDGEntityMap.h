//
//  GDGEntityMap.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/21/16.
//

#import <Foundation/Foundation.h>
#import "GDGSource.h"

@interface GDGEntityMap : NSObject

@property (assign, nonatomic) Class entityClass;
@property (strong, nonatomic) id <GDGSource> source;
@property (strong, nonatomic) NSDictionary *fromToDictionary;
@property (strong, nonatomic) NSDictionary *valueTransformerDictionary;

+ (instancetype)mapWithDictionary:(NSDictionary *)fromToDictionary
                             from:(id <GDGSource>)source
							   to:(Class)entityClass;

- (void)addFromToMappings:(NSDictionary *)dictionary;

- (void)addValueTransformerMappings:(NSDictionary *)dictionary;

- (void)setValueTransformer:(NSValueTransformer *)transformer forProperties:(NSArray *)propertyNames;

- (NSArray *)mappedValuesFromProperties:(NSArray <NSString *> *)properties;

- (id)mappedValueFromProperty:(NSString *)propertyName;

- (NSString *)propertyFromMappedValue:(id)mappedValue;

- (id)objectForKeyedSubscript:(NSString *)key;

@end
