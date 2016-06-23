//
//  SQLQuerySource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "SQLQuerySource.h"

#import "SQLQuery.h"
#import "SQLTableSource.h"

@interface SQLQuerySource ()

@property (readwrite, nonatomic) __kindof SQLQuery *query;

@end

@implementation SQLQuerySource

- (instancetype)initWithQuery:(__kindof SQLQuery *)query
{
	if (self = [super init])
		_query = query;

	return self;
}

- (SQLQuerySource *)copyWithZone:(nullable NSZone *)zone
{
	SQLQuerySource *copy = [(SQLQuerySource *) [[self class] allocWithZone:zone] initWithQuery:[_query copy]];

	return copy;
}

- (NSString *)identifier
{
	return _alias ?: _query.source.identifier;
}

@end
