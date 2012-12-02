/*
    File: ContainerView.m
Abstract: ContainerView Implementation
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

#import "ContainerView.h"
#import "TreeViewColorConversion.h"
#import <QuartzCore/QuartzCore.h>

@implementation ContainerView

#pragma mark *** Initialization ***

- initWithFrame:(NSRect)newFrame {
    self = [super initWithFrame:newFrame];
    if (self) {

        // Initialize ivars directly.  As a rule, it's best to avoid invoking accessors from an -init... method, since they may wrongly expect the instance to be fully formed.

        borderColor = [[NSColor colorWithCalibratedRed:1.0 green:0.8 blue:0.4 alpha:1.0] retain];
        borderWidth = 3.0;
        cornerRadius = 8.0;
        fillColor = [[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.0 alpha:1.0] retain];

        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
    }
    return self;
}


#pragma mark *** Optimizations for Layer-Backed Mode ***

- (void)updateLayerAppearanceToMatchContainerView {
    CALayer *layer = [self layer];
    if (layer) {

        // Disable implicit animations during these layer property changes, to make them take effect immediately.
        BOOL actionsWereDisabled = [CATransaction disableActions];
        [CATransaction setDisableActions:YES];

        // Apply the ContainerView's appearance properties to its backing layer.  Important: While NSView metrics are conventionally expressed in points, CALayer metrics are expressed in pixels.  To produce the correct borderWidth and cornerRadius to apply to the layer, we must multiply by the window's userSpaceScaleFactor (which is normally 1.0, but may be larger on a higher-resolution display) to yield pixel units.
        CGFloat scaleFactor = [[self window] userSpaceScaleFactor];

        [layer setBorderWidth:(borderWidth * scaleFactor)];
        if (borderWidth > 0.0) {
            [layer setBorderColor:TreeView_CGColorFromNSColor(borderColor)];
        }
        [layer setCornerRadius:(cornerRadius * scaleFactor)];
        [layer setBackgroundColor:TreeView_CGColorFromNSColor(showingSelected ? [NSColor yellowColor] : [self fillColor])];

        [CATransaction setDisableActions:actionsWereDisabled];
    } else {
        [self setNeedsDisplay:YES];
    }
}

- (void)setLayer:(CALayer *)newLayer {
    [super setLayer:newLayer];
    if (newLayer) {
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
        [self updateLayerAppearanceToMatchContainerView];
    }
}


#pragma mark *** Drawing ***

/* Since we set each ContainerView's layerContentsRedrawPolicy to NSViewLayerContentsRedrawNever, this -drawRect: method will only be invoked if the ContainerView is window-backed.  If the ContainerView is layer-backed, the layer's appearance properties, as configured in -updateLayerAppearanceToMatchContainerView above, provide this drawing for us.
*/
- (void)drawRect:(NSRect)rect {
    float halfBorderWidth = 0.5 * [self borderWidth];
    NSRect borderRect = NSInsetRect([self bounds], halfBorderWidth, halfBorderWidth);
    CGFloat effectiveRadius = MAX(0.0, [self cornerRadius] - halfBorderWidth); // CALayer's cornerRadius applies to its overall shape, with its border (if any) extending for borderWidth pixels from there.  A srtroked NSBezierPath extends by half the path's line width to either side of the ideal path.  To produce rendered results that closely match those in layer-backed mode, since ContainerView is optimized to leverage CALayer's programmatic drawing capabilities when layer-backed, we need to inset the path we're going to stroke by half the border width.
    NSBezierPath *borderStrokePath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:effectiveRadius yRadius:effectiveRadius];

    // Fill background.
    [(showingSelected ? [NSColor yellowColor] : [self fillColor]) set];
    [borderStrokePath fill];

    // Stroke border.
    if (halfBorderWidth > 0.0) {
        [borderStrokePath setLineWidth:[self borderWidth]];
        [[self borderColor] set];
        [borderStrokePath stroke];
    }
}


#pragma mark *** Making Style Properties Animatable Using "animator" Syntax ***

+ (id)defaultAnimationForKey:(NSString *)key {
    static NSSet *animatablePropertyKeys = nil;
    if (animatablePropertyKeys == nil) {
        animatablePropertyKeys = [[NSSet alloc] initWithObjects:@"borderColor", @"borderWidth", @"cornerRadius", @"fillColor", nil];
    }
    if ([animatablePropertyKeys containsObject:key]) {
        // If the key names one of our appearance properties that we want to make animatable using the "animator" proxy syntax, return a default animation specification.  Note that, in order for this to work, the setter methods for these properties *must* mark affected view areas as needing display.
        return [CABasicAnimation animation];
    } else {
        // For keys you don't handle, always delegate up to super.
        return [super defaultAnimationForKey:key];
    }
}


#pragma mark *** Styling ***

- (NSColor *)borderColor {
    return borderColor;
}

- (void)setBorderColor:(NSColor *)color {
    if (borderColor != color) {
        [borderColor release];
        borderColor = [color copy];
        [self updateLayerAppearanceToMatchContainerView];
    }
}

- (float)borderWidth {
    return borderWidth;
}

- (void)setBorderWidth:(float)width {
    if (borderWidth != width) {
        borderWidth = width;
        [self updateLayerAppearanceToMatchContainerView];
    }
}

- (float)cornerRadius {
    return cornerRadius;
}

- (void)setCornerRadius:(float)radius {
    if (cornerRadius != radius) {
        cornerRadius = radius;
        [self updateLayerAppearanceToMatchContainerView];
    }
}

- (NSColor *)fillColor {
    return fillColor;
}

- (void)setFillColor:(NSColor *)color {
    if (fillColor != color) {
        [fillColor release];
        fillColor = [color copy];
        [self updateLayerAppearanceToMatchContainerView];
    }
}


#pragma mark *** Selection State ***

- (BOOL)showingSelected {
    return showingSelected;
}

- (void)setShowingSelected:(BOOL)newShowingSelected {
    if (showingSelected != newShowingSelected) {
        showingSelected = newShowingSelected;
        [self updateLayerAppearanceToMatchContainerView];
    }
}


#pragma mark *** Archiving/Unarchiving ***

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        if ([decoder allowsKeyedCoding]) {
            borderColor = [[decoder decodeObjectForKey:@"borderColor"] retain];
            borderWidth = [decoder decodeFloatForKey:@"borderWidth"];
            cornerRadius = [decoder decodeFloatForKey:@"cornerRadius"];
            fillColor = [[decoder decodeObjectForKey:@"fillColor"] retain];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeObject:borderColor forKey:@"borderColor"];
        [coder encodeFloat:borderWidth forKey:@"borderWidth"];
        [coder encodeFloat:cornerRadius forKey:@"cornerRadius"];
        [coder encodeObject:fillColor forKey:@"fillColor"];
    }
}


#pragma mark *** Cleanup ***

- (void)dealloc {
    [borderColor release];
    [fillColor release];
    [super dealloc];
}

@end
