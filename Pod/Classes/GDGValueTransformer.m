//
//  GDGValueTransformer.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGValueTransformer.h"

@implementation GDGValueTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

+ (instancetype)transformerFrom:(id (^)(id))fromDatabaseHandler to:(id (^)(id))toDatabaseHandler
{
	return [[self alloc] initWithFromDatabaseHandler:fromDatabaseHandler toDatabaseHandler:toDatabaseHandler];
}

- (instancetype)initWithFromDatabaseHandler:(id (^)(id))fromDatabaseHandler toDatabaseHandler:(id (^)(id))toDatabaseHandler
{
	if (self = [super init])
	{
		_toDatabase = toDatabaseHandler;
		_fromDatabase = fromDatabaseHandler;
	}

	return self;
}

- (id)transformedValue:(id)value
{
	return _fromDatabase(value);
}

- (id)reverseTransformedValue:(id)value
{
	return _toDatabase(value);
}

@end
