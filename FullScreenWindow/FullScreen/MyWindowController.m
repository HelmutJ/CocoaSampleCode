/*
     File: MyWindowController.m 
 Abstract: This sample's window controller object for managing its window.
  
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"
#import "MyWindow.h"

@implementation MyWindowController

@synthesize frameForNonFullScreenMode;

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // To specify we want our given window to be the full screen primary one, we can
    // use the following:
    //      [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    //
    // But since we have already set this in our xib file for our NSWindow object
    //  (Full Screen -> Primary Window) this line of code it not needed.
    
	// listen for these notifications so we can update our image based on the full-screen state
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterFull:)
                                                 name:NSWindowWillEnterFullScreenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didExitFull:)
                                                 name:NSWindowDidExitFullScreenNotification
                                               object:nil];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillEnterFullScreenNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidExitFullScreenNotification
                                                  object:nil];
    
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	didEnterFull:notif
// -------------------------------------------------------------------------------
- (void)didExitFull:(NSNotification *)notif
{
    // our window "exited" full screen mode
    [imageView setImage:[NSImage imageNamed:@"LakeDonPedro1"]];
}

// -------------------------------------------------------------------------------
//	willEnterFull:notif
// -------------------------------------------------------------------------------
- (void)willEnterFull:(NSNotification *)notif
{
    // our window "entered" full screen mode
    [imageView setImage:[NSImage imageNamed:@"LakeDonPedro2"]];
}

// -------------------------------------------------------------------------------
//	window:willUseFullScreenContentSize:proposedSize
//
//  A window's delegate can optionally override this method, to specify a different
//  full screen size for the window. This delegate method override's the window's full
//  screen content size to include a border space around it.
// -------------------------------------------------------------------------------
- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize
{
    // leave a border space around our full screen window
    //
    return NSMakeSize(proposedSize.width - 180, proposedSize.height - 100);
}

// -------------------------------------------------------------------------------
//	window:willUseFullScreenPresentationOptions:proposedOptions
//
//  Delegate method to determine the presentation options the window will use when
//  transitioning to full-screen mode.
// -------------------------------------------------------------------------------
- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    // customize our appearance when entering full screen:
    // we don't want the dock to appear but we want the menubar to hide/show automatically
    //
    return (NSApplicationPresentationFullScreen |       // support full screen for this window (required)
            NSApplicationPresentationHideDock |         // completely hide the dock
            NSApplicationPresentationAutoHideMenuBar);  // yes we want the menu bar to show/hide
}


#pragma mark -
#pragma mark Enter Full Screen

// as a window delegate, window delegate we provide a list of windows involved in our custom animation,
// in our case we animate just the one primary window.
//
- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window
{
    return [NSArray arrayWithObject:window];
}

- (void)window:(NSWindow *)window startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration
{
    self.frameForNonFullScreenMode = [window frame];
    [self invalidateRestorableState];
    
    NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
    NSRect screenFrame = [screen frame];
    
    NSRect proposedFrame = screenFrame;
    proposedFrame.size = [self window:window willUseFullScreenContentSize:proposedFrame.size];
    
    proposedFrame.origin.x += floor((NSWidth(screenFrame) - NSWidth(proposedFrame))/2);
    proposedFrame.origin.y += floor((NSHeight(screenFrame) - NSHeight(proposedFrame))/2);
    
    // The center frame for each window is used during the 1st half of the fullscreen animation and is
    // the window at its original size but moved to the center of its eventual full screen frame.
    NSRect centerWindowFrame = [window frame];
    centerWindowFrame.origin.x = NSWidth(proposedFrame)/2 - NSWidth(centerWindowFrame)/2;
    centerWindowFrame.origin.y = NSHeight(proposedFrame)/2 - NSHeight(centerWindowFrame)/2;
    
    // Our animation will be broken into two stages.
    // First, we'll move the window to the center of the primary screen and then we'll enlarge
    // it its full screen size.
    //
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [context setDuration:duration];
        [[window animator] setFrame:centerWindowFrame display:YES];
        
    } completionHandler:^{
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            
            [context setDuration:duration/4];
            [[window animator] setFrame:proposedFrame display:YES];
            
        } completionHandler:^{

        }];
    }];
}

- (void)windowDidFailToEnterFullScreen:(NSWindow *)window
{
    // If we had any cleanup to perform in the event of failure to enter Full Screen,
    // this would be the place to do it.
    //
    // One case would be if the user attempts to move to full screen but then
    // immediately switches to Dashboard.
}


#pragma mark -
#pragma mark Exit Full Screen

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window
{
    return [NSArray arrayWithObject:window];
}

- (void)window:(NSWindow *)window startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration
{
    [(MyWindow *)window setConstrainingToScreenSuspended:YES];
    
    // The center frame for each window is used during the 1st half of the fullscreen animation and is
    // the window at its original size but moved to the center of its eventual full screen frame.
    NSRect centerWindowFrame = self.frameForNonFullScreenMode;
    centerWindowFrame.origin.x = window.frame.size.width/2 - self.frameForNonFullScreenMode.size.width/2;
    centerWindowFrame.origin.y = window.frame.size.height/2 - self.frameForNonFullScreenMode.size.height/2;
    
    // Our animation will be broken into two stages.  First, we'll restore the window
    // to its original size while centering it and then we'll move it back to its initial
    // position.
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
         [context setDuration:duration/4];
         [[window animator] setFrame:centerWindowFrame display:YES];
         
     } completionHandler:^{
         
         [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
             [context setDuration:duration];
             [[window animator] setFrame:self.frameForNonFullScreenMode display:YES];
             
         } completionHandler:^{
             
             [(MyWindow *)window setConstrainingToScreenSuspended:NO];
         }];
         
     }];
}

- (void)windowDidFailToExitFullScreen:(NSWindow *)window
{
    // If we had any cleanup to perform in the event of failure to exit Full Screen,
    // this would be the place to do it.
    // ...
}


#pragma mark -
#pragma mark Full Screen Support: Persisting and Restoring Window's Non-FullScreen Frame

+ (NSArray *)restorableStateKeyPaths
{
    return [[super restorableStateKeyPaths] arrayByAddingObject:@"frameForNonFullScreenMode"];
}

@end
