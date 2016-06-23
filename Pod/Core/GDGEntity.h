//
//  GDGEntity.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <Foundation/Foundation.h>

@class GDGEntityMap;

@interface GDGEntity : NSObject

@property (strong, nonatomic) id id;

+ (instancetype)entity;

- (BOOL)isEqualToEntity:(GDGEntity *)entity;

@end
