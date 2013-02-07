/*
     File: MainWindowController.m 
 Abstract: Class for the sample's main window controller. 
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

#import "MainWindowController.h"


@implementation MainWindowController

-(id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    return self;
}


// NOTE: One key to having the contained view resize correctly is to have its autoresizing set correctly in IB.
//Based on the new content view frame, calculate the window's new frame
-(NSRect)newFrameForNewContentView:(NSView *)view {
    NSWindow *window = [self window];
    NSRect newFrameRect = [window frameRectForContentRect:[view frame]];
    NSRect oldFrameRect = [window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame = [window frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    
    return frame;
}


-(NSView *)viewForTag:(int)tag {
    NSView *view = nil;
    switch(tag) {
	case 0: view = smallView; break;
	case 1: view = mediumView; break;
	case 2: default: view = largeView; break;
    }
    return view;
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item tag] == currentViewTag) return NO;
    else return YES;
}


// We need to be layer-backed to have subview transitions.
-(void)awakeFromNib {
    [[self window] setContentSize:[smallView frame].size];
    [[[self window] contentView] addSubview:smallView];
    [[[self window] contentView] setWantsLayer:YES];
}


-(IBAction)switchView:(id)sender {

	// Figure out the new view, the old view, and the new size of the window
	int tag = [sender tag];
	NSView *view = [self viewForTag:tag];
	NSView *previousView = [self viewForTag: currentViewTag];
	currentViewTag = tag;
	
	NSRect newFrame = [self newFrameForNewContentView:view];

	// Using an animation grouping because we may be changing the duration
	[NSAnimationContext beginGrouping];
	
	// With the shift key down, do slow-mo animation
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	    [[NSAnimationContext currentContext] setDuration:1.0];
	
	// Call the animator instead of the view / window directly
	[[[[self window] contentView] animator] replaceSubview:previousView with:view];
	[[[self window] animator] setFrame:newFrame display:YES];

	[NSAnimationContext endGrouping];
	
}


// In this case, just moving an image view back and forth.
// Note the use of the animator.
-(IBAction)moveView:(id)sender {
    NSPoint newPoint = didMoveView ? NSMakePoint(17.0, 87.0) : NSMakePoint(339.0, 87.0);

    [[imageView animator] setFrameOrigin: newPoint];
    
    didMoveView = !didMoveView;
}


// Moving all subviews except the button that triggers the action.
// Note the use of the animator, and that there is an implied transaction
// All of the animations start simultaneously.
-(IBAction)moveAllViews:(id)sender {
    float deltaY = didMoveAllViews ? 222.0 : -222.0;
    
    for (NSView *subview in [mediumView subviews]) {
	if ([subview tag] != -12) {
	    NSRect frame = [subview frame];
	    frame.origin.y += deltaY;
	    [[subview animator] setFrame: frame];
	}
    }
    didMoveAllViews = !didMoveAllViews;
}



@end
