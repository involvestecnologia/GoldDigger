//
//  SQLSource.h
//  AgilePromoterClient
//
//  Created by Felipe Lobo on 4/7/16.
//

#import "GDGSource.h"

@class GDGColumn;
@class SQLQuery;

@protocol SQLSource <GDGSource>

@property (readonly, nonatomic) NSArray <GDGColumn *> *columns;
@property (readonly, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *alias;

@optional

- (NSArray *)evalByTuple:(SQLQuery *)query;

- (NSArray *)evalByColumn:(SQLQuery *)query;

@end