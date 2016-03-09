//
//  GDGQuerySource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGQuerySource.h"

@implementation GDGQuerySource

- (instancetype)initWithQuery:(GDGQuery *)query;
{
	if (self = [super init])
	{
		_query = query;

		self.alias = query.source.alias;
	}

	return self;
}

@end
