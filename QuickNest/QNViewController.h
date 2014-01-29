//
//  QNViewController.h
//  QuickNest
//
//  Created by Chris J. Davis on 1/21/14.
//  Copyright (c) 2014 LEAGUEOFBEARDS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNAppDelegate.h"
#import "AXStatusItemPopup.h"

@interface QNViewController : NSViewController

@property(weak, nonatomic) AXStatusItemPopup *statusItemPopup;
@property (retain, nonatomic) IBOutlet NSTextField *currentTemp;
@property (retain, nonatomic) IBOutlet NSTextField *setTemp;
@property (weak) IBOutlet NSButton *increaseTemp;
@property (weak) IBOutlet NSButton *decreaseTemp;
@property (weak) IBOutlet NSImageView *backCircle;
@property (weak) IBOutlet NSProgressIndicator *activity;
@property (weak) IBOutlet NSTextField *weather;
@property (weak) IBOutlet NSButton *login;
@property (retain, nonatomic) IBOutlet NSView *containerView;
@property (retain, nonatomic) IBOutlet NSView *dial;
@property (retain, nonatomic) IBOutlet NSView *loginError;

-(void)nestCurrentTemp;
-(IBAction)showPrefs:(id)sender;

@end
