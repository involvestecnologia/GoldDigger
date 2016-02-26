//
//  GDGColumn.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//  Copyright © 2016 Involves. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GDGColumnType) {
	GDGColumnTypeInteger,
	GDGColumnTypeFloat,
	GDGColumnTypeText,
	GDGColumnTypeBlob,
	GDGColumnTypeDate,
	GDGColumnTypeDouble,
	GDGColumnTypeBoolean,
	GDGColumnTypeNull
};

GDGColumnType GDGColumnFindColumnTypeByName(NSString* typeName);

@interface GDGColumn : NSObject

@property (assign, readonly, nonatomic) GDGColumnType type;
@property (assign, readonly, nonatomic, getter=isPrimaryKey) BOOL primaryKey;
@property (assign, readonly, nonatomic, getter=isNotNull) BOOL notNull;
@property (strong, readonly, nonatomic) NSString* name;

- (instancetype)initWithName:(NSString*)name type:(GDGColumnType)type primaryKey:(BOOL)primaryKey notNull:(BOOL)notNull;

- (NSString*)fullName;

@end
