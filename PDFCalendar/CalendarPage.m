/*

File: CalendarPage.m

Abstract: <Description, Points of interest, Algorithm approach>

Version: <1.0>

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
//  CalendarPage.m
// =====================================================================================================================


#import "CalendarPage.h"


static void fitRectInRect (NSRect *srcRect, NSRect destRect);


@implementation CalendarPage
// ======================================================================================================== CalendarPage
// ------------------------------------------------------------------------------------------------- initWithImage:month

- (id) initWithImage: (NSImage *) image month: (int) month
{
	// Call PDFPage to init.
	[super init];
	
	// Retain, assign image.
	_image = [image retain];
	
	// Assign month.
	_month = month;
	
	return self;
}

// --------------------------------------------------------------------------------------------------------------- label

- (NSString *) label
{
	switch (_month)
	{
		case 1:
		return @"January";
		break;
		
		case 2:
		return @"February";
		break;
		
		case 3:
		return @"March";
		break;
		
		case 4:
		return @"April";
		break;
		
		case 5:
		return @"May";
		break;
		
		case 6:
		return @"June";
		break;
		
		case 7:
		return @"July";
		break;
		
		case 8:
		return @"August";
		break;
		
		case 9:
		return @"September";
		break;
		
		case 10:
		return @"October";
		break;
		
		case 11:
		return @"November";
		break;
		
		default:
		return @"December";
		break;
	}
}

// -------------------------------------------------------------------------------------------------------- boundsForBox

- (NSRect) boundsForBox: (PDFDisplayBox) box
{
	// Always return 8.5 x 11 inches (in points of course).
	return NSMakeRect(0.0, 0.0, 612.0, 792.0);
}

// --------------------------------------------------------------------------------------------------------- drawWithBox

- (void) drawWithBox: (PDFDisplayBox) box
{
	NSRect		sourceRect;
	NSRect		topHalf;
	NSRect		destRect;
	int			row, col;
	
	// Drag image.
	// ...........
	// Source rectangle.
	sourceRect.origin = NSMakePoint(0.0, 0.0);
	sourceRect.size = [_image size];
	
	// Represent the top half of the page.
	topHalf = [self boundsForBox: box];
	topHalf.origin.y += topHalf.size.height / 2.0;
	topHalf.size.height = (topHalf.size.height / 2.0) - 36.0;
	
	// Scale and center image within top half of page.
	destRect = sourceRect;
	fitRectInRect(&destRect, topHalf);
	
	// Draw.
	[_image drawInRect: destRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
	
	// Draw month name.
	// ...........
	destRect = [self boundsForBox: box];
	destRect.origin.y += destRect.size.height / 2.0;
	destRect.size.height = 48.0;
	destRect.origin.y -= 48.0;
	destRect.size.width -= 36.0;
	destRect.origin.x += 36.0;
	
	// Draw label.
	[[self label] drawInRect: destRect withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSFont boldSystemFontOfSize: 36.0], NSFontAttributeName, NULL]];
	
	// Draw calendar grid.
	// ...........
	destRect = [self boundsForBox: box];
	destRect.size.height = (destRect.size.height / 2.0) - 48.0 - 36.0;
	destRect.size.width -= (36.0 * 2.0);
	destRect.origin.x += 36.0;
	destRect.origin.y += 36.0;
	
	// Set grid color.
	[[NSColor grayColor] set];
	
	// Frame.
	NSFrameRect(destRect);
	
	for (col = 1; col < 7; col++)
	{
		NSRect	line;
		
		line = NSMakeRect(destRect.origin.x + (col * destRect.size.width / 7.0), destRect.origin.y, 
				1.0, destRect.size.height);
		NSFrameRect(line);
	}
	
	for (row = 1; row < 5; row++)
	{
		NSRect	line;
		
		line = NSMakeRect(destRect.origin.x, destRect.origin.y + (row * destRect.size.height / 5.0), 
				destRect.size.width, 1.0);
		NSFrameRect(line);
	}
}

@end

// =========================================================================================================== Functions
// ------------------------------------------------------------------------------------------------------- fitRectInRect

static void fitRectInRect (NSRect *srcRect, NSRect destRect)
{
	NSRect		fitRect;
	
	// Assign.
	fitRect = *srcRect;
	
	// Only scale down.
	if (fitRect.size.width > destRect.size.width)
	{
		float		scaleFactor;
		
		// Try to scale for width first.
		scaleFactor = destRect.size.width / fitRect.size.width;
		fitRect.size.width *= scaleFactor;
		fitRect.size.height *= scaleFactor;
		
		// Did it pass the bounding test?
		if (fitRect.size.height > destRect.size.height)
		{
			// Failed above test -- try to scale the height instead.
			fitRect = *srcRect;
			scaleFactor = destRect.size.height / fitRect.size.height;
			fitRect.size.width *= scaleFactor;
			fitRect.size.height *= scaleFactor;
		}
	}
	else if (fitRect.size.height > destRect.size.height)
	{
		float		scaleFactor;
		
		// Scale based on height requirements.
		scaleFactor = destRect.size.height / fitRect.size.height;
		fitRect.size.height *= scaleFactor;
		fitRect.size.width *= scaleFactor;
	}
	
	// Center.
	fitRect.origin.x = destRect.origin.x + ((destRect.size.width - fitRect.size.width) / 2.0);
	fitRect.origin.y = destRect.origin.y + ((destRect.size.height - fitRect.size.height) / 2.0);
	
	// Assign back.
	*srcRect = fitRect;
}

