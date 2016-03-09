//
//  CIRDatabase+GoldDigger.h
//  GoldDigger
//
//  Created by Felipe Lobo on 3/1/16.
//

#import <SQLAid/CIRDatabase.h>

@interface CIRDatabase (GoldDigger)

+ (CIRDatabase *)goldDigger_mainDatabase;

+ (void)goldDigger_executeWhenDatabaseIsReady:(void (^)())callback;

- (void)goldDigger_setAsMainDatabase;

@end