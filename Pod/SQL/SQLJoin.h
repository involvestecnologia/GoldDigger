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
@property (strong, nonatomic) NSMutableArray *projection;
@property (readonly, nonatomic) id <SQLSource> source;

+ (instancetype)joinWithKind:(SQLJoinKind)kind
                   condition:(GDGCondition *)condition
                      source:(id <SQLSource>)source;

- (void)select:(NSArray <NSString *> *)projection;

@end