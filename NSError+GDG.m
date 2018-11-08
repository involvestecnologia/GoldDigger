//
// Created by Felipe Lobo on 2018-11-02.
//

#import "NSError+GDG.h"


@implementation NSError (GDG)

+ (instancetype)errorWithCode:(GDGErrorCode)code message:(NSString *)message underlying:(NSError *)error;
{
	NSMutableDictionary *errorInfo = @{ NSLocalizedDescriptionKey: message }.mutableCopy;

	if (error)
		errorInfo[NSUnderlyingErrorKey] = error;

	return [self errorWithDomain:GDGErrorDomain code:code userInfo:errorInfo];
}

@end