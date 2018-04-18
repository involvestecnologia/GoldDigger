//
//  GDGBelongsToRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGBelongsToRelation.h"
#import "GDGCondition+Entity.h"
#import "GDGEntity+SQL.h"
#import "GDGColumn.h"
#import "SQLEntityQuery.h"

@implementation GDGBelongsToRelation

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource
{
	return [GDGCondition builder]
			.field([GDGRelationField relationFieldWithName:((GDGColumn *) self.map[self.foreignProperty]).name source:source])
			.equals([GDGRelationField relationFieldWithName:@"id" source:joinedSource]);
}

- (void)setRelatedMap:(GDGEntityMap *)relatedMap
{
	[super setRelatedMap:relatedMap];

	NSString *className = [NSStringFromClass(relatedMap.entityClass) substringFromIndex:3];

	self.foreignProperty = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
}

- (void)fill:(NSArray <GDGEntity *> *)entities selecting:(NSArray *)properties
{
	NSMutableDictionary *pulling = [NSMutableDictionary dictionary];
	NSMutableArray *selecting = [NSMutableArray array];

	for (id property in properties)
		if ([property isKindOfClass:[NSDictionary class]])
			[pulling addEntriesFromDictionary:property];
		else
			[selecting addObject:property];

	SQLEntityQuery *baseQuery = ((SQLEntityMap *)self.relatedMap).query;

	[self fill:entities fromQuery:baseQuery.select(selecting).pull(pulling)];
}

- (void)fill:(NSArray<GDGEntity *> *)entities fromQuery:(SQLEntityQuery *)query
{
	NSMutableArray *ids = [NSMutableArray arrayWithArray:[entities map:^id(id object) {
		return [object valueForKey:self.foreignProperty] ?: [NSNull null];
	}]];

	NSMutableDictionary<id, NSMutableArray<GDGEntity *> *> *relationEntitiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:entities.count];
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

	ids = (NSMutableArray *) [ids keepIf:^BOOL(id object) {
		return object != [NSNull null];
	}];

	if (ids.count == 0) return;

	query.where(^(GDGCondition *builder) {
		builder.prop(@"id").in(ids);
	});

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.build(^(GDGCondition *catBuilder) {
				catBuilder.cat(self.condition);
			});
		});

	NSMutableArray *unfilledEntities = [entities mutableCopy];

	for (GDGEntity *relatedEntity in query.array)
	{
		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[relatedEntity.id];
		for (GDGEntity *entity in mutableEntities)
		{
			[entity setValue:relatedEntity forKey:self.name];
			[entity setValue:relatedEntity.id forKey:self.foreignProperty];
			[unfilledEntities removeObject:entity];
		}
	}

	for (GDGEntity *unfilledEntity in unfilledEntities)
		[unfilledEntity setValue:nil forKey:self.name];
}

- (BOOL)save:(GDGEntity *)entity error:(NSError **)error
{
	GDGEntity *related = [entity valueForKey:self.name];

	if ([related save:error])
	{
		[entity setValue:related.id forKey:self.foreignProperty];
		return YES;
	}

	return NO;
}

- (void)hasBeenSetOnEntity:(GDGEntity *)entity
{
	[entity setValue:[[entity valueForKey:self.name] id] forKey:self.foreignProperty];
}

@end
