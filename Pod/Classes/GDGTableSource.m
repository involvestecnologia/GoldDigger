//
//  GDGTableSource.m
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGTableSource.h"

#import "GDGSource_Protected.h"

@implementation GDGTableSource

- (instancetype)initWithName:(NSString*)tableName columns:(NSArray<GDGColumn*>*)columns
{
	if (self = [super init])
	{
		self.alias = _name = tableName;
		self.columns = columns;
	}
	
	return self;
}

@end
