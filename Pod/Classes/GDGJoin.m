//
//  GDGJoin.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGJoin.h"

#import "GDGSource.h"

@implementation GDGJoin

- (instancetype)initWithType:(NSString *)type condition:(NSString *)condition source:(GDGSource *)source
{
	if (self = [super init])
	{
		_type = type;
		_condition = condition;
		_source = source;
	}

	return self;
}

- (NSString *)visit
{
	NSMutableString *joinString = [_type mutableCopy];

	[joinString appendString:@" JOIN "];
	[joinString appendString:_source.alias];
	[joinString appendString:@" ON "];
	[joinString appendString:_condition];

	return [NSString stringWithString:joinString];
}

- (GDGJoin *)copyWithZone:(nullable NSZone *)zone
{
	GDGJoin *join = [(GDGJoin *) [[self class] allocWithZone:zone] init];

	join.type = _type;
	join.condition = _condition;
	join.source = _source.copy;

	return join;
}

@end
