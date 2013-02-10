/*
     File: SliceView.m
 Abstract: View to display the slice guidelines
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "SliceView.h"


@implementation SliceView

-(void)drawRect:(NSRect)rect {
	//Draw the image
	[img drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
	
	//Query the view's width/height
	NSRect vBounds = [self bounds];
	float vWidth = vBounds.size.width;
	float vHeight = vBounds.size.height;
	
	//Set the active color to red and create the lines
	[[NSColor redColor] set];
	NSBezierPath* path = [NSBezierPath bezierPath];
	
	//The two horizontal slice lines
	[path moveToPoint:NSMakePoint(0, southWest.y)];
	[path lineToPoint:NSMakePoint(vWidth, southWest.y)];
	[path moveToPoint:NSMakePoint(0, northEast.y)];
	[path lineToPoint:NSMakePoint(vWidth, northEast.y)];
	
	//The two vertical slice lines
	[path moveToPoint:NSMakePoint(southWest.x, 0)];
	[path lineToPoint:NSMakePoint(southWest.x, vHeight)];
	[path moveToPoint:NSMakePoint(northEast.x, 0)];
	[path lineToPoint:NSMakePoint(northEast.x, vHeight)];
	
	//Draw the lines
	[path stroke];
}

//Slice up the image using the center slice bounds
-(void)sliceWithRect:(CGRect)rect {
	//Get the bounds for this view
	NSRect vBounds = [self bounds];
	float vWidth = vBounds.size.width;
	float vHeight = vBounds.size.height;
	
	//Calculate the origin and dimmensions in view coordinates
	float x0 = rect.origin.x * vWidth;
	float y0 = rect.origin.y * vHeight;
	float width = rect.size.width * vWidth;
	float height = rect.size.height * vHeight;
	
	//Set the corners of the center slice to be used in 'drawRect:' 
	southWest = NSMakePoint(x0, y0);
	northEast = NSMakePoint(x0 + width, y0 + height);
	
	//Tell the system that this view needs to be re-drawn
	[self setNeedsDisplay:YES];
}

@synthesize img;

@end
