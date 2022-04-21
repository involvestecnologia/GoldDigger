//
//  GDGDatabase.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/4/16.
//

#import <Foundation/Foundation.h>
#import <SQLAid/CIRDatabase.h>

@protocol GDGDatabaseProvider <NSObject>

- (CIRDatabase *)database;

@end
