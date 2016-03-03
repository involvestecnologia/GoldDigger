//
//  GDGEntitySettings.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/21/16.
//

#import <Foundation/Foundation.h>

@class GDGRelation;
@class GDGTableSource;

@interface GDGEntitySettings : NSObject

@property (assign, readonly, nonatomic) Class entityClass;
@property (strong, nonatomic) GDGTableSource *tableSource;
@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *columnsDictionary;
@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *propertiesDictionary;

- (instancetype)initWithEntityClass:(Class)entityClass;

@end
