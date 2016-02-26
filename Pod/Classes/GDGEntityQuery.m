//
//  GDGEntityQuery.m
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGEntityQuery.h"

#import "GDGColumn.h"
#import "GDGEntityManager.h"
#import "GDGEntitySettings.h"
#import "GDGEntitySettings_Relations.h"
#import "GDGQuery_Protected.h"
#import "GDGRelation.h"
#import "GDGTableSource.h"
#import "GDGConditionBuilder+EntityQuery.h"

@implementation GDGEntityQuery

#pragma mark - Initialization

- (instancetype)initWithManager:(GDGEntityManager*)manager
{
	if (self = [super init])
	{
		_manager = manager;

		self.select(@[@"id"]);

		self.conditionBuilder = [[GDGConditionBuilder alloc] initWithEntityQuery:self];
		
		__weak typeof(self) weakSelf = self;
		
		self.select = ^GDGQuery* (NSArray<NSString*>* projection) {
			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
			
			for (NSString *property in projection)
			{
				NSString *columnName = [weakSelf.manager columnNameForProperty:property];
				GDGColumn *column = [weakSelf findColumnNamed:columnName];
				if (column)
					[validProjection addObject:column.fullName];
			}
			
			[weakSelf.mutableProjection addObjectsFromArray:validProjection];
			
			return weakSelf;
		};
		
		self.asc = ^GDGQuery* (NSString* order) {
			if (weakSelf.orderList == nil) weakSelf.orderList = [[NSMutableArray alloc] init];
			
			NSString *column = [weakSelf.manager columnNameForProperty:order];
			
			if ([weakSelf findColumnNamed:column])
				[weakSelf.orderList addObject:[column stringByAppendingString:@" ASC"]];
			
			return weakSelf;
		};
		
		self.desc = ^GDGQuery* (NSString* order) {
			if (weakSelf.orderList == nil) weakSelf.orderList = [[NSMutableArray alloc] init];
			
			NSString *column = [weakSelf.manager columnNameForProperty:order];
			
			if ([weakSelf findColumnNamed:column])
				[weakSelf.orderList addObject:[column stringByAppendingString:@" DESC"]];
			
			return weakSelf;
		};
		
		_joinRelation = ^GDGEntityQuery* (NSString *relationName, NSArray<NSString*> *projection) {
			GDGRelation *relation = weakSelf.manager.settings.relationNameDictionary[relationName];
			
			GDGTableSource *tableSource = weakSelf.manager.settings.tableSource;
			
			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];
			
			for (NSString *property in projection)
			{
				NSString *columnName = [weakSelf.manager columnNameForProperty:property];
				GDGColumn *column = [tableSource columnNamed:columnName];
				if (column)
					[validProjection addObject:column.fullName];
			}
			
			return weakSelf.join(relation.relatedManager.settings.tableSource, @"INNER", [relation joinCondition], validProjection);
		};
	}
	
	return self;
}

#pragma mark - Object

- (NSArray<__kindof GDGEntity*>*)array
{
	return [_manager select:self];
}

- (__kindof GDGEntity*)object
{
	return [_manager find:self];
}

@end
