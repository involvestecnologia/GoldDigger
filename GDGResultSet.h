//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>
#import <SQLAid/CIRResultSet.h>

@class GDGTable;

@interface GDGResultSet : NSObject

@property (readonly, nonatomic, nonnull) CIRResultSet *resultSet;
@property (readonly, nonatomic, nonnull) NSArray *projection;

- (instancetype)initWithResultSet:(CIRResultSet *__nonnull)resultSet
                       projection:(NSArray *__nonnull)projection;

- (NSDictionary *__nullable)next:(NSError **__nullable)error;

@end