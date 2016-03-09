//
//  GDGQuerySource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"

#import "GDGQuery.h"

@interface GDGQuerySource : GDGSource

@property (strong, nonatomic) GDGQuery *query;

- (instancetype)initWithQuery:(GDGQuery *)query;

@end
