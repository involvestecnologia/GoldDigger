//
//  SQLQuerySource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"
#import "SQLSource.h"

@class SQLQuery;

@interface SQLQuerySource : NSObject <SQLSource>

@property (readonly, nonatomic) __kindof SQLQuery *query;
@property (strong, nonatomic) NSString *alias;

- (instancetype)initWithQuery:(__kindof SQLQuery *)query;

@end
