//
//  GDGEntitySettings+Relations.m
//  Pods
//
//  Created by Pietro Caselani on 3/14/16.
//

#import "GDGEntitySettings+Relations.h"

#import <objc/runtime.h>

@implementation GDGEntitySettings (Relations)

- (NSMutableDictionary *)relationNameDictionary
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setRelationNameDictionary:(NSMutableDictionary *)relationNameDictionary
{
	objc_setAssociatedObject(self, @selector(relationNameDictionary), relationNameDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)valueTransformerDictionary
{
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setValueTransformerDictionary:(NSMutableDictionary *)valueTransformerDictionary
{
	objc_setAssociatedObject(self, @selector(valueTransformerDictionary), valueTransformerDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end