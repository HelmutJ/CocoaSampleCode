/*
     File: MyWindowController.m 
 Abstract: This sample's main NSWindowController managing its primary window. 
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"
#import "MyViewController.h"
#import "NSButton+Extended.h"

@implementation MyWindowController

@synthesize myPopover;

// -------------------------------------------------------------------------------
//  awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // setup the default preferences
    [animatesCheckbox setState:1];                  // animates = YES
    [popoverType setState:1 atRow:0 column:0];      // type = normal
    [popoverPosition setState:1 atRow:1 column:0];  // position = NSMinYEdge
    
    // To make a popover detachable to a separate window you need:
    // 1) a separate NSWindow instance
    //      - it must not be visible:
    //          (if created by Interface Builder: not "Visible at Launch")
    //          (if created in code: must not be ordered front)
    //      - must not be released when closed
    //      - ideally the same size as the view controller's view frame size
    //
    // 2) two separate NSViewController instances
    //      - one for the popover, the other for the detached window
    //      - view best loaded as a sebarate nib (file's owner = NSViewController)
    //
    // To make the popover detached, simply drag the visible popover away from its attached view
    //
    // Fore more detailed information, refer to NSPopover.h
    
    // set separate copies of the view controller's view to each detached window
    detachedWindow.contentView = detachedWindowViewController.view;
    detachedHUDWindow.contentView = detachedWindowViewControllerHUD.view;
    
    // change the detached HUD window's view controller to use white text and labels
    [detachedWindowViewControllerHUD.checkButton setTextColor:[NSColor whiteColor]];
    [detachedWindowViewControllerHUD.textLabel setTextColor:[NSColor whiteColor]];
}

// -------------------------------------------------------------------------------
//  createPopover
// -------------------------------------------------------------------------------
- (void)createPopover
{
    if (self.myPopover == nil)
    {
        // create and setup our popover
        myPopover = [[NSPopover alloc] init];
        
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        //
        // use a different view controller content if normal vs. HUD appearance
        //
        if ([popoverType selectedRow] == 0)
        {
            self.myPopover.contentViewController = popoverViewController;
        }   
        else
        {
            self.myPopover.contentViewController = popoverViewControllerHUD;
        } 
        self.myPopover.appearance = [popoverType selectedRow];
        
        self.myPopover.animates = [animatesCheckbox state];
        
        // AppKit will close the popover when the user interacts with a user interface element outside the popover.
        // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
        self.myPopover.behavior = NSPopoverBehaviorTransient;
        
        // so we can be notified when the popover appears or closes
        self.myPopover.delegate = self;
    }
}

// -------------------------------------------------------------------------------
//  dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [myPopover release];
    [super dealloc];
}

// -------------------------------------------------------------------------------
//  showPopoverAction:sender
// -------------------------------------------------------------------------------
- (IBAction)showPopoverAction:(id)sender
{
    [self createPopover];
    
    NSButton *targetButton = (NSButton *)sender;
    
    // configure the preferred position of the popover
    NSRectEdge prefEdge = popoverPosition.selectedRow;
    
    [self.myPopover showRelativeToRect:[targetButton bounds] ofView:sender preferredEdge:prefEdge];
}

// -------------------------------------------------------------------------------
//  applicationShouldTerminateAfterLastWindowClosed:sender
//
//  NSApplication delegate method placed here so the sample conveniently quits
//  after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


#pragma mark -
#pragma mark NSPopoverDelegate

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
// This method will also be invoked on the popover. 
// -------------------------------------------------------------------------------
- (void)popoverWillShow:(NSNotification *)notification
{
    NSPopover *popover = [notification object];
    if (popover.appearance == NSPopoverAppearanceHUD)
    {
        // popoverViewControllerHUD is loaded by now, so set its UI to use white text and labels
        [popoverViewControllerHUD.checkButton setTextColor:[NSColor whiteColor]];
        [popoverViewControllerHUD.textLabel setTextColor:[NSColor whiteColor]];
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
// This method will also be invoked on the popover. 
// -------------------------------------------------------------------------------
- (void)popoverDidShow:(NSNotification *)notification
{
    // add new code here after the popover has been shown
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
// This method will also be invoked on the popover. 
// -------------------------------------------------------------------------------
- (void)popoverWillClose:(NSNotification *)notification
{
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "before" the popover closes
        //
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
// This method will also be invoked on the popover. 
// -------------------------------------------------------------------------------
- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
    }
    
    [myPopover release];
    myPopover = nil;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate asked for the detachable window for the popover.
// -------------------------------------------------------------------------------
- (NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
    NSWindow *window = detachedWindow;
    if (popover.appearance == NSPopoverAppearanceHUD)
    {
        window = detachedHUDWindow;
    }
    return window;
}

@end
