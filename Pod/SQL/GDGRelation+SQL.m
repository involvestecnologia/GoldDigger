//
//  GDGRelation+SQL.m
//  Pods
//
//  Created by Felipe Lobo on 5/9/16.
//

#import "GDGRelation+SQL.h"
#import "SQLEntityQuery.h"

@implementation GDGRelation (SQL)

- (SQLEntityQuery *)baseQuery
{
	@throw [NSException exceptionWithName:@"Abstract Implementation Required"
	                               reason:@"[GDGRealtion+SQL baseQuery] throws that 'baseQuery' method should be overrided by it's subclasses"
	                             userInfo:nil];
}

@end