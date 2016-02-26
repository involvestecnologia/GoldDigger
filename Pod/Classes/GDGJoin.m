//
//  GDGJoin.m
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGJoin.h"

#import "GDGSource.h"

@implementation GDGJoin

- (instancetype)initWithType:(NSString*)type condition:(NSString*)condition source:(GDGSource*)source
{
	if (self = [super init])
	{
		_type = type;
		_condition = condition;
		_source = source;
	}
	
	return self;
}

- (NSString*)visit
{
	NSMutableString *joinString = [[NSMutableString alloc] initWithString:_type];
	
	[joinString appendString:@" JOIN "];
	[joinString appendString:_source.alias];
	[joinString appendString:@" ON "];
	[joinString appendString:_condition];
	
	return [NSString stringWithString:joinString];
}

@end
