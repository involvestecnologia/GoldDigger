//
//  GDGTableSource.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <SQLAid/CIRDatabase.h>
#import "GDGTableSource.h"

#import "GDGSource_Protected.h"
#import "CIRResultSet.h"
#import "CIRDatabase+GoldDigger.h"

@implementation GDGTableSource

+ (instancetype)tableSourceFromTable:(NSString *)tableName
{
	return [self tableSourceFromTable:tableName in:[CIRDatabase goldDigger_mainDatabase]];
}

+ (instancetype)tableSourceFromTable:(NSString *)tableName in:(CIRDatabase *)database
{
	CIRResultSet *resultSet = [database executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName]];

	NSMutableArray<GDGColumn *> *columns = [[NSMutableArray alloc] init];

	while ([resultSet next])
	{
		NSString *name = [resultSet textAtIndex:1];
		GDGColumnType type = [GDGColumn columnTypeFromTypeName:[resultSet textAtIndex:2]];
		BOOL notNull = [resultSet boolAtIndex:3];
		BOOL primaryKey = [resultSet boolAtIndex:5];

		[columns addObject:[[GDGColumn alloc] initWithName:name type:type primaryKey:primaryKey notNull:notNull]];
	}

	return [[GDGTableSource alloc] initWithName:tableName columns:[NSArray arrayWithArray:columns]];
}

- (instancetype)initWithName:(NSString *)tableName columns:(NSArray<GDGColumn *> *)columns
{
	if (self = [super init])
	{
		self.name = tableName;
		self.columns = columns;
	}

	return self;
}

- (GDGTableSource *)copyWithZone:(nullable NSZone *)zone
{
	return (GDGTableSource *) [super copyWithZone:zone];
}

@end
