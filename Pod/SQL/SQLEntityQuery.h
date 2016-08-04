//
//  SQLEntityQuery.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/8/16.
//

#import "SQLQuery.h"

@class GDGEntity;
@class SQLEntityMap;

@interface SQLEntityQuery : SQLQuery

@property (readonly, nonatomic) SQLEntityMap *map;
@property (readonly, nonatomic) NSDictionary <NSString *, NSArray *> *pulledRelations;
@property (copy, readonly, nonatomic) SQLEntityQuery *(^pull)(NSDictionary <NSString *, NSArray *> *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^withId)(id);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^select)(NSArray <NSString *> *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^join)(SQLJoin *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^filter)(NSArray <id <GDGFilter>> *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^where)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) SQLEntityQuery *(^asc)(NSString *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^desc)(NSString *);
@property (copy, readonly, nonatomic) SQLEntityQuery *(^limit)(int);

- (instancetype)initWithEntityMap:(SQLEntityMap *)map;

- (NSArray<__kindof GDGEntity *> *)array;

- (__kindof GDGEntity *)object;

- (instancetype)copy;

@end
