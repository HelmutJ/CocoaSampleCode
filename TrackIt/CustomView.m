/*
     File: CustomView.m
 Abstract: Custom NSView example that uses NSTrackingArea
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

#import "CustomView.h"

@implementation CustomView

// -------------------------------------------------------------------------------
//	initWithFrame:frame
// -------------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self myAddTrackingArea];
		currentColor = [NSColor lightGrayColor];
	}
	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[self myRemoveTrackingArea];
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	myAddTrackingArea
// -------------------------------------------------------------------------------
- (void)myAddTrackingArea
{
	[self myRemoveTrackingArea];
	
	NSTrackingAreaOptions trackingOptions =
		NSTrackingCursorUpdate | NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited |
		NSTrackingActiveInActiveApp;
		// note: NSTrackingActiveAlways flags turns off the cursor updating feature
		
	myTrackingArea = [[NSTrackingArea alloc]
						initWithRect: [self bounds] // in our case track the entire view
						options: trackingOptions
						owner: self
						userInfo: nil];
	[self addTrackingArea: myTrackingArea];
}

// -------------------------------------------------------------------------------
//	myRemoveTrackingArea
// -------------------------------------------------------------------------------
- (void)myRemoveTrackingArea
{
	if (myTrackingArea)
	{
		[self removeTrackingArea: myTrackingArea];
		[myTrackingArea release];
		myTrackingArea = nil;
	}
}	

// -------------------------------------------------------------------------------
//	drawRect:rect
// -------------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
	[currentColor set];
	NSRectFill(rect);	// fill the contents with the correct color
						// based on whether the cursor has entered/exited the tracking area
}

// -------------------------------------------------------------------------------
//	cursorUpdate:event
// -------------------------------------------------------------------------------
- (void)cursorUpdate:(NSEvent *)event
{
	[[NSCursor crosshairCursor] set];
}

// -------------------------------------------------------------------------------
//	mouseExited:event
// -------------------------------------------------------------------------------
- (void)mouseEntered:(NSEvent *)event
{
	currentColor = [NSColor darkGrayColor];
	[self setNeedsDisplay:YES];
}

// -------------------------------------------------------------------------------
//	mouseExited:event
// -------------------------------------------------------------------------------
- (void)mouseExited:(NSEvent *)event
{
	currentColor = [NSColor lightGrayColor];
	[self setNeedsDisplay:YES];
}

@end
