//     File: PlayView.m
// Abstract: Implementation file for PlayView class of HID_Config_Save project
//  Version: 5.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 
#import "PlayView.h"

@implementation PlayView

- (id) initWithFrame: (NSRect) frame {
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code here.
		x = y = 128.f;
		minX = minY = 0.f;
		maxX = maxY = 255.f;
	}
	
	return (self);
} // initWithFrame

// Drawing code here.
- (void) drawRect: (NSRect) dirtyRect {
#pragma unused (dirtyRect)
	NSRect bounds = [self bounds];
	
	// erase us
	[[NSColor blackColor] setFill];
	NSRectFill(bounds);

	// now calculate the axis coordinates (x, y)
	CGFloat width = NSWidth(bounds), height = NSHeight(bounds);
	
	CGFloat dotRadius = MAX(MAX(width, height) / 40.f, 5.f);
	CGFloat dotDiameter = dotRadius * 2.f;
	
	width -= dotDiameter;
	height -= dotDiameter;
	
	CGFloat rangeX = maxX - minX, rangeY = maxY - minY;
	CGFloat dotX = NSMinX(bounds) + ((x - minX) * width / rangeX) + dotRadius;
	CGFloat dotY = NSMaxY(bounds) - ((y - minY) * height / rangeY) - dotRadius;
	
	NSRect dotBounds = NSMakeRect(dotX - dotRadius, dotY - dotRadius, dotDiameter, dotDiameter);
	
	// draw the dot
	if (thrust) {
		[[NSColor greenColor] setFill];
	} else {
		[[NSColor yellowColor] setFill];
	}
	[[NSBezierPath bezierPathWithOvalInRect:dotBounds] fill];

	NSBezierPath *thePath = [NSBezierPath bezierPath];
	if (fire) {
		// draw the lasers
		[thePath moveToPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))];
		[thePath lineToPoint:NSMakePoint(dotX, dotY)];
		[thePath moveToPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))];
		[thePath lineToPoint:NSMakePoint(dotX, dotY)];
		[thePath moveToPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
		[thePath lineToPoint:NSMakePoint(dotX, dotY)];
		[thePath moveToPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
		[thePath lineToPoint:NSMakePoint(dotX, dotY)];
		[[NSColor redColor] setStroke];
	} else {
		// draw the crosshairs
		[thePath moveToPoint:NSMakePoint(NSMinX(bounds), dotY)];
		[thePath lineToPoint:NSMakePoint(NSMaxX(bounds), dotY)];
		[thePath moveToPoint:NSMakePoint(dotX, NSMinY(bounds))];
		[thePath lineToPoint:NSMakePoint(dotX, NSMaxY(bounds))];
		[[NSColor grayColor] setStroke];
	}
	[thePath closePath];
	[thePath stroke];
	
} // drawRect

- (void) setX: (double) inValue {
	if (inValue < minX) {
		inValue = minX;
	}
	if (inValue > maxX) {
		inValue = maxX;
	}
	if (x != inValue) {
		x = inValue;
		[self setNeedsDisplay:YES];
	}
} // setX

- (void) setY: (double) inValue {
	if (inValue < minY) {
		inValue = minY;
	}
	if (inValue > maxY) {
		inValue = maxY;
	}
	if (y != inValue) {
		y = inValue;
		[self setNeedsDisplay:YES];
	}
} // setY

- (void) setMinX: (double) inValue {
	if (minX != inValue) {
		minX = inValue;
		[self setNeedsDisplay:YES];
	}
} // setMinX

- (void) setMinY: (double) inValue {
	if (minY != inValue) {
		minY = inValue;
		[self setNeedsDisplay:YES];
	}
} // setMinY

- (void) setMaxX: (double) inValue {
	if (maxX != inValue) {
		maxX = inValue;
		[self setNeedsDisplay:YES];
	}
} // setMaxX

- (void) setMaxY: (double) inValue {
	if (maxY != inValue) {
		maxY = inValue;
		[self setNeedsDisplay:YES];
	}
} // setMaxY

- (void) setThrust: (BOOL) inValue {
	if (thrust != inValue) {
		thrust = inValue;
		[self setNeedsDisplay:YES];
	}
} // setThrust

- (void) setFire: (BOOL) inValue {
	if (fire != inValue) {
		fire = inValue;
		[self setNeedsDisplay:YES];
	}
} // setFire

@synthesize x, y, minX, minY, maxX, maxY, thrust, fire;

@end
