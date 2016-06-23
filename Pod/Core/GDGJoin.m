//
//  GDGJoin.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGJoin.h"

#import "GDGCondition.h"
#import "GDGSource.h"

@implementation GDGJoin

- (instancetype)initWithCondition:(GDGCondition *)condition source:(id <GDGSource>)source;
{
	if (self = [super init])
	{
		_condition = condition;
		_source = source;
	}

	return self;
}

- (GDGJoin *)copyWithZone:(nullable NSZone *)zone
{
	GDGJoin *join = [(GDGJoin *) [self.class allocWithZone:zone] init];
	join.condition = [_condition copyWithZone:zone];
	join.source = [_source copyWithZone:zone];

	return join;
}

@end
