//
// Created by Felipe Lobo on 2019-05-16.
//

#import "GDGObjectFiller.h"
#import "GDGRecord.h"
#import "GDGQuery.h"
#import "GDGTable.h"
#import "GDGMapping.h"
#import "GDGColumn.h"
#import "GDGRelation.h"
#import "GDGConnection.h"
#import "GDGResultSet.h"
#import "NSError+GDG.h"
#import <ObjectiveSugar/NSDictionary+ObjectiveSugar.h>
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>

@implementation GDGObjectFiller {
    __strong GDGConnection *_connection;
}

- (instancetype)initWithConnection:(GDGConnection *)connection
{
    self = [super init];
    if (self)
        _connection = connection;
    
    return self;
}

- (BOOL)fill:(id)object withMapping:(GDGMapping *)mapping error:(NSError **)error
{
    // Separate attributes
    
    NSMutableDictionary <NSString *, GDGColumn *> *columns = [[NSMutableDictionary alloc] init];
    NSMutableDictionary <NSString *, GDGRelation *> *relations = [[NSMutableDictionary alloc] init];
    
    [mapping.fromToDictionary each:^(NSString *property, id value) {
        if ([value isKindOfClass:[GDGColumn class]])
            columns[property] = value;
        else if ([value isKindOfClass:[GDGRelation class]])
            relations[property] = value;
        else
            NSLog(@"[GDGObjectFiller fill:withMapping:error:] is warning that you \
                  have mapped something that is not a column (GDGColumn) or relation (GDGRelation)");
    }];
    
    // Assemble query
    
    GDGMutableQuery *query = [[GDGMutableQuery alloc] initWithSource:mapping.table];
    
    NSArray *projection = [columns.allValues map:^NSString *(GDGColumn *column) { return column.name; }];
    [query select:projection];
    
    GDGCondition *whereCondition = [GDGCondition builder].field(columns[@"id"]).equals([object valueForKey:@"id"]);
    [query addCondition:whereCondition];
    
    // Execute
    
    NSError *underlyingError;
    BOOL success = [self execute:query
                         mapping:mapping
                      eachColumn:^(NSString *property, id value) { [object setValue:value forKey:property]; }
                           error:&underlyingError];
    
    if (!success && underlyingError)
    {
        if (error)
        {
            NSString *message = NSStringWithFormat(@"Error when trying to fill object of class %@;", NSStringFromClass([object class]));
            *error = [NSError errorWithCode:GDGRecordableObjectFillError
                                    message:message
                                 underlying:underlyingError];
        }
        
        return NO;
    }
    
    // TODO Still not filling relations
    
    return YES;
}

#pragma mark - Private

- (BOOL)execute:(GDGQuery *)query mapping:(GDGMapping *)mapping
     eachColumn:(void (^)(NSString *, id))columnHandler
          error:(NSError **)error
{
    NSDictionary *toFrom = [self reverse:mapping.fromToDictionary];
    GDGResultSet *resultSet = [_connection eval:query error:error];
    
    for (NSDictionary *tuple = [resultSet next:error]; tuple != nil; tuple = [resultSet next:error])
        for (NSString *column in tuple.allKeys)
            columnHandler(toFrom[column], tuple[column]);
    
    return error == NULL;
}

- (NSDictionary *)reverse:(NSDictionary <NSString *, GDGColumn *> *)columns
{
    NSMutableDictionary *mutableToFrom = [[NSMutableDictionary alloc] init];
    
    for (NSString *property in columns.allKeys)
        mutableToFrom[columns[property].name] = property;
    
    return [NSDictionary dictionaryWithDictionary:mutableToFrom];
}

@end
