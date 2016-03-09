//
//  GDGValueTransformer.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <Foundation/Foundation.h>

@interface GDGValueTransformer : NSValueTransformer

@property (copy, nonatomic) id (^fromDatabase)(id);
@property (copy, nonatomic) id (^toDatabase)(id);

+ (instancetype)transformerFrom:(id (^)(id))fromDatabaseHandler to:(id (^)(id))toDatabaseHandler;

- (instancetype)initWithFromDatabaseHandler:(id (^)(id))fromDatabaseHandler toDatabaseHandler:(id (^)(id))toDatabaseHandler;

@end
