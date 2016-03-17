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
#import "GDGEntitySettings.h"
#import "GDGTableSource.h"

@implementation GDGBelongsToRelation

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray<NSString *> *)properties
{
	NSArray<NSNumber *> *ids = [entities map:^id(id object) {
		return [object valueForKey:self.foreignProperty];
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

	GDGEntityQuery *query = self.relatedManager.query.select(properties)
		.where(^(GDGCondition *builder) {
			builder.prop(@"id").inList(ids);
		});

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
		});

	for (GDGEntity *relatedEntity in query.array)
	{
		NSMutableArray<GDGEntity *> *mutableEntities = relationEntitiesDictionary[@([relatedEntity id])];
		for (GDGEntity *entity in mutableEntities)
			[entity setValue:relatedEntity forKey:self.name];
	}
}

- (NSString *)joinConditionForSource:(GDGSource *)source withSource:(GDGSource *)joinedSource
{
	NSMutableString *condition = [[NSMutableString alloc] initWithString:joinedSource.identifier];

	[condition appendFormat:@".%@ = %@.id", [self.manager columnNameForProperty:self.foreignProperty], source.identifier];

	return [NSString stringWithString:condition];
}

@end
