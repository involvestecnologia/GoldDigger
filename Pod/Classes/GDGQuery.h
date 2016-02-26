//
//  GDGQuery.h
//  Pods
//
//  Created by Pietro Caselani on 2/15/16.
//
//

#import <Foundation/Foundation.h>

@class GDGConditionBuilder;
@class GDGSource;
@class GDGColumn;
@class GDGEntity;

@interface GDGQuery : NSObject

@property (copy, readonly, nonatomic) __kindof GDGQuery* (^select)(NSArray<NSString*>*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^from)(GDGSource*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^fromTable)(NSString*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^join)(__kindof GDGSource*, NSString*, NSString*, NSArray<NSString*>*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^joinTable)(NSString*, NSString*, NSString*, NSArray<NSString*>*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^where)(void (^)(GDGConditionBuilder*));
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^asc)(NSString*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^desc)(NSString*);
@property (copy, readonly, nonatomic) __kindof GDGQuery* (^limit)(int);
@property (strong, readonly, nonatomic) NSArray<NSString*>* projection;
@property (readonly, nonatomic) NSDictionary<NSString*, id>* arguments;
@property (readonly, nonatomic) GDGConditionBuilder *whereBuilder;
@property (readonly, nonatomic) GDGSource *source;

- (instancetype)initWithSource:(__kindof GDGSource*)source;
- (instancetype)initWithTableName:(NSString*)tableName;

- (GDGColumn*)findColumnNamed:(NSString*)columnName;

- (NSArray<id>*)pluck;
- (NSArray<id>*)rawObjects;
- (NSString*)visit;
- (NSUInteger)count;
- (instancetype)distinct;
- (instancetype)clearProjection;
- (instancetype)clearOrder;
- (NSArray<__kindof GDGEntity*>*)array;
- (__kindof GDGEntity*)object;

@end
