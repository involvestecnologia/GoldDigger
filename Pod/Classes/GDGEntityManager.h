//
//  GDGEntityManager.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import <Foundation/Foundation.h>

#import "GDGEntity.h"

@class GDGEntitySettings;
@class GDGHasOneRelation, GDGHasManyRelation, GDGBelongsToRelation;
@class GDGEntityQuery;
@class GDGTableSource;
@class CIRDatabase;
@class GDGColumn;
@class GDGRelation;

@interface GDGEntityManager : NSObject <GDGEntityFillDelegate>

@property (weak, readonly, nonatomic) GDGEntitySettings *settings;
@property (weak, readonly, nonatomic) GDGEntity *entity;

- (instancetype)initWithEntity:(GDGEntity *)entity;

- (instancetype)initWithClass:(Class)entityClass tableName:(NSString *)tableName;

- (GDGEntityQuery *)query;

- (NSArray<__kindof GDGEntity *> *)select:(GDGEntityQuery *)query;

- (__kindof GDGEntity *)find:(GDGEntityQuery *)query;

- (BOOL)save;

- (BOOL)drop;

- (void)hasMany:(NSString *)relationName config:(void (^)(GDGHasManyRelation *))tap;

- (void)hasOne:(NSString *)relationName config:(void (^)(GDGHasOneRelation *))tap;

- (void)belongsTo:(NSString *)relationName config:(void (^)(GDGBelongsToRelation *))tap;

- (void)fillProperties:(NSArray<NSString *> *)properties;

- (void)fillEntities:(NSArray<GDGEntity *> *)entities withProperties:(NSArray<NSString *> *)properties;

- (NSString *)columnNameForProperty:(NSString *)propertyName;

- (NSString *)propertyNameForColumn:(NSString *)columnName;

- (GDGColumn *)columnForProperty:(NSString *)propertyName;

- (void)addValueTransformer:(__kindof NSValueTransformer *)transformer forProperties:(NSArray<NSString *> *)properties;

- (id)objectForKeyedSubscript:(NSString *)idx;

- (GDGRelation *)relationNamed:(NSString *)relationName;

@end
