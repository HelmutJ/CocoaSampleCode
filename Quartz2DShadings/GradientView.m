/*

File: GradientView.m

Abstract: Implements a view that uses a CGGradientRef and the given
	parameters to render a gradient within it's bounds.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#import "GradientView.h"

@implementation GradientView

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(self != nil)
	{
		// Default to a square clipping area,
		// linear gradient, show the clip & end points,
		// and don't extend past start or end point.
		shape = 0;
		type = 0;
		gradient = NULL;
		showClip = showEndpoints = true;
		extendStart = extendEnd = false;
	}
	return self;
}

-(void)dealloc
{
	CGGradientRelease(gradient);
	[super dealloc];
}

-(void)drawRect:(NSRect)rect
{
	// Obtain the current context
	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	// Move 0,0 to the center of the view
	CGContextTranslateCTM(context, rect.size.width / 2.0, rect.size.height / 2.0);
	
	CGContextSaveGState(context);

	// Scale the coordinate system to -1,1 on both axies.
	CGContextScaleCTM(context, rect.size.width / 2.0, rect.size.height / 2.0);
	
	// Clip to the correct shape.
	switch(shape)
	{
		case 0: // Square
			CGContextAddPath(context, GetSquarePath());
			CGContextClip(context);
			break;
		
		case 1: // Triangle
			CGContextAddPath(context, GetCirclePath());
			CGContextClip(context);
			break;
		
		case 2: // Filled Star
			CGContextAddPath(context, GetStarPath());
			CGContextClip(context);
			break;
		
		case 3: // Hollow Star
			CGContextAddPath(context, GetStarPath());
			CGContextEOClip(context);
			break;
	}
	
	// If we need to show the clipping region, then add a black fill with 25% opacity.
	if(showClip)
	{
		CGContextSetGrayFillColor(context, 0.0, 0.25);
		CGContextFillRect(context, CGRectMake(-1, -1, 2, 2));
	}
	
	// Draw the correct gradient
	switch(type)
	{
		case 0:	// Linear (perpendicular to the line from startPoint to endPoint)
			CGContextDrawLinearGradient(context, gradient, startPoint, endPoint,
				(extendStart ? kCGGradientDrawsBeforeStartLocation : 0) | (extendEnd ? kCGGradientDrawsAfterEndLocation : 0));
			break;
			
		case 1:	// Radial (concentric circles, interpolating radius from startRadius to endRadius,
				//and center from startPoint to endPoint)
			CGContextDrawRadialGradient(context, gradient, startPoint, startRadius, endPoint, endRadius,
				(extendStart ? kCGGradientDrawsBeforeStartLocation : 0) | (extendEnd ? kCGGradientDrawsAfterEndLocation : 0));
			break;
	}
	
	CGContextRestoreGState(context);

	// If we need to show the endpoints, then draw them.
	if(showEndpoints)
	{
		DrawEmbellishments(context, NSSizeToCGSize(rect.size), startPoint, startRadius, endPoint, endRadius, type == 1);
	}
}

-(void)setShapeSquare
{
	shape = 0;
	[self setNeedsDisplay:YES];
}

-(void)setShapeCircle
{
	shape = 1;
	[self setNeedsDisplay:YES];
}

-(void)setShapeFilledStar
{
	shape = 2;
	[self setNeedsDisplay:YES];
}

-(void)setShapeHollowStar
{
	shape = 3;
	[self setNeedsDisplay:YES];
}

-(void)setTypeAxial
{
	type = 0;
	[self setNeedsDisplay:YES];
}

-(void)setTypeRadial
{
	type = 1;
	[self setNeedsDisplay:YES];
}

-(void)setExtendStart:(BOOL)extend
{
	if(extend != extendStart)
	{
		extendStart = extend;
		[self setNeedsDisplay:YES];
	}
}

-(void)setExtendEnd:(BOOL)extend
{
	if(extend != extendEnd)
	{
		extendEnd = extend;
		[self setNeedsDisplay:YES];
	}
}

-(void)setStartPoint:(CGPoint)p
{
	startPoint = p;
	[self setNeedsDisplay:YES];
}

-(void)setEndPoint:(CGPoint)p
{
	endPoint = p;
	[self setNeedsDisplay:YES];
}

-(void)setStartRadius:(CGFloat)r
{
	startRadius = r;
	[self setNeedsDisplay:YES];
}

-(void)setEndRadius:(CGFloat)r
{
	endRadius = r;
	[self setNeedsDisplay:YES];
}

-(void)setShowClip:(BOOL)yn
{
	showClip = yn;
	[self setNeedsDisplay:YES];
}

-(void)setShowEndpoints:(BOOL)yn
{
	showEndpoints = yn;
	[self setNeedsDisplay:YES];
}

-(void)setGradient:(CGGradientRef)g
{
	if(gradient != g)
	{
		CGGradientRelease(gradient);
		CGGradientRetain(g);
		gradient = g;
		[self setNeedsDisplay:YES];
	}
}

@end