/*
     File: MyWindowController.m 
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

#import "MyWindowController.h"


@interface MyWindowController ()
- (void)setupDatePickerControl:(NSDatePickerStyle)pickerStyle;
- (void)updateControls;
- (void)updateDateTimeElementFlags;
- (void)updateDatePickerMode;
@end


@implementation MyWindowController

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// based our date formatter on CFDateFormatter: allows more configurability and better localization
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	[self setupDatePickerControl:NSClockAndCalendarDatePickerStyle];
	
	// setup the initial NSDatePickerElementFlags since we are using picker style: NSClockAndCalendarDatePickerStyle
	NSDatePickerElementFlags flags = 0;
	flags |= NSYearMonthDatePickerElementFlag;
    flags |= NSYearMonthDayDatePickerElementFlag;
	flags |= NSEraDatePickerElementFlag;	
	flags |= NSHourMinuteDatePickerElementFlag;
    flags |= NSHourMinuteSecondDatePickerElementFlag;
	flags |= NSTimeZoneDatePickerElementFlag;
	[datePickerControl setDatePickerElements: flags];
	
	if (NSAppKitVersionNumber < NSAppKitVersionNumber10_5)
    {
        [[datePickerModeRadios cellWithTag: 1] setEnabled:NO];	// not currently implemened in 10.4.x and earlier
    }
    
	[minDatePicker setDateValue:[NSDate date]];
	[maxDatePicker setDateValue:[NSDate distantFuture]];
    
	[self updateControls];	// force update of all UI elements and the picker itself
}

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

// -------------------------------------------------------------------------------
//	setupDatePickerControl:pickerStyle
//
//	Delete and re-create a new NSDatePicker
// -------------------------------------------------------------------------------
- (void)setupDatePickerControl:(NSDatePickerStyle)pickerStyle
{
	// we need to re-create the picker control (due to a resize bug when switching between styles)
	if (datePickerControl != nil)	// hide and release the previous date picker, if any
	{
		[datePickerControl release];
		datePickerControl = nil;
	}
	
	NSRect frame = NSMakeRect(10, 10, 295, 154);
    shrinkGrowFactor = frame.size.height - 30;
	
	// create the date picker control if not created already
	if (datePickerControl == nil)
		datePickerControl = [[NSDatePicker alloc] initWithFrame:frame];
	
	[datePickerControl setDatePickerStyle: pickerStyle];	// set our desired picker style
	
	[outerBox addSubview:datePickerControl];
    
    [datePickerControl setDrawsBackground:YES];
	[datePickerControl setBezeled:YES];
	[datePickerControl setBordered:NO];
	[datePickerControl setEnabled:YES];
	
	[datePickerControl setTextColor: [textColorWell color]];
	[datePickerControl setBackgroundColor: [backColorWell color]];
	
	// always set the date/time to TODAY
	// note that our delete override might block this...
	[datePickerControl setDateValue: [NSDate date]];	
	
	[datePickerControl setNeedsDisplay:YES];
	[self updateControls];	// force update of all UI elements and the picker itself
	
	// synch the picker style popup with the new style change
	[pickerStylePopup selectItemWithTag:pickerStyle];
	
	// we want to be the cell's delegate to catch date validation
	[datePickerControl setDelegate:self];
	// or we can set us as the delegate to its cell like so:
	//		[[datePickerControl cell] setDelegate:self];
	
	// we want to respond to date/time changes
	[datePickerControl setAction:@selector(datePickerAction:)];
}

// -------------------------------------------------------------------------------
//	updateDateResult:
// -------------------------------------------------------------------------------
- (void)updateDateResult
{
	NSDate *theDate = [datePickerControl dateValue];
	if (theDate)
	{
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		
		/* some examples:
		[formatter setDateStyle:NSDateFormatterNoStyle];		// <no date displayed>
		[formatter setDateStyle:NSDateFormatterMediumStyle];	// Jan 24, 1984
		[formatter setDateStyle:NSDateFormatterShortStyle];		// 1/24/84
		[formatter setDateStyle:NSDateFormatterLongStyle];		// January 24, 1984
		[formatter setDateStyle:NSDateFormatterFullStyle];		// Tuesday, January 24, 1984
		
		[formatter setTimeStyle:NSDateFormatterNoStyle];		// <no time displayed>
		[formatter setTimeStyle:NSDateFormatterShortStyle];		// 2:44 PM
		[formatter setTimeStyle:NSDateFormatterMediumStyle];	// 2:44:55 PM
		[formatter setTimeStyle:NSDateFormatterLongStyle];		// 2:44:55 PM PDT
		[formatter setTimeStyle:NSDateFormatterFullStyle];		// 2:44:55 PM PDT
		*/
				
		NSString *formattedDateString;

		[formatter setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		formattedDateString = [formatter stringFromDate:theDate];
		[dateResult1 setStringValue: formattedDateString];
		
		[formatter setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		formattedDateString = [formatter stringFromDate:theDate];
		[dateResult2 setStringValue: formattedDateString];
		
		[formatter setDateStyle:NSDateFormatterMediumStyle];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		formattedDateString = [formatter stringFromDate:theDate];
		[dateResult3 setStringValue: formattedDateString];
		
		[formatter setDateStyle:NSDateFormatterLongStyle];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		formattedDateString = [formatter stringFromDate:theDate];
		[dateResult4 setStringValue: formattedDateString];
		
		[formatter setDateStyle:NSDateFormatterFullStyle];
		[formatter setTimeStyle:NSDateFormatterFullStyle];
		formattedDateString = [formatter stringFromDate:theDate];
		[dateResult5 setStringValue: formattedDateString];
	}
}

// -------------------------------------------------------------------------------
//	updateControls:
//
//	Force update of all UI elements and the picker itself.
// -------------------------------------------------------------------------------
- (void)updateControls
{
	[datePickerControl setNeedsDisplay: YES];	// force it to update
	
	[self updateDatePickerMode];
	[self updateDateTimeElementFlags];
	[self updateDateResult];
}


#pragma mark -
#pragma mark NSDATEPICKER

// -------------------------------------------------------------------------------
//	setPickerStyle:sender:
//
//	User chose a different picker style from the Picker Style popup.
// -------------------------------------------------------------------------------
- (IBAction)setPickerStyle:(id)sender
{
	NSInteger tag = [[sender selectedCell] tag];
	
	if ([datePickerControl datePickerStyle] != (NSUInteger)tag)
	{
		NSRect windowFrame = [[self window] frame];
		NSRect boxFrame = [outerBox frame];
		
		[datePickerControl setHidden: YES];

		if (tag == NSClockAndCalendarDatePickerStyle)
		{
			// for this picker style, we need to grow the window to make room
			//
			windowFrame.size.height += shrinkGrowFactor;
			windowFrame.origin.y -= shrinkGrowFactor;
			
			boxFrame.size.height += shrinkGrowFactor;
			[outerBox setFrame: boxFrame];
			
			[[self window] setFrame:windowFrame display:YES animate:YES];
			
			[datePickerControl setDatePickerStyle: NSClockAndCalendarDatePickerStyle];	// set our desired picker style
			
			// shows these last
			[dateResult1 setHidden: NO];
			[dateResult2 setHidden: NO];
			[dateResult3 setHidden: NO];
			[dateResult4 setHidden: NO];
		}
		else
		{
			NSDatePickerStyle currentPickerStyle = [datePickerControl datePickerStyle];
			
			// shrink the window only if the current style is "clock and calendar"
			if (currentPickerStyle == NSClockAndCalendarDatePickerStyle)
			{
				// hide these first
				[dateResult1 setHidden: YES];
				[dateResult2 setHidden: YES];
				[dateResult3 setHidden: YES];
				[dateResult4 setHidden: YES];
				
				windowFrame.size.height -= shrinkGrowFactor;
				windowFrame.origin.y += shrinkGrowFactor;
				
				boxFrame.size.height -= shrinkGrowFactor;
				[outerBox setFrame: boxFrame];
				
				[[self window] setFrame:windowFrame display:YES animate:YES];
			}
			
			[self setupDatePickerControl: tag];	// set our desired picker style
		}
		
		[datePickerControl setHidden: NO];
		
		[self updateControls];	// force update of all UI elements and the picker itself
	}
}

// -------------------------------------------------------------------------------
//	setFontSize:
//
//	User chose a different control font size from the Font Size popup.
// -------------------------------------------------------------------------------
- (IBAction)setFontSize:(id)sender
{
	int tag = [[sender selectedCell] tag];
	switch (tag)
	{
		case NSMiniControlSize:
			[[datePickerControl cell] setControlSize:NSMiniControlSize];
			[[datePickerControl cell] setFont:[NSFont systemFontOfSize:9.0]];
			break;
			
		case NSSmallControlSize:
			[[datePickerControl cell] setControlSize:NSSmallControlSize];
			[[datePickerControl cell] setFont:[NSFont systemFontOfSize:11.0]];
			break;
			
		case NSRegularControlSize:
			[[datePickerControl cell] setControlSize:NSRegularControlSize];
			[[datePickerControl cell] setFont:[NSFont systemFontOfSize:13.0]];
			break;
	}
}

// -------------------------------------------------------------------------------
//	datePickerAction:sender:
//
//	The user interacted with the date picker control so update the date/time examples.
// -------------------------------------------------------------------------------
- (IBAction)datePickerAction:(id)sender
{
	[self updateDateResult];
}

// -------------------------------------------------------------------------------
//	dateOverrideAction:sender:
//
//	The user checked/unchecked the "Date Override" checkbox - which in effect
//	turns on or off the delegate method to override the date.
// -------------------------------------------------------------------------------
- (IBAction)dateOverrideAction:(id)sender
{
	BOOL checked = [[sender selectedCell] state];
	if (checked)
	{
		[datePickerControl setDelegate: self];
	}
	else
	{
		[datePickerControl setDelegate: nil];
	}
	
	[datePickerControl setDateValue: [NSDate date]];	// force the delete "datePickerCell" to be called
}

// -------------------------------------------------------------------------------
//	datePickerCell:aDatePickerCell:proposedDateValue:proposedTimeInterval
//
//	Delegate to NSDatePickerCell
// -------------------------------------------------------------------------------
- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate **)proposedDateValue timeInterval:(NSTimeInterval*)proposedTimeInterval
{	
	MyWindowController *controller = (MyWindowController *)[aDatePickerCell delegate];
	
	if ((controller == self) && (aDatePickerCell == [datePickerControl cell]))
	{
		// override the date and time?
		if ([[overrideDateCheck cell] state])
		{
			// override the date using the user specified date
			*proposedDateValue = [overrideDate dateValue];
		}
	}
}

// -------------------------------------------------------------------------------
//	setToday:sender
//
//	Sets the date picker value to 'today'
// -------------------------------------------------------------------------------
- (IBAction)setToday:(id)sender
{
    [datePickerControl setDateValue:[NSDate date]];
}


#pragma mark -
#pragma mark APPEARANCE

// -------------------------------------------------------------------------------
//	setDrawsBackground:sender:
//
//	The user checked/unchecked the "Draws Background" checkbox.
// -------------------------------------------------------------------------------
- (IBAction)setDrawsBackground:(id)sender
{
	NSButton *checkbox = sender;
	[datePickerControl setDrawsBackground: [checkbox state]];
}

// -------------------------------------------------------------------------------
//	setBackgroundColor:sender:
//
//	The user chose a different background color from the "Back Color" color well.
// -------------------------------------------------------------------------------
- (IBAction)setBackgroundColor:(id)sender
{
	NSColor *newColor = [sender color];
	[datePickerControl setBackgroundColor: newColor];
}

// -------------------------------------------------------------------------------
//	setTextColor:sender:
//
//	The user chose a different text color from the "Text Color" color well.
// -------------------------------------------------------------------------------
- (IBAction)setTextColor:(id)sender
{
	NSColor *newColor = [sender color];
	[datePickerControl setTextColor: newColor];
}

// -------------------------------------------------------------------------------
//	setBezeled:sender:
//
//	The user checked/unchecked the "Bezeled" checkbox.	
// -------------------------------------------------------------------------------
- (IBAction)setBezeled:(id)sender
{
	NSButton *checkbox = sender;
	[datePickerControl setBezeled: [checkbox state]];
}

// -------------------------------------------------------------------------------
//	setBordered:sender:
//
//	The user checked/unchecked the "Bordered" checkbox.	
// -------------------------------------------------------------------------------
- (IBAction)setBordered:(id)sender
{
	NSButton *checkbox = sender;
	[datePickerControl setBordered: [checkbox state]];
}


#pragma mark -
#pragma mark DATE TIME ELEMENTS

// date/time element popup selections:
enum
{
    kNSHourMinuteDatePickerElementFlag = 0,
	kNSHourMinuteSecondDatePickerElementFlag,
    kNSTimeZoneDatePickerElementFlag,

    kNSYearMonthDatePickerElementFlag = 0,
    kNSYearMonthDayDatePickerElementFlag,
    kNSEraDatePickerElementFlag
};

// -------------------------------------------------------------------------------
//	setDateElementFlags:sender:
//
//	The user checked/unchecked one of the "Date Element" checkboxes.
// -------------------------------------------------------------------------------
- (IBAction)setDateElementFlags:(id)sender
{
	int tag = [[sender selectedCell] tag];
	NSDatePickerElementFlags flags = [datePickerControl datePickerElements];
	
	BOOL checked = [[sender selectedCell] state];
	
	switch (tag)
	{
		case kNSYearMonthDatePickerElementFlag:
			if (checked)
				flags |= NSYearMonthDatePickerElementFlag;
			else
				flags ^= NSYearMonthDatePickerElementFlag;
            break;

		case kNSYearMonthDayDatePickerElementFlag:
			if (checked)
				flags |= NSYearMonthDayDatePickerElementFlag;
			else
				flags ^= NSYearMonthDayDatePickerElementFlag;
            break;

		case kNSEraDatePickerElementFlag:
			if (checked)
				flags |= NSEraDatePickerElementFlag;
			else
				flags ^= NSEraDatePickerElementFlag;
            
            break;
	}
	[datePickerControl setDatePickerElements: flags];
	
	[self updateControls];	// force update of all UI elements and the picker itself
}

// -------------------------------------------------------------------------------
//	setTimeElementFlags:sender:
//
//	The user checked/unchecked one of the "Time Element" checkboxes.
// -------------------------------------------------------------------------------
- (IBAction)setTimeElementFlags:(id)sender
{
	int tag = [[sender selectedCell] tag];
	NSDatePickerElementFlags flags = [datePickerControl datePickerElements];
	
	BOOL checked = [[sender selectedCell] state];
	
	switch (tag)
	{
		case kNSHourMinuteDatePickerElementFlag:
			if (checked)
				flags |= NSHourMinuteDatePickerElementFlag;
			else
				flags ^= NSHourMinuteDatePickerElementFlag;
			break;
			
		case kNSHourMinuteSecondDatePickerElementFlag:
			if (checked)
				flags |= NSHourMinuteSecondDatePickerElementFlag;
			else
				flags ^= NSHourMinuteSecondDatePickerElementFlag;
			break;
			
		case kNSTimeZoneDatePickerElementFlag:
			if (checked)
				flags |= NSTimeZoneDatePickerElementFlag;
			else
				flags ^= NSTimeZoneDatePickerElementFlag;
			break;
	}
	[datePickerControl setDatePickerElements: flags];
	
	[self updateControls];	// force update of all UI elements and the picker itself
}

// -------------------------------------------------------------------------------
//	updateDateTimeElementFlags:
//
//  Updates our checkboxes to reflect the current control flags
// -------------------------------------------------------------------------------
- (void)updateDateTimeElementFlags
{
	NSDatePickerElementFlags elementFlags = [datePickerControl datePickerElements];
    
	// time elements
	if ((elementFlags & NSHourMinuteDatePickerElementFlag) != 0)
		[timeElementChecks selectCellWithTag: kNSHourMinuteDatePickerElementFlag];
	if ((elementFlags & NSHourMinuteSecondDatePickerElementFlag) != 0)
		[timeElementChecks selectCellWithTag: kNSHourMinuteSecondDatePickerElementFlag];
	if ((elementFlags & NSTimeZoneDatePickerElementFlag) != 0)
		[timeElementChecks selectCellWithTag: kNSTimeZoneDatePickerElementFlag];
	
	// date elements
	if ((elementFlags & NSYearMonthDatePickerElementFlag) != 0)
		[dateElementChecks selectCellWithTag: kNSYearMonthDatePickerElementFlag];
	if ((elementFlags & NSYearMonthDayDatePickerElementFlag) != 0)
		[dateElementChecks selectCellWithTag: kNSYearMonthDayDatePickerElementFlag];
	if ((elementFlags & NSEraDatePickerElementFlag) != 0)
		[dateElementChecks selectCellWithTag: kNSEraDatePickerElementFlag];
}


#pragma mark -
#pragma mark PICKER MIN MAX DATE

// -------------------------------------------------------------------------------
//	setMinDate:sender:
//
//	User wants to set the minimum date for the picker.
// -------------------------------------------------------------------------------
- (IBAction)setMinDate:(id)sender
{
	[datePickerControl setMinDate: [minDatePicker dateValue]];	
}

// -------------------------------------------------------------------------------
//	setMaxDate:sender:
//
//	User wants to set the maximum date for the picker.
// -------------------------------------------------------------------------------
- (IBAction)setMaxDate:(id)sender
{
	[datePickerControl setMaxDate: [maxDatePicker dateValue]];
}


#pragma mark -
#pragma mark PICKER MODE

enum
{
	kSingleDateMode = 0,
	kRangeDateMode
};

// -------------------------------------------------------------------------------
//	setDatePickerMode:sender:
//
//	User wants to change the "Date Picker Mode".
// -------------------------------------------------------------------------------
- (IBAction)setDatePickerMode:(id)sender
{
	switch ([[sender selectedCell] tag])
	{
		case kSingleDateMode:
		{
			[datePickerControl setDatePickerMode:NSSingleDateMode];
            break;
		}
		case kRangeDateMode:
		{
			[datePickerControl setDatePickerMode:NSRangeDateMode];
			break;
		}
	}
	
	[self updateControls];	// force update of all UI elements and the picker itself
}

// -------------------------------------------------------------------------------
//	updateDatePickerMode:
//
//	Used to update the NSDatePicker's NSDatePickerMode attributes.
// -------------------------------------------------------------------------------
-(void)updateDatePickerMode
{
	NSDatePickerMode mode = [datePickerControl datePickerMode];
	switch (mode)
	{
		case NSSingleDateMode:
		{
			[datePickerModeRadios selectCellWithTag: 0];
			
			// interval value not applicable:
			[secondsRangeEdit setEnabled: NO];
			[secondsRangeEditLabel setTextColor: [NSColor lightGrayColor]];
			
			[datePickerControl setTimeInterval: 0];
			break;
		}
			
		case NSRangeDateMode:
		{
			[datePickerModeRadios selectCellWithTag: 1];
            
            if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_5)
            {
                // interval value applies:
                [secondsRangeEdit setEnabled: YES];
                [secondsRangeEditLabel setTextColor: [NSColor blackColor]];
                
                // set the date range by start date (here we use the current date in the date picker control), and time interval (in seconds)
                NSString* secsStr = [secondsRangeEdit stringValue];
                int numSeconds = [secsStr intValue];
                [datePickerControl setTimeInterval: numSeconds];
            }
			break;
		}
	}
}

// -------------------------------------------------------------------------------
//	textDidEndEditing:notification
//
//	The user finished editing the time interval (in seconds).
//
//	This controller is a delegate to the NSTextField: number of seconds (for the date range),
//	so here we get notified when the user has finished editing the seconds range,
//	then we update the date picker control.
//
//
//	NOTE: don't use "textDidEndEditing" because NSTextField is not NSText, rather is a subclass
//	of NSControl, so use the delegate methods from NSControl.
// -------------------------------------------------------------------------------
-(void)controlTextDidEndEditing:(NSNotification *)notification
{
	[self updateDatePickerMode];	// force update of the date picker control
}

@end
