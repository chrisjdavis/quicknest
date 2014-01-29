#import <QuartzCore/QuartzCore.h>

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