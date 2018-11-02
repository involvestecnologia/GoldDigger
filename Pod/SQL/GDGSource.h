//
//  SQLSource.h
//  AgilePromoterClient
//
//  Created by Felipe Lobo on 4/7/16.
//

#import "GDGSource.h"

@class GDGColumn;
@class GDGQuery;

@protocol GDGSource

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSArray <GDGColumn *> *columns;
@property (readonly, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *alias;

- (NSString *)visit:(GDGQuery *)query;

@optional

- (NSArray *)evalByTuple:(GDGQuery *)query;

- (NSArray *)evalByColumn:(GDGQuery *)query;

@end