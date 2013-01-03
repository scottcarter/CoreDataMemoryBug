//
//  PersonNoInverse.h
//  CoreDataMemoryBug
//
//  Created by Scott Carter on 1/3/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmailNoInverse;

@interface PersonNoInverse : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) EmailNoInverse *email;

@end
