/*

File: DCDie.m

Abstract: Implementation of a single die

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

Copyright © 2006-2009 Apple Inc., All Rights Reserved

*/ 

#import "DCDie.h"
#import "NSBezierPath-RoundedRect.h"
#import "DCDiceView.h"
#import "DCDiceView-Private.h"

@implementation DCDie

+(void)initialize {
	srandom(time(NULL));
}

-(id)initWithBounds:(NSRect) rect {
	self = [super init];
	if (self) {
		hasHold = NO;
		[self roll];
		bounds = rect;
	}
	return self;
}

-(id)initWithBounds:(NSRect) rect spotCount:(unsigned int)spots
{
	self = [self initWithBounds: rect];
	if (self) {
		spotCount = spots;
	}
	return self;
}


- (void)setParent:(DCDiceView *)view {
	parent = view;
}

- (DCDiceView *) parent {
	return parent;
}



- (unsigned int)spotCount {
    return spotCount;
}


- (NSRect)bounds {
    return bounds;
}

- (void)setBounds:(NSRect)value {
        bounds = value;
}


- (void)toggleHold {
	hasHold = !hasHold;
	NSAccessibilityPostNotification(self, NSAccessibilityValueChangedNotification);  // Accessibility Related
}

- (void)clearFromView {
	hasHold = NO;
	NSAccessibilityPostNotification(self, NSAccessibilityUIElementDestroyedNotification);  // Accessibility Related
}


- (BOOL)hasFocus {
	return hasFocus;
}

- (void)setFocus:(BOOL)flag {
	hasFocus = flag;
}


-(void)drawSpotAtPoint:(NSPoint) point {
	float spotSide = bounds.size.width / 5.0;
	float halfSide = spotSide / 2.0;
	NSRect spotRect = NSMakeRect(point.x - halfSide, point.y - halfSide, spotSide, spotSide);
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: spotRect] fill];
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: NSInsetRect(spotRect, 1.0, 1.0)] fill];
}

-(void)drawSpots {

	NSRect insetRect = NSInsetRect(bounds, bounds.size.width / 4.0, bounds.size.height / 4.0);

	switch(spotCount) {
	
		case 1:
			[self drawSpotAtPoint: NSMakePoint(NSMidX(insetRect), NSMidY(insetRect))];
			break;
			
		case 2:
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMaxY(insetRect))];
			break;
			
		case 3:
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMidX(insetRect), NSMidY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMaxY(insetRect))];
			break;
			
		case 4:
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMaxY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMaxY(insetRect))];
			break;
			
		case 5:
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMaxY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMidX(insetRect), NSMidY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMaxY(insetRect))];
			break;
			
		case 6:
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMidY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMinX(insetRect), NSMaxY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMinY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMidY(insetRect))];
			[self drawSpotAtPoint: NSMakePoint(NSMaxX(insetRect), NSMaxY(insetRect))];
			break;
			
		default:
			break;
	}
}

-(void)draw {

	float radius = bounds.size.width / 10.0;
	NSBezierPath *path = nil;
	
	if (hasFocus && parent && [parent shouldDisplayFocus]) {
	
		float focusRectOffset;
		if (hasHold) {
			focusRectOffset = 8.0; 
		} else {
			focusRectOffset = 2.0;
		}
	
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
		path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, -focusRectOffset, -focusRectOffset)  cornerRadius:(radius + (focusRectOffset / bounds.size.width))];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
	
	
	}
	
	if (hasHold) {
		[[NSColor blackColor] set];
		path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, -6.0, -6.0)  cornerRadius:(radius + (6.0 / bounds.size.width))];
		[path fill];

		[[NSColor yellowColor] set];
		path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, -4.0, -4.0)  cornerRadius:(radius + (4.0 / bounds.size.width))];
		[path fill];
	}
	
	[[NSColor blackColor] set];
	path = [NSBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius];
	[path fill];
	
	[[NSColor redColor] set];
	path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 2.0, 2.0) cornerRadius: (radius - (2.0 / bounds.size.width))];
	[path fill];

	[self drawSpots];

}


-(void)roll {
	if (!hasHold) {
		spotCount = random() % 6 + 1;
	}
}

-(BOOL)containsPoint:(NSPoint) point {
	float radius = bounds.size.width / 10.0;
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius];
	return [path containsPoint: point];
}




@end
