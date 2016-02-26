//
//  GDGValueAdapter.h
//  Pods
//
//  Created by Pietro Caselani on 1/26/16.
//
//

#import <Foundation/Foundation.h>

@interface GDGValueAdapter : NSValueTransformer

@property (copy, nonatomic) id (^fromDatabase)(id);
@property (copy, nonatomic) id (^toDatabase)(id);

- (instancetype)initWithFromDatabaseHandler:(id (^)(id))fromDatabaseHandler toDatabaseHandler:(id (^)(id))toDatabaseHandler;

@end
