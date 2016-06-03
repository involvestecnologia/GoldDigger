//
//  SQLQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGQuery.h"

@protocol SQLSource;
@class SQLTableSource;
@class SQLJoin;
@class GDGCondition;

@interface SQLQuery : GDGQuery

@property (readonly, nonatomic) NSArray<NSString *> *projection;
@property (readonly, nonatomic) NSArray<SQLJoin *> *joins;
@property (readonly, nonatomic) NSArray<NSString *> *orderList;
@property (readonly, nonatomic) GDGCondition *whereCondition;
@property (readonly, nonatomic) id <SQLSource> source;
@property (assign, readonly, nonatomic, getter=isDistinct) BOOL distinct;
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^select)(NSArray <NSString *> *);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^from)(id <SQLSource>);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^join)(SQLJoin *);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^filter)(NSArray <id <GDGFilter>> *);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^where)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^asc)(NSString *);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^desc)(NSString *);
@property (copy, readonly, nonatomic) __kindof SQLQuery *(^limit)(int);

+ (instancetype)query;

- (instancetype)initWithSQLSource:(id <SQLSource>)source;

- (instancetype)distinct;

- (NSString *)visit;

- (NSArray *)pluck;

- (NSDictionary *)args;

- (NSArray *)raw;

- (NSUInteger)count;

- (instancetype)copy;

@end