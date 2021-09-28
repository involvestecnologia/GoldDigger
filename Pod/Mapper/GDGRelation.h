//
//  GDGRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <Foundation/Foundation.h>
#import "GDGCondition.h"

@class GDGCondition;
@class GDGRecord;
@class GDGQuery;
@class GDGMapping;
@protocol GDGSource;

@interface GDGRelation : NSObject

@property (readonly, nonatomic, nonnull) NSString *name;
@property (readonly, nonatomic, nonnull) GDGMapping *mapping;
@property (strong, nonatomic, nullable) GDGMapping *relatedMapping;
@property (strong, nonatomic, nullable) NSString *foreignProperty;
@property (strong, nonatomic, nullable) GDGCondition *condition;

- (nonnull instancetype)initWithName:(NSString * __nonnull)name mapping:(GDGMapping * __nonnull)mapping;

- (void)hasBeenSetOnEntity:(GDGRecord * __nonnull)entity;

- (BOOL)save:(GDGRecord * __nonnull)entity error:(NSError ** __nullable)error;

- (BOOL)fill:(NSArray <GDGRecord *> * __nonnull)entities selecting:(NSArray * __nonnull)properties error:(NSError ** __nullable)error;

- (BOOL)fill:(NSArray <GDGRecord *> * __nonnull)entities fromQuery:(GDGQuery * __nonnull)query error:(NSError ** __nullable)error;

- (nullable GDGCondition *)joinCondition;

@end
