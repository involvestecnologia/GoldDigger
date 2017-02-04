//
//  GDGColumn.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import <Foundation/Foundation.h>
#import "GDGCondition.h"

@class SQLTableSource;

typedef NS_ENUM(NSUInteger, GDGColumnType)
{
		GDGColumnTypeText,
		GDGColumnTypeInteger,
		GDGColumnTypeFloat,
		GDGColumnTypeBlob,
		GDGColumnTypeDate,
		GDGColumnTypeDouble,
		GDGColumnTypeBoolean,
		GDGColumnTypeNull
};

@interface GDGColumn : NSObject <NSCopying, GDGConditionField>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) SQLTableSource *table;
@property (assign, nonatomic) GDGColumnType type;
@property (assign, nonatomic) int primaryKey;
@property (assign, nonatomic, getter=isNotNull) BOOL notNull;

+ (GDGColumnType)columnTypeFromTypeName:(NSString *)typeName;

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type;

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type primaryKey:(int)primaryKey notNull:(BOOL)notNull;

- (NSString *)fullName;

@end
