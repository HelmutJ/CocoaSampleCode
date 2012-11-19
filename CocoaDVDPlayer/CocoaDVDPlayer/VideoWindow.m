/*
     File: VideoWindow.m
 Abstract: Implementation file for the video window class in CocoaDVDPlayer, 
 an Apple Developer sample project.
  Version: 1.3
 
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

#import <DVDPlayback/DVDPlayback.h>
#import "VideoWindow.h"
#import "Controller.h"


/*
********************************************************************************
**
**		Class: VideoWindow
**
********************************************************************************
*/

/* These methods are used inside this file only. Instead of declaring them in
VideoWindow.h, we declare them here in a category that extends the class. */

@interface VideoWindow (InternalMethods)

- (void) setVideoBounds; 
- (void) setVideoDisplay;
- (float) titleAspectRatio;
- (NSSize) getVideoSize;

@end


@implementation VideoWindow

- (void) awakeFromNib 
{
	/* register for notifications */

	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(windowDidMove:) 
		name:NSWindowDidMoveNotification 
		object:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(frameDidChange:) 
		name:NSViewFrameDidChangeNotification 
		object:NULL];

	/* we want to respond to mouse movements -- see sendEvent */
	[self setAcceptsMouseMovedEvents:YES];

	/* display a black background before media starts playing */
	[self setBackgroundColor: [NSColor blackColor]];
}


- (void) keyDown:(NSEvent *)theEvent 
{
	/* pass all key-down events in this window to our delegate, the Controller
	object */
	BOOL eventHandled = [(Controller *) [self delegate] onKeyDown:theEvent];

	if (eventHandled == NO) {
		[super keyDown:theEvent];
	} else {
		[self flushBufferedKeyEvents];
	}
}


/* This method overrides NSWindow to handle button mouse-overs and mouse-clicks
in the window. */

- (void) sendEvent:(NSEvent *)theEvent 
{
	/* index of selected button in DVD menu */
	SInt32 index = kDVDButtonIndexNone;

	/* get mouse location */
	NSPoint location = [theEvent locationInWindow];
	location.y = [self frame].size.height - location.y;

	switch ([theEvent type])
	{
		case NSMouseMoved:
			DVDDoMenuCGMouseOver ((CGPoint *)&location, &index);
			break;
		case NSLeftMouseDown:
			DVDDoMenuCGClick ((CGPoint *)&location, &index);
			break;
		default:
			break;
	}

	/* sync the cursor */
	NSCursor *cursor;
	if (index != kDVDButtonIndexNone) {
		cursor = [NSCursor pointingHandCursor];
	}
	else {
		cursor = [NSCursor arrowCursor];
	}
	[cursor set];

	/* pass the event back to NSWindow for additional handling */
	[super sendEvent:theEvent];
}


/* This method returns a number that represents the aspect ratio of the
current title. */

- (float) titleAspectRatio
{
	const float kStandardRatio = 4.0 / 3.0;
	const float kWideRatio = 16.0 / 9.0;
	float ratio = kStandardRatio;

	DVDAspectRatio format = kDVDAspectRatioUninitialized;
	DVDGetAspectRatio (&format);

	switch (format) {
		case kDVDAspectRatio4x3:
		case kDVDAspectRatio4x3PanAndScan:
		case kDVDAspectRatioUninitialized:
			ratio = kStandardRatio;
			break;
		case kDVDAspectRatio16x9:
		case kDVDAspectRatioLetterBox:
			ratio = kWideRatio;
			break;
	}

	return ratio;
}


/* This method finds the native video size of the current title and adjusts the
width so the aspect ratio is correct (this is arbitrary -- we could also adjust
the height.) This information is needed when the user chooses either the small
or the normal window size from the Video menu. */

- (NSSize) getVideoSize
{
	/* get the native height and width of the media */
	UInt16 width = 720, height = 480;
	DVDGetNativeVideoSize (&width, &height);

	NSSize size;
	size.height = height;
	/* adjust the width using the current aspect ratio */
	size.width = size.height * [self titleAspectRatio];

	return size;
}


/* This method sets the dimensions of the window's content area and positions
the window on the screen. The setWindowSize message is sent (1) when the user
chooses one of the 3 standard sizes in the Video menu, (2) when the user resizes
the window manually, and (3) when the aspect ratio of the playback title
changes. */

- (void) setWindowSize: (PlaybackVideoSize)inSize
{
	/* get the aspect ratio of the current title */
	float titleRatio = [self titleAspectRatio];

	/* get the bounding rectangle of the display for this window, excluding
	menu bar and dock */
	NSRect screenBounds = [[self screen] visibleFrame];

	/* create and initialize a rectangle for the new content area */
	NSRect frame = [self frame];
	NSPoint topLeft = { frame.origin.x, frame.origin.y + frame.size.height };
	NSSize bounds = [[self contentView] bounds].size;

	/* now compute the new bounds */
	switch (inSize) 
	{
		case kVideoSizeCurrent: {
			/* apply the aspect ratio to the new size */
			bounds.width = bounds.height * titleRatio;
			if (bounds.width > screenBounds.size.width) {
				bounds.width = screenBounds.size.width;
				bounds.height = screenBounds.size.width * (1.0 / titleRatio);
			}
			break;
		}

		case kVideoSizeNormal: {
			bounds = [self getVideoSize];
			break;
		}

		case kVideoSizeSmall: {
			bounds = [self getVideoSize];
			bounds.width /= 2;
			bounds.height /= 2;
			break;
		}

		case kVideoSizeMax: {

			/* find the largest frame that fits inside the display bounds */
			float screenRatio = screenBounds.size.width / screenBounds.size.height;
			if (screenRatio >= titleRatio) {
				bounds.height = screenBounds.size.height;
				bounds.width = screenBounds.size.height * titleRatio;
			}
			else {
				bounds.width = screenBounds.size.width;
				bounds.height = screenBounds.size.width * (1.0 / titleRatio);
			}

			/* move window to top left corner of screen */
			topLeft.x = screenBounds.origin.x;
			topLeft.y = screenBounds.size.height + screenBounds.origin.y;
			break;
		}
	}
	
	/* update the window location and size */
	[self disableFlushWindow];
	[self setContentSize:bounds];
	[self setFrameTopLeftPoint:topLeft];
	[self enableFlushWindow];
}


/* This method sets the video window state in DVD Playback Services. The
setupVideoWindow message is sent by the Controller object during playback
session initialization. */

- (void) setupVideoWindow 
{
	NSLog(@"Step 2: Set Video Window");

	OSStatus result = DVDSetVideoWindowID ((UInt32)[self windowNumber]);
	if (result != noErr) {
		NSLog(@"DVDSetVideoWindowID returned %ld", result);
	}
	
	[self setVideoDisplay];

	/* set initial bounds of video area in window */
	[self setVideoBounds];
}


/* This method finds the display ID for our window and notifies DVD Playback
Services. The setVideoDisplay message is sent (1) when CocoaDVDPlayer finishes
launching and the Controller object sends us the setupVideoWindow message, and
(2) when the user moves the window to a new location. */

- (void) setVideoDisplay 
{
	static CGDirectDisplayID curDisplay = 0;

	/* get the ID of the display that contains the largest part of the window */
	CGDirectDisplayID newDisplay = (CGDirectDisplayID) 
		[[[[self screen] deviceDescription] valueForKey:@"NSScreenNumber"] intValue];

	/* if the display has changed, set the new display */
	if (newDisplay != curDisplay) {
		NSLog(@"Step 3: Set Video Display");
		Boolean isSupported = FALSE;
		OSStatus result = DVDSwitchToDisplay (newDisplay, &isSupported);
		if (result != noErr) {
			NSLog(@"DVDSwitchToDisplay returned %ld", result);
		}
		if (isSupported) { 
			curDisplay = newDisplay;
		}
		else {
			NSLog(@"video display %u not supported", newDisplay);
		}
	}
}


/* This method finds our video area (that is, our content view) and passes it to
DVD Playback Services. The setVideoBounds message is sent (1) when
CocoaDVDPlayer finishes launching and the Controller object sends us the
setupVideoWindow message, (2) when the user resizes our window frame, and (3)
when the aspect ratio of the title changes. */

- (void) setVideoBounds 
{
	NSLog(@"Step 4: Set Video Bounds");

	NSRect content = [[self contentView] bounds];
	NSRect frame = [self frame];

	CGRect bounds = CGRectMake (0, frame.size.height - content.size.height, content.size.width, content.size.height);

	OSStatus result = DVDSetVideoCGBounds ((CGRect *)&bounds);
	if (result != noErr) {
		NSLog(@"DVDSetVideoCGBounds returned %ld", result);
	}
}


#pragma mark NSWindow notifications


- (void) frameDidChange:(NSNotification *)notification 
{
	if ([notification object] == [self contentView]) {
		[self setWindowSize:kVideoSizeCurrent];
		[self setVideoBounds];
	}
}

- (void) windowDidMove:(NSNotification *)notification 
{
	if ([notification object] == self) {
		[self setVideoDisplay];
	}
}

@end
