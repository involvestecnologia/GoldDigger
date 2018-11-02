//
//  SQLQuerySource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"
#import "SQLSource.h"

@class GDGQuery;

@interface SQLQuerySource : NSObject <GDGSource>

@property (readonly, nonatomic) __kindof GDGQuery *query;
@property (strong, nonatomic) NSString *alias;

- (instancetype)initWithQuery:(__kindof GDGQuery *)query;

@end
