//
//  GDGSource.h
//  GoldDigger
//
//  Created by Pietro Caselani on 2/12/16.
//

#import <Foundation/Foundation.h>

@class GDGQuery;

@protocol GDGSource <NSObject, NSCopying>

@property (readonly, nonatomic) NSString *identifier;

- (id)eval:(id)anyObject;

@end

