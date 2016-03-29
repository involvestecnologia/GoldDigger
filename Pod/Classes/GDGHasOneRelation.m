//
//  GDGHasOneRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGHasOneRelation.h"

#import "GDGEntityQuery.h"
#import "GDGCondition+EntityQuery.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

@implementation GDGHasOneRelation

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray<NSString *> *)properties
{
	NSArray<NSNumber *> *ids = [entities map:^id(GDGEntity *object) {
		return @(object.id);
	}];

	NSDictionary<NSNumber *, GDGEntity *> *idEntitiesDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

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

	NSMutableArray *unfilledEntities = [entities mutableCopy];

	for (GDGEntity *relatedEntity in query.array)
	{
		GDGEntity *entity = idEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];
		[entity setValue:relatedEntity forKey:self.name];

		[unfilledEntities removeObject:entity];
	}

	for (GDGEntity *unfilledEntity in unfilledEntities)
		[unfilledEntity setValue:nil forKey:self.name];
}

- (void)set:(GDGEntity *)value onEntity:(GDGEntity *)entity
{
	[value setValue:@(entity.id) forKey:self.foreignProperty];
}

- (void)save:(GDGEntity *)entity
{
	GDGEntity *owned = [entity valueForKey:self.foreignProperty];
	[owned.db save];
}

@end
