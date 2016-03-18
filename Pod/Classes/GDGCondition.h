//
//  GDGCondition.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/8/16.
//

#import <Foundation/Foundation.h>

@class GDGQuery;
@class GDGColumn;

@interface GDGCondition : NSObject <NSCopying>

@property (copy, readonly, nonatomic) GDGCondition *(^build)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) GDGCondition *(^col)(GDGColumn *);
@property (copy, readonly, nonatomic) GDGCondition *(^cat)(GDGCondition *);
@property (copy, readonly, nonatomic) GDGCondition *(^func)(NSString *, NSArray<GDGColumn *> *);
@property (copy, readonly, nonatomic) GDGCondition *(^equals)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^gt)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^gte)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^lt)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^lte)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^notEquals)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^isNull)();
@property (copy, readonly, nonatomic) GDGCondition *(^isNotNull)();
@property (copy, readonly, nonatomic) GDGCondition *(^inText)(NSString *);
@property (copy, readonly, nonatomic) GDGCondition *(^inList)(NSArray<NSNumber *> *);
@property (copy, readonly, nonatomic) GDGCondition *(^inQuery)(GDGQuery *);
@property (copy, readonly, nonatomic) GDGCondition *(^DATE)(GDGColumn *);

+ (instancetype)builder;

- (GDGCondition *)build:(void (^)(GDGCondition *))builder;

- (GDGCondition *)and;

- (GDGCondition *)or;

- (GDGCondition *)openParentheses;

- (GDGCondition *)closeParentheses;

- (NSString *)visit;

- (BOOL)isEmpty;

@end
