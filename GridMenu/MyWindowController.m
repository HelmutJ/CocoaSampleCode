/*
     File: MyWindowController.m 
 Abstract: The main NSWindowController that manages the main window of this application.
  
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
#import "IconViewController.h"
#import "TrackingView.h"
#import "Choices.h"

@implementation MyWindowController


#pragma mark - Actions

// -------------------------------------------------------------------------------
//	commonHandleMenuChoice:menuChoice
// -------------------------------------------------------------------------------
- (void)commonHandleMenuChoice:(NSInteger)menuChoice
{
	NSString *msgStr = @"You have chosen the";
	NSString *buttonTitle = nil;
	
	switch (menuChoice)
	{
		case kColorWheel:
			buttonTitle = @"Color";
			break;
		case kComputer:
			buttonTitle = @"Computer";
			break;
		case kDotMac:
			buttonTitle = @"DotMac";
			break;
		case kSmart:
			buttonTitle = @"Smart";
			break;
		case kUser:
			buttonTitle = @"User";
			break;
		case kBurnable:
			buttonTitle = @"Burnable";
			break;
		case kNetwork:
			buttonTitle = @"Network";
			break;
		case kFont:
			buttonTitle = @"Font";
			break;
        default:
			buttonTitle = @"<?>";
            break;
	}
	
	NSLog(@"%@", [NSString stringWithFormat:@"%@ '%@' button.", msgStr, buttonTitle]);
}

// -------------------------------------------------------------------------------
//	handleCollectionItem:note
//
//	Notification with name "HandleCollectionItem", was posted by IconViewController
// -------------------------------------------------------------------------------
- (void)handleCollectionItem:(NSNotification *)note
{
	[[actionButton menu] cancelTracking];
	
	[self commonHandleMenuChoice: [[note object] intValue]];
}

// -------------------------------------------------------------------------------
//	matrixMenuAction:sender
// -------------------------------------------------------------------------------
- (IBAction)matrixMenuAction:(id)sender
{
	// dismiss the menu
	NSMenu *menu = [[sender enclosingMenuItem] menu];
	[menu cancelTracking];
	
	[self commonHandleMenuChoice: [[sender selectedCell] tag]];
}


#pragma mark - Life Cycle

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	iconViewController = [[IconViewController alloc] initWithNibName:@"IconView" bundle:nil];
	
	// register for the notification to handle the selection from the IconViewController
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleCollectionItem:)
												 name:HandleCollectionItem
											   object:nil];
	
	// embed the NSCollectionView to its popup menu item
    NSMenuItem *custMenuItem = [[actionButton menu] itemAtIndex:0];
	[custMenuItem setView:[iconViewController view]];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [iconViewController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:HandleCollectionItem object:nil];
    
	[super dealloc];
}

@end
