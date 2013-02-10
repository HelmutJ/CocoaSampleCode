/*
     File: MyWindowController.m
 Abstract: This sample's main NSWindowController
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

@implementation MyWindowController

// key values for dictionary in NSTrackingAreas's userInfo
enum {
	kTrackingArea1 = 1,		// left-most tracking area (horiz image flip tracking)
	kTrackingArea2			// right-most tracking area (rotation image tracking)
};
// key for dictionary in NSTrackingAreas's userInfo
NSString* kTrackerKey = @"whichTracker";

// -------------------------------------------------------------------------------
//	awakeFromNib
//
//	Once the nib is loaded, apply images to the image views and load the sounds.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// load both images and set them to their proper NSImageView
	NSImage* theImage1 = [NSImage imageNamed:@"LakeDonPedro1"];
	[myImageView1 setImage:theImage1];
	
	NSImage* theImage2 = [NSImage imageNamed:@"LakeDonPedro2"];
	[myImageView2 setImage:theImage2];
	
	// turn on tracking areas automatically at launch
	[self myAddTrackingArea];
	
	soundIn = [[NSSound soundNamed:@"inSound"] retain];
	soundOut = [[NSSound soundNamed:@"outSound"] retain];
	
	inTrackArea2 = NO;	// initialize track area 2 flag used in mouseMoved method
}

// -------------------------------------------------------------------------------
//	myRemoveTrackingArea
//
//  Called when the user clicks the "Activate Tracking Area" checkbox to turn
//	off all tracking areas.
// -------------------------------------------------------------------------------
- (void)myRemoveTrackingArea
{
	if (myTrackingArea1)
	{
		[myImageView1 removeTrackingArea: myTrackingArea1];
		[myTrackingArea1 release];
		myTrackingArea1 = nil;
	}
	
	if (myTrackingArea2)
	{
		[myImageView2 removeTrackingArea: myTrackingArea2];
		[myTrackingArea2 release];
		myTrackingArea2 = nil;
	}
}

// -------------------------------------------------------------------------------
//	myAddTrackingArea
//
//  Called when the user clicks the "Activate Tracking Area" checkbox to turn
//	on all tracking areas.
//
//	It uses a custom dictionary as the NSTrackingArea's 'userInfo'.
//	This is used later to identify which tracking area is currently being tracked in
//	our mouseMove, mousEnter, mouseExited methods. This illustrates how you can manage
//	multiple tracking areas setup outside the various NSViews.
//
// -------------------------------------------------------------------------------
- (void)myAddTrackingArea
{
	[self myRemoveTrackingArea];
	
	NSTrackingAreaOptions trackingOptions =
		NSTrackingMouseMoved | NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited |
		NSTrackingActiveInActiveApp;
		
	NSDictionary* trackerData1 = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt: kTrackingArea1], kTrackerKey, nil];
	myTrackingArea1 = [[NSTrackingArea alloc]
						initWithRect: [myImageView1 bounds] // in our case track the entire view
						options: trackingOptions
						owner: self
						userInfo: trackerData1];
	[myImageView1 addTrackingArea: myTrackingArea1];
	
	NSDictionary* trackerData2 = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt: kTrackingArea2], kTrackerKey, nil];
	
	myTrackingArea2 = [[NSTrackingArea alloc]
						initWithRect: [myImageView2 bounds]	// in our case track the entire view
						options: trackingOptions
						owner: self
						userInfo: trackerData2];
	[myImageView2 addTrackingArea: myTrackingArea2];
	
	// note: the 3rd tracking area resides in CustomView class
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
-(void)dealloc
{
	[self myRemoveTrackingArea];
	[super dealloc];
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
//	activateTrackingArea:sender
//
//	The user wants to activate or de-activate the tracking areas.
// -------------------------------------------------------------------------------
- (IBAction)activateTrackingArea:(id)sender
{
	if ([[sender selectedCell] state])
	{
		// reset the image view's rotation position:
		// we do this because 'myImageView2' may have already been rotated,
		// we need the proper initial frame/bounds when adding add back the NSTrackingArea:
		//
		[myImageView2 setBoundsRotation: 0.0];
		[myImageView2 setNeedsDisplay: YES];	// make sure the initial rotated image is immediately drawn
	
		[self myAddTrackingArea];				// add the tracking areas managed by this class
		[myCustomView myAddTrackingArea];		// add the tracking area from our CustomView
	}
	else
	{
		[self myRemoveTrackingArea];			// remove the tracking areas managed by this class
		[myCustomView myRemoveTrackingArea];	// remove the tracking area from our CustomView
	}
}

// -------------------------------------------------------------------------------
//	myHandleTrackAction1:mouseEntered
//
//	This method determines what happens when the mouse enteres 'myImageView1'.
//	It turns flips the image and redraws it.
// -------------------------------------------------------------------------------
- (void)myHandleTrackAction1:(BOOL)mouseEntered
{
	[myImageView1 rotateByAngle:180.0];
	[myImageView1 setNeedsDisplay: YES];
}

// -------------------------------------------------------------------------------
//	myHandleTrackAction2:mouseEntered
//
//	This method determines what happens when the mouse enteres 'myImageView2'.
//	This method doesn't do anything because 'mouseMoved' does all the work.
// -------------------------------------------------------------------------------
- (void)myHandleTrackAction2:(BOOL)mouseEntered
{
	// do something for this view...
}

// -------------------------------------------------------------------------------
//	mouseMoved:event
// -------------------------------------------------------------------------------
//	Because we installed NSTrackingArea with "NSTrackingMouseMoved",
//	as an option, this method will be called.  Each time it's called we rotate
//	trackin area #2's image by 5 degrees.
// -------------------------------------------------------------------------------
- (void)mouseMoved:(NSEvent*)event
{
	if (inTrackArea2)
	{
		[myImageView2 rotateByAngle:-5.0];
		[myImageView2 setNeedsDisplay: YES];
	}
}

// -------------------------------------------------------------------------------
//	handleEnteredExited:entered:withTrackingDict
// -------------------------------------------------------------------------------
//	The main routine for handling both entered and exit tracking events.
// -------------------------------------------------------------------------------
- (void)handleEnteredExited:(BOOL)entered withTrackingDict:(NSDictionary*)trackingDict
{
	if (trackingDict != NULL)
	{
		// sound out if the "Use Tracking Sound" checkbox is checked
		if ([[useSoundCheck selectedCell] state])
		{
			if (entered)
				[soundIn play];
			else
				[soundOut play];
		}

		// which tracking area is being tracked?
		int whichTrackerID = [self getTrackerIDFromDict:trackingDict];
		switch (whichTrackerID)
		{
			case kTrackingArea1:
				inTrackArea2 = NO;	// used to flag tracking area 2 because 'mouseMoved' doesn't provide userData
				[self myHandleTrackAction1:entered];
				break;
				
			case kTrackingArea2:
				inTrackArea2 = YES;
				[self myHandleTrackAction2:entered];
				break;
		}
	}
}

// -------------------------------------------------------------------------------
//	mouseEntered:event
// -------------------------------------------------------------------------------
//	Because we installed NSTrackingArea with "NSTrackingMouseEnteredAndExited"
//	as an option, this method will be called.
// -------------------------------------------------------------------------------
- (void)mouseEntered:(NSEvent*)event
{
	[self handleEnteredExited:	YES // YES = enter
								withTrackingDict:[event userData]];	// determine which tracking area
}

// -------------------------------------------------------------------------------
//	mouseExited:event
// -------------------------------------------------------------------------------
//	Because we installed NSTrackingArea with "NSTrackingMouseEnteredAndExited",
//	as an option, this method will be called.
// -------------------------------------------------------------------------------
- (void)mouseExited:(NSEvent*)event
{
	[self handleEnteredExited:	NO // NO = exit
								withTrackingDict:[event userData]]; // determine which tracking area
}

@end
