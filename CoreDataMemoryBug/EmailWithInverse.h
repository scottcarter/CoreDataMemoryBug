//
//  EmailWithInverse.h
//  CoreDataMemoryBug
//
//  Created by Scott Carter on 1/3/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonWithInverse;

@interface EmailWithInverse : NSManagedObject

@property (nonatomic, retain) NSString * emailLabel;
@property (nonatomic, retain) NSString * emailAddress;
@property (nonatomic, retain) PersonWithInverse *person;

@end
