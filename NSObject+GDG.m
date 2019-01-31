//
// Created by Felipe Lobo on 2018-12-29.
//

#import <objc/runtime.h>
#import "NSObject+GDG.h"

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

+ (char)typeFromPropertyName:(NSString *)propertyName
{
	objc_property_t property = class_getProperty(self, propertyName.UTF8String);

	return property_getAttributes(property)[1];
}

@end
