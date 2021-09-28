//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>
#import "GDGParser.h"

@interface GDGRawQuery: NSObject

@property (readonly, nonatomic, nonnull) NSString *visit;
@property (readonly, nonatomic, nullable) NSArray *args;

- (nonnull instancetype)initWithQuery:(NSString *__nonnull)rawValue args:(NSArray *__nullable)args;

@end
