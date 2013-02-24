/*
     File: LTWindowController.m
 Abstract: This is the window controller for our document window. It performs two functions. First, it sets up the bindings that we could not do in IB. Second, it handles showing and hiding the tools view when the user swipes.
 
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "LTWindowController.h"


@implementation LTWindowController

- (void)awakeFromNib {
    _toolsViewFrame = [self.toolsView frame];
    
    NSView *contentView = [self.toolsView superview];
    [self.toolsView removeFromSuperview];
    
    NSPoint newOrigin = _toolsViewFrame.origin;
    newOrigin.x = -(NSMaxX(_toolsViewFrame) + 1);
    [self.toolsView setFrameOrigin:newOrigin];
    [contentView addSubview:self.toolsView];
    
        
    
    // Set up the bindings between the LTView and the NSArrayController that points to Core Data data model.
    [_lightTableView bind:@"slides" toObject:_slidesArrayController withKeyPath:@"arrangedObjects" options:nil];
    
    [_slidesArrayController bind:@"selectionIndexes" toObject:_lightTableView withKeyPath:@"selectionIndexes" options:nil];
    
}


#pragma mark NSResponder

/* If no view in the window processes the swipe, then this window controller will have its -swipeWithEvent: method called, at which point we want to hide or show the tools.
*/
- (void)swipeWithEvent:(NSEvent *)event {
    CGFloat delta = [event deltaX];
    
    if (delta > 0.0) {
        // Swipe to the left.
        [self hideToolsView:nil];
    } else if (delta < 0.0) {
        // Swipe to the right.
        [self showToolsView:nil];
    }
}


#pragma mark NSMenuValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleToolsViewShown:)) {
        if (self.toolsView.frame.origin.x < _toolsViewFrame.origin.x) {
            [menuItem setState:NSOffState];
        } else {
            [menuItem setState:NSOnState];
        }
    }
    
    return YES;
}


#pragma mark API

@synthesize toolsView = _toolsView;
@synthesize lightTableView = _lightTableView;
@synthesize slidesArrayController = _slidesArrayController;

- (IBAction)toggleToolsViewShown:(id)sender {
    if (self.toolsView.frame.origin.x < _toolsViewFrame.origin.x) {
        [self showToolsView:sender];
    } else {
        [self hideToolsView:sender];
    }
}

- (IBAction)hideToolsView:(id)sender {
    NSPoint newOrigin = _toolsViewFrame.origin;
    newOrigin.x = -(NSMaxX(_toolsViewFrame) + 1);
    [[self.toolsView animator] setFrameOrigin:newOrigin];
}

- (IBAction)showToolsView:(id)sender {
    [[self.toolsView animator] setFrameOrigin:_toolsViewFrame.origin];
}
@end
