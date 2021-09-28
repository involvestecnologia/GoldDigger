//
// Created by Felipe Lobo on 2018-11-05.
//

#import <Foundation/Foundation.h>
#import "GDGTable.h"

@class GDGColumn;

@interface GDGTable ()

- (nonnull instancetype)initWithTableName:(NSString *__nonnull)name
						  columns:(NSArray <GDGColumn *> *__nonnull)columns;

@end
