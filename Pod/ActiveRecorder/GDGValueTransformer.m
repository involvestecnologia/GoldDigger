//
//  GDGValueTransformer.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGValueTransformer.h"

@implementation GDGValueTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

+ (instancetype)transformerForward:(id (^)(id))forwardHandler reverse:(id (^)(id))reverseHandler
{
	return [[self alloc] initWithForwardHandler:forwardHandler reverseHandler:reverseHandler];
}

- (instancetype)initWithForwardHandler:(id (^)(id))forwardHandler reverseHandler:(id (^)(id))reverseHandler
{
	if (self = [super init])
	{
		_forwardHandler = forwardHandler;
		_reverseHandler = reverseHandler;
	}

	return self;
}

- (id)transformedValue:(id)value
{
	return _forwardHandler(value);
}

- (id)reverseTransformedValue:(id)value
{
	return _reverseHandler(value);
}

@end
