//
//  GDGJoin.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

@class GDGSource;

@interface GDGJoin : NSObject <NSCopying>

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *condition;
@property (strong, nonatomic) GDGSource *source;

- (instancetype)initWithType:(NSString *)type condition:(NSString *)condition source:(GDGSource *)source;

- (NSString *)visit;

@end
