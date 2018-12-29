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

@property (readonly, nonatomic, nonnull) NSString *name;
@property (readonly, nonatomic, nonnull) NSArray <GDGColumn *> *columns;

- (nonnull NSString *)insertStringForColumns:(NSArray <NSString *> *__nonnull)columns;

- (nonnull NSString *)updateStringForColumns:(NSArray <NSString *> *__nonnull)columns;

- (nonnull NSString *)updateStringForColumns:(NSArray <NSString *> *__nonnull)columns
                                   condition:(NSString *__nullable)condition;

- (nonnull NSString *)deleteString;

- (nullable GDGColumn *)objectForKeyedSubscript:(NSString *__nonnull)columnName;

@end
