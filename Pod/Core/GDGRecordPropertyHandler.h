//
// Created by Felipe Lobo on 2018-12-29.
//

#import <Foundation/Foundation.h>

@class GDGRecord;

@interface GDGEntityPropertyHandler : NSObject

@property (copy, nonatomic, nonnull) void (^block)(GDGRecord *, NSString *);

+ (instancetype)handlerWithBlock:(void (^ __nonnull)(GDGRecord *, NSString *))block;

- (nonnull instancetype)initWithBlock:(void (^ __nonnull)(GDGRecord *, NSString *))block;

- (void)invokeWithEntity:(GDGRecord *)entity
                property:(NSString *)propertyName;

@end
