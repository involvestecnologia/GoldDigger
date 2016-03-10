//
//  GDGQuerySource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"

#import "GDGQuery.h"

@interface GDGQuerySource : GDGSource <NSCopying>

@property (readonly, nonatomic) GDGQuery *query;

- (instancetype)initWithQuery:(GDGQuery *)query;

@end
