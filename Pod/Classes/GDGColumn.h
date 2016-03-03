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
	GDGColumnTypeNone
};

@interface GDGColumn : NSObject

@property (assign, readonly, nonatomic) GDGColumnType type;
@property (assign, readonly, nonatomic, getter=isPrimaryKey) BOOL primaryKey;
@property (assign, readonly, nonatomic, getter=isNotNull) BOOL notNull;
@property (strong, readonly, nonatomic) NSString *name;

+ (GDGColumnType)columnTypeFromTypeName:(NSString *)typeName;

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type primaryKey:(BOOL)primaryKey notNull:(BOOL)notNull;

- (NSString *)fullName;

@end
