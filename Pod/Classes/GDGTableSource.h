//
//  GDGTableSource.h
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGSource.h"

@class GDGColumn;

@interface GDGTableSource : GDGSource

@property (strong, readonly, nonatomic) NSString* name;

- (instancetype)initWithName:(NSString*)tableName columns:(NSArray<GDGColumn*>*)columns;

@end
