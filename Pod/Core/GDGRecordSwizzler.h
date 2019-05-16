//
// Created by Felipe Lobo on 2019-05-15.
//

#import <Foundation/Foundation.h>

@class GDGRecordHandlers;

@interface GDGRecordSwizzler : NSObject

- (instancetype)initWithProperties:(NSArray <NSValue *> *__nonnull)properties ofClass:(Class)class;

- (BOOL)swizzleProperties:(NSError **)error;

@end