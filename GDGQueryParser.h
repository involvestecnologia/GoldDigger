//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>

@class GDGQuery;

@interface GDGRawQuery: NSObject

@property (readonly, nonatomic) NSString *visit;
@property (readonly, nonatomic) NSArray *args;

- (instancetype)initWithQuery:(NSString *)rawValue args:(NSArray *)args;

@end

@interface GDGQueryParser : NSObject

- (GDGRawQuery *)parse:(GDGQuery *)query error:(NSError **)error;

@end
