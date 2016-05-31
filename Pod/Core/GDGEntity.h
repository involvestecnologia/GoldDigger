//
//  GDGEntity.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <Foundation/Foundation.h>

@class GDGEntityMap;

@interface GDGEntity : NSObject

@property (strong, nonatomic) id id;

+ (instancetype)entity;

+ (void)addBeforeSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName;

+ (void)addAfterSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
               forProperty:(NSString *)propertyName;

+ (void)addBeforeGetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
                forProperty:(NSString *)propertyName;

- (BOOL)isEqualToEntity:(GDGEntity *)entity;

@end
