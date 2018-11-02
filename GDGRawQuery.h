//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>
#import "GDGParser.h"

@interface GDGRawQuery : NSObject <GDGParsingResult>

@property (readonly, nonatomic) NSString *visit;
@property (readonly, nonatomic) NSArray *array;

@end