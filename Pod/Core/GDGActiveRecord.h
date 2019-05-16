//
// Created by Felipe Lobo on 2019-05-14.
//

#import <Foundation/Foundation.h>

@class GDGRecord;
@class GDGQuery;
@class GDGConnection;
@class GDGRelation;
@protocol GDGRecordable;

@interface GDGActiveRecord: NSObject

+ (nonnull instancetype)activeRecordConnecting:(GDGConnection *)connection onRecordable:(id __nonnull)object;

- (nonnull instancetype)initWithRecordable:(id __nonnull)object connection:(GDGConnection *__nonnull)connection;

- (BOOL)fill:(NSArray *)properties error:(NSError **)error;

- (BOOL)fill:(NSArray *)properties
   relations:(NSArray *(^)(GDGRelation *))relationPropertiesHandler
       error:(NSError **)error;

- (BOOL)save:(NSError *)error;

- (BOOL)delete:(NSError *)error;

@end
