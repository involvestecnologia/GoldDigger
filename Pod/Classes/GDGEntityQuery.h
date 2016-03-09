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

@property (copy, readonly, nonatomic) GDGEntityQuery *(^joinRelation)(NSString *, NSArray<NSString *> *);

@property (readonly, nonatomic) GDGEntityManager *manager;

- (instancetype)initWithManager:(GDGEntityManager *)manager;

@end
