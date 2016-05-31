//
//  GDGRelation+SQL.h
//  Pods
//
//  Created by Felipe Lobo on 5/9/16.
//

#import <Foundation/Foundation.h>
#import "GDGRelation.h"

@class SQLEntityQuery;

@interface GDGRelation (SQL)

@property (nonatomic, readonly) SQLEntityQuery *baseQuery;

@end