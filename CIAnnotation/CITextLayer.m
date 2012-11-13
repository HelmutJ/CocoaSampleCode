
/*
     File: CITextLayer.m
 Abstract: The CITextLayer handles the rendering of the text.
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

#import "CITextLayer.h"


@implementation TextObject

- (id)initWithRect:(CGRect)inRect
{
    self = [super init];
    
    if (self) {
        textRect = *(NSRect*)(&inRect);
        text = [[NSAttributedString alloc] initWithString:@"Text" attributes:@{ NSFontAttributeName:[NSFont messageFontOfSize:48.0]}];
    }
    return self;
}

- (void)dealloc
{
    [text release];
    [super dealloc];
}

- (NSAttributedString*)getText
{
    return text;
}

- (void)setText:(NSAttributedString*)inString
{
    [inString retain];
    [text release];
    text = [inString copy];
    [inString release];
    textRect.size = [text size];
}

- (NSRect)getTextRect
{
    return textRect;
}

- (void)renderIntoCurrentContext
{
    [text drawInRect:textRect];
}

- (BOOL)pointInObject:(NSPoint)inPoint;
{
    return NSPointInRect(inPoint, textRect);
}

@end

//-----------------------------------------------------------------------------------------------------------

@interface CITextLayer (private)

- (void)renderText;

@end

@implementation CITextLayer

- (id)initWithDelegate:(id)inDelegate targetRect:(CGRect)inRect  ciContext:(CIContext*)inCIContext
{
    self = [super initWithDelegate:inDelegate];
    
    if (self == nil)
        return nil;
    
    ciContext = inCIContext;

    textObjects = [[NSMutableArray alloc] init];
    layerRect = inRect;
    
    invertFilter = [[CIFilter filterWithName:@"CIColorInvert"] retain];
    blurFilter = [[CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputRadius", [NSNumber numberWithDouble:3.0], nil] retain];
    compositeFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
    
    if(ciContext) 
    {
        // if a CIContext is available, we use it to create a CGLayer from that context as it is colormatched
        layer = [ciContext createCGLayerWithSize:layerRect.size  info: nil];
        bitmapContext = CGLayerGetContext(layer);
    } else {
        // otherwise we create a CGBitmapContext
        CGColorSpaceRef	colorspace = CGColorSpaceCreateDeviceRGB();	
        size_t		bytesPerRow, width, height;
	
        width = floor(layerRect.size.width);
        height = floor(layerRect.size.height);
        bytesPerRow = (width * 4 + 63) & ~63;
        bitmapData = calloc(bytesPerRow * height, 1);
        bitmapContext = CGBitmapContextCreate(bitmapData, width, height, 8 ,bytesPerRow, colorspace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorspace);
    }
    [self renderText]; // create initial image
    return self;
}

- (void)dealloc
{
    [textImage release];
    [textObjects release];
    [invertFilter release];
    [blurFilter release];
    if(layer) 
    {
        CGLayerRelease(layer);
    } else {
        CGContextRelease(bitmapContext);
        free(bitmapData);
    }
    [super dealloc];
}

- (void)renderText
{
    // release the old image
    [textImage release];
    textImage = nil;
    
    // render the text objects into the context
    CGContextClearRect(bitmapContext,layerRect);
    NSGraphicsContext		*savedContext = [NSGraphicsContext currentContext];
    NSGraphicsContext	    *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:bitmapContext flipped:NO];
    
    [NSGraphicsContext setCurrentContext:graphicsContext];
    [textObjects makeObjectsPerformSelector:@selector(renderIntoCurrentContext)];

    if(layer)
    {
        // we can render using the CGLayer
        textImage = [[CIImage alloc] initWithCGLayer: layer];
    } else {
        // create a CIImage from the bitmap context by the way of creating a CGImage - this causes a copy !
        CGImageRef		bitmapImage = nil;

        bitmapImage = CGBitmapContextCreateImage(bitmapContext);
        if(!bitmapImage)
            return;
        
        textImage = [[CIImage alloc] initWithCGImage: bitmapImage];
        CGImageRelease(bitmapImage);	// now retained by the CIImage
    }
    [invertFilter setValue:textImage forKey:@"inputImage"];
    [blurFilter setValue:[invertFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositeFilter setValue:textImage forKey:@"inputImage"];
    [compositeFilter setValue:[blurFilter valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
	[NSGraphicsContext setCurrentContext:savedContext];
}

- (CIImage*)getLayerImage
{
    return [compositeFilter valueForKey:@"outputImage"];
}

- (void)mouseDown:(NSEvent*)theEvent view:(NSView*)inView
{
    NSPoint		    location = [inView convertPoint:[theEvent locationInWindow] fromView:nil];
    
    NSEnumerator	    *enumerator = [textObjects objectEnumerator];
    TextObject		    *textObject = nil;
    
    // check if the click was on an existing text object
    while(textObject = [enumerator nextObject])
    {
        if([textObject pointInObject:location])
            break;
	    textObject = nil;
    }
    if(!textObject) // user did not click on a text object so lets create a new one
    {
        CGRect	    targetRect = CGRectMake(location.x, location.y, 50.0, 50.0);
        textObject = [[TextObject alloc] initWithRect:targetRect];
        [textObjects addObject:textObject];
        [textObject release];			    // now retained by textObjects array
    }
    [layerDelegate doTextEditSession:textObject];
    if([textObject getText] == nil)		    // no text means the text object gets deleted
        [textObjects removeObject:textObject];
    // render our output
    [self renderText];
    // cause the document to redraw
    [layerDelegate refresh:[self getRect]];
}

@end
