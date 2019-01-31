//
//  GDGRecord.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <Foundation/Foundation.h>

@class GDGMapping;

@interface GDGRecord : NSObject

@property (strong, nonatomic, nonnull) GDGMapping *mapping;

+ (nonnull instancetype)recordClass:(Class)class usingTableMapping:(GDGMapping *(^)(NSArray *))tap;

- (BOOL)fill:(void (^ __nonnull)(GDGRecord * __nullable))fillHandler error:(NSError ** __nullable)error;

- (BOOL)isEqualToRecord:(GDGRecord * __nonnull)entity;

@end
