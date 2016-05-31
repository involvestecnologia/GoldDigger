//
//  SQLJoin.m
//  GoldDigger
//
//  Created by Felipe Lobo on 4/7/16.
//

#import "SQLJoin.h"
#import "SQLSource.h"


@implementation SQLJoin

+ (instancetype)joinWithKind:(SQLJoinKind)kind condition:(GDGCondition *)condition source:(id <GDGSource>)source
{
	SQLJoin *join = [[SQLJoin alloc] initWithCondition:condition source:source];
	join->_kind = kind;

	return join;
}

- (instancetype)initWithCondition:(GDGCondition *)condition source:(id <GDGSource>)source
{
	if (self = [super initWithCondition:condition source:source])
		_projection = [NSMutableArray array];

	return self;
}

- (void)select:(NSArray <NSString *> *)projection
{
	[_projection addObjectsFromArray:projection];
}

@end
