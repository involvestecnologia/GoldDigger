//
//  GDGHasManyThroughRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGHasManyThroughRelation.h"

#import <SQLAid/CIRStatement.h>
#import <SQLAid/CIRDatabase.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "SQLTableSource.h"
#import "GDGEntityMap.h"
#import "GDGEntity+SQL.h"
#import "SQLEntityQuery.h"
#import "SQLEntityMap.h"
#import "SQLJoin.h"
#import "GDGDatabaseProvider.h"
#import "GDGColumn.h"

#define kDEFAULT_ERROR_CODE         -101

@implementation GDGHasManyThroughRelation

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource
{
	@throw [NSException exceptionWithName:@"Join Condition Nonexistent"
	                               reason:@"[GDGHasManyThroughRelation -joinConditionFromSource:toSource:] thorws that "
			                               @"relations defined through third party tables can not provide a pattern of "
			                               @"join condition"
	                             userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name map:(GDGEntityMap *)map
{
	if (self = [super initWithName:name map:map])
	{
		NSString *className = [NSStringFromClass(map.entityClass) substringFromIndex:3];

		_localRelationColumn = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
	}

	return self;
}

- (void)fill:(NSArray <GDGEntity *> *)entities selecting:(NSArray *)properties
{
	NSArray <NSDictionary *> *pulledRelations = [properties select:^BOOL(id object) {
		return [object isKindOfClass:[NSDictionary class]];
	}];

	properties = [properties relativeComplement:pulledRelations];

	GDGEntityQuery *query = ((GDGMapping *) self.relatedMap).query.select(properties).distinct;

	for (NSDictionary *relation in pulledRelations)
		query.pull(relation);

	[self fill:entities fromQuery:query];
}

- (void)fill:(NSArray <GDGEntity *> *)entities fromQuery:(GDGEntityQuery *)query
{
	NSArray<NSNumber *> *ids = [entities map:^id(GDGEntity *object) {
		return object.id;
	}];

	NSMutableDictionary<NSNumber *, NSMutableArray<GDGEntity *> *> *relationEntitiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:entities.count];

	for (NSUInteger i = 0; i < entities.count; i++)
	{
		GDGEntity *entity = entities[i];
		NSNumber *foreignId = ids[i];

		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[foreignId];
		if (mutableEntities == nil)
		{
			mutableEntities = [NSMutableArray array];
			relationEntitiesDictionary[foreignId] = mutableEntities;
		}

		[mutableEntities addObject:entity];
	}

	GDGCondition *joinCondition = [GDGCondition builder].field(_relationSource[_foreignRelationColumn]).equals(self.relatedMap[@"id"]);

	query.where(^(GDGCondition *cond) {
		cond.field(_relationSource[_localRelationColumn]).in(ids);
	}).join([GDGJoin joinWithKind:SQLJoinKindInner condition:joinCondition source:_relationSource]);

	GDGQuery *relationQuery = [GDGQuery query].from(_relationSource)
			.select(@[_foreignRelationColumn, _localRelationColumn])
			.join([GDGJoin joinWithKind:SQLJoinKindInner
			                  condition:joinCondition
			                     source:((GDGMapping *) self.relatedMap).table])
			.where(^(GDGCondition *cond) {
				cond.field(_relationSource[_localRelationColumn]).in(ids);
			})
			.groupBy(_relationSource[_foreignRelationColumn])
			.asc(_localRelationColumn)
			.asc(_foreignRelationColumn);

	if (self.condition)
	{
		query.where(^(GDGCondition *cond) {
			cond.and.cat(self.condition);
		});

		relationQuery.where(^(GDGCondition *cond) {
			cond.and.cat(self.condition);
		});
	}

	NSArray *result = relationQuery.pluck;

	NSUInteger count = [result[0] count];

	NSMutableDictionary *relationIds = [[NSMutableDictionary alloc] initWithCapacity:count];

	for (NSUInteger i = 0; i < count; i++)
	{
		NSNumber *ownerId = result[1][i];
		NSNumber *relationId = result[0][i];

		NSMutableArray *relationsIds = relationIds[ownerId];
		if (relationsIds == nil)
		{
			relationsIds = [NSMutableArray array];
			relationIds[ownerId] = relationsIds;
		}

		[relationsIds addObject:relationId];
	}

	NSMutableDictionary<NSNumber *, NSMutableArray *> *idRelationDictionary = [[NSMutableDictionary alloc] initWithCapacity:count];
	NSMutableDictionary<NSNumber *, GDGEntity *> *relationIdDictionary = [[NSMutableDictionary alloc] initWithCapacity:count];

	for (GDGEntity *relatedEntity in query.array)
		relationIdDictionary[relatedEntity.id] = relatedEntity;

	for (NSNumber *ownerId in relationIds.allKeys)
	{
		NSMutableArray *idArray = relationIds[ownerId];
		NSMutableArray *relations = [[NSMutableArray alloc] initWithCapacity:idArray.count];

		for (NSNumber *relationId in idArray)
			[relations addObject:relationIdDictionary[relationId]];

		idRelationDictionary[ownerId] = relations;
	}

	for (GDGEntity *entity in entities)
	{
		NSMutableArray *relatedEntities = idRelationDictionary[entity.id];

		[entity setValue:[NSArray arrayWithArray:relatedEntities] forKey:self.name];
	}
}

- (BOOL)save:(GDGEntity *)entity error:(NSError **)error
{
	NSArray <NSNumber *> *relatedIds = [[(NSArray *) [entity valueForKey:self.name] select:^BOOL(GDGEntity *related) {
		return [related save:nil];
	}] map:^NSNumber *(GDGEntity *related) {
		return related.id;
	}];

	return [self insertOrReplaceOwner:entity.id forRelated:relatedIds error:error];
}

- (BOOL)insertOrReplaceOwner:(NSNumber *)ownerId forRelated:(NSArray <NSNumber *> *)related error:(NSError **)error
{
	NSString *sql = [NSString stringWithFormat:@"REPLACE INTO %@ (%@, %@, rowId) VALUES (?, ?, (SELECT rowId FROM %@ WHERE (%@ = ? AND %@ = ?)))",
	                                           _relationSource.name, _foreignRelationColumn, _localRelationColumn,
	                                           _relationSource.name, _foreignRelationColumn, _localRelationColumn];

	CIRDatabase *database = _relationSource.databaseProvider.database;
	CIRStatement *statement = [database prepareStatement:sql error:nil];

	for (NSNumber *relatedId in related)
	{
		[statement bindLong:[relatedId longValue] atIndex:1];
		[statement bindLong:[ownerId longValue] atIndex:2];
		[statement bindLong:[relatedId longValue] atIndex:3];
		[statement bindLong:[ownerId longValue] atIndex:4];

		if ([statement step] != SQLITE_DONE)
		{
			if (error)
				*error = [NSError errorWithDomain:@"com.CopyIsRight.GoldDigger" code:kDEFAULT_ERROR_CODE
				                         userInfo:@{NSLocalizedDescriptionKey : database.lastErrorMessage}];

			return NO;
		}

		[statement clearBindings];
		[statement reset];
	}

	return YES;
}

- (CIRStatement *)insertStatement
{
	NSString *sql = NSStringWithFormat(@"INSERT INTO %@ (%@, %@) VALUES (?, ?)",
			_relationSource.name, _foreignRelationColumn, _localRelationColumn);

	return [_relationSource.databaseProvider.database prepareStatement:sql error:nil];
}

@end
