//
//  GDGBelongsToRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGBelongsToRelation.h"

#import "GDGCondition+EntityQuery.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGEntityQuery.h"
#import "GDGTableSource.h"

@implementation GDGBelongsToRelation

- (GDGCondition *)joinConditionFromSource:(GDGSource *)source toSource:(GDGSource *)joinedSource
{
	return [GDGCondition builder].col([joinedSource columnNamed:[self.manager columnNameForProperty:self.foreignProperty]]).equals([source columnNamed:@"id"]);
}

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray *)properties
{
	NSArray *ids = [entities map:^id(id object) {
		return [object valueForKey:self.foreignProperty] ?: [NSNull null];
	}];

	NSMutableDictionary<NSNumber *, NSMutableArray<GDGEntity *> *> *relationEntitiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:entities.count];
	for (NSUInteger i = 0; i < entities.count; i++)
	{
		id foreignId = ids[i];
		if (foreignId == [NSNull null])
			continue;

		GDGEntity *entity = entities[i];

		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[foreignId];
		if (mutableEntities == nil)
		{
			mutableEntities = [NSMutableArray array];
			relationEntitiesDictionary[foreignId] = mutableEntities;
		}

		[mutableEntities addObject:entity];
	}

	ids = [ids select:^BOOL(id object) {
		return object != [NSNull null];
	}];

	GDGEntityQuery *query = self.baseQuery.copy;

	NSArray <NSDictionary *> *pulledRelations = [properties select:^BOOL(id object) {
		return [object isKindOfClass:[NSDictionary class]];
	}];
	properties = [properties relativeComplement:pulledRelations];

	query.select(properties).where(^(GDGCondition *builder) {
		builder.prop(@"id").inList(ids);
	});

	for (NSDictionary *relation in pulledRelations)
		query.pull(relation);

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
		});

	NSMutableArray *unfilledEntities = [entities mutableCopy];

	for (GDGEntity *relatedEntity in query.array)
	{
		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[@(relatedEntity.id)];
		for (GDGEntity *entity in mutableEntities)
		{
			[entity setValue:relatedEntity forKey:self.name];
			[unfilledEntities removeObject:entity];
		}
	}

	for (GDGEntity *unfilledEntity in unfilledEntities)
		[unfilledEntity setValue:nil forKey:self.name];
}

- (void)set:(GDGEntity *)value onEntity:(GDGEntity *)entity
{
	[entity setValue:@(value.id) forKey:self.foreignProperty];
}

@end
