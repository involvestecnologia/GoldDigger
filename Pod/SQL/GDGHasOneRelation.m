//
//  GDGHasOneRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGHasOneRelation.h"

#import "GDGQuery.h"
#import "SQLEntityQuery.h"
#import "GDGCondition+Entity.h"
#import "GDGEntity.h"
#import "GDGColumn.h"
#import "GDGRecord+SQL.h"

@implementation GDGHasOneRelation

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource
{
	return [GDGCondition builder]
			.field(GDGRelationField(@"id", source))
			.equals(GDGRelationField(((GDGColumn *) self.relatedMap[self.foreignProperty]).name, joinedSource));
}

- (void)setRelatedMap:(GDGEntityMap *)relatedMap
{
	[super setRelatedMap:relatedMap];

	NSString *className = [NSStringFromClass(self.mapping.entityClass) substringFromIndex:3];

	self.foreignProperty = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
}

- (void)fill:(NSArray <GDGRecord *> *)entities selecting:(NSArray *)properties
{
	NSMutableDictionary *pulling = [NSMutableDictionary dictionary];
	NSMutableArray *selecting = [NSMutableArray array];

	for (id property in properties)
		if ([property isKindOfClass:[NSDictionary class]])
			[pulling addEntriesFromDictionary:property];
		else
			[selecting addObject:property];

	GDGEntityQuery *baseQuery = ((GDGMapping *)self.relatedMap).query;

	[self fill:entities fromQuery:baseQuery.select(selecting).pull(pulling)];
}

- (void)fill:(NSArray<GDGRecord *> *)entities fromQuery:(GDGEntityQuery *)query
{
	NSArray<NSNumber *> *ids = [entities map:^id(GDGRecord *entity) {
		return entity.id;
	}];

	NSDictionary<NSNumber *, GDGRecord *> *idEntitiesDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

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

	for (GDGRecord *relatedEntity in query.array)
	{
		GDGRecord *entity = idEntitiesDictionary[[relatedEntity valueForKey:self.foreignProperty]];

		[relatedEntity setValue:entity.id forKey:self.foreignProperty];
		[entity setValue:relatedEntity forKey:self.name];
		[unfilledEntities removeObject:entity];
	}

	for (GDGRecord *unfilledEntity in unfilledEntities)
		[unfilledEntity setValue:nil forKey:self.name];
}

- (BOOL)save:(GDGRecord *)entity error:(NSError **)error
{
	GDGRecord *related = [entity valueForKey:self.name];

	[related setValue:entity.id forKey:self.foreignProperty];

	return [related save:error];
}

@end
