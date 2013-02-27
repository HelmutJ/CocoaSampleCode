// ======================================================================================================================
//  MyPDFView.m
// ======================================================================================================================


#import "MyPDFView.h"
#import "MyWindowController.h"


@implementation MyPDFView
// ============================================================================================================ MyPDFView
// ------------------------------------------------------------------------------------------------------------- drawPage

- (void) drawPage: (PDFPage *) pdfPage
{
	NSArray			*allAnnotations;
	PDFAnnotation	*activeAnnotation;
	
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
	// Find out if an annotation is selected in the table view.
	activeAnnotation = [(MyWindowController *)[[self window] windowController] activeAnnotation];
	
	allAnnotations = [pdfPage annotations];
	if (allAnnotations)
	{
		unsigned int	count;
		unsigned int	i;
		BOOL			foundActive = NO;
		
		[self transformContextForPage: pdfPage];
		
		count = [allAnnotations count];
		for (i = 0; i < count; i++)
		{
			PDFAnnotation	*annotation;
			
			annotation = [allAnnotations objectAtIndex: i];
			if (([[annotation type] isEqualToString: @"Link"]) && ([(PDFAnnotationLink *)annotation URL] != NULL))
			{
				if (annotation == activeAnnotation)
				{
					foundActive = YES;
				}
				else
				{
					NSRect			bounds;
					NSBezierPath	*path;
					
					bounds = [annotation bounds];
					
					path = [NSBezierPath bezierPathWithRect: bounds];
					[path setLineJoinStyle: NSRoundLineJoinStyle];
					[[NSColor colorWithDeviceWhite: 0.0 alpha: 0.1] set];
					[path fill];
					[[NSColor grayColor] set];
					[path stroke];
				}
			}
		}
		
		// Draw active annotation last so it is not "painted" over.
		if (foundActive)
		{
			NSRect			bounds;
			NSBezierPath	*path;
			
			bounds = [activeAnnotation bounds];
			
			path = [NSBezierPath bezierPathWithRect: bounds];
			[path setLineJoinStyle: NSRoundLineJoinStyle];
			[[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.1] set];
			[path fill];
			[[NSColor redColor] set];
			[path stroke];
		}
	}
}

// ---------------------------------------------------------------------------------------------- transformContextForPage

- (void) transformContextForPage: (PDFPage *) page
{
	NSAffineTransform	*transform;
	NSRect				boxRect;
	
	boxRect = [page boundsForBox: [self displayBox]];
	
	transform = [NSAffineTransform transform];
	[transform translateXBy: -boxRect.origin.x yBy: -boxRect.origin.y];
	[transform concat];
}

@end
