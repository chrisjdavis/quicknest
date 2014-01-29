//
//  QNViewController.m
//  QuickNest
//
//  Created by Chris J. Davis on 1/21/14.
//  Copyright (c) 2014 LEAGUEOFBEARDS. All rights reserved.
//

#import "QNViewController.h"
#import "QNAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "RFKeychain.h"

@interface NSTextField (AnimatedSetString)

- (void) setAnimatedStringValue:(NSString *)aString;

@end

@implementation NSTextField (AnimatedSetString)

- (void) setAnimatedStringValue:(NSString *)aString
{
    if ([[self stringValue] isEqual: aString])
    {
        return;
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration: 0.5];
        [context setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
        [self.animator setAlphaValue: 0.0];
    }
                        completionHandler:^{
                            [self setStringValue: aString];
                            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                                [context setDuration: 0.5];
                                [context setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];
                                [self.animator setAlphaValue: 1.0];
                            } completionHandler: ^{}];
                        }];
}

@end

@interface QNViewController () <NSMenuDelegate> {}

@end

@implementation QNViewController

@synthesize currentTemp;
@synthesize setTemp;
@synthesize increaseTemp;
@synthesize decreaseTemp;
@synthesize backCircle;
@synthesize activity;
@synthesize weather;
@synthesize login;
@synthesize containerView;
@synthesize dial;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *nestUsername = [prefs stringForKey:@"nest.username"];
    NSString *nestPassword = nil;
    
    if( nestUsername ) {
        nestPassword = [RFKeychain passwordForAccount:nestUsername service:@"nest"];
    }
    
    if( nestPassword ) {
        [NSTimer scheduledTimerWithTimeInterval:300.0f target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
        
        dispatch_sync(dispatch_get_global_queue(0, 0), ^ {
            [self performSelectorInBackground:@selector(nestCurrentTemp) withObject:nil];
        });
    } else {
        [currentTemp setStringValue:@"!"];
        return;
    }
}

- (void) handleTimer:(NSTimer *)timer {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^ {
        [self performSelectorInBackground:@selector(refresh:) withObject:nil];
    });
}

- (IBAction)logOut:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *nestUsername = [prefs stringForKey:@"nest.username"];
    [RFKeychain deletePasswordForAccount:nestUsername service:@"nest"];
}

-(NSString *)runAPI:(NSString*)scriptName {
    NSTask *task = [[NSTask alloc] init];
    NSArray *args;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *nestUsername = [prefs stringForKey:@"nest.username"];
    NSString *nestPassword = [RFKeychain passwordForAccount:nestUsername service:@"nest"];
    
    NSString *taskPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"php"];
    [task setLaunchPath: taskPath];
    
    NSString* scriptPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], scriptName];
    
    args = [NSArray arrayWithObjects:scriptPath, nestUsername, nestPassword, nil];
    [task setArguments: args];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    [task launch];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    [file waitForDataInBackgroundAndNotify];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:file];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    return string;
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *file = [notif object];
    NSData *data = [file availableData];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"%@", str);
}

- (void)nestCurrentTemp {
    [activity startAnimation:self];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    NSString *whatToRun = @"temp.model.php";
    NSString *thisTemp = [self runAPI:whatToRun];
    
    NSString *started = [prefs stringForKey:@"nest.connected"];
    
    BOOL idle = 0;
    
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:[thisTemp dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    NSArray *currentState = [jsonObject valueForKey:@"current_state"];
    NSArray *target = [jsonObject valueForKey:@"target"];
    
    // Find the current state of the nest, e.g. Set to heat/cool.
    NSString *currentMode = [currentState valueForKey:@"mode"];
    NSString *active = [currentState valueForKey:currentMode];
    
    BOOL state = [active boolValue];
    
    if( state == idle ) {
        [backCircle setImage:[NSImage imageNamed:@"off.png"]];
    } else {
        NSString *imageName = [NSString stringWithFormat:@"%@.png", currentMode];
        [backCircle setImage:[NSImage imageNamed:imageName]];
    }
    
    // Process and display the target temp
    NSString *temp = [currentState valueForKey:@"temperature"];
    NSNumber *degrees = @([temp floatValue]);
    int roundedRating = (int)round(degrees.floatValue);
    [currentTemp setAnimatedStringValue:[NSString stringWithFormat:@"%d", roundedRating]];

    NSString *set = [target valueForKey:@"temperature"];
    NSNumber *setDegrees = @([set floatValue]);
    int setRoundedRating = (int)round(setDegrees.floatValue);

    [setTemp setAnimatedStringValue:[NSString stringWithFormat:@"SET TO %d", setRoundedRating]];

    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Connected to Nest!";
    notification.informativeText = [NSString stringWithFormat:@"The current temperature is %dº", setRoundedRating];
    
    if( started == NULL ) {
        [prefs setObject:@"connected" forKey:@"nest.connected"];
        [self showNotification:notification];
    }
    
    int setRoundedWeather = [self getCurrentWeather];
    
    [weather setAnimatedStringValue:[NSString stringWithFormat:@"%dº", setRoundedWeather]];
    [activity stopAnimation:self];
}

- (IBAction)showPrefs:(id)sender {
    [(QNAppDelegate *) [[NSApplication sharedApplication] delegate] showPrefs];
}

-(int)getCurrentWeather {
    NSString *whatToRun = @"location.model.php";
    NSString *thisTemp = [self runAPI:whatToRun];
    
    int setRoundedWeather = (int)round([thisTemp integerValue]);
    return setRoundedWeather;
}

-(IBAction)refresh:(id)sender {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^ {
        [self performSelectorInBackground:@selector(nestCurrentTemp) withObject:nil];
    });
}

-(IBAction)btnIncreaseClicked:(id)sender {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^ {
        [self performSelectorInBackground:@selector(increaseTemperature) withObject:nil];
    });
}

-(IBAction)btnDecreaseClicked:(id)sender {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^ {
        [self performSelectorInBackground:@selector(decreaseTemperature) withObject:nil];
    });
}

-(void)increaseTemperature {
    NSString *whatToRun = [NSString stringWithFormat:@"%@", @"temp.increase.php"];
    [self runAPI:whatToRun];
    [self nestCurrentTemp];
}

-(void)decreaseTemperature {
    NSString *whatToRun = [NSString stringWithFormat:@"%@", @"temp.decrease.php"];
    [self runAPI:whatToRun];
    [self nestCurrentTemp];
}

- (void)showNotification:notif {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *doNotifs = [prefs stringForKey:@"nest.doNotifications"];
    
    if( [doNotifs isEqualToString:@"YES"] ) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
    }
}

@end
