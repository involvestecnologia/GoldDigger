//
//  GDGQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import "GDGQuery.h"

#import "GDGColumn.h"
#import "GDGConditionBuilder.h"
#import "GDGEntityManager.h"
#import "GDGJoin.h"
#import "GDGQuery_Protected.h"
#import "GDGTableSource.h"
#import "GDGConditionBuilder_Protected.h"
#import "CIRDatabase+GoldDigger.h"
#import <SQLAid/CIRResultSet.h>
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>

@interface GDGQuery ()

@property (assign, nonatomic) int limitValue;
@property (assign, nonatomic, getter=isDistinct) BOOL distinctFlag;
@property (strong, nonatomic) NSMutableArray<GDGJoin *> *joins;

@end

@implementation GDGQuery

@dynamic projection;

#pragma mark - Initialization

- (instancetype)initWithSource:(GDGSource *)source
{
	if (self = [super init])
	{
		_source = source;
		_conditionBuilder = [[GDGConditionBuilder alloc] init];
		_mutableProjection = [[NSMutableArray alloc] init];

		__weak __typeof(self) weakSelf = self;

		_select = ^GDGQuery *(NSArray<NSString *> *projection) {
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

		_join = ^GDGQuery *(GDGSource *joinSource, NSString *type, NSString *condition, NSArray<NSString *> *projection) {
			if (weakSelf.joins == nil) weakSelf.joins = [[NSMutableArray alloc] init];

			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];

			for (NSString *column in projection)
				if ([source columnNamed:column])
					[validProjection addObject:column];

			weakSelf.select([NSArray arrayWithArray:validProjection]);

			[weakSelf.joins addObject:[[GDGJoin alloc] initWithType:type condition:condition source:source]];

			return weakSelf;
		};

		_joinTable = ^GDGQuery *(NSString *tableName, NSString *type, NSString *condition, NSArray<NSString *> *projection) {
			return weakSelf.join([GDGTableSource tableSourceFromTable:tableName in:[CIRDatabase goldDigger_mainDatabase]], type, condition, projection);
		};

		_where = ^GDGQuery *(void (^handler)(GDGConditionBuilder *)) {
			handler(weakSelf.conditionBuilder);
			return weakSelf;
		};

#define ORDER_BLOCK(direction) \
        ^GDGQuery *(NSString *col) { \
            if (weakSelf.orderList == nil)\
                weakSelf.orderList = [NSMutableArray array];\
            \
            if ([weakSelf findColumnNamed:col])\
                [weakSelf.orderList addObject:[col stringByAppendingString:direction]];\
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

	[query appendString:_mutableProjection.count > 0 ? @"*" : [_mutableProjection join:@", "]];

	[query appendString:@" FROM "];
	[query appendString:_source.alias];

	if (_joins.count > 0)
	{
		NSString *joinsString = [[_joins map:^id(GDGJoin *object) {
			return object.visit;
		}] join:@" "];

		[query appendFormat:@" %@", joinsString];
	}

	if (![_conditionBuilder isEmpty])
	{
		[query appendString:@" WHERE ("];
		[query appendString:_conditionBuilder.visit];
		[query appendString:@")"];
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
	[_mutableProjection removeObject:@"id"];

	NSMutableArray *objects = [NSMutableArray array];
	CIRResultSet *resultSet = [[CIRDatabase goldDigger_mainDatabase] executeQuery:[self visit] withNamedParameters:self.arguments];

	const int columnCount = [resultSet columnCount];

	for (NSUInteger i = 0; i < columnCount; i++)
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
	self.mutableProjection = [@[@"COUNT(id)"] mutableCopy];
	return [self.pluck[0] unsignedIntegerValue];
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

- (NSArray *)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSDictionary<NSString *, id> *)arguments
{
	return [_conditionBuilder.arguments copy];
}

@end
