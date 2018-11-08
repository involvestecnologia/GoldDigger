//
//  GDGTable.h
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

@interface GDGTable : NSObject <GDGSource>

//@property (strong, nonatomic, nullable) NSString *alias;
//@property (readonly, nonatomic, nonnull) NSString *identifier;
@property (readonly, nonatomic, nonnull) NSString *name;
@property (readonly, nonatomic, nonnull) NSArray <GDGColumn *> *columns;

- (NSString *__nonnull)insertStringForColumns:(NSArray <NSString *> *__nonnull)columns;

- (NSString *__nonnull)updateStringForColumns:(NSArray <NSString *> *__nonnull)columns;

- (NSString *__nonnull)updateStringForColumns:(NSArray <NSString *> *__nonnull)columns
                                    condition:(NSString *__nullable)condition;

- (NSString *__nonnull)deleteString;

- (GDGColumn *__nullable)objectForKeyedSubscript:(NSString *__nonnull)columnName;

@end
