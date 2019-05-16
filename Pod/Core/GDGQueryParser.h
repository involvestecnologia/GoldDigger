//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>
#import "GDGRawQuery.h"

@class GDGQuery;

@interface GDGQueryParser : NSObject

- (nullable GDGRawQuery *)parse:(GDGQuery * __nonnull)query error:(NSError ** __nullable)error;

@end
