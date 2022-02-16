//
//  GDGDatabase.h
//  GoldDigger
//
//  Created by Felipe Lobo on 4/4/16.
//

#import <Foundation/Foundation.h>
#import <SQLAids/CIRDatabase.h>

@protocol GDGDatabaseProvider <NSObject>

- (CIRDatabase *)database;

@end
