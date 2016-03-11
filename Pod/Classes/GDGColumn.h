//
//  GDGColumn.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import <Foundation/Foundation.h>

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

@interface GDGColumn : NSObject <NSCopying>

@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) GDGColumnType type;
@property (assign, nonatomic, getter=isPrimaryKey) BOOL primaryKey;
@property (assign, nonatomic, getter=isNotNull) BOOL notNull;

+ (GDGColumnType)columnTypeFromTypeName:(NSString *)typeName;

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type;

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type primaryKey:(BOOL)primaryKey notNull:(BOOL)notNull;

- (NSString *)fullName;

@end
