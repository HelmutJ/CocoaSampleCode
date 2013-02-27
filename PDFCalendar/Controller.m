/*

File: Controller.m

Abstract: <Description, Points of interest, Algorithm approach>

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 

// =====================================================================================================================
//  Controller.m
// =====================================================================================================================


#import "Controller.h"
#import "CalendarPage.h"


@implementation Controller
// ========================================================================================================== Controller
// -------------------------------------------------------------------------------------------------------- awakeFromNib

- (void) awakeFromNib
{
	// Bring up window.
	[_chooseWindow makeKeyAndOrderFront: self];
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Release.
	[_calendarPDF release];
	
	// Super.
	[super dealloc];
}

// ---------------------------------------------------------------------------------------------------------- imageAdded

- (void) imageAdded: (id) sender
{
}

// -------------------------------------------------------------------------------------------------------- makeCalendar

- (void) makeCalendar: (id) sender
{
	NSImage			*image;
	CalendarPage	*page;
	
	// Start with an empty PDFDocument.
	_calendarPDF = [[PDFDocument alloc] init];
	
	// Create January.
	// Get image.
	image = [_image0 image];
	
	// Create our custom PDFPage subclass (pass it an image and the month it is to represent).
	page = [[CalendarPage alloc] initWithImage: image month: 1];
	
	// Insert the new page in our PDF document.
	[_calendarPDF insertPage: page atIndex: 0];
	
	// Release since the document retains.
	[page release];

	// Create February.
	if ([_image1 image])
		image = [_image1 image];
	page = [[CalendarPage alloc] initWithImage: image month: 2];
	[_calendarPDF insertPage: page atIndex: 1];
	[page release];
	
	// Create March.
	if ([_image2 image])
		image = [_image2 image];
	page = [[CalendarPage alloc] initWithImage: image month: 3];
	[_calendarPDF insertPage: page atIndex: 2];
	[page release];
	
	// Create April.
	if ([_image3 image])
		image = [_image3 image];
	page = [[CalendarPage alloc] initWithImage: image month: 4];
	[_calendarPDF insertPage: page atIndex: 3];
	[page release];
	
	// Create May.
	if ([_image4 image])
		image = [_image4 image];
	page = [[CalendarPage alloc] initWithImage: image month: 5];
	[_calendarPDF insertPage: page atIndex: 4];
	[page release];
	
	// Create June.
	if ([_image5 image])
		image = [_image5 image];
	page = [[CalendarPage alloc] initWithImage: image month: 6];
	[_calendarPDF insertPage: page atIndex: 5];
	[page release];
	
	// Create July.
	if ([_image6 image])
		image = [_image6 image];
	page = [[CalendarPage alloc] initWithImage: image month: 7];
	[_calendarPDF insertPage: page atIndex: 6];
	[page release];
	
	// Create August.
	if ([_image7 image])
		image = [_image7 image];
	page = [[CalendarPage alloc] initWithImage: image month: 8];
	[_calendarPDF insertPage: page atIndex: 7];
	[page release];
	
	// Create September.
	if ([_image8 image])
		image = [_image8 image];
	page = [[CalendarPage alloc] initWithImage: image month: 9];
	[_calendarPDF insertPage: page atIndex: 8];
	[page release];
	
	// Create October.
	if ([_image9 image])
		image = [_image9 image];
	page = [[CalendarPage alloc] initWithImage: image month: 10];
	[_calendarPDF insertPage: page atIndex: 9];
	[page release];
	
	// Create November.
	if ([_image10 image])
		image = [_image10 image];
	page = [[CalendarPage alloc] initWithImage: image month: 11];
	[_calendarPDF insertPage: page atIndex: 10];
	[page release];
	
	// Create December.
	if ([_image11 image])
		image = [_image11 image];
	page = [[CalendarPage alloc] initWithImage: image month: 12];
	[_calendarPDF insertPage: page atIndex: 11];
	[page release];
	
	// Assign PDFDocument ot PDFView.
	[_pdfView setDocument: _calendarPDF];
	
	// Goodbye to the choose window.
	[_chooseWindow orderOut: self];
	
	// Open calendar window.
	[_pdfWindow makeKeyAndOrderFront: self];
}

// ------------------------------------------------------------------------------------------------------ saveCalendarAs

- (void) saveCalendarAs: (id) sender
{
	NSSavePanel	*savePanel;
	
	// Create save panel, require PDF.
	savePanel = [NSSavePanel savePanel];
	[savePanel setRequiredFileType: @"pdf"];
	
	// Run save panel — write PDF document to resulting URL.
	if ([savePanel runModal] == NSFileHandlingPanelOKButton)
		[_calendarPDF writeToURL: [savePanel URL]];
}

@end
