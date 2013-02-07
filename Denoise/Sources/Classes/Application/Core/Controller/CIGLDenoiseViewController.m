//---------------------------------------------------------------------------------
//
//	File: CIGLDenoiseViewController.m
//
// Abstract: Mediator with the OpenGL view.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2009, 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#import "CIGLDenoiseViewController.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation CIGLDenoiseViewController

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - App Startup

//---------------------------------------------------------------------------------

- (void) awakeFromNib
{
	// Set the default path
	viewSnapshotDir = [[NSString alloc] initWithFormat:@"%@/Pictures",NSHomeDirectory()];
	
	// Get an instance of the Open panel
	viewSnapshotPanel = [[NSOpenPanel openPanel] retain];
	
	// Set open panel properties
    [viewSnapshotPanel setMessage:@"Choose destination folder for captured images"];
	[viewSnapshotPanel setCanChooseDirectories:YES];
	[viewSnapshotPanel setResolvesAliases:YES];
	[viewSnapshotPanel setCanChooseFiles:NO];
    [viewSnapshotPanel setAllowsMultipleSelection:NO];
	[viewSnapshotPanel setCanCreateDirectories:YES];
	[viewSnapshotPanel setPrompt:@"Select"];
	[viewSnapshotPanel setDirectoryURL:[NSURL fileURLWithPath:viewSnapshotDir 
												  isDirectory:YES]];
    
	// Post a notification for app termination
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(glViewControllerWillTerminate:)
												 name:@"NSApplicationWillTerminateNotification"
											   object:NSApp];
    
	// CI noise reduction filter sliders are invisible on startup
	filterControlsVisible = NO;
} // awakeFromNib

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Releasing Objects

//---------------------------------------------------------------------------------

- (void) cleanUpOpenGLViewController
{
	if( viewSnapshotDir )
	{
		[viewSnapshotDir release];
		
		viewSnapshotDir = nil;
	} // if
	
	if( viewSnapshotPanel )
	{
		[viewSnapshotPanel release];
		
		viewSnapshotPanel = nil;
	} // if
} // cleanUpOpenGLViewController

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Action - View Capture

//---------------------------------------------------------------------------------

- (IBAction) viewSnapshotLocation:(id)sender
{
	void (^viewSnapshotPanelHandler)(NSInteger) = ^( NSInteger resultCode )
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
		if( resultCode ) 
		{
			NSURL *url = [viewSnapshotPanel URL];
			
            if( url )
            {
                // Get the directory from the open panel
                NSString *viewSnapshotCurrentDir = [url path];
                
                if( viewSnapshotCurrentDir )
                {
                    [viewSnapshotCurrentDir retain];
                    [viewSnapshotDir release];
                    
                    viewSnapshotDir = viewSnapshotCurrentDir;
                } // if
			} // if
		} // if
        
		[pool drain];
	};
    
	[viewSnapshotPanel beginSheetModalForWindow:mainWindow
                              completionHandler:viewSnapshotPanelHandler];
} // viewSnapshotLocation

//---------------------------------------------------------------------------------
//
// Image name with include a time stamp and formatted according to
//
//		<directory>/Image-<date>-<hour><minute><second>.jpg
//
//---------------------------------------------------------------------------------

- (IBAction) viewSnapshot:(id)sender
{
	// Construct a pathname for the saved image
	NSCharacterSet *separator   = [NSCharacterSet characterSetWithCharactersInString:@" :"];
	NSDate         *today       = [NSDate date];
	NSString       *todayString = [NSString stringWithFormat:@"%@",today];
	NSArray        *todayArray  = [todayString componentsSeparatedByCharactersInSet:separator];
    
	NSString *viewSnapshotPath = [NSString stringWithFormat:@"%@/ViewSnapshot-%@-%@%@%@.jpg",
								  viewSnapshotDir,
								  [todayArray objectAtIndex:0],
								  [todayArray objectAtIndex:1],
								  [todayArray objectAtIndex:2],
								  [todayArray objectAtIndex:3]];
	
	// Read pixels from the frame buffer and save the image as JPEG at the path
	[denoiseView imageSaveAs:(CFStringRef)viewSnapshotPath 
                      UTType:kUTTypeJPEG];
} // viewSnapshot

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Action - Selecting Filters

//---------------------------------------------------------------------------------

- (void) filterControlIsVisible
{
	if( !filterControlsVisible )
	{
		[filterControlsBox setHidden:NO];
		
		filterControlsVisible = YES;
	} // if
} // filterControlIsVisible

//---------------------------------------------------------------------------------

- (void) filterControlIsHidden
{
	if( filterControlsVisible )
	{
		[filterControlsBox setHidden:YES];
		
		filterControlsVisible = NO;
	} // if
} // filterControlIsHidden

//---------------------------------------------------------------------------------

- (IBAction) filterSelectionChanged:(id)sender
{
	// sender is the NSPopUpButton containing filter choices.
	// We ask the sender which popup menu item is selected and
	// increment to compensate for counting from zero.
	
	NSInteger filterSelected = [sender indexOfSelectedItem] + 1;
	
	// Based on selected shader effect, we set the target to the
	// selected shader.
	
	switch( filterSelected ) 
	{
		case 1:
			[self filterControlIsHidden];
			break;
		default:
			[self filterControlIsVisible];
			break;
	} // switch
    
	[denoiseView setFilter:filterSelected];
} // filterChanged

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Action - Sliders Changed

//---------------------------------------------------------------------------------

- (IBAction) noiseLevelChanged:(id)sender
{
	CGFloat noiseLevel = [noiseLevelSlider floatValue];
	
	[denoiseView setNoiseLevel:noiseLevel];
} // noiseLevelChanged

//---------------------------------------------------------------------------------

- (IBAction) inputSharpnessChanged:(id)sender
{
	CGFloat sharpness = [sharpnessSlider floatValue];
	
	[denoiseView setSharpness:sharpness];
} // inputSharpnessChanged

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Action - Image View

//---------------------------------------------------------------------------------

- (IBAction) imageViewChanged:(id)sender
{
	[denoiseView updateFilter:[imageView image]];
} // imageViewChanged

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Action - Screen Mode

//--------------------------------------------------------------------------------

- (IBAction) screenModeChanged:(id)sender
{
	[denoiseView setFullScreenMode];
} // screenModeChanged

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Notification

//---------------------------------------------------------------------------------
//
// It's important to clean up our rendering objects before we terminate -- 
// Cocoa will not specifically release everything on application termination, 
// so we explicitly call our clean up routine ourselves.
//
//---------------------------------------------------------------------------------

- (void) glViewControllerWillTerminate:(NSNotification *)notification
{
	[self cleanUpOpenGLViewController];
} // glViewControllerWillTerminate

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

