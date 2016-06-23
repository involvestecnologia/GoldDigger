//
//  GDGQuery.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/15/16.
//

#import <Foundation/Foundation.h>

@protocol GDGFilter;

@interface GDGQuery : NSObject <NSCopying>

@property (readonly, nonatomic) int limitValue;
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^filter)(NSArray <id <GDGFilter>> *);
@property (copy, readonly, nonatomic) __kindof GDGQuery *(^limit)(int);

+ (instancetype)query;

- (id)visit;

- (id)pluck;

- (NSDictionary *)args;

- (instancetype)copy;

@end
