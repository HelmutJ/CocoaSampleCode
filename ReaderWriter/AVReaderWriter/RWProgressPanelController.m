/*
     File: RWProgressPanelController.m
 Abstract: n/a
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

#import "RWProgressPanelController.h"

#import <QuartzCore/CATransaction.h>

@interface RWProgressPanelController ()
@property (nonatomic, retain) CALayer *frameLayer;
@end

@implementation RWProgressPanelController

- (void)dealloc
{
	[frameLayer release];
	[frameView release];
	[progressIndicator release];
	[interestingProgressValues release];

	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	// Create a layer and set it on the view.  We will display video frames by adding sublayers as we go
	CALayer *localFrameLayer = [CALayer layer];
	[self setFrameLayer:localFrameLayer];
	NSView *localFrameView = [self frameView];
	[localFrameView setLayer:localFrameLayer];
	[localFrameView setWantsLayer:YES];
}

@synthesize progressIndicator=progressIndicator;
@synthesize frameView=frameView;
@synthesize frameLayer=frameLayer;
@synthesize delegate=delegate;

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer forProgress:(double)progress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self progressIndicator] setDoubleValue:progress];
	});
	
	if (pixelBuffer == NULL)
		return;
	
	CALayer *localFrameLayer = [self frameLayer];
	
	// Calculate size of image
	CGSize frameLayerSize = [localFrameLayer frame].size;
	double imageLayerWidth = (double)CVPixelBufferGetWidth(pixelBuffer) * frameLayerSize.height / (double)CVPixelBufferGetHeight(pixelBuffer);
	double imageLayerHeight = frameLayerSize.height;

	// Calculate position of image in the progress bar
	double expectedImageCount = ceil(frameLayerSize.width / imageLayerWidth) + 2.0;
	double progressValueForFinalImage = (expectedImageCount - 1) / expectedImageCount;
	double imageLayerXPos = progress * (frameLayerSize.width - imageLayerWidth) / progressValueForFinalImage;
	double imageLayerYPos = 0.0;
	
	// If we haven't already done so, decide the set of progress values for which we will display an image
	if (!interestingProgressValues)
	{
		interestingProgressValues = [[NSMutableArray alloc] init];

		double progressDisplayInterval = 1.0 / expectedImageCount;
		for (NSInteger i = 0; i < (NSInteger)expectedImageCount; ++i)
			[interestingProgressValues addObject:[NSNumber numberWithDouble:((double)i * progressDisplayInterval)]];
	}
	
	// Determine whether we will display this frame
	BOOL displayThisFrame = NO;
	if ([interestingProgressValues count] > 0)
	{
		NSNumber *nextInterestingProgressValue = [interestingProgressValues objectAtIndex:0];
		// If we have progressed beyond the next progress value, make a note that we should display this one
		if (progress >= [nextInterestingProgressValue doubleValue])
		{
			displayThisFrame = YES;
			[interestingProgressValues removeObjectAtIndex:0];
		}
	}
	
	// If so, add a sublayer to the frame layer with the pixel buffer as its contents
	if (displayThisFrame)
	{
		CALayer *imageLayer = [[CALayer alloc] init];

		// Make contents for this layer
		NSImage *image = nil;
		id contents = (id)CVPixelBufferGetIOSurface(pixelBuffer);  // try IOSurface first
		if (!contents)
		{
			// Fall back to creating an NSImage from the image buffer, via CIImage
			CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:pixelBuffer];
			NSCIImageRep *imageRep = [[NSCIImageRep alloc] initWithCIImage:ciImage];
			[ciImage release];
			image = [[NSImage alloc] initWithSize:[imageRep size]];
			[image addRepresentation:imageRep];
			[imageRep release];
				
			contents = image;
		}
		
		// Set contents, frame, and initial opacity
		[CATransaction begin];  // need an explicit transaction since we may not be executing on the main thread
		{
			[imageLayer setContents:contents];
			[imageLayer setFrame:CGRectMake(imageLayerXPos, imageLayerYPos, imageLayerWidth, imageLayerHeight)];
			[imageLayer setOpacity:0.0];
			[localFrameLayer addSublayer:imageLayer];
		}
		[CATransaction commit];

		// Animate opacity from 0.0 -> 1.0
		[CATransaction begin];
		{
			[CATransaction setAnimationDuration:1.5];
			[imageLayer setOpacity:1.0];
		}
		[CATransaction commit];
		
		[image release];
		[imageLayer release];
	}
}

- (IBAction)cancel:(id)sender
{
	id <RWProgressPanelControllerDelegate> localDelegate = [self delegate];
	if (localDelegate && [localDelegate respondsToSelector:@selector(progressPanelControllerDidCancel:)])
		[localDelegate progressPanelControllerDidCancel:self];
}

@end
