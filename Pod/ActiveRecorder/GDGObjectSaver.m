//
//  GDGObjectSaver.m
//  GoldDigger
//
//  Created by Felipe Lobo on 29/07/19.
//

#import "GDGObjectSaver.h"

@implementation GDGObjectSaver {
    __strong GDGConnection *_connection;
}

- (instancetype)initWithConnection:(GDGConnection *)connection
{
    self = [super init];
    if (self)
        _connection = connection;
    
    return self;
}

- (BOOL)save:(id<GDGRecordable>)object mappingBy:(GDGMapping *)mapping error:(NSError **)error
{
    return YES;
}

@end
