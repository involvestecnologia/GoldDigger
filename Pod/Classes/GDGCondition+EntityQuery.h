//
//  GDGCondition+EntityQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGCondition.h"

@class GDGEntityQuery;

@interface GDGCondition (EntityQuery)

@property (readonly, nonatomic) GDGEntityQuery *query;
@property (copy, readonly, nonatomic) GDGCondition *(^prop)(NSString *);

+ (instancetype)builderWithEntityQuery:(GDGEntityQuery *)entityQuery;

@end
