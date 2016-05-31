//
//  GDGEntity+SQL.h
//  GoldDigger
//
//  Created by Felipe Lobo on 5/4/16.
//

#import "GDGEntity.h"

@class SQLEntityMap;
@class SQLEntityQuery;

@interface GDGEntity (SQL)

@property (strong, nonatomic) NSMutableArray *filledProperties;
@property (strong, nonatomic) NSMutableArray *changedProperties;

+ (SQLEntityMap *)db;

+ (instancetype)entityFromQuery:(SQLEntityQuery *)query;

+ (NSArray <__kindof GDGEntity *> *)entitiesFromQuery:(SQLEntityQuery *)query;

+ (void)autoFillProperties:(NSArray <NSString *> *)propertyNames;

+ (void)fill:(NSArray <GDGEntity *> *)entities withProperties:(NSArray *)properties;

- (void)fillProperties:(NSArray *)properties;

- (BOOL)save:(NSError *)error;

- (BOOL)delete:(NSError *)error;

@end
