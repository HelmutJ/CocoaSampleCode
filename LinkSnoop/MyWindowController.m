// ======================================================================================================================
//  MyWindowController.m
// ======================================================================================================================


#import "LinkData.h"
#import "MyWindowController.h"


#define kHorizontalWindowPadding		80.0
#define kVerticalWindowPadding			120.0


@implementation MyWindowController
// =================================================================================================== MyWindowController
// -------------------------------------------------------------------------------------------------------- windowDidLoad

- (void) windowDidLoad
{
	PDFDocument	*pdfDoc;
	NSRect		visibleScreen;
	NSSize		windowSize;
	
	// Create PDFDocument.
	pdfDoc = [[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: [[self document] fileName]]];
	
	// Set document.
	[_pdfView setDocument: pdfDoc];
	[pdfDoc release];
	
	// Default display mode.
	[_pdfView setAutoScales: YES];
	[_pdfView setDisplaysPageBreaks: NO];
	
	// How big to create the window?
	// Visible frame for main screen.
	visibleScreen = [[NSScreen mainScreen] visibleFrame];
	
	// Taking into account the toolbars, etc. in the UI.
	windowSize.width = visibleScreen.size.width - kHorizontalWindowPadding;
	windowSize.height = visibleScreen.size.height - kVerticalWindowPadding;
	
	// Set the window size.
	[[self window] setContentSize: windowSize];
	
	// Clear count field.
	[_linkCount setStringValue: @""];
}

// -------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Clean up instance var.
	[_linkList release];
	
	// Call super.
	[super dealloc];
}

// ---------------------------------------------------------------------------------------------------- beginScanForLinks

- (void) beginScanForLinks
{
	_linkList = [[NSMutableArray alloc] initWithCapacity: 10];
	_scanPageIndex = 0;
	
	// Start number of links at zero.
	[_linkCount setStringValue: [NSString stringWithFormat: 
			NSLocalizedString(@"Number of URL links found: %d", NULL), 0]];
	
	// Listen for these (we'll post).
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(scheduledScanPage:) 
			name: @"scanPageForLinks" object: self];
	
	// Schedule a notification to begin the scan.
	// This is a way to allow user interaction while the PDF is being processed without using a seperate thread.
	// You don't want to be accessing a PDFDocument from two seperate threads.
	[[NSNotificationQueue defaultQueue] enqueueNotification: [NSNotification notificationWithName: 
			@"scanPageForLinks" object: self] postingStyle: NSPostWhenIdle];
}

// ---------------------------------------------------------------------------------------------------- scheduledScanPage

- (void) scheduledScanPage: (NSNotification *) notification
{
	PDFPage		*page;
	NSArray		*annotations;
	BOOL		foundLink = NO;
	
	// Get the page to scan for annotations.
	page = [[_pdfView document] pageAtIndex: _scanPageIndex];
	
	// Get page annotations (if any).
	annotations = [page annotations];
	if ((annotations != NULL) && ([annotations count] > 0))
	{
		unsigned int	count;
		unsigned int	i;
		
		// Walk annotations looking for links.
		count = [annotations count];
		for (i = 0; i < count; i++)
		{
			PDFAnnotation	*oneAnnotation;
			
			// Link must have a URL associated with it.
			oneAnnotation = [annotations objectAtIndex: i];
			if (([[oneAnnotation type] isEqualToString: @"Link"]) && 
					([(PDFAnnotationLink *)oneAnnotation URL] != NULL))
			{
				LinkData	*linkDatum;
				
				// Wrap in "LinkData" object and add to array.
				linkDatum = [[LinkData alloc] initWithAnnotation: oneAnnotation];
				[_linkList addObject: linkDatum];
				[linkDatum release];
				
				// Indicate at least one link found for this page.
				foundLink = YES;
			}
		}
	}
	
	if (foundLink)
	{
		// reflect current number of links found.
		[_linkCount setStringValue: [NSString stringWithFormat: 
				NSLocalizedString(@"Number of URL links found: %d", NULL), [_linkList count]]];
		
		// Update the table view after every page scanned where a link was found.
		[_linksTable reloadData];
	}
	
	// Increment page index.
	_scanPageIndex = _scanPageIndex + 1;
	
	// Are we at the end of the document?
	if (_scanPageIndex < [[_pdfView document] pageCount])
	{
		// Schedule a notification again in order to process the next page.
		[[NSNotificationQueue defaultQueue] enqueueNotification: [NSNotification notificationWithName: 
				@"scanPageForLinks" object: self] postingStyle: NSPostWhenIdle];
	}
	else
	{
		// Done.
	}
}

// ----------------------------------------------------------------------------------------------------- activeAnnotation

- (PDFAnnotation *) activeAnnotation
{
	// For our purposes, the "active annotation" is the one corresponding to the selected row in the links table.
	if ((_linkList != NULL) && ([_linksTable selectedRow] >= 0))
		return ([(LinkData *)[_linkList objectAtIndex: [_linksTable selectedRow]] annotation]);
	else
		return NULL;
}

#pragma mark -------- NSTableView delegate methods
// ---------------------------------------------------------------------------------------------- numberOfRowsInTableView

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	// Lazily....
	if (_linkList == NULL)
	{
		// Start to scan for links when the table view is queried for data.
		[self beginScanForLinks];
		return 0;
	}
	else
	{
		// If we have begun (or completed) the scan, return the count.
		return [_linkList count];
	}
}

// ------------------------------------------------------------------------------ tableView:objectValueForTableColumn:row

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) theColumn row: (int) rowIndex
{
	// Retrieve data as requested.
	if ([[theColumn identifier] isEqualToString: @"Text"])
		return ([(LinkData *)[_linkList objectAtIndex: rowIndex] text]);
	else if ([[theColumn identifier] isEqualToString: @"URL"])
		return ([[(PDFAnnotationLink *)[(LinkData *)[_linkList objectAtIndex: rowIndex] annotation] URL] absoluteString]);
	else
		return NULL;
}

// ------------------------------------------------------------------------------------------ tableViewSelectionDidChange

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	int			rowIndex;
	
	// What was selected. Skip out if the row has not changed.
	rowIndex = [(NSTableView *)[notification object] selectedRow];
	if (rowIndex >= 0)
	{
		PDFAnnotation	*annotation;
		NSRect			annotationBounds;
		
		// The annotation.
		annotation = [(LinkData *)[_linkList objectAtIndex: rowIndex] annotation];
		
		// The annotation bounds in "view-space".
		annotationBounds = [_pdfView convertRect: [annotation bounds] fromPage: [annotation page]];
		
		// If not visible, go there.
		if (NSEqualRects(NSIntersectionRect(annotationBounds, [_pdfView bounds]), annotationBounds) == NO)
			[_pdfView goToDestination: [(LinkData *)[_linkList objectAtIndex: rowIndex] destination]];
	}
	
	// Redraw (non-optimal, need to only redraw rectangle bounding old link and new).
	[_pdfView setNeedsDisplay: YES];
}

@end
