//
//  GDGQuerySource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGQuerySource.h"
#import "GDGQuery.h"

@interface GDGQuerySource ()

@property (readwrite, nonatomic) GDGQuery *query;

@end

@implementation GDGQuerySource

- (instancetype)initWithQuery:(GDGQuery *__nonnull)query alias:(NSString *__nullable)alias
{
	if (self = [super init])
	{
		_query = query;
		_alias = alias;
	}

	return self;
}

- (NSString *)identifier
{
	return _alias ?: _query.source.identifier;
}

@end
