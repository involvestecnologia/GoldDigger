//
//  GDGCondition+Entity.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/9/16.
//

#import <ObjectiveSugar/NSString+ObjectiveSugar.h>
#import <objc/runtime.h>
#import "GDGCondition+Entity.h"
#import "GDGCondition_Protected.h"

@implementation GDGCondition (Entity)

- (GDGCondition *(^)(NSString *))prop
{
	GDGCondition *(^prop)(NSString *) = objc_getAssociatedObject(self, _cmd);
	if (prop == nil)
	{
		__weak typeof(self) weakSelf = self;

		prop = ^GDGCondition *(NSString *propertyName) {
			return weakSelf.field(weakSelf.map[propertyName]);
		};

		objc_setAssociatedObject(self, _cmd, prop, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}

	return prop;
}

- (SQLEntityMap *)map
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setMap:(SQLEntityMap *)map
{
	objc_setAssociatedObject(self, @selector(map), map, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end