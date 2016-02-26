//
//  GDGSource.h
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import <Foundation/Foundation.h>

#import "GDGColumn.h"

@interface GDGSource : NSObject

@property(strong, nonatomic) NSString *alias;
@property(strong, readonly, nonatomic) NSArray<GDGColumn *> *columns;

- (GDGColumn *)columnNamed:(NSString *)columnName;

- (NSString *)adjustColumnNamed:(NSString *)columnName;

- (GDGColumn *)objectForKeyedSubscript:(NSString *)idx;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)idx;

@end

@interface GDGColumn (Source)

@property(nonatomic) GDGSource *source;

@end
