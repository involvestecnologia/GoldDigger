//
//  GDGEntity.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//  Copyright © 2016 Involves. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GDGEntityManager;
@class GDGEntity;

@protocol GDGEntityFillDelegate <NSObject>

- (void)entity:(GDGEntity*)entity hasFilledPropertyNamed:(NSString*)propertyName;
- (void)entity:(GDGEntity*)entity requestToFillPropertyNamed:(NSString*)propertyName;

@end

@interface GDGEntity : NSObject

@property (assign, nonatomic) NSUInteger id;
@property (readonly, nonatomic) GDGEntityManager<GDGEntityFillDelegate>* db;

- (BOOL)save;
- (BOOL)drop;

- (BOOL)isEqualToEntity:(GDGEntity *)entity;

+ (void)autoFillProperties:(NSArray<NSString*>*)propertiesNames;

@end
