/*
 
     File: ScreenSnapshotAppDelegate.m 
 Abstract:  
 A UIApplication delegate class. Uses Quartz Display Services to obtain a list
 of all connected displays. Installs a callback function that's invoked whenever
 the configuration of a local display is changed. When the user selects a display
 item from the 'Capture' menu, a screen snapshot image is obtained and displayed
 in a new document window.
  
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 
 */

#import "ScreenSnapshotAppDelegate.h"

// DisplayRegisterReconfigurationCallback is a client-supplied callback function that’s invoked 
// whenever the configuration of a local display is changed.  Applications who want to register 
// for notifications of display changes would use CGDisplayRegisterReconfigurationCallback
static void DisplayRegisterReconfigurationCallback (CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo) 
{
    ScreenSnapshotAppDelegate * snapshotDelegateObject = (ScreenSnapshotAppDelegate*)userInfo;
    static BOOL DisplayConfigurationChanged = NO;
    
    // Before display reconfiguration, this callback fires to inform
    // applications of a pending configuration change. The callback runs
    // once for each on-line display.  The flags passed in are set to
    // kCGDisplayBeginConfigurationFlag.  This callback does not
    // carry other per-display information, as details of how a
    // reconfiguration affects a particular device rely on device-specific
    // behaviors which may not be exposed by a device driver.
    //
    // After display reconfiguration, at the time the callback function
    // is invoked, all display state reported by CoreGraphics, QuickDraw,
    // and the Carbon Display Manager API will be up to date.  This callback
    // runs after the Carbon Display Manager notification callbacks.
    // The callback runs once for each added, removed, and currently
    // on-line display.  Note that in the case of removed displays, calls into
    // the CoreGraphics API with the removed display ID will fail.
    
    // Because the callback is called for each display I use DisplayConfigurationChanged to
    // make sure we only disable the menu to change displays once and then refresh it only once.
    if(flags == kCGDisplayBeginConfigurationFlag) 
    {
        if(DisplayConfigurationChanged == NO) 
        {
            [snapshotDelegateObject disableUI];
            DisplayConfigurationChanged = YES;
        }
    }
    else if(DisplayConfigurationChanged == YES) 
    {
        [snapshotDelegateObject enableUI];
        [snapshotDelegateObject interrogateHardware];
        DisplayConfigurationChanged = NO;
    }
}


@implementation ScreenSnapshotAppDelegate


#pragma mark NSApplicationDelegate

// don't want an untitled document opened upon program launch
// so return NO here
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender 
{ 
	return NO; 
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* Save the shared NSDocumentController for use later. */
    documentController = [[NSDocumentController sharedDocumentController] retain];
        
    displays = nil;
    
    /* Populate the Capture menu with a list of displays by iterating over all of the displays. */
    [self interrogateHardware];
    
    // Applications who want to register for notifications of display changes would use 
    // CGDisplayRegisterReconfigurationCallback
    //
    // Display changes are reported via a callback mechanism.
    //
    // Callbacks are invoked when the app is listening for events,
    // on the event processing thread, or from within the display
    // reconfiguration function when in the program that is driving the
    // reconfiguration.
    DisplayRegistrationCallBackSuccessful = NO; // Hasn't been tried yet.
	CGError err = CGDisplayRegisterReconfigurationCallback(DisplayRegisterReconfigurationCallback,self);
	if(err == kCGErrorSuccess)
    {
		DisplayRegistrationCallBackSuccessful = YES;
    }
 }

-(void) dealloc
{
	// CGDisplayRemoveReconfigurationCallback Removes the registration of a callback function that’s invoked 
	// whenever a local display is reconfigured.  We only remove the registration if it was successful in the first place.
	if(CGDisplayRemoveReconfigurationCallback != NULL && DisplayRegistrationCallBackSuccessful == YES)
    {
		CGDisplayRemoveReconfigurationCallback(DisplayRegisterReconfigurationCallback, self);
    }
    
    [captureMenuItem release];
    
    if(displays != nil)
    {
		free(displays);
    }
    
	[super dealloc];
}


#pragma mark Display routines

/* 
 A display item was selected from the Capture menu. This takes a
 a snapshot image of the screen and creates a new document window
 with the image.
*/
- (IBAction)selectDisplayItem:(id)sender
{
    NSMenuItem *menuItem = (NSMenuItem *)sender;

    /* Get the index for the chosen display from the CGDirectDisplayID array. */
    NSInteger displaysIndex = [menuItem tag];
    /* Make a snapshot image of the current display. */
    CGImageRef image = CGDisplayCreateImage(displays[displaysIndex]);
    
    NSError *error = nil;
    /* Create a new document. */
    ImageDocument *newDocument = [documentController openUntitledDocumentAndDisplay:YES error:&error];
    if (newDocument) 
    {
        /* Save the CGImageRef with the document. */
        [newDocument setCGImage:image];
    }
    else
    {
        /* Display the error. */
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    
    if (image) 
    {
        CFRelease(image);
    }
}

/* Get the localized name of a display, given the display ID. */
-(NSString *)displayNameFromDisplayID:(CGDirectDisplayID)displayID
{
    NSString *displayProductName = nil;
    
    /* Get a CFDictionary with a key for the preferred name of the display. */
    NSDictionary *displayInfo = (NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
    /* Retrieve the display product name. */
    NSDictionary *localizedNames = [displayInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    /* Use the first name. */
    if ([localizedNames count] > 0) 
    {
        displayProductName = [[localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]] retain];
    }
    
    [displayInfo release];
    return [displayProductName autorelease];
}

/* Populate the Capture menu with a list of displays by iterating over all of the displays. */
-(void)interrogateHardware
{
	CGError				err = CGDisplayNoErr;
	CGDisplayCount		dspCount = 0;
    
    /* How many active displays do we have? */
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
	/* If we are getting an error here then their won't be much to display. */
    if(err != CGDisplayNoErr)
    {
        return;
    }
	
	/* Maybe this isn't the first time though this function. */
	if(displays != nil)
    {
		free(displays);
    }
    
	/* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
	// Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
	
	/* More error-checking here. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
    }

    /* Create the 'Capture Screen' menu. */
    NSMenu *captureMenu = [[NSMenu alloc] initWithTitle:@"Capture Screen"];

    int i;
    /* Now we iterate through them. */
    for(i = 0; i < dspCount; i++)
    {
        /* Get display name for the selected display. */
        NSString* name = [self displayNameFromDisplayID:displays[i]];

        /* Create new menu item for the display. */
        NSMenuItem *displayMenuItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectDisplayItem:) keyEquivalent:@""];
        /* Save display index with the menu item. That way, when it is selected we can easily retrieve
           the display ID from the displays array. */
        [displayMenuItem setTag:i];
        /* Add the display menu item to the menu. */
        [captureMenu addItem:displayMenuItem];
        
        [displayMenuItem release];
    }
    
    /* Set the display menu items as a submenu of the Capture menu. */
    [captureMenuItem setSubmenu:captureMenu];
    [captureMenu release];
}

#pragma mark Menus

/* Disable the Capture Screen menu. */
-(void) disableUI
{
    [captureMenuItem setEnabled:NO];
}

/* Enable the Capture Screen menu. */
-(void) enableUI
{
    [captureMenuItem setEnabled:YES];
}

@end
