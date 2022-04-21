//
//  SQLTableSource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <SQLAids/CIRDatabase.h>
#import <SQLAids/CIRStatement.h>

#import <SQLite/SQLite.h> // TODO

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

		CIRResultSet *resultSet = [databaseProvider.database executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName] error:nil];

		NSMutableArray <GDGColumn *> *mutableColumns = [NSMutableArray array];
		while ([resultSet next:nil])
		{
			NSString *name = [resultSet textAtIndex:1];
			GDGColumnType type = [GDGColumn columnTypeFromTypeName:[resultSet textAtIndex:2]];
			BOOL notNull = [resultSet boolAtIndex:3];
			int primaryKey = [resultSet intAtIndex:5];

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

	CIRResultSet *resultSet = [_databaseProvider.database executeQuery:query.visit withNamedParameters:query.args error:nil];
	NSMutableArray <NSDictionary *> *mutableArray = [NSMutableArray array];

	while ([resultSet next:nil])
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

			mutableDictionary[name] = resultSet[(NSUInteger) columnIndex] ?: [NSNull null];
		}

		[mutableArray addObject:[NSDictionary dictionaryWithDictionary:mutableDictionary]];
	}

	return [NSArray arrayWithArray:mutableArray];
}

#pragma mark Other eval's

- (NSArray *)evalByTuple:(SQLQuery *)query
{
	NSMutableArray *objects = [NSMutableArray array];

	CIRResultSet *resultSet = [self.databaseProvider.database executeQuery:[query visit] withNamedParameters:query.args error:nil];

	while ([resultSet next:nil])
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
	CIRResultSet *resultSet = [self.databaseProvider.database executeQuery:[query visit] withNamedParameters:query.args error:nil];

	const int columnCount = [resultSet columnCount];

	for (NSUInteger i = 0; i < columnCount && columnCount > 1; i++)
		objects[i] = [NSMutableArray array];

	while ([resultSet next:nil])
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

#pragma mark Prepare

- (CIRStatement *)insertStatementForColumns:(NSArray <NSString *> *)columns
{
	return [_databaseProvider.database prepareStatement:[self insertStringForColumns:columns] error:nil];
}

- (CIRStatement *)updateStatementForColumns:(NSArray <NSString *> *)columns condition:(NSString *)condition
{
	NSString *updateSQL = [self updateStringForColumns:columns condition:condition];
	return [_databaseProvider.database prepareStatement:updateSQL error:nil];
}

- (CIRStatement *)updateStatementForColumns:(NSArray <NSString *> *)columns
{
	return [self updateStatementForColumns:columns condition:nil];
}

- (CIRStatement *)deleteStatement
{
	return [_databaseProvider.database prepareStatement:[self deleteString] error:nil];
}

#pragma mark Execute

- (NSString *)insert:(NSDictionary <NSString *, id> *)values
{
	NSString *stringBuff = [NSString new];
	sqlite3 *handler = _databaseProvider.database.handler;
	int code = 0;
	const char *errMessage;

	code = sqlite3_exec(handler, [@"SAVEPOINT insertBegin" UTF8String], 0, 0, &errMessage);

	code = sqlite3_exec(handler, [@"DROP TABLE IF EXISTS temp._temp" UTF8String], 0, 0, &errMessage);
	code = sqlite3_exec(handler, [@"CREATE TEMP TABLE IF NOT EXISTS _temp (id INTEGER NOT NULL PRIMARY KEY)" UTF8String], 0, 0, &errMessage);
	code = sqlite3_exec(handler, [[NSString stringWithFormat:@"CREATE TEMP TRIGGER _trigger AFTER INSERT ON main.%@ BEGIN INSERT INTO _temp SELECT NEW.id; END", _name, _name] UTF8String], 0, 0, &errMessage);

	NSString *insertString = [self insertStringForColumns:[values allKeys]];
	BOOL succeeded = [_databaseProvider.database executeUpdate:insertString withNamedParameters:values error:nil];
	if (!succeeded)
		return [NSString new];

	code = sqlite3_exec(handler, [@"DROP TRIGGER _trigger;" UTF8String], 0, 0, &errMessage);

	sqlite3_stmt *stmt;
	code = sqlite3_prepare_v2(handler, [@"SELECT id FROM temp._temp ORDER BY id DESC" UTF8String], -1, &stmt, NULL);

	while ( (code = sqlite3_step(stmt)) == SQLITE_ROW) {
		char *buff = sqlite3_column_text(stmt, 0);
		stringBuff = [NSString stringWithUTF8String:buff];
	}

	sqlite3_reset(stmt);
	sqlite3_finalize(stmt);

	code = sqlite3_exec(handler, [@"DELETE FROM temp._temp" UTF8String], 0, 0, &errMessage);
	code = sqlite3_exec(handler, [@"RELEASE insertBegin" UTF8String], 0, 0, &errMessage);

	if (code != 0)
		@throw [NSException exceptionWithName:@"Insert error"
									   reason:_databaseProvider.database.lastErrorMessage
									 userInfo:nil];

	return stringBuff;
}

- (BOOL)update:(NSDictionary <NSString *, id> *)values error:(NSError **)error
{
	NSString *updateString = [self updateStringForColumns:[values allKeys]];
	BOOL succeeded = [_databaseProvider.database executeUpdate:updateString withNamedParameters:values error:error];
	if (!succeeded && error)
		*error = [NSError errorWithDomain:@"com.CopyIsRight.GoldDigger" code:kDEFAULT_ERROR_CODE
								 userInfo:@{NSLocalizedDescriptionKey: _databaseProvider.database.lastErrorMessage}];

	return succeeded;
}

- (BOOL)delete:(id)primaryKey error:(NSError **)error
{
	BOOL succeeded = [_databaseProvider.database executeUpdate:[self deleteString] withParameters:@[primaryKey] error:error];
	if (!succeeded && error)
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
