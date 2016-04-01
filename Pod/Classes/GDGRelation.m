//
//  GDGRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGRelation.h"

#import "GDGEntitySettings.h"
#import "GDGTableSource.h"
#import "GDGEntityQuery.h"
#import "GDGCondition.h"

@implementation GDGRelation

- (instancetype)initWithName:(NSString *)name manager:(GDGEntityManager *)manager
{
	if (self = [super init])
	{
		_name = name;
		_manager = manager;
	}

	return self;
}

- (void)setRelatedManager:(GDGEntityManager *)relatedManager
{
	_relatedManager = relatedManager;

	NSString *className = [NSStringFromClass(relatedManager.settings.entityClass) substringFromIndex:3];

	_foreignProperty = [[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
}

- (GDGEntityQuery *)baseQuery
{
	return _relatedManager.query.copy;
}

- (GDGCondition *)joinCondition
{
	return [self joinConditionFromSource:_manager.settings.tableSource toSource:_relatedManager.settings.tableSource];
}

- (GDGCondition *)joinConditionFromSource:(GDGSource *)source toSource:(GDGSource *)joinedSource
{
	return [GDGCondition builder].col([joinedSource columnNamed:@"id"]).equals([source columnNamed:[_manager columnNameForProperty:_foreignProperty]]);
}

- (void)save:(GDGEntity *)entity
{
	// Default implementation does nothing
}

#pragma mark - Abstract

- (void)fill:(NSArray<GDGEntity *> *)entities withProperties:(NSArray *)properties
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Exception"
	                               reason:@"[GDGRelation -fill:withProperties:] throws that child classes must override this method"
	                             userInfo:nil];
}

- (void)set:(__kindof NSObject *)value onEntity:(GDGEntity *)entity
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Exception"
	                               reason:@"[GDGRelation -set:onEntity:] throws that child classes must override this method"
	                             userInfo:nil];
}

@end
