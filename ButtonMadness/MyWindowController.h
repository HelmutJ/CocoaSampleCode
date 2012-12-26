/*
     File: MyWindowController.h 
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

#import <Cocoa/Cocoa.h>


@class DropDownButton;

@interface MyWindowController : NSWindowController
{
	//==================================================
	// NSPopUpButton
	
	// nib based controls
	IBOutlet	NSPopUpButton       *nibBasedPopUpDown;
	IBOutlet	NSPopUpButton       *nibBasedPopUpRight;
	
	IBOutlet	NSBox               *popupBox;
	IBOutlet	NSMenu              *buttonMenu;
	
	// code based controls
	IBOutlet	NSView              *placeHolder1;	// the anchor/reference place for the code-based popup
				NSPopUpButton       *codeBasedPopUpDown;
				
	IBOutlet	NSView              *placeHolder2;
				NSPopUpButton       *codeBasedPopUpRight;
	
	//==================================================
	// NSButton
	
	// nib based controls
	IBOutlet	NSButton            *nibBasedButtonRound;
	IBOutlet	NSButton            *nibBasedButtonSquare;
	
	IBOutlet	NSBox               *buttonBox;
	
	// code based controls
	IBOutlet	NSView              *placeHolder3;
				NSButton            *codeBasedButtonRound;
				
	IBOutlet	NSView              *placeHolder4;		
				NSButton            *codeBasedButtonSquare;
			
	//==================================================
	// NSSegmentedControl
	
	// nib based control
	IBOutlet	NSSegmentedControl  *nibBasedSegControl;
	
	IBOutlet	NSBox               *segmentBox;
	
	// code based control
	IBOutlet	NSView              *placeHolder5;
				NSSegmentedControl  *codeBasedSegmentControl;
				
	//==================================================
	// NSMatrix (Radio buttons)
	
	// nib based control
	IBOutlet	NSMatrix            *nibBasedMatrix;
	
	IBOutlet	NSBox               *matrixBox;
	
	// code based control
	IBOutlet	NSView              *placeHolder6;
				NSMatrix            *codeBasedMatrix;
				
	//==================================================
	// NSColorWell
	
	// nib based control
	IBOutlet	NSColorWell         *nibBasedColorWell;
	
	IBOutlet	NSBox               *colorBox;
	
	// code based control
	IBOutlet	NSView              *placeHolder7;
				NSColorWell         *codeBasedColorWell;
				
	//==================================================
	// NSLevelIndicator
	
	// nib based control
	IBOutlet	NSLevelIndicator    *nibBasedIndicator;
	
	IBOutlet	NSBox               *indicatorBox;
	
	// code based control
	IBOutlet	NSView              *placeHolder8;
				NSLevelIndicator    *codeBasedIndicator;
				
	IBOutlet	NSStepper           *levelAdjuster;
	
	//==================================================
	// DropDownButton
	
	IBOutlet	DropDownButton      *dropDownButton;
}

@property (copy) IBOutlet NSMenu *buttonMenu;

// the action methods for all the buttons:
- (IBAction)pullsDownAction:(id)sender;
- (IBAction)popupAction:(id)sender;

- (IBAction)useIconAction:(id)sender;
- (IBAction)buttonAction:(id)sender;

- (IBAction)segmentAction:(id)sender;
- (IBAction)unselectAction:(id)sender;

- (IBAction)matrixAction:(id)sender;

- (IBAction)colorAction:(id)sender;

- (IBAction)levelAdjustAction:(id)sender;
- (IBAction)levelAction:(id)sender;
- (IBAction)setStyleAction:(id)sender;

- (IBAction)dropDownAction:(id)sender;

@end
