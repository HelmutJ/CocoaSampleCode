/*
	    File: AppController.m
	Abstract: n/a
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
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

#import "AppController.h"

/* APPLICATION DATA STORAGE NOTES:
- This application uses a simple data storage as an array of entries, each containing two attributes: a label and a value
- The array is represented as a NSMutableArray, the entries as NSMutableDictionaries, the label as a NSString with the "label" key and the value as a NSNumber with the "value" key
*/

/* QUARTZ COMPOSER COMPOSITION NOTES:
- The enclosed Quartz Composer composition renders a 3D bars chart and is loaded on the QCView in the application's window
- This composition has three input parameters:
	* "Data": the data to display by the chart which must be formatted as a NSArray of NSDictionaries, each NSDictionary containing "label" / NSString and "value" / NSNumber value-key pairs
	* "Scale": a NSNumber used to scale the chart bars
	* "Spacing": a NSNumber indicating the extra spacing between the chart bars
- The "Data" and "Scale" input parameters are set programmatically while the "Spacing" is set directly from the UI through Cocoa bindings
- Note that this composition is quite simple and has the following limitations:
	* it may have rendering artifacts when looking at the chart from some angles
	* it does not support negative values
	* labels are not truncated if too long
- Basically, the composition performs the following:
	* renders a background gradient
	* draws three planes on the X, Y and Z axes
	* uses an Iterator patch to loop on the chart data, which is available as a Structure, and for each member, retrieves the label and value, then draws them
	* the chart rendering is enclosed into a Camera macro patch used to center it in the view
	* the Camera macro patch is itself enclosed into a TrackBall macro patch so that the user can rotate the chart with the mouse
	* the TrackBall macro patch is itself enclosed into a Lighting macro patch so that the chart is lighted
- This composition makes uses of transparency for a nicer effect, but neither OpenGL nor Quartz Composer handle automatically proper rendering of mixed opaque and transparent 3D objects
- A simple, but not fail-proof, algorithm to render opaque and transparent 3D objects is to: 
	* render opaque objects first with depth testing set to "Read / Write"
	* render transparent objects with depth testing set to "Read-Only"
*/

/* NIB FILES NOTES:
- The QCView is configured to start rendering automatically and forward user events (mouse events are required to rotate the chart)
- An AppController instance is connected as the data source for the NSTableView
- The NSTableView is set up so that the identifiers of table columns match the keys used in the data storage
- The "Value" column of the NSTableView has a NSNumberFormatter which guarantees only positive or null numbers can be entered here
- The "Label" column of the NSTableView simply contains text
*/

/* Keys for the entries in the data storage */
#define kDataKey_Label			@"label" //NSString
#define kDataKey_Value			@"value" //NSNumber

/* Keys for the composition input parameters */
#define kParameterKey_Data		@"Data" //NSArray of NSDictionaries
#define kParameterKey_Scale		@"Scale" //NSNumber
#define kParameterKey_Spacing	@"Spacing" //NSNumber

@implementation AppController

- (id) init
{
	//Allocate our data storage
	if(self = [super init])
	_data = [NSMutableArray new];
	
	return self;
}

- (void) dealloc
{
	//Release our data storage
	[_data release];
	[super dealloc];
}

- (void) awakeFromNib
{
	//Load the composition file into the QCView (because this QCView is bound to a QCPatchController in the nib file, this will actually update the QCPatchController along with all the bindings)
	if(![view loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"Chart" ofType:@"qtz"]]) {
		NSLog(@"Composition loading failed");
		[NSApp terminate:nil];
	}
	
	//Populate data storage
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Palo Alto",kDataKey_Label,[NSNumber numberWithInt:2],kDataKey_Value,nil]];
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Cupertino",kDataKey_Label,[NSNumber numberWithInt:1],kDataKey_Value,nil]];
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Menlo Park",kDataKey_Label,[NSNumber numberWithInt:4],kDataKey_Value,nil]];
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Mountain View",kDataKey_Label,[NSNumber numberWithInt:8],kDataKey_Value,nil]];
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"San Francisco",kDataKey_Label,[NSNumber numberWithInt:7],kDataKey_Value,nil]];
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Los Altos",kDataKey_Label,[NSNumber numberWithInt:3],kDataKey_Value,nil]];
	
	//Initialize the views
	[tableView reloadData];
	[self updateChart];
}

- (void) updateChart
{
	float					max,
							value;
	unsigned				i;
	
	//Update the data displayed by the chart - it will be converted to a Structure of Structures by Quartz Composer
	[view setValue:_data forInputKey:kParameterKey_Data];
	
	//Compute the maximum value and set the chart scale accordingly
	max = 0.0;
	for(i = 0; i < [_data count]; ++i) {
		value = [(NSNumber*)[(NSDictionary*)[_data objectAtIndex:i] objectForKey:kDataKey_Value] floatValue];
		if(value > max)
		max = value;
	}
	[view setValue:[NSNumber numberWithFloat:(max > 0.0 ? 1.0 / max : 1.0)] forInputKey:kParameterKey_Scale];
}

@end

@implementation AppController (IBActions)

- (IBAction) addEntry:(id)sender
{
	//Add a new entry to the data storage
	[_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Untitled",kDataKey_Label,[NSNumber numberWithInt:0],kDataKey_Value,nil]];
	
	//Notify the NSTableView and update the chart
	[tableView reloadData];
	[self updateChart];
	
	//Automatically select and edit the new entry
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:([_data count] - 1)] byExtendingSelection:NO];
	[tableView editColumn:[tableView columnWithIdentifier:kDataKey_Label] row:([_data count] - 1) withEvent:nil select:YES];
}

- (IBAction) removeEntry:(id)sender
{
	int					selectedRow;
	
	//Make sure we have a valid selected row
	selectedRow = [tableView selectedRow];
	if((selectedRow < 0) || ([tableView editedRow] == selectedRow))
	return;
	
	//Remove the currently selected entry from the data storage
	[_data removeObjectAtIndex:selectedRow];
	
	//Notify the NSTableView and update the chart
	[tableView reloadData];
	[self updateChart];
}

@end

@implementation AppController (NSTableDataSource)
 
- (int) numberOfRowsInTableView:(NSTableView*)aTableView
{
	//Return the number of entries in the data storage
	return [_data count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex 
{
	//Get the "label" or "value" attribute of the entry from the data storage at index "rowIndex"
	return [(NSDictionary*)[_data objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex 
{
	//Set the "label" or "value" attribute of the entry from the data storage at index "rowIndex"
	[(NSMutableDictionary*)[_data objectAtIndex:rowIndex] setObject:anObject forKey:[aTableColumn identifier]];
	
	//Update the chart
	[self updateChart];
}

@end
