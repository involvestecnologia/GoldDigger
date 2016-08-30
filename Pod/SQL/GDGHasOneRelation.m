//
//  GDGHasOneRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGHasOneRelation.h"

#import "SQLQuery.h"
#import "SQLEntityQuery.h"
#import "GDGCondition+Entity.h"
#import "GDGEntity.h"
#import "GDGColumn.h"
#import "GDGEntity+SQL.h"

@implementation GDGHasOneRelation

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

	NSDictionary<NSNumber *, GDGEntity *> *idEntitiesDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

	query.where(^(GDGCondition *builder) {
		builder.prop(self.foreignProperty).in(ids);
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
		GDGEntity *entity = idEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];

		[relatedEntity setValue:entity.id forKey:self.foreignProperty];
		[entity setValue:relatedEntity forKey:self.name];
		[unfilledEntities removeObject:entity];
	}

	for (GDGEntity *unfilledEntity in unfilledEntities)
		[unfilledEntity setValue:nil forKey:self.name];
}

- (void)save:(GDGEntity *)entity
{
	GDGEntity *related = [entity valueForKey:self.name];

	[related setValue:entity.id forKey:self.foreignProperty];
	[related save:nil];
}

@end
