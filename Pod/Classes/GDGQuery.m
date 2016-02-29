//
//  GDGQuery.m
//  Pods
//
//  Created by Pietro Caselani on 2/15/16.
//
//

#import "GDGQuery.h"

#import "GDGColumn.h"
#import "GDGConditionBuilder.h"
#import "GDGEntityManager.h"
#import "GDGJoin.h"
#import "GDGQuery_Protected.h"
#import "GDGTableSource.h"
#import "NSArray+ObjectiveSugar.h"
#import "GDGConditionBuilder_Protected.h"
#import <SQLAid/CIRDatabase.h>
#import <SQLAid/CIRResultSet.h>

@interface GDGQuery ()

@property (assign, nonatomic) int limitValue;
@property (assign, nonatomic, getter=isDistinct) BOOL distinctFlag;
@property (strong, nonatomic) NSMutableArray<GDGJoin*>* joins;

@end

@implementation GDGQuery

@dynamic projection;

#pragma mark - Initialization

- (instancetype)initWithTableName:(NSString*)tableName
{
	return [self initWithSource:[GDGEntityManager tableSourceWithName:tableName]];
}

- (instancetype)initWithSource:(GDGSource*)source
{
	if (self = [super init])
	{
		_source = source;
		_conditionBuilder = [[GDGConditionBuilder alloc] init];
		_mutableProjection = [[NSMutableArray alloc] init];

		__weak __typeof(self)weakSelf = self;
		
		_select = ^GDGQuery* (NSArray<NSString*>* projection) {
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
		
		_join = ^GDGQuery* (GDGSource *joinSource, NSString *type, NSString *condition, NSArray<NSString*>* projection) {
			if (weakSelf.joins == nil) weakSelf.joins = [[NSMutableArray alloc] init];
			
			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
			
			for (NSString *column in projection)
				if ([source columnNamed:column])
					[validProjection addObject:column];

			weakSelf.select([NSArray arrayWithArray:validProjection]);
			
			[weakSelf.joins addObject:[[GDGJoin alloc] initWithType:type condition:condition source:source]];
			
			return weakSelf;
		};
		
		_joinTable = ^GDGQuery* (NSString *tableName, NSString *type, NSString *condition, NSArray<NSString*>* projection) {
			return weakSelf.join([GDGEntityManager tableSourceWithName:tableName], type, condition, projection);
		};
		
		_where = ^GDGQuery *(void (^handler)(GDGConditionBuilder *)) {
			handler(weakSelf.conditionBuilder);
			return weakSelf;
		};
		
		_asc = ^GDGQuery* (NSString* order) {
			if (weakSelf.orderList == nil) weakSelf.orderList = [[NSMutableArray alloc] init];
			
			if ([weakSelf findColumnNamed:order])
				[weakSelf.orderList addObject:[order stringByAppendingString:@" ASC"]];
			
			return weakSelf;
		};
		
		_desc = ^GDGQuery* (NSString* order) {
			if (weakSelf.orderList == nil) weakSelf.orderList = [[NSMutableArray alloc] init];
			
			if ([weakSelf findColumnNamed:order])
				[weakSelf.orderList addObject:[order stringByAppendingString:@" DESC"]];
			
			return weakSelf;
		};
		
		_limit = ^GDGQuery* (int value) {
			weakSelf.limitValue = value;
			return weakSelf;
		};
		
		_from = ^GDGQuery* (GDGSource *fromSource) {
			weakSelf.source = fromSource;
			return weakSelf;
		};
		
		_fromTable = ^GDGQuery* (NSString *tableName) {
			return weakSelf.from([GDGEntityManager tableSourceWithName:tableName]);
		};
	}
	
	return self;
}

#pragma mark - Others

- (GDGColumn*)findColumnNamed:(NSString*)columnName
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

#pragma mark - Results

- (NSString*)visit
{
	NSMutableString* query = [[NSMutableString alloc] initWithString:@"SELECT "];
	
	if (_distinctFlag) [query appendString:@" DISTINCT "];
	
	[query appendString:[_mutableProjection join:@", "]];
	
	[query appendString:@" FROM "];
	[query appendString:_source.alias];
	
	if (_joins.count > 0)
	{
		NSString *joinsString = [[_joins map:^id(GDGJoin *object) {
			return object.visit;
		}] join:@" "];
		
		[query appendFormat:@" %@", joinsString];
	}
	
	if (_conditionBuilder)
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

- (NSArray<__kindof GDGEntity*>*)array
{
	@throw [[NSException alloc] initWithName:@"Unsupported exception" reason:@"Can't build entity." userInfo:nil];
}

- (__kindof GDGEntity*)object
{
	@throw [[NSException alloc] initWithName:@"Unsupported exception" reason:@"Can't build entity." userInfo:nil];
}

- (NSArray<id>*)rawObjects
{
	NSMutableArray<id>* objects = [[NSMutableArray alloc] init];
	
	CIRResultSet* resultSet = [[GDGEntityManager database] executeQuery:[self visit] withNamedParameters:self.arguments];
	
	while ([resultSet next]) [objects addObject:[self rawObjectWithResultSet:resultSet]];
	
	return [NSArray arrayWithArray:objects];
}

- (NSArray<id>*)pluck
{
	NSMutableArray<id>* objects = [[NSMutableArray alloc] init];
	
	[_mutableProjection removeObject:@"id"];
	
	CIRResultSet* resultSet = [[GDGEntityManager database] executeQuery:[self visit] withNamedParameters:self.arguments];
	
	while ([resultSet next])
	{
		int columnCount = [resultSet columnCount];
		
		if (columnCount == 1)
			[objects addObject:resultSet[0]];
		else
		{
			for (int i = 0; i < columnCount; i++)
				objects[i] = [NSMutableArray array];
			
			for (int i = 0; i < columnCount; i++)
				[objects[i] addObject:resultSet[i]];
		}
	}
	
	return [NSArray arrayWithArray:objects];
}

- (NSUInteger)count
{
	self.mutableProjection = [@[@"COUNT(id)"] mutableCopy];
	return [self.pluck[0] unsignedIntegerValue];
}

#pragma mark - Getters & Setters

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

- (NSArray*)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSDictionary<NSString*, id> *)arguments
{
	return [_conditionBuilder.arguments copy];
}

#pragma mark - Private

- (id)rawObjectWithResultSet:(CIRResultSet*)resultSet
{
	id object;
	
	int columnCount = [resultSet columnCount];
	
	if (columnCount == 0) object = nil;
	else if (columnCount == 1) object = [resultSet objectAtIndex:0];
	else
	{
		NSMutableArray* objects = [[NSMutableArray alloc] init];
		
		for (int i = 0; i < columnCount; i++) [objects addObject:[resultSet objectAtIndex:i]];
		
		object = [NSArray arrayWithArray:objects];
	}
	
	return object;
}

@end
