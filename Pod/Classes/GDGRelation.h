//
//  GDGRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <Foundation/Foundation.h>
#import "GDGEntity.h"
#import "GDGEntityManager.h"

@class GDGCondition;
@class GDGSource;

@interface GDGRelation : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) GDGEntityManager *manager;
@property (strong, nonatomic) GDGEntityManager *relatedManager;
@property (strong, nonatomic) NSString *foreignProperty;
@property (strong, nonatomic) GDGCondition *condition;
@property (strong, nonatomic) GDGEntityQuery *baseQuery;

- (instancetype)initWithName:(NSString *)name manager:(GDGEntityManager *)manager;

- (NSString *)joinCondition;

- (NSString *)joinConditionFromSource:(GDGSource *)source toSource:(GDGSource *)joinedSource;

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray *)properties;

- (void)set:(__kindof NSObject *)value onEntity:(GDGEntity *)entity;

- (void)save:(GDGEntity *)entity;

@end
