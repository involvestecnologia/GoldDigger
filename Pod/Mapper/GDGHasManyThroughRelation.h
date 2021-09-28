//
//  GDGHasManyThroughRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGRelation.h"
#import <SQLAid/CIRStatement.h>

@class GDGTable;

@interface GDGHasManyThroughRelation : GDGRelation

@property (strong, nonatomic) GDGTable *relationSource;
@property (strong, nonatomic) NSString *localRelationColumn;
@property (strong, nonatomic) NSString *foreignRelationColumn;

- (BOOL)insertOrReplaceOwner:(NSNumber *)ownerId forRelated:(NSArray <NSNumber *> *)related error:(NSError **)error;

- (CIRStatement *)insertStatement;

@end