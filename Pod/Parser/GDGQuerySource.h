//
//  GDGQuerySource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import "GDGSource.h"

@class GDGQuery;

@interface GDGQuerySource : NSObject <GDGSource>

@property (readonly, nonatomic, nonnull) GDGQuery *query;
@property (readonly, nonatomic, nullable) NSString *alias;

- (nullable instancetype)initWithQuery:(GDGQuery * __nonnull)query alias:(NSString * __nullable)alias;

@end
