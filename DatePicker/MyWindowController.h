/*
     File: MyWindowController.h 
 Abstract: This sample's main NSWindowController.
  
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

@interface MyWindowController : NSWindowController <NSDatePickerCellDelegate>
{
	NSDatePicker*			datePickerControl;
	
	IBOutlet NSBox*			outerBox;
	
	IBOutlet NSTextField*	dateResult1;
	IBOutlet NSTextField*	dateResult2;
	IBOutlet NSTextField*	dateResult3;
	IBOutlet NSTextField*	dateResult4;
	IBOutlet NSTextField*	dateResult5;
	
	// appearance
	IBOutlet NSPopUpButton* pickerStylePopup;
	IBOutlet NSButton*		drawsBackgroundCheck;
	IBOutlet NSButton*		bezeledCheck;
	IBOutlet NSButton*		borderedCheck;
	IBOutlet NSColorWell*	backColorWell;
	IBOutlet NSColorWell*	textColorWell;
	IBOutlet NSPopUpButton*	fontSizePopup;
	
	// date and time
	IBOutlet NSMatrix*		dateElementChecks;
	IBOutlet NSMatrix*		timeElementChecks;
	IBOutlet NSButton*		overrideDateCheck;
	IBOutlet NSDatePicker*	overrideDate;
	
	// date range
	IBOutlet NSMatrix*		datePickerModeRadios;
	IBOutlet NSTextField*	secondsRangeEdit;
	IBOutlet NSTextField*	secondsRangeEditLabel;
	
	IBOutlet NSDatePicker*	minDatePicker;
	IBOutlet NSDatePicker*	maxDatePicker;
	
	int						shrinkGrowFactor;
}

- (IBAction)datePickerAction:(id)sender;

- (IBAction)setPickerStyle:(id)sender;
- (IBAction)setDrawsBackground:(id)sender;
- (IBAction)setBackgroundColor:(id)sender;
- (IBAction)setTextColor:(id)sender;
- (IBAction)setBezeled:(id)sender;
- (IBAction)setBordered:(id)sender;
- (IBAction)setDateElementFlags:(id)sender;
- (IBAction)setTimeElementFlags:(id)sender;
- (IBAction)setDatePickerMode:(id)sender;

- (IBAction)setToday:(id)sender;

- (IBAction)setFontSize:(id)sender;

- (IBAction)setMinDate:(id)sender;
- (IBAction)setMaxDate:(id)sender;

- (IBAction)dateOverrideAction:(id)sender;

@end
