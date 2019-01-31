//
// Created by Felipe Lobo on 2018-12-29.
//

#import "GDGRecordHandlers.h"

@implementation GDGRecordHandlers

+ (instancetype)entityHandler
{
	return [[self alloc] init];
}

- (instancetype)initWithProperties:(NSArray<NSString *> *)properties
{
	if (self = [super init])
	{
		_beforeSetHandlers = @{}.mutableCopy;
		_afterSetHandlers = @{}.mutableCopy;
		_beforeGetHandlers = @{}.mutableCopy;
		_properties = properties;
	}

	return self;
}

@end
