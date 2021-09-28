//
// Created by Felipe Lobo on 2018-11-02.
//

#import "GDGResultSet.h"
#import "NSError+GDG.h"
#import "ObjectiveSugar.h"

@implementation GDGResultSet

- (instancetype)initWithResultSet:(CIRResultSet *__nonnull)resultSet projection:(NSArray *__nonnull)projection
{
	self = [super init];
	if (self)
	{
		_resultSet = resultSet;
		_projection = projection;
	}

	return self;
}

- (NSDictionary *)next:(NSError **)error
{
	NSError *underlyingError;
	BOOL next = [_resultSet next:&underlyingError];

	if (!next)
	{
		if (underlyingError && error)
		{
			NSString *message = NSStringWithFormat(@"Error while iterating result, underlying error message: %@", underlyingError.localizedDescription);
			*error = [NSError errorWithCode:GDGResultIterationError message:message underlying:underlyingError];//;
		}

		return nil;
	}

	NSUInteger dotIndex = 0;
	NSInteger columnIndex = 0;
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithCapacity:_resultSet.columnCount];
	NSString *name = nil;

	for (name in _projection)
	{
		dotIndex = [name rangeOfString:@"."].location;
		name = dotIndex != NSNotFound ? [name substringFromIndex:dotIndex + 1] : name;
		columnIndex = [_resultSet columnIndexWithName:name];

		mutableDictionary[name] = _resultSet[(NSUInteger) columnIndex] ?: [NSNull null];
	}

	return [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

@end