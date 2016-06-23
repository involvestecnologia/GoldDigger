//
//  GDGJoin.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

@class GDGSource;
@class GDGCondition;

@interface GDGJoin : NSObject <NSCopying>

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) GDGCondition *condition;
@property (strong, nonatomic) GDGSource *source;

- (instancetype)initWithType:(NSString *)type condition:(GDGCondition *)condition source:(GDGSource *)source;

- (NSString *)visit;

@end
