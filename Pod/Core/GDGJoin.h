//
//  GDGJoin.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

@class GDGCondition;
@protocol GDGSource;

@interface GDGJoin : NSObject <NSCopying>

@property (strong, nonatomic) GDGCondition *condition;
@property (strong, nonatomic) id <GDGSource> source;

- (instancetype)initWithCondition:(GDGCondition *)condition source:(id <GDGSource>)source;

@end
