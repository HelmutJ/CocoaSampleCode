/*

File: QuartzDrawing.c

Abstract: Implements basic Quartz Drawing helpers used by the
	ShadingView, GradientView and PreviewView

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

#include "QuartzDrawing.h"

#define kRadialSize 1.0
#define kSquareBounds CGRectMake(-kRadialSize, -kRadialSize, kRadialSize * 2.0, kRadialSize * 2.0)

// Creates a square path that encompases the unit coordinate area.
CGPathRef GetSquarePath()
{
	static CGMutablePathRef square = NULL;
	if(square == NULL)
	{
		square = CGPathCreateMutable();
		CGPathAddRect(square, NULL, kSquareBounds);
	}
	return square;
}

// Creates a circular path that encompases the unit coordinate area.
CGPathRef GetCirclePath()
{
	static CGMutablePathRef circle = NULL;
	if(circle == NULL)
	{
		circle = CGPathCreateMutable();
		CGPathAddEllipseInRect(circle, NULL, kSquareBounds);
	}
	return circle;
}

// Creates a star-shaped path that encompases the unit coordinate area.
CGPathRef GetStarPath()
{
	static CGMutablePathRef star = NULL;
	if(star == NULL)
	{
		CGAffineTransform starPoints[5];
		int i;
		for(i = 0; i < 5; ++i)
		{
			starPoints[i] = CGAffineTransformMakeRotation(M_PI * 2.0 * i / 5.0);
		}
			
		star = CGPathCreateMutable();
		CGPathMoveToPoint(star, &starPoints[0], 0.0, kRadialSize);
		for(i = 2; i < 10; i += 2)
		{
			CGPathAddLineToPoint(star, &starPoints[i%5], 0.0, kRadialSize);
		}
		CGPathCloseSubpath(star);
	}
	return star;
}

typedef struct
{
	// the start value is where in the domain this
	// color should be at full intensity.
	CGFloat start;
	// the color to present at the start point and to
	// interpolate with.
	CGFloat components[4];
} LinearColorSpec;

static void LinearColorEvaluator(
	void *inInfo,
	const CGFloat *inInputs,
	CGFloat *outOutputs)
{
	// We assume 3 LinearColorSpecs, as that is what CreateShadingFunction creates.
	LinearColorSpec *colorInfo = (LinearColorSpec*)inInfo;
	CGFloat progression = inInputs[0];
	if(progression <= colorInfo[0].start)
	{
		memcpy(outOutputs, colorInfo[0].components, 4 * sizeof(CGFloat));
	}
	else if(progression <= colorInfo[1].start)
	{
		// progression is in the range of [color1Start, color2Start]. So we can calculate the correct
		// color we want a value between [0,1], so we convert the value of progression from the former domain
		// to the latter domain here.
		CGFloat value = (progression - colorInfo[0].start) / (colorInfo[1].start - colorInfo[0].start);
		int i;
		for(i = 0; i < 4; ++i)
		{
			// transition smoothly from color1 => color2
			outOutputs[i] = colorInfo[0].components[i] + value * (colorInfo[1].components[i] - colorInfo[0].components[i]);
		}
	}
	else if(progression <= colorInfo[2].start)
	{
		// progression is in the range of [color2Start, color3Start]. So we can calculate the correct
		// color we want a value between [0,1], so we convert the value of progression from the former domain
		// to the latter domain here.
		CGFloat value = (progression - colorInfo[1].start) / (colorInfo[2].start - colorInfo[1].start);
		int i;
		for(i = 0; i < 4; ++i)
		{
			// transition smoothly from color2 => color3
			outOutputs[i] = colorInfo[1].components[i] + value * (colorInfo[2].components[i] - colorInfo[1].components[i]);
		}
	}
	else
	{
		memcpy(outOutputs, colorInfo[2].components, 4 * sizeof(CGFloat));
	}
}

static void LinearColorReleaser(
	void *inInfo)
{
	free(inInfo);
}

// This is basically a bubble sort implemented in our tiny tiny domain of 3 color specs.
// A more sophisticated sort wasn't used for various sundry reasons
// including that they are all overkill for sorting 3 numbers.
void Sort(LinearColorSpec * specs)
{
	LinearColorSpec temp;
	if(specs[0].start > specs[1].start)
	{
		temp = specs[0]; specs[0] = specs[1]; specs[1] = temp;
	}
	if(specs[1].start > specs[2].start)
	{
		temp = specs[1]; specs[1] = specs[2]; specs[2] = temp;
	}
	// spec[2] is definately largest at this point...
	if(specs[0].start > specs[1].start)
	{
		temp = specs[0]; specs[0] = specs[1]; specs[1] = temp;
	}
	// spec[1] is definately larger than spec[0], thus we are sorted.
}

CGFunctionRef CreateShadingFunction(
	CGColorRef inColor1,
	CGFloat inColor1Start,
	CGColorRef inColor2,
	CGFloat inColor2Start,
	CGColorRef inColor3,
	CGFloat inColor3Start)
{
	// Version 0, use LinearColorEvaluator to derive values, and LinearColorReleaser to clean up.
	static CGFunctionCallbacks callbacks = {0, &LinearColorEvaluator, &LinearColorReleaser};
	// Our domain (input) consists of 1 parameter whose values range from 0.0 to 1.0 inclusive.
	CGFloat domain[2] = {0.0, 1.0};
	// Our range (output) consists of 4 parameters whose values range from 0.0 to 1.0 inclusive.
	CGFloat range[8] = {0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0};
	// Allocate enough space for 3 color specs.
	LinearColorSpec * info = malloc(sizeof(LinearColorSpec) * 3);
	// Fill them out
	info[0].start = inColor1Start;
	info[1].start = inColor2Start;
	info[2].start = inColor3Start;
	memcpy(info[0].components, CGColorGetComponents(inColor1), sizeof(info[0].components));
	memcpy(info[1].components, CGColorGetComponents(inColor2), sizeof(info[1].components));
	memcpy(info[2].components, CGColorGetComponents(inColor3), sizeof(info[2].components));
	// Sort the specs - this mimics what CGGradientCreateWithColors does.
	Sort(info);
	
	// Create the function
	CGFunctionRef function = CGFunctionCreate(info, 1, domain, 4, range, &callbacks);
	if(function == NULL)
	{
		// if we have a failure, then clean up now, since our callback will not be called.
		LinearColorReleaser(info);
	}
	
	return function;
}

CGGradientRef CreateGradient(
	CGColorRef inColor1,
	CGFloat inColor1Start,
	CGColorRef inColor2,
	CGFloat inColor2Start,
	CGColorRef inColor3,
	CGFloat inColor3Start)
{
	// Setup a CFArray with our CGColorRefs
	const void *colorRefs[3] = {inColor1, inColor2, inColor3};
	CFArrayRef colorArray = CFArrayCreate(kCFAllocatorDefault, colorRefs, 3, &kCFTypeArrayCallBacks);
	// Setup a parallel array that contains the start locations of those colors
	CGFloat locations[3] = {inColor1Start, inColor2Start, inColor3Start};
	// Create the gradient
	CGGradientRef gradient = CGGradientCreateWithColors(NULL, colorArray, locations);
	// clean up the color array (the gradient will retain it if necessary)
	CFRelease(colorArray);

	return gradient;
}

// A simple utility function to return a Generic RGB colorspace that we don't have to release.
CGColorSpaceRef GetGenericRGBColorspace()
{
	static CGColorSpaceRef rgb = NULL;
	if(rgb == NULL)
	{
		rgb = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	}
	return rgb;
}

void DrawEmbellishments(CGContextRef context, CGSize size, CGPoint startPoint, CGFloat startRadius, CGPoint endPoint, CGFloat endRadius, bool drawRadii)
{
	CGFloat startX = startPoint.x * size.width / 2.0;
	CGFloat startY = startPoint.y * size.height / 2.0;
	CGFloat endX = endPoint.x * size.width / 2.0;
	CGFloat endY = endPoint.y * size.height / 2.0;

	CGContextSaveGState(context);
	CGContextSetBlendMode(context, kCGBlendModeDifference);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);

	// Line joining crosshairs
	CGContextMoveToPoint(context, startX, startY);
	CGContextAddLineToPoint(context, endX, endY);
	CGContextStrokePath(context);

	// Crosshairs
	CGContextMoveToPoint(context, startX, startY - 5.0);
	CGContextAddLineToPoint(context, startX, startY + 5.0);
	CGContextStrokePath(context);
	CGContextMoveToPoint(context, startX - 5.0, startY);
	CGContextAddLineToPoint(context, startX + 5.0, startY);
	CGContextStrokePath(context);

	CGContextMoveToPoint(context, endX, endY - 5.0);
	CGContextAddLineToPoint(context, endX, endY + 5.0);
	CGContextStrokePath(context);
	CGContextMoveToPoint(context, endX - 5.0, endY);
	CGContextAddLineToPoint(context, endX + 5.0, endY);
	CGContextStrokePath(context);
	
	// Radii if requested
	if(drawRadii)
	{
		CGFloat startRX = startRadius * size.width / 2.0;
		CGFloat startRY = startRadius * size.height / 2.0;
		CGFloat endRX = endRadius * size.width / 2.0;
		CGFloat endRY = endRadius * size.height / 2.0;
		
		CGContextStrokeEllipseInRect(context, CGRectMake(startX - startRX, startY - startRY, startRX * 2.0, startRY * 2.0));
		CGContextStrokeEllipseInRect(context, CGRectMake(endX - endRX, endY - endRY, endRX * 2.0, endRY * 2.0));
	}

	CGContextRestoreGState(context);
}