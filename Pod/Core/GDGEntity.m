//
//  GDGEntity.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <objc/runtime.h>
#import "GDGEntity.h"
#import "GDGEntity_Package.h"
#import "GDGEntityMap.h"

static BOOL IsTrackingProperties;

static NSMutableDictionary *BeforeSetHandlers;
static NSMutableDictionary *AfterSetHandlers;
static NSMutableDictionary *BeforeGetHandlers;

static NSMutableDictionary *Maps;

#define GDGEntityHandler(block)     [GDGEntityHandler handlerWithBlock:block]

@interface GDGEntityHandler : NSObject

@property (copy, nonatomic) void (^block)(GDGEntity *, NSString *);

+ (instancetype)handlerWithBlock:(void (^)(GDGEntity *, NSString *))block;

- (void)invokeWithEntity:(GDGEntity *)entity
                property:(NSString *)propertyName;
@end

@implementation GDGEntityHandler

+ (instancetype)handlerWithBlock:(void (^)(GDGEntity *, NSString *))block
{
	GDGEntityHandler *entityHandler = [[GDGEntityHandler alloc] init];
	entityHandler->_block = block;

	return entityHandler;
}

- (void)invokeWithEntity:(GDGEntity *)entity
                property:(NSString *)propertyName
{
	_block(entity, propertyName);
}

@end

@implementation GDGEntity

+ (void)load
{
	IsTrackingProperties = NO;

	BeforeSetHandlers = [NSMutableDictionary dictionary];
	AfterSetHandlers = [NSMutableDictionary dictionary];
	BeforeGetHandlers = [NSMutableDictionary dictionary];

	Maps = [NSMutableDictionary dictionary];
}

+ (void)trackPropertyCalls
{
	if (IsTrackingProperties)
		return;

	unsigned int count = 0;
	objc_property_t *properties = class_copyPropertyList(self, &count);

	for (int i = 0; i < count; ++i)
	{
		objc_property_t property = properties[i];
		if (property == NULL)
			@throw [NSException exceptionWithName:@"Property List Inconsistency Exception"
			                               reason:@"[GDGEntity -trackPropertyCalls] throws that and <objc/runtime> error has occurred and property list could not be fully retrieved"
			                             userInfo:nil];

		[self overrideSetter:property];
		[self overrideGetter:property];
	}

	IsTrackingProperties = YES;
}

#pragma mark - Creation

+ (instancetype)entity
{
	return [[self alloc] init];
}

#pragma mark Property hack

+ (void)overrideSetter:(objc_property_t)property
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
	Method setter = class_getInstanceMethod(self, setterSelector);

	if (!setter)
		return;

	IMP setterImplementation = method_getImplementation(setter);

	const char *str = property_getAttributes(property);
	const char type = str[1];

#define SETTER_IMP_BLOCK(T)     ^(__kindof GDGEntity *_self, T argument) { \
		\
		for (GDGEntityHandler *handler in BeforeSetHandlers[propertyName]) \
			[handler invokeWithEntity:_self property:propertyName]; \
		\
        ((void(*)(NSObject *, SEL, T)) setterImplementation)(_self, setterSelector, argument); \
		\
		for (GDGEntityHandler *handler in AfterSetHandlers[propertyName]) \
			[handler invokeWithEntity:_self property:propertyName]; \
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
			@throw [NSException exceptionWithName:@"Setter Type Not Handled Exception" reason:[NSString stringWithFormat:@"[GDGEntity -overrideSetter:forClass:] throws that the type %c cannot be handled", type] userInfo:nil];
	}

#undef SETTER_IMP_BLOCK

	IMP fillSetterImplementation = imp_implementationWithBlock(block);
	method_setImplementation(setter, fillSetterImplementation);

	free(cstrSignature);
}

+ (void)overrideGetter:(objc_property_t)property
{
	NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

	char *cstrSignature = property_copyAttributeValue(property, "G");

	NSString *signature = cstrSignature == NULL ? propertyName : @(cstrSignature);

	SEL getterSelector = NSSelectorFromString(signature);
	Method getter = class_getInstanceMethod(self, getterSelector);

	if (!getter)
		return;

	IMP getterImplementation = method_getImplementation(getter);

	char type = property_getAttributes(property)[1];

#define GETTER_IMP_BLOCK(T) ^(__kindof GDGEntity *_self) { \
		\
		for (GDGEntityHandler *handler in BeforeGetHandlers[propertyName]) \
			[handler invokeWithEntity:_self property:propertyName]; \
        \
        return ((T(*)(NSObject *, SEL)) getterImplementation)(_self, getterSelector); \
    }

	id block;
	switch (type)
	{
		case '@':
		{
			block = GETTER_IMP_BLOCK(id);
			break;
		}
		case 'i':
		case 'l':
		case 's':
		case 'q':
		{
			block = GETTER_IMP_BLOCK(NSInteger);
			break;
		}
		case 'B':
		{
			block = GETTER_IMP_BLOCK(BOOL);
			break;
		}
		case 'c':
		{
			block = GETTER_IMP_BLOCK(char);
			break;
		}
		case 'I':
		case 'Q':
		{
			block = GETTER_IMP_BLOCK(NSUInteger);
			break;
		}
		case 'd':
		{
			block = GETTER_IMP_BLOCK(double);
			break;
		}
		case 'f':
		{
			block = GETTER_IMP_BLOCK(float);
			break;
		}
		default:
			@throw [NSException exceptionWithName:@"Setter Type Not Handled Exception" reason:[NSString stringWithFormat:@"[GDGEntity -overrideSetter:forClass:] throws that the type %c cannot be handled", type] userInfo:nil];
	}

#undef GETTER_IMP_BLOCK

	IMP autoFillGetterImplementation = imp_implementationWithBlock(block);
	method_setImplementation(getter, autoFillGetterImplementation);

	free(cstrSignature);
}

+ (void)addBeforeSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName
{
	[self trackPropertyCalls];

	NSMutableArray *beforeSetHandlers = BeforeSetHandlers[propertyName];
	if (beforeSetHandlers == nil)
		BeforeSetHandlers[propertyName] = beforeSetHandlers = [NSMutableArray array];

	[beforeSetHandlers addObject:GDGEntityHandler(hasFilledHandler)];
}

+ (void)addAfterSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
               forProperty:(NSString *)propertyName
{
	[self trackPropertyCalls];

	NSMutableArray *afterSetHandlers = AfterSetHandlers[propertyName];
	if (afterSetHandlers == nil)
		AfterSetHandlers[propertyName] = afterSetHandlers = [NSMutableArray array];

	[afterSetHandlers addObject:GDGEntityHandler(hasFilledHandler)];
}

+ (void)addBeforeGetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName
{
	[self trackPropertyCalls];

	NSMutableArray *beforeGetHandlers = BeforeGetHandlers[propertyName];
	if (beforeGetHandlers == nil)
		BeforeGetHandlers[propertyName] = beforeGetHandlers = [NSMutableArray array];

	[beforeGetHandlers addObject:GDGEntityHandler(hasFilledHandler)];
}

+ (void)addMap:(GDGEntityMap *)map toSelector:(SEL)selector
{
	Maps[NSStringFromSelector(selector)] = map;
}

- (BOOL)isEqualToEntity:(GDGEntity *)entity
{
	return [entity isKindOfClass:[self class]]
			&& self.id != nil
			&& entity.id != nil
			&& [self.id isEqual:entity.id];
}

- (NSUInteger)hash
{
	return [self.id hash] ^ [NSStringFromClass(self.class) hash];
}

@end
