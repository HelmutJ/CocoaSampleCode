/*

File: AnnotationPanel.m

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
//  AnnotationPanel.m
// =====================================================================================================================


#import "AnnotationPanel.h"


// Global instance.
AnnotationPanel		*gAnnotationPanel = NULL;


NSString *AnnotationPanelAnnotationDidChangeNotification = @"AnnotationPanelAnnotationDidChange";


@interface AnnotationPanel(AnnotationPanelPriv)
- (void) updateAnnotationSubtypeAndAttributes;
@end


@implementation AnnotationPanel
// ===================================================================================================== AnnotationPanel
// ----------------------------------------------------------------------------------------------- sharedAnnotationPanel

+ (AnnotationPanel *) sharedAnnotationPanel
{
	// Create if it does not exist.
	if (gAnnotationPanel == NULL)
		gAnnotationPanel = [[AnnotationPanel alloc] init];
	
	return gAnnotationPanel;
}

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	id			myself = NULL;
	
	// Super.
	[super init];
	
	// Lazily load the annotation panel.
	if (_annotationPanel == NULL)
	{
		BOOL		loaded;
		
		loaded = [NSBundle loadNibNamed: @"AnnotationPanel" owner: self];
		require(loaded == YES, bail);
	}
	
	// Display.
	[_annotationPanel makeKeyAndOrderFront: self];
	
	// Set up UI.
	[self updateAnnotationSubtypeAndAttributes];
	
	// Success.
	myself = self;
	
bail:
	
	return myself;
}

// --------------------------------------------------------------------------------------------------------------- panel

- (NSPanel *) panel
{
	return _annotationPanel;
}

// ------------------------------------------------------------------------------------------------------- setAnnotation

- (void) setAnnotation: (PDFAnnotation *) annotation
{
	// Release old.
	if (_annotation != annotation)
		[_annotation release];
	
	// Assign.
	_annotation = [annotation retain];
	
	// Update.
	[self updateAnnotationSubtypeAndAttributes];
}

// -------------------------------------------------------------------------------------------------------- setFieldName

- (void) setFieldName: (id) sender
{
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	if ([_annotation isKindOfClass: [PDFAnnotationButtonWidget class]])
		[(PDFAnnotationButtonWidget *)_annotation setFieldName: [sender stringValue]];
	else if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
		[(PDFAnnotationTextWidget *)_annotation setFieldName: [sender stringValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setButtonType

- (void) setButtonType: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	[(PDFAnnotationButtonWidget *)_annotation setControlType: [sender selectedRow]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ---------------------------------------------------------------------------------------------------------- setOnValue

- (void) setOnValue: (id) sender
{
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	[(PDFAnnotationButtonWidget *)_annotation setOnStateValue: [sender stringValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------- setHasBackgroundColor

- (void) setHasBackgroundColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
	{
		if ([_annotation isKindOfClass: [PDFAnnotationButtonWidget class]])
			[(PDFAnnotationButtonWidget *)_annotation setBackgroundColor: [NSColor blackColor]];
		else if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
			[(PDFAnnotationTextWidget *)_annotation setBackgroundColor: [NSColor blackColor]];
	}
	else
	{
		if ([_annotation isKindOfClass: [PDFAnnotationButtonWidget class]])
			[(PDFAnnotationButtonWidget *)_annotation setBackgroundColor: NULL];
		else if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
			[(PDFAnnotationTextWidget *)_annotation setBackgroundColor: NULL];
	}
	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ---------------------------------------------------------------------------------------------------------- setBGColor

- (void) setBGColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([_annotation isKindOfClass: [PDFAnnotationButtonWidget class]])
		[(PDFAnnotationButtonWidget *)_annotation setBackgroundColor: [sender color]];
	else if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
		[(PDFAnnotationTextWidget *)_annotation setBackgroundColor: [sender color]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// --------------------------------------------------------------------------------------------------------- setContents

- (void) setContents: (id) sender
{
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	[_annotation setContents: [sender stringValue]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// --------------------------------------------------------------------------------------------------------- setHasColor

- (void) setHasColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
		[_annotation setColor: [NSColor blackColor]];
	else
		[_annotation setColor: NULL];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------------ setColor

- (void) setColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	[_annotation setColor: [sender color]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------- setHasInteriorColor

- (void) setHasInteriorColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
	{
		if ([_annotation isKindOfClass: [PDFAnnotationCircle class]])
			[(PDFAnnotationCircle *)_annotation setInteriorColor: [NSColor blackColor]];
		else if ([_annotation isKindOfClass: [PDFAnnotationSquare class]])
			[(PDFAnnotationSquare *)_annotation setInteriorColor: [NSColor blackColor]];
		else if ([_annotation isKindOfClass: [PDFAnnotationLine class]])
			[(PDFAnnotationLine *)_annotation setInteriorColor: [NSColor blackColor]];
	}
	else
	{
		if ([_annotation isKindOfClass: [PDFAnnotationCircle class]])
			[(PDFAnnotationCircle *)_annotation setInteriorColor: NULL];
		else if ([_annotation isKindOfClass: [PDFAnnotationSquare class]])
			[(PDFAnnotationSquare *)_annotation setInteriorColor: NULL];
		else if ([_annotation isKindOfClass: [PDFAnnotationLine class]])
			[(PDFAnnotationLine *)_annotation setInteriorColor: NULL];
	}
	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ---------------------------------------------------------------------------------------------------- setInteriorColor

- (void) setInteriorColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([_annotation isKindOfClass: [PDFAnnotationCircle class]])
		[(PDFAnnotationCircle *)_annotation setInteriorColor: [sender color]];
	else if ([_annotation isKindOfClass: [PDFAnnotationSquare class]])
		[(PDFAnnotationSquare *)_annotation setInteriorColor: [sender color]];
	else if ([_annotation isKindOfClass: [PDFAnnotationLine class]])
		[(PDFAnnotationLine *)_annotation setInteriorColor: [sender color]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setFontColor

- (void) setFontColor: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([_annotation isKindOfClass: [PDFAnnotationFreeText class]])
		[(PDFAnnotationFreeText *)_annotation setFontColor: [sender color]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setStartStyle

- (void) setStartStyle: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	[(PDFAnnotationLine *)_annotation setStartLineStyle: [sender indexOfSelectedItem]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// --------------------------------------------------------------------------------------------------------- setEndStyle

- (void) setEndStyle: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	[(PDFAnnotationLine *)_annotation setEndLineStyle: [sender indexOfSelectedItem]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------- setLinkHasDestination

- (void) setLinkHasDestination: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
	{
		PDFDestination	*destination;
		
		destination = [[PDFDestination alloc] initWithPage: [_annotation page] atPoint: NSMakePoint(0.0, 0.0)];
		[(PDFAnnotationLink *)_annotation setDestination: destination];
	}
	else
	{
		[(PDFAnnotationLink *)_annotation setDestination: NULL];
	}
	
	[self updateAnnotationSubtypeAndAttributes];

	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// --------------------------------------------------------------------------------------------------------- setLinkPage

- (void) setLinkPage: (id) sender
{
	int		pageIndex;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	pageIndex = [sender intValue];
	if ((pageIndex < 0) || (pageIndex >= [[[_annotation page] document] pageCount]))
	{
		PDFDestination	*destination;
		
		// Wrong, restore.
		NSBeep();
		destination = [(PDFAnnotationLink *)_annotation destination];
		[sender setIntValue: [[[_annotation page] document] indexForPage: [destination page]] + 1];
		return;
	}
	else
	{
		PDFDestination	*wasDestination;
		PDFDestination	*newDestination;
		
		wasDestination = [(PDFAnnotationLink *)_annotation destination];
		newDestination = [[PDFDestination alloc] initWithPage: 
				[[[_annotation page] document] pageAtIndex: pageIndex - 1] 
				atPoint: [wasDestination point]];
		[(PDFAnnotationLink *)_annotation setDestination: newDestination];
	}
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setLinkPointX

- (void) setLinkPointX: (id) sender
{
	PDFDestination	*wasDestination;
	PDFDestination	*newDestination;
	float			newPoint;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	newPoint = [sender floatValue];
	
	wasDestination = [(PDFAnnotationLink *)_annotation destination];
	newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
			atPoint: NSMakePoint(newPoint, [wasDestination point].y)];
	[(PDFAnnotationLink *)_annotation setDestination: newDestination];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setLinkPointY

- (void) setLinkPointY: (id) sender
{
	PDFDestination	*wasDestination;
	PDFDestination	*newDestination;
	float			newPoint;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	newPoint = [sender floatValue];
	
	wasDestination = [(PDFAnnotationLink *)_annotation destination];
	newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
			atPoint: NSMakePoint([wasDestination point].x, newPoint)];
	[(PDFAnnotationLink *)_annotation setDestination: newDestination];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setMarkupType

- (void) setMarkupType: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	[(PDFAnnotationMarkup *)_annotation setMarkupType: [sender indexOfSelectedItem]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setStampName

- (void) setStampName: (id) sender
{
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	[(PDFAnnotationStamp *)_annotation setName: [sender stringValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// --------------------------------------------------------------------------------------------------------- setTextIcon

- (void) setTextIcon: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	// Set.
	[(PDFAnnotationText *)_annotation setIconType: [sender indexOfSelectedItem]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------------------- setIsOpen

- (void) setIsOpen: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	// Set.
	[[_annotation popup] setIsOpen: [sender state]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------------------- setMaxLen

- (void) setMaxLen: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	// Set.
	[(PDFAnnotationTextWidget *)_annotation setMaximumLength: [sender intValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setAlignment

- (void) setAlignment: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	// Set.
	if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
		[(PDFAnnotationTextWidget *)_annotation setAlignment: [sender indexOfSelectedItem]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------------ setPrint

- (void) setPrint: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	// Toggle printing of annotation.
	[_annotation setShouldPrint: [sender intValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ---------------------------------------------------------------------------------------------------------- setDisplay

- (void) setDisplay: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	// Toggle display of annotation.
	[_annotation setShouldDisplay: [sender intValue]];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setActionType

- (void) setActionType: (id) sender
{
	PDFAction	*action = NULL;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	// Create action.
	switch ([sender indexOfSelectedItem])
	{
		case 0:		// None.
		break;
		
		case 1:		// Go To
		action = [[PDFActionGoTo alloc] initWithDestination: 
				[[[PDFDestination alloc] initWithPage: [_annotation page] atPoint: NSMakePoint(0.0, 0.0)] autorelease]];
		break;
		
		case 2:		// Named
		action = [(PDFActionNamed *)[PDFActionNamed alloc] initWithName: kPDFActionNamedNextPage];
		break;
		
		case 3:		// Reset
		action = [[PDFActionResetForm alloc] init];
		break;
		
		case 4:		// URL
		action = [[PDFActionURL alloc] initWithURL: [NSURL URLWithString: @"http://www.apple.com"]];
		break;
		
		default:	// None.
		break;
	}
	
	// Set, release action.
	[_annotation setMouseUpAction: action];
	[action release];
	
	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setActionPage

- (void) setActionPage: (id) sender
{
	int		pageIndex;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	pageIndex = [sender intValue];
	if ((pageIndex < 0) || (pageIndex > [[[_annotation page] document] pageCount]))
	{
		PDFDestination	*destination;
		
		// Wrong, restore.
		NSBeep();
		destination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
		[sender setIntValue: [[[_annotation page] document] indexForPage: [destination page]] + 1];
		return;
	}
	else
	{
		PDFDestination	*wasDestination;
		PDFDestination	*newDestination;
		
		wasDestination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
		newDestination = [[PDFDestination alloc] initWithPage: 
				[[[_annotation page] document] pageAtIndex: pageIndex - 1] 
				atPoint: [wasDestination point]];
		[(PDFActionGoTo *)[_annotation mouseUpAction] setDestination: newDestination];
	}
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------- setHasActionPointX

- (void) setHasActionPointX: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
	{
		[self setActionPointX: _gotoPointX];
	}
	else
	{
		PDFDestination	*wasDestination;
		PDFDestination	*newDestination;
		
		wasDestination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
		newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
				atPoint: NSMakePoint(kPDFDestinationUnspecifiedValue, [wasDestination point].y)];
		[(PDFActionGoTo *)[_annotation mouseUpAction] setDestination: newDestination];
		
		// Notification.
		[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
				object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
	}
	
	// Update UI.
	[self updateAnnotationSubtypeAndAttributes];
}

// -------------------------------------------------------------------------------------------------- setHasActionPointY

- (void) setHasActionPointY: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
	{
		[self setActionPointY: _gotoPointY];
	}
	else
	{
		PDFDestination	*wasDestination;
		PDFDestination	*newDestination;
		
		wasDestination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
		newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
				atPoint: NSMakePoint([wasDestination point].x, kPDFDestinationUnspecifiedValue)];
		[(PDFActionGoTo *)[_annotation mouseUpAction] setDestination: newDestination];
		
		// Notification.
		[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
				object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
	}
	
	// Update UI.
	[self updateAnnotationSubtypeAndAttributes];
}

// ----------------------------------------------------------------------------------------------------- setActionPointX

- (void) setActionPointX: (id) sender
{
	PDFDestination	*wasDestination;
	PDFDestination	*newDestination;
	float			newPoint;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	newPoint = [sender floatValue];
	
	wasDestination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
	newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
			atPoint: NSMakePoint(newPoint, [wasDestination point].y)];
	[(PDFActionGoTo *)[_annotation mouseUpAction] setDestination: newDestination];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------------- setActionPointY

- (void) setActionPointY: (id) sender
{
	PDFDestination	*wasDestination;
	PDFDestination	*newDestination;
	float			newPoint;
	
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	newPoint = [sender floatValue];
	
	wasDestination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
	newDestination = [[PDFDestination alloc] initWithPage: [wasDestination page] 
			atPoint: NSMakePoint([wasDestination point].x, newPoint)];
	[(PDFActionGoTo *)[_annotation mouseUpAction] setDestination: newDestination];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------- setActionName

- (void) setActionName: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender indexOfSelectedItem] < 0)
		return;
	
	// Set.
	[(PDFActionNamed *)[_annotation mouseUpAction] setName: [sender indexOfSelectedItem] + 1];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------------- setResetExclude

- (void) setResetExclude: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
		[(PDFActionResetForm *)[_annotation mouseUpAction] setFieldsIncludedAreCleared: NO];
	else
		[(PDFActionResetForm *)[_annotation mouseUpAction] setFieldsIncludedAreCleared: YES];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ------------------------------------------------------------------------------------------------------ setResetFields

- (void) setResetFields: (id) sender
{
	NSArray	*fieldArray;
	
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	// I'm lazy Ñ require user to enter fields manually with comma-space seperators.
	fieldArray = [[sender stringValue] componentsSeparatedByString: @", "];
	[(PDFActionResetForm *)[_annotation mouseUpAction] setFields: fieldArray];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setActionURL

- (void) setActionURL: (id) sender
{
	PDFActionURL	*action;
	
	// Sanity check.
	if ((_annotation == NULL) || (_ignoreTextEnter))
		return;
	
	// Set.
	action = [[PDFActionURL alloc] initWithURL: [NSURL URLWithString: [sender stringValue]]];
	[_annotation setMouseUpAction: action];
	[action release];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setHasBorder

- (void) setHasBorder: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
		[_annotation setBorder: [[PDFBorder alloc] init]];
	else
		[_annotation setBorder: NULL];
	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// -------------------------------------------------------------------------------------------------------- setThickness

- (void) setThickness: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	[[_annotation border] setLineWidth: [sender floatValue]];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

// ----------------------------------------------------------------------------------------------------------- setDashed

- (void) setDashed: (id) sender
{
	// Sanity check.
	if (_annotation == NULL)
		return;
	
	if ([sender state] == NSOnState)
		[[_annotation border] setStyle: kPDFBorderStyleDashed];
	else
		[[_annotation border] setStyle: kPDFBorderStyleSolid];
//	[self updateAnnotationSubtypeAndAttributes];
	
	// Notification.
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
}

@end

@implementation AnnotationPanel(AnnotationPanelPriv)
// ================================================================================================= AnnotationPanelPriv
// -------------------------------------------------------------------------------- updateAnnotationSubtypeAndAttributes

- (void) updateAnnotationSubtypeAndAttributes
{
	PDFAction	*action;
	PDFBorder	*border;
	BOOL		canHaveBorder = YES;
	
	_ignoreTextEnter = YES;
	
	if (_annotation == NULL)
	{
		[_subtypeLabel setStringValue: @""];
		[_attributesView selectTabViewItemAtIndex: 12];
		
		[_actionType selectItemAtIndex: 0];
		[_actionView selectTabViewItemAtIndex: 4];
		
		[_displayFlag setEnabled: NO];
		[_printFlag setEnabled: NO];
		
		return;
	}
	
	if ([_annotation isKindOfClass: [PDFAnnotationButtonWidget class]])
	{
		PDFWidgetControlType	controlType;
		NSString				*string;
		NSColor					*color;
		
		[_subtypeLabel setStringValue: @"Widget (Button)"];
		[_attributesView selectTabViewItemAtIndex: 0];
		
		// Attributes.
		// Field name.
		string = [(PDFAnnotationButtonWidget *)_annotation fieldName];
		if (string)
			[_buttonFieldName setStringValue: string];
		else
			[_buttonFieldName setStringValue: @""];
		
		// Control type.
		controlType = [(PDFAnnotationButtonWidget *)_annotation controlType];
		[_controlType selectCellAtRow: controlType column: 0];
		
		// "On" value.
		string = [(PDFAnnotationButtonWidget *)_annotation onStateValue];
		if (string)
			[_onValue setStringValue: string];
		else
			[_onValue setStringValue: @""];
		
		// Background color.
		color = [(PDFAnnotationButtonWidget *)_annotation backgroundColor];
		[_buttonHasBGColor setState: color != NULL];
		[_buttonBGColor setEnabled: color != NULL];
		if (color == NULL)
			[_buttonBGColor setColor: [NSColor blackColor]];
		else
			[_buttonBGColor setColor: color];
		
		// Color.
		color = [_annotation color];
		[_buttonHasColor setState: color != NULL];
		[_buttonColor setEnabled: color != NULL];
		if (color == NULL)
			[_buttonColor setColor: [NSColor blackColor]];
		else
			[_buttonColor setColor: color];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationChoiceWidget class]])
	{
		[_subtypeLabel setStringValue: @"Widget (Choice)"];
		[_attributesView selectTabViewItemAtIndex: 1];
		
		// Attributes.
		[_choiceFieldName setStringValue: [(PDFAnnotationChoiceWidget *)_annotation fieldName]];
	}
	else if (([_annotation isKindOfClass: [PDFAnnotationCircle class]]) || 
			([_annotation isKindOfClass: [PDFAnnotationSquare class]]))
	{
		NSString	*string;
		NSColor		*color;
		
		if ([_annotation isKindOfClass: [PDFAnnotationCircle class]])
			[_subtypeLabel setStringValue: @"Circle"];
		else
			[_subtypeLabel setStringValue: @"Square"];
		[_attributesView selectTabViewItemAtIndex: 2];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_circleContents setStringValue: string];
		else
			[_circleContents setStringValue: @""];
		
		// Border color.
		color = [_annotation color];
		if (color)
			[_circleColor setColor: color];
		else
			[_circleColor setColor: [NSColor blackColor]];
		
		// Interior color.
		if ([_annotation isKindOfClass: [PDFAnnotationCircle class]])
			color = [(PDFAnnotationCircle *)_annotation interiorColor];
		else
			color = [(PDFAnnotationSquare *)_annotation interiorColor];
		[_circleHasInteriorColor setState: color != NULL];
		[_circleInteriorColor setEnabled: color != NULL];
		if (color)
			[_circleInteriorColor setColor: color];
		else
			[_circleInteriorColor setColor: [NSColor blackColor]];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationFreeText class]])
	{
		NSString	*string;
		NSColor		*color;
		
		[_subtypeLabel setStringValue: @"Free Text"];
		[_attributesView selectTabViewItemAtIndex: 3];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_freeTextContents setStringValue: string];
		else
			[_freeTextContents setStringValue: @""];
		
		// Fill color.
		color = [_annotation color];
		if (color)
			[_freeTextColor setColor: color];
		else
			[_freeTextColor setColor: [NSColor blackColor]];
		
		// Font color.
		color = [(PDFAnnotationFreeText *)_annotation fontColor];
		if (color)
		{
//			[_freeTextFontColor setEnabled: YES];
			[_freeTextFontColor setColor: color];
		}
		else
		{
			[_freeTextFontColor setColor: [NSColor blackColor]];
//			[_freeTextFontColor setEnabled: NO];
		}
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationInk class]])
	{
		NSString	*string;
		NSColor		*color;
		
		[_subtypeLabel setStringValue: @"Ink"];
		[_attributesView selectTabViewItemAtIndex: 4];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_inkContents setStringValue: string];
		else
			[_inkContents setStringValue: @""];
		
		// Fill color.
		color = [_annotation color];
		if (color)
			[_inkColor setColor: color];
		else
			[_inkColor setColor: [NSColor blackColor]];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationLine class]])
	{
		NSString	*string;
		NSColor		*color;
		
		[_subtypeLabel setStringValue: @"Line"];
		[_attributesView selectTabViewItemAtIndex: 5];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_lineContents setStringValue: string];
		else
			[_lineContents setStringValue: @""];
		
		// Fill color.
		color = [_annotation color];
		if (color)
			[_lineColor setColor: color];
		else
			[_lineColor setColor: [NSColor blackColor]];

		// Interior color.
		color = [(PDFAnnotationLine *)_annotation interiorColor];
		[_lineHasInteriorColor setState: color != NULL];
		if (color)
		{
			[_lineInteriorColor setEnabled: YES];
			[_lineInteriorColor setColor: color];
		}
		else
		{
			[_lineInteriorColor setColor: [NSColor blackColor]];
			[_lineInteriorColor setEnabled: NO];
		}
		
		// Line styles.
		[_startStyle selectItemAtIndex: [(PDFAnnotationLine *)_annotation startLineStyle]];
		[_endStyle selectItemAtIndex: [(PDFAnnotationLine *)_annotation endLineStyle]];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationLink class]])
	{
		NSColor			*color;
		PDFDestination	*destination;
		
		[_subtypeLabel setStringValue: @"Link"];
		[_attributesView selectTabViewItemAtIndex: 6];
		
		// Attributes.
		// Destination.
		destination = [(PDFAnnotationLink *)_annotation destination];
		[_linkHasDestination setState: destination != NULL];
		[_linkPage setEnabled: destination != NULL];
		[_linkPointX setEnabled: destination != NULL];
		[_linkPointY setEnabled: destination != NULL];
		
		if (destination == NULL)
		{
			[_linkPage setStringValue: @""];
			[_linkPointX setStringValue: @""];
			[_linkPointY setStringValue: @""];
		}
		else
		{
			[_linkPage setIntValue: [[[_annotation page] document] indexForPage: [destination page]] + 1];
			[_linkPointX setFloatValue: [destination point].x];
			[_linkPointY setFloatValue: [destination point].y];
		}
		
		// Border color.
		color = [_annotation color];
		[_linkHasColor setState: color != NULL];
		[_linkColor setEnabled: color != NULL];
		if (color)
			[_linkColor setColor: color];
		else
			[_linkColor setColor: [NSColor blackColor]];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationMarkup class]])
	{
		NSString	*string;
		NSColor		*color;
		
		[_subtypeLabel setStringValue: @"Mark-Up"];
		[_attributesView selectTabViewItemAtIndex: 7];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_markupContents setStringValue: string];
		else
			[_markupContents setStringValue: @""];
		
		// Fill color.
		color = [_annotation color];
		if (color)
			[_markupColor setColor: color];
		else
			[_markupColor setColor: [NSColor blackColor]];
		
		// Type.
		[_markupType selectItemAtIndex: [(PDFAnnotationMarkup *)_annotation markupType]];
		
		// No border.
		canHaveBorder = NO;
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationStamp class]])
	{
		NSString	*string;
		
		[_subtypeLabel setStringValue: @"Stamp"];
		[_attributesView selectTabViewItemAtIndex: 8];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_stampContents setStringValue: string];
		else
			[_stampContents setStringValue: @""];
		
		// Name.
		string = [(PDFAnnotationStamp *)_annotation name];
		if (string)
			[_stampName setStringValue: string];
		else
			[_stampName setStringValue: @""];
		
		// No border.
		canHaveBorder = NO;
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationText class]])
	{
		NSString	*string;
		NSColor		*color;
		
		[_subtypeLabel setStringValue: @"Text"];
		[_attributesView selectTabViewItemAtIndex: 9];
		
		// Attributes.
		// Contents.
		string = [_annotation contents];
		if (string)
			[_textContents setStringValue: string];
		else
			[_textContents setStringValue: @""];
		
		// Note color.
		color = [_annotation color];
		if (color)
			[_textColor setColor: color];
		else
			[_textColor setColor: [NSColor blackColor]];
		
		// Icon type.
		[_textIcon selectItemAtIndex: [(PDFAnnotationText *)_annotation iconType]];
		
		// Is open.
		[_textIsOpen setState: [[(PDFAnnotationText *)_annotation popup] isOpen]];
		
		// No border.
		canHaveBorder = NO;
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationTextWidget class]])
	{
		NSString		*string;
		NSColor			*color;
		
		[_subtypeLabel setStringValue: @"Widget (Text)"];
		[_attributesView selectTabViewItemAtIndex: 10];
		
		// Attributes.
		// Field name.
		string = [(PDFAnnotationTextWidget *)_annotation fieldName];
		if (string)
			[_textFieldName setStringValue: string];
		else
			[_textFieldName setStringValue: @""];
		
		// Max len.
		[_maxLen setIntValue: [(PDFAnnotationTextWidget *)_annotation maximumLength]];
		
		// Alignment.
		[_textAlignment selectItemAtIndex: [(PDFAnnotationTextWidget *)_annotation alignment]];
		
		// Background color.
		color = [(PDFAnnotationTextWidget *)_annotation backgroundColor];
		[_textHasBGColor setState: color != NULL];
		[_textBGColor setEnabled: color != NULL];
		if (color)
			[_textBGColor setColor: color];
		else
			[_textBGColor setColor: [NSColor blackColor]];
	}
	else if ([_annotation isKindOfClass: [PDFAnnotationPopup class]])
	{
		[_subtypeLabel setStringValue: @"Popup"];		
		[_attributesView selectTabViewItemAtIndex: 11];
		
		// No border.
		canHaveBorder = NO;
	}
	else
	{
		[_subtypeLabel setStringValue: @"Unknown"];
		[_attributesView selectTabViewItemAtIndex: 12];
		
		// No border.
		canHaveBorder = NO;
	}
	
	// Flags.
	[_displayFlag setEnabled: YES];
	[_displayFlag setState: [_annotation shouldDisplay]];
	[_printFlag setEnabled: YES];
	[_printFlag setState: [_annotation shouldPrint]];
	
	// Action
	// Action
	// Action
	// Action
	// Action
	action = [_annotation mouseUpAction];
	if (action == NULL)
	{
		[_actionType selectItemAtIndex: 0];
		[_actionView selectTabViewItemAtIndex: 4];
	}
	else if ([action isKindOfClass: [PDFActionGoTo class]])
	{
		// Skip if we have a destination.
		if (([_annotation isKindOfClass: [PDFAnnotationLink class]]) && 
				([(PDFAnnotationLink *)_annotation destination] != NULL))
		{
			[_actionType selectItemAtIndex: 0];
			[_actionView selectTabViewItemAtIndex: 4];
		}
		else
		{
			PDFDestination	*destination;
			
			[_actionType selectItemAtIndex: 1];
			[_actionView selectTabViewItemAtIndex: 0];
			
			destination = [(PDFActionGoTo *)[_annotation mouseUpAction] destination];
			[_gotoPage setIntValue: [[[destination page] document] indexForPage: [destination page]] + 1];
			if ([destination point].x == kPDFDestinationUnspecifiedValue)
			{
				[_hasGotoPointX setState: NSOffState];
				[_gotoPointX setFloatValue: 0.0];
				[_gotoPointX setEnabled: NO];
			}
			else
			{
				[_hasGotoPointX setState: NSOnState];
				[_gotoPointX setFloatValue: [destination point].x];
				[_gotoPointX setEnabled: YES];
			}
			if ([destination point].y == kPDFDestinationUnspecifiedValue)
			{
				[_hasGotoPointY setState: NSOffState];
				[_gotoPointY setFloatValue: 0.0];
				[_gotoPointY setEnabled: NO];
			}
			else
			{
				[_hasGotoPointY setState: NSOnState];
				[_gotoPointY setFloatValue: [destination point].y];
				[_gotoPointY setEnabled: YES];
			}
		}
	}
	else if ([action isKindOfClass: [PDFActionNamed class]])
	{
		[_actionType selectItemAtIndex: 2];
		[_actionView selectTabViewItemAtIndex: 1];
		
		[_actionName selectItemAtIndex: [(PDFActionNamed *)action name] - 1];
	}
	else if ([action isKindOfClass: [PDFActionResetForm class]])
	{
		NSArray	*fields;
		
		[_actionType selectItemAtIndex: 3];
		[_actionView selectTabViewItemAtIndex: 2];
		
		[_resetExclude setState: [(PDFActionResetForm *)action fieldsIncludedAreCleared] == NO];
		fields = [(PDFActionResetForm *)action fields];
		if ((fields) && ([fields count] > 0))
			[_resetText setStringValue: [fields componentsJoinedByString: @", "]];
		else
			[_resetText setStringValue: @""];
	}
	else if ([action isKindOfClass: [PDFActionURL class]])
	{
		[_actionType selectItemAtIndex: 4];
		[_actionView selectTabViewItemAtIndex: 3];
		
		[_actionURL setStringValue: [[(PDFActionURL *)action URL] absoluteString]];
	}
	
	// Border.
	if (canHaveBorder)
	{
		[_hasBorder setEnabled: YES];
		
		border = [_annotation border];
		[_hasBorder setState: (border != NULL)];
		if (border)
		{
			[_thickness setEnabled: YES];
			[_thickness setStringValue: [NSString stringWithFormat: @"%.1f", [border lineWidth]]];
			
			[_dashed setEnabled: YES];
			[_dashed setState: [border style] == kPDFBorderStyleDashed];
		}
		else
		{
			[_thickness setStringValue: @""];
			[_thickness setEnabled: NO];
			
			[_dashed setState: NSOffState];
			[_dashed setEnabled: NO];
		}
	}
	else
	{
		[_hasBorder setEnabled: NO];
		[_hasBorder setState: NSOffState];
		[_thickness setStringValue: @""];
		[_thickness setEnabled: NO];
		[_dashed setState: NSOffState];
		[_dashed setEnabled: NO];
	}
	
	_ignoreTextEnter = NO;
}

@end
