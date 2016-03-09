//
//  GDGTableSource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"

@class GDGColumn;
@class CIRDatabase;

@interface GDGTableSource : GDGSource

@property (strong, readonly, nonatomic) NSString *name;

+ (instancetype)tableSourceFromTable:(NSString *)tableName;

+ (instancetype)tableSourceFromTable:(NSString *)tableName in:(CIRDatabase *)database;

- (instancetype)initWithName:(NSString *)tableName columns:(NSArray<GDGColumn *> *)columns;

@end
