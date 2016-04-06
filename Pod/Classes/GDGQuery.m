//
//  GDGQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import "GDGQuery.h"

#import "GDGColumn.h"
#import "GDGCondition.h"
#import "GDGJoin.h"
#import "GDGQuery_Protected.h"
#import "GDGTableSource.h"
#import "GDGCondition_Protected.h"
#import "CIRDatabase+GoldDigger.h"
#import "GDGFilter.h"
#import "ObjectiveSugar.h"
#import <SQLAid/CIRResultSet.h>

@interface GDGQuery ()

@property (assign, nonatomic, getter=isIdExplicit) BOOL explicitId;
@property (assign, nonatomic) int limitValue;
@property (assign, nonatomic, getter=isDistinct) BOOL distinctFlag;
@property (strong, nonatomic) NSMutableArray<GDGJoin *> *joins;
@property (strong, nonatomic) NSMutableArray<NSString *> *groups;
@property (strong, nonatomic) GDGCondition *havingCondition;

@end

@implementation GDGQuery

@dynamic projection;

#pragma mark - Initialization

- (instancetype)initWithSource:(GDGSource *)source
{
	if (self = [self init])
		_source = source;

	return self;
}

- (instancetype)init
{
	if (self = [super init])
	{
		_condition = [[GDGCondition alloc] init];
		_mutableProjection = [[NSMutableArray alloc] init];
		_explicitId = NO;

		__weak typeof(self) weakSelf = self;

		_select = ^GDGQuery *(NSArray<NSString *> *projection) {
			if ([projection containsObject:@"id"])
				_explicitId = YES;

			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];

			for (NSString *columnName in projection)
			{
				GDGColumn *column = [weakSelf findColumnNamed:columnName];
				if (column)
					[validProjection addObject:column.fullName];
			}

			[weakSelf.mutableProjection addObjectsFromArray:validProjection];

			return weakSelf;
		};

		_join = ^GDGQuery *(GDGSource *joinSource, NSString *type, GDGCondition *condition, NSArray<NSString *> *projection) {
			if (weakSelf.joins == nil)
				weakSelf.joins = [[NSMutableArray alloc] init];
			else
			{
				GDGJoin *join = [weakSelf.joins find:^BOOL(GDGJoin *object) {
					return [object.source.identifier caseInsensitiveCompare:joinSource.identifier] == NSOrderedSame;
				}];

				if (join != nil)
					@throw [NSException exceptionWithName:@"Duplicate Join's alias" reason:NSStringWithFormat(@"Multiple joins with the same alias %@", joinSource.alias) userInfo:nil];
			}

			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
			GDGColumn *column;

			for (NSString *columnName in projection)
				if ((column = [joinSource columnNamed:columnName]))
					[validProjection addObject:column.fullName];

			weakSelf.select([NSArray arrayWithArray:validProjection]);

			[weakSelf.joins addObject:[[GDGJoin alloc] initWithType:type condition:condition source:joinSource]];

			return weakSelf;
		};

		_joinTable = ^GDGQuery *(NSString *tableName, NSString *type, GDGCondition *condition, NSArray<NSString *> *projection) {
			return weakSelf.join([GDGTableSource tableSourceFromTable:tableName in:[CIRDatabase goldDigger_mainDatabase]], type, condition, projection);
		};

		_where = ^GDGQuery *(void (^handler)(GDGCondition *)) {
			handler(weakSelf.condition);
			return weakSelf;
		};

#define ORDER_BLOCK(direction) \
        ^GDGQuery *(NSString *col) { \
            if (weakSelf.orderList == nil)\
                weakSelf.orderList = [NSMutableArray array];\
            \
						GDGColumn *column; \
            if (column = [weakSelf findColumnNamed:col])\
                [weakSelf.orderList addObject:[column.fullName stringByAppendingString:direction]];\
            \
            return weakSelf;\
        };

		_asc = ORDER_BLOCK(@" ASC");
		_desc = ORDER_BLOCK(@" DESC");

#undef ORDER_BLOCK

		_limit = ^GDGQuery *(int value) {
			weakSelf.limitValue = value;
			return weakSelf;
		};

		_from = ^GDGQuery *(GDGSource *fromSource) {
			weakSelf.source = fromSource;
			return weakSelf;
		};

		_fromTable = ^GDGQuery *(NSString *tableName) {
			return weakSelf.from([GDGTableSource tableSourceFromTable:tableName in:[CIRDatabase goldDigger_mainDatabase]]);
		};

		_filter = ^GDGQuery *(NSArray<id <GDGFilter>> *filters) {
			for (id <GDGFilter> filter in filters)
				[filter apply:weakSelf];

			return weakSelf;
		};

		_groupBy = ^__kindof GDGQuery *(GDGColumn *column) {
			if (weakSelf.groups == nil)
				weakSelf.groups = [[NSMutableArray alloc] init];

			[weakSelf.groups addObject:column.fullName];

			return weakSelf;
		};

		_having = ^__kindof GDGQuery *(GDGCondition *condition) {
			weakSelf.havingCondition = condition;
			return weakSelf;
		};
	}

	return self;
}

#pragma mark - Convenience

- (GDGColumn *)findColumnNamed:(NSString *)columnName
{
	GDGColumn *column = [_source columnNamed:columnName];
	if (column == nil)
	{
		NSUInteger count = _joins.count;
		for (NSUInteger i = 0; i < count && column == nil; i++)
			column = [_joins[i].source columnNamed:columnName];
	}

	return column;
}

#pragma mark - Materialization

- (NSString *)visit
{
	NSMutableString *query = [[NSMutableString alloc] initWithString:@"SELECT "];

	if (_distinctFlag) [query appendString:@" DISTINCT "];

	[query appendString:_mutableProjection.count == 0 ? @"*" : [_mutableProjection join:@", "]];

	[query appendString:@" FROM "];
	[query appendString:_source.name];

	if (_source.alias)
		[query appendFormat:@" AS %@", _source.alias];

	if (_joins.count > 0)
	{
		NSString *joinsString = [[_joins map:^id(GDGJoin *object) {
			return object.visit;
		}] join:@" "];

		[query appendFormat:@" %@", joinsString];
	}

	if (![_condition isEmpty])
	{
		[query appendString:@" WHERE ("];
		[query appendString:_condition.visit];
		[query appendString:@")"];
	}

	if (_groups.count > 0)
	{
		[query appendString:@" GROUP BY "];
		[query appendString:[_groups join:@", "]];
	}

	if (_havingCondition)
	{
		[query appendString:@" HAVING "];
		[query appendString:_havingCondition.visit];
	}

	if (_orderList.count > 0)
	{
		[query appendString:@" ORDER BY "];
		[query appendString:[_orderList join:@", "]];
	}

	if (_limitValue > 0)
		[query appendFormat:@" LIMIT %d", _limitValue];

	return [NSString stringWithString:query];
}

- (NSArray *)raw
{
	NSMutableArray *objects = [NSMutableArray array];

	CIRResultSet *resultSet = [[CIRDatabase goldDigger_mainDatabase] executeQuery:[self visit] withNamedParameters:self.arguments];

	while ([resultSet next])
		[objects addObject:[self rawObjectWithResultSet:resultSet]];

	return [NSArray arrayWithArray:objects];
}

- (NSArray *)pluck
{
	typeof(self) query = self.copy;

	if (!_explicitId)
		[query->_mutableProjection removeObject:@"id"];

	NSMutableArray *objects = [NSMutableArray array];
	CIRResultSet *resultSet = [[CIRDatabase goldDigger_mainDatabase] executeQuery:[query visit] withNamedParameters:query.arguments];

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

- (NSUInteger)count
{
	self.mutableProjection = [@[NSStringWithFormat(@"COUNT(%@.id)", self.source.identifier)] mutableCopy];
	return [self.pluck[0] unsignedIntegerValue];
}

#pragma - Copying

- (__kindof GDGQuery *)copyWithZone:(nullable NSZone *)zone
{
	GDGQuery *copy = [(GDGQuery *) [[self class] allocWithZone:zone] initWithSource:_source.copy];

	copy->_limitValue = _limitValue;
	copy->_distinctFlag = _distinctFlag;
	copy->_joins = [_joins mutableCopy];
	copy->_mutableProjection = [_mutableProjection mutableCopy];
	copy->_orderList = [_orderList mutableCopy];
	copy->_condition = [_condition copy];

	return copy;
}

#pragma mark Private

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

#pragma mark - Encaps
#pragma mark Getter

- (instancetype)distinct
{
	_distinctFlag = YES;
	return self;
}

- (instancetype)clearProjection
{
	[_mutableProjection removeAllObjects];
	return self;
}

- (instancetype)clearOrder
{
	[_orderList removeAllObjects];
	return self;
}

- (GDGJoin *)joinForTableSource:(GDGTableSource *)tableSource
{
	return [_joins find:^BOOL(GDGJoin *object) {
		return [object.source.name isEqualToString:tableSource.name];
	}];
}

- (NSArray *)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSDictionary<NSString *, id> *)arguments
{
	NSMutableDictionary *args = [[NSMutableDictionary alloc] initWithDictionary:_condition.arguments];

	for (GDGJoin *join in _joins)
		[args addEntriesFromDictionary:join.condition.arguments];

	return [NSDictionary dictionaryWithDictionary:args];
}

@end
