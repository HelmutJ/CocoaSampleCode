/*
     File: Controller.m 
 Abstract: Main controller object for the SBSystemPrefs sample. 
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

#import "Controller.h"
#import "System Preferences.h"


@interface Controller (delegate) <SBApplicationDelegate>
@end

@implementation Controller


@synthesize prefPanes, prefPanesController, selectionWindow;


	/* quit-on-close housekeeping method - the application will quit
	 when the main window is closed.  */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

    /* Part of the SBApplicationDelegate protocol.  Called when an error occurs in
     Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    [[NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}


	/* methods for managing the select-and-display gui interaction. */

	/* populates the list in the select and display window using names
	 retrieved from the System Preferences application and waits
	 for the user to make a selection */
- (IBAction)selectPaneForDisplay:(id)sender {
	
		/* allocate a System Preferences Scripting Bridge object */
	SystemPreferencesApplication *systemPreferences =
		[SBApplication
			applicationWithBundleIdentifier:@"com.apple.systempreferences"];
    
        /* set ourself as the delegate to receive any errors */
    systemPreferences.delegate = self;
	
        /* add all of the preference panes to the list */
    NSArray *listOfPreferencePanes = [systemPreferences panes];
	
		/* set the array.  The array controller takes care of the display */
	self.prefPanes = [NSMutableArray arrayWithArray:listOfPreferencePanes];

		/* display the window */
	[self.selectionWindow makeKeyAndOrderFront:self];
	
		/* interact until a selection is made or the user cancels. */
	NSInteger modalResult = [NSApp runModalForWindow:self.selectionWindow];
	
		/* hide the window */
	[self.selectionWindow orderOut:self];
	
		/* if a row was selected, display the selected pane */
	if ( NSNotFound != modalResult ) {
		
		/* retrieve the selected one. */
		SystemPreferencesPane *selectedPane =
		(SystemPreferencesPane *) [[prefPanesController arrangedObjects]
								   objectAtIndex: modalResult];
		
		/* bring the System Preferences app in front */
		[systemPreferences activate];
		
		/* ask the System Preferences to display the pane.  */
		systemPreferences.currentPane = selectedPane;
	}
	
		/* reset the array (releases the array of SystemPreferencesPanes
		 managed by the array controller) */
	self.prefPanes = nil;
}


	/* called when the user clicks on the 'Show' button in the
	 pane selection window. */
- (IBAction)displaySelectedPane:(id)sender {

		/* get the selected row from the table. */
	NSInteger theRow = [prefPanesController selectionIndex];
	
	if ( NSNotFound != theRow) {  /* if there is selected row... */

			/* done the modal loop, return row selection */
		[NSApp stopModalWithCode: theRow];
				
	}
}


	/* called when the user clicks on the 'Cancel' button in the
	 pane selection window. */
- (IBAction)cancelSelectPaneForDisplay:(id)sender {
	
		/* done the modal loop, return no selection */
	[NSApp stopModalWithCode: NSNotFound];
}





	/* method for displaying one pane */

- (IBAction)displayUniversalAccess:(id)sender {
		
		/* allocate a System Preferences Scripting Bridge object */
	SystemPreferencesApplication *systemPreferences =
		[SBApplication
			applicationWithBundleIdentifier:@"com.apple.systempreferences"];
	
        /* set ourself as the delegate to receive any errors */
    systemPreferences.delegate = self;
    
		/* bring the System Preferences in front */
	[systemPreferences activate];

		/* display the Universal Access pane */
	systemPreferences.currentPane = (SystemPreferencesPane *)
		[[systemPreferences panes] objectWithID:@"com.apple.preference.universalaccess"];
}

@end
