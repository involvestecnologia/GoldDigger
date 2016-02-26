//
//  GDGConditionBuilder+EntityQuery.m
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGConditionBuilder+EntityQuery.h"

#import <objc/runtime.h>
#import "GDGEntityQuery.h"
#import "GDGEntityManager.h"

@implementation GDGConditionBuilder (EntityQuery)

- (instancetype)initWithEntityQuery:(GDGEntityQuery *)entityQuery
{
	if (self = [super init])
	{
		self.query = entityQuery;
	}

	return self;
}

- (GDGEntityQuery *)query
{
	return objc_getAssociatedObject(self, @selector(query));
}

- (void)setQuery:(GDGEntityQuery *)query
{
	objc_setAssociatedObject(self, @selector(query), query, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (GDGConditionBuilder *(^)(NSString*))prop
{
	GDGConditionBuilder *(^prop)(NSString *) = objc_getAssociatedObject(self, @selector(prop));
	if (prop == nil) {
		__weak typeof(self) weakSelf = self;
		
		prop = ^GDGConditionBuilder* (NSString *property) {
			GDGEntityQuery *query = weakSelf.query;
			
			NSInteger dotIndex = [property rangeOfString:@"."].location;
			
			return weakSelf.col([query.manager columnForProperty:dotIndex == NSNotFound ? property : [property substringFromIndex:(NSUInteger) (dotIndex + 1)]]);
		};
		
		objc_setAssociatedObject(self, @selector(prop), prop, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}
	
	return prop;
}

@end
