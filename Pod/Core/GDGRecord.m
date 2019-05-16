//
//  GDGRecord.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import "GDGRecord.h"
#import "NSObject+GDG.h"
#import "GDGMapping.h"
#import "GDGRecordSwizzler.h"
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import <objc/runtime.h>

@implementation GDGRecord

+ (nullable instancetype)recordClass:(Class)class mapping:(GDGMapping *(^)(NSArray *))tap
{
	NSArray <NSValue *> *properties = [NSObject gdg_propertyListFromClass:class until:class];

	NSError *error;
	GDGRecordSwizzler *swizzler = [[GDGRecordSwizzler alloc] initWithProperties:properties ofClass:class];
	if (![swizzler swizzleProperties:&error])
	{
		NSLog(error.localizedDescription);
		return nil;
	}

	NSArray <NSString *> *propertyNames = \
			[properties map:^NSString *(NSValue *property) {
				objc_property_t cproperty = property.pointerValue;
				return [NSString stringWithUTF8String:property_getName(cproperty)];
			}];

	GDGMapping *mapping = tap(propertyNames);

	return [[self alloc] initWithMapping:mapping];
}

- (instancetype)init
{
	@throw [NSException exceptionWithName:@"Direct Itinialization Exception"
	                               reason:@"GDGRecord throws that its initialization is encapsulate, and it should always be instantiated statically by using the +recordClass:mapping: method"
	                             userInfo:nil];
}

- (nonnull instancetype)initWithMapping:(GDGMapping *)mapping
{
	self = [super init];
	if (self)
		_mapping = mapping;

	return self;
}

// #########

- (nullable NSArray <ObjectType> *)findAllConnecting:(GDGConnection *)connection error:(NSError **)error
{
	return nil;
}

- (nullable NSArray <ObjectType> *)findById:(id)id1 connecting:(GDGConnection *)connection error:(NSError **)error
{
	return nil;
}

- (nullable NSArray <ObjectType> *)findByQuery:(GDGQuery *)query connecting:(GDGConnection *)connection error:(NSError **)error
{
	return nil;
}

@end
