//
// Created by Felipe Lobo on 2019-05-15.
//

#import "GDGRecordSwizzler.h"
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import <objc/runtime.h>

@implementation GDGRecordSwizzler {
	__strong NSArray *_properties;
	__unsafe_unretained Class _class;

	SEL _changedPropertiesSelector;
	SEL _filledPropertiesSelector;
}

- (instancetype)initWithProperties:(NSArray *__nonnull)properties ofClass:(Class)class
{
	self = [super init];
	if (self)
	{
		_properties = properties;
		_class = class;

		_changedPropertiesSelector = @selector(changedProperties);
		_filledPropertiesSelector = @selector(changedProperties);
	}

	return self;
}

- (BOOL)swizzleProperties:(NSError **)error
{
	// Start the magic
	// Create dynamic properties: -changedProperties and -filledProperties

	[self runtimeAddChangedPropertiesToClass:_class];
	[self runtimeAddFilledPropertiesToClass:_class];

	// Start the black magic
	// Swizzle setter impl for every property in list

	[_properties each:^(NSValue *property) {
		[self overrideSetter:property.pointerValue ofClass:_class];
	}];

	// End magic

	return YES;
}

#pragma mark - Runtime add properties

// region Runtime add properties

- (void)runtimeAddChangedPropertiesToClass:(Class)class
{
	NSArray *(^changedPropertiesGetterHandler)(id) = ^NSArray *(id _self) {
		NSMutableArray *changedProperties;

		changedProperties = objc_getAssociatedObject(_self, _changedPropertiesSelector);
		if (!changedProperties)
		{
			changedProperties = [[NSMutableArray alloc] init];
			objc_setAssociatedObject(_self, _changedPropertiesSelector, changedProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}

		return changedProperties;
	};

	IMP changedPropertiesGetter = imp_implementationWithBlock(changedPropertiesGetterHandler);
	class_addMethod(class, _changedPropertiesSelector, changedPropertiesGetter, "@@:");
}

- (void)runtimeAddFilledPropertiesToClass:(Class)class
{
	NSArray *(^filledPropertiesGetterHandler)(id) = ^NSArray *(id _self) {
		NSMutableArray *filledProperties;

		filledProperties = objc_getAssociatedObject(_self, _filledPropertiesSelector);
		if (!filledProperties)
		{
			filledProperties = [[NSMutableArray alloc] init];
			objc_setAssociatedObject(_self, _changedPropertiesSelector, filledProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}

		return filledProperties;
	};

	IMP filledPropertiesGetter = imp_implementationWithBlock(filledPropertiesGetterHandler);
	class_addMethod(class, _filledPropertiesSelector, filledPropertiesGetter, "@@:");
}

// endregion

#pragma mark - Overriding

// region Overriding

- (void)overrideSetter:(objc_property_t)property ofClass:(Class)class
{
	NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

	char *cstrSignature = property_copyAttributeValue(property, "S");
	NSString *signature = nil;

	if (cstrSignature == NULL)
	{
		NSString *camelCaseProp = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
		                                                                withString:[[propertyName substringToIndex:1] uppercaseString]];
		signature = [NSString stringWithFormat:@"set%@:", camelCaseProp];
	}
	else
		signature = @(cstrSignature);

	SEL setterSelector = NSSelectorFromString(signature);
	Method setter = class_getInstanceMethod(class, setterSelector);

	if (!setter)
		return;

	IMP setterImplementation = method_getImplementation(setter);

	const char *str = property_getAttributes(property);
	const char type = str[1];

#define SETTER_IMP_BLOCK(T)     ^(id _self, T argument) { \
    \
	/* Original setter impl call */ \
    ((void(*)(NSObject *, SEL, T)) setterImplementation)(_self, setterSelector, argument); \
    \
	NSMutableArray *filledProperties = [_self performSelector:_filledPropertiesSelector]; \
	if ([filledProperties containsObject:propertyName]) \
	{ \
		NSMutableArray *changedProperties = [_self performSelector:_changedPropertiesSelector]; \
		if (![changedProperties containsObject:propertyName]) \
			[changedProperties addObject:propertyName]; \
	} \
	else \
		[filledProperties addObject:propertyName]; \
}

	id block;
	switch (type)
	{
		case '@':
		{
			block = SETTER_IMP_BLOCK(id);
			break;
		}
		case 'i':
		case 'l':
		case 's':
		case 'q':
		{
			block = SETTER_IMP_BLOCK(NSInteger);
			break;
		}
		case 'B':
		{
			block = SETTER_IMP_BLOCK(BOOL);
			break;
		}
		case 'c':
		{
			block = SETTER_IMP_BLOCK(char);
			break;
		}
		case 'I':
		case 'Q':
		{
			block = SETTER_IMP_BLOCK(NSUInteger);
			break;
		}
		case 'd':
		{
			block = SETTER_IMP_BLOCK(double);
			break;
		}
		case 'f':
		{
			block = SETTER_IMP_BLOCK(float);
			break;
		}
		default:
			@throw [NSException exceptionWithName:@"Setter Type Not Handled Exception"
			                               reason:[NSString stringWithFormat:@"[GDGRecord -overrideSetter:forClass:] throws that the type %c cannot be handled", type]
			                             userInfo:nil];
	}

#undef SETTER_IMP_BLOCK

	IMP fillSetterImplementation = imp_implementationWithBlock(block);
	method_setImplementation(setter, fillSetterImplementation);

	free(cstrSignature);
}

// endregion

@end