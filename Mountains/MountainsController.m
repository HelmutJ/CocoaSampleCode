/*
 
 File:		MountainsController.m
 
 Abstract:	Demonstrates internationalization and localization APIs
 
 Version:	1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2008-2011 Apple Inc. All Rights Reserved.
 
 */

#import "Mountain.h"
#import "MountainsController.h"

// These are the indices in our calendar override popup for the
//	various calendars
enum {
	kGregorianCalendarItem = 2,
	kBuddhistCalendarItem = 3,
	kHebrewCalendarItem = 4,
	kIslamicCalendarItem = 5,
	kIslamicCivilCalendarItem = 6,
	kJapaneseCalendarItem = 7
};

@interface MountainsController (PrivateFunctions)

// A convenience function, since NSLocale doesn't provide this for us
- (NSLocale*)localeLanguageComboWithCalendar;

// Either the locale's calendar or the override set by the user
- (NSCalendar *)calendar;

// This is the array of mountain data we get from our localized plists
//	The sorted version is a convenience function used for display in 
//	our table view
- (NSArray *)mountains;
- (NSArray *)sortedMountains;

// Reset the user-visible items appropriately
- (void)resetSentence;
- (void)resetAll;
- (void)updateDatePicker:(NSTimer*)timer;

// Convenience functions to get localized strings for actual
//	display of the non-string data in the Mountain class
- (NSString*)heightAsString:(NSNumber*)heightNumber;
- (NSString*)dateAsString:(NSDate*)rawDate;

@end

@implementation MountainsController

- (id)init
{
	self = [ super init ];
	if ( self != nil ) {
		// We want to know when the table selection changes (so we can update the sentence view)
		//	and when the locale changes (so we can update everything)
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(localeChanged:) name:NSCurrentLocaleDidChangeNotification object:nil ];
        
        // We don't need to explicitly set our data members to nil; that happens automatically 
		//  _timer = nil;
		//  _mountains = nil;
	}
	return self;
}


- (void)dealloc
{
	// Don't need to be notified anymore
	[ [ NSNotificationCenter defaultCenter ] removeObserver:self ];

	// Don't need our timer anymore
	if ( _timer != nil ) {
		[ _timer invalidate ];
		[ _timer release ];
	}
    
    [ _mountains release ];

	// Never forget this!
	[ super dealloc ];
}


// This gets called when the nib has been fully loaded and all the 
//	connections set up
- (void)awakeFromNib
{
	[ self resetSentence ];
	
	// Adjust the size of the text in the table view for easier viewing
	[ summaryTable setRowHeight:( [ summaryTable rowHeight ] * 18.0 / [ NSFont systemFontSize ] ) ];
	NSFont *font = [ NSFont systemFontOfSize:18.0 ];
	for ( NSTableColumn *column in [ summaryTable tableColumns ] ) {
		NSCell *cell = [ column dataCell ];
		if ( [ cell isKindOfClass:[ NSCell class ] ] && [ cell type ] == NSTextCellType ) {
			[ cell setFont:font ];
		}
	}

	// Now that summaryTable is available, we can start getting notifications about it
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(tableSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:summaryTable ];

	// We use a timer so that our date-picker (which shows the time)
	//	updates every second
	_timer = [ [ NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDatePicker:) userInfo:nil repeats:YES ] retain ];
	[ self updateDatePicker:_timer ];
	 
}

// Our popup calls this to override the selected calendar
- (IBAction)changeCalendar:(id)sender
{
	[ self resetAll ];
}

// Table view data source functions
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [ [ self mountains ] count ];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id returnValue = @"";
	Mountain *mountain = [ [ self sortedMountains ] objectAtIndex:rowIndex ];
	NSString *columnID = [ aTableColumn identifier ];
	if ( [ columnID isEqualToString:kMountainNameString ] ) {
		returnValue = [ [ mountain name ] capitalizedString ];
	}
	else if ( [ columnID isEqualToString:kMountainHeightString ] ) {
		returnValue = [ self heightAsString:[ mountain height ] ];
	}
	else if ( [ columnID isEqualToString:kMountainClimbedDateString ] ) {
		returnValue = [ self dateAsString:[ mountain climbedDate ] ];
	}
	return returnValue;
}

// When the table view sorting changes, the selected row doesn't, so we
//	have to reset our sentence display to match the new data on that row
- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	[ self resetSentence ];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[ aTableView reloadData ];
}

// Notification target functions
- (void)tableSelectionChanged:(id)notification
{
	[ self resetSentence ];
}

- (void)localeChanged:(id)notification
{
	
	NSLocale *locale = [ self localeLanguageComboWithCalendar ];
	NSLog( @"The locale has changed, the new calendar identifier is %@", [ locale displayNameForKey:NSLocaleCalendar value:[ [ self calendar ] calendarIdentifier ] ] );
	NSLog( @"The new calendar is %@", [ locale displayNameForKey:NSLocaleCalendar value:[ self calendar ] ] );

	[ self resetAll ];
}

// NSApp delegate method
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end

@implementation MountainsController (PrivateFunctions)

// We don't cache this
- (NSCalendar *)calendar
{
	NSCalendar *returnValue = nil;
	// We rely on the fact that all the localizations use the same popup for overriding
	//	the calendar setting
	switch ( [ calendarPopup indexOfSelectedItem ] ) {
		case kGregorianCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSGregorianCalendar ] autorelease ];
			break;
		case kBuddhistCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSBuddhistCalendar ] autorelease ];
			break;
		case kHebrewCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSHebrewCalendar ] autorelease ];
			break;
		case kIslamicCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSIslamicCalendar ] autorelease ];
			break;
		case kIslamicCivilCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSIslamicCivilCalendar ] autorelease ];
			break;
		case kJapaneseCalendarItem:
			returnValue = [ [ [ NSCalendar alloc ] initWithCalendarIdentifier:NSJapaneseCalendar ] autorelease ];
			break;
		default:
			// Always include an explicit default case in a switch statement...
			break;
			
	}	
	return returnValue;
	
}

// Our array of Mountain data
//	We allocate this lazily, waiting until we need it before we read it in
- (NSArray *)mountains
{
	if ( _mountains == nil ) {
		// Get the correct, localized version of the data file
		NSString *path = [ [ NSBundle mainBundle ] pathForResource:@"Mountains" ofType:@"plist" ];
		NSArray *mountainList = ( path != nil ? [ NSArray arrayWithContentsOfFile:path ] : nil );
		NSMutableArray *array = [ NSMutableArray arrayWithCapacity:( mountainList != nil ? [ mountainList count ] : 0 ) ];
		for ( NSDictionary *mountainDict in mountainList ) {
			// Create a Mountain object from each entry in the plist and add it
			[ array addObject:[ Mountain mountainWithDictionary:mountainDict ] ];
		}
		// Just to be perverse, we copy our mutable array rather than keeping it
		//	but not using its mutability
		_mountains = [ [ NSArray alloc ] initWithArray:array ];
	}
	return _mountains;
}


// Our array of mountains sorted per the table view's descriptors
- (NSArray*)sortedMountains
{
	return [ [ self mountains ] sortedArrayUsingDescriptors:[ summaryTable sortDescriptors ] ];
}

// Reset the text field with a sentence for the currently selected mountain
// This is localized, and two versions are used since not all mountains have
//	a climbed date available
- (void)resetSentence
{
	NSString *sentence = @"";
	NSString *format;
	if ( [ summaryTable selectedRow ] != -1 ) {
		Mountain *mountain = (Mountain *) [ [ self sortedMountains ] objectAtIndex:[ summaryTable selectedRow ] ];
		if ( mountain.climbedDate != nil ) {
			format = NSLocalizedStringFromTable( @"sentenceFormat", @"Mountains", @"A sentence with the mountain's name (first parameter), height (second parameter), and climbed date (third parameter)" );
			sentence = [ NSString stringWithFormat:format, mountain.name, [ self heightAsString:mountain.height ], [ self dateAsString:mountain.climbedDate ] ];
		}
		else {
			format = NSLocalizedStringFromTable( @"undatedSentenceFormat", @"Mountains", @"A sentence with the mountain's name (first parameter), and height (second parameter), but no climbed date" );
			sentence = [ NSString stringWithFormat:format, mountain.name, [ self heightAsString:mountain.height ] ];
		}
	}
	[ sentenceText setStringValue:sentence ];
}

// Update all our UI elements
- (void)resetAll
{
	[ self resetSentence ];
	[ summaryTable reloadData ];
	[ self updateDatePicker:_timer ];
}

// Make sure our date picker gets the correct, localized calendar
- (void)updateDatePicker:(NSTimer*)timer
{
	[ datePicker setLocale:[ self localeLanguageComboWithCalendar ] ];
	[ datePicker setCalendar:[ self calendar ] ];
	[ datePicker setDateValue:[ NSDate date ] ];
	
}

// We want a single string expressing a mountain's height
// We need to allow for the possibility that the user is using either metric
//	or non-metric units.  If the units are non-metric, we need to do the
//	conversion ourselves
- (NSString*)heightAsString:(NSNumber*)heightNumber
{
	NSString *returnValue = @"";
	if ( heightNumber != nil ) {
		NSString *format = @"%d";
		NSInteger height = [ heightNumber integerValue ];
		NSNumber *usesMetricSystem = [ [ NSLocale autoupdatingCurrentLocale ] objectForKey:NSLocaleUsesMetricSystem ];
		if ( usesMetricSystem != nil && ![ usesMetricSystem boolValue ] ) {
			// Convert the height to feet
			height = (int) ( (float) height * 3.280839895 );
			format = NSLocalizedStringFromTable( @"footFormat", @"Mountains", @"Use to express a height in feet" );
		} 
		else {
			format = NSLocalizedStringFromTable( @"meterFormat", @"Mountains", @"Use to express a height in meters" );
		}
		
		NSNumberFormatter *formatter = [ [ NSNumberFormatter alloc ] init ];
		[ formatter setNumberStyle:NSNumberFormatterDecimalStyle ];
		
		returnValue = [ NSString stringWithFormat:format, [ formatter stringFromNumber:[ NSNumber numberWithInteger:height ] ] ];
        
        [ formatter release ];
	}
	return returnValue;
}

// A single string expressing a mountain's climbed date, properly localized
- (NSString*)dateAsString:(NSDate*)date
{
	NSString *returnValue = @"";
	if ( date != nil ) {
		NSDateFormatter *formatter = [ [ NSDateFormatter alloc ] init ];
		[ formatter setDateStyle:NSDateFormatterMediumStyle ];
		[ formatter setTimeStyle:NSDateFormatterNoStyle ];
		[ formatter setLocale:[ self localeLanguageComboWithCalendar ] ];
		returnValue = [ formatter stringFromDate:date ];
        [ formatter release ];
	}
	// We leave this in just to demonstrate that descriptionWithLocale does the right thing
	NSLog( @"%@ => %@", [ date descriptionWithLocale:[ self localeLanguageComboWithCalendar ] ], returnValue );
	return returnValue;
}

// A convenience function, since NSLocale doesn't provide this for us
- (NSLocale*)localeLanguageComboWithCalendar
{
	// This is tricky.  We need to create a new locale, one which is identical to the
	//	current locale except that we explicitly override the language and calendar.  We can then
	//	use this new locale to create a date formatter, which will then
	//	generate the proper date for us, as well as other objects
	
	NSCalendar *calendar = [ self calendar ];
	NSArray *languages = [ NSLocale preferredLanguages ];
	NSString *languageIdentifier = ( languages != nil ? [ languages objectAtIndex:0 ] : nil );
	NSString *localeLanguage = [ [ NSLocale autoupdatingCurrentLocale ] objectForKey:NSLocaleLanguageCode ];
	NSString *localeIdentifier = [ [ NSLocale autoupdatingCurrentLocale ] localeIdentifier ];
	NSString *newLocaleIdentifier = localeIdentifier;
	
	if ( languageIdentifier != nil && localeLanguage != nil && ![ languageIdentifier isEqualToString:localeLanguage ] ) {
		newLocaleIdentifier = [ NSString stringWithFormat:@"%@-%@", languageIdentifier, localeIdentifier ];
	}
	if ( calendar != nil ) {
		NSString *calendarIdentifier = [ calendar calendarIdentifier ];
		newLocaleIdentifier = [ NSLocale canonicalLocaleIdentifierFromString:[ NSString stringWithFormat:@"%@@calendar=%@", newLocaleIdentifier, calendarIdentifier ] ];		
	}
	NSLocale *returnValue = [ [ [ NSLocale alloc ] initWithLocaleIdentifier:newLocaleIdentifier ] autorelease ];
	return returnValue;
}

@end
