/*
     File: RadiantColorControl.m
 Abstract: Custom subclass of NSControl to display the color picker
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */



#import "RadiantColorControl.h"

@implementation RadiantColorControl

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {
        [self setColor:[NSColor redColor]];
    }
    return self;
}

- (void)dealloc {
    [_cachedImage release];
    [super dealloc];
}

- (void)_cacheColorImage {
    NSRect bounds = [self bounds];
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    // Create a bitmap image rep that will hold our resulting gradiant color image
    NSBitmapImageRep *bitRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32];

   CGFloat halfWidth = width / 2.0;
   CGFloat halfHeight = height / 2.0;
   CGFloat smallestDistance = halfWidth < halfHeight ? halfWidth : halfHeight;

   // We want to be able to grab the RGB components of the NSColor instance. In order to do this, we have to make sure it is in the RGB Color space.
   CGFloat red, green, blue, a;
   NSColor *colorAsRGB = [_color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
   [colorAsRGB getRed:&red green:&green blue:&blue alpha:&a];
    
    // If we have a pure-white color, make it easier to see
    if (red == 1 && green == 1 && blue == 1) {
        red = green = blue = 0.5;
    }
    
    // This is rather SLOW, but is easy to understand. Create a gradiant, where it is full intensity in the center of the circle, and zero on the edges.
    NSInteger x, y;
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            // How far are we from the center? sqrt(x^2 + y^2)
            CGFloat dist = sqrt(pow(x - halfWidth, 2) + pow(y - halfHeight, 2));
            CGFloat percentage = dist / smallestDistance;

            CGFloat r = percentage * red + (1 - percentage);
            CGFloat g = percentage * green + (1 - percentage);
            CGFloat b = percentage * blue + (1 - percentage);
            
            [bitRep setColor:[NSColor colorWithDeviceRed:r green:g blue:b alpha:1.0] atX:x y:y];
        }
    }
  
    _cachedImage = [[NSImage alloc] initWithSize:bounds.size];
    [_cachedImage addRepresentation:bitRep];
    
    [bitRep release];
}

- (BOOL)isOpaque {
    return YES;
}

- (void)setFrameSize:(NSSize)size { 
    [_cachedImage release];
    _cachedImage = nil;
    [super setFrameSize:size];
}

- (void)drawRect:(NSRect)rect {
#pragma unused (rect)
    if (_cachedImage == nil) {
        [self _cacheColorImage];
    }
    [_cachedImage compositeToPoint:[self bounds].origin operation:NSCompositeCopy];
}

- (NSColor *)color {
    return _color;
}

- (NSColor *)selectedColor {
    return _selectedColor;
}

- (void)setColor:(NSColor *)color {
    if (![_color isEqualTo:color] && ![_selectedColor isEqualTo:color]) {
        [_color release];
        _color = [color retain];
        [_selectedColor release];
        _selectedColor = [_color retain];
        [_cachedImage release];
        _cachedImage = nil;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
#pragma unused (theEvent)
    return YES;
}

- (NSColor *)colorAtPoint:(NSPoint)point {
    NSBitmapImageRep *rep = [[_cachedImage representations] objectAtIndex:0];
    return [rep colorAtX:point.x y:point.y];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [_selectedColor release];
    _selectedColor = [[self colorAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]] retain];
    [self sendAction:[self action] to:[self target]];
}

- (SEL)action {
    return _action;    
}

- (void)setAction:(SEL)a {
    _action = a;
}

- (void)setTarget:(id)target {
    _target = target;
}

- (id)target {
    return _target;
}

@end
