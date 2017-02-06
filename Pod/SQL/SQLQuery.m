//
//  SQLQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "SQLQuery.h"

#import "GDGColumn.h"
#import "SQLTableSource.h"
#import "SQLJoin.h"
#import "SQLQuerySource.h"
#import "SQLQuery_Protected.h"

@interface SQLQuery ()

@property (readwrite, nonatomic) NSObject <SQLSource> *source;
@property (strong, nonatomic) NSMutableDictionary <NSString *, id> *mutableArgs;
@property (strong, nonatomic) NSMutableArray <GDGColumn *> *mutableGroups;

@end

@implementation SQLQuery {
	BOOL _distinct;
}

#pragma mark - Initialization

+ (instancetype)query
{
	return [(SQLQuery *) [self.class alloc] initWithSQLSource:nil];
}

- (instancetype)initWithSQLSource:(id <SQLSource>)source
{
	if (self = [self init])
		_source = source;

	return self;
}

- (instancetype)init
{
	if (self = [super init])
	{
		_distinct = NO;
		_whereCondition = [GDGCondition builder];
		_havingCondition = [GDGCondition builder];
		_mutableArgs = [NSMutableDictionary dictionary];
		_mutableProjection = [NSMutableArray array];
		_mutableOrderList = [NSMutableArray array];
		_mutableJoins = [NSMutableArray array];
		_mutableGroups = [NSMutableArray array];

		__weak typeof(self) weakSelf = self;

		_select = ^SQLQuery *(NSArray<NSString *> *projection) {
			[weakSelf select:projection];
			return weakSelf;
		};

		_from = ^SQLQuery *(id <SQLSource> src) {
			weakSelf.source = src;
			return weakSelf;
		};

		_join = ^SQLQuery *(SQLJoin *join) {
			[weakSelf join:join];
			return weakSelf;
		};

		_where = ^SQLQuery *(void (^handler)(GDGCondition *)) {
			[weakSelf where:handler];
			return weakSelf;
		};

		_groupBy = ^SQLQuery *(GDGColumn *column) {
			[weakSelf groupBy:column];
			return weakSelf;
		};

		_having = ^SQLQuery *(void (^handler)(GDGCondition *)) {
			[weakSelf having:handler];
			return weakSelf;
		};

		_asc = ^SQLQuery *(NSString *prop) {
			[weakSelf asc:prop];
			return weakSelf;
		};

		_desc = ^SQLQuery *(NSString *prop) {
			[weakSelf desc:prop];
			return weakSelf;
		};

		[self select:@[@"id"]];
	}

	return self;
}

#pragma mark - Abstract impl

- (NSString *)visit
{
	NSMutableString *query = [[NSMutableString alloc] initWithString:@"SELECT "];

	NSString *(^disambiguateArgs)(SQLQuery *) = ^(SQLQuery *qry) {
		NSMutableString *innerQuery = [NSMutableString stringWithString:[qry visit]];
		NSString *key = nil, *newKey = nil;
		NSDictionary *args = [qry args];

		for (key in args.keyEnumerator)
		{
			if ([_mutableArgs hasKey:key])
			{
				unsigned int random = arc4random() % 10000;

				newKey = NSStringWithFormat(@"%@_%u", key, random);

				_mutableArgs[newKey] = args[key];

				[innerQuery replaceOccurrencesOfString:key withString:newKey options:NSLiteralSearch range:NSMakeRange(0, innerQuery.length)];
			}
		}

		return innerQuery;
	};

	if (_distinct)
		[query appendString:@"DISTINCT "];

	NSArray *projection = self.projection;

	[query appendString:projection.count == 0 ? @"*" : [projection join:@", "]];
	[query appendString:@" FROM "];

	if ([_source isKindOfClass:[SQLTableSource class]])
		[query appendString:((SQLTableSource *) _source).name];
	else if ([_source isKindOfClass:[SQLQuerySource class]])
	{
		SQLQuerySource *querySource = (SQLQuerySource *) _source;
		[query appendString:@"("];
		[query appendString:disambiguateArgs(querySource.query)];
		[query appendString:@")"];
	}

	if ([_source alias])
		[query appendFormat:@" AS %@ ", _source.alias];

	NSArray *joins = self.joins;

	if (joins.count > 0)
	{
		NSString *joinsString = [[self.joins map:^id(SQLJoin *join) {
			return [self visitJoin:join disambiguate:disambiguateArgs];
		}] join:@" "];

		[query appendString:joinsString];
	}

	if (!self.whereCondition.isEmpty)
	{
		[query appendString:@" WHERE ("];
		[query appendString:[self visitCondition:self.whereCondition disambiguate:disambiguateArgs]];
		[query appendString:@")"];
	}

	if (_mutableGroups.count > 0)
	{
		[query appendString:@" GROUP BY "];
		[query appendString:[[_mutableGroups map:^NSString *(GDGColumn *column) {
			return column.fullName;
		}] join:@", "]];

		if (!_havingCondition.isEmpty)
		{
			[query appendString:@" HAVING ("];
			[query appendString:[self visitCondition:_havingCondition disambiguate:disambiguateArgs]];
			[query appendString:@")"];
		}
	}

	NSArray *orderList = self.orderList;

	if (orderList.count > 0)
	{
		[query appendString:@" ORDER BY "];

		for (NSString *token in orderList)
			if ([token isEqualToString:@"ASC"] || [token isEqualToString:@"DESC"])
				[query appendFormat:@" %@, ", token];
			else
				[query appendString:token];

		[query replaceCharactersInRange:NSMakeRange(query.length - 2, 2) withString:@" "];
	}

	if (self.limitValue > 0)
		[query appendFormat:@" LIMIT %d", self.limitValue];

	return [NSString stringWithString:query];
}

- (NSArray *)pluck
{
	return [self.source evalByColumn:self];
}

- (NSDictionary *)args
{
	return [NSDictionary dictionaryWithDictionary:_mutableArgs];
}

#pragma mark - Visit

- (NSString *)visitCondition:(GDGCondition *)condition disambiguate:(NSString *(^)(SQLQuery *))disambiguationHandler
{
	NSMutableString *mutableCondition = [NSMutableString string];

	NSArray *operatorTokens = @[@"=", @">", @">=", @"<", @"<=", @"<>"];
	NSString *token = nil;
	NSDictionary *fields = condition.fields;
	NSMutableArray *tokens = condition.tokens.mutableCopy;
	NSMutableDictionary *conditionArgs = condition.args.mutableCopy;

	for (NSString *key in condition.args.keyEnumerator)
	{
		NSString *newKey = key;

		if ([_mutableArgs hasKey:key])
		{
			unsigned int random = arc4random() % 10000;

			newKey = NSStringWithFormat(@"%@_%u", key, random);

			conditionArgs[newKey] = conditionArgs[key];

			tokens[[tokens indexOfObject:key]] = newKey;

			[conditionArgs removeObjectForKey:key];
		}

		_mutableArgs[newKey] = conditionArgs[newKey];
	}

	for (NSUInteger i = 0; i < tokens.count; i++)
	{
		token = tokens[i];

		if ([token isEqualToString:@"("])
			[mutableCondition appendString:@"("];
		else if ([token isEqualToString:@")"])
			[mutableCondition appendString:@")"];
		else if ([token hasPrefix:@"FIELD_"])
			[mutableCondition appendString:[(id <GDGConditionField>) fields[token] fullName]];
		else if ([operatorTokens containsObject:token])
			[mutableCondition appendString:token];
		else if ([token isEqualToString:@"IN"])
		{
			[mutableCondition appendString:@" IN ("];

			token = tokens[++i];

			if ([token hasPrefix:@"ARG_"])
			{
				id arg = conditionArgs[token];
				if ([arg isKindOfClass:[NSString class]])
					[mutableCondition appendString:arg];
				else if ([arg isKindOfClass:[NSArray class]])
					[mutableCondition appendString:[[(NSArray *) arg map:^id(id object) {
						return NSStringWithFormat(@"%@", object);
					}] join:@", "]];
				else if ([arg isKindOfClass:[SQLQuery class]])
					[mutableCondition appendString:disambiguationHandler(arg)];
				else
					@throw [NSException exceptionWithName:@"SQL Query Translation Exception"
					                               reason:NSStringWithFormat(@"[SQLQuery -visit] thorws that the argument kind \"%@\" can't be interpreted", NSStringFromClass([arg class]))
					                             userInfo:nil];
			}

			[mutableCondition appendString:@")"];
		}
		else if ([token hasPrefix:@"ARG_"])
			[mutableCondition appendString:[@":" stringByAppendingString:token]];
		else if ([token isEqualToString:@"AND"])
			[mutableCondition appendString:@"AND"];
		else if ([token isEqualToString:@"OR"])
			[mutableCondition appendString:@"OR"];
		else if ([token isEqualToString:@"NULL"])
			[mutableCondition appendString:@"IS NULL"];
		else if ([token isEqualToString:@"NOTNULL"])
			[mutableCondition appendString:@"IS NOT NULL"];

		[mutableCondition appendString:@" "];
	}

	[mutableCondition replaceCharactersInRange:NSMakeRange(mutableCondition.length - 1, 1) withString:@""];

	return [NSString stringWithString:mutableCondition];
}

- (NSString *)visitJoin:(SQLJoin *)join disambiguate:(NSString *(^)(SQLQuery *))disambiguationHandler
{
	NSMutableString *mutableString = [NSMutableString string];

	if (join.kind == SQLJoinKindInner)
		[mutableString appendString:@" INNER "];
	else if (join.kind == SQLJoinKindLeft)
		[mutableString appendString:@" LEFT "];

	[mutableString appendString:@"JOIN "];
	[mutableString appendFormat:@"%@ ", join.source.name];

	if (join.source.alias != nil)
		[mutableString appendFormat:@"AS %@ ", join.source.alias];

	[mutableString appendString:@"ON ("];
	[mutableString appendString:[self visitCondition:join.condition disambiguate:disambiguationHandler]];
	[mutableString appendString:@")"];

	return [NSString stringWithString:mutableString];
}

#pragma mark - Protected impl

- (void)select:(NSArray <NSString *> *)projection
{
	NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
	for (NSString *key in projection)
	{
		GDGColumn *column = [self.source.columns find:^BOOL(GDGColumn *object) {
			return [object.name isEqualToString:key];
		}];

		if (column)
			[validProjection addObject:column.fullName];
	}

	[_mutableProjection addObjectsFromArray:validProjection];
}

- (void)join:(SQLJoin *)join
{
	GDGJoin *alreadyAddedJoin = [self.mutableJoins find:^BOOL(GDGJoin *object) {
		return [join.source.identifier isEqualToString:object.source.identifier];
	}];

	if (alreadyAddedJoin != nil)
		@throw [NSException exceptionWithName:@"SQL Query Join Exception"
		                               reason:NSStringWithFormat(@"[SQLQuery -join:] throws that access attempt to add multiple joins with the same identifier \"%@\"", join.source.identifier)
		                             userInfo:nil];

	NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:join.projection.count];
	GDGColumn *column;

	for (NSString *name in join.projection)
	{
		column = [join.source.columns find:^BOOL(GDGColumn *object) {
			return [name isEqualToString:object.name];
		}];

		if (column)
			[validProjection addObject:column.fullName];
	}

	[self.mutableProjection addObjectsFromArray:validProjection];
	[self.mutableJoins addObject:join];
}

- (void)where:(void (^)(GDGCondition *))handler
{
	handler(_whereCondition);
}

- (void)groupBy:(GDGColumn *)column
{
	[_mutableGroups addObject:column];
}

- (void)having:(void (^)(GDGCondition *))handler
{
	handler(_havingCondition);
}

- (void)asc:(NSString *)prop
{
	[_mutableOrderList addObject:prop];
	[_mutableOrderList addObject:@"ASC"];
}

- (void)desc:(NSString *)prop
{
	[_mutableOrderList addObject:prop];
	[_mutableOrderList addObject:@"DESC"];
}

#pragma mark - Flaggin'

- (instancetype)distinct
{
	_distinct = YES;

	return self;
}

#pragma mark - Convenience

- (NSString *)debugDescription
{
	SQLQuery *evaluationQuery = self.copy;
	
	NSMutableString *visit = [[NSMutableString alloc] initWithString:evaluationQuery.visit];
	NSDictionary *args = evaluationQuery.args;
	
	for (NSString *token in args.allKeys)
	{
		NSRange fullRange = NSMakeRange(0, visit.length);
		[visit replaceOccurrencesOfString:[@":" stringByAppendingString:token] withString:[args[token] stringValue] options:NSLiteralSearch range:fullRange];
	}
	
	return [NSString stringWithString:visit];
}

- (instancetype)clearProjection
{
	[_mutableProjection removeAllObjects];
	return self;
}

- (NSArray *)raw
{
	return [self.source evalByTuple:self];
}

- (NSUInteger)count
{
	SQLQuery *countQuery = self.copy;
	
	countQuery.mutableProjection = [@[NSStringWithFormat(@"COUNT(%@.id)", self.source.identifier)] mutableCopy];

	return [countQuery.pluck[0] unsignedIntegerValue];
}

#pragma mark - Proxy

- (NSArray *)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSArray *)joins
{
	return [NSArray arrayWithArray:_mutableJoins];
}

- (NSArray *)orderList
{
	return [NSArray arrayWithArray:_mutableOrderList];
}

#pragma mark - Copying

- (instancetype)copyWithZone:(NSZone *)zone
{
	SQLQuery *copy = [super copyWithZone:zone];
	copy->_mutableJoins = [_mutableJoins mutableCopy];
	copy->_mutableProjection = [_mutableProjection mutableCopy];
	copy->_mutableOrderList = [_mutableOrderList mutableCopy];
	copy->_whereCondition = [_whereCondition copy];
	copy->_source = [_source copy];
	copy->_distinct = _distinct;
	copy->_mutableArgs = [_mutableArgs mutableCopy];

	return copy;
}

@end
