//
//  GDGEntitySettings.m
//  RuntimeiOS
//
//  Created by Pietro Caselani on 1/21/16.
//  Copyright © 2016 Pietro Caselani. All rights reserved.
//

#import "GDGEntitySettings.h"

#import "GDGEntitySettings_Relations.h"
#import <objc/runtime.h>

@implementation GDGEntitySettings

- (instancetype)initWithEntityClass:(Class)entityClass
{
	if (self = [super init])
	{
		_entityClass = entityClass;
		_relationNameDictionary = [NSMutableDictionary dictionary];
		_valueAdapterDictionary = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void)addValueAdpter:(NSValueTransformer*)valueAdapter forPropertyNamed:(NSString*)propertyName
{
	_valueAdapterDictionary[propertyName] = valueAdapter;
}

- (void)setColumnsDictionary:(NSDictionary<NSString*,NSString*>*)columnsDictionary
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
