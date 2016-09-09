//
//  GDGRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <Foundation/Foundation.h>
#import "GDGCondition.h"

@class GDGCondition;
@class GDGEntity;
@class GDGEntityMap;
@class GDGQuery;
@protocol GDGSource;

#define GDGRelationField(name, src)         [GDGRelationField relationFieldWithName:name source:src]

@interface GDGRelation : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) GDGEntityMap *map;
@property (strong, nonatomic) GDGEntityMap *relatedMap;
@property (strong, nonatomic) NSString *foreignProperty;
@property (strong, nonatomic) GDGCondition *condition;

- (instancetype)initWithName:(NSString *)name map:(GDGEntityMap *)map;

- (void)fill:(NSArray <GDGEntity *> *)entities selecting:(NSArray *)properties;

- (void)fill:(NSArray <GDGEntity *> *)entities fromQuery:(__kindof GDGQuery *)query;

- (void)hasBeenSetOnEntity:(GDGEntity *)entity;

- (BOOL)save:(GDGEntity *)entity error:(NSError **)error;

- (GDGCondition *)joinCondition;

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource;

@end

@interface GDGRelationField : NSObject <GDGConditionField>

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) id <GDGSource> source;

+ (instancetype)relationFieldWithName:(NSString *)name source:(id <GDGSource>)source;

- (NSString *)fullName;

@end
