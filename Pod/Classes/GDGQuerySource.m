//
//  GDGQuerySource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGQuerySource.h"

#import "GDGSource_Protected.h"

@interface GDGQuerySource ()

@property (readwrite, nonatomic) GDGQuery *query;

@end

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

- (GDGQuerySource *)copyWithZone:(nullable NSZone *)zone
{
	GDGQuerySource *copy = (GDGQuerySource *) [super copyWithZone:zone];

	copy.query = [_query copy];

	return copy;
}

@end
