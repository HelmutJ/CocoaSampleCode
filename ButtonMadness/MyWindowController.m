/*
     File: MyWindowController.m 
 Abstract: The primary NSWindowController object for managing all the buttons and controls. 
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

// -------------------------------------------------------------------------------
//	NSSegmentedControl category to unselect all segments.
//
//	NSSegmentedControl won't unselect all segments if there is currently one
//	segment selected.  So you have to go into the "Momentary tracking mode", unselect
//	each of the cells, then go back to its original mode.
// -------------------------------------------------------------------------------
@interface NSSegmentedControl (SampleAddition)
- (void)unselectAllSegments;
@end


#pragma mark -

@implementation NSSegmentedControl (SampleAddition)
- (void)unselectAllSegments
{
    NSSegmentSwitchTracking current;
    current = [[self cell] trackingMode];

    [[self cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];

    int i;
    for (i = 0; i < [self segmentCount]; i++)
	{
        [self setSelected: NO  forSegment: i];
    }

    [[self cell] setTrackingMode: current];
}
@end


#pragma mark -

@implementation MyWindowController

@synthesize buttonMenu;

// -------------------------------------------------------------------------------
//	initWithPath:newPath
// -------------------------------------------------------------------------------
- (id)initWithPath:(NSString *)newPath
{
    return [super initWithWindowNibName:@"TestWindow"];
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[codeBasedPopUpDown release];
	[codeBasedPopUpRight release];
	[codeBasedButtonRound release];
	[codeBasedButtonSquare release];
    [buttonMenu release];
    
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
//
//	Note that we copy the 'buttonMenu' outlet whenever we set this copied menu to a
//	particular button.  This will ensure each button has their own unique menu so
//	not to affect each other.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	NSImage* iconImage = [NSImage imageNamed:@"moof"];
	
    [nibBasedButtonRound setImage:iconImage];
    [nibBasedButtonSquare setImage:iconImage];
    
	//===============================
	// NSPopupButton

	// update its menu (keep original self.buttonMenu untouched)
	NSMenu *newMenu = [self.buttonMenu copy];
	
	// add the image menu item back to the first menu item
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	[menuItem setImage:[NSImage imageNamed: @"moof"]];
	[newMenu insertItem:menuItem atIndex:0];
	[menuItem release];

	// create the pull down button pointing DOWN
	NSRect buttonFrame = [placeHolder1 frame];
	codeBasedPopUpDown = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:YES];
	[[codeBasedPopUpDown cell] setArrowPosition:NSPopUpArrowAtBottom];	
	[[codeBasedPopUpDown cell] setBezelStyle:NSSmallIconButtonBezelStyle];
	[codeBasedPopUpDown setMenu:newMenu];
	[popupBox addSubview:codeBasedPopUpDown];
	[placeHolder1 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	// create the pull down button pointing RIGHT
	buttonFrame = [placeHolder2 frame];
	codeBasedPopUpRight = [[NSPopUpButton alloc] initWithFrame:buttonFrame pullsDown:YES];
	[[codeBasedPopUpRight cell] setArrowPosition:NSPopUpArrowAtBottom];
	[codeBasedPopUpRight setPreferredEdge:NSMaxXEdge];	// make the popup menu appear to the right
	[[codeBasedPopUpRight cell] setBezelStyle: NSShadowlessSquareBezelStyle];
	[codeBasedPopUpRight setMenu:newMenu];
	[[codeBasedPopUpRight cell] setHighlightsBy:NSChangeGrayCellMask];
	[popupBox addSubview:codeBasedPopUpRight];
	[placeHolder2 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	// copy the menu again for 'nibBasedPopUpDown' and 'nibBasedPopUpRight' control
	[nibBasedPopUpDown setMenu:newMenu];
	[nibBasedPopUpRight setMenu:newMenu];
    
	[newMenu release];
	
	//===============================
	// NSButton
	
	// create the rounded button
	buttonFrame = [placeHolder3 frame];
	codeBasedButtonRound = [[NSButton alloc] initWithFrame:buttonFrame];
	// note: this button we want alternate title and image, so we need to call this:
	[codeBasedButtonRound setButtonType: NSMomentaryChangeButton];
	[codeBasedButtonRound setTitle: @"NSButton"];
	[codeBasedButtonRound setAlternateTitle: @"(pressed)"];
	[codeBasedButtonRound setImage:iconImage];
	[codeBasedButtonRound setAlternateImage:[NSImage imageNamed: @"moof2"]];
	
	[codeBasedButtonRound setBezelStyle: NSRegularSquareBezelStyle];
	[codeBasedButtonRound setImagePosition: NSImageLeft];
	[[codeBasedButtonRound cell] setAlignment:NSLeftTextAlignment];
	[codeBasedButtonRound setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[codeBasedButtonRound setSound:[NSSound soundNamed:@"Pop"]];
	[codeBasedButtonRound setTarget:self];
	[codeBasedButtonRound setAction:@selector(buttonAction:)];
	
	[buttonBox addSubview:codeBasedButtonRound];
	[placeHolder3 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	// create the square button
	buttonFrame = [placeHolder4 frame];
	codeBasedButtonSquare = [[NSButton alloc] initWithFrame:buttonFrame];
	[codeBasedButtonSquare setTitle: @"NSButton"];
	[codeBasedButtonSquare setBezelStyle:NSShadowlessSquareBezelStyle];
	[codeBasedButtonSquare setImagePosition:NSImageLeft];
	[[codeBasedButtonSquare cell] setAlignment:NSLeftTextAlignment];
	[codeBasedButtonSquare setImage:iconImage];
	[codeBasedButtonSquare setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[codeBasedButtonSquare setSound:[NSSound soundNamed:@"Pop"]];
	[codeBasedButtonSquare setTarget:self];
	[codeBasedButtonSquare setAction:@selector(buttonAction:)];
	[buttonBox addSubview:codeBasedButtonSquare];
	[placeHolder4 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	//===============================
	// NSSegmentedControl
	
	// create the segmented control button
	buttonFrame = [placeHolder5 frame];
	codeBasedSegmentControl = [[NSSegmentedControl alloc] initWithFrame:buttonFrame];
	[codeBasedSegmentControl setSegmentCount:3];
	[codeBasedSegmentControl setWidth:[nibBasedSegControl widthForSegment:0] forSegment:0];
	[codeBasedSegmentControl setWidth:[nibBasedSegControl widthForSegment:1] forSegment:1];
	[codeBasedSegmentControl setWidth:[nibBasedSegControl widthForSegment:2] forSegment:2];
	[codeBasedSegmentControl setLabel:@"One" forSegment:0];
	[codeBasedSegmentControl setLabel:@"Two" forSegment:1];
	[codeBasedSegmentControl setLabel:@"Three" forSegment:2];
	[codeBasedSegmentControl setTarget:self];
	[codeBasedSegmentControl setAction:@selector(segmentAction:)];
	[segmentBox addSubview:codeBasedSegmentControl];
	[placeHolder5 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	// use a menu to the first segment (applied to both nib-based and code-based)
	[codeBasedSegmentControl setMenu:self.buttonMenu forSegment:0];
	[nibBasedSegControl setMenu:self.buttonMenu forSegment:0];
	
	// add icons to each segment (applied to both nib-based and code-based)
	iconImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kComputerIcon)];
	[iconImage setSize:NSMakeSize(16,16)];
	[nibBasedSegControl setImage:iconImage forSegment:0];
	[codeBasedSegmentControl setImage:iconImage forSegment:0];
	iconImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kDesktopIcon)];
	[iconImage setSize:NSMakeSize(16,16)];
	[nibBasedSegControl setImage:iconImage forSegment:1];
	[codeBasedSegmentControl setImage:iconImage forSegment:1];
	iconImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kFinderIcon)];
	[iconImage setSize:NSMakeSize(16,16)];
	[nibBasedSegControl setImage:iconImage forSegment:2];
	[codeBasedSegmentControl setImage:iconImage forSegment:2];
	
	//===============================
	// NSMatrix
	
	// first create a radio cell prototype
	NSButtonCell *radioCell; 
	radioCell = [[[NSButtonCell alloc] init] autorelease]; 
	[radioCell setButtonType:NSRadioButton]; 
	[radioCell setTitle:@"RadioCell"];
	
	// create the NSMatrix
	buttonFrame = [placeHolder6 frame];
	codeBasedMatrix = [[NSMatrix alloc] initWithFrame:buttonFrame mode:NSRadioModeMatrix prototype:radioCell numberOfRows:2 numberOfColumns:1];
	
	// add the cells to the matrix
	NSCell *cellToChange = [codeBasedMatrix cellAtRow:0 column:0];
	[cellToChange setTitle:@"Radio 1"];
	cellToChange = [codeBasedMatrix cellAtRow:1 column:0];
	[cellToChange setTitle:@"Radio 2"];
	
	[codeBasedMatrix setTarget:self];
	[codeBasedMatrix setAction:@selector(matrixAction:)];
	
	[matrixBox addSubview:codeBasedMatrix];
	[placeHolder6 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	//===============================
	// NSColorWell
	
	buttonFrame = [placeHolder7 frame];
	codeBasedColorWell = [[NSColorWell alloc] initWithFrame:buttonFrame];
	[codeBasedColorWell setColor: [NSColor blueColor]];
	[colorBox addSubview:codeBasedColorWell];
	[codeBasedColorWell setAction:@selector(colorAction:)];
	[placeHolder7 removeFromSuperview];	// we are done with the place holder, remove it from the window
	
	//===============================
	// NSLevelIndicator
	
	buttonFrame = [placeHolder8 frame];
	codeBasedIndicator = [[NSLevelIndicator alloc] initWithFrame:buttonFrame];
	[codeBasedIndicator setMaxValue: 10];
	
	[codeBasedIndicator setNumberOfMajorTickMarks: 4];
	[codeBasedIndicator setNumberOfTickMarks: 7];
	[codeBasedIndicator setWarningValue: 5];
	[codeBasedIndicator setCriticalValue: 8];
	[[codeBasedIndicator cell] setLevelIndicatorStyle: NSDiscreteCapacityLevelIndicatorStyle];
	[codeBasedIndicator setAction:@selector(levelAction:)];
	
	[indicatorBox addSubview:codeBasedIndicator];
	[placeHolder8 removeFromSuperview];	// we are done with the place holder, remove it from the window
}


#pragma mark -
#pragma mark NSPopUpButton

// -------------------------------------------------------------------------------
//	popupAction:
//
//	User chose a menu item from one of the popups.
//	Note that all four popup buttons share the same action method.
// -------------------------------------------------------------------------------
- (IBAction)popupAction:(id)sender
{
	// menu item chosen: [sender tag];
}

// -------------------------------------------------------------------------------
//	changePopupState:
//
//	Change the given NSPopupButton as "popup" or "pull down" styte.
// -------------------------------------------------------------------------------
- (void)changePopupState:(NSPopUpButton *)popup asPullDown:(BOOL)pullDown
{
	// hide button first to invalidate its old size
	[popup setHidden:YES];
	[popup displayIfNeeded];
	
	NSRect buttonFrame = [popup frame];
	
	if (pullDown)
	{
		// - change the button to pull down style
		
		// make the popup a larger square to fit the moof image, and move its origin
		buttonFrame.size.height += 36;		
		buttonFrame.origin.y -= 36;
		
		// update its menu (keep original self.buttonMenu untouched)
		NSMenu *newMenu = [self.buttonMenu copy];
		
		// add the image menu item back to the first menu item
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
		[menuItem setImage:[NSImage imageNamed: @"moof"]];
		[newMenu insertItem:menuItem atIndex:0];
		[menuItem release];
		
		[popup setMenu:newMenu];
		[newMenu release];
	}
	else
	{
		// - change the button with a popup style
		
		// shrink the popup down to menu height size and move its origin upwards
		buttonFrame.size.height -= 36;	
		buttonFrame.origin.y += 36;
		
		// update its menu (keep original self.buttonMenu untouched)
		NSMenu *newMenu = [self.buttonMenu copy];
		[popup setMenu:self.buttonMenu];
		[newMenu release];
	}	
	
	[[popup cell] setPullsDown:pullDown];
	
	// change the button's frame size and make it visible again
	[popup setFrame:buttonFrame];
	[popup setHidden:NO];
}

// -------------------------------------------------------------------------------
//	pullsDownAction:sender
//
//	User checked "Pull Down" checkbox to change the popup button's appearance:
//		1) as a drop down menu, or 2) as popup menu.
//
//	This is an example on how to change the attributes of these popup buttons,
//	so that they appear correctly.
//
//	If checkbox is not checked:
//		Shrink the button height to appear as a popup button.
//		We also remove the moof image in this casae.
//	If checkbox is checked:
//		Make the button square to fit the moof image.
//		Put back the moof image menu item.
//	
// -------------------------------------------------------------------------------
- (IBAction)pullsDownAction:(id)sender
{
	BOOL pullDown = [[sender selectedCell] state];
	
	[self changePopupState:codeBasedPopUpDown asPullDown:pullDown];
	[self changePopupState:codeBasedPopUpRight asPullDown:pullDown];
	
	[self changePopupState:nibBasedPopUpDown asPullDown:pullDown];
	[self changePopupState:nibBasedPopUpRight asPullDown:pullDown];
}


#pragma mark -
#pragma mark NSButton

// -------------------------------------------------------------------------------
//	setIconPosition:useIcon
// -------------------------------------------------------------------------------
- (void)setIconPosition:(NSButton*)button useIcon:(BOOL)useIcon
{
	if (useIcon)
	{
		[button setImagePosition: NSImageLeft];
		[[button cell] setAlignment:NSLeftTextAlignment];
	}
	else
	{
		[button setImagePosition: NSNoImage];
		[[button cell] setAlignment:NSCenterTextAlignment];
	}
}

// -------------------------------------------------------------------------------
//	useIconAction:sender
//
//	User checked "Use Icon" checkbox - add or remove the moof icon.
// -------------------------------------------------------------------------------
- (IBAction)useIconAction:(id)sender
{
	BOOL useIcon = [[sender cell] state];
	
	[self setIconPosition:nibBasedButtonRound useIcon:useIcon];
	[self setIconPosition:nibBasedButtonSquare useIcon:useIcon];
	[self setIconPosition:codeBasedButtonRound useIcon:useIcon];
	[self setIconPosition:codeBasedButtonSquare useIcon:useIcon];
}

// -------------------------------------------------------------------------------
//	buttonAction:sender
//
//	User clicked one of the NSButttons.
//	Note that all four buttons share the same action method.
// -------------------------------------------------------------------------------
- (IBAction)buttonAction:(id)sender
{
	NSLog(@"Button was clicked");
}


#pragma mark -
#pragma mark NSSegmentedControl

// -------------------------------------------------------------------------------
//	segmentAction:sender
//
//	User clicked one of the segments.
//	Note that both segmented controls share the same action method.
// -------------------------------------------------------------------------------
- (IBAction)segmentAction:(id)sender
{
	// segment control was clicked: [sender selectedSegment];
}

// -------------------------------------------------------------------------------
//	unselectAction:sender
//
//	User clicked on the button to unselect all segments.
//	Use our category to NSSegmentedControl to unselect the cells.
// -------------------------------------------------------------------------------
- (IBAction)unselectAction:(id)sender
{
	[nibBasedSegControl unselectAllSegments];
	[codeBasedSegmentControl unselectAllSegments];
}


#pragma mark -
#pragma mark NSMatrix

// -------------------------------------------------------------------------------
//	matrixAction:sender
//
//	User clicked one of the radio buttons in the NSMatrix.
// -------------------------------------------------------------------------------
- (IBAction)matrixAction:(id)sender
{
	// NSMatrix was clicked, radio control: [sender selectedRow];
}


#pragma mark -
#pragma mark NSColorWell

// -------------------------------------------------------------------------------
//	colorAction:sender
//
//	User clicked one of the NSColorWell.
// -------------------------------------------------------------------------------
- (IBAction)colorAction:(id)sender
{
	// user chose a color: [sender color];
}


#pragma mark -
#pragma mark NSLevelIndicator

// -------------------------------------------------------------------------------
//	levelAdjustAction:sender
//
//	User clicked the up/down arrow to adjust the level.
// -------------------------------------------------------------------------------
- (IBAction)levelAdjustAction:(id)sender
{
	// change level
	[nibBasedIndicator setIntValue: [sender intValue]];
	[codeBasedIndicator setIntValue: [sender intValue]];
}

// -------------------------------------------------------------------------------
//	levelAction:sender
//
//	User clicked on the actual level indicator to change its value.
// -------------------------------------------------------------------------------
- (IBAction)levelAction:(id)sender
{
	// level clicked: [sender intValue];
}

// -------------------------------------------------------------------------------
//	setStyleAction:sender
//
//	User wants to change the level indicator's style.
// -------------------------------------------------------------------------------
- (IBAction)setStyleAction:(id)sender
{
	int tag = [[sender selectedCell] tag];
	[[nibBasedIndicator cell] setLevelIndicatorStyle: tag];
	[[codeBasedIndicator cell] setLevelIndicatorStyle: tag];
}


#pragma mark -
#pragma mark DropDownButton

// -------------------------------------------------------------------------------
//	dropDownAction:sender
//
//	User clicked the DropDownButton.
// -------------------------------------------------------------------------------
- (IBAction)dropDownAction:(id)sender
{
	// Drop down button clicked
}

@end
