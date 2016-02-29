//
//  GDGEntityManager.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//  Copyright © 2016 Involves. All rights reserved.
//

#import "GDGEntityManager.h"

#import "GDGBelongsToRelation.h"
#import "GDGColumn.h"
#import "GDGEntityQuery.h"
#import "GDGEntitySettings.h"
#import "GDGEntitySettings_Relations.h"
#import "GDGHasManyRelation.h"
#import "GDGHasOneRelation.h"
#import "GDGTableSource.h"
#import "GDGValueAdapter.h"
#import "ObjectiveSugar.h"
#import "GDGConditionBuilder+EntityQuery.h"
#import <objc/runtime.h>
#import <SQLAid/CIRDatabase.h>
#import <SQLAid/CIRResultSet.h>

static CIRDatabase *Database;
static NSMutableArray *Callbacks;
static NSMutableDictionary<NSString *, GDGEntitySettings *> *ClassSettingsDictionary;

@interface GDGEntity (GDGEntityManager)

@property NSMutableSet *filledProperties;
@property NSMutableSet *changedProperties;

@end

@implementation GDGEntity (GDGEntityManager)

@dynamic filledProperties, changedProperties;

- (NSMutableSet *)filledProperties
{
	return objc_getAssociatedObject(self, @selector(filledProperties));
}

- (void)setFilledProperties:(NSMutableSet *)filledProperties
{
	objc_setAssociatedObject(self, @selector(filledProperties), filledProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableSet *)changedProperties
{
	return objc_getAssociatedObject(self, @selector(changedProperties));
}

- (void)setChangedProperties:(NSMutableSet *)changedProperties
{
	objc_setAssociatedObject(self, @selector(changedProperties), changedProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation GDGEntityManager

#pragma mark - Static

+ (void)load
{
	ClassSettingsDictionary = [[NSMutableDictionary alloc] init];
}

+ (GDGTableSource *)tableSourceWithName:(NSString *)tableName
{
	CIRResultSet *resultSet = [Database executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName]];

	NSMutableArray<GDGColumn *> *columns = [[NSMutableArray alloc] init];

	while ([resultSet next])
	{
		NSString *name = [resultSet textAtIndex:1];
		GDGColumnType type = GDGColumnFindColumnTypeByName([resultSet textAtIndex:2]);
		BOOL notNull = [resultSet boolAtIndex:3];
		BOOL primaryKey = [resultSet boolAtIndex:5];

		[columns addObject:[[GDGColumn alloc] initWithName:name type:type primaryKey:primaryKey notNull:notNull]];
	}

	return [[GDGTableSource alloc] initWithName:tableName columns:[NSArray arrayWithArray:columns]];
}

+ (void)executeOnDatabaseReady:(void (^)())callback
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Callbacks = [[NSMutableArray alloc] init];
	});

	[Callbacks addObject:callback];
}

+ (void)setDatabase:(CIRDatabase *)database
{
	Database = database;

	for (void (^callback)() in Callbacks) callback();

	[Callbacks removeAllObjects];
}

+ (CIRDatabase *)database
{
	return Database;
}

#pragma mark - Inits

- (instancetype)initWithEntity:(GDGEntity *)entity
{
	if (self = [super init])
	{
		_entity = entity;

		_settings = [[entity class] db].settings;
	}

	return self;
}

- (instancetype)initWithClass:(Class)entityClass tableName:(NSString *)tableName
{
	if (self = [super init])
	{
		if (ClassSettingsDictionary == nil) ClassSettingsDictionary = [[NSMutableDictionary alloc] init];

		NSString *className = NSStringFromClass(entityClass);

		GDGEntitySettings *settings = ClassSettingsDictionary[className];

		if (settings == nil)
		{
			settings = [[GDGEntitySettings alloc] initWithEntityClass:entityClass];
			settings.tableSource = [GDGEntityManager tableSourceWithName:tableName];

			ClassSettingsDictionary[className] = settings;
		}

		_settings = settings;
	}

	return self;
}

#pragma mark - Instance

#pragma mark - Public

- (GDGEntityQuery *)query
{
	return [[GDGEntityQuery alloc] initWithManager:self];
}

- (NSArray<__kindof GDGEntity *> *)select:(GDGEntityQuery *)query
{
	return [self select:query withProjection:query.projection arguments:query.arguments];
}

- (NSArray<GDGEntity *> *)select:(GDGEntityQuery *)query withProjection:(NSArray<NSString *> *)projection arguments:(NSDictionary<NSString *, id> *)arguments
{
	CIRResultSet *resultSet = [Database executeQuery:query.visit withNamedParameters:arguments];

	NSMutableArray *entities = [[NSMutableArray alloc] init];

	while ([resultSet next])
	{
		[entities addObject:[self buildEntityWithProperties:projection resultSet:resultSet]];
	}

	return [NSArray arrayWithArray:entities];
}

- (GDGEntity *)find:(GDGEntityQuery *)query
{
	NSArray<GDGEntity *> *entities = [self select:query.limit(1)];
	return entities.count > 0 ? entities.firstObject : nil;
}

#pragma mark - Save & Delete

- (BOOL)save
{
	BOOL exists = _entity.id > 0;

	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:_entity.changedProperties.count + 1];

	NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:_entity.changedProperties.count];

	for (NSString *propertyName in _entity.changedProperties)
	{
		[values addObject:[self adaptToDatabaseValue:[_entity valueForKeyPath:propertyName] forPropertyNamed:propertyName]];

		[columns addObject:[self columnNameForProperty:propertyName]];
	}

	NSString *sql;

	if (exists)
	{
		sql = [self buildUpdateQueryWithColumns:columns];
		[values addObject:@(_entity.id)];
	}
	else
	{
		sql = [self buildInsertQueryWithColumns:columns];
	}

	BOOL saved = [Database executeUpdate:sql withParameters:values];

	if (!exists) _entity.id = (NSUInteger) [Database lastInsertedId];

	return saved;
}

- (BOOL)drop
{
	return [Database executeUpdate:[self buildDeleteQuery] withParameters:@[@(_entity.id)]];
}

#pragma mark - Fills

- (void)fillProperties:(NSArray<NSString *> *)properties
{
	[self fillEntities:@[_entity] withProperties:properties];
}

- (void)fillEntities:(NSArray<GDGEntity *> *)entities withProperties:(NSArray<NSString *> *)properties
{
	NSArray<NSNumber *> *ids = [entities map:^id(id object) {
		return @([object id]);
	}];

	NSDictionary<NSNumber *, GDGEntity *> *entityIdDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

	NSMutableArray<NSString *> *mutableProperties = [NSMutableArray arrayWithArray:properties];
	NSMutableArray<NSString *> *projection = [[NSMutableArray alloc] initWithCapacity:properties.count];
	NSMutableArray<NSString *> *relations = [NSMutableArray array];

	for (NSString *property in properties)
	{
		GDGRelation *relation = _settings.relationNameDictionary[property];
		if (relation)
		{
			[mutableProperties removeObject:property];
			[relations addObject:property];
			[mutableProperties addObject:relation.foreignProperty];
		}
		else
		{
			[projection addObject:[self columnNameForProperty:property]];
		}
	}

	NSString *visit = self.query.select([NSArray arrayWithArray:projection])
		.where(^(GDGConditionBuilder *builder) {
			builder.prop(@"id").inList(ids);
		}).visit;

	[Database executeQuery:visit each:^(CIRResultSet *resultSet) {
		GDGEntity *entity = entityIdDictionary[resultSet[0]];
		int columnCount = [resultSet columnCount] - 1;
		for (int i = 0; i < columnCount; i++)
		{
			NSString *key = mutableProperties[i];
			id value = [self adaptFromDatabaseValue:resultSet[i + 1] forPropertyNamed:key];
			if (value && entity)
			{
				[entity setValue:value forKey:key];
				[entity.changedProperties removeObject:key];
			}
		}
	}];

	for (NSString *relationName in relations)
	{
		GDGRelation *relation = _settings.relationNameDictionary[relationName];
		[relation fill:entities withProperties:nil];
	}
}

#pragma mark - Relations

- (void)hasMany:(NSString *)relationName config:(void (^)(GDGHasManyRelation *))tap
{
	GDGHasManyRelation *relation = [[GDGHasManyRelation alloc] initWithName:relationName manager:self];
	_settings.relationNameDictionary[relationName] = relation;
	tap(relation);
}

- (void)hasOne:(NSString *)relationName config:(void (^)(GDGHasOneRelation *))tap
{
	GDGHasOneRelation *relation = [[GDGHasOneRelation alloc] initWithName:relationName manager:self];
	_settings.relationNameDictionary[relationName] = relation;
	tap(relation);
}

- (void)belongsTo:(NSString *)relationName config:(void (^)(GDGBelongsToRelation *))tap
{
	GDGBelongsToRelation *relation = [[GDGBelongsToRelation alloc] initWithName:relationName manager:self];
	_settings.relationNameDictionary[relationName] = relation;
	tap(relation);
}

#pragma mark - Entity

- (GDGEntity *)buildEntityWithProperties:(NSArray<id> *)projection resultSet:(CIRResultSet *)resultSet
{
	GDGEntity *entity = [[_settings.entityClass alloc] init];

	[self fillEntity:entity withProperties:projection resultSet:resultSet];

	return entity;
}

- (void)fillEntity:(GDGEntity *)entity withProperties:(NSArray<id> *)projection resultSet:(CIRResultSet *)resultSet
{
	NSString *name;
	NSUInteger dotIndex;
	int columnIndex;

	for (id property in projection)
	{
		if ([property isKindOfClass:[NSString class]])
		{
			name = (NSString *) property;
			columnIndex = [self findInResultSet:resultSet indexOfColumnName:name];
		}
		else
		{
			name = nil;
			columnIndex = -1;
		}

		if (columnIndex > -1)
		{
			dotIndex = [name rangeOfString:@"."].location;
			if (dotIndex != NSNotFound) name = [name substringFromIndex:dotIndex + 1];

			NSString *propertyName = [self propertyNameForColumn:name];

			id value = [self adaptFromDatabaseValue:[resultSet objectAtIndex:columnIndex] forPropertyNamed:propertyName];
			if ([propertyName isEqualToString:@"id"] && [value isKindOfClass:[NSNumber class]])
			{
				entity.id = [value unsignedIntegerValue];
			}
			else
			{
				[entity setValue:value forKeyPath:propertyName];
				[entity.changedProperties removeObject:propertyName];
			}
		}
	}
}

#pragma mark Automator

- (void)entity:(GDGEntity *)entity hasFilledPropertyNamed:(NSString *)propertyName
{
	if (_entity.filledProperties == nil) _entity.filledProperties = [[NSMutableSet alloc] init];
	if (_entity.changedProperties == nil) _entity.changedProperties = [[NSMutableSet alloc] init];

	[_entity.filledProperties addObject:propertyName];
	[_entity.changedProperties addObject:propertyName];
}

- (void)entity:(GDGEntity *)entity requestToFillPropertyNamed:(NSString *)propertyName
{
	if (entity.id > 0 && ![entity.filledProperties containsObject:propertyName])
		[self fillEntities:@[entity] withProperties:@[propertyName]];
}

#pragma mark - Search Column and Property

- (int)findInResultSet:(CIRResultSet *)resultSet indexOfColumnName:(NSString *)columnName
{
	NSUInteger dotIndex = [columnName rangeOfString:@"."].location;
	NSString *inner = dotIndex != NSNotFound ? [columnName substringFromIndex:dotIndex + 1] : columnName;

	return [resultSet columnIndexWithName:inner];
}

- (NSString *)columnNameForProperty:(NSString *)propertyName
{
	NSString *columnName = [_settings.columnsDictionary valueForKey:propertyName];
	return columnName == nil ? propertyName : columnName;
}

- (NSString *)propertyNameForColumn:(NSString *)columnName
{
	NSString *propertyName = [_settings.propertiesDictionary valueForKey:columnName];
	return propertyName == nil ? columnName : propertyName;
}

- (GDGColumn *)columnForProperty:(NSString *)propertyName
{
	return _settings.tableSource[[self columnNameForProperty:propertyName]];
}

#pragma mark - Adapters

- (void)addValueAdapterForPropertyNamed:(NSString *)propertyName fromDatabaseHandler:(id (^)(id))fromDatabaseHandler toDatabaseHandler:(id (^)(id))toDatabaseHandler
{
	[self addValueAdapterForPropertyNamed:propertyName valueAdapter:[[GDGValueAdapter alloc] initWithFromDatabaseHandler:fromDatabaseHandler toDatabaseHandler:toDatabaseHandler]];
}

- (void)addValueAdapterForPropertyNamed:(NSString *)propertyName valueAdapter:(NSValueTransformer *)valueAdapter
{
	[_settings addValueAdpter:valueAdapter forPropertyNamed:propertyName];
}

- (id)adaptFromDatabaseValue:(id)value forPropertyNamed:(NSString *)propertyName
{
	NSValueTransformer *adapter = _settings.valueAdapterDictionary[propertyName];
	return adapter ? [adapter transformedValue:value] : value;
}

- (id)adaptToDatabaseValue:(id)value forPropertyNamed:(NSString *)propertyName
{
	NSValueTransformer *adapter = _settings.valueAdapterDictionary[propertyName];
	return adapter ? [adapter reverseTransformedValue:value] : value;
}

#pragma mark - SQL Builders

- (NSString *)buildUpdateQueryWithColumns:(NSArray<NSString *> *)columns
{
	NSMutableString *sqlBuilder = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET", _settings.tableSource.alias];

	NSString *columnsString = [[columns map:^id(id object) {
		return [object stringByAppendingString:@" = ?"];
	}] join:@", "];

	[sqlBuilder appendFormat:@"%@ WHERE %@.id = ?", columnsString, _settings.tableSource.alias];

	return [NSString stringWithString:sqlBuilder];
}

- (NSString *)buildInsertQueryWithColumns:(NSArray<NSString *> *)columns
{
	NSMutableString *sqlBuilder = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", _settings.tableSource.alias];

	NSString *valuesString = [[columns map:^id(id object) {
		return @"?";
	}] join:@", "];

	[sqlBuilder appendFormat:@"%@) VALUES (%@)", [columns join:@", "], valuesString];

	return [NSString stringWithString:sqlBuilder];
}

- (NSString *)buildDeleteQuery
{
	return [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = ?", _settings.tableSource.alias];
}

@end
