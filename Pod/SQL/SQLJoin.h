//
//  SQLJoin.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/7/16.
//

#import "GDGJoin.h"

@protocol SQLSource;

typedef NS_ENUM(NSInteger, SQLJoinKind) {
	SQLJoinKindInner,
	SQLJoinKindLeft
};

@interface SQLJoin : GDGJoin

@property (assign, nonatomic) SQLJoinKind kind;
@property (strong, nonatomic, nonnull) NSMutableArray *projection;
@property (readonly, nonatomic, nonnull) id <GDGSource> source;

+ (instancetype)joinWithKind:(SQLJoinKind)kind
                   condition:(GDGCondition *__nonnull)condition
                      source:(id <GDGSource>__nonnull)source;

- (void)select:(NSArray <NSString *> *__nonnull)projection;

@end
