//
// Created by Felipe Lobo on 2019-05-16.
//

#import <Foundation/Foundation.h>

@class GDGMapping;

@interface GDGObjectFiller : NSObject

- (instancetype)initWithConnection:(GDGConnection *)connection;

- (BOOL)fill:(id)object withMapping:(GDGMapping *)mapping error:(NSError **)error;

@end
