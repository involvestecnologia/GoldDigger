//
//  GDGHasManyRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGHasManyRelation.h"

#import "GDGEntityQuery.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGCondition+EntityQuery.h"

@implementation GDGHasManyRelation

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

	GDGEntityQuery *query = self.relatedManager.query.copy;
	query.select(properties).where(^(GDGCondition *builder) {
		builder.prop(self.foreignProperty).inList(ids);
	});

	for (NSDictionary *relation in pulledRelations)
		query.pull(relation);

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
		});

	NSMutableDictionary<NSNumber *, NSMutableArray *> *idRelationDictionary = [[NSMutableDictionary alloc] init];

	for (GDGEntity *relatedEntity in query.array)
	{
		NSMutableArray *mutableEntities = relationEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];

		for (GDGEntity *entity in mutableEntities)
		{
			NSMutableArray *relations = idRelationDictionary[@([entity id])];
			if (relations == nil)
			{
				relations = [NSMutableArray array];
				idRelationDictionary[@([entity id])] = relations;
			}

			[relations addObject:relatedEntity];
		}
	}

	for (GDGEntity *entity in entities)
	{
		NSMutableArray *relatedEntities = idRelationDictionary[@([entity id])];

		[entity setValue:[NSArray arrayWithArray:relatedEntities] forKey:self.name];
	}
}

- (void)set:(NSArray <GDGEntity *> *)ownedEntities onEntity:(GDGEntity *)entity
{
	for (GDGEntity *owned in ownedEntities)
		[owned setValue:@(entity.id) forKey:self.foreignProperty];
}

- (void)save:(GDGEntity *)entity
{
	NSArray <GDGEntity *> *ownedEntities = [entity valueForKey:self.foreignProperty];
	for (GDGEntity *owned in ownedEntities)
		[owned.db save];
}

@end
