//
// Created by Felipe Lobo on 2018-11-02.
//

#import "GDGParser.h"

@implementation GDGParsingResult

- (instancetype)initWithVisit:(NSString *)visit args:(NSArray *)args
{
	self = [super init];
	if (self)
	{
		_visit = visit;
		_args = args;
	}

	return self;
}


@end