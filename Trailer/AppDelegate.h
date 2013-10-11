//
//  AppDelegate.h
//  Trailer
//
//  Created by Paul Tsochantaris on 20/09/2013.
//  Copyright (c) 2013 HouseTrip. All rights reserved.
//

#define LOW_API_WARNING 1000

@interface AppDelegate : NSObject <NSApplicationDelegate,
NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (unsafe_unretained) IBOutlet NSWindow *preferencesWindow;

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) API *api;
@property (weak) IBOutlet NSButton *refreshButton;
@property (weak) IBOutlet NSTextField *githubToken;
@property (weak) IBOutlet NSMenu *statusBarMenu;
@property (weak) IBOutlet NSTextField *tokenHolder;
@property (weak) IBOutlet NSProgressIndicator *activityDisplay;
@property (weak) IBOutlet NSTableView *projectsTable;
@property (weak) IBOutlet NSMenuItem *refreshNow;
@property (weak) IBOutlet NSButton *clearAll;
@property (weak) IBOutlet NSButton *selectAll;
@property (weak) IBOutlet NSProgressIndicator *apiLoad;

+(AppDelegate*)shared;

@end
