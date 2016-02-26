//
//  GDGEntitySettings.h
//  RuntimeiOS
//
//  Created by Pietro Caselani on 1/21/16.
//  Copyright © 2016 Pietro Caselani. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GDGRelation;
@class GDGTableSource;

@interface GDGEntitySettings : NSObject

@property (assign, readonly, nonatomic) Class entityClass;
@property (strong, nonatomic) GDGTableSource* tableSource;
@property (strong, nonatomic) NSDictionary<NSString*, NSString*>* columnsDictionary;
@property (strong, nonatomic) NSDictionary<NSString*, NSString*>* propertiesDictionary;

- (instancetype)initWithEntityClass:(Class)entityClass;

- (void)addValueAdpter:(NSValueTransformer*)valueAdapter forPropertyNamed:(NSString*)propertyName;

@end
