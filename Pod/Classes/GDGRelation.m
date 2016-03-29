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

- (NSString *)joinCondition
{
	return [self joinConditionFromSource:_manager.settings.tableSource toSource:_relatedManager.settings.tableSource];
}

- (NSString *)joinConditionFromSource:(GDGSource *)source toSource:(GDGSource *)joinedSource
{
	NSMutableString *condition = [[NSMutableString alloc] initWithString:joinedSource.identifier];

	[condition appendFormat:@".id = %@.%@", source.identifier, [_manager columnNameForProperty:_foreignProperty]];

	return [NSString stringWithString:condition];
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
