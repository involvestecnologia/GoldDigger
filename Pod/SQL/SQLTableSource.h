//
//  SQLTableSource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"

@class GDGColumn;
@class GDGRelation;
@class GDGQuery;
@class CIRStatement;
@protocol GDGDatabaseProvider;

@interface SQLTableSource : NSObject <GDGSource>

@property (weak, nonatomic, nullable) id <GDGDatabaseProvider> databaseProvider;
@property (strong, nonatomic, nullable) NSString *alias;
@property (readonly, nonatomic, nonnull) NSNumber *lastInsertedId;
@property (readonly, nonatomic, nonnull) NSString *name;
@property (readonly, nonatomic, nonnull) NSString *identifier;
@property (readonly, nonatomic, nonnull) NSArray <GDGColumn *> *columns;

- (instancetype)initWithTableName:(NSString *__nonnull)tableName
                 databaseProvider:(id <GDGDatabaseProvider>__nonnull)databaseProvider;

- (CIRStatement *__nonnull)insertStatementForColumns:(NSArray <NSString *> *__nonnull)columns;

- (CIRStatement *__nonnull)updateStatementForColumns:(NSArray <NSString *> *__nonnull)columns condition:(NSString *__nullable)condition;

- (CIRStatement *__nonnull)updateStatementForColumns:(NSArray <NSString *> *__nonnull)columns;

- (CIRStatement *__nonnull)deleteStatement;

- (BOOL)insert:(NSDictionary <NSString *, id> *)values error:(NSError **)error;

- (BOOL)update:(NSDictionary <NSString *, id> *)values error:(NSError **)error;

- (BOOL)delete:(id)primaryKey error:(NSError **)error;

- (NSArray <NSDictionary *> *)eval:(GDGQuery *)query;

- (NSArray *)evalByTuple:(GDGQuery *)query;

- (NSArray *)evalByColumn:(GDGQuery *)query;

- (GDGColumn *)objectForKeyedSubscript:(NSString *)columnName;

@end
