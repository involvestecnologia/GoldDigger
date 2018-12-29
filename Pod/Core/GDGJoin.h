//
//  GDGJoin.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

@class GDGCondition;
@protocol GDGSource;

typedef NS_ENUM(NSInteger, GDGJoinKind) {
	GDGJoinKindInner,
	GDGJoinKindLeft
};

@interface GDGJoin : NSObject <NSCopying>

@property (readonly, nonatomic) GDGJoinKind kind;
@property (readonly, nonatomic, nonnull) GDGCondition *condition;
@property (readonly, nonatomic, nonnull) id <GDGSource> source;

- (instancetype)initWithKind:(GDGJoinKind)kind
                   condition:(GDGCondition *__nonnull)condition
                      source:(id <GDGSource>__nonnull)source;

@end
