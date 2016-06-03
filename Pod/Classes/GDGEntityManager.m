//
//  GDGEntityManager.m
//  GoldDigger
//
//  Created by Pietro Caselani on 1/20/16.
//

#import "GDGEntityManager.h"

#import "GDGBelongsToRelation.h"
#import "GDGColumn.h"
#import "GDGEntityQuery.h"
#import "GDGEntitySettings+Relations.h"
#import "GDGHasManyRelation.h"
#import "GDGHasOneRelation.h"
#import "GDGTableSource.h"
#import "GDGCondition+EntityQuery.h"
#import "CIRDatabase+GoldDigger.h"
#import "GDGHasManyThroughRelation.h"
#import <objc/runtime.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <SQLAid/CIRResultSet.h>

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

#pragma mark - Initialization

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
		if (ClassSettingsDictionary == nil)
			ClassSettingsDictionary = [NSMutableDictionary dictionary];

		NSString *className = NSStringFromClass(entityClass);

		GDGEntitySettings *settings = ClassSettingsDictionary[className];

		if (settings == nil)
		{
			settings = [[GDGEntitySettings alloc] initWithEntityClass:entityClass tableSource:[GDGTableSource tableSourceFromTable:tableName in:[CIRDatabase goldDigger_mainDatabase]]];

			ClassSettingsDictionary[className] = settings;
		}

		_settings = settings;
	}

	return self;
}

#pragma mark - Database

- (GDGEntityQuery *)query
{
	return [[GDGEntityQuery alloc] initWithManager:self];
}

- (NSArray<__kindof GDGEntity *> *)select:(GDGEntityQuery *)query
{
	NSArray *projection = query.projection;
	NSMutableArray *entities = [NSMutableArray array];

	CIRResultSet *resultSet = [[CIRDatabase goldDigger_mainDatabase] executeQuery:query.visit withNamedParameters:query.arguments];

	while ([resultSet next])
		[entities addObject:[self entityWithProperties:projection resultSet:resultSet]];

	NSDictionary <NSString *, NSArray *> *pulledRelations = query.pulledRelations;
	for (NSString *relationName in pulledRelations.keyEnumerator)
	{
		GDGRelation *relation = [self relationNamed:relationName];
		[relation fill:entities withProperties:pulledRelations[relationName]];
	}

	return [NSArray arrayWithArray:entities];
}

- (GDGEntity *)find:(GDGEntityQuery *)query
{
	return [self select:query.limit(1)].firstObject;
}

#pragma mark Save & Delete

- (BOOL)save
{
	BOOL exists = self.query.copy.id(_entity.id).count > 0;

	NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:_entity.changedProperties.count + 1];
	NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:_entity.changedProperties.count];

	NSArray *relationNames = self.settings.relationNameDictionary.allKeys;
	NSArray *allChangedObjects = [_entity.changedProperties.objectEnumerator.allObjects relativeComplement:relationNames];
	NSArray *foreignProperties = [[relationNames intersectionWithArray:allChangedObjects] map:^id(NSString *relationName) {
		return [[self relationNamed:relationName] foreignProperty];
	}];
	NSArray *changedProperties = [allChangedObjects unionWithArray:foreignProperties];

	for (NSString *propertyName in changedProperties)
	{
		[values addObject:[self transformToDatabaseValue:[_entity valueForKeyPath:propertyName] forPropertyNamed:propertyName]];
		[columns addObject:[self columnNameForProperty:propertyName]];
	}

	NSString *sql;

	if (exists)
	{
		sql = [self buildUpdateQueryWithColumns:columns];
		[values addObject:@(_entity.id)];
	}
	else
		sql = [self buildInsertQueryWithColumns:columns];

	CIRDatabase *database = [CIRDatabase goldDigger_mainDatabase];

	BOOL saved = [database executeUpdate:sql withParameters:values];

	if (saved)
		[_entity.changedProperties removeAllObjects];

	if (!exists)
		_entity.id = (NSInteger) [database lastInsertedId];

	return saved;
}

- (BOOL)drop
{
	return [[CIRDatabase goldDigger_mainDatabase] executeUpdate:[self buildDeleteQuery] withParameters:@[@(_entity.id)]];
}

#pragma mark - Relations

- (void)hasMany:(NSString *)relationName config:(void (^)(GDGHasManyRelation *))tap
{
	GDGHasManyRelation *relation = [[GDGHasManyRelation alloc] initWithName:relationName manager:self];
	_settings.relationNameDictionary[relationName] = relation;
	tap(relation);
}

- (void)hasMany:(NSString *)relationName through:(NSString *)tableName config:(void (^)(GDGHasManyThroughRelation *))tap
{
	GDGHasManyThroughRelation *relation = [[GDGHasManyThroughRelation alloc] initWithName:relationName manager:self];
	_settings.relationNameDictionary[relationName] = relation;

	relation.relationSource = [GDGTableSource tableSourceFromTable:tableName];

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

#pragma mark - Entity filling
#pragma mark API

- (void)fillProperties:(NSArray *)properties
{
	[self fillEntities:@[_entity] withProperties:properties];
}

- (void)fillEntities:(NSArray<GDGEntity *> *)entities withProperties:(NSArray *)properties
{
	NSArray<NSNumber *> *ids = [entities map:^id(GDGEntity *object) {
		return @(object.id);
	}];

	NSDictionary<NSNumber *, GDGEntity *> *entityIdDictionary = [NSDictionary dictionaryWithObjects:entities forKeys:ids];

	NSMutableArray<NSString *> *mutableProperties = [NSMutableArray arrayWithArray:properties];
	NSMutableArray<NSString *> *projection = [[NSMutableArray alloc] initWithCapacity:properties.count];
	NSMutableArray<NSString *> *relations = [NSMutableArray array];

	for (id property in properties)
	{
		if ([property isKindOfClass:[NSDictionary class]])
			[relations addObject:property];
		else
		{
			GDGRelation *relation = _settings.relationNameDictionary[property];
			if (relation)
			{
				[mutableProperties removeObject:property];
				[relations addObject:property];
				[mutableProperties addObject:relation.foreignProperty];
			}
			else
				[projection addObject:[self columnNameForProperty:property]];
		}
	}

	NSString *visit = self.query.select([NSArray arrayWithArray:projection])
			.where(^(GDGCondition *builder) {
				builder.prop(@"id").inList(ids);
			}).visit;

	[[CIRDatabase goldDigger_mainDatabase] executeQuery:visit each:^(CIRResultSet *resultSet) {
		GDGEntity *entity = entityIdDictionary[resultSet[0]];
		int columnCount = [resultSet columnCount] - 1;
		for (NSUInteger i = 0; i < columnCount; i++)
		{
			NSString *key = mutableProperties[i];
			id value = [self transformFromDatabaseValue:resultSet[i + 1] forPropertyNamed:key];
			if (value && entity)
			{
				[entity setValue:value forKey:key];
				[entity.changedProperties removeObject:key];
			}
		}
	}];

	NSArray *relationProperties = nil;
	NSString *relationName = nil;

	for (id relation in relations)
	{
		if ([relation isKindOfClass:[NSDictionary class]])
		{
			relationName = [(NSDictionary *) relation allKeys].lastObject;
			relationProperties = relation[relationName];
		}
		else
		{
			relationName = relation;
			relationProperties = nil;
		}

		GDGRelation *relation = _settings.relationNameDictionary[relationName];
		[relation fill:entities withProperties:relationProperties];
	}
}

#pragma mark Private

- (GDGEntity *)entityWithProperties:(NSArray<id> *)projection resultSet:(CIRResultSet *)resultSet
{
	GDGEntity *entity = [_settings.entityClass entity];

	[self fillEntity:entity withProperties:projection resultSet:resultSet];

	return entity;
}

- (void)fillEntity:(GDGEntity *)entity withProperties:(NSArray *)projection resultSet:(CIRResultSet *)resultSet
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
			if (dotIndex != NSNotFound)
				name = [name substringFromIndex:dotIndex + 1];

			NSString *propertyName = [self propertyNameForColumn:name];

			id value = [self transformFromDatabaseValue:[resultSet objectAtIndex:columnIndex] forPropertyNamed:propertyName];
			if ([propertyName isEqualToString:@"id"] && [value isKindOfClass:[NSNumber class]])
				entity.id = [value unsignedIntegerValue];
			else
			{
				[entity setValue:value forKeyPath:propertyName];
				[entity.changedProperties removeObject:propertyName];
			}
		}
	}
}

#pragma mark Delegate

- (void)entity:(GDGEntity *)entity hasFilledPropertyNamed:(NSString *)propertyName
{
	if (_entity.filledProperties == nil)
		_entity.filledProperties = [NSMutableSet set];

	if (_entity.changedProperties == nil)
		_entity.changedProperties = [NSMutableSet set];

	[_entity.filledProperties addObject:propertyName];
	[_entity.changedProperties addObject:propertyName];
}

- (void)entity:(GDGEntity *)entity requestToFillPropertyNamed:(NSString *)propertyName
{
	if (entity.id != 0 && ![entity.filledProperties containsObject:propertyName])
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

- (GDGRelation *)relationNamed:(NSString *)relationName
{
	return _settings.relationNameDictionary[relationName];
}

#pragma mark - Adapters

- (void)addValueTransformer:(__kindof NSValueTransformer *)transformer forProperties:(NSArray<NSString *> *)properties
{
	for (NSString *property in properties)
		_settings.valueTransformerDictionary[property] = transformer;
}

- (id)transformFromDatabaseValue:(id)value forPropertyNamed:(NSString *)propertyName
{
	NSValueTransformer *adapter = _settings.valueTransformerDictionary[propertyName];
	return adapter ? [adapter transformedValue:value] : value;
}

- (id)transformToDatabaseValue:(id)value forPropertyNamed:(NSString *)propertyName
{
	NSValueTransformer *adapter = _settings.valueTransformerDictionary[propertyName];
	return adapter ? [adapter reverseTransformedValue:value] : value;
}

#pragma mark - Update/Insert/Delete string builders

- (NSString *)buildUpdateQueryWithColumns:(NSArray<NSString *> *)columns
{
	NSMutableString *sqlBuilder = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", _settings.tableSource.identifier];

	NSString *columnsString = [[columns map:^id(id object) {
		return [object stringByAppendingString:@" = ?"];
	}] join:@", "];

	[sqlBuilder appendFormat:@"%@ WHERE %@.id = ?", columnsString, _settings.tableSource.identifier];

	return [NSString stringWithString:sqlBuilder];
}

- (NSString *)buildInsertQueryWithColumns:(NSArray<NSString *> *)columns
{
	NSMutableString *sqlBuilder = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (", _settings.tableSource.identifier];

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

#pragma mark - Subscript

- (id)objectForKeyedSubscript:(NSString *)idx;
{
	GDGColumn *column = [self columnForProperty:idx];
	return column ?: [self relationNamed:idx];
}

@end
