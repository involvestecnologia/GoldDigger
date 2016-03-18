//
//  GDGEntitySettings+Relations.h
//  Pods
//
//  Created by Pietro Caselani on 3/14/16.
//

#import "GDGEntitySettings.h"

@interface GDGEntitySettings (Relations)

@property (strong, nonatomic) NSMutableDictionary<NSString *, GDGRelation *> *relationNameDictionary;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSValueTransformer *> *valueTransformerDictionary;

@end