//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>

@class CIRStatement;
@class GDGActiveRecord;
@class GDGQuery;
@class GDGResultSet;
@class GDGTable;
@protocol GDGDatabaseProvider;
@protocol GDGRecordable;
@class GDGRecord;

@interface GDGConnection : NSObject

@property(weak, readonly, nonatomic, nullable) id <GDGDatabaseProvider> databaseProvider;

+ (GDGTable *__nullable)tableWithName:(NSString *__nonnull)name error:(NSError **__nullable)error;

- (instancetype)initWithDatabaseProvider:(id <GDGDatabaseProvider> __nonnull)databaseProvider;

- (NSNumber *)lastInsertedId;

- (BOOL)insert:(NSDictionary <NSString *, id> *__nonnull)values
       onTable:(GDGTable *__nonnull)table
         error:(NSError **__nullable)error;

- (BOOL)update:(NSDictionary <NSString *, id> *__nonnull)values
       onTable:(GDGTable *__nonnull)table
         error:(NSError **__nullable)error;

- (BOOL)delete:(id __nonnull)value
     fromTable:(GDGTable *__nonnull)table
         error:(NSError **__nullable)error;

- (CIRStatement *__nullable)insertStatementForColumns:(NSArray <NSString *> *__nonnull)columns
                                              ofTable:(GDGTable *__nonnull)table
                                                error:(NSError **__nullable)error;

- (CIRStatement *__nullable)updateStatementForColumns:(NSArray <NSString *> *__nonnull)columns
                                              ofTable:(GDGTable *__nonnull)table
                                            condition:(NSString *__nullable)condition
                                                error:(NSError **__nullable)error;

- (CIRStatement *__nullable)deleteStatementForTable:(GDGTable *__nonnull)table
                                             error:(NSError **__nullable)error;

- (NSArray *__nullable)evalByTuple:(GDGQuery *__nonnull)query error:(NSError **__nullable)error;

- (NSDictionary *__nullable)evalByColumn:(GDGQuery *__nonnull)query error:(NSError **__nullable)error;

- (GDGResultSet *__nullable)eval:(GDGQuery *__nonnull)query error:(NSError **__nullable)error;

@end