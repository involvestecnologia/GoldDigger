//
//  GDGHasManyThroughRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGRelation.h"

@class SQLTableSource;

@interface GDGHasManyThroughRelation : GDGRelation

@property (strong, nonatomic) SQLTableSource *relationSource;
@property (strong, nonatomic) NSString *localRelationColumn;
@property (strong, nonatomic) NSString *foreignRelationColumn;

@end