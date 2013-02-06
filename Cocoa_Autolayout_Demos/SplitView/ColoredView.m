/*
    File: ColoredView.m
Abstract: Draws a colored view with a gradient.  This does not illustrate anything with respect to autolayout.
 Version: 1.2

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

#import "ColoredView.h"


@implementation ColoredView

@synthesize backgroundColor=_backgroundColor, backgroundColorName=_backgroundColorName;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        _backgroundHue = 1; // red
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)dealloc {
    [_backgroundColor release];
    [super dealloc];
}

- (void)setBackgroundColor:(NSColor *)newColor {
    if (newColor != _backgroundColor) {
        [_backgroundColor release];
        _backgroundColor = [newColor copy];
        _backgroundHue = [[_backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] hueComponent];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColorName:(NSString *)newName {
    if (newName != _backgroundColorName) {
        [_backgroundColorName release];
        _backgroundColorName = nil;
        
        SEL colorSelector = NSSelectorFromString(newName);
        if ([[NSColor class] respondsToSelector:colorSelector]) {
            NSColor *background = [[NSColor class] performSelector:colorSelector];
            if ([background isKindOfClass:[NSColor class]]) {
                self.backgroundColor = background;

                _backgroundColorName = [newName copy];
                [self setIdentifier:_backgroundColorName];
            } else {
                NSLog(@"I don't know what I just did, but it did not create a color");
            }
        } else {
            NSLog(@"Invalid color name. %@", newName);
        }
    }
}

/* Convert HSB to RGB. Come in with hue, saturation, and brightness all in the range 0..1.
 */
static void  _NXHSBToRGB (CGFloat hue, CGFloat saturation, CGFloat brightness, CGFloat *red, CGFloat *green, CGFloat *blue) {
    
    CGFloat hueTimesSix, frac, p1, p2, p3;
    
    if (hue == 1.0) {
        hue = 0.0;
    }
    
    hueTimesSix = hue * 6.0;
    frac = hueTimesSix - (NSInteger)hueTimesSix;
    p1 = brightness * (1.0 - saturation);
    p2 = brightness * (1.0 - (saturation * frac));
    p3 = brightness * (1.0 - (saturation * (1.0 - frac)));
    
    switch ((NSInteger)hueTimesSix) {
        case 0:
            *red = brightness;
            *green = p3;
            *blue = p1;
            break;
        case 1:
            *red = p2;
            *green = brightness;
            *blue = p1;
            break;
        case 2:
            *red = p1;
            *green = brightness;
            *blue = p3;
            break;
        case 3:
            *red = p1;
            *green = p2;
            *blue = brightness;
            break;
        case 4:
            *red = p3;
            *green = p1;
            *blue = brightness;
            break;
        case 5:
            *red = brightness;
            *green = p1;
            *blue = p2;
            break;
    }
    
}

#define DEG2RAD(x)  ((x) * M_PI / 180.0)

static void CapacityShader(void* info, const CGFloat* in, CGFloat* out) {
    ColoredView *self = info;
            
    CGFloat y = in[0];
    
    CGFloat hue, saturation, brightness;
    CGFloat brightness1 = 0.87;
    CGFloat brightness2 = 0.12;
    
    hue = self->_backgroundHue;
    saturation = 0.8;
    brightness = brightness1 + brightness2 * sin(DEG2RAD((y - .07)*360*1.45)) * exp(-1.5 * y) + 0.07 * y;
        
    // convert to RGB. solid alpha
    //
    _NXHSBToRGB(hue, saturation, brightness, &out[0], &out[1], &out[2]);
    out[3] = 1.0;
}

static void ShadeWithCapacityGradient(ColoredView *self) {
    
    CGFunctionCallbacks callbacks = { 0 /*version*/, CapacityShader, NULL /*release*/ };
    
    // create a new one if needed
    //
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFunctionRef   function   = CGFunctionCreate(self, 1, NULL, 4, NULL, &callbacks);
    
    // our shader works from top to bottom hence start is at y = 1.0 and end is at y = 0.0
    //
    CGShadingRef shader = CGShadingCreateAxial(colorSpace, CGPointMake(0, 1), CGPointMake(0, 0), function, false, false);
    
    CGFunctionRelease(function);
    CGColorSpaceRelease(colorSpace);
    
    // and fill in clip rectangle
    //
    CGContextDrawShading((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], shader);
    CFRelease(shader);
}


- (void)drawRect:(NSRect)dirtyRect {
    [NSGraphicsContext saveGraphicsState];
    
    // shading fills clip so clip to the rectangle we want to fill
    //
    NSRectClip([self bounds]);
    
    // shading assumes 1 pixel high rect, origin at 0,0, normal direction. scale
    // so we fill the actual destination rectangle and flip if necessary
    //
    NSAffineTransform* originTransform = [NSAffineTransform transform];
    if ([self isFlipped]) {
        [originTransform translateXBy:NSMinX([self bounds]) yBy:NSMaxY([self bounds])];
        [originTransform scaleXBy:1.0 yBy:-1.0];
    } else {
        [originTransform translateXBy:NSMinX([self bounds]) yBy:NSMinY([self bounds])];
    }
    [originTransform scaleXBy:NSWidth([self bounds]) yBy:NSHeight([self bounds])];
    [originTransform concat];
    
    ShadeWithCapacityGradient(self);
    
    [NSGraphicsContext restoreGraphicsState];
    
}

@end
