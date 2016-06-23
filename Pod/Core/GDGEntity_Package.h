//
//  GDGEntity_Package.h
//  AgilePromoter
//
//  Created by Felipe Lobo on 03/06/16.
//
//

#import "GDGEntity.h"

@interface GDGEntity ()

+ (void)addBeforeSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

+ (void)addAfterSetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

+ (void)addBeforeGetHandler:(void (^)(GDGEntity *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

@end