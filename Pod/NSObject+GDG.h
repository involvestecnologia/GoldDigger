//
// Created by Felipe Lobo on 2018-12-29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (GDG)

+ (char)typeFromPropertyName:(NSString *)propertyName;

+ (NSArray <NSValue *> *)gdg_propertyListFromClass:(Class)fromClass until:(Class)toClass;

@end

NS_ASSUME_NONNULL_END
