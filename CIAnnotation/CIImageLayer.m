
/*
     File: CIImageLayer.m
 Abstract: The CIImageLayer handles the image with its filters.
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

#import "CIImageLayer.h"

const CGFloat	    scale = 4.0;

@implementation CIImageLayer


- (id)initWithDelegate:(id)inDelegate imageURL:(NSURL*)inURL
{
    self = [super initWithDelegate:inDelegate];
    
    image = [[CIImage alloc] initWithContentsOfURL:inURL];
    if(!image)
    {
        [self release];
        return nil;
    }
    radius = 50.0;
    // add the color correction filter
    colorFilter = [[CIFilter filterWithName:@"CIColorControls"] retain]; 
    [colorFilter setDefaults];
    [colorFilter setValue:image forKey:@"inputImage"];
    // apply an affine transform to the iamge to scale it to one quarter of its size
    scaleFilter = [[CIFilter filterWithName:@"CIAffineTransform"] retain];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleBy: 1.0 / scale];
    [scaleFilter setValue:transform forKey:@"inputTransform"];
    [scaleFilter setValue:[colorFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    // add the magnifying lens filter
    lensFilter = [[CIFilter filterWithName: @"LensFilter"] retain];
    [lensFilter setDefaults];
    [lensFilter setValue:[scaleFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [lensFilter setValue:[CIVector vectorWithX:(layerRect.size.width * 0.5) Y:(layerRect.size.height * 0.5)] forKey:@"inputCenter"];
    [lensFilter setValue:[NSNumber numberWithDouble:scale] forKey:@"inputMagnification"];
    [lensFilter setValue: [CIVector vectorWithX:[[scaleFilter valueForKey:@"outputImage"] extent].size.width * 0.5 Y:[[scaleFilter valueForKey:@"outputImage"] extent].size.height * 0.5] forKey: @"inputCenter"];
    layerRect = [[lensFilter valueForKey:@"outputImage"] extent];
    return self;
}

- (void)dealloc
{
    [scaleFilter release];
    [lensFilter release];
    [colorFilter release];
    [image release];
    [super dealloc];
}

- (CIImage*)getLayerImage
{
    if(showLens)
	return [lensFilter valueForKey:@"outputImage"];
    else
	return [scaleFilter valueForKey:@"outputImage"];
}

- (void)mouseDown:(NSEvent*)theEvent view:(NSView*)inView
{
    BOOL		    dragActive = YES;
    NSPoint		    location;
    CIVector		    *oldLocationVector;
    CGRect		    oldRect, currentRect, dirtyRect;
    CGFloat		    lensRadius = [[lensFilter valueForKey:@"inputRingWidth"] doubleValue]+ ([[lensFilter valueForKey:@"inputWidth"] doubleValue] * 0.5);
    NSAutoreleasePool	    *myPool = nil;
    NSEvent*		    event = NULL;
    NSWindow		    *targetWindow = [inView window];

    
    myPool = [[NSAutoreleasePool alloc] init];
    while (dragActive)
    {	    
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
                oldLocationVector = [lensFilter valueForKey:@"inputCenter"];
                oldRect = CGRectMake([oldLocationVector X] - lensRadius, [oldLocationVector Y] - lensRadius, 2.0 * lensRadius, 2.0 * lensRadius);
                currentRect = CGRectMake(location.x - lensRadius, location.y - lensRadius, 2.0 * lensRadius, 2.0 * lensRadius);
                dirtyRect = CGRectUnion(oldRect, currentRect);
                [lensFilter setValue: [CIVector vectorWithX: location.x Y:location.y] forKey: @"inputCenter"];

                [layerDelegate refresh:dirtyRect];
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

- (void)setImageSetting:(ImageSetting)setting value:(CGFloat)inValue
{
    NSNumber	*imageValue = [NSNumber numberWithDouble:inValue];
    
    switch(setting)
    {
        case kContrastSetting:
            [colorFilter setValue:imageValue forKey:@"inputContrast"];
            break;

        case kBrightnessSetting:
            [colorFilter setValue:imageValue forKey:@"inputBrightness"];
            break;

        case kSaturationSetting:
            [colorFilter setValue:imageValue forKey:@"inputSaturation"];
            break;
    }
    [scaleFilter setValue:[colorFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [lensFilter setValue:[scaleFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [layerDelegate refresh:[self getRect]];
}

- (void)showLens:(BOOL)inShowLens
{
    showLens = inShowLens;
}

@end
