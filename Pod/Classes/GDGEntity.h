//
//  GDGEntity.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import <Foundation/Foundation.h>

@class GDGEntityManager;
@class GDGEntity;
@class GDGColumn;

@protocol GDGEntityFillDelegate <NSObject>

- (void)entity:(GDGEntity *)entity hasFilledPropertyNamed:(NSString *)propertyName;

- (void)entity:(GDGEntity *)entity requestToFillPropertyNamed:(NSString *)propertyName;

@end

@interface GDGEntity : NSObject

@property (assign, nonatomic) NSInteger id;
@property (readonly, nonatomic) GDGEntityManager <GDGEntityFillDelegate> *db;

+ (instancetype)entity;

+ (void)autoFillProperties:(NSArray<NSString *> *)propertiesNames;

- (BOOL)isEqualToEntity:(GDGEntity *)entity;

@end
