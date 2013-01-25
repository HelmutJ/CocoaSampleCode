/*
     File: Controller.m 
 Abstract: Main window's controller. 
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


@implementation Controller


	/* tell the compiler to synthasize the property accessors
	for our instance variables and IBOutlets. */
	
@synthesize myWindow, workflowView, workflowTable, workflowController, tableContent;
@synthesize workflows, runningWorkflow;



	/* display the selected workflow. */
- (BOOL)displaySelectedWorkflow {

		/* get the selected row from the workflow table. */
	NSUInteger theRow = [workflowTable selectedRow];

	  /* if there is a selection and we are not running
	  the selected workflow, then we can display the
	  workflow selected in the list. */
	if ( theRow != -1 && ! self.runningWorkflow ) {
	
			/* retrieve the first item in the selection */
		NSDictionary* selectedEntry = [[tableContent arrangedObjects] objectAtIndex: theRow];
	
			/* retrieve the selected application from our list of applications. */
		AMWorkflow* selectedWorkflow =
			(AMWorkflow*) [selectedEntry objectForKey:@"workflow"];

			/* ask the AMWorkflowController to display the selected workflow */
		[workflowController setWorkflow: selectedWorkflow];
			
			/* set the window title */
		[myWindow setTitle: (NSString*) [selectedEntry objectForKey:@"name"]];

		return YES;
		
	} else {
	
		return NO;
		
	}
}


	/* awakeFromNib is called after our MainMenu.nib file has been loaded
	and the main window is ready for use.  Here, we finish initializing
	our content for display in the window.  */
- (void)awakeFromNib {
	
		/* we're only using the AMWorkflowView for display */
	[workflowView setEditable: NO];	

		/* set up the data for NSTableView.  We'll store a list of
		NSDictonary records each containing some information about the
		workflow.  We'll display the name of the workflow's file in the
		window.  */
		
		/* set up an array for storing the table information */
	NSMutableArray *theWorkflows = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
	
		/* retrieve a list of all of the workflows stored in the application's
		resourced folder. */
	NSArray *workflowPaths = [[NSBundle mainBundle]
		pathsForResourcesOfType:@"workflow" inDirectory:@"workflows"];
		
		/* iterate through the paths, adding them to our table information
		as we go.  */
	for ( NSString* nthWorkflowPath in workflowPaths ) {
		NSError *wfError = nil;
		
			/* convert the path into an URL */
		NSURL* nthWorkflowURL = [NSURL fileURLWithPath:nthWorkflowPath isDirectory:NO];

			/* allocate and initialize the workflow */
		AMWorkflow* nthWorkflow = [(AMWorkflow *)[AMWorkflow alloc] initWithContentsOfURL:nthWorkflowURL error:&wfError];

		if ( nthWorkflow ) {
		
				/* calculate the file name without path or extension */
			NSString* nthFileName = [nthWorkflowURL lastPathComponent];
			NSString* nthDisplayName = [nthFileName stringByDeletingPathExtension];

				/* add the workflow to the list */
			[theWorkflows addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					nthDisplayName, @"name", /* name displayed in list */
					nthWorkflowPath, @"path", /* complete path to the bundle */
					nthWorkflow, @"workflow", /* initialized AMWorkflow */
					nil]];
		}
        
        [nthWorkflow release];
	}
	
		/* set the workflows */
	self.workflows = theWorkflows;

		/* if there are any workflows in the list, then select and display the first one */
	if ([self.workflows count] > 0 ) {
		[workflowTable selectRowIndexes:
				[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[self displaySelectedWorkflow];
	}

}



	/* NSApplication delegate method - for convenience. We have set the
	File's Owner's delegate to our Controller object in the MainMenu.nib file. */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}






	/* NSTableView delegate methods.
	We have set our controller object as the NSTableView's delegate in the MainMenu.nib file.  */

	/* selectionShouldChangeInTableView: is called when the user has clicked in the
	table view in a way that will cause the selection to change.  This method allows us
	to decide if we would like to allow the selection to change and the response
	we return depends on if we are running a selection - we don't allow the selection
	to change while a workflow is running. */ 
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {

		/* if the current selected workflow is running, don't change the selection. */
	if ( self.runningWorkflow ) {
	
			/* display an alert explaining why the selection cannot be changed. */
			
			/* get the name of the action that is running now. */
		NSString* selectedWorkflow =
			(NSString*) [(NSDictionary*)
				[[tableContent arrangedObjects] objectAtIndex: [workflowTable selectedRow]] objectForKey:@"name"];
				
			/* display a modal sheet explaining why the selection cannot be changed. */
		NSBeginInformationalAlertSheet(
				[NSString stringWithFormat:@"The '%@' action is running.", selectedWorkflow],
				@"OK", nil, nil, myWindow, nil, nil, nil, nil,
				[NSString stringWithFormat:
					@"You cannot select another action until the '%@' action has finished running.",
					selectedWorkflow]
			);
	}
	
		/* return true only if we are not in the middle of running an action. */
	return ! self.runningWorkflow;
}

	/* tableViewSelectionIsChanging: is called after the selection has changed.  All there
	is to do here is update the workflow displayed in the AMWorkflowView to show the newly
	selected workflow. */
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification {
	[self displaySelectedWorkflow];
}



	/* AMWorkflowController delegate methods.  In these routines we adjust the
	value of our runningWorkflow property.  Key value bindings to this property
	defined in our interface file take care of enabling/disabling the run/stop buttons,
	and displaying the progress bar. */
	
- (void)workflowControllerWillRun:(AMWorkflowController *)controller {
	self.runningWorkflow = YES;
}


- (void)workflowControllerDidRun:(AMWorkflowController *)controller {
	self.runningWorkflow = NO;
}


- (void)workflowControllerDidStop:(AMWorkflowController *)controller {
	self.runningWorkflow = NO;
}


- (void)dealloc
{
    self.workflows = nil;
}


@end


