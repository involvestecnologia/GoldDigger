//
//  GDGQuery_Protected.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import "GDGQuery.h"

@interface GDGQuery ()

@property (copy, readwrite, nonatomic) __kindof GDGQuery *(^select)(NSArray<NSString *> *);
@property (copy, readwrite, nonatomic) __kindof GDGQuery *(^asc)(NSString *);
@property (copy, readwrite, nonatomic) __kindof GDGQuery *(^desc)(NSString *);

@property (strong, nonatomic) NSMutableArray<NSString *> *mutableProjection;
@property (strong, nonatomic) NSMutableArray<NSString *> *orderList;

@property (readwrite, nonatomic) GDGConditionBuilder *conditionBuilder;
@property (readwrite, nonatomic) GDGSource *source;

- (NSDictionary<NSString *, id> *)arguments;

@end
