/*

File: MyWindowController.m

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
//  MyWindowController.m
// =====================================================================================================================


#import "AnnotationPanel.h"
#import "MyWindowController.h"
#import "PDFViewEdit.h"


@implementation MyWindowController
// ================================================================================================== MyWindowController
// ------------------------------------------------------------------------------------------------------- windowDidLoad

- (void) windowDidLoad
{
	PDFDocument		*pdfDoc;
	AnnotationPanel	*annotPanel;
	
	// Create PDFDocument.
	pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: [[self document] fileName]]];
	
	// Set document.
	[_pdfView setDocument: pdfDoc];
	[pdfDoc release];
	
	// Default display mode.
	[_pdfView setAutoScales: YES];
	
	// Indicate edit mode.
	[_pdfView setEditMode: ([_editTestButton selectedSegment] == 0)];
	
	// Establish notifications for this document.
	[self setupDocumentNotifications];
	
	// Bring up annotation panel.
	annotPanel = [AnnotationPanel sharedAnnotationPanel];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(annotationChanged:) 
			name: AnnotationPanelAnnotationDidChangeNotification object: annotPanel];
}

// ------------------------------------------------------------------------------------------ setupDocumentNotifications

- (void) setupDocumentNotifications
{
	// Document saving progress notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentBeginWrite:) 
			name: @"PDFDidBeginDocumentWrite" object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndWrite:) 
			name: @"PDFDidEndDocumentWrite" object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndPageWrite:) 
			name: @"PDFDidEndPageWrite" object: [_pdfView document]];
	
	// Delegate.
	[[_pdfView document] setDelegate: self];
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	// Call super.
	[super dealloc];
}

#pragma mark -------- actions
// ----------------------------------------------------------------------------------------------------- setEditTestMode

- (void) setEditTestMode: (id) sender;
{
	// Tell our PDFView sublclass what mode it is in.
	[_pdfView setEditMode: ([(NSSegmentedControl *)sender selectedSegment] == 0)];
}

#pragma mark -------- annotation panel notification
// --------------------------------------------------------------------------------------------------- annotationChanged

- (void) annotationChanged: (NSNotification *) notification
{
	// Lazy.
	[_pdfView setNeedsDisplay: YES];
	
	// Tell our subclass about the annotation change.
	[_pdfView annotationChanged];
}

#pragma mark -------- save progress
// -------------------------------------------------------------------------------------------------- documentBeginWrite

- (void) documentBeginWrite: (NSNotification *) notification
{
	// Establish maximum and current value for progress bar.
	[_saveProgressBar setMaxValue: (double)[[_pdfView document] pageCount]];
	[_saveProgressBar setDoubleValue: 0.0];
	
	// Bring up the save panel as a sheet.
	[NSApp beginSheet: _saveWindow modalForWindow: [self window] modalDelegate: self 
			didEndSelector: @selector(saveProgressSheetDidEnd: returnCode: contextInfo:) contextInfo: NULL];
}

// ---------------------------------------------------------------------------------------------------- documentEndWrite

- (void) documentEndWrite: (NSNotification *) notification
{
	[NSApp endSheet: _saveWindow];
}

// ------------------------------------------------------------------------------------------------ documentEndPageWrite

- (void) documentEndPageWrite: (NSNotification *) notification
{
	[_saveProgressBar setDoubleValue: [[[notification userInfo] objectForKey: @"PDFDocumentPageIndex"] floatValue]];
	[_saveProgressBar displayIfNeeded];
}

// --------------------------------------------------------------------------------------------- saveProgressSheetDidEnd

- (void) saveProgressSheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
	[_saveWindow close];
}

@end
