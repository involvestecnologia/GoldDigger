//
//  GDGColumn.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import "GDGColumn.h"
#import "GDGSource.h"

@implementation GDGColumn

+ (GDGColumnType)columnTypeFromTypeName:(NSString *)typeName
{
	GDGColumnType type;

	if ([typeName caseInsensitiveCompare:@"integer"] == NSOrderedSame)
		type = GDGColumnTypeInteger;
	else if ([typeName caseInsensitiveCompare:@"float"] == NSOrderedSame)
		type = GDGColumnTypeFloat;
	else if ([typeName caseInsensitiveCompare:@"text"] == NSOrderedSame)
		type = GDGColumnTypeText;
	else if ([typeName caseInsensitiveCompare:@"blob"] == NSOrderedSame)
		type = GDGColumnTypeBlob;
	else if ([typeName caseInsensitiveCompare:@"date"] == NSOrderedSame)
		type = GDGColumnTypeDate;
	else if ([typeName caseInsensitiveCompare:@"double"] == NSOrderedSame)
		type = GDGColumnTypeDouble;
	else if ([typeName caseInsensitiveCompare:@"boolean"] == NSOrderedSame)
		type = GDGColumnTypeBoolean;
	else
		type = GDGColumnTypeNone;

	return type;
}

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type primaryKey:(BOOL)primaryKey notNull:(BOOL)notNull
{
	self = [super init];
	if (self)
	{
		_name = name;
		_type = type;
		_primaryKey = primaryKey;
		_notNull = notNull;
	}

	return self;
}

- (NSString *)fullName
{
	return [self.source.alias stringByAppendingFormat:@".%@", _name];
}

@end
