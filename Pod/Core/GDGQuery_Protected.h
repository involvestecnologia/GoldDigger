//
//  GDGQuery_Protected.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import "GDGQuery.h"

@interface GDGQuery ()

@property (readwrite, nonatomic) int limitValue;

- (void)limit:(int)limit;

- (void)filter:(NSArray <id <GDGFilter>> *)filters;

@end
