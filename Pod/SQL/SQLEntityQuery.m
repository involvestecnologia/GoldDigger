//
//  SQLEntityQuery.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/8/16.
//

#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import <ObjectiveSugar/NSString+ObjectiveSugar.h>
#import "SQLQuery_Protected.h"
#import "SQLEntityQuery.h"

#import "GDGEntityMap.h"
#import "GDGColumn.h"
#import "GDGCondition+Entity.h"
#import "GDGRelation.h"
#import "SQLJoin.h"
#import "SQLSource.h"
#import "SQLEntityMap.h"
#import "GDGEntity+SQL.h"

@interface SQLEntityQuery ()

@property (readwrite, nonatomic) NSMutableDictionary <NSString *, NSArray *> *mutablePulledRelations;

@end

@implementation SQLEntityQuery

- (instancetype)initWithEntityMap:(SQLEntityMap *)map
{
	if (self = [super initWithSQLSource:map.source])
	{
		_mutablePulledRelations = [NSMutableDictionary dictionary];

		__weak typeof(self) weakSelf = self;

		_pull = ^SQLEntityQuery *(NSDictionary <NSString *, NSArray *> *pulledRelations) {
			[weakSelf pull:pulledRelations];
			return weakSelf;
		};

		_withId = ^SQLEntityQuery *(id identifier) {
			return weakSelf.where(^(GDGCondition *condition) {
				condition.field(map[@"id"]).equals(identifier);
			});
		};

		_map = map;

		self.whereCondition.map = map;
	}

	return self;
}

#pragma mark - Private impl

- (void)select:(NSArray <NSString *> *)projection
{
	projection = [[self.map mappedValuesFromProperties:projection] map:^id(GDGColumn *column) {
		return column.fullName;
	}];

	[self.mutableProjection addObjectsFromArray:projection];
}

- (void)join:(SQLJoin *)join
{
	NSArray *actualProjection = [[self.map mappedValuesFromProperties:join.projection] map:^id(GDGColumn *column) {
		return column.fullName;
	}];

	GDGJoin *alreadyAddedJoin = [self.mutableJoins find:^BOOL(GDGJoin *object) {
		return [join.source.identifier isEqualToString:object.source.identifier];
	}];

	if (alreadyAddedJoin != nil)
		@throw [NSException exceptionWithName:@"SQL Entity Query Join Exception"
		                               reason:NSStringWithFormat(@"[SQLEntityQuery -join:] throws that access attempt to add multiple joins with the same identifier \"%@\"", join.source.identifier)
		                             userInfo:nil];

	[self.mutableProjection addObjectsFromArray:actualProjection];
	[self.mutableJoins addObject:join];
}

- (void)asc:(NSString *)prop
{
	[super asc:[(GDGColumn *)self.map.fromToDictionary[prop] fullName]];
}

- (void)desc:(NSString *)prop
{
	[super desc:[(GDGColumn *)self.map.fromToDictionary[prop] fullName]];
}

- (void)pull:(NSDictionary <NSString *, NSArray *> *)relations
{
	for (NSString *relationName in relations.keyEnumerator)
	{
		GDGRelation *relation = self.map.fromToDictionary[relationName];
		if (relation != nil)
			[self select:@[relation.foreignProperty]];
	}

	[self.mutablePulledRelations addEntriesFromDictionary:relations];
}

#pragma mark - Convenience

- (NSArray<__kindof GDGEntity *> *)array
{
	Class entityClass = self.map.entityClass;
	return [entityClass entitiesFromQuery:self];
}

- (__kindof GDGEntity *)object
{
	Class entityClass = self.map.entityClass;
	return [entityClass entityFromQuery:self];
}

#pragma mark - Copying

- (instancetype)copyWithZone:(NSZone *)zone
{
	SQLEntityQuery *copy = [super copyWithZone:zone];

	__weak typeof(copy) weakCopy = copy;

	copy->_mutablePulledRelations = [_mutablePulledRelations mutableCopy];
	copy->_map = _map;

	copy->_pull = ^SQLEntityQuery *(NSDictionary <NSString *, NSArray *> *pulledRelations) {
		[weakCopy pull:pulledRelations];
		return weakCopy;
	};

	copy->_withId = ^SQLEntityQuery *(id identifier) {
		return weakCopy.where(^(GDGCondition *condition) {
			condition.field(weakCopy.map[@"id"]).equals(identifier);
		});
	};

	copy.whereCondition.map = _map;

	return copy;
}

#pragma mark - Proxy

- (NSDictionary <NSString *, NSArray *> *)pulledRelations
{
	return [NSDictionary dictionaryWithDictionary:self.mutablePulledRelations];
}

@end
