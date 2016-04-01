//
//  GDGEntityQuery.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGEntityQuery.h"

#import "GDGColumn.h"
#import "GDGEntityManager.h"
#import "GDGEntitySettings.h"
#import "GDGEntitySettings+Relations.h"
#import "GDGQuery_Protected.h"
#import "GDGRelation.h"
#import "GDGTableSource.h"
#import "GDGCondition+EntityQuery.h"
#import "GDGCondition_Protected.h"

@implementation GDGQuery (Entity)

- (NSArray<__kindof GDGEntity *> *)array
{
	@throw [NSException exceptionWithName:@"Abstract Method Call"
	                               reason:@"[GDGQuery+Entity -array] throws that as an abstract method interface, it should never be called directly"
	                             userInfo:nil];
}

- (__kindof GDGEntity *)object
{
	@throw [NSException exceptionWithName:@"Abstract Method Call"
	                               reason:@"[GDGQuery+Entity -object] throws that as an abstract method interface, it should never be called directly"
	                             userInfo:nil];
}

@end

@interface GDGEntityQuery ()

@property (strong, nonatomic) NSMutableDictionary *mutablePulledRelations;
@property (readwrite, nonatomic) GDGEntityManager *manager;

@end

@implementation
GDGEntityQuery

#pragma mark - Initialization

- (instancetype)initWithSource:(__kindof GDGSource *)source
{
	if (self = [super initWithSource:source])
	{
		self.select(@[@"id"]);

		self.condition = [GDGCondition builderWithEntityQuery:self];

		_mutablePulledRelations = [NSMutableDictionary dictionary];

		__weak typeof(self) weakSelf = self;

		_pull = ^GDGEntityQuery *(NSDictionary <NSString *, NSArray *> *pulledRelations) {
			for (NSString *relationName in pulledRelations.keyEnumerator)
			{
				GDGRelation *relation = [weakSelf.manager relationNamed:relationName];
				weakSelf.select(@[relation.foreignProperty]);
			}
			[weakSelf.mutablePulledRelations addEntriesFromDictionary:pulledRelations];
			return weakSelf;
		};

		self.select = ^GDGEntityQuery *(NSArray<NSString *> *projection) {
			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];

			for (NSString *propertyName in projection)
			{
				NSString *columnName = [weakSelf.manager columnNameForProperty:propertyName];
				GDGColumn *column = [weakSelf findColumnNamed:columnName];
				if (column)
					[validProjection addObject:column.fullName];
			}

			[weakSelf.mutableProjection addObjectsFromArray:validProjection];

			return weakSelf;
		};

#define ORDER_BLOCK(direction) \
    ^GDGEntityQuery *(NSString *prop) { \
      if (weakSelf.orderList == nil)\
        weakSelf.orderList = [NSMutableArray array];\
      \
      NSString *columnName = [weakSelf.manager columnNameForProperty:prop]; \
      GDGColumn *column; \
      \
      if (column = [weakSelf findColumnNamed:columnName])\
        [weakSelf.orderList addObject:[column.fullName stringByAppendingString:direction]];\
      \
      return weakSelf;\
    };

		self.asc = ORDER_BLOCK(@" ASC");
		self.desc = ORDER_BLOCK(@" DESC");

#undef ORDER_BLOCK

		_id = ^GDGEntityQuery *(NSInteger id) {
			return weakSelf.where(^(GDGCondition *condition) {
				condition.prop(@"id").equals(@(id));
			}).limit(1);
		};

		_joinRelation = ^GDGEntityQuery *(NSString *relationName, NSArray<NSString *> *projection) {
			GDGRelation *relation = weakSelf.manager.settings.relationNameDictionary[relationName];

			NSMutableArray *validProjection = [[NSMutableArray alloc] initWithCapacity:projection.count];

			for (NSString *propertyName in projection)
				[validProjection addObject:[weakSelf.manager columnForProperty:propertyName].fullName];

			return weakSelf.join(relation.relatedManager.settings.tableSource, @"INNER", [relation joinCondition], validProjection);
		};
	}

	return self;
}


- (instancetype)initWithManager:(GDGEntityManager *)manager
{
	if (self = [self initWithSource:manager.settings.tableSource])
		_manager = manager;

	return self;
}

- (NSDictionary <NSString *, NSArray *> *)pulledRelations
{
	return [NSDictionary dictionaryWithDictionary:_mutablePulledRelations];
}

#pragma mark - Copy

- (instancetype)copy
{
	GDGEntityQuery *copy = (GDGEntityQuery *) [super copy];
	copy->_mutablePulledRelations = _mutablePulledRelations;

	return copy;
}

- (GDGEntityQuery *)copyWithZone:(nullable NSZone *)zone
{
	GDGEntityQuery *copy = (GDGEntityQuery *) [super copyWithZone:zone];
	copy.manager = _manager;
	copy.condition.query = copy;
	return copy;
}

#pragma mark - Object

- (NSArray<__kindof GDGEntity *> *)array
{
	return [_manager select:self];
}

- (__kindof GDGEntity *)object
{
	return [_manager find:self];
}

@end
