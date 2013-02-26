/*

File: SlideshowView.m

Abstract: A SlideshowView displays a single NSImage at a time, and can transition to a new image using any of the Core Animation / Core Image supported transition effects.

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

#import "SlideshowView.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>

@implementation SlideshowView

- (void)awakeFromNib {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    // Preload shading bitmap to use in transitions (borrowed from the "Fun House" Core Image example).
    NSData *shadingBitmapData = [NSData dataWithContentsOfFile:[bundle pathForResource:@"restrictedshine" ofType:@"tiff"]];
    NSBitmapImageRep *shadingBitmap = [[[NSBitmapImageRep alloc] initWithData:shadingBitmapData] autorelease];
    inputShadingImage = [[CIImage alloc] initWithBitmapImageRep:shadingBitmap];

    // Preload mask bitmap to use in transitions.
    NSData *maskBitmapData = [NSData dataWithContentsOfFile:[bundle pathForResource:@"transitionmask" ofType:@"jpg"]];
    NSBitmapImageRep *maskBitmap = [[[NSBitmapImageRep alloc] initWithData:maskBitmapData] autorelease];
    inputMaskImage = [[CIImage alloc] initWithBitmapImageRep:maskBitmap];
}

- (void)updateSubviewsTransition {
    NSRect rect = [self bounds];
    NSString *transitionType = nil;
    CIFilter *transitionFilter = nil;
    CIFilter *maskScalingFilter = nil;
    CGRect maskExtent;

    // Map our transitionStyle to one of Core Animation's four built-in CATransition types, or an appropriately instantiated and configured Core Image CIFilter.  (The code used to construct the CIFilters here is very similar to that in the "Reducer" code sample from WWDC 2005.  See http://developer.apple.com/samplecode/Reducer/ )
    switch (transitionStyle) {
        case SlideshowViewFadeTransitionStyle:
            transitionType = kCATransitionFade;
            break;

        case SlideshowViewMoveInTransitionStyle:
            transitionType = kCATransitionMoveIn;
            break;

        case SlideshowViewPushTransitionStyle:
            transitionType = kCATransitionPush;
            break;

        case SlideshowViewRevealTransitionStyle:
            transitionType = kCATransitionReveal;
            break;

        case SlideshowViewCopyMachineTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CICopyMachineTransition"] retain];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
            break;

        case SlideshowViewDisintegrateWithMaskTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CIDisintegrateWithMaskTransition"] retain];
            [transitionFilter setDefaults];

            // Scale our mask image to match the transition area size, and set the scaled result as the "inputMaskImage" to the transitionFilter.
            maskScalingFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
            [maskScalingFilter setDefaults];
            maskExtent = [inputMaskImage extent];
            float xScale = rect.size.width / maskExtent.size.width;
            float yScale = rect.size.height / maskExtent.size.height;
            [maskScalingFilter setValue:[NSNumber numberWithFloat:yScale] forKey:@"inputScale"];
            [maskScalingFilter setValue:[NSNumber numberWithFloat:xScale / yScale] forKey:@"inputAspectRatio"];
            [maskScalingFilter setValue:inputMaskImage forKey:@"inputImage"];

            [transitionFilter setValue:[maskScalingFilter valueForKey:@"outputImage"] forKey:@"inputMaskImage"];
            break;

        case SlideshowViewDissolveTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CIDissolveTransition"] retain];
            [transitionFilter setDefaults];
            break;

        case SlideshowViewFlashTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CIFlashTransition"] retain];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
            break;

        case SlideshowViewModTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CIModTransition"] retain];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            break;

        case SlideshowViewPageCurlTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CIPageCurlTransition"] retain];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[NSNumber numberWithFloat:-M_PI_4] forKey:@"inputAngle"];
            [transitionFilter setValue:inputShadingImage forKey:@"inputShadingImage"];
            [transitionFilter setValue:inputShadingImage forKey:@"inputBacksideImage"];
            [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
            break;

        case SlideshowViewSwipeTransitionStyle:
            transitionFilter = [[CIFilter filterWithName:@"CISwipeTransition"] retain];
            [transitionFilter setDefaults];
            break;

        case SlideshowViewRippleTransitionStyle:
        default:
            transitionFilter = [[CIFilter filterWithName:@"CIRippleTransition"] retain];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
            [transitionFilter setValue:inputShadingImage forKey:@"inputShadingImage"];
            break;
    }

    // Construct a new CATransition that describes the transition effect we want.
    CATransition *transition = [CATransition animation];
    if (transitionFilter) {
        // We want to build a CIFilter-based CATransition.  When an CATransition's "filter" property is set, the CATransition's "type" and "subtype" properties are ignored, so we don't need to bother setting them.
        [transition setFilter:transitionFilter];
    } else {
        // We want to specify one of Core Animation's built-in transitions.
        [transition setType:transitionType];
        [transition setSubtype:kCATransitionFromLeft];
    }

    // Specify an explicit duration for the transition.
    [transition setDuration:1.0];

    // Associate the CATransition we've just built with the "subviews" key for this SlideshowView instance, so that when we swap ImageView instances in our -transitionToImage: method below (via -replaceSubview:with:).
    [self setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
}

- initWithFrame:(NSRect)newFrame {
    self = [super initWithFrame:newFrame];
    if (self) {
        [self updateSubviewsTransition];
    }
    return self;
}

- (void)dealloc {
    [currentImageView release];
    [super dealloc];
}

- (BOOL)isOpaque {
    // We're opaque, since we fill with solid black in our -drawRect: method, below.
    return YES;
}

- (void)drawRect:(NSRect)rect {
    // Draw a solid black background.
    [[NSColor blackColor] set];
    NSRectFill(rect);
}

- (void)transitionToImage:(NSImage *)newImage {
    // Auto-advance to the next transition style if desired.
    if ([self autoCyclesTransitionStyle]) {
        [self setTransitionStyle:(([self transitionStyle] + 1) % NumberOfSlideshowViewTransitionStyles)];
    }

    // Create a new NSImageView and swap it into the view in place of our previous NSImageView.  This will trigger the transition animation we've wired up in -updateSubviewsTransition, which fires on changes in the "subviews" property.
    NSImageView *newImageView = nil;
    if (newImage) {
        newImageView = [[NSImageView alloc] initWithFrame:[self bounds]];
        [newImageView setImage:newImage];
        [newImageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }
    if (currentImageView && newImageView) {
        [[self animator] replaceSubview:currentImageView with:newImageView];
    } else {
        if (currentImageView) [[currentImageView animator] removeFromSuperview];
        if (newImageView) [[self animator] addSubview:newImageView];
    }
	[currentImageView release];
    currentImageView = newImageView;
}

- (SlideshowViewTransitionStyle)transitionStyle {
    return transitionStyle;
}

- (void)setTransitionStyle:(SlideshowViewTransitionStyle)newTransitionStyle {
    if (transitionStyle != newTransitionStyle) {
        transitionStyle = newTransitionStyle;
        [self updateSubviewsTransition];
    }
}

- (BOOL)autoCyclesTransitionStyle {
    return autoCyclesTransitionStyle;
}

- (void)setAutoCyclesTransitionStyle:(BOOL)flag {
    autoCyclesTransitionStyle = flag;
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];

    // Some Core Image transition filters have geometric parameters that we derive from the view's dimensions.  So when the view is resized, we may need to update our "subviews" CATransition to match its new dimensions.
    switch (transitionStyle) {
        case SlideshowViewCopyMachineTransitionStyle:
        case SlideshowViewDisintegrateWithMaskTransitionStyle:
        case SlideshowViewFlashTransitionStyle:
        case SlideshowViewModTransitionStyle:
        case SlideshowViewPageCurlTransitionStyle:
        case SlideshowViewRippleTransitionStyle:
            [self updateSubviewsTransition];
            break;
    }
}

@end
