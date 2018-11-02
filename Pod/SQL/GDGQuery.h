//
//  SQLQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

@protocol SQLSource;
@protocol GDGFilter;
@class SQLTableSource;
@class SQLJoin;
@class GDGColumn;
@class GDGCondition;

typedef NS_ENUM(uint8_t, GDGQueryOrder) {
	GDGQueryOrderAsc,
	GDGQueryOrderDesc
};

@interface GDGQuery: NSObject

@property (readonly, nonatomic, nonnull) id <GDGSource> source;
@property (readonly, nonatomic) BOOL distinct;
@property (readonly, nonatomic) NSUInteger limit;
@property (readonly, nonatomic, nonnull) NSArray<NSString *> *projection;
@property (readonly, nonatomic, nonnull) NSArray<SQLJoin *> *joins;
@property (readonly, nonatomic, nonnull) NSArray<NSString *> *orderList;
@property (readonly, nonatomic, nonnull) NSArray <NSString *> *groups;
@property (readonly, nonatomic, nonnull) GDGCondition *whereCondition;
@property (readonly, nonatomic, nonnull) GDGCondition *havingCondition;

- (instancetype __nonnull)initWithSQLSource:(id <GDGSource>)source;

@end

@interface GDGMutableQuery: GDGQuery

@property (readwrite, nonatomic) BOOL distinct;
@property (readwrite, nonatomic) NSUInteger limit;

- (void)select:(NSArray <NSString *> * __nonnull)projection;
- (BOOL)joining:(SQLJoin * __nonnull)join error:(NSError *__nullable*)error;
- (BOOL)filteredBy:(id <GDGFilter> __nonnull)filter error:(NSError *__nullable*)error;
- (void)addCondition:(GDGCondition *__nonnull)condition;
- (void)groupBy:(GDGColumn *__nonnull)column;
- (void)addGroupCondition:(GDGCondition *__nonnull)condition;
- (void)orderBy:(GDGColumn *__nonnull)column order:(GDGQueryOrder)order;
- (void)clearProjection;

@end