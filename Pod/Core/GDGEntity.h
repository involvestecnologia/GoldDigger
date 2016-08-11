//
//  GDGEntity.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <Foundation/Foundation.h>

@class GDGEntityMap;

@interface NSObject (GDG)

+ (NSArray <NSValue *> *)gdg_propertyListFromClass:(Class)fromClass until:(Class)toClass;

@end

@interface GDGEntity : NSObject

@property (strong, nonatomic) id id;

+ (instancetype)entity;

- (BOOL)isEqualToEntity:(GDGEntity *)entity;

@end
