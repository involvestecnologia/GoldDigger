//
//  GDGConditionBuilder+EntityQuery.h
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGConditionBuilder.h"

@class GDGEntityQuery;

@interface GDGConditionBuilder (EntityQuery)

@property (readonly, nonatomic) GDGEntityQuery *query;
@property (copy, readonly, nonatomic) GDGConditionBuilder* (^prop)(NSString*);

- (instancetype)initWithEntityQuery:(GDGEntityQuery *)entityQuery;

@end
