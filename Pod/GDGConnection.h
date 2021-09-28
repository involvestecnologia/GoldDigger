//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>

@class CIRStatement;
@class GDGActiveRecord;
@class GDGQuery;
@class GDGResultSet;
@class GDGTable;
@class GDGRecord;
@protocol GDGDatabaseProvider;
@protocol GDGRecordable;

NS_ASSUME_NONNULL_BEGIN

@interface GDGConnection : NSObject

@property(weak, readonly, nonatomic, nullable) id <GDGDatabaseProvider> databaseProvider;

+ (GDGTable *__nullable)tableWithName:(NSString *)name error:(NSError **__nullable)error;

- (instancetype)initWithDatabaseProvider:(id <GDGDatabaseProvider>)databaseProvider;

- (NSNumber *)lastInsertedId;

- (BOOL)insert:(NSDictionary <NSString *, id> *)values
       onTable:(GDGTable *)table
         error:(NSError **__nullable)error;

- (BOOL)update:(NSDictionary <NSString *, id> *)values
       onTable:(GDGTable *)table
         error:(NSError **__nullable)error;

- (BOOL)delete:(id)value
     fromTable:(GDGTable *)table
         error:(NSError **__nullable)error;

- (CIRStatement *__nullable)insertStatementForColumns:(NSArray <NSString *> *)columns
                                              ofTable:(GDGTable *)table
                                                error:(NSError **__nullable)error;

- (CIRStatement *__nullable)updateStatementForColumns:(NSArray <NSString *> *)columns
                                              ofTable:(GDGTable *)table
                                            condition:(NSString *__nullable)condition
                                                error:(NSError **__nullable)error;

- (CIRStatement *__nullable)deleteStatementForTable:(GDGTable *)table
                                             error:(NSError **__nullable)error;

- (NSArray *__nullable)evalByTuple:(GDGQuery *)query error:(NSError **__nullable)error;

- (NSDictionary *__nullable)evalByColumn:(GDGQuery *)query error:(NSError **__nullable)error;

- (GDGResultSet *__nullable)eval:(GDGQuery *)query error:(NSError **__nullable)error;

@end

NS_ASSUME_NONNULL_END
