//
//  GDGQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGColumn.h"
#import "GDGFilter.h"
#import "GDGJoin.h"
#import "GDGQuery.h"
#import "GDGMapping.h"
#import "GDGSource.h"
#import "GDGTable.h"
#import "NSError+GDG.h"

@interface GDGQuery ()

@property (readwrite, nonatomic) NSObject <GDGSource> *source;

@end

@implementation GDGQuery

- (instancetype)initWithSource:(id <GDGSource>)source
{
	if (self = [self init])
		_source = source;

	return self;
}

- (instancetype)initWithQuery:(GDGQuery *)query
{
	if (self = [self initWithSource:query.source])
	{
		_projection = [NSArray arrayWithArray:query.projection];
		_orderList = [NSArray arrayWithArray:query.orderList];
		_joins = [NSArray arrayWithArray:query.joins];
		_groups = [NSArray arrayWithArray:query.groups];
	}

	return self;
}

- (instancetype)initWithMapping:(GDGMapping *)mapping
{
	GDGTable *table = mapping.table;

	if (self = [self initWithSource:table])
		_mapping = mapping;

	return self;
}

@end

@interface GDGMutableQuery ()

@property (strong, nonatomic) NSMutableArray *mutableProjection;
@property (strong, nonatomic) NSMutableArray *mutableOrderList;
@property (strong, nonatomic) NSMutableArray *mutableJoins;
@property (strong, nonatomic) NSMutableDictionary <NSString *, id> *mutableArgs;
@property (strong, nonatomic) NSMutableArray <GDGColumn *> *mutableGroups;
@property (strong, nonatomic) NSMutableDictionary <NSString *, NSArray *> *mutablePulledRelations;

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
		_mutablePulledRelations = [NSMutableDictionary dictionaryWithDictionary:query.pulledRelations];
	}

	return self;
}

- (instancetype)initWithSource:(id <GDGSource>)source
{
	GDGQuery *aQuery = [[GDGQuery alloc] initWithSource:source];
	return [self initWithQuery:aQuery];
}

- (void)select:(NSArray <NSString *> *)projection
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

- (BOOL)join:(GDGJoin *)join error:(NSError **)error
{
	GDGJoin *alreadyAddedJoin = [_mutableJoins find:^BOOL(GDGJoin *object) {
		return [join.source.identifier isEqualToString:object.source.identifier];
	}];

	if (alreadyAddedJoin != nil)
	{
		if (error)
		{
			NSString *message = NSStringWithFormat(@"[GDGQuery -join:] throws that access attempt to add multiple joins with the same identifier \"%@\"", join.source.identifier);
			*error = [NSError errorWithCode:GDGQueryDuplicateJoinError
									message:message
								 underlying:nil];
		}

		return NO;
	}

	return YES;
}

- (BOOL)filteredBy:(id <GDGFilter>)filter error:(NSError **)error
{
	return [filter apply:self error:error];
}

- (BOOL)pull:(NSDictionary <NSString *, NSArray *> *)relations error:(NSError **)error
{
	if (self.map == nil)
	{
		*error = [NSError errorWithCode:GDGQueryPullWithNoMapError
		                        message:@"[GDGQuery -join:] throws that you tried to pull relations not having an entity map";
		                     underlying:nil];

		return NO;
	}

	for (NSString *relationName in relations.keyEnumerator)
	{
		GDGRelation *relation = self.map.fromToDictionary[relationName];
		if (relation.foreignProperty != nil)
			[self select:@[relation.foreignProperty]];
	}

	[self.mutablePulledRelations addEntriesFromDictionary:relations];
}

- (void)addCondition:(GDGCondition *)condition
{
	if (!_whereCondition)
		_whereCondition = [GDGCondition builder];

	_whereCondition.and.cat(condition);
}

- (void)groupBy:(GDGColumn *)column
{
	[_mutableGroups addObject:column];
}

- (void)addGroupCondition:(GDGCondition *)condition
{
	if (!_havingCondition)
		_havingCondition = [GDGCondition builder];

	_havingCondition.and.cat(condition);
}

- (void)orderBy:(GDGColumn *)column order:(GDGQueryOrder)order
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

#pragma mark - Proxies

- (NSArray<NSString *> *)projection
{
	return [NSArray arrayWithArray:_mutableProjection];
}

- (NSArray<GDGJoin *> *)joins
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

- (NSDictionary <NSString *, NSArray *> *)pulledRelations
{
	return [NSDictionary dictionaryWithDictionary:_mutablePulledRelations];
}

@end
