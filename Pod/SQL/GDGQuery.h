//
//  GDGQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

@protocol GDGSource;
@protocol GDGFilter;
@class GDGColumn;
@class GDGCondition;
@class GDGJoin;
@class GDGMapping;
@class GDGTable;

typedef NS_ENUM(uint8_t, GDGQueryOrder) {
	GDGQueryOrderAsc,
	GDGQueryOrderDesc
};

@interface GDGQuery: NSObject

@property (readonly, nonatomic, nullable) GDGMapping *mapping;
@property (readonly, nonatomic, nonnull) id <GDGSource> source;
@property (readonly, nonatomic) BOOL distinct;
@property (readonly, nonatomic) NSUInteger limit;
@property (readonly, nonatomic, nonnull) NSArray<NSString *> *projection;
@property (readonly, nonatomic, nonnull) NSArray<GDGJoin *> *joins;
@property (readonly, nonatomic, nonnull) NSArray<NSString *> *orderList;
@property (readonly, nonatomic, nonnull) NSArray <NSString *> *groups;
@property (readonly, nonatomic, nonnull) NSDictionary <NSString *, NSArray *> *pulledRelations;
@property (readonly, nonatomic, nonnull) GDGCondition *whereCondition;
@property (readonly, nonatomic, nonnull) GDGCondition *havingCondition;

- (nonnull instancetype)initWithSource:(id <GDGSource>)source;

- (nonnull instancetype)initWithMapping:(GDGMapping *__nonnull)map;

@end

@interface GDGMutableQuery: GDGQuery

@property (readwrite, nonatomic) BOOL distinct;
@property (readwrite, nonatomic) NSUInteger limit;

- (void)select:(NSArray <NSString *> * __nonnull)projection;

- (BOOL)join(GDGJoin * __nonnull)join error:(NSError **__nullable)error;

- (BOOL)pull:(NSDictionary <NSString *, NSArray *> *__nonnull)relations error:(NSError **__nullable)error;

- (BOOL)filteredBy:(id <GDGFilter> __nonnull)filter error:(NSError **__nullable)error;

- (void)addCondition:(GDGCondition *__nonnull)condition;

- (void)groupBy:(GDGColumn *__nonnull)column;

- (void)addGroupCondition:(GDGCondition *__nonnull)condition;

- (void)orderBy:(GDGColumn *__nonnull)column order:(GDGQueryOrder)order;

- (void)clearProjection;

@end