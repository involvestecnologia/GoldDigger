//
// Created by Felipe Lobo on 2018-12-29.
//

#import <Foundation/Foundation.h>

@protocol GDGSource;
@protocol GDGConditionField;

#define GDGRelationField(name, src)         [GDGRelationField relationFieldWithName:name source:src]

@interface GDGRelationField : NSObject <GDGConditionField>

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) id <GDGSource> source;

+ (instancetype)relationFieldWithName:(NSString *)name source:(id <GDGSource>)source;

- (NSString *)fullName;

@end