//
//  GDGSource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

#import "GDGColumn.h"

@interface GDGSource : NSObject <NSCopying>

@property (strong, nonatomic) NSString *alias;
@property (readonly, nonatomic) NSArray<GDGColumn *> *columns;

- (GDGColumn *)columnNamed:(NSString *)columnName;

- (NSString *)adjustColumnNamed:(NSString *)columnName;

- (GDGColumn *)objectForKeyedSubscript:(NSString *)idx;

@end

@interface GDGColumn (Source)

@property (nonatomic) GDGSource *source;

@end
