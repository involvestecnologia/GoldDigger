//
//  GDGQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import <Foundation/Foundation.h>

@class GDGCondition;
@class GDGSource;
@class GDGColumn;
@protocol GDGFilter;

@interface GDGQuery : NSObject <NSCopying>

@property (copy, readonly, nonatomic) __kindof GDGQuery *(^select)(NSArray<NSString *> *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^from)(GDGSource *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^fromTable)(NSString *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^join)(__kindof GDGSource *, NSString *, GDGCondition *, NSArray<NSString *> *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^joinTable)(NSString *, NSString *, GDGCondition *, NSArray<NSString *> *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^where)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^asc)(NSString *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^desc)(NSString *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^limit)(int);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^filter)(NSArray<id <GDGFilter>> *);
@property (readonly, nonatomic) NSArray<NSString *> *projection;
@property (readonly, nonatomic) NSDictionary<NSString *, id> *arguments;
@property (readonly, nonatomic) GDGCondition *condition;
@property (readonly, nonatomic) GDGSource *source;

- (instancetype)initWithSource:(__kindof GDGSource *)source;

- (GDGColumn *)findColumnNamed:(NSString *)columnName;

- (NSArray<id> *)pluck;

- (NSArray<id> *)raw;

- (NSString *)visit;

- (NSUInteger)count;

- (instancetype)distinct;

- (instancetype)clearProjection;

- (instancetype)clearOrder;

@end
