//
//  GDGEntitySettings.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/21/16.
//

#import "GDGEntitySettings.h"

#import "GDGEntitySettings+Relations.h"
#import <objc/runtime.h>

@implementation GDGEntitySettings

- (instancetype)initWithEntityClass:(Class)entityClass tableSource:(GDGTableSource *)tableSource
{
	if (self = [super init])
	{
		_entityClass = entityClass;
		_tableSource = tableSource;
		self.relationNameDictionary = [NSMutableDictionary dictionary];
		self.valueTransformerDictionary = [NSMutableDictionary dictionary];
	}

	return self;
}

- (void)setColumnsDictionary:(NSDictionary<NSString *, NSString *> *)columnsDictionary
{
	_columnsDictionary = columnsDictionary;

	NSMutableDictionary *propertiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:columnsDictionary.count];

	for (NSString *key in columnsDictionary)
	{
		NSString *value = columnsDictionary[key];
		propertiesDictionary[value] = key;
	}

	_propertiesDictionary = propertiesDictionary;
}

@end
