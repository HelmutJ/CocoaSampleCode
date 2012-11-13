
/*
     File: CIPaintLayer.m
 Abstract: The CIPaintLayer handles painting.
  Version: 1.3
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "CIPaintLayer.h"
#import "CIPaintLayer.h"


@implementation CIPaintLayer


- (id)initWithDelegate:(id)inDelegate targetRect:(CGRect)inRect
{
    self = [super initWithDelegate:inDelegate];
    
    if (self == nil)
	return nil;

    brushSize = 5.0;

    cicolor = [[CIColor alloc] initWithColor: [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0]];
    brushFilter = [[CIFilter filterWithName: @"PaintFilter" keysAndValues:
						@"inputColor", cicolor,
						@"inputWidth", [NSNumber numberWithDouble:brushSize], nil] retain];
    compositeFilter = [[CIFilter filterWithName: @"CISourceOverCompositing"] retain];
    imageAccumulator = [[CIImageAccumulator alloc] initWithExtent:inRect format:kCIFormatRGBA16];
    
    //set the accumulator up with an empty image
    [imageAccumulator setImage:[[CIFilter filterWithName:@"CIConstantColorGenerator"
	 keysAndValues:@"inputColor",[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0], nil] valueForKey:@"outputImage"]];
    return self;
}

- (void)dealloc
{
    [imageAccumulator release];
    [brushFilter release];
    [compositeFilter release];
    [cicolor release];
    [super dealloc];
}

- (CIImage*)getLayerImage
{
    return [imageAccumulator image];
}

- (void)mouseDown:(NSEvent*)theEvent view:(NSView*)inView
{
    BOOL		    dragActive = YES;
    NSPoint		    lastPoint, location = [inView convertPoint:[theEvent locationInWindow] fromView:nil];
    CGRect		    rect;
    NSAutoreleasePool	    *myPool = nil;
    NSEvent*		    event = NULL;
    NSWindow		    *targetWindow = [inView window];

    
    myPool = [[NSAutoreleasePool alloc] init];
    while (dragActive)
    {	    
	    lastPoint = location;
	    event = [targetWindow nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)
							untilDate:[NSDate distantFuture]
							inMode:NSEventTrackingRunLoopMode
							dequeue:YES];
    
	    if(!event)
		    continue;
	    location = [inView convertPoint:[event locationInWindow] fromView:nil];
	    switch ([event type])
	    {
		    case NSLeftMouseDragged:
                rect = CGRectUnion(CGRectMake(lastPoint.x-brushSize, lastPoint.y-brushSize, 2.0*brushSize, 2.0*brushSize), 
					    CGRectMake(location.x-brushSize, location.y-brushSize, 2.0*brushSize, 2.0*brushSize));
                [brushFilter setValue: [CIVector vectorWithX: lastPoint.x Y:lastPoint.y] forKey: @"inputPoint1"];
                [brushFilter setValue: [CIVector vectorWithX: location.x Y:location.y] forKey: @"inputPoint2"];
			
                [compositeFilter setValue: [brushFilter valueForKey: @"outputImage"] forKey: @"inputImage"];
                [compositeFilter setValue: [imageAccumulator image] forKey: @"inputBackgroundImage"];
			
                [imageAccumulator setImage: [compositeFilter valueForKey: @"outputImage"] dirtyRect: rect];
                [layerDelegate refresh:rect];
                break;
			
		    case NSLeftMouseUp:
                dragActive = NO;
                break;
			
            default:
                break;
        }
    }
    [myPool release];
}

@end
