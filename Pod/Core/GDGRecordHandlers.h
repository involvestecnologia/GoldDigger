//
// Created by Felipe Lobo on 2018-12-29.
//

#import <Foundation/Foundation.h>

@interface GDGRecordHandlers : NSObject

@property (readonly, nonatomic, nonnull) NSMutableDictionary *beforeSetHandlers;
@property (readonly, nonatomic, nonnull) NSMutableDictionary *afterSetHandlers;
@property (readonly, nonatomic, nonnull) NSMutableDictionary *beforeGetHandlers;
@property (readonly, nonatomic, nonnull) NSArray<NSString *> *properties;

+ (nonnull instancetype)entityHandler;

- (instancetype)initWithProperties:(NSArray<NSString *> * __nonnull)properties;

@end
