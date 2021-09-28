//
// Created by Felipe Lobo on 2018-11-02.
//

#import "GDGRawQuery.h"

@implementation GDGRawQuery

- (instancetype)initWithQuery:(NSString *)rawQueryValue args:(NSArray *)args
{
	self = [super init];
	if (self)
	{
		_visit = rawQueryValue;
		_args = args;
	}

	return self;
}

- (NSString *)debugDescription
{
	NSMutableString *visit = [[NSMutableString alloc] initWithString:self.visit];

	for (NSString *arg in self.args)
	{
		NSRange questionMarkRange = [visit rangeOfString:@"?"];

		[visit replaceCharactersInRange:questionMarkRange withString:arg];
	}

	return [NSString stringWithString:visit];
}

@end
