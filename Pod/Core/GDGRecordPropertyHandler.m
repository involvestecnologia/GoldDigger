//
// Created by Felipe Lobo on 2018-12-29.
//

#import "GDGRecordPropertyHandler.h"
#import "GDGRecord.h"

@implementation GDGEntityPropertyHandler

+ (instancetype)handlerWithBlock:(void (^)(GDGRecord *, NSString *))block
{
	return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(void (^ __nonnull)(GDGRecord *, NSString *))block
{
	self = [super init];
	if (self)
		_block = block;

	return self;
}

- (void)invokeWithEntity:(GDGRecord *)entity property:(NSString *)propertyName
{
	_block(entity, propertyName);
}

@end
