//
//  GDGHasManyThroughRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGHasManyThroughRelation.h"

#import "GDGEntityQuery.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGCondition+EntityQuery.h"
#import "GDGSource.h"
#import "GDGTableSource.h"
#import "GDGEntitySettings.h"

@implementation GDGHasManyThroughRelation

- (instancetype)initWithName:(NSString *)name manager:(GDGEntityManager *)manager
{
	if (self = [super initWithName:name manager:manager])
	{
		NSString *className = [NSStringFromClass(manager.settings.entityClass) substringFromIndex:3];

		_ownerRelationColumn = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
	}

	return self;
}

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray *)properties
{
	NSArray<NSNumber *> *ids = [entities map:^id(GDGEntity *object) {
		return @(object.id);
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

	NSArray <NSDictionary *> *pulledRelations = [properties select:^BOOL(id object) {
		return [object isKindOfClass:[NSDictionary class]];
	}];

	properties = [[properties relativeComplement:pulledRelations] arrayByAddingObject:self.foreignProperty];

	GDGCondition *joinCondition = [GDGCondition builder].col([_relationSource columnNamed:_foreignRelationColumn]).equals([self.relatedManager columnForProperty:@"id"]);

	GDGEntityQuery *query = self.relatedManager.query.copy;
	query.select(properties).join(_relationSource, @"INNER", joinCondition, nil).where(^(GDGCondition *builder) {
		builder.col([_relationSource columnNamed:_ownerRelationColumn]).inList(ids);
	});

	GDGQuery *relationQuery = [[GDGQuery alloc] initWithSource:_relationSource].select(@[_foreignRelationColumn, _ownerRelationColumn])
			.join(self.relatedManager.settings.tableSource, @"INNER", joinCondition, nil)
			.where(^(GDGCondition *condition) {
				condition.col([_relationSource columnNamed:_ownerRelationColumn]).inList(ids);
			}).asc(_ownerRelationColumn).asc(_foreignRelationColumn);

	for (NSDictionary *relation in pulledRelations)
		query.pull(relation);

	if (self.condition)
	{
		query.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
		});

		relationQuery.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
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
		relationIdDictionary[@(relatedEntity.id)] = relatedEntity;

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
		NSMutableArray *relatedEntities = idRelationDictionary[@([entity id])];

		[entity setValue:[NSArray arrayWithArray:relatedEntities] forKey:self.name];
	}
}

- (void)set:(__kindof NSObject *)value onEntity:(GDGEntity *)entity {}

@end