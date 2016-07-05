//
//  GDGRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGRelation.h"

#import "GDGEntityMap.h"
#import "GDGQuery.h"

@implementation GDGRelationField

+ (instancetype)relationFieldWithName:(NSString *)name
                               source:(id <GDGSource>)source
{
	GDGRelationField *conditionField = [[GDGRelationField alloc] init];
	conditionField->_name = name;
	conditionField->_source = source;

	return conditionField;
}

- (NSString *)fullName
{
	return [NSString stringWithFormat:@"%@.%@", _source.identifier, _name];
}

@end

@implementation GDGRelation

- (instancetype)initWithName:(NSString *)name map:(GDGEntityMap *)map
{
	if (self = [super init])
	{
		_name = name;
		_map = map;
	}

	return self;
}

- (void)setRelatedMap:(GDGEntityMap *)relatedMap
{
	NSString *className = [NSStringFromClass(relatedMap.entityClass) substringFromIndex:3];

	_relatedMap = relatedMap;

	_foreignProperty = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
}

- (void)hasBeenSetOnEntity:(GDGEntity *)entity;
{
	// Default implementation does nothing
}

#pragma mark - Abstract

- (void)fill:(NSArray<GDGEntity *> *)entities fromQuery:(__kindof GDGQuery *)query
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Exception"
	                               reason:@"[GDGRelation -fill:fromQuery:] throws that child classes must override this method"
	                             userInfo:nil];
}

#pragma mark - Convenience

- (GDGCondition *)joinConditionFromSource:(id <GDGSource>)source toSource:(id <GDGSource>)joinedSource
{
	return [GDGCondition builder]
			.field(GDGRelationField(@"id", source))
			.equals(GDGRelationField(self.relatedMap[self.foreignProperty], joinedSource));
}

- (GDGCondition *)joinCondition
{
	return [self joinConditionFromSource:_map.source toSource:_relatedMap.source];
}

@end
