//
//  GDGRecord.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/22/16.
//

#import <Foundation/Foundation.h>
#import "GDGActiveRecord.h"

@class GDGRecord;
@class GDGMapping;
@class GDGQuery;
@class GDGConnection;

@protocol GDGRecordable <NSObject>

+ (GDGRecord *)record;

@end

@interface GDGRecord <ObjectType> : NSObject

@property (readonly, nonatomic, nonnull) GDGMapping *mapping;

+ (nullable instancetype)recordClass:(Class)class mapping:(GDGMapping *(^ __nonnull)(NSArray *__nonnull))tap;

@end
