//
//  CoreDataMemoryBugViewController.m
//  CoreDataMemoryBug
//
//  Created by Scott Carter on 1/2/13.
//  Copyright (c) 2013 Scott Carter. All rights reserved.
//

/* 
 
 Description
 ===========
 This project is intended to demonstrate what appear to be bugs in how Core Data 
 manages memory.  In several cases, Core Data is not releasing allocated memory as expected.
 
 Please see the section below labeled "Constants and Defines" where the various test cases
 are documented.
 
 I have flagged certain test cases with "ISSUE" where the behaviour is not as expected.
 
 
 Test Selection
 ==============
 Select a test case by changing the define for TEST_CASE.  As an example, one would
 choose the first test case by changing the define to:
 
 #define TEST_CASE 1
 
 
 Run a test case
 ===============
 Profile the test using the Allocations Instrument.
 
 Let the test run for at least 25 seconds to ensure that a steady state has been reached.
 
 Examine the "Live Bytes" and "# Living" columns to measure allocations in the steady state.
 
 
 MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS
 ======================================
 Since this project includes a pair of entities that has a relationship in only one direction
 (PersonNoInverse, EmailNoInverse), I get the warning:
 "CoreDataMemoryBug.xcdatamodel
    Misconfigured Property
    PersonNoInverse.email should have an inverse"
 
 I see this same warning appear twice.   Setting MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS to YES in the 
 TARGETS Build Settings, gets rid of one of the warnings.   Setting this flag to YES in the PROJECT Build
 Settings has no affect.
 
 Is this also a bug?
 
 
 */



#import "CoreDataMemoryBugViewController.h"


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Private Interface
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//

@interface CoreDataMemoryBugViewController ()


// ==========================================================================
// Properties
// ==========================================================================
//
#pragma mark -
#pragma mark Properties

@property (nonatomic, strong) UIManagedDocument *contactDatabase;  // Model is a Core Data database of contacts

@end


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Implementation
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
#pragma mark -

@implementation CoreDataMemoryBugViewController


// ==========================================================================
// Constants and Defines
// ==========================================================================
//
#pragma mark -
#pragma mark Constants and Defines

// Contact Database Name
#define CONTACT_DATABASE_NAME @"_Contact_Database"


// Select a test case
#define TEST_CASE 0


// 
// ***** Definitions of test cases *****
//
// Notes
// -------------------
// - Using iPhone 6.0 Simulator
// - Measurements of Live Bytes, #Living taken in steady state from "All Allocations" row.
// - For each test case (except 0 - manual operation), we are removing all records and then inserting 25,000 records.
//
// Terminology used
// -----------------
// MOC: Managed object context.
// Add: Add some records to Core Data
// Empty: Remove persistent store from MOC, delete file on disk and recreate store.
// Refresh: Call refreshObject on managed objects to turn objects into faults.
// Reset:   Call reset method on MOC to "forget" all managed objects.
// Recreate Store:  Remove persistent store from MOC and recreate.
//
//
// Manual operation
// ----------------
// TEST_CASE 0  Manual interation using buttons.
//      Live Bytes=   #Living=
//
//
// No retain loop (No Inverse relationship in Core Data)
// --------------------------------------------------------------------------------------
// TEST_CASE 1 Empty/Add  (Baseline)
//      Live Bytes=16.53 MB   #Living=437,489
//
// TEST_CASE 2  Empty/Add/Refresh.
//      Live Bytes=8.33 MB   #Living=162,508
//      ISSUE  Core Data not releasing memory as expected after all managed objects faulted.
//
// TEST_CASE 3  Empty/Add/Reset
//      Live Bytes=5.48 MB   #Living=112,476
//      ISSUE   Core Data not releasing memory as expected after MOC reset.
//
// TEST_CASE 4 Empty/Add/Recreate
//      Live Bytes=2.07 MB   #Living=12,211
//      Note:  This is what I would expect once Core Data releases all memory properly (our gold standard).
//
// TEST_CASE 5 Empty/Add/Refresh/Reset (Reset not in same event loop iteration as Refresh)
//      Live Bytes=2.12 MB   #Living=12,482
//      ISSUE: While the end result looks good, it took 10 seconds after MOC reset completed to go from 5.49 MB
//            to where it settled at 2.12 MB.
//
// TEST_CASE 6 Empty/Add/Refresh/Reset (Reset in same event loop iteration as Refresh)
//      Live Bytes=5.49 MB   #Living=112,475
//      ISSUE: Core Data not releasing memory as expected after MOC reset.  For some reason, including Reset in
//             same event loop as Refresh causes a change in behaviour.
//
//
// No retain loop.  Call setUndoManager:nil on MOC
// -------------------------------------------------
// Note:  I was not expecting any differences here from previous test cases above, since the
// documentation for NSManagedObjectContext indicated:
// "on iOS, the undo manager is nil by default."
//
// TEST_CASE 10 Empty/Add (Baseline)
//      Live Bytes=5.35 MB   #Living=112,448
//      ISSUE:  I would not expect this result to be different than TEST_CASE 1
//
// TEST_CASE 11  Empty/Add/Refresh.
//      Live Bytes=5.35 MB   #Living=112,451
//
// TEST_CASE 12 Empty/Add/Reset
//       Live Bytes=5.24 MB   #Living=112,461
//
// TEST_CASE 13 Empty/Add/Recreate
//      Live Bytes=1.94 MB   #Living=12,184
//
// TEST_CASE 14 Empty/Add/Refresh/Reset
//      Live Bytes=5.24 MB   #Living=112,444
//      ISSUE: Compare this test case to TEST_CASE 5.   I would expect the result to be the same, but it is not.
//
//
// Retain loop (Cause retain loop using inverse relationship in Core Data)
// -----------------------------------------------------------------------
// TEST_CASE 100  Empty/Add (Baseline)
//      Live Bytes=22.52 MB   #Living=610,550
//
// TEST_CASE 101 Empty/Add/Refresh
//      Live Bytes=19.09 MB   #Living=460,579
//
// TEST_CASE 102 Empty/Add/Reset
//      Live Bytes=8.85 MB   #Living=212,580
//
// TEST_CASE 103 Empty/Add/Recreate
//      Live Bytes=2.08 MB   #Living=12,306
//      Note:  As with TEST_CASE 4, the Recreate of Persistent Store after a save provides a quick way to reclaim all
//             memory allocated and held by Core Data.
//
// TEST_CASE 104 Empty/Add/Refresh/Reset
//      Live Bytes=8.85 MB   #Living=212,573
//      ISSUE: Compare to TEST_CASE 5 (which eventually released memory held by Core Data).  The presence of a
//             retain loop causes memory to not be released.
//
//
// Retain loop   Call setUndoManager:nil on MOC
// --------------------------------------------
// TEST_CASE 110 Empty/Add (Baseline)
//      Live Bytes=20.49 MB  #Living=560,501
//
// TEST_CASE 111 Empty/Add/Refresh
//      Live Bytes=8.73 MB   #Living=212,548
//
// TEST_CASE 112 Empty/Add/Reset
//      Live Bytes=8.73 MB   #Living=212,550
//
// TEST_CASE 113 Empty/Add/Recreate
//      Live Bytes= N/A  #Living= N/A
//      ISSUE:  This test case caused a hang in the call to removePersistentStore inside our method recreatePersistentStore.
//
// TEST_CASE 114 Empty/Add/Refresh/Reset
//      Live Bytes= 8.73 MB  #Living=212,551
//
// TEST_CASE 115 Empty/Add/Refresh/Recreate
//      Live Bytes= 2.07 MB  #Living=12,285
//      Note:  Interesting that this test case works (with addition of Refresh) and TEST_CASE 113 hangs.
//
// TEST_CASE 116 Empty/Add/Reset/Recreate
//      Live Bytes= 2.08 MB   #Living=12,295
//
//
//
// Permanent ID test
// ---------------------
// TEST_CASE 1000 Empty/Add/Recreate  Do NOT obtain permanent ids for managed objects prior to save.
//      Live Bytes=4.85 MB   #Living=112,285
//      ISSUE:  Core Data not releasing memory as expected.  In particular, there are 50,000 references
//              to NSTemporaryObjectID_default not being released (781 Kbytes).
// 


// If this is not a manual test case, we always start by emptying and then adding records to Core Data
#if (TEST_CASE > 0)
#define EMPTY_CORE_DATA 1
#define ADD_TO_CORE_DATA 1
#endif

// No retain loop (No Inverse relationship in Core Data)
#if (TEST_CASE == 2)
#define REFRESH_OBJECT 1
#endif

#if (TEST_CASE == 3)
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 4)
#define RECREATE_PERSISTENT_STORE 1
#endif

#if (TEST_CASE == 5)
#define REFRESH_OBJECT 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 6)
#define REFRESH_OBJECT 1
#define RESET_CONTEXT_SAME_EVENT_LOOP 1
#endif


// No retain loop.  Call setUndoManager:nil on MOC
#if (TEST_CASE == 10)
#define UNDO_MANAGER_NIL 1
#endif

#if (TEST_CASE == 11)
#define UNDO_MANAGER_NIL 1
#define REFRESH_OBJECT 1
#endif

#if (TEST_CASE == 12)
#define UNDO_MANAGER_NIL 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 13)
#define UNDO_MANAGER_NIL 1
#define RECREATE_PERSISTENT_STORE 1
#endif

#if (TEST_CASE == 14)
#define UNDO_MANAGER_NIL 1
#define REFRESH_OBJECT 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif


// Retain loop (Cause retain loop using inverse relationship in Core Data)
#if (TEST_CASE >= 100) 
#define INVERSE_RELATIONSHIP 1
#endif

#if (TEST_CASE == 101)
#define REFRESH_OBJECT 1
#endif

#if (TEST_CASE == 102)
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 103)
#define RECREATE_PERSISTENT_STORE 1
#endif

#if (TEST_CASE == 104)
#define REFRESH_OBJECT 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif


// Retain loop   Call setUndoManager:nil on MOC
#if (TEST_CASE == 110)
#define UNDO_MANAGER_NIL 1
#endif

#if (TEST_CASE == 111)
#define UNDO_MANAGER_NIL 1
#define REFRESH_OBJECT 1
#endif

#if (TEST_CASE == 112)
#define UNDO_MANAGER_NIL 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 113)
#define UNDO_MANAGER_NIL 1
#define RECREATE_PERSISTENT_STORE 1
#endif

#if (TEST_CASE == 114)
#define UNDO_MANAGER_NIL 1
#define REFRESH_OBJECT 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#endif

#if (TEST_CASE == 115)
#define UNDO_MANAGER_NIL 1
#define REFRESH_OBJECT 1
#define RECREATE_PERSISTENT_STORE 1
#endif

#if (TEST_CASE == 116)
#define UNDO_MANAGER_NIL 1
#define RESET_CONTEXT_NEXT_EVENT_LOOP 1
#define RECREATE_PERSISTENT_STORE_NEXT_EVENT_LOOP 1
#endif


// Obtain permanent ids for managed objects unless this is test case 1000.
#if (TEST_CASE != 1000)
#define OBTAIN_PERM_ID 1
#endif

#if (TEST_CASE == 1000)
#define RECREATE_PERSISTENT_STORE 1
#endif



// ==========================================================================
// Synthesize private properties
// ==========================================================================
//
#pragma mark -
#pragma mark Synthesize private properties

@synthesize contactDatabase = _contactDatabase;


// ==========================================================================
// Getters and Setters
// ==========================================================================
//
#pragma mark -
#pragma mark Getters and Setters

// Setup our fetched results controller when database changes.
- (void)setContactDatabase:(UIManagedDocument *)contactDatabase
{
    if(_contactDatabase != contactDatabase){
        _contactDatabase = contactDatabase;
        
#ifdef UNDO_MANAGER_NIL
        [_contactDatabase.managedObjectContext setUndoManager:nil];
#endif
        
        // Start with an empty database
#ifdef EMPTY_CORE_DATA
        [self emptyCoreData];
#endif
        
        // Add records to core data
#ifdef ADD_TO_CORE_DATA
        [self addToCoreData];
#endif
        
    }
}


// ==========================================================================
// Initializations
// ==========================================================================
//
#pragma mark -
#pragma mark Initializations

// Callback for fetch of managed document
- (void)readyWithDocument:(UIManagedDocument *)managedDocument
{
    self.contactDatabase = managedDocument;
}



- (void)viewDidLoad
{
    
    // Inform the user about the test case parameters
    
#if (TEST_CASE == 0)
    NSLog(@"Manual test case.  Use buttons for interaction");
#endif
    
#ifdef EMPTY_CORE_DATA
    NSLog(@"EMPTY_CORE_DATA defined");
#endif
    
#ifdef ADD_TO_CORE_DATA
    NSLog(@"ADD_TO_CORE_DATA defined");
#endif
    
#ifdef REFRESH_OBJECT
    NSLog(@"REFRESH_OBJECT defined");
#endif
    
#ifdef INVERSE_RELATIONSHIP
    NSLog(@"INVERSE_RELATIONSHIP defined");
#endif
    
#ifdef OBTAIN_PERM_ID
    NSLog(@"OBTAIN_PERM_ID defined");
#endif
    
#ifdef RESET_CONTEXT_NEXT_EVENT_LOOP
    NSLog(@"RESET_CONTEXT_NEXT_EVENT_LOOP defined");
#endif
    
#ifdef RESET_CONTEXT_SAME_EVENT_LOOP
    NSLog(@"RESET_CONTEXT_SAME_EVENT_LOOP defined");
#endif
    
#ifdef RECREATE_PERSISTENT_STORE
    NSLog(@"RECREATE_PERSISTENT_STORE defined");
#endif
    
#ifdef RECREATE_PERSISTENT_STORE_NEXT_EVENT_LOOP
    NSLog(@"RECREATE_PERSISTENT_STORE_NEXT_EVENT_LOOP defined");
#endif
    
#ifdef UNDO_MANAGER_NIL
    NSLog(@"UNDO_MANAGER_NIL defined");
#endif
    
    
    
    
    // Get our managed document.
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:CONTACT_DATABASE_NAME]; // url is now "<Documents Directory>/documentName
    
    UIManagedDocument *managedDocument = [[UIManagedDocument alloc] initWithFileURL:url];
    
        
    NSLog(@"Created document %@",CONTACT_DATABASE_NAME);
    
    
    // Does not exist on disk, so create it
    if (![[NSFileManager defaultManager] fileExistsAtPath:[managedDocument.fileURL path]]) {
        NSLog(@"Document did not exist on disk, so we are creating");
        [managedDocument saveToURL:managedDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self readyWithDocument:managedDocument];
        }];
    }
    
    // Exists on disk, but we need to open it
    else if (managedDocument.documentState == UIDocumentStateClosed) {
        NSLog(@"Document existed on disk and needs to be opened");
        [managedDocument openWithCompletionHandler:^(BOOL success) {
            [self readyWithDocument:managedDocument];
        }];
    }
    
    // Already open and ready to use
    else if (managedDocument.documentState == UIDocumentStateNormal) {
        NSLog(@"Document is already open and ready for use");
        [self readyWithDocument:managedDocument];
    }
    
    else if (managedDocument.documentState == UIDocumentStateInConflict) {
        NSLog(@"ERROR: Got UIDocumentStateInConflict");
    }
    
    else if (managedDocument.documentState == UIDocumentStateSavingError) {
        NSLog(@"ERROR: Got UIDocumentStateSavingError");
    }
    
    else if (managedDocument.documentState == UIDocumentStateEditingDisabled) {
        NSLog(@"ERROR: Got UIDocumentStateEditingDisabled");
    }
    
    else {
        NSLog(@"ERROR: Other documentState = %d",managedDocument.documentState);
    }
    
    
    
}




// ==========================================================================
// Actions
// ==========================================================================
//
#pragma mark -
#pragma mark Actions


- (IBAction)addToCoreDataAction:(UIButton *)sender {
    [self addToCoreData];
}


- (IBAction)emptyCoreDataAction:(UIButton *)sender {
    [self emptyCoreData];
}


- (IBAction)refreshObjectsAction:(UIButton *)sender {
    [self refreshObjects];
}


- (IBAction)resetContextAction:(UIButton *)sender {
    [self resetContext];
}


- (IBAction)recreatePersistentStoreAction:(UIButton *)sender {
    [self recreatePersistentStore];
}


// ==========================================================================
// Methods
// ==========================================================================
//
#pragma mark -
#pragma mark Methods


// Add some information to Core Data
- (void)addToCoreData
{
    
    // Create some entities and populate with test data.
    for(int i=0; i<25000; i++) {
        
#ifdef INVERSE_RELATIONSHIP
        PersonWithInverse *person = [NSEntityDescription insertNewObjectForEntityForName:@"PersonWithInverse" inManagedObjectContext:self.contactDatabase.managedObjectContext];
        
        EmailWithInverse *email = [NSEntityDescription insertNewObjectForEntityForName:@"EmailWithInverse" inManagedObjectContext:self.contactDatabase.managedObjectContext];
#else
        PersonNoInverse *person = [NSEntityDescription insertNewObjectForEntityForName:@"PersonNoInverse" inManagedObjectContext:self.contactDatabase.managedObjectContext];
        
        EmailNoInverse *email = [NSEntityDescription insertNewObjectForEntityForName:@"EmailNoInverse" inManagedObjectContext:self.contactDatabase.managedObjectContext];
#endif
        
        person.firstName = @"Jonathan";
        
        
        email.emailLabel = @"home email";
        email.emailAddress = @"jon@hotmail.com";
        
        // It makes no difference to the memory allocation test cases whether
        // there is a To-Many Relationship or not.
        //[person addEmailObject:email];
        //
        person.email = email;
        
    }
    
    
    // Convert all temporary ids to permanent ids.
#ifdef OBTAIN_PERM_ID
    NSArray *objArr = [[self.contactDatabase.managedObjectContext registeredObjects] allObjects];
    BOOL result = [self.contactDatabase.managedObjectContext obtainPermanentIDsForObjects:objArr error:nil];
    if(result == NO){
        NSLog(@"WARNING: Was not able to obtain permanent ids for all objects.");
    }
#endif
    
    
    [self.contactDatabase saveToURL:self.contactDatabase.fileURL
                   forSaveOperation:UIDocumentSaveForOverwriting
                  completionHandler:^(BOOL success) {
                      if(!success){
                          NSLog(@"ERROR: Failed to save document %@", self.contactDatabase.localizedName);
                      } else {
                          
                          NSLog(@"Completed addToCoreData.  Save has completed successfully.");
                          
#ifdef REFRESH_OBJECT
                          [self refreshObjects];
#endif
                        
                          
#ifdef RESET_CONTEXT_SAME_EVENT_LOOP
                          [self resetContext];
#endif
       
                          
#ifdef RECREATE_PERSISTENT_STORE
                          [self recreatePersistentStore];
#endif
                          
                          
#ifdef RESET_CONTEXT_NEXT_EVENT_LOOP
                          [NSTimer scheduledTimerWithTimeInterval:0.0
                                                           target:self
                                                         selector:@selector(resetContext)
                                                         userInfo:nil
                                                          repeats:NO];
#endif
                          
                          // If a call to recreatePersistentStore is scheduled for next event loop,
                          // we would want it to occur after any possible call to resetContext, so delay
                          // by a few seconds.
#ifdef RECREATE_PERSISTENT_STORE_NEXT_EVENT_LOOP
                          [NSTimer scheduledTimerWithTimeInterval:3.0
                                                           target:self
                                                         selector:@selector(recreatePersistentStore)
                                                         userInfo:nil
                                                          repeats:NO];
#endif
                          
                          
                      }
                      
                  }];
     
}


// Remove the persistent store for our context and delete the associated file on disk.
//
- (void)emptyCoreData
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.contactDatabase.managedObjectContext;
    
    // Retrieve the store URL
    NSURL * storeURL = [[managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
    
    
    [managedObjectContext lock];  // Lock the current context
    
    
    // Remove the store from the current managedObjectContext
    if ([[managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
    {
        // Remove the file containing the data
        if(![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
            NSLog(@"Could not remove persistent store file");
        }
        
        // Recreate the persistent store
        if(![[managedObjectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]){
            NSLog(@"Could not add persistent store");
        }
    }
    
    else {
        NSLog(@"Could not remove persistent store");
    }
    
    [managedObjectContext reset];
    [managedObjectContext unlock];
    
    NSLog(@"Completed emptyCoreData");
}



- (void)refreshObjects
{
    for (NSManagedObject *mo in [self.contactDatabase.managedObjectContext registeredObjects]) {
        [self.contactDatabase.managedObjectContext refreshObject:mo mergeChanges:NO];
    }
    NSLog(@"Completed refreshObjects");
}


- (void)resetContext
{
    [self.contactDatabase.managedObjectContext reset];
    NSLog(@"Completed resetContext");
    
}



// Remove the persistent store for our context.
//
// Note that this performs the same actions as emptyCoreData, but does not remove the file on disk.
//
- (void)recreatePersistentStore
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.contactDatabase.managedObjectContext;
    
    // Retrieve the store URL
    NSURL * storeURL = [[managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
    
    [managedObjectContext lock];  // Lock the current context
    
    
    // Remove the store from the current managedObjectContext
    if ([[managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
    {
        
        // Recreate the persistent store
        if(![[managedObjectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]){
            NSLog(@"Could not add persistent store");
        }
    }
    
    else {
        NSLog(@"Could not remove persistent store");
    }
    
    
    [managedObjectContext reset];
    [managedObjectContext unlock];
    
    NSLog(@"Completed recreatePersistentStore");
}


@end

















