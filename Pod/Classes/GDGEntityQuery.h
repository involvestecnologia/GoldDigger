//
//  GDGEntityQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGQuery.h"

@class GDGEntityManager;
@class GDGEntity;

@interface GDGQuery (Entity)

- (NSArray<__kindof GDGEntity *> *)array;

- (__kindof GDGEntity *)object;

@end

@interface GDGEntityQuery : GDGQuery

@property (copy, readonly, nonatomic) GDGEntityQuery *(^select)(NSArray<NSString *> *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^from)(GDGSource *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^fromTable)(NSString *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^join)(__kindof GDGSource *, NSString *, GDGCondition *, NSArray<NSString *> *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^joinTable)(NSString *, NSString *, GDGCondition *, NSArray<NSString *> *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^where)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) GDGEntityQuery *(^asc)(NSString *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^desc)(NSString *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^limit)(int);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^filter)(NSArray<id <GDGFilter>> *);

@property (copy, readonly, nonatomic) GDGEntityQuery *(^pull)(NSDictionary <NSString *, NSArray *> *);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^id)(NSInteger);
@property (copy, readonly, nonatomic) GDGEntityQuery *(^joinRelation)(NSString *, NSArray<NSString *> *);

@property (readonly, nonatomic) NSDictionary <NSString *, NSArray *> *pulledRelations;
@property (readonly, nonatomic) GDGEntityManager *manager;

- (instancetype)initWithManager:(GDGEntityManager *)manager;

- (instancetype)copy;

@end