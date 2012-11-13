
/*
     File: TransitionSelectorView.m
 Abstract: Simple CG based CoreImage view.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "TransitionSelectorView.h"


@interface TransitionSelectorView ()

@property (nonatomic, strong) CIImage *sourceImage;
@property (nonatomic, strong) CIImage *targetImage;
@property (nonatomic, strong, readwrite) CIImage *blankImage;
@property (nonatomic, strong, readwrite) CIImage *shadingImage;
@property (nonatomic, strong, readwrite) CIImage *maskImage;

@end



@implementation TransitionSelectorView
{
    NSTimeInterval  base;
    float           thumbnailGap;
}


- (void)awakeFromNib
{
    thumbnailWidth  = 340.0;
    thumbnailHeight = 240.0;
    thumbnailGap    = 20.0;

    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Rose" withExtension:@"jpg"];
    [self setSourceImage: [CIImage imageWithContentsOfURL:URL]];

    URL = [[NSBundle mainBundle] URLForResource:@"Frog" withExtension:@"jpg"];
    [self setTargetImage: [CIImage imageWithContentsOfURL:URL]];

    base = [NSDate timeIntervalSinceReferenceDate];

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0  target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}


- (CIImage *)shadingImage
{
    if (!_shadingImage) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Shading" withExtension:@"tiff"];
        _shadingImage = [[CIImage alloc] initWithContentsOfURL:URL];
    }
    return _shadingImage;
}


- (CIImage *)blankImage
{
    if (!_blankImage) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Blank" withExtension:@"jpg"];
        _blankImage = [[CIImage alloc] initWithContentsOfURL:URL];
    }
    return _blankImage;
}


- (CIImage *)maskImage
{
    if (!_maskImage) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Mask" withExtension:@"jpg"];
        _maskImage = [[CIImage alloc] initWithContentsOfURL:URL];
    }
    return _maskImage;
}


- (void)timerFired: (id)sender
{
    [self setNeedsDisplay: YES];
}


- (CIImage *)imageForTransition:(NSInteger)transitionNumber  atTime: (float)t
{
    CIFilter *transition = [self.transitions objectAtIndex:transitionNumber];

    if (fmodf(t, 2.0) < 1.0f)
    {
        [transition setValue:self.sourceImage forKey:@"inputImage"];
        [transition setValue:self.targetImage forKey:@"inputTargetImage"];
    }
    else
    {
        [transition setValue:self.targetImage forKey:@"inputImage"];
        [transition setValue:self.sourceImage forKey:@"inputTargetImage"];
    }

    [transition setValue:@(0.5*(1-cos(fmodf(t, 1.0f) * M_PI))) forKey: @"inputTime"];

    CIFilter *crop = [CIFilter filterWithName: @"CICrop"
        keysAndValues: @"inputImage", [transition valueForKey: @"outputImage"],
            @"inputRectangle", [CIVector vectorWithX: 0  Y: 0
            Z: thumbnailWidth  W: thumbnailHeight], nil];

    return [crop valueForKey: @"outputImage"];
}


- (void)drawRect: (NSRect)rectangle
{
    NSInteger transitionsCount = [self.transitions count];

    if (transitionsCount == 0) {
        [self setupTransitions];
        transitionsCount = [self.transitions count];
    }
    
	CIContext* context = [[NSGraphicsContext currentContext] CIContext];
    CGRect thumbFrame = CGRectMake(0,0, thumbnailWidth,thumbnailHeight);
    float t = 0.4*([NSDate timeIntervalSinceReferenceDate] - base);
    int w = (int)ceil(sqrt((double)(transitionsCount)));

    for (NSInteger i = 0; i < transitionsCount; i++) {
        
        CGPoint origin;
        origin.x = (i % w) * (thumbnailWidth  + thumbnailGap);
        origin.y = (i / w) * (thumbnailHeight + thumbnailGap);
	
		if (context != nil) {
            CIImage *image = [self imageForTransition:i atTime:(t + 0.1*i)];
			[context drawImage:image atPoint:origin fromRect:thumbFrame];
        }
    }
}


@end
