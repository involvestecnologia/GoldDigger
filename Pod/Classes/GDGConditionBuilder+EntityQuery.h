//
//  GDGConditionBuilder+EntityQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGConditionBuilder.h"

@class GDGEntityQuery;

@interface GDGConditionBuilder (EntityQuery)

@property (readonly, nonatomic) GDGEntityQuery *query;
@property (copy, readonly, nonatomic) GDGConditionBuilder *(^prop)(NSString *);

+ (instancetype)builderWithEntityQuery:(GDGEntityQuery *)entityQuery;

@end
