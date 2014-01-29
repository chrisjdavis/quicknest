//
//  QNAppDelegate.m
//  QuickNest
//
//  Created by Chris J. Davis on 1/20/14.
//  Copyright (c) 2014 LEAGUEOFBEARDS. All rights reserved.
//

#import "QNAppDelegate.h"
#import "RFKeychain.h"
#import "AXStatusItemPopup.h"
#import "ITProgressBar.h"

@interface QNAppDelegate () {
    AXStatusItemPopup *_statusItemPopup;
}

@end
    
@implementation QNAppDelegate

@synthesize username;
@synthesize password;
@synthesize login;
@synthesize apiReturnJSONData;
@synthesize loginView;
@synthesize window;
@synthesize progressBar;
@synthesize error;
@synthesize prefsWindow;
@synthesize prefsToolBar;
@synthesize generalItems;
@synthesize accountItems;
@synthesize startupItem;
@synthesize doNotifications;
@synthesize savedUserN;
@synthesize savedUserPWD;
@synthesize prefsSaveButton;
@synthesize saveProgressBar;

NSURLConnection *currentConnection = nil;
NSString *nestLogin = @"https://home.nest.com";
NSString *service = @"nest";
NSString *access_token = nil;
NSString *transportUrl = nil;
NSString *userId = nil;
NSString *doNotifics = nil;
NSString *loginItem = nil;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [self reset:self];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *nestUsername = [prefs stringForKey:@"nest.username"];
    NSString *nestPassword = nil;
    
    doNotifics = [prefs stringForKey:@"nest.doNotifications"];
    loginItem = [prefs stringForKey:@"nest.loginItem"];
    transportUrl = [prefs stringForKey:@"nest.transport"];
    access_token = [prefs stringForKey:@"nest.access_token"];
    userId = [prefs stringForKey:@"nest.user_id"];
    
    if( nestUsername ) {
        nestPassword = [RFKeychain passwordForAccount:nestUsername service:@"nest"];
    }
    
    QNViewController *contentViewController = [[QNViewController alloc] initWithNibName:@"QNViewController" bundle:nil];
    
    NSImage *image = [NSImage imageNamed:@"nestIcon"];
    NSImage *alternateImage = [NSImage imageNamed:@"nestIcon"];

    _statusItemPopup = [[AXStatusItemPopup alloc] initWithViewController:contentViewController image:image alternateImage:alternateImage];
    contentViewController.statusItemPopup = _statusItemPopup;

    [self.prefsToolBar setSelectedItemIdentifier:@"gen"];
    
    if( [loginItem isEqualToString:@"YES"] ) {
        [startupItem setState:NSOnState];
    } else {
        [startupItem setState:NSOffState];
    }
    
    if( nestPassword && nestUsername ) {
        [savedUserN setStringValue:nestUsername];
        [savedUserPWD setStringValue:nestPassword];
    }
    
    if( [doNotifics isEqualToString:@"YES"] ) {
        [doNotifications setState:NSOnState];
    } else {
        [doNotifications setState:NSOffState];
    }
    
    if( nestUsername && nestPassword ) {
        [contentViewController nestCurrentTemp];
        [window orderOut:self];
    } else {
        [_statusItemPopup setNeedsDisplay:NO];
        [window makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

-(void)addAsLoginItem {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
    
	CFURLRef url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
    
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
		if (item){
			CFRelease(item);
        }
	}
    
	CFRelease(loginItems);
}

-(void) deleteFromLoginItems {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
    
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		UInt32 seedValue;
		NSArray  *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
		for( int i = 0; i < [loginItemsArray count]; i++ ) {
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFBridgingRetain([loginItemsArray objectAtIndex:i]);
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(NSURL*)CFBridgingRelease(url) path];
                if ([urlPath isEqualToString:appPath]) {
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
	}
}

- (IBAction)reset:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"nest.username"];
    [prefs removeObjectForKey:@"nest.access_token"];
    [prefs removeObjectForKey:@"nest.transport"];
}

- (void)showPrefs {
    [_statusItemPopup setNeedsDisplay:NO];
    [_statusItemPopup hidePopover];
    [prefsWindow makeKeyAndOrderFront:self];
}

- (IBAction)savePrefs:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *saveUsername = [savedUserN stringValue];
    NSString *savePass = [savedUserPWD stringValue];

    [saveProgressBar startAnimation:sender];
    
    [prefs setObject:saveUsername forKey:@"nest.username"];
    [RFKeychain setPassword:savePass account:saveUsername service:service];
    
    [saveProgressBar stopAnimation:sender];
}

- (IBAction)loginToNest:(id)sender {
    NSString *saveUsername = [username stringValue];
    NSString *savePass = [password stringValue];
    NSString *restLogin = nil;

    [CATransaction begin]; {
        [progressBar setHidden:FALSE];
    }[CATransaction commit];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:saveUsername forKey:@"nest.username"];
    
    restLogin = [NSString stringWithFormat:@"%@/user/login?username=%@&amp;password=%@", nestLogin, saveUsername, savePass];
    [RFKeychain setPassword:savePass account:saveUsername service:service];
    
    NSURL *url = [NSURL URLWithString:restLogin];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
    
    [request setHTTPMethod:@"POST"];
    
    NSMutableArray *postData = [[NSMutableArray alloc] init];
    NSDictionary *user = [[NSDictionary alloc] initWithObjectsAndKeys:@"username",saveUsername, nil];
    NSDictionary *passw = [[NSDictionary alloc] initWithObjectsAndKeys:@"password",savePass, nil];
    
    [postData addObject: user];
    [postData addObject: passw];
    
    NSData *pD= [NSKeyedArchiver archivedDataWithRootObject:postData];
    
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:pD];
    
    if( currentConnection) {
        [currentConnection cancel];
        currentConnection = nil;
    }
    
    currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSError *jsonParsingError = nil;
    
    NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
    NSString *hasError = [responseData objectForKey:@"error_description"];
    
    if( hasError == NULL ) {
        NSDictionary *access_dict = [responseData objectForKey:@"access_token"];
        NSDictionary *user_dict = [responseData objectForKey:@"user"];
        NSDictionary *urls_dict = [responseData objectForKey:@"urls"];
        
        NSDictionary *transport_dict = [urls_dict objectForKey:@"transport_url"];
        
        [prefs setObject:access_dict forKey:@"nest.access_token"];
        [prefs setObject:user_dict forKey:@"nest.user_id"];
        [prefs setObject:transport_dict forKey:@"nest.transport"];

        [CATransaction begin]; {
            [progressBar setHidden:TRUE];
        }[CATransaction commit];
        
        [window orderOut:self];
    } else {
        [error setStringValue:hasError];
        
        [CATransaction begin]; {
            [progressBar setHidden:TRUE];
        }[CATransaction commit];
    }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [CATransaction begin]; {
        [progressBar setHidden:TRUE];
    }[CATransaction commit];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"nest.connected"];
    
    NSInteger startState = [startupItem state];
    NSInteger notifsState = [doNotifications state];
    
    if( startState == 1 ) {
        [prefs setObject:@"YES" forKey:@"nest.loginItem"];
        [self addAsLoginItem];
    } else {
        [prefs setObject:@"NO" forKey:@"nest.loginItem"];
        [self deleteFromLoginItems];
    }
    
    if( notifsState == 1 ) {
        [prefs setObject:@"YES" forKey:@"nest.doNotifications"];
    } else {
        [prefs setObject:@"NO" forKey:@"nest.doNotifications"];
    }
    
    return NSTerminateNow;
}

@end
