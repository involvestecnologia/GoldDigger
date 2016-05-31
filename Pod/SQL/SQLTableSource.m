//
//  SQLTableSource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <SQLAid/CIRDatabase.h>
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import "SQLTableSource.h"

#import "CIRResultSet.h"
#import "GDGDatabaseProvider.h"
#import "GDGColumn.h"
#import "SQLQuery.h"

#define kDEFAULT_ERROR_CODE         10

@implementation SQLTableSource

- (instancetype)initWithTableName:(NSString *)tableName
                 databaseProvider:(id <GDGDatabaseProvider>)databaseProvider;
{
	if (self = [super init])
	{
		_databaseProvider = databaseProvider;
		_name = tableName;

		CIRResultSet *resultSet = [databaseProvider.database executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName]];

		NSMutableArray <GDGColumn *> *mutableColumns = [NSMutableArray array];
		while ([resultSet next])
		{
			NSString *name = [resultSet textAtIndex:1];
			GDGColumnType type = [GDGColumn columnTypeFromTypeName:[resultSet textAtIndex:2]];
			BOOL notNull = [resultSet boolAtIndex:3];
			BOOL primaryKey = [resultSet boolAtIndex:5];

			GDGColumn *column = [[GDGColumn alloc] initWithName:name type:type primaryKey:primaryKey notNull:notNull];
			column.table = self;

			[mutableColumns addObject:column];
		}

		_columns = [NSArray arrayWithArray:mutableColumns];
	}

	return self;
}

- (NSNumber *)lastInsertedId
{
	return @([_databaseProvider.database lastInsertedId]);
}

#pragma mark - GoldDigger source

- (NSString *)identifier
{
	return _alias ?: _name;
}

- (NSArray <NSDictionary *> *)eval:(SQLQuery *)query
{
	query = query.copy;

	CIRResultSet *resultSet = [_databaseProvider.database executeQuery:query.visit withNamedParameters:query.args];
	NSMutableArray <NSDictionary *> *mutableArray = [NSMutableArray array];

	while ([resultSet next])
	{
		NSUInteger dotIndex = 0;
		NSInteger columnIndex = 0;
		NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithCapacity:resultSet.columnCount];
		NSString *name = nil;

		for (name in query.projection)
		{
			dotIndex = [name rangeOfString:@"."].location;
			name = dotIndex != NSNotFound ? [name substringFromIndex:dotIndex + 1] : name;
			columnIndex = [resultSet columnIndexWithName:name];

			mutableDictionary[name] = resultSet[(NSUInteger) columnIndex];
		}

		[mutableArray addObject:[NSDictionary dictionaryWithDictionary:mutableDictionary]];
	}

	return [NSArray arrayWithArray:mutableArray];
}

#pragma mark Other eval's

- (NSArray *)evalByTuple:(SQLQuery *)query
{
	NSMutableArray *objects = [NSMutableArray array];

	CIRResultSet *resultSet = [self.databaseProvider.database executeQuery:[query visit] withNamedParameters:query.args];

	while ([resultSet next])
		[objects addObject:[self rawObjectWithResultSet:resultSet]];

	return [NSArray arrayWithArray:objects];
}

- (id)rawObjectWithResultSet:(CIRResultSet *)resultSet
{
	id object;
	const int columnCount = [resultSet columnCount];

	if (columnCount == 0)
		object = nil;
	else if (columnCount == 1)
		object = resultSet[0];
	else
	{
		NSMutableArray *objects = [NSMutableArray array];

		for (NSUInteger i = 0; i < columnCount; i++)
			[objects addObject:resultSet[i]];

		object = [NSArray arrayWithArray:objects];
	}

	return object;
}

- (NSArray *)evalByColumn:(SQLQuery *)query
{
	NSMutableArray *objects = [NSMutableArray array];
	CIRResultSet *resultSet = [self.databaseProvider.database executeQuery:[query visit] withNamedParameters:query.args];

	const int columnCount = [resultSet columnCount];

	for (NSUInteger i = 0; i < columnCount && columnCount > 1; i++)
		objects[i] = [NSMutableArray array];

	while ([resultSet next])
		if (columnCount == 1)
			[objects addObject:resultSet[0]];
		else
			for (NSUInteger i = 0; i < columnCount; i++)
				[objects[i] addObject:resultSet[i]];

	return [NSArray arrayWithArray:objects];
}

#pragma mark - Table operations
#pragma mark Strings

- (NSString *)insertStringForColumns:(NSArray <NSString *> *)columns
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", self.identifier];

	NSString *valuesString = [[columns map:^id(id obj) {
		return @"?";
	}] join:@", "];

	[mutableString appendFormat:@"%@) VALUES (%@)", [columns join:@", "], valuesString];

	return mutableString;
}

- (NSString *)updateStringForColumns:(NSArray <NSString *> *)columns
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", self.identifier];

	NSString *columnsString = [[columns map:^id(NSString *str) {
		return [str stringByAppendingString:@" = ?"];
	}] join:@", "];

	[mutableString appendFormat:@"%@ WHERE %@.id = ?", columnsString, self.identifier];

	return mutableString;
}

- (NSString *)deleteString
{
	return [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = ?", self.identifier];
}

#pragma mark Prepare

- (CIRStatement *)insertStatementForColumns:(NSArray <NSString *> *)columns
{
	return [_databaseProvider.database prepareStatement:[self insertStringForColumns:columns]];
}

- (CIRStatement *)updateStatementForColumns:(NSArray <NSString *> *)columns
{
	return [_databaseProvider.database prepareStatement:[self updateStringForColumns:columns]];
}

- (CIRStatement *)deleteStatement
{
	return [_databaseProvider.database prepareStatement:[self deleteString]];
}

#pragma mark Execute

- (BOOL)insert:(NSArray <NSString *> *)columns params:(NSArray *)params error:(NSError **)error
{
	BOOL succeeded = [_databaseProvider.database executeUpdate:[self insertStringForColumns:columns] withParameters:params];
	if (!succeeded && error)
		*error = [NSError errorWithDomain:@"com.CopyIsRight.GoldDigger" code:kDEFAULT_ERROR_CODE
		                         userInfo:@{NSLocalizedDescriptionKey : _databaseProvider.database.lastErrorMessage}];

	return succeeded;
}

- (BOOL)update:(NSArray <NSString *> *)columns params:(NSArray *)params error:(NSError **)error
{
	BOOL succeeded = [_databaseProvider.database executeUpdate:[self updateStringForColumns:columns] withParameters:params];
	if (!succeeded)
		*error = [NSError errorWithDomain:@"com.CopyIsRight.GoldDigger" code:kDEFAULT_ERROR_CODE
		                         userInfo:@{NSLocalizedDescriptionKey : _databaseProvider.database.lastErrorMessage}];

	return succeeded;
}

- (BOOL)delete:(id)primaryKey error:(NSError **)error
{
	BOOL succeeded = [_databaseProvider.database executeUpdate:[self deleteString] withParameters:@[primaryKey]];
	if (!succeeded)
		*error = [NSError errorWithDomain:@"com.CopyIsRight.GoldDigger" code:kDEFAULT_ERROR_CODE
		                         userInfo:@{NSLocalizedDescriptionKey : _databaseProvider.database.lastErrorMessage}];

	return succeeded;
}

#pragma mark

#pragma mark - Copying

- (SQLTableSource *)copyWithZone:(nullable NSZone *)zone
{
	typeof(self) copy = [(SQLTableSource *)[self.class allocWithZone:zone] init];
	copy->_name = [_name copy];
	copy->_alias = [_alias copy];
	copy->_databaseProvider = _databaseProvider;

	NSMutableArray *mutableColumns = [NSMutableArray arrayWithCapacity:self->_columns.count];
	for (GDGColumn *column in self->_columns)
	{
		GDGColumn *columnCopy = [column copy];
		columnCopy.table = copy;

		[mutableColumns addObject:columnCopy];
	}

	copy->_columns = [NSArray arrayWithArray:mutableColumns];

	return copy;
}

#pragma mark - Keyed subscript

- (GDGColumn *)objectForKeyedSubscript:(NSString *)columnName
{
	return [self.columns find:^BOOL(GDGColumn *column) {
		return [column.name isEqualToString:columnName];
	}];
}

@end
