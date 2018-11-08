//
// Created by Felipe Lobo on 2018-11-02.
//

#import "GDGConnection.h"
#import "GDGDatabaseProvider.h"
#import "GDGTable.h"
#import "GDGRawQuery.h"
#import "GDGResultSet.h"
#import "GDGQuery.h"
#import "NSError+GDG.h"
#import "GDGQueryParser.h"
#import "GDGColumn.h"
#import "GDGTable_Package.h"
#import <ObjectiveSugar/NSString+ObjectiveSugar.h>
#import <SQLAid/CIRStatement.h>

@implementation GDGConnection

- (instancetype)initWithDatabaseProvider:(id <GDGDatabaseProvider>)databaseProvider
{
	self = [super init];
	if (self)
	{
		_databaseProvider = databaseProvider;
	}

	return self;
}

- (GDGTable *__nullable)tableWithName:(NSString *__nonnull)tableName error:(NSError **__nullable)error
{
	CIRDatabase *database = self.databaseProvider.database;

	NSError *underlyingError;
	NSString *tableInfoQuery = NSStringWithFormat(@"PRAGMA table_info(%@)", tableName);

	CIRResultSet *resultSet = [database executeQuery:tableInfoQuery error:&underlyingError];
	if (!resultSet && underlyingError)
	{
		if (error)
		{
			NSString *message = NSStringWithFormat(@"Error when trying to initialize table %@; database error: %@", tableName, database.lastErrorMessage);
			*error = [NSError errorWithCode:GDGConnectionPragmaTableInfoError
									message:message
								 underlying:underlyingError];
		}

		return nil;
	}

	NSMutableArray *mutableColumns = [NSMutableArray array];

	while ([resultSet next:&underlyingError])
	{
		NSString *name = [resultSet textAtIndex:1];
		GDGColumnType type = [GDGColumn columnTypeFromTypeName:[resultSet textAtIndex:2]];
		BOOL notNull = [resultSet boolAtIndex:3];
		int primaryKey = [resultSet intAtIndex:5];

		GDGColumn *column = [[GDGColumn alloc] initWithName:name type:type primaryKey:primaryKey notNull:notNull];

		[mutableColumns addObject:column];
	}

	if (underlyingError)
	{
		if (error)
		{
			NSString *message = NSStringWithFormat(@"Error when trying to initialize table %@; database error: %@", tableName, database.lastErrorMessage);
			*error = [NSError errorWithCode:GDGConnectionColumnIterationError
				                	message:message
					             underlying:underlyingError];
		}

		return nil;
	}

	NSArray *columns = [NSArray arrayWithArray:mutableColumns];

	return [[GDGTable alloc] initWithTableName:tableName columns:columns];
}

- (NSNumber *)lastInsertedId
{
	return @([_databaseProvider.database lastInsertedId]);
}

#pragma mark - Execute update

- (BOOL)insert:(NSDictionary <NSString *, id> *)values onTable:(GDGTable *)table error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;
	NSString *insertString = [table insertStringForColumns:[values allKeys]];

	NSError *underlyingError;
	BOOL succeeded = [database executeUpdate:insertString withNamedParameters:values error:&underlyingError];

	if (error && !succeeded && underlyingError)
	{
		NSString *message = NSStringWithFormat(@"Error while inserting values at table %@, database error message: %@", table.name, database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionInsertError
								message:message
							 underlying:underlyingError];
	}

	return succeeded;
}

- (BOOL)update:(NSDictionary <NSString *, id> *)values onTable:(GDGTable *)table error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;
	NSString *updateString = [table updateStringForColumns:[values allKeys]];

	NSError *underlyingError;
	BOOL succeeded = [database executeUpdate:updateString withNamedParameters:values error:&underlyingError];

	if (error && !succeeded && underlyingError)
	{
		NSString *message = NSStringWithFormat(@"Error while updating values at table %@, database error message: %@", table.name, database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionUpdateError
								message:message
							 underlying:underlyingError];
	}

	return succeeded;
}

- (BOOL)delete:(id)value fromTable:(GDGTable *)table error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;

	NSError *underlyingError;
	BOOL succeeded = [database executeUpdate:[table deleteString] withParameters:@[value] error:&underlyingError];

	if (error && !succeeded && underlyingError)
	{
		NSString *message = \
				NSStringWithFormat(@"Error while deleting the value %@ of table %@, database error message: %@", value, table.name, database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionDeleteError
								message:message
							 underlying:underlyingError];
	}

	return succeeded;
}

#pragma mark - Prepare statements

- (CIRStatement *)insertStatementForColumns:(NSArray <NSString *> *)columns ofTable:(GDGTable *)table error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;

	NSError *underlyingError;
	CIRStatement *statement = [database prepareStatement:[table insertStringForColumns:columns] error:&underlyingError];

	if (error && !statement && underlyingError)
	{
		NSString *message = NSStringWithFormat(@"Could not prepare insert statement, database error message: %@", database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionPrepareInsertError
								message:message
							 underlying:underlyingError];
	}

	return statement;
}

- (CIRStatement *__nullable)updateStatementForColumns:(NSArray <NSString *> *__nonnull)columns ofTable:(GDGTable *__nonnull)table condition:(NSString *__nullable)condition error:(NSError **__nullable)error
{
	CIRDatabase *database = self.databaseProvider.database;

	NSError *underlyingError;
	NSString *query = [table updateStringForColumns:columns condition:condition];
	CIRStatement *statement = [database prepareStatement:query error:&underlyingError];

	if (error && !statement && underlyingError)
	{
		NSString *message = NSStringWithFormat(@"Could not prepare update statement, database error message: %@", database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionPrepareUpdateError
							   	message:message
							 underlying:underlyingError];
	}

	return statement;
}

- (CIRStatement *)deleteStatementForTable:(GDGTable *)table error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;

	NSError *underlyingError;
	CIRStatement *statement = [database prepareStatement:[table deleteString] error:&underlyingError];

	if (error && !statement && underlyingError)
	{
		NSString *message = NSStringWithFormat(@"Could not prepare delete statement, database error message: %@", database.lastErrorMessage);
		*error = [NSError errorWithCode:GDGConnectionPrepareDeleteError
								message:message
							 underlying:underlyingError];
	}

	return statement;
}

#pragma mark - Evaluate & Execute

- (GDGResultSet *)eval:(GDGQuery *)query error:(NSError **)error
{
	CIRDatabase *database = self.databaseProvider.database;

	GDGQueryParser *queryParser = [[GDGQueryParser alloc] init];
	GDGRawQuery *rawQuery = [queryParser parse:query error:error];

	if (!rawQuery)
		return nil;

	NSError *underlyingError;
	CIRResultSet *resultSet = [database executeQuery:rawQuery.visit
								   	  withParameters:rawQuery.args
								               error:&underlyingError];

	if (!resultSet && underlyingError)
	{
		if (error)
		{
			NSString *message = NSStringWithFormat(@"Could not end query evaluation with error: %@ | Query: \"%@\"", database.lastErrorMessage, rawQuery.debugDescription);
			*error = [NSError errorWithCode:GDGConnectionQueryEvaluationError
			                        message:message
			                     underlying:underlyingError];
		}

		return nil;
	}

	return [[GDGResultSet alloc] initWithResultSet:resultSet projection:query.projection];
}

- (NSArray *)evalByTuple:(GDGQuery *)query error:(NSError **)error
{
	GDGResultSet *resultSet = [self eval:query error:error];
	if (!resultSet)
		return nil;

	NSMutableArray *objects = [[NSMutableArray alloc] init];
	NSDictionary *tuple;

	while ((tuple = [resultSet next:error]))
		[objects addObject:tuple];

	if (*error)
		return nil;

	return [NSArray arrayWithArray:objects];
}

- (NSDictionary *)evalByColumn:(GDGQuery *)query error:(NSError **)error
{
	GDGResultSet *resultSet = [self eval:query error:error];
	if (!resultSet)
		return nil;

	NSMutableDictionary *mutableColumns = [[NSMutableDictionary alloc] init];
	NSDictionary *tuple = [resultSet next:error];

	for (NSString *column in tuple.allKeys)
		mutableColumns[column] = [[NSMutableArray alloc] init];

	while (tuple)
	{
		for (NSString *column in tuple.allKeys)
		{
			NSMutableArray *values = mutableColumns[column];
			[values addObject:tuple[column]];
		}

		tuple = [resultSet next:error];
	}

	if (*error)
		return nil;

	return [NSDictionary dictionaryWithDictionary:mutableColumns];
}

@end
