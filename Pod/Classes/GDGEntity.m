//
//  GDGEntity.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import "GDGEntity.h"

#import <objc/runtime.h>
#import <GoldDigger/GDGRelation.h>
#import "GDGEntityManager.h"

@implementation GDGEntity

@synthesize db = _db;

+ (instancetype)entity
{
	return [[self alloc] init];
}

- (GDGEntityManager *)db
{
	return _db ? _db : (_db = [[GDGEntityManager alloc] initWithEntity:self]);
}

#pragma mark - Equality

- (BOOL)isEqualToEntity:(GDGEntity *)entity
{
	return [entity isKindOfClass:[self class]] && self.id == entity.id;
}

- (BOOL)isEqual:(id)object
{
	if (self == object)
		return YES;

	return [self isEqualToEntity:object];
}

- (NSUInteger)hash
{
	return self.id * 11u;
}

#pragma mark - Property hacking

+ (void)autoFillProperties:(NSArray<NSString *> *)propertiesNames
{
	NSString *className = NSStringFromClass([self class]);

	id clazz = objc_getClass(className.UTF8String);

	for (NSString *propertyName in propertiesNames)
	{
		objc_property_t property = class_getProperty(clazz, propertyName.UTF8String);

		if (property == NULL)
			@throw [NSException exceptionWithName:@"Property not found exception" reason:[NSString stringWithFormat:@"Property named %@ does not exists", propertyName] userInfo:nil];

		[self overrideSetter:property forClass:clazz];
		[self overrideGetter:property forClass:clazz];
	}
}

+ (void)overrideSetter:(objc_property_t)property forClass:(Class)clazz
{
	NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

	char *cstrSignature = property_copyAttributeValue(property, "S");

	NSString *signature = cstrSignature == NULL ?
			[NSString stringWithFormat:@"set%@:", [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] uppercaseString]]] :
			@(cstrSignature);

	SEL setterSelector = NSSelectorFromString(signature);
	Method setter = class_getInstanceMethod(clazz, setterSelector);
	IMP setterImplementation = method_getImplementation(setter);

	const char *str = property_getAttributes(property);
	char type = str[1];

#define SETTER_IMP_BEGIN(T)	^(GDGEntity* _self, T argument) {
#define SETTER_IMP_END(T) [_self.db entity:_self hasFilledPropertyNamed:propertyName]; \
        ((void(*)(GDGEntity*, SEL, T)) setterImplementation)(_self, setterSelector, argument); \
	}
#define SETTER_IMP_BLOCK(T) SETTER_IMP_BEGIN(T) SETTER_IMP_END(T)

	id block;
	switch (type)
	{
		case '@':
		{
			block = SETTER_IMP_BEGIN(id)
				GDGRelation *relation = [_self.db relationNamed:propertyName];
				if (relation) [relation set:argument onEntity:_self];
				SETTER_IMP_END(id);
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

#undef SETTER_IMP_BEGIN
#undef SETTER_IMP_END
#undef SETTER_IMP_BLOCK

	IMP fillSetterImplementation = imp_implementationWithBlock(block);
	method_setImplementation(setter, fillSetterImplementation);

	free(cstrSignature);
}

+ (void)overrideGetter:(objc_property_t)property forClass:(Class)clazz
{
	NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

	char *cstrSignature = property_copyAttributeValue(property, "G");

	NSString *signature = cstrSignature == NULL ? propertyName : @(cstrSignature);

	SEL getterSelector = NSSelectorFromString(signature);
	Method getter = class_getInstanceMethod(clazz, getterSelector);
	IMP getterImplementation = method_getImplementation(getter);

	char type = property_getAttributes(property)[1];

#define GETTER_IMP_BLOCK(T) ^(GDGEntity* _self) { \
        [_self.db entity:_self requestToFillPropertyNamed:propertyName]; \
        return ((T(*)(GDGEntity*, SEL)) getterImplementation)(_self, getterSelector); \
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

@end
