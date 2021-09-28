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

- (instancetype)initWithKind:(GDGJoinKind)kind
                   condition:(GDGCondition *__nonnull)condition
                      source:(id <GDGSource>__nonnull)source
{
	if (self = [super init])
	{
		_kind = kind;
		_condition = condition;
		_source = source;
	}

	return self;
}

@end
