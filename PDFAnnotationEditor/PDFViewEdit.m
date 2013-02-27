/*

File: PDFViewEdit.m

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
//  PDFViewEdit.m
// =====================================================================================================================


#import "AnnotationPanel.h"
#import "MyStampAnnotation.h"
#import "PDFViewEdit.h"


static NSRect RectPlusScale (NSRect aRect, float scale);


@implementation PDFViewEdit
// ========================================================================================================= PDFViewEdit
// -------------------------------------------------------------------------------------------------------- saveDocument

- (void) saveDocument: (id) sender
{
	[self saveDocumentAs: sender];
}

// ------------------------------------------------------------------------------------------------------ saveDocumentAs

- (void) saveDocumentAs: (id) sender
{
	NSSavePanel	*panel;
	
	panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"pdf"];
	
	// Run.
	if ([panel runModal] == NSFileHandlingPanelOKButton)
	{
		PDFDocument	*document;
		
		// Save file.
		[[self document] writeToURL: [panel URL]];
		
		// Clear active annotation.
		_activeAnnotation = NULL;
		
		// Set new file.
		document = [[[PDFDocument alloc] initWithURL: [panel URL]] autorelease];
		[self setDocument: document];
	}
}

// ------------------------------------------------------------------------------------------------------- printDocument

- (void) printDocument: (id) sender
{
	// Pass to PDF view.
	[self printWithInfo: [[[[self window] windowController] document] printInfo] autoRotate: YES];
}

// ------------------------------------------------------------------------------------------------------------ drawPage

- (void) drawPage: (PDFPage *) pdfPage
{
	NSArray			*annotations;
	NSUInteger		annotCount;
	NSUInteger		i;
	
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
	// Skip out unless we are in 'edit mode'.
	if (_editMode == NO)
		return;
	
	// Save.
	[NSGraphicsContext saveGraphicsState];
	
	// Tranform.
	[self transformContextForPage: pdfPage];
	
	// Frame all annotations in gray.
	[[NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.3] set];
	
	// Walk array of annotations.
	annotations = [pdfPage annotations];
	annotCount = [annotations count];
	for (i = 0; i < annotCount; i++)
		NSFrameRectWithWidthUsingOperation([[annotations objectAtIndex: i] bounds], 1.0, NSCompositeSourceOver);
	
	// Handle the selected annotation.
	if ((_activeAnnotation) && ([_activeAnnotation page] == pdfPage))
	{
		NSRect			bounds;
		NSBezierPath	*path;
		
		bounds = [_activeAnnotation bounds];
		
		path = [NSBezierPath bezierPathWithRect: bounds];
		[path setLineJoinStyle: NSRoundLineJoinStyle];
		[[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.1] set];
		[path fill];
		[[NSColor redColor] set];
		[path stroke];
		
		// Draw resize handle.
		NSRectFill(NSIntegralRect([self resizeThumbForRect: bounds rotation: [pdfPage rotation]]));
	}
	
	// Restore.
	[NSGraphicsContext restoreGraphicsState];
}

// --------------------------------------------------------------------------------------------- transformContextForPage

- (void) transformContextForPage: (PDFPage *) page
{
	NSAffineTransform	*transform;
	NSRect				boxRect;
	int					rotation;
	
	// Identity.
	transform = [NSAffineTransform transform];
	
	// Bounds for page.
	boxRect = [page boundsForBox: [self displayBox]];
	
	// Handle rotation.
	rotation = [page rotation];
	switch (rotation)
	{
		case 90:
		[transform rotateByDegrees: -90];
		[transform translateXBy: -boxRect.size.width yBy: 0.0];
		break;
		
		case 180:
		[transform rotateByDegrees: 180];
		[transform translateXBy: -boxRect.size.height yBy: -boxRect.size.width];
		break;
		
		case 270:
		[transform rotateByDegrees: 90];
		[transform translateXBy: 0.0 yBy: -boxRect.size.height];
		break;
	}
	
	// Origin.
	[transform translateXBy: -boxRect.origin.x yBy: -boxRect.origin.y];
	
	// Concatenate.
	[transform concat];
}

// ---------------------------------------------------------------------------------------------------- selectAnnotation

- (void) selectAnnotation: (PDFAnnotation *) annotation
{
	// Deselect old annotation when appropriate.
	if ((_activeAnnotation != NULL) && (_activeAnnotation != annotation))
	{
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds]
				fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
	
	// Assign.
	_activeAnnotation = annotation;
	
	// Display in panel.
	[[AnnotationPanel sharedAnnotationPanel] setAnnotation: _activeAnnotation];
	
	if (_activeAnnotation)
	{
		// Old (current) annotation location.
		_wasBounds = [_activeAnnotation bounds];
		
		// Force redisplay.
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_activeAnnotation bounds] 
				fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
}

// --------------------------------------------------------------------------------------------------- annotationChanged

- (void) annotationChanged
{
	NSRect		bounds;
	
	// NOP.
	if (_activeAnnotation == NULL)
		return;
	
	// Get bounds.
	bounds = [_activeAnnotation bounds];
	
	// Handle line start and end points.
	if ([_activeAnnotation isKindOfClass: [PDFAnnotationLine class]])
	{
		PDFBorder	*border = [_activeAnnotation border];
		float		inset = 1.0;
		
		if (border)
			inset = ceilf([border lineWidth] * 2.2);
		[(PDFAnnotationLine *)_activeAnnotation setStartPoint: NSMakePoint(inset, inset)];
		[(PDFAnnotationLine *)_activeAnnotation setEndPoint: NSMakePoint(bounds.size.width - inset, bounds.size.height - inset)];
	}
	else if ([_activeAnnotation isKindOfClass: [PDFAnnotationMarkup class]])
	{
		[(PDFAnnotationMarkup *)_activeAnnotation setQuadrilateralPoints: [NSArray arrayWithObjects: 
				[NSValue valueWithPoint: NSMakePoint(0.0, bounds.size.height)], 
				[NSValue valueWithPoint: NSMakePoint(bounds.size.width, bounds.size.height)], 
				[NSValue valueWithPoint: NSMakePoint(0.0, 0.0)], 
				[NSValue valueWithPoint: NSMakePoint(bounds.size.width, 0.0)], 
				NULL]];
	}
}

// --------------------------------------------------------------------------------------------------------- setEditMode

- (void) setEditMode: (BOOL) edit
{
	// Assign.
	_editMode = edit;
	
	// Redraw.
	[self setNeedsDisplay: YES];
}

#pragma mark -------- event overrides
// ------------------------------------------------------------------------------------------ setCursorForAreaOfInterest
/*
- (void) setCursorForAreaOfInterest: (PDFAreaOfInterest) area
{
	[[NSCursor arrowCursor] set];
}
*/
// ----------------------------------------------------------------------------------------------------------- mouseDown

- (void) mouseDown: (NSEvent *) theEvent
{
	PDFPage			*activePage;
	PDFAnnotation	*newActiveAnnotation = NULL;
	NSArray			*annotations;
	int				numAnnotations, i;
	NSPoint			pagePoint;
	
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseDown: theEvent];
		return;
	}
	
	// Mouse in display view coordinates.
	_mouseDownLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Page we're on.
	activePage = [self pageForPoint: _mouseDownLoc nearest: YES];
	
	// Get mouse in "page space".
	pagePoint = [self convertPoint: _mouseDownLoc toPage: activePage];
	
	// Hit test for annotation.
	annotations = [activePage annotations];
	numAnnotations = [annotations count];
	for (i = 0; i < numAnnotations; i++)
	{
		NSRect		annotationBounds;
		
		// Hit test annotation.
		annotationBounds = [[annotations objectAtIndex: i] bounds];
		if (NSPointInRect(pagePoint, annotationBounds))
		{
			// New annotation.
			newActiveAnnotation = [annotations objectAtIndex: i];
			
			// Update font panel.
			[self reflectFont];
			
			// Remember click point relative to annotation origin.
			_clickDelta.x = pagePoint.x - annotationBounds.origin.x;
			_clickDelta.y = pagePoint.y - annotationBounds.origin.y;
			break;
		}
	}
	
	// Select annotation.
	[self selectAnnotation: newActiveAnnotation];
	
	if (_activeAnnotation == NULL)
	{
		[super mouseDown: theEvent];
	}
	else
	{
		_mouseDownInAnnotation = YES;
		
		// Hit-test for resize box.
		_resizing = NSPointInRect(pagePoint, [self resizeThumbForRect: _wasBounds 
				rotation: [[_activeAnnotation page] rotation]]);
	}
}

// -------------------------------------------------------------------------------------------------------- mouseDragged

- (void) mouseDragged: (NSEvent *) theEvent
{
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseDragged: theEvent];
		return;
	}
	
	_dragging = YES;
	
	// Handle link-edit mode.
	if (_mouseDownInAnnotation)
	{
		NSRect		newBounds;
		NSRect		currentBounds;
		NSRect		dirtyRect;
		NSPoint		mouseLoc;
		NSPoint		endPt;
		
		// Where is annotation now?
		currentBounds = [_activeAnnotation bounds];
		
		// Mouse in display view coordinates.
		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
		
		// Convert end point to page space.
		endPt = [self convertPoint: mouseLoc toPage: [_activeAnnotation page]];
		
		if (_resizing)
		{
			NSPoint		startPoint;
			
			// Convert start point to page space.
			startPoint = [self convertPoint: _mouseDownLoc toPage: [_activeAnnotation page]];
			
			// Resize the annotation.
			switch ([[_activeAnnotation page] rotation])
			{
				case 0:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
				
				case 90:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 180:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 270:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
			}
			
			// Keep integer.
			newBounds = NSIntegralRect(newBounds);
		}
		else
		{
			// Move annotation.
			// Hit test, is mouse still within page bounds?
			if (NSPointInRect([self convertPoint: mouseLoc toPage: [_activeAnnotation page]], 
					[[_activeAnnotation page] boundsForBox: [self displayBox]]))
			{
				// Calculate new bounds for annotation.
				newBounds = currentBounds;
				newBounds.origin.x = roundf(endPt.x - _clickDelta.x);
				newBounds.origin.y = roundf(endPt.y - _clickDelta.y);
			}
			else
			{
				// Snap back to initial location.
				newBounds = _wasBounds;
			}
		}
		
		// Change annotation's location.
		[_activeAnnotation setBounds: newBounds];
		
		// Call our method to handle updating annotation geometry.
		[self annotationChanged];
		
		// Force redraw.
		dirtyRect = NSUnionRect(currentBounds, newBounds);
		[self setNeedsDisplayInRect: 
				RectPlusScale([self convertRect: dirtyRect fromPage: [_activeAnnotation page]], [self scaleFactor])];
	}
	else
	{
		[super mouseDragged: theEvent];
	}
}

// ------------------------------------------------------------------------------------------------------------- mouseUp

- (void) mouseUp: (NSEvent *) theEvent
{
	// Defer to super for locked PDF or if not in 'edit mode'.
	if (([[self document] isLocked]) || (_editMode == NO))
	{
		[super mouseUp: theEvent];
		return;
	}
	
	_dragging = NO;
	
	// Handle link-edit mode.
	if (_mouseDownInAnnotation)
	{
		_mouseDownInAnnotation = NO;
	}
	else
	{
		[super mouseUp: theEvent];
	}
}

// ------------------------------------------------------------------------------------------------------------- keyDown

- (void) keyDown: (NSEvent *) theEvent
{
	unichar			oneChar;
	unsigned int	theModifiers;
	BOOL			noModifier;
	
	// Skip out if not in 'edit mode'.
	if (_editMode == NO)
	{
		[super keyDown: theEvent];
		return;
	}
	
	// Get the character from the keyDown event.
	oneChar = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
	theModifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	noModifier = ((theModifiers & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) == 0);
	
	// Delete?
	if ((oneChar == NSDeleteCharacter) || (oneChar == NSDeleteFunctionKey))
		[self delete: self];
	else
		[super keyDown: theEvent];
}

// -------------------------------------------------------------------------------------------------------------- delete

- (void) delete: (id) sender
{
	if (_activeAnnotation != NULL)
	{
		// Remove annotation from page.
		[[_activeAnnotation page] removeAnnotation: _activeAnnotation];
		_activeAnnotation = NULL;
		
		// Lazy, redraw entire view.
		[self setNeedsDisplay: YES];
		
		// No annotation selected.
		[[AnnotationPanel sharedAnnotationPanel] setAnnotation: NULL];

		// Set edited flag.
		[[self window] setDocumentEdited: YES];
	}
}

// ------------------------------------------------------------------------------------------------------- newAnnotation

- (void) newAnnotation: (id) sender
{
	PDFSelection	*selection;
	PDFAnnotation	*annotation;
	NSRect			annotationBounds;
	
	// Get bounds for selection if available, otherwise, create an arbitrary rectangle.
	selection = [self currentSelection];
	if (selection)
	{
		annotationBounds = [selection boundsForPage: [[selection pages] objectAtIndex: 0]];
		[self setCurrentSelection: NULL];
	}
	else
	{
		NSRect		pageBounds;
		
		pageBounds = [[self currentPage] boundsForBox: [self displayBox]];
		annotationBounds = NSMakeRect(pageBounds.origin.x + 20.0, pageBounds.origin.y + 20.0, 200.0, 80.0);
	}
	
	// Which annotation to create....
	switch ([sender tag])
	{
		case 0:
		annotation = [[PDFAnnotationButtonWidget alloc] initWithBounds: annotationBounds];
		break;
		
		case 1:
		annotation = [[PDFAnnotationChoiceWidget alloc] initWithBounds: annotationBounds];
		break;
		
		case 2:
		annotation = [[PDFAnnotationCircle alloc] initWithBounds: annotationBounds];
		break;
		
		case 3:
		annotation = [[PDFAnnotationFreeText alloc] initWithBounds: annotationBounds];
		break;
		
		case 4:
		annotation = [[PDFAnnotationInk alloc] initWithBounds: annotationBounds];
		// CREATE INK
		break;
		
		case 5:
		annotation = [[PDFAnnotationLine alloc] initWithBounds: annotationBounds];
		break;
		
		case 6:
		annotation = [[PDFAnnotationLink alloc] initWithBounds: annotationBounds];
		break;
		
		case 7:
		annotation = [[PDFAnnotationMarkup alloc] initWithBounds: annotationBounds];
		break;
		
		case 8:
		annotation = [[PDFAnnotationSquare alloc] initWithBounds: annotationBounds];
		break;
		
		case 9:
		annotation = [[MyStampAnnotation alloc] initWithBounds: annotationBounds];
		break;
		
		case 10:
		// Special case bounds for Text annotation - we want something small and icon-sized.
		annotationBounds.size.width = 20.0;
		annotationBounds.size.height = 20.0;
		annotation = [[PDFAnnotationText alloc] initWithBounds: annotationBounds];
		break;
		
		case 11:
		annotation = [[PDFAnnotationTextWidget alloc] initWithBounds: annotationBounds];
		break;
	}
	
	[[self currentPage] addAnnotation: annotation];
	[self setNeedsDisplay: YES];
	
	// Select.
	[self selectAnnotation: annotation];
}

#pragma mark -------- font
// -------------------------------------------------------------------------------------------------------- showFontPanel

- (void) showFontPanel: (id) sender
{
	[[NSFontPanel sharedFontPanel] makeKeyAndOrderFront: self];
	[[NSFontManager sharedFontManager] setDelegate: self];
	[self reflectFont];
}

// ---------------------------------------------------------------------------------------------------------- reflectFont

- (void) reflectFont
{
	if ([NSFontPanel sharedFontPanelExists] == NO)
		return;
	
	if (_activeAnnotation == NULL)
		return;
	
	if ([_activeAnnotation isKindOfClass: [PDFAnnotationFreeText class]])
		[[NSFontPanel sharedFontPanel] setPanelFont: [(PDFAnnotationFreeText *)_activeAnnotation font] isMultiple: NO];
}

// ----------------------------------------------------------------------------------------------------------- changeFont

- (void) changeFont: (id) sender
{
	NSFont		*newFont;
	
	if (_activeAnnotation == NULL)
		return;
	
	if ([_activeAnnotation isKindOfClass: [PDFAnnotationFreeText class]])
	{
		newFont = [sender convertFont: [(PDFAnnotationFreeText *)_activeAnnotation font]];
		[(PDFAnnotationFreeText *)_activeAnnotation setFont: newFont];
	}
	
	// Lazy.
	[self setNeedsDisplay: YES];
}

// --------------------------------------------------------------------------------------------------- resizeThumbForRect

- (NSRect) resizeThumbForRect: (NSRect) rect rotation: (int) rotation
{
	NSRect		thumb;
	
	// Start with rect.
	thumb = rect;
	
	// Use rotation to determine thumb origin.
	switch (rotation)
	{
		case 0:
		thumb.origin.x += rect.size.width - 8.0;
		break;
		
		case 90:
		thumb.origin.x += rect.size.width - 8.0;
		thumb.origin.y += rect.size.height - 8.0;
		break;
		
		case 180:
		thumb.origin.y += rect.size.height - 8.0;
		break;
	}
	
	thumb.size.width = 8.0;
	thumb.size.height = 8.0;
	
	return thumb;
}

@end

// -------------------------------------------------------------------------------------------------------- RectPlusScale

static NSRect RectPlusScale (NSRect aRect, float scale)
{
	float		maxX;
	float		maxY;
	NSPoint		origin;
	
	// Determine edges.
	maxX = ceilf(aRect.origin.x + aRect.size.width) + scale;
	maxY = ceilf(aRect.origin.y + aRect.size.height) + scale;
	origin.x = floorf(aRect.origin.x) - scale;
	origin.y = floorf(aRect.origin.y) - scale;
	
	return NSMakeRect(origin.x, origin.y, maxX - origin.x, maxY - origin.y);
}
