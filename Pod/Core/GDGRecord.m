//
//  GDGRecord.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import "GDGRecord.h"
#import "NSObject+GDG.h"
#import "GDGRecordHandlers.h"
#import "GDGRecordPropertyHandler.h"
#import "GDGMapping.h"
#import "ObjectiveSugar.h"
#import <objc/runtime.h>

static NSMutableDictionary *EntityHandlersDictionary;

#define GDGEntityHandlerForClass(class)         EntityHandlersDictionary[NSStringFromClass(class)]

#define GDGEntityPropertyHandler(block)     [GDGEntityPropertyHandler handlerWithBlock:block]

@implementation GDGRecord

+ (nonnull instancetype)recordClass:(Class)class usingTableMapping:(GDGMapping *(^)(NSArray *))tap
{
	NSArray <NSValue *> *properties = [NSObject gdg_propertyListFromClass:class until:class];
	NSArray <NSString *> *propertyNames = \
			[properties map:^NSString *(NSValue *property) {
				objc_property_t cproperty = property.pointerValue;
				return [NSString stringWithUTF8String:property_getName(cproperty)];
			}];

	GDGMapping *mapping = tap(propertyNames);

	return [[self alloc] initWithMapping:mapping];
}

- (nonnull instancetype)initWithMapping:(GDGMapping *)mapping
{
	self = [super init];
	if (self)
		_mapping = mapping;

	return self;
}

- (BOOL)fill:(void (^ __nonnull)(GDGRecord *__nullable))fillHandler error:(NSError **__nullable)error
{


	return ;
}

#pragma mark - Property hacking

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

#define SETTER_IMP_BLOCK(T)     ^(__kindof GDGRecord *_self, T argument) { \
    \
    GDGRecordHandlers *entityHandler = GDGEntityHandlerForClass(_self.class); \
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
			@throw [NSException exceptionWithName:@"Setter Type Not Handled Exception" reason:[NSString stringWithFormat:@"[GDGRecord -overrideSetter:forClass:] throws that the type %c cannot be handled", type] userInfo:nil];
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

#define GETTER_IMP_BLOCK(T) ^(__kindof GDGRecord *_self) { \
    \
    GDGRecordHandlers *entityHandler = GDGEntityHandlerForClass(_self.class); \
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
		case '#':
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
			@throw [NSException exceptionWithName:@"Setter Type Not Handled Exception" reason:[NSString stringWithFormat:@"[GDGRecord -overrideSetter:forClass:] throws that the type %c cannot be handled", type] userInfo:nil];
	}

#undef GETTER_IMP_BLOCK

	IMP autoFillGetterImplementation = imp_implementationWithBlock(block);
	method_setImplementation(getter, autoFillGetterImplementation);

	free(cstrSignature);
}

#pragma mark - Add static handlers

+ (void)addBeforeSetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName
{
	[self trackProperties];

	GDGRecordHandlers *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *beforeSetHandlers = handler.beforeSetHandlers[propertyName];
	if (beforeSetHandlers == nil)
		handler.beforeSetHandlers[propertyName] = beforeSetHandlers = [NSMutableArray array];

	[beforeSetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

+ (void)addAfterSetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
               forProperty:(NSString *)propertyName
{
	[self trackProperties];

	GDGRecordHandlers *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *afterSetHandlers = handler.afterSetHandlers[propertyName];
	if (afterSetHandlers == nil)
		handler.afterSetHandlers[propertyName] = afterSetHandlers = [NSMutableArray array];

	[afterSetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

+ (void)addBeforeGetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName
{
	[self trackProperties];

	GDGRecordHandlers *handler = GDGEntityHandlerForClass(self);

	NSMutableArray *beforeGetHandlers = handler.beforeGetHandlers[propertyName];
	if (beforeGetHandlers == nil)
		handler.beforeGetHandlers[propertyName] = beforeGetHandlers = [NSMutableArray array];

	[beforeGetHandlers addObject:GDGEntityPropertyHandler(hasFilledHandler)];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
	if (self == object)
		return YES;

	if (![object isKindOfClass:[self class]])
		return NO;

	return [self isEqualToRecord:object];
}

- (BOOL)isEqualToRecord:(GDGRecord *)record
{
	return [record isKindOfClass:[self class]]
			&& self.id != nil
			&& record.id != nil
			&& [self.id isEqual:record.id];
}

- (NSUInteger)hash
{
	return ([self.id hash] ^ [NSStringFromClass(self.class) hash]) * 31u;
}

@end
