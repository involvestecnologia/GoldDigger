//
//  CIRDatabase+GoldDigger.m
//  GoldDigger
//
//  Created by Felipe Lobo on 3/1/16.
//

#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import <SQLAid/CIRDatabase.h>

static CIRDatabase *GoldDiggerDatabase;
static NSMutableArray *Callbacks;

@implementation CIRDatabase (GoldDigger)

+ (CIRDatabase *)goldDigger_mainDatabase
{
	return GoldDiggerDatabase;
}

+ (void)goldDigger_executeWhenDatabaseIsReady:(void (^)())callback
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Callbacks = [NSMutableArray array];
	});

	[Callbacks addObject:callback];
}

- (void)goldDigger_setAsMainDatabase
{
	if (GoldDiggerDatabase)
		@throw [NSException exceptionWithName:@"Main Database Override Exception"
		                               reason:@"[CIRDatabase+GoldDigger -setAsMainDatabase] throws that you should not override Gold Digger's main database after it was set"
		                             userInfo:nil];

	[Callbacks each:^(id object) {
		((void (^)())object)();
	}];

	GoldDiggerDatabase = self;
}

@end
