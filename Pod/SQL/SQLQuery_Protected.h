//
//  SQLQuery_Protected.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/8/16.
//

#import "SQLQuery.h"

@class SQLJoin;

@interface SQLQuery ()

@property (strong, nonatomic) NSMutableArray<NSString *> *mutableProjection;
@property (strong, nonatomic) NSMutableArray<NSString *> *mutableOrderList;
@property (strong, nonatomic) NSMutableArray<SQLJoin *> *mutableJoins;
@property (readwrite, nonatomic) int limitValue;
@property (readwrite, nonatomic) GDGCondition *whereCondition;

- (void)select:(NSArray <NSString *> *)projection;

- (void)join:(SQLJoin *)join;

- (void)where:(void (^)(GDGCondition *))handler;

- (void)asc:(NSString *)field;

- (void)desc:(NSString *)field;

- (void)limit:(int)limit;

- (void)filter:(NSArray <id <GDGFilter>> *)filters;

@end
