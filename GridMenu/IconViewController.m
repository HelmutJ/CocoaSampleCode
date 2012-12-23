/*
     File: IconViewController.m 
 Abstract: Controller object for our icon collection view.
  
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

#import "IconViewController.h"
#import "NSEventExtras.h"
#import "Choices.h"

// key values for the icon view dictionary
#define KEY_NAME	@"name"
#define KEY_ICON	@"icon"
#define KEY_TAG		@"tag"

// NSNotification name to tell the Window controller to deal with collection view selection
NSString *HandleCollectionItem = @"HandleCollectionItem";
NSString *SelectionIndexesContext = @"SelectionIndexesContext";


#pragma mark -

@implementation MyCollectionView

// -------------------------------------------------------------------------------
//	keyDown:theEvent
//
//	If the user hits enter/return on the collection view while tracking - perform the selection.
// -------------------------------------------------------------------------------
- (void)keyDown:(NSEvent *)theEvent
{
	if ([theEvent isReturnOrEnterKeyEvent])
	{
		NSIndexSet *selection = [self selectionIndexes];
		if ([selection count] > 0)
		{
			// dismiss the menu
			NSMenu *menu = [[self enclosingMenuItem] menu];
			[menu cancelTracking];  // this will cause a "NSMenuDidEndTrackingNotification" notification
		}
	}
	else
	{
		[super keyDown:theEvent];
	}
}

// -------------------------------------------------------------------------------
//	viewDidMoveToWindow
//
//	Make items in our view keyboard-navigable from the start.
// -------------------------------------------------------------------------------
- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	if (self.window)
	{
		[self.window makeFirstResponder:self];
	}
}
			 
@end


#pragma mark -

@implementation IconViewBox

// -------------------------------------------------------------------------------
//	hitTest:aPoint
// -------------------------------------------------------------------------------
- (NSView *)hitTest:(NSPoint)aPoint
{
#pragma unused(aPoint)
	// don't allow any mouse clicks for subviews in this NSBox
	return nil;
}

@end


#pragma mark -

@interface IconViewController ()
- (void)gatherContents:(id)inObject;
@end

@implementation IconViewController

@synthesize icons;

// -------------------------------------------------------------------------------
//	handleEndTrack:notif
// -------------------------------------------------------------------------------
- (void)handleEndTrack:(NSNotification *)notif
{
    NSArray *selection = [iconArrayController selectedObjects];
	
	// clear the current selection for the next time
	[iconArrayController setSelectedObjects:nil];

	NSEvent *curEvent = [[NSApplication sharedApplication] currentEvent];
    if ([curEvent type] == NSKeyDown && [curEvent keyCode] == 53)	// check for escape-key
    {
		return;
	}
	else
	{
		// check if it's "our" menu
		NSMenu *menu = [notif object];
		if (menu != nil && menu == [[[self view] enclosingMenuItem] menu])
		{
			if (selection && [selection count] > 0)
			{
				// fetch the tag for the collection item, used to notify which item was chosen
				NSMutableDictionary *selectedItem = [selection objectAtIndex:0];
				NSNumber *tagNum = [selectedItem valueForKey:KEY_TAG];

				// send this notification to the window controller to handle the selection
				[[NSNotificationCenter defaultCenter] postNotificationName:HandleCollectionItem object:tagNum];
			}
		}
	}
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// bind our collection view's contents and selection to our array controller
	[[self view] bind:@"content" toObject:iconArrayController withKeyPath:@"arrangedObjects" options:nil];
	[[self view] bind:@"selectionIndexes" toObject:iconArrayController withKeyPath:@"selectionIndexes" options:nil];

	MyCollectionView *collectionView = (MyCollectionView *)[self view];
	
	[collectionView setFocusRingType:NSFocusRingTypeNone];	// we don't want a focus ring
	
	[collectionView setAllowsMultipleSelection:NO];	// as a menu we only allow one choice
	[collectionView setSelectable:YES];
	
	// start building our collection on a secondary thread in case it takes time
	[NSThread detachNewThreadSelector:@selector(gatherContents:)
										toTarget:self		// we are the target
										withObject:nil];
    
	// listen for end track event of our menu (the bottleneck for handling selections)
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEndTrack:)
                                                 name:NSMenuDidEndTrackingNotification
                                               object:[[[self view] enclosingMenuItem] menu]];
	
	[iconArrayController setSelectedObjects:nil];	// clear the current selection for the next time
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"selectionIndexes"];
	[icons release];
	
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	updateIcons:obj
//
//	The incoming object is the NSArray of file system object to display.
//-------------------------------------------------------------------------------
- (void)updateIcons:(id)obj
{
	self.icons = obj;	// set this icon array to our collection
	
	// start out with no default selected item
	[iconArrayController setSelectionIndex:NSNotFound];
	
	// start listening for collection view selection changes through our array controller
	[iconArrayController addObserver:self
                          forKeyPath:@"selectionIndexes"
                             options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                             context:SelectionIndexesContext];
}

// -------------------------------------------------------------------------------
//	gatherContents:inObject
//
//	Gathering the contents and their icons could be expensive.
//	This method is being called on a separate thread to avoid blocking the UI.
// -------------------------------------------------------------------------------
- (void)gatherContents:(id)inObject
{
#pragma unused(inObject)
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];

	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSColorPanel"], KEY_ICON,
									@"Color", KEY_NAME,
									[NSNumber numberWithInt:kColorWheel], KEY_TAG,
									nil]];
									
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSComputer"], KEY_ICON,
									@"Computer", KEY_NAME,
									[NSNumber numberWithInt:kComputer], KEY_TAG,
									nil]];
									
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSDotMac"], KEY_ICON,
									@".Mac", KEY_NAME,
									[NSNumber numberWithInt:kDotMac], KEY_TAG,
									nil]];
									
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSFolderSmart"], KEY_ICON,
									[NSNumber numberWithInt:kSmart], KEY_TAG,
									@"Smart", KEY_NAME,
									nil]];
									
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSUser"], KEY_ICON,
									[NSNumber numberWithInt:kUser], KEY_TAG,
									@"User", KEY_NAME,
									nil]];
	
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSFolderBurnable"], KEY_ICON,
									[NSNumber numberWithInt:kBurnable], KEY_TAG,
									@"Burnable", KEY_NAME,
									nil]];
																	
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSNetwork"], KEY_ICON,
									[NSNumber numberWithInt:kNetwork], KEY_TAG,
									@"Network", KEY_NAME,
									nil]];
									
	[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSImage imageNamed: @"NSFontPanel"], KEY_ICON,
									[NSNumber numberWithInt:kFont], KEY_TAG,
									@"Font", KEY_NAME,
									nil]];
									
	[self performSelectorOnMainThread:@selector(updateIcons:) withObject:contentArray waitUntilDone:YES];
	
	[contentArray release];
	
	[pool release];
}

// -------------------------------------------------------------------------------
//	observeValueForKeyPath:ofObject:change:context
//
//	Listen for changes in the "selectionIndexes" of our array controller.
// -------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath
								ofObject:(id)object 
								change:(NSDictionary *)change 
								context:(void *)context
{
    if (context == SelectionIndexesContext)	// be sure this is the right notification for us
	{
		NSEvent *curEvent = [NSApp currentEvent];
		
        // don't act on the selection if the user is type-navigating or dragging the mouse
        if ([curEvent type] != NSKeyDown && [curEvent type] != NSLeftMouseDragged)
        {
            NSArray *selection = [object selectedObjects];
			if (selection && [selection count] > 0)
			{
				// dismiss the menu
				NSMenu *menu = [[[self view] enclosingMenuItem] menu];
				[menu cancelTracking];  // this will cause a "NSMenuDidEndTrackingNotification" notification
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
