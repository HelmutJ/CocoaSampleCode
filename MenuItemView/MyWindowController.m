/*
     File: MyWindowController.m 
 Abstract: Header file for this sample's main NSWindowController. 
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

#import "MyWindowController.h"

#import "GradientView.h"
#import "PictView.h"
#import "TrackView.h"

@implementation MyWindowController

// -------------------------------------------------------------------------------
//	initWithPath:newPath
// -------------------------------------------------------------------------------
- (id)initWithPath:(NSString *)newPath
{
    return [super initWithWindowNibName:@"TestWindow"];
}

// -------------------------------------------------------------------------------
//	addMenuItemViews:menu
//
//	Canned routine used to copy and set each NSView to the right NSMenuItem.
// -------------------------------------------------------------------------------
- (void)addMenuItemViews:(NSMenu *)menu
{
	// button
	NSData *viewCopyData = [NSArchiver archivedDataWithRootObject:myButtonView];
	id viewCopy = [NSUnarchiver unarchiveObjectWithData:viewCopyData];
	NSMenuItem *menuItem = [menu itemAtIndex:0];
	[menuItem setView:viewCopy];
	[menuItem setTarget:self];

	// radio buttons
	viewCopyData = [NSArchiver archivedDataWithRootObject:myRadioView];
	viewCopy = [NSUnarchiver unarchiveObjectWithData:viewCopyData];
	menuItem = [menu itemAtIndex:1];
	[menuItem setView:viewCopy];
	[menuItem setTarget:self];
	
	// slider
	viewCopyData = [NSArchiver archivedDataWithRootObject:myGradientView];
	viewCopy = [NSUnarchiver unarchiveObjectWithData:viewCopyData];
	[viewCopy setupGradient];			// create gradient background
	menuItem = [menu itemAtIndex:2];
	[menuItem setView:viewCopy];
	[menuItem setTarget:self];
	
	// image view
	viewCopyData = [NSArchiver archivedDataWithRootObject:myPictView];
	viewCopy = [NSUnarchiver unarchiveObjectWithData:viewCopyData];
	[viewCopy setupBackgroundImage];	// load the background image
	menuItem = [menu itemAtIndex:3];
	[menuItem setView:viewCopy];
	[menuItem setTarget:self];
	
	// progress view
	viewCopyData = [NSArchiver archivedDataWithRootObject:myProgressView];
	viewCopy = [NSUnarchiver unarchiveObjectWithData:viewCopyData];
	menuItem = [menu itemAtIndex:4];
	[menuItem setView:viewCopy];
}

// -------------------------------------------------------------------------------
//	createPopupButtons
//
//	Creates the two popup button controls from scratch.
// -------------------------------------------------------------------------------
- (void)createPopupButtons
{
	myCustomPopupButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(18.0, 30.0, 60.0, 40.0)
                                                     pullsDown:NO];
	myCustomPopupButtonPullDown = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(102.0, 30.0, 60.0, 40.0)
                                                             pullsDown:YES];
	
    [(NSPopUpButtonCell *)[myCustomPopupButton cell] setBezelStyle:NSSmallIconButtonBezelStyle];
	[(NSPopUpButtonCell *)[myCustomPopupButtonPullDown cell] setBezelStyle:NSSmallIconButtonBezelStyle];
   
	// set the arrow indicator position
	[[myCustomPopupButton cell] setArrowPosition:NSPopUpArrowAtBottom];
	[myCustomPopupButton setPreferredEdge:NSMaxXEdge];
	
	// set the arrow indicator position
	[[myCustomPopupButtonPullDown cell] setArrowPosition:NSPopUpArrowAtBottom];
	[myCustomPopupButtonPullDown setPreferredEdge:NSMinYEdge];
	 
	// these two controls do not use an item from the menu for its own title
	[[myCustomPopupButton cell] setUsesItemFromMenu:NO];
	[[myCustomPopupButtonPullDown cell] setUsesItemFromMenu:NO];
	
	// set the button icon for both controls
	NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
    NSImage *iconImage = [NSImage imageNamed: @"NSApplicationIcon"];
	[iconImage setSize:NSMakeSize(32,32)];
	[item setImage:iconImage];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[myCustomPopupButton cell] setMenuItem:item];
	[[myCustomPopupButtonPullDown cell] setMenuItem:item];
	[item release];
	
	[[[self window] contentView] addSubview:myCustomPopupButton];
    [[[self window] contentView] addSubview:myCustomPopupButtonPullDown];
}

// -------------------------------------------------------------------------------
//	awakeFromNib
//
//	Create the custom menu and add the NSViews to each menu item.
//
//	Note: since we want each control and menubar to have their own custom menus and views,
//	we need to copy them using NSArchiver/NSUnarchiver.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// create a new menu from scratch and add it to the app's menu bar
    NSMenuItem *newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom" action:NULL keyEquivalent:@""];
    NSMenu *newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom"];
    [newItem setEnabled:YES];
	[newItem setSubmenu:newMenu];
    [newMenu release];
	[[NSApp mainMenu] insertItem:newItem atIndex:3];
    [newItem release];
	
	// create the menu items for this menu
	
	// this menu item will have a view with one NSButton
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Popup Menu" action:@selector(menuItem1Action:) keyEquivalent:@""];
    [newItem setEnabled:YES];
	[newItem setView:myButtonView];
	[newItem setTarget:self];
    [newMenu addItem:newItem];
    [newItem release];
	
	// this menu item will have a view with radio buttons
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Item 2" action:@selector(menuItem2Action:) keyEquivalent:@""];
    [newItem setEnabled:YES];
	[newItem setView:myRadioView];
	[newItem setTarget:self];
    [newMenu addItem:newItem];
    [newItem release];
	
	// this menu item will have a view with a gradient backbround and a slider
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Item 3" action:nil keyEquivalent:@""];
    [newItem setEnabled:YES];
	[newItem setView:myGradientView];
    [newMenu addItem:newItem];
    [newItem release];
	
	// this menu item will have a view with a picture background
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Item 4" action:nil keyEquivalent:@""];
    [newItem setEnabled:YES];
	[newItem setView:myPictView];
    [newMenu addItem:newItem];
    [newItem release];
	
	// this menu item will have a view with a progress indicator
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Item 5" action:nil keyEquivalent:@""];
    [newItem setEnabled:YES];
    [newItem setView:myProgressView];
    [newMenu addItem:newItem];
    [newItem release];
    	
	// this menu item will have a view with tracking areas (much like Finder's label menu item)
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Item 6" action:nil keyEquivalent:@""];
    [newItem setEnabled:YES];
	[newItem setView:myTrackView];
	[newMenu addItem:newItem];
    [newItem release];
		
	// copy the custom NSMenu and its embedded NSViews
	NSData *menuCopyData = [NSArchiver archivedDataWithRootObject:newMenu];
	id menuCopy = [NSUnarchiver unarchiveObjectWithData:menuCopyData];
	[menuCopy removeItemAtIndex:5];		// don't use the label view menu item here
	[self addMenuItemViews:menuCopy];	// add the NSViews to all the menu items
	[myPopupButton setMenu:menuCopy];	// set the newly copied menu to the popup button
	
	// setup more customized popup buttons from scratch:
	[self createPopupButtons];
	
	// copy and add the custom menu to the popup button
	menuCopyData = [NSArchiver archivedDataWithRootObject:menuCopy];
	id finalMenu = [NSUnarchiver unarchiveObjectWithData:menuCopyData];
	[self addMenuItemViews:finalMenu];			// add the NSViews to all the menu items
	[myCustomPopupButton setMenu:finalMenu];	// set the newly copied menu to the popup button

	// copy and add the custom menu to the pull down button
	menuCopyData = [NSArchiver archivedDataWithRootObject:menuCopy];
	finalMenu = [NSUnarchiver unarchiveObjectWithData:menuCopyData];
	[self addMenuItemViews:finalMenu];			// add the NSViews to all the menu items
	[myCustomPopupButtonPullDown setMenu:finalMenu];	// set the newly copied menu to the pulldown button
	
	// copy and add the custom menu as the NSImageView's contextual menu
	menuCopyData = [NSArchiver archivedDataWithRootObject:menuCopy];
	finalMenu = [NSUnarchiver unarchiveObjectWithData:menuCopyData];
	[self addMenuItemViews:finalMenu];			// add the NSViews to all the menu items
	[myImageView setMenu:finalMenu];			// set the newly copied menu to the image view
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[myCustomPopupButton release];
	[myCustomPopupButtonPullDown release];
    
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	menuItem1Action:sender
//
//	User clicked the button in the button menu item view
// -------------------------------------------------------------------------------
- (IBAction)menuItem1Action:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"NSMenuItem button"
                                     defaultButton:@"Wow"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"This is what happens when you put a button in an NSMenuItem."];
	[alert runModal];

	// dismiss the menu
	NSMenu *menu = [[sender enclosingMenuItem] menu];
	[menu cancelTracking];
}

// -------------------------------------------------------------------------------
//	menuItem2Action:sender
//
//	User clicked one of the radio buttons in the radio menu item view
// -------------------------------------------------------------------------------
- (IBAction)menuItem2Action:(id)sender
{
}

@end
