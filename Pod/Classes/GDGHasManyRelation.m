//
//  GDGHasManyRelation.m
//  Pods
//
//  Created by Pietro Caselani on 1/26/16.
//
//

#import "GDGHasManyRelation.h"

#import "GDGEntityQuery.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGConditionBuilder+EntityQuery.h"

@implementation GDGHasManyRelation

- (void)fill:(NSArray<GDGEntity*>*)entities withProperties:(NSArray<NSString*>*)properties
{
	NSArray<NSNumber*>* ids = [entities map:^id(id object) {
		return @([object id]);
	}];
	
	NSMutableDictionary<NSNumber*, NSMutableArray<GDGEntity*>*>* relationEntitiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:entities.count];
	
	for (int i = 0; i < entities.count; i++)
	{
		GDGEntity* entity = entities[i];
		NSNumber* foreignId = ids[i];
		
		NSMutableArray<GDGEntity*>* mutableEntities = relationEntitiesDictionary[foreignId];
		if (mutableEntities == nil)
		{
			mutableEntities = [NSMutableArray array];
			relationEntitiesDictionary[foreignId] = mutableEntities;
		}
		
		[mutableEntities addObject:entity];
	}
	
	NSMutableArray* mutableProperties = [NSMutableArray arrayWithArray:properties];
	
	[mutableProperties addObject:self.foreignProperty];
	
	GDGEntityQuery* query = self.relatedManager.query.select([NSArray arrayWithArray:mutableProperties])
		.where(^(GDGConditionBuilder *builder) {
			builder.prop(self.foreignProperty).inList(ids);
		});
	
	if (self.condition)
		query.where(^(GDGConditionBuilder *builder) {
			builder.and.cat(self.condition);
		});
	
	NSMutableDictionary<NSNumber*, NSMutableArray*>* idRelationDictionary = [[NSMutableDictionary alloc] init];
	
	for (GDGEntity* relatedEntity in query.array)
	{
		NSMutableArray* mutableEntities = relationEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];
		
		for (GDGEntity* entity in mutableEntities)
		{
			NSMutableArray* relations = idRelationDictionary[@([entity id])];
			if (relations == nil)
			{
				relations = [NSMutableArray array];
				idRelationDictionary[@([entity id])] = relations;
			}
			
			[relations addObject:relatedEntity];
		}
	}
	
	for (GDGEntity* entity in entities)
	{
		NSMutableArray* relatedEntities = idRelationDictionary[@([entity id])];
		
		[entity setValue:[NSArray arrayWithArray:relatedEntities] forKey:self.name];
	}
}

@end
