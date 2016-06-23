//
//  GDGFilter.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/10/16.
//

#import <Foundation/Foundation.h>

@class GDGQuery;

@protocol GDGFilter <NSObject>

- (void)apply:(__kindof GDGQuery *)query;

@end