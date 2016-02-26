//
//  GDGEntityManager.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//  Copyright © 2016 Involves. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDGEntity.h"

@class GDGEntitySettings;
@class GDGHasOneRelation, GDGHasManyRelation, GDGBelongsToRelation;
@class GDGEntityQuery;
@class GDGValueAdapter;
@class GDGTableSource;
@class CIRDatabase;
@class GDGColumn;

@interface GDGEntityManager : NSObject <GDGEntityFillDelegate>

@property(weak, readonly, nonatomic) GDGEntitySettings *settings;
@property(weak, readonly, nonatomic) GDGEntity *entity;

+ (GDGTableSource *)tableSourceWithName:(NSString *)tableName;

+ (void)executeOnDatabaseReady:(void (^)())callback;

+ (void)setDatabase:(CIRDatabase *)database;

+ (CIRDatabase *)database;

- (instancetype)initWithEntity:(GDGEntity *)entity;

- (instancetype)initWithClass:(Class)entityClass tableName:(NSString *)tableName;

- (GDGEntityQuery *)query;

- (NSArray<__kindof GDGEntity *> *)select:(GDGEntityQuery *)query;

- (__kindof GDGEntity *)find:(GDGEntityQuery *)query;

- (BOOL)save;

- (BOOL)drop;

- (void)fillProperties:(NSArray<NSString *> *)properties;

- (void)fillEntities:(NSArray<GDGEntity *> *)entities withProperties:(NSArray<NSString *> *)properties;

- (NSString *)columnNameForProperty:(NSString *)propertyName;

- (NSString *)propertyNameForColumn:(NSString *)columnName;

- (GDGColumn *)columnForProperty:(NSString *)propertyName;

- (void)addValueAdapterForPropertyNamed:(NSString *)propertyName fromDatabaseHandler:(id (^)(id))fromDatabaseHandler toDatabaseHandler:(id (^)(id))toDatabaseHandler;

- (void)addValueAdapterForPropertyNamed:(NSString *)propertyName valueAdapter:(NSValueTransformer *)valueAdapter;

- (void)hasMany:(NSString *)relationName config:(void (^)(GDGHasManyRelation *))tap;

- (void)hasOne:(NSString *)relationName config:(void (^)(GDGHasOneRelation *))tap;

- (void)belongsTo:(NSString *)relationName config:(void (^)(GDGBelongsToRelation *))tap;

@end
