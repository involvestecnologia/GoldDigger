//
//  GDGRelation.m
//  Pods
//
//  Created by Pietro Caselani on 1/26/16.
//
//

#import "GDGRelation.h"

#import "GDGEntitySettings.h"
#import "GDGConditionBuilder.h"
#import "GDGTableSource.h"

@implementation GDGRelation

- (instancetype)initWithName:(NSString*)name manager:(GDGEntityManager*)manager
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
	
	NSString* className = [NSStringFromClass(relatedManager.settings.entityClass) substringFromIndex:3];
	
	_foreignProperty = [[className stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[className substringToIndex:1] lowercaseString]] stringByAppendingString:@"Id"];
}

- (NSString*)joinCondition
{
	NSMutableString *condition = [[NSMutableString alloc] initWithString:_relatedManager.settings.tableSource.alias];
	
	[condition appendFormat:@".%@", _foreignProperty];
	[condition appendFormat:@" = %@.id", _manager.settings.tableSource.alias];
	
	return [NSString stringWithString:condition];
}

- (void)fill:(NSArray<GDGEntity*>*)entities withProperties:(NSArray<NSString*>*)properties
{
	@throw [[NSException alloc] initWithName:@"Not Implemented" reason:@"TODO" userInfo:nil];
}

@end
