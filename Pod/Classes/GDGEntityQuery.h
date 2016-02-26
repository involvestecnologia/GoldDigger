//
//  GDGEntityQuery.h
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGQuery.h"

@class GDGEntityManager;
@class GDGEntity;

@interface GDGEntityQuery : GDGQuery

@property (copy, readonly, nonatomic) GDGEntityQuery* (^joinRelation)(NSString*, NSArray<NSString*>*);

@property (readonly, nonatomic) GDGEntityManager *manager;

- (instancetype)initWithManager:(GDGEntityManager*)manager;

@end
