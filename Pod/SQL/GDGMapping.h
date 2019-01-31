//
//  GDGMapping.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/5/16.
//

@class GDGHasOneRelation;
@class GDGHasManyRelation;
@class GDGBelongsToRelation;
@class GDGColumn;
@class GDGRecord;
@class GDGRelation;
@class GDGTable;
@class GDGHasManyThroughRelation;
@class GDGValueTransformer;

@interface GDGMapping : NSObject

@property (assign, nonatomic) Class entityClass;
@property (readonly, nonatomic, nonnull) GDGTable *table;
@property (strong, nonatomic, nonnull) NSDictionary <NSString *, id> *fromToDictionary;
@property (strong, nonatomic, nonnull) NSDictionary <NSString *, GDGValueTransformer *> *valueTransformerDictionary;

- (nonnull instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *__nonnull)fromToDictionary
                              from:(GDGTable *__nonnull)table
                                to:(Class)class;

#pragma mark - Relation mapping

- (void)hasOne:(NSString *__nonnull)relationName tap:(void (^__nullable)(GDGHasOneRelation *__nonnull))tap;

- (void)hasMany:(NSString *__nonnull)relationName tap:(void (^__nullable)(GDGHasManyRelation *__nonnull))tap;

- (void)hasMany:(NSString *__nonnull)relationName through:(GDGTable *)table tap:(void (^__nullable)(GDGHasManyThroughRelation *__nonnull))tap;

- (void)belongsTo:(NSString *__nonnull)relationName tap:(void (^__nullable)(GDGBelongsToRelation *__nonnull))tap;

#pragma mark - Value transforming

- (void)addValueTransformerMappings:(NSDictionary *__nonnull)dictionary;

- (void)setValueTransformer:(NSValueTransformer *__nonnull)transformer
              forProperties:(NSArray *__nonnull)propertyNames;

#pragma mark - Acessing

- (nonnull NSArray *)mappedValuesFromProperties:(NSArray <NSString *> * __nonnull)properties;

- (nonnull NSString *)columnNameForProperty:(NSString * __nonnull)propertyName;

- (nullable NSString *)propertyFromColumnName:(NSString * __nonnull)columnName;

- (nullable NSString *)propertyFromMappedValue:(id __nonnull)mappedValue;

- (nullable GDGColumn *)columnForProperty:(NSString * __nonnull)propertyName;

- (nullable GDGRelation *)relationForProperty:(NSString * __nonnull)relationName;

- (nullable id)mappedValueFromProperty:(NSString * __nonnull)propertyName;

- (nullable id)objectForKeyedSubscript:(NSString * __nonnull)key;

@end
