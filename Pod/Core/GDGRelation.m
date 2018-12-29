//
//  GDGRelation.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGRelation.h"

#import "GDGQuery.h"
#import "GDGMapping.h"
#import "GDGSource.h"
#import "GDGRelationField.h"

@implementation GDGRelation

- (instancetype)initWithName:(NSString *)name mapping:(GDGMapping *)mapping
{
	if (self = [super init])
	{
		_name = name;
		_mapping = mapping;
	}

	return self;
}

- (void)hasBeenSetOnEntity:(GDGEntity *)entity;
{
	NSLog(@"The default implementation of GDGRelation's -hasBeenSetOnEntity: does nothing");
}

- (BOOL)save:(GDGEntity *)entity error:(NSError **)error
{
	NSLog(@"The default implementation of GDGRelation's -save:error: does nothing and returns true");
	return YES;
}

#pragma mark - Abstract

- (BOOL)fill:(NSArray <GDGEntity *> *)entities selecting:(NSArray *)properties error:(NSError **)error
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Exception"
	                               reason:@"[GDGRelation -fill:selecting:] throws that child classes must override this method"
	                             userInfo:nil];
}

- (BOOL)fill:(NSArray<GDGEntity *> *)entities fromQuery:(GDGQuery *)query error:(NSError **)error
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Exception"
	                               reason:@"[GDGRelation -fill:fromQuery:] throws that child classes must override this method"
	                             userInfo:nil];
}

#pragma mark - Convenience

- (GDGCondition *)joinCondition
{
	NSError *error;

	id <GDGSource> source = _mapping.source;
	id <GDGSource> joinedSource = _relatedMapping.source;
	NSString *related = _relatedMapping[_foreignProperty];

	if (!related)
	{
		@throw [NSException exceptionWithName:@"Relation Join Condition Exception"
		                               reason:@"[GDGRelation -joinCondition] throws that a condition coming directly from from a "
		                             userInfo:nil];
	}

	return [GDGCondition builder]
			.field(GDGRelationField(@"id", source))
			.equals(GDGRelationField(related, joinedSource));
}

@end
