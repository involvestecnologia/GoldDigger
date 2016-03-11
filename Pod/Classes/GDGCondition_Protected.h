//
//  GDGCondition_Protected.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/19/16.
//

#import "GDGCondition.h"

@class GDGEntityQuery;

@interface GDGCondition ()

@property (readwrite, nonatomic) GDGEntityQuery *query;

- (NSDictionary<NSString *, id> *)arguments;

@end
