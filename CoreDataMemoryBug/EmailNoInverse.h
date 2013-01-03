//
//  EmailNoInverse.h
//  CoreDataMemoryBug
//
//  Created by Scott Carter on 1/3/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EmailNoInverse : NSManagedObject

@property (nonatomic, retain) NSString * emailLabel;
@property (nonatomic, retain) NSString * emailAddress;

@end
