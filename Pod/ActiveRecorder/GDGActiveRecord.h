//
// Created by Felipe Lobo on 2019-05-14.
//

#import <Foundation/Foundation.h>

@class GDGRecord;
@class GDGQuery;
@class GDGConnection;
@class GDGRelation;
@protocol GDGRecordable;

NS_ASSUME_NONNULL_BEGIN

@interface GDGActiveRecord: NSObject

+ (instancetype)activeRecordConnecting:(GDGConnection *)connection onRecordable:(id<GDGRecordable>)object;

- (instancetype)initWithRecordable:(id<GDGRecordable>)object connection:(GDGConnection *)connection;

- (BOOL)fill:(NSError **__nullable)error;

- (BOOL)save:(NSError **__nullable)error;

- (BOOL)delete:(NSError **__nullable)error;

@end

NS_ASSUME_NONNULL_END
