//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>
#import "GDGParser.h"

@class GDGCondition;
@class GDGQueryParser;

@interface GDGCondition <GDGParsable> (Parsable) @end

@interface GDGConditionParser : NSObject <GDGParser>

- (id <GDGParsingResult>)parse:(GDGCondition *)condition error:(NSError **)error;

@end
