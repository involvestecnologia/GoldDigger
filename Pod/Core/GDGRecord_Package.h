//
//  GDGEntity_Package.h
//  AgilePromoter
//
//  Created by Felipe Lobo on 03/06/16.
//
//

#import "GDGRecord.h"

@interface GDGRecord ()

+ (void)addBeforeSetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

+ (void)addAfterSetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

+ (void)addBeforeGetHandler:(void (^)(GDGRecord *, NSString *))hasFilledHandler
		forProperty:(NSString *)propertyName;

@end