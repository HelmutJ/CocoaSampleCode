//
// File:       ExampleCATiledLayerDelegate.m
//
// Abstract:   A sample delegate for a CATiledLayer that draws zoomable content into the tiled layer.
//
// Version:    1.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//

#import "ExampleCATiledLayerDelegate.h"

@implementation ExampleCATiledLayerDelegate

static CGFloat randomFloat()
{
	return random() / (double)LONG_MAX;
}

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		// Create our initial content.
		[self refreshContent];
	}
	return self;
}

-(void)dealloc
{
	CGPathRelease(path);
	CGColorRelease(bgColor);
	CGColorRelease(fgColor);
	[super dealloc];
}

-(void)refreshContent
{
	CGPathRelease(path);
	CGColorRelease(bgColor);
	CGColorRelease(fgColor);

	// We aren't interested in the actual content of the layer, but we want the same object
	// everytime we draw, so we create a CGPathRef to store a randomly generated path and a CGColorRef
	// to store the color to draw it in.
	bgColor = CGColorCreateGenericRGB(randomFloat(), randomFloat(), randomFloat(), 1.0);
	fgColor = CGColorCreateGenericRGB(randomFloat(), randomFloat(), randomFloat(), 1.0);
	path = CGPathCreateMutable();
	int sides = (random() % 18) + 1;
	CGPathMoveToPoint(path, NULL, randomFloat() * kTiledLayerExampleWidth, randomFloat() * kTiledLayerExampleHeight);
	for(int i = 0; i < sides; ++i)
	{
		CGPathAddLineToPoint(path, NULL, randomFloat() * kTiledLayerExampleWidth, randomFloat() * kTiledLayerExampleHeight);
	}
	CGPathCloseSubpath(path);
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
	// First, fill the clipping bounds with the background color.
	CGRect bounds = CGContextGetClipBoundingBox(context);
	CGContextSetFillColorWithColor(context, bgColor);
	CGContextFillRect(context, bounds);

	// Then add and fill the pre-generated path with the foreground color.
	CGContextSetFillColorWithColor(context, fgColor);
	CGContextAddPath(context, path);
	CGContextEOFillPath(context);
}

@end
