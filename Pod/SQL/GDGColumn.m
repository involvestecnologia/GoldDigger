//
//  GDGColumn.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import "GDGColumn.h"
#import "GDGSource.h"
#import "SQLTableSource.h"

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
		type = GDGColumnTypeNull;

	return type;
}

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type
{
	return [self initWithName:name type:type primaryKey:NO notNull:NO];
}

- (instancetype)initWithName:(NSString *)name type:(GDGColumnType)type primaryKey:(int)primaryKey notNull:(BOOL)notNull
{
	if (self = [super init])
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
	return [self.table.identifier stringByAppendingFormat:@".%@", _name];
}

- (GDGColumn *)copyWithZone:(nullable NSZone *)zone
{
	GDGColumn *copy = [(GDGColumn *) [[self class] allocWithZone:zone] init];

	copy.name = _name;
	copy.type = _type;
	copy.table = _table;
	copy.primaryKey = _primaryKey;
	copy.notNull = _notNull;

	return copy;
}

@end
