//
//  SQLTableSource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "SQLSource.h"

@class GDGColumn;
@class GDGRelation;
@class SQLQuery;
@class CIRStatement;
@protocol GDGDatabaseProvider;

@interface SQLTableSource : NSObject <SQLSource>

@property (weak, nonatomic) id <GDGDatabaseProvider> databaseProvider;
@property (readonly, nonatomic) NSNumber *lastInsertedId;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSArray <GDGColumn *> *columns;
@property (strong, nonatomic) NSString *alias;

- (instancetype)initWithTableName:(NSString *)tableName
                 databaseProvider:(id <GDGDatabaseProvider>)databaseProvider;

- (CIRStatement *)insertStatementForColumns:(NSArray <NSString *> *)columns;

- (CIRStatement *)updateStatementForColumns:(NSArray <NSString *> *)columns;

- (CIRStatement *)deleteStatement;

- (BOOL)insert:(NSArray <NSString *> *)columns params:(NSArray *)params error:(NSError **)error;

- (BOOL)update:(NSArray <NSString *> *)columns params:(NSArray *)params error:(NSError **)error;

- (BOOL)delete:(id)primaryKey error:(NSError **)error;

- (NSArray <NSDictionary *> *)eval:(SQLQuery *)query;

- (NSArray *)evalByTuple:(SQLQuery *)query;

- (NSArray *)evalByColumn:(SQLQuery *)query;

- (GDGColumn *)objectForKeyedSubscript:(NSString *)columnName;

@end