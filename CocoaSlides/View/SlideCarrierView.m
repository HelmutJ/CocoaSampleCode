/*

File: SlideCarrierView.m

Abstract: A SlideCarrierView serves as the root view for each Asset's visual representation.  It draws a filled rounded-rect background, with a transparent cutout behind the slide's NSImageView, and mainly serves as a container view.  A SlideCarrierView also maintains a reference to the Asset that the slide represents.

Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/

#import "SlideCarrierView.h"
#import "AssetCollection.h"
#import "ImageAsset.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAAnimation.h>

#define BORDER_CORNER_RADIUS    8.0

static NSSound *highlightSound = nil;

@implementation SlideCarrierView

+ (id)defaultAnimationForKey:(NSString *)key {
    static CABasicAnimation *basicAnimation = nil;

    // Example of overriding default animations: AppKit provides default animation specifications for "frameOrigin" and "frameCenterRotation", but the default animations for these properties are configured to use a simple linear progress curve.  We'd like to have a more interesting animation progress curve that has some acceleration and deceleration, so here we substitute our own CABasicAnimation with an "Ease In, Ease Out" CATimingFunction.
    if ([key isEqualToString:@"frameOrigin"] || [key isEqualToString:@"frameCenterRotation"]) {
        if (basicAnimation == nil) {
            basicAnimation = [[CABasicAnimation alloc] init];
            [basicAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        }
        return basicAnimation;
    } else {
        return [super defaultAnimationForKey:key];
    }
}

- initWithAsset:(Asset *)newAsset {
    self = [self initWithFrame:NSMakeRect(0, 0, 80, 80)];
    if (self) {
	asset = [newAsset retain];
    }
    return self;
}

- (void)dealloc {
    [self setAsset:nil];
    [super dealloc];
}

- (Asset *)asset {
    return asset;
}

- (void)setAsset:(Asset *)newAsset {
    if (asset != newAsset) {
        id old = asset;
        asset = [newAsset retain];
        [old release];
    }
}

- (void)drawRect:(NSRect)rect {
    // Fill our background using a gradient in a rounded-rectangle shape.  NSGradient is a handy new class in Leopard that makes this really easy.
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:BORDER_CORNER_RADIUS yRadius:BORDER_CORNER_RADIUS];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
    [gradient drawInBezierPath:path angle:90.0];
    [gradient release];

    // Leave a transparent cutout behind our imageView.
    NSRect imageViewRect = [imageView frame];
    [[NSColor clearColor] set];
    NSRectFill(imageViewRect);
}

- (void)doHighlightEffect:(BOOL)highlight {
    // Example of using the new "contentFilters" property to easily apply Core Image effects to view content: Apply a highlight effect to the content drawn by this SlideCarrierView and its descendants, using a "CIPointillize" filter.  Other fun filters you might want to try include "CIBloom" and "CISepiaTone".
    NSArray *filters = nil;
    if (highlight) {
        // Instantiate the desired CIFilter, using the usual documented procedure for creating a CIFilter.
        CIFilter *filter = [CIFilter filterWithName:@"CIPointillize"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:4.0] forKey:@"inputRadius"];

        // A view's "contentFilters" property is an NSArray, allowing for CIFilters to be chained together to produce arbitrarily complex effects.  In this case we're just using a single filter, so we just need to wrap that single filter in an array.
        filters = [NSArray arrayWithObject:filter];
    } // Else, "filters" will be left as nil, and setContentFilters: below will remove the view's previously assigned contentFilters.

    // When applying the highlight effect (highlight == YES), we want the change in appearance to take effect immediately.  When unhighlighting (highlight == NO), however, we'd like for the removal of the filter effect to fade out gradually instead of being instantaneous.  There are two ways you can apply such a change without animating.  One is to set the enclosing NSAnimationContext's "duration" to zero, as we do below when "highlight" is true.  Another would be to message the view directly to make the contentFilters change, rather than messaging through the view's animator.  Doing "[self setContentFilters:filters]" (as with setting any other view property directly, without going through the animator) always has an instantaneous effect, regardless of the enclosing NSAnimationContext's duration.
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:highlight ? 0.0 : 0.5];
    [[self animator] setContentFilters:filters];
    [NSAnimationContext endGrouping];

    // Just for fun, play a sound when highlighting, to give a little bit of feedback.
    if (highlight) {
        if (highlightSound == nil) {
            highlightSound = [[NSSound soundNamed:@"Morse"] retain];
        }
        [highlightSound play];
    }
}

// Just to show off the use of Core Image filters to apply effect to a view's content, highlight the SlideCarrierView on mouseDown:, and unhighlight it on mouseUp:
- (void)mouseDown:(NSEvent *)theEvent {
    [self doHighlightEffect:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self doHighlightEffect:NO];
}

@end
