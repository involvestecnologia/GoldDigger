//
//  GDGConditionBuilder.h
//  Pods
//
//  Created by Pietro Caselani on 2/8/16.
//
//

#import <Foundation/Foundation.h>

@class GDGQuery;
@class GDGColumn;

@interface GDGConditionBuilder : NSObject

@property(copy, readonly, nonatomic) GDGConditionBuilder *(^build)(void (^)(GDGConditionBuilder *));
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^col)(GDGColumn *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^cat)(GDGConditionBuilder *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^equals)(id);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^notEquals)(id);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^isNull)();
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^isNotNull)();
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^equalsDate)(NSString *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^equalsCol)(GDGColumn *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^inText)(NSString *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^inList)(NSArray<NSNumber *> *);
@property(copy, readonly, nonatomic) GDGConditionBuilder *(^inQuery)(GDGQuery *);

+ (instancetype)builder;

- (GDGConditionBuilder *)build:(void (^)(GDGConditionBuilder *))builder;

- (GDGConditionBuilder *)and;

- (GDGConditionBuilder *)or;

- (GDGConditionBuilder *)openParentheses;

- (GDGConditionBuilder *)closeParentheses;

- (NSString *)visit;

@end
