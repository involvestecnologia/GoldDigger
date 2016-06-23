//
//  GDGCondition+Entity.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/9/16.
//

#import <Foundation/Foundation.h>
#import "GDGCondition.h"
#import "SQLEntityMap.h"

@interface GDGCondition (Entity)

@property (copy, readonly, nonatomic) GDGCondition *(^prop)(NSString *);
@property (strong, nonatomic) SQLEntityMap *map;

@end