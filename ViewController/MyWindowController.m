/*
     File: MyWindowController.m 
 Abstract: main NSWindowController 
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
#import "CustomImageViewController.h"
#import "CustomTableViewController.h"
#import "CustomVideoViewController.h"

@implementation MyWindowController

enum	// popup tag choices
{
	kImageView = 0,
	kTableView,
	kVideoView,
	kCameraView
};

NSString *const kViewTitle		= @"CustomImageView";
NSString *const kTableTitle		= @"CustomTableView";
NSString *const kVideoTitle		= @"CustomVideoView";
NSString *const kCameraTitle	= @"CustomCameraView";

// -------------------------------------------------------------------------------
//	initWithPath:newPath
// -------------------------------------------------------------------------------
- initWithPath:(NSString *)newPath
{
   return [super initWithWindowNibName:@"TestWindow"];
}

// -------------------------------------------------------------------------------
//	changeViewController:whichViewTag
//
//	Change the current NSViewController to a new one based on a tag obtained from
//	the NSPopupButton control.
// -------------------------------------------------------------------------------
- (void)changeViewController:(NSInteger)whichViewTag
{
	// we are about to change the current view controller,
	// this prepares our title's value binding to change with it
	[self willChangeValueForKey:@"viewController"];
	
	if ([myCurrentViewController view] != nil)
		[[myCurrentViewController view] removeFromSuperview];	// remove the current view

	if (myCurrentViewController != nil)
		[myCurrentViewController release];		// remove the current view controller
	
	switch (whichViewTag)
	{
		case 0:	// swap in the "CustomImageViewController - NSImageView"
		{
			CustomImageViewController* imageViewController =
				[[CustomImageViewController alloc] initWithNibName:kViewTitle bundle:nil];
			if (imageViewController != nil)
			{
				
				myCurrentViewController = imageViewController;	// keep track of the current view controller
				[myCurrentViewController setTitle:kViewTitle];
			}
			break;
		}
		
		case 1:	// swap in the "CustomTableViewController - NSTableView"
		{
			CustomTableViewController* tableViewController =
				[[CustomTableViewController alloc] initWithNibName:kTableTitle bundle:nil];
			if (tableViewController != nil)
			{
				myCurrentViewController = tableViewController;	// keep track of the current view controller
				[myCurrentViewController setTitle:kTableTitle];
			}
			break;
		}
		
		case 2:	// swap in the "CustomVideoViewController - QTMovieView"
		{
			CustomVideoViewController* videoViewController =
				[[CustomVideoViewController alloc] initWithNibName:kVideoTitle bundle:nil];
			if (videoViewController != nil)
			{
				myCurrentViewController = videoViewController;	// keep track of the current view controller
				[myCurrentViewController setTitle:kVideoTitle];
			}
			break;
		}
		
		case 3:	// swap in the "NSViewController - Quartz Composer iSight Camera"
		{
			NSViewController* cameraViewController =
				[[NSViewController alloc] initWithNibName:kCameraTitle bundle:nil];
			if (cameraViewController != nil)
			{
				myCurrentViewController = cameraViewController;	// keep track of the current view controller
				[myCurrentViewController setTitle:kCameraTitle];
			}
			break;
		}
	}
	
	// embed the current view to our host view
	[myTargetView addSubview: [myCurrentViewController view]];
	
	// make sure we automatically resize the controller's view to the current window size
	[[myCurrentViewController view] setFrame: [myTargetView bounds]];
	
	// set the view controller's represented object to the number of subviews in that controller
	// (our NSTextField's value binding will reflect this value)
	[myCurrentViewController setRepresentedObject: [NSNumber numberWithUnsignedInt: [[[myCurrentViewController view] subviews] count]]];
	
	[self didChangeValueForKey:@"viewController"];	// this will trigger the NSTextField's value binding to change
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	[self changeViewController: kImageView];
}

// -------------------------------------------------------------------------------
//	viewChoicePopupAction
// -------------------------------------------------------------------------------
- (IBAction)viewChoicePopupAction:(id)sender
{
	[self changeViewController: [[sender selectedCell] tag]];
}

// -------------------------------------------------------------------------------
//	viewController
// -------------------------------------------------------------------------------
- (NSViewController*)viewController
{
	return myCurrentViewController;
}

@end
