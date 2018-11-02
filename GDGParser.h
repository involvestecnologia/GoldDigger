//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>

@protocol GDGParsingResult <NSObject>

@property (readonly, nonatomic) NSString *visit;
@property (readonly, nonatomic) NSArray *args;

@end

@protocol GDGParsable <NSObject> @end

@protocol GDGParser <NSObject>

- (id <GDGParsingResult>)parse:(id)object error:(NSError **)error;

@end

@interface GDGParsingResult: NSObject <GDGParsingResult>

@property (strong, nonatomic) NSString *visit;
@property (strong, nonatomic) NSArray *args;

@end
