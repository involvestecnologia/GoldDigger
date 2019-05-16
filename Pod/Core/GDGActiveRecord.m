//
// Created by Felipe Lobo on 2019-05-14.
//

#import "GDGActiveRecord.h"
#import "GDGRecord.h"
#import "GDGConnection.h"
#import "GDGRelation.h"

@interface GDGActiveRecord ()

@property (nonatomic, weak) id recordableObject;
@property (nonatomic, weak) GDGConnection *connection;
@property (readonly, nonatomic, nonnull) GDGRecord *innerRecord;

@end

@implementation GDGActiveRecord

+ (instancetype)activeRecordConnecting:(GDGConnection *)connection onRecordable:(id __nonnull)object
{
	return [[self alloc] initWithRecordable:object connection:connection];
}

- (instancetype)initWithRecordable:(id)object connection:(GDGConnection *)connection
{
	self = [super init];
	if (self)
	{
		_recordableObject = object;

		if ([object respondsToSelector:@selector(record)])
			_innerRecord = [object performSelector:@selector(record)];
		else
		{
			@throw [NSException exceptionWithName:@"Active Record Instantiate Exception"
			                               reason:@"GDGActiveRecord throws that it can't be instantiated with a non recorded object. Refer to GDGRecord to more information."
			                             userInfo:@{@"object": object}];
		}

		_connection = connection;
	}

	return self;
}

#pragma mark - Active record methods

- (BOOL)fill:(NSArray *)properties error:(NSError **)error
{
	return NO;
}

- (BOOL)fill:(NSArray *)properties relations:(NSArray *(^)(GDGRelation *))relationPropertiesHandler error:(NSError **)error
{
	return NO;
}

- (BOOL)save:(NSError *)error
{
	return NO;
}

- (BOOL)delete:(NSError *)error
{
	return NO;
}


@end