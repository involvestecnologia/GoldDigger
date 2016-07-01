//
//  GDGEntity.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import "GDGEntity.h"
#import <objc/runtime.h>

static NSMutableDictionary *EntityHandlersDictionary;

#define GDGEntityHandlerForClass(class)         EntityHandlersDictionary[NSStringFromClass(class)]

@implementation NSObject (GDG)

+ (NSArray<NSValue *> *)gdg_propertyListFromClass:(Class)fromClass until:(Class)toClass
{
	NSMutableArray *props = [[NSMutableArray alloc] init];

	unsigned int innerCount;
	Class currentClass = fromClass;

	objc_property_t *properties;

	do
	{
		properties = class_copyPropertyList(currentClass, &innerCount);

		for (int i = 0; i < innerCount; i++)
		{
			objc_property_t prop = properties[i];
			NSValue *value = [NSValue valueWithPointer:prop];
			[props addObject:value];
		}

		free(properties);

		currentClass = [currentClass superclass];
	} while (currentClass != toClass);

	return [NSArray arrayWithArray:props];
}

@end

@interface GDGEntityHandler : NSObject

@property (readonly, nonatomic) NSMutableDictionary *beforeSetHandlers;
@property (readonly, nonatomic) NSMutableDictionary *afterSetHandlers;
@property (readonly, nonatomic) NSMutableDictionary *beforeGetHandlers;
@property (readonly, nonatomic) NSArray<NSString *> *properties;

+ (instancetype)entityHandler;

@end

@implementation GDGEntityHandler

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

#define GDGEntityPropertyHandler(block)     [GDGEntityPropertyHandler handlerWithBlock:block]

@interface GDGEntityPropertyHandler : NSObject

@property (copy, nonatomic) void (^block)(GDGEntity *, NSString *);

+ (instancetype)handlerWithBlock:(void (^)(GDGEntity *, NSString *))block;

- (void)invokeWithEntity:(GDGEntity *)entity
                property:(NSString *)propertyName;
@end

@implementation GDGEntityPropertyHandler

+ (instancetype)handlerWithBlock:(void (^)(GDGEntity *, NSString *))block
{
	GDGEntityPropertyHandler *entityHandler = [[self alloc] init];
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
	EntityHandlersDictionary = @{}.mutableCopy;
}

+ (void)trackPropertyCalls
{
	if ([EntityHandlersDictionary.allKeys containsObject:NSStringFromClass(self)])
		return;

	NSArray<NSValue *> *properties = [self gdg_propertyListFromClass:self until:[GDGEntity class]];

	NSMutableArray<NSString *> *propertiesName = [[NSMutableArray alloc] initWithCapacity:properties.count];

	for (NSValue *property in properties)
	{
		objc_property_t cproperty = property.pointerValue;

		NSString *name = [NSString stringWithUTF8String:property_getName(cproperty)];

		[propertiesName addObject:name];

		[self overrideSetter:cproperty];
		[self overrideGetter:cproperty];
	}

	EntityHandlersDictionary[NSStringFromClass(self)] = [[GDGEntityHandler alloc] initWithProperties:[NSArray arrayWithArray:propertiesName]];
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
    GDGEntityHandler *entityHandler = GDGEntityHandlerForClass(_self.class); \
    \
    for (GDGEntityPropertyHandler *handler in entityHandler.beforeSetHandlers[propertyName]) \
      [handler invokeWithEntity:_self property:propertyName]; \
    \
        ((void(*)(NSObject *, SEL, T)) setterImplementation)(_self, setterSelector, argument); \
    \
    for (GDGEntityPropertyHandler *handler in entityHandler.afterSetHandlers[propertyName]) \
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
    GDGEntityHandler *entityHandler = GDGEntityHandlerForClass(_self.class); \
    \
    for (GDGEntityPropertyHandler *handler in entityHandler.beforeGetHandlers[propertyName]) \
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

	GDGEntityHandler *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *beforeSetHandlers = handler.beforeSetHandlers[propertyName];
	if (beforeSetHandlers == nil)
		handler.beforeSetHandlers[propertyName] = beforeSetHandlers = [NSMutableArray array];

	[beforeSetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

+ (void)addAfterSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
               forProperty:(NSString *)propertyName
{
	[self trackPropertyCalls];

	GDGEntityHandler *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *afterSetHandlers = handler.afterSetHandlers[propertyName];
	if (afterSetHandlers == nil)
		handler.afterSetHandlers[propertyName] = afterSetHandlers = [NSMutableArray array];

	[afterSetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

+ (void)addBeforeGetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName
{
	[self trackPropertyCalls];

	GDGEntityHandler *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *beforeGetHandlers = handler.beforeGetHandlers[propertyName];
	if (beforeGetHandlers == nil)
		handler.beforeGetHandlers[propertyName] = beforeGetHandlers = [NSMutableArray array];

	[beforeGetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

- (BOOL)isEqual:(id)object
{
	if (self == object)
		return YES;

	if (![object isKindOfClass:[self class]])
		return NO;

	return [self isEqualToEntity:object];
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
	return ([self.id hash] ^ [NSStringFromClass(self.class) hash]) * 31u;
}

@end
