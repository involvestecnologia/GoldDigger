//
//  GDGHasManyThroughRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGRelation.h"
#import <SQLAids/CIRStatement.h>

@class SQLTableSource;

@interface GDGHasManyThroughRelation : GDGRelation

@property (strong, nonatomic) SQLTableSource *relationSource;
@property (strong, nonatomic) NSString *localRelationColumn;
@property (strong, nonatomic) NSString *foreignRelationColumn;

- (BOOL)insertOrReplaceOwner:(NSNumber *)ownerId forRelated:(NSArray <NSNumber *> *)related error:(NSError **)error;

- (CIRStatement *)insertStatement;

@end