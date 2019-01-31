//
// Created by Felipe Lobo on 2018-12-29.
//

#import <Foundation/Foundation.h>

@interface NSObject (GDG)

+ (char)typeFromPropertyName:(NSString * __nonnull)propertyName;

+ (NSArray <NSValue *> * __nonnull)gdg_propertyListFromClass:(Class)fromClass until:(Class)toClass;

@end
