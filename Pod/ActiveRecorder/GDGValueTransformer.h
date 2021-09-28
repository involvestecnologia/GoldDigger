//
//  GDGValueTransformer.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <Foundation/Foundation.h>

@interface GDGValueTransformer : NSValueTransformer

@property (copy, nonatomic) id (^forwardHandler)(id);
@property (copy, nonatomic) id (^reverseHandler)(id);

+ (instancetype)transformerForward:(id (^)(id))forwardHandler reverse:(id (^)(id))reverseHandler;

- (instancetype)initWithForwardHandler:(id (^)(id))forwardHandler reverseHandler:(id (^)(id))reverseHandler;

@end
