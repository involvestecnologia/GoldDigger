//
//  GDGHasManyThroughRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGRelation.h"

@interface GDGHasManyThroughRelation : GDGRelation

@property (strong, nonatomic) GDGTableSource *relationSource;
@property (strong, nonatomic) NSString *ownerRelationProperty;
@property (strong, nonatomic) NSString *ownerRelationColumn;
@property (strong, nonatomic) NSString *foreignRelationColumn;

@end