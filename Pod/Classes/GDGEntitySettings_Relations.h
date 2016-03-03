//
//  GDGEntitySettings_Relations.h
//  GoldDigger
//
//  Created by Pietro Caselani on 1/26/16.
//

#import "GDGEntitySettings.h"

@interface GDGEntitySettings ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, GDGRelation *> *relationNameDictionary;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSValueTransformer *> *valueTransformerDictionary;

@end
