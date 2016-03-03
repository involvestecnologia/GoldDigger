//
//  GDGEntity.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import "GDGEntity.h"

#import <objc/runtime.h>
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
	return self.id * 11;
}

#pragma mark - Property hacking

+ (void)autoFillProperties:(NSArray<NSString *> *)propertiesNames
{
	NSString *className = NSStringFromClass([self class]);

	id clazz = objc_getClass(className.UTF8String);

	for (NSString *propertyName in propertiesNames)
	{
		objc_property_t property = class_getProperty(clazz, propertyName.UTF8String);
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

	char type = property_getAttributes(property)[1];

#define SETTER_IMP_BLOCK(T) ^(GDGEntity* _self, T argument) { \
        [_self.db entity:_self hasFilledPropertyNamed:propertyName]; \
        ((void(*)(GDGEntity*, SEL, T)) setterImplementation)(_self, setterSelector, argument); \
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
		{
			block = SETTER_IMP_BLOCK(NSInteger);
			break;
		}
		case 'c':
		{
			block = SETTER_IMP_BLOCK(char);
			break;
		}
		case 'I':
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
		{
			block = GETTER_IMP_BLOCK(NSInteger);
			break;
		}
		case 'c':
		{
			block = GETTER_IMP_BLOCK(char);
			break;
		}
		case 'I':
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
