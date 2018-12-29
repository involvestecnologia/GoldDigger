//
//  GDGCondition.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/8/16.
//

#import <Foundation/Foundation.h>

@class GDGQuery;
@class GDGColumn;

@protocol GDGConditionField <NSObject>

- (NSString *)fullName;

@end

@interface GDGCondition : NSObject <NSCopying>

@property (readonly, nonatomic) NSArray *tokens;
@property (readonly, nonatomic) NSDictionary *fields;
@property (readonly, nonatomic) NSDictionary *args;
@property (copy, readonly, nonatomic) GDGCondition *(^build)(void (^)(GDGCondition *));
@property (copy, readonly, nonatomic) GDGCondition *(^field)(id <GDGConditionField>);
@property (copy, readonly, nonatomic) GDGCondition *(^cat)(GDGCondition *);
@property (copy, readonly, nonatomic) GDGCondition *(^equals)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^gt)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^gte)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^lt)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^lte)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^notEquals)(id);
@property (copy, readonly, nonatomic) GDGCondition *(^in)(id);

+ (instancetype)builder;

- (GDGCondition *)build:(void (^)(GDGCondition *))builder;

- (GDGCondition *)and;

- (GDGCondition *)or;

- (GDGCondition *)null;

- (GDGCondition *)notNull;

- (NSString *)visit;

- (BOOL)isEmpty;

@end
