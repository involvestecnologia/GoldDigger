//
// Created by Felipe Lobo on 2018-11-02.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGQueryParser.h"
#import "GDGQuery.h"
#import "GDGCondition.h"
#import "SQLQuery_Protected.h"
#import "SQLTableSource.h"
#import "SQLQuerySource.h"
#import "SQLJoin.h"
#import "GDGColumn.h"
#import "GDGConditionParser.h"
#import "NSError+GDG.h"

@implementation GDGRawQuery

- (instancetype)initWithQuery:(NSString *)rawValue args:(NSArray *)args
{
	self = [super init];
	if (self)
	{
		_visit = rawValue;
		_args = args;
	}

	return self;
}

@end

@implementation GDGQueryParser

- (GDGRawQuery *)parse:(GDGQuery *)queryObject error:(NSError **)error
{
	NSMutableString *query = [[NSMutableString alloc] initWithString:@"SELECT "];
	NSMutableArray *args = [[NSMutableArray alloc] init];

	if (queryObject.distinct)
		[query appendString:@"DISTINCT "];

	NSArray *projection = queryObject.projection;
	[query appendString:projection.count == 0 ? @"*" : [projection join:@", "]];

	GDGParsingResult *fromResult = [self parseFromSource:queryObject.source error:error];
	if (!fromResult)
		return nil;

	[query appendString:fromResult.visit];
	[args addObjectsFromArray:fromResult.args];

	NSArray <SQLJoin *> *joins = queryObject.joins;
	if (joins.count > 0)
	{
		GDGParsingResult *parsedJoins = [self parseJoins:joins error:error];
		if (!parsedJoins)
			return nil;

		[query appendString:parsedJoins.visit];
		[args addObjectsFromArray:parsedJoins.args];
	}

	GDGCondition *whereCondition = queryObject.whereCondition;
	if (!whereCondition.isEmpty)
	{
		GDGParsingResult *where = [self parseWhere:whereCondition error:error];
		if (!where)
			return nil;

		[query appendString:where.visit];
		[args addObjectsFromArray:where.args];
	}

	NSArray <GDGColumn *> *groups = queryObject.groups;
	if (groups.count > 0)
	{
		[query appendString:[self parseGroups:groups]];

		GDGCondition *havingCondition = queryObject.havingCondition;
		if (!havingCondition.isEmpty)
		{
			GDGParsingResult *having = [self parseHaving:havingCondition error:error];
			if (!having)
				return nil;

			[query appendString:having.visit];
			[args addObjectsFromArray:having.args];
		}
	}

	NSArray *orderList = queryObject.orderList;
	if (orderList.count > 0)
		[query appendString:[self parseOrderBy:orderList]];

	NSUInteger limit = queryObject.limit;
	if (limit > 0)
		[query appendFormat:@" LIMIT %d", limit];

	NSString *raw = [NSString stringWithString:query];
	NSArray *allArgs = [NSArray arrayWithArray:args];

	GDGRawQuery *rawQuery = [[GDGRawQuery alloc] initWithQuery:raw args:allArgs];

	return rawQuery;
}

- (GDGParsingResult *)parseFromSource:(id <GDGSource>)source error:(NSError **)error
{
	NSMutableString *mutableString = [[NSMutableString alloc] initWithString:@" FROM "];
	NSMutableArray *args = [[NSMutableArray alloc] init];

	if ([source isKindOfClass:[SQLTableSource class]])
		[mutableString appendString:source.name];
	else if ([source isKindOfClass:[SQLQuerySource class]])
	{
		NSError *underlyingError;
		GDGRawQuery *sourceParsingResult = [self parse:((SQLQuerySource *)source).query error:&underlyingError];

		if (!sourceParsingResult && underlyingError)
		{
			NSString *localizedDescription = @"Error while parsing FROM with source being a query";
			NSDictionary *errorInfo = @{
					NSLocalizedDescriptionKey: localizedDescription,
					NSUnderlyingErrorKey: underlyingError
			};

			if (error)
				*error = [NSError errorWithDomain:GDGErrorDomain code:200 userInfo:errorInfo];

			return nil;
		}

		[mutableString appendString:@"("];
		[mutableString appendString:sourceParsingResult.visit];
		[mutableString appendString:@")"];

		[args addObjectsFromArray:sourceParsingResult.args];
	}

	if ([source alias])
		[mutableString appendFormat:@" AS %@ ", source.alias];

	GDGParsingResult *result = [[GDGParsingResult alloc] init];
	result.visit = [NSString stringWithString:mutableString];
	result.args = [NSArray arrayWithArray:args];

	return result;
}

- (GDGParsingResult *)parseJoins:(NSArray <SQLJoin *> *)joins error:(NSError **)error
{
	NSMutableArray *joinsString = [[NSMutableArray alloc] init];
	NSMutableArray *args = [[NSMutableArray alloc] init];

	for (uint i = 0; i < joins.count; i++)
	{
		SQLJoin *join = joins[i];
		NSMutableString *result = [[NSMutableString alloc] init];

		if (join.kind == SQLJoinKindInner)
			[result appendString:@" INNER "];
		else if (join.kind == SQLJoinKindLeft)
			[result appendString:@" LEFT "];

		[result appendString:@"JOIN "];
		[result appendFormat:@"%@ ", join.source.name];

		if (join.source.alias != nil)
			[result appendFormat:@"AS %@ ", join.source.alias];

		[result appendString:@"ON ("];

		NSError *underlyingError;
		GDGParsingResult *joinCondition = [self parseCondition:join.condition error:&underlyingError];

		if (!joinCondition && underlyingError)
		{
			NSString *localizedDescription = NSStringWithFormat(@"Error while parsing a join condition, partial: %@", result);
			NSDictionary *errorInfo = @{
					NSLocalizedDescriptionKey: localizedDescription,
					NSUnderlyingErrorKey: underlyingError
			};

			if (error)
				*error = [NSError errorWithDomain:GDGErrorDomain code:201 userInfo:errorInfo];

			return nil;
		}

		[result appendString:joinCondition.visit];
		[result appendString:@")"];

		[joinsString addObject:result];
		[args addObject:joinCondition.args];
	}

	GDGParsingResult *result = [[GDGParsingResult alloc] init];
	result.visit = [joinsString join:@" "];
	result.args = [NSArray arrayWithArray:args];

	return result;
}

- (GDGParsingResult *)parseWhere:(GDGCondition *)condition error:(NSError **)error
{
	NSError *underlyingError;
	GDGParsingResult *where = [self parseCondition:condition error:&underlyingError];

	if (!where && underlyingError)
	{
		NSString *localizedDescription = @"Error while parsing where condition";
		NSDictionary *errorInfo = @{
				NSLocalizedDescriptionKey: localizedDescription,
				NSUnderlyingErrorKey: underlyingError
		};

		if (error)
			*error = [NSError errorWithDomain:GDGErrorDomain code:202 userInfo:errorInfo];

		return nil;
	}

	NSMutableString *mutableString = [[NSMutableString alloc] init];

	[mutableString appendString:@" WHERE ("];
	[mutableString appendString:where.visit];
	[mutableString appendString:@")"];

	GDGParsingResult *result = [[GDGParsingResult alloc] init];
	result.visit = [NSString stringWithString:mutableString];
	result.args = where.args;

	return result;
}

- (NSString *)parseGroups:(NSArray <GDGColumn *> *)groups
{
	NSMutableString *result = [[NSMutableString alloc] init];

	[result appendString:@" GROUP BY "];
	[result appendString:[[groups map:^NSString *(GDGColumn *column) {
		return column.fullName;
	}] join:@", "]];

	return [NSString stringWithString:result];
}

- (GDGParsingResult *)parseHaving:(GDGCondition *)condition error:(NSError **)error
{
	NSError *underlyingError;
	GDGParsingResult *having = [self parseCondition:condition error:&underlyingError];

	if (!having && underlyingError)
	{
		NSString *localizedDescription = @"Error while parsing having condition";
		NSDictionary *errorInfo = @{
				NSLocalizedDescriptionKey: localizedDescription,
				NSUnderlyingErrorKey: underlyingError
		};

		if (error)
			*error = [NSError errorWithDomain:GDGErrorDomain code:203 userInfo:errorInfo];

		return nil;
	}

	NSMutableString *mutableString = [[NSMutableString alloc] init];

	[mutableString appendString:@" HAVING ("];
	[mutableString appendString:having.visit];
	[mutableString appendString:@")"];

	GDGParsingResult *result = [[GDGParsingResult alloc] init];
	result.visit = [NSString stringWithString:mutableString];
	result.args = having.args;

	return result;
}

- (NSString *)parseOrderBy:(NSArray *)ordersList
{
	NSMutableString *result = [[NSMutableString alloc] init];

	[result appendString:@" ORDER BY "];

	for (NSString *token in ordersList)
		if ([token isEqualToString:@"ASC"] || [token isEqualToString:@"DESC"])
			[result appendFormat:@" %@, ", token];
		else
			[result appendString:token];

	[result replaceCharactersInRange:NSMakeRange(result.length - 2, 2) withString:@" "];

	return [NSString stringWithString:result];
}

- (id <GDGParsingResult>)parseCondition:(GDGCondition *)condition error:(NSError **)error
{
	GDGConditionParser *conditionParser = [[GDGConditionParser alloc] init];
	return [conditionParser parse:condition error:error];
}

@end
