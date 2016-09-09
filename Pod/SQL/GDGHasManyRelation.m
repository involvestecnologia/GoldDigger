//
//  GDGHasManyRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGHasManyRelation.h"

#import "GDGCondition+Entity.h"
#import "SQLEntityQuery.h"
#import "GDGEntity.h"
#import "GDGColumn.h"
#import "GDGEntity+SQL.h"
#import "SQLTableSource.h"
#import "GDGDatabaseProvider.h"
#import <SQLAid/CIRDatabase.h>

@implementation GDGHasManyRelation

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource
{
	return [GDGCondition builder]
			.field(GDGRelationField(@"id", source))
			.equals(GDGRelationField(((GDGColumn *) self.relatedMap[self.foreignProperty]).name, joinedSource));
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
	NSArray<NSNumber *> *ids = [entities map:^id(GDGEntity *entity) {
		return entity.id;
	}];

	NSMutableDictionary<id, NSMutableArray<GDGEntity *> *> *relationEntitiesDictionary = [NSMutableDictionary dictionaryWithCapacity:entities.count];

	for (NSUInteger i = 0; i < entities.count; i++)
	{
		GDGEntity *entity = entities[i];
		id foreignId = ids[i];

		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[foreignId];
		if (mutableEntities == nil)
		{
			mutableEntities = [NSMutableArray array];
			relationEntitiesDictionary[foreignId] = mutableEntities;
		}

		[mutableEntities addObject:entity];
	}

	query.where(^(GDGCondition *builder) {
		builder.prop(self.foreignProperty).in(ids);
	});

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.build(^(GDGCondition *catBuilder) {
				catBuilder.cat(self.condition);
			});
		});

	NSMutableDictionary<id, NSMutableArray *> *idRelationDictionary = [NSMutableDictionary dictionary];

	for (GDGEntity *relatedEntity in query.array)
	{
		NSMutableArray *mutableEntities = relationEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];

		for (GDGEntity *entity in mutableEntities)
		{
			NSMutableArray *relations = idRelationDictionary[entity.id];
			if (relations == nil)
			{
				relations = [NSMutableArray array];
				idRelationDictionary[entity.id] = relations;
			}

			[relatedEntity setValue:entity.id forKey:self.foreignProperty];

			[relations addObject:relatedEntity];
		}
	}

	for (GDGEntity *entity in entities)
	{
		NSMutableArray *relatedEntities = idRelationDictionary[[entity id]];

		[entity setValue:[NSArray arrayWithArray:relatedEntities] forKey:self.name];
	}
}

- (void)hasBeenSetOnEntity:(GDGEntity *)entity
{
	if (entity.id != nil)
		for (GDGEntity *owned in [entity valueForKey:self.name])
			[owned setValue:entity.id forKey:self.foreignProperty];
}

- (BOOL)save:(GDGEntity *)entity error:(NSError **)error
{
	for (GDGEntity *related in [entity valueForKey:self.name])
	{
		[related setValue:entity.id forKey:self.foreignProperty];
		if (![related save:error])
			return NO;
	}

	return YES;
}

@end
