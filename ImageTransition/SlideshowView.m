/*
     File: SlideshowView.m 
 Abstract: 
 A view class that displays a single NSImage at a time, and can transition to a new image using any of the Core Animation / Core Image supported transition effects.
  
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

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>

#import "SlideshowView.h"

@implementation SlideshowView

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    // preload shading bitmap to use in transitions:
	
	// this one is for "SlideshowViewPageCurlTransitionStyle", and "SlideshowViewRippleTransitionStyle"
	NSURL *pathURL = [NSURL fileURLWithPath:[bundle pathForResource:@"restrictedshine" ofType:@"tiff"]];
	inputShadingImage = [[CIImage imageWithContentsOfURL:pathURL] retain];
	
	// this one is for "SlideshowViewDisintegrateWithMaskTransitionStyle"
	pathURL = [NSURL fileURLWithPath:[bundle pathForResource:@"transitionmask" ofType:@"jpg"]];
	inputMaskImage = [[CIImage imageWithContentsOfURL:pathURL] retain];
}

// -------------------------------------------------------------------------------
//	updateSubviewsWithTransition:transition
// -------------------------------------------------------------------------------
- (void)updateSubviewsWithTransition:(NSString *)transition
{
    NSRect		rect = [self bounds];
    CIFilter	*transitionFilter = nil;

    // Use Core Animation's four built-in CATransition types,
	// or an appropriately instantiated and configured Core Image CIFilter.
    //
    transitionFilter = [CIFilter filterWithName:transition];
    [transitionFilter setDefaults];
    
    if ([transition isEqualToString:@"CICopyMachineTransition"])
    {
        [transitionFilter setValue:
            [CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height]
                        forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIDisintegrateWithMaskTransition"])
    {
        // scale our mask image to match the transition area size, and set the scaled result as the
        // "inputMaskImage" to the transitionFilter.
        //
        CIFilter *maskScalingFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [maskScalingFilter setDefaults];
        CGRect maskExtent = [inputMaskImage extent];
        float xScale = rect.size.width / maskExtent.size.width;
        float yScale = rect.size.height / maskExtent.size.height;
        [maskScalingFilter setValue:[NSNumber numberWithFloat:yScale] forKey:@"inputScale"];
        [maskScalingFilter setValue:[NSNumber numberWithFloat:xScale / yScale] forKey:@"inputAspectRatio"];
        [maskScalingFilter setValue:inputMaskImage forKey:@"inputImage"];
        
        [transitionFilter setValue:[maskScalingFilter valueForKey:@"outputImage"] forKey:@"inputMaskImage"];
    }
    else if ([transition isEqualToString:@"CIFlashTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIModTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
    }
    else if ([transition isEqualToString:@"CIPageCurlTransition"])
    {
        [transitionFilter setValue:[NSNumber numberWithFloat:-M_PI_4] forKey:@"inputAngle"];
        [transitionFilter setValue:inputShadingImage forKey:@"inputShadingImage"];
        [transitionFilter setValue:inputShadingImage forKey:@"inputBacksideImage"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIRippleTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
        [transitionFilter setValue:inputShadingImage forKey:@"inputShadingImage"];
    }
    
    // construct a new CATransition that describes the transition effect we want.
	CATransition *newTransition = [CATransition animation];
    if (transitionFilter)
	{
        // we want to build a CIFilter-based CATransition.
		// When an CATransition's "filter" property is set, the CATransition's "type" and "subtype" properties are ignored,
		// so we don't need to bother setting them.
        [newTransition setFilter:transitionFilter];
    }
	else
	{
        // we want to specify one of Core Animation's built-in transitions.
        [newTransition setType:transition];
        [newTransition setSubtype:kCATransitionFromLeft];
    }

    // specify an explicit duration for the transition.
    [newTransition setDuration:1.0];

    // associate the CATransition we've just built with the "subviews" key for this SlideshowView instance,
	// so that when we swap ImageView instances in our -transitionToImage: method below (via -replaceSubview:with:).
	//
	[self setAnimations:[NSDictionary dictionaryWithObject:newTransition forKey:@"subviews"]];
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [inputShadingImage release];
	[inputMaskImage release];
	[currentImageView release];
	
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	isOpaque:
// -------------------------------------------------------------------------------
- (BOOL)isOpaque
{
    // we're opaque, since we fill with solid black in our -drawRect: method, below.
    return YES;
}

// -------------------------------------------------------------------------------
//	drawRect:
// -------------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
    // draw a solid black background by default
    [[NSColor blackColor] set];
    NSRectFill(rect);
}

// -------------------------------------------------------------------------------
//	transitionToImage:newimage
// -------------------------------------------------------------------------------
- (void)transitionToImage:(NSImage *)newImage
{
    // create a new NSImageView and swap it into the view in place of our previous NSImageView.
	// this will trigger the transition animation we've wired up in -updateSubviewsTransition,
	// which fires on changes in the "subviews" property.
    NSImageView *newImageView = nil;
    if (newImage)
	{
        newImageView = [[NSImageView alloc] initWithFrame:[self bounds]];
        [newImageView setImage:newImage];
        [newImageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }
    if (currentImageView && newImageView)
	{
        [[self animator] replaceSubview:currentImageView with:newImageView];
    }
	else
	{
        if (currentImageView)
			[[currentImageView animator] removeFromSuperview];
        if (newImageView)
			[[self animator] addSubview:newImageView];
    }
    currentImageView = newImageView;
}

@end
