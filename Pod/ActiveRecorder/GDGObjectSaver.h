//
//  GDGObjectSaver.h
//  GoldDigger
//
//  Created by Felipe Lobo on 29/07/19.
//

#import <Foundation/Foundation.h>

@class GDGConnection;
@class GDGMapping;
@protocol GDGRecordable;

NS_ASSUME_NONNULL_BEGIN

@interface GDGObjectSaver : NSObject

- (instancetype)initWithConnection:(GDGConnection *)connection;

- (BOOL)save:(id<GDGRecordable>)object mappingBy:(GDGMapping *)mapping error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
