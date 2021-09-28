//
//  GDGCondition_Protected.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/19/16.
//

#import "GDGCondition.h"

@class GDGQuery;

@interface GDGCondition ()

@property (strong, nonatomic) id context;
@property (readwrite, nonatomic) NSMutableArray<NSString *> *mutableTokens;
@property (readwrite, nonatomic) NSMutableDictionary<NSString *, id <GDGConditionField>> *mutableFields;
@property (readwrite, nonatomic) NSMutableDictionary<NSString *, id> *mutableArgs;

@property (copy, readwrite, nonatomic) GDGCondition *(^build)(void (^)(GDGCondition *));
@property (copy, readwrite, nonatomic) GDGCondition *(^field)(id <GDGConditionField>);
@property (copy, readwrite, nonatomic) GDGCondition *(^cat)(GDGCondition *);
@property (copy, readwrite, nonatomic) GDGCondition *(^equals)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^gt)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^gte)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^lt)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^lte)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^notEquals)(id);
@property (copy, readwrite, nonatomic) GDGCondition *(^in)(id);

@end
