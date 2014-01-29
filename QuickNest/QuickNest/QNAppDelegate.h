//
//  QNAppDelegate.h
//  QuickNest
//
//  Created by Chris J. Davis on 1/20/14.
//  Copyright (c) 2014 LEAGUEOFBEARDS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ITProgressBar.h"
#import "QNViewController.h"

@class QNAppDelegate;

@interface QNAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (retain, nonatomic) IBOutlet NSTextField *username;
@property (weak) IBOutlet NSTextField *password;
@property (assign) IBOutlet ITProgressBar *progressBar;
@property (assign) IBOutlet NSProgressIndicator *saveProgressBar;
@property (weak) IBOutlet NSButton *login;
@property (weak) NSMutableData *apiReturnJSONData;
@property (weak) IBOutlet NSView *loginView;
@property (weak) IBOutlet NSTextField *error;
@property (weak) IBOutlet NSWindow *prefsWindow;
@property (weak) IBOutlet NSToolbar *prefsToolBar;
@property (weak) IBOutlet NSToolbarItem *generalItems;
@property (weak) IBOutlet NSToolbarItem *accountItems;
@property (weak) IBOutlet NSButton *startupItem;
@property (weak) IBOutlet NSButton *doNotifications;
@property (weak) IBOutlet NSTextField *savedUserN;
@property (weak) IBOutlet NSTextField *savedUserPWD;
@property (weak) IBOutlet NSButton *prefsSaveButton;
    
- (IBAction)loginToNest:(id)sender;
- (void)showPrefs;
    
@end
