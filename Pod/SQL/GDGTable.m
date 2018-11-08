//
//  GDGTable.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import "GDGTable.h"
#import "GDGTable_Package.h"
#import "CIRResultSet.h"
#import "GDGColumn.h"

@implementation GDGTable

- (void)dealloc
{
	_columns = nil;
}

- (instancetype)initWithTableName:(NSString *)tableName columns:(NSArray <GDGColumn *> *)columns
{
	if (self = [super init])
	{
		_name = tableName;
		_columns = columns;
	}

	return self;
}

- (instancetype)init
{
	@throw [NSException exceptionWithName:@"Table initialization exception"
	                               reason:@"Use GDGConnection's -tableWithName:error: method to initialize a table instead"
	                             userInfo:nil];
}

#pragma mark - GoldDigger source

- (NSString *)identifier
{
	return _alias ?: _name;
}

#pragma mark - Table operations
#pragma mark Strings

- (NSString *)insertStringForColumns:(NSArray <NSString *> *)columns
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", self.identifier];

	NSString *valuesString = [[columns map:^NSString *(NSString *str) {
		return [NSString stringWithFormat:@":%@", str];
	}] join:@", "];

	[mutableString appendFormat:@"%@) VALUES (%@)", [columns join:@", "], valuesString];

	return mutableString;
}

- (NSString *)updateStringForColumns:(NSArray <NSString *> *)columns condition:(NSString *)condition
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", self.identifier];

	NSString *columnsString = [[columns map:^id(NSString *str) {
		return [str stringByAppendingString:[NSString stringWithFormat:@" = :%@", str]];
	}] join:@", "];

	[mutableString appendFormat:@"%@ WHERE ", columnsString];

	NSArray *primaryKeys = [[self.columns select:^BOOL(GDGColumn *column) {
		return column.primaryKey > 0;
	}] sortBy:@"primaryKey"];

	NSString *primaryKeysCondition = [[primaryKeys map:^NSString *(GDGColumn *primaryKey) {
		return [NSString stringWithFormat:@"%@.%@ = :%@", self.identifier, primaryKey.name, primaryKey.name];
	}] join:@" AND "];

	NSString *conditions = condition.length == 0 ? primaryKeysCondition :
			[NSString stringWithFormat:@"(%@) AND (%@)", primaryKeysCondition, condition];

	[mutableString appendString:conditions];

	return mutableString;
}

- (NSString *)updateStringForColumns:(NSArray <NSString *> *)columns
{
	return [self updateStringForColumns:columns condition:nil];
}

- (NSString *)deleteString
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE", self.identifier];
	
	NSArray *primaryKeys = [[self.columns select:^BOOL(GDGColumn *column) {
		return column.primaryKey > 0;
	}] sortBy:@"primaryKey"];
	
	for (GDGColumn *primaryKey in primaryKeys) {
		[mutableString appendFormat:@" %@.%@ = ? AND", self.identifier, primaryKey.name];
	}
	
	[mutableString replaceCharactersInRange:NSMakeRange(mutableString.length - 4, 4) withString:@""];
	
	return mutableString;
}

#pragma mark - Keyed subscript

- (GDGColumn *)objectForKeyedSubscript:(NSString *)columnName
{
	return [self.columns find:^BOOL(GDGColumn *column) {
		return [column.name isEqualToString:columnName];
	}];
}

@end
