//
//  GDGHasManyThroughRelation.h
//  GoldDigger
//
//  Created by Pietro Caselani on 3/30/16.
//

#import "GDGRelation.h"
#import <SQLAid/CIRStatement.h>

@class SQLTableSource;

@interface GDGHasManyThroughRelation : GDGRelation

@property (strong, nonatomic) SQLTableSource *relationSource;
@property (strong, nonatomic) NSString *localRelationColumn;
@property (strong, nonatomic) NSString *foreignRelationColumn;

- (void)save:(GDGEntity *)entity;

- (void)insertOrReplaceOwner:(NSNumber *)ownerId forRelated:(NSArray <NSNumber *> *)related;

- (CIRStatement *)insertStatement;

@end