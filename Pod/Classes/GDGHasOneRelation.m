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
	NSArray<NSNumber *> *ids = [entities map:^id(id object) {
		return @([object id]);
	}];

	NSDictionary<NSNumber *, GDGEntity *> *idEntitiesDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

	NSMutableArray *mutableProperties = [NSMutableArray arrayWithArray:properties];
	[mutableProperties addObject:self.foreignProperty];

	GDGEntityQuery *query = self.relatedManager.query.select([NSArray arrayWithArray:mutableProperties])
			.where(^(GDGCondition *builder) {
				builder.prop(self.foreignProperty).inList(ids);
			});

	if (self.condition)
		query.where(^(GDGCondition *builder) {
			builder.and.cat(self.condition);
		});

	for (GDGEntity *relatedEntity in query.array)
	{
		GDGEntity *entity = idEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];
		[entity setValue:relatedEntity forKey:self.name];
	}
}

@end
