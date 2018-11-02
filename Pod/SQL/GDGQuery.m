//
//  SQLQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGQuery.h"

#import "GDGColumn.h"
#import "SQLTableSource.h"
#import "SQLJoin.h"
#import "GDGFilter.h"
#import "NSError+GDG.h"

@interface GDGQuery ()

@property (readwrite, nonatomic) NSObject <GDGSource> *source;

@end

@implementation GDGQuery

#pragma mark - Initialization

- (instancetype)initWithSQLSource:(id <GDGSource>)source
{
	if (self = [self init])
		_source = source;

	return self;
}

- (instancetype)initWithQuery:(GDGQuery *)query
{
	if (self = [self initWithSQLSource:query.source])
	{
		_projection = [NSArray arrayWithArray:query.projection];
		_orderList = [NSArray arrayWithArray:query.orderList];
		_joins = [NSArray arrayWithArray:query.joins];
		_groups = [NSArray arrayWithArray:query.groups];
	}

	return self;
}

#pragma mark - Debug

- (NSString *)debugDescription
{
	NSMutableString *visit = [[NSMutableString alloc] initWithString:self.visit];
	NSDictionary *args = self.args;
	
	for (NSString *token in args.allKeys)
	{
		NSRange fullRange = NSMakeRange(0, visit.length);
		[visit replaceOccurrencesOfString:[@":" stringByAppendingString:token] withString:[args[token] stringValue] options:NSLiteralSearch range:fullRange];
	}
	
	return [NSString stringWithString:visit];
}

@end

@interface GDGMutableQuery ()

@property (strong, nonatomic) NSMutableArray *mutableProjection;
@property (strong, nonatomic) NSMutableArray *mutableOrderList;
@property (strong, nonatomic) NSMutableArray *mutableJoins;
@property (strong, nonatomic) NSMutableDictionary <NSString *, id> *mutableArgs;
@property (strong, nonatomic) NSMutableArray <GDGColumn *> *mutableGroups;

@end

@implementation GDGMutableQuery

@synthesize havingCondition = _havingCondition;
@synthesize whereCondition = _whereCondition;

- (instancetype)initWithQuery:(GDGQuery *)query
{
	if (self = [super initWithQuery:query])
	{
		_mutableProjection = [NSMutableArray arrayWithArray:query.projection];
		_mutableOrderList = [NSMutableArray arrayWithArray:query.orderList];
		_mutableJoins = [NSMutableArray arrayWithArray:query.joins];
		_mutableGroups = [NSMutableArray arrayWithArray:query.groups];
	}

	return self;
}

- (instancetype)initWithSQLSource:(id <GDGSource>)source
{
	GDGQuery *aQuery = [[GDGQuery alloc] initWithSQLSource:source];
	return [self initWithQuery:aQuery];
}

- (void)select:(NSArray <NSString *> __nonnull *)projection
{
	NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
	for (NSString *key in projection)
	{
		GDGColumn *column = [self.source.columns find:^BOOL(GDGColumn *object) {
			return [object.name isEqualToString:key];
		}]; // TODO Error handling?

		if (column)
			[validProjection addObject:column.fullName];
	}

	[_mutableProjection addObjectsFromArray:validProjection];
}

- (BOOL)joining:(SQLJoin __nonnull *)join error:(NSError **)error
{
	GDGJoin *alreadyAddedJoin = [_mutableJoins find:^BOOL(GDGJoin *object) {
		return [join.source.identifier isEqualToString:object.source.identifier];
	}];

	if (alreadyAddedJoin != nil)
	{
		if (error)
		{
			NSString *localizedDescription = NSStringWithFormat(@"[SQLQuery -join:] throws that access attempt to add multiple joins with the same identifier \"%@\"", join.source.identifier);
			NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey: localizedDescription };

			*error = [NSError errorWithDomain:GDGErrorDomain code:300 userInfo:errorInfo];
		}

		return NO;
	}

	NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:join.projection.count];
	GDGColumn *column;

	for (NSString *name in join.projection)
	{
		column = [join.source.columns find:^BOOL(GDGColumn *object) {
			return [name isEqualToString:object.name];
		}]; // TODO error handling?

		if (column)
			[validProjection addObject:column.fullName];
	}

	[_mutableProjection addObjectsFromArray:validProjection];
	[_mutableJoins addObject:join];

	return YES;
}

- (BOOL)filteredBy:(id <GDGFilter> __nonnull)filter error:(NSError **)error
{
	return [filter apply:self error:error];
}

- (void)addCondition:(GDGCondition __nonnull *)condition
{
	if (!_whereCondition)
		_whereCondition = [GDGCondition builder];

	_whereCondition.and.cat(condition);
}

- (void)groupBy:(GDGColumn __nonnull *)column
{
	[_mutableGroups addObject:column];
}

- (void)addGroupCondition:(GDGCondition __nonnull *)condition
{
	if (!_havingCondition)
		_havingCondition = [GDGCondition builder];

	_havingCondition.and.cat(condition);
}

- (void)orderBy:(GDGColumn __nonnull *)column order:(GDGQueryOrder)order
{
	[_mutableOrderList addObject:column.fullName];

	if (order == GDGQueryOrderAsc)
		[_mutableOrderList addObject:@"ASC"];
	else
		[_mutableOrderList addObject:@"DESC"];
}

- (void)clearProjection
{
	[_mutableProjection removeAllObjects];
}

// region Proxies

- (NSArray<NSString *> *)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSArray<SQLJoin *> *)joins
{
	return [NSArray arrayWithArray:_mutableJoins];
}

- (NSArray<NSString *> *)orderList
{
	return [NSArray arrayWithArray:_mutableOrderList];
}

- (NSArray<GDGColumn *> *)groups
{
	return [NSArray arrayWithArray:_mutableGroups];
}

// endregion

@end