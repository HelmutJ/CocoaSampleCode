/*
     File: TrackView.m 
 Abstract: The NSView that handles the label color tracking. 
  Version: 1.2 
  
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

#import "TrackView.h"

@implementation TrackView

// key for dictionary in NSTrackingAreas's userInfo
NSString* kTrackerKey = @"whichTracker";

// key values for dictionary in NSTrackingAreas's userInfo,
// which tracking area is being tracked
enum trackingAreaIDs
{
	kTrackingArea1 = 1,
	kTrackingArea2,
	kTrackingArea3,
	kTrackingArea4,
	kTrackingArea5,
	kTrackingArea6,
	kTrackingArea7,
	kTrackingArea8
};

// -------------------------------------------------------------------------------
//	awakeFromNib:
//
//	Setup the tracking areas for each colored dot.  Each colored dot is a separate
//	NSView for easy management/tracking purposes.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	[self setupTrackingAreas];
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[trackingAreas release];
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	setupTrackingAreas:
// -------------------------------------------------------------------------------
- (void)setupTrackingAreas
{
	if (trackingAreas == nil)
	{
		// load all the suviews and add tracking areas to them
		NSArray *viewsToFrame = [self subviews];
		
		trackingAreas = [NSMutableArray array];	// keep all tracking areas in an array
		
		// determine the tracking options
		NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag |
												NSTrackingMouseEnteredAndExited |
												NSTrackingActiveInActiveApp |
												NSTrackingActiveAlways;
		
		NSInteger numViews = [[self subviews] count];
		NSInteger index;
		for (index = 1; index < numViews; index++)
		{
            // make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine which tracking area is focused on
            //
            NSDictionary *trackerData = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:index], kTrackerKey, nil];

            NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                                initWithRect:[[viewsToFrame objectAtIndex:index-1] frame]
                                                // note: since we are working with this view's coordinate system,
                                                // we need to  use the 'frame' for each subview instead of its bounds
                                                options:trackingOptions
                                                owner:self
                                                userInfo:trackerData];
                                                
            [trackingAreas addObject:trackingArea];	// keep track of this tracking area for later disposal
            [self addTrackingArea:trackingArea];	// add the tracking area to the view/window
            [trackingArea release];
		}
	}
}

// -------------------------------------------------------------------------------
//	drawRect:rect
//
//	Returns the NSColor corresponding to the sub-view index.
// -------------------------------------------------------------------------------
- (NSColor *)colorForViewIndex:(NSInteger)viewIndex
{
	NSColor *returnColor = nil;
	switch (viewIndex)
	{
		case kTrackingArea1:	// grey
			returnColor = [NSColor grayColor];
			break;
			
		case kTrackingArea2:	// purple
			returnColor = [NSColor purpleColor];
			break;
			
		case kTrackingArea3:	// blue
			returnColor = [NSColor blueColor];
			break;
			
		case kTrackingArea4:	// green
			returnColor = [NSColor greenColor];
			break;
			
		case kTrackingArea5:	// yellow
			returnColor = [NSColor yellowColor];
			break;
			
		case kTrackingArea6:	// orange
			returnColor = [NSColor orangeColor];
			break;
			
		case kTrackingArea7:	// red
			returnColor = [NSColor redColor];
			break;
			
		case kTrackingArea8:	// none (black)
			returnColor = [NSColor blackColor];
			break;
	}
	return returnColor;
}

// -------------------------------------------------------------------------------
//	drawRect:rect
//
//	Examine all the sub-view colored dots and color them with their appropriate colors.
// -------------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
	NSArray *viewsToFrame = [self subviews];
	
	NSInteger viewCount = [viewsToFrame count] - 1;
	NSInteger index;
	for (index = 1; index <= viewCount; index++)
	{
		if (whichTrackedID == index)
		{
			// obtain the bezier path (a filled circle) to draw in
			NSBezierPath *theFill = [NSBezierPath bezierPathWithOvalInRect:[[viewsToFrame objectAtIndex:whichTrackedID - 1] frame]];
			
			NSColor *theColor = [self colorForViewIndex:whichTrackedID];
				
			if (trackEntered)
			{
				// if we are tracking inside any label, we want to brighten the color to show selection feedback
				
				// take the current label color and brighten it
				CGFloat hue, saturation, brightness, alpha;
				[[theColor
					colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue
					saturation:&saturation brightness:&brightness alpha:&alpha];
				
				theColor = [NSColor colorWithDeviceHue:hue saturation:saturation-.60 brightness:brightness + 40.0 alpha:alpha];
			}

			// finally, render the color change (light or dark)
			[self lockFocus];
			[theColor set];
			[theFill fill];
			[self unlockFocus];
		}
		else
		{
			// obtain the bezier path (a filled circle) to draw in
			NSBezierPath *theFill = [NSBezierPath bezierPathWithOvalInRect:[[viewsToFrame objectAtIndex:index-1] frame]];
			
			// fill the area with the appropriate color
			[[self colorForViewIndex:index] set];
			[theFill fill];
		}
	}
}

// -------------------------------------------------------------------------------
//	getTrackerIDFromDict:dict
//
//	Used in obtaining dictionary entry info from the 'userData', used by each
//	mouse event method.  It helps determine which tracking area is being tracked.
// -------------------------------------------------------------------------------
- (int)getTrackerIDFromDict:(NSDictionary *)dict
{
	id whichTracker = [dict objectForKey: kTrackerKey];
	return [whichTracker intValue];
}

// -------------------------------------------------------------------------------
//	mouseEntered:event
//
//	Because we installed NSTrackingArea to our NSImageView, this method will be called.
// -------------------------------------------------------------------------------
- (void)mouseEntered:(NSEvent *)event
{
	// which tracking area is being tracked?
	whichTrackedID = [self getTrackerIDFromDict:[event userData]];
	trackEntered = YES;

	[self setNeedsDisplay:YES];	// force update the currently tracked label back to its original color
}

// -------------------------------------------------------------------------------
//	mouseExited:event
//
//	Because we installed NSTrackingArea to our NSImageView, this method will be called.
// -------------------------------------------------------------------------------
- (void)mouseExited:(NSEvent *)event
{
	// which tracking area is being tracked?
	whichTrackedID = [self getTrackerIDFromDict:[event userData]];
	trackEntered = NO;

	[self setNeedsDisplay:YES];	// force update the currently tracked label to a lighter color
}

// -------------------------------------------------------------------------------
//	mouseDown:event
// -------------------------------------------------------------------------------
- (void)mouseUp:(NSEvent*)event
{
	NSPoint mousePoint = [self convertPoint: [event locationInWindow] fromView:nil];
	
	// figure out which label color was clicked on at mouseUp time
	NSArray *labelViews = [self subviews];
	NSInteger numViews = [labelViews count];
	NSInteger index;
	for (index = 1; index < numViews; index++)
	{
		NSRect labelRect = [[labelViews objectAtIndex:index-1] frame];
		if (NSPointInRect(mousePoint, labelRect))
		{
			// here you would respond to the particular label selection...
			NSLog(@"label %d was selected", (int)index);
		}
	}
	
	// on mouse up, we want to dismiss the menu being tracked
	NSMenu *menu = [[self enclosingMenuItem] menu];
	[menu cancelTracking];
	
	// we are no longer tracking, reset the tracked label color (if any)
	whichTrackedID = NSNotFound;
	[self setNeedsDisplay:YES];
}

@end
