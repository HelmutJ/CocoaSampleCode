/*
    File:       AppDelegate.m

    Contains:   Main app controller.

    Written by: DTS

    Copyright:  Copyright (c) 1997-2011 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "AppDelegate.h"

#import "SillyBallsView.h"

@interface AppDelegate () <NSApplicationDelegate>

@property (nonatomic, assign, readwrite) BOOL       running;        // whether we are currently drawing
@property (nonatomic, assign, readwrite) double     ballRate;       // the rate at which we should draw

@end

@implementation AppDelegate

@synthesize window = window_;
@synthesize sillyBallView = sillyBallView_;
@synthesize ballRateSlider = sliderView_;
@synthesize ballRateLabel = textView_;

@synthesize running = running_;
@synthesize ballRate = ballRate_;

- (NSTimeInterval)intervalFromRate:(double)rate
    // We map the ball rate slider to a time interval via this function 
    // to get a pleasing non-linearity.
{
    return pow(10, -rate);
}

- (void)didChangeBallRate
    // After a ball rate change we need to update both the ball rate slider 
    // and its associated text field.  I could have done this with bindings 
    // but I decided to use the traditional target/action/outlet mechanism 
    // just to keep things simple.
{
    [self.ballRateSlider setDoubleValue:self.ballRate];
    self.sillyBallView.ballInterval = [self intervalFromRate:self.ballRate];
    [self.ballRateLabel setStringValue:[NSString stringWithFormat:@"%.1f", self.ballRate]];
}

#pragma mark * Application delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)note
    // An application delegate method called on startup.  We set up our 
    // default values and then apply them to the UI.
{
    #pragma unused(note)
    
    assert(self.window != nil);
    assert(self.sillyBallView != nil);
    assert(self.ballRateSlider != nil);
    assert(self.ballRateLabel != nil);
    
    // Set up the default values.
    
    self.running  = YES;
    self.ballRate = 1.0;
    
    // Apply them to the UI.
    
    [self didChangeBallRate];
    self.sillyBallView.ballInterval = [self intervalFromRate:self.ballRate];
    self.sillyBallView.running = self.running;
    
    // After everthing is set up, show our window.
    
    [self.window makeKeyAndOrderFront:self];
}

- (void)dealloc
    // The application delegate is never deallocated, so this is just a stub.
{
    assert(NO);
    [super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
    // An application delegate method called when the user closes the last 
    // window.  In our case, we do want the application to quit when the last 
    // window is closed.
{
    #pragma unused(sender)
    return YES;
}

#pragma mark * User interface actions

- (IBAction)startStopAction:(id)sender
    // See comment in header.
{
    NSButton *  senderButton;
    
    // Change our state.
    
    self.running = ! self.running;

    // Reflect that change to the view.
    
    self.sillyBallView.running = self.running;
    
    // Reflect that change to the menu item.
    
    senderButton = (NSButton *) sender;
    assert([senderButton isKindOfClass:[NSButton class]]);
    
    [senderButton setTitle:self.running ? @"Stop" : @"Start"];
}

- (IBAction)clearAction:(id)sender
    // See comment in header.
{
    #pragma unused(sender)
    
    // Just reflect this operation down to the view.
    
    [self.sillyBallView clear];
}

- (IBAction)sliderDidChangeAction:(id)sender
    // See comment in header.
{
    assert(sender == self.ballRateSlider);
    #pragma unused(sender)

    // Change our state.
    
    self.ballRate = [self.ballRateSlider doubleValue];
    
    // Reflect that change to the ball rate views.
    
    [self didChangeBallRate];
}

@end
