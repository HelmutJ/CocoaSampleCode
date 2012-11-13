
/*
     File: LensFilter.m
 Abstract: Obj-C part of the filter.
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

#import "LensFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation LensFilter

static CIKernel *_lensKernel = nil;
static CIKernel *_ringKernel = nil;
static CIImage *_ringMaterialImage = nil;
static CIImage *_lensShineImage = nil;

- (id)init
{
    NSBundle    *bundle;
    NSString    *code;
    NSArray     *kernels;
    NSString    *path;
    NSURL       *url;

    if(_lensKernel == nil)
    {
		NSStringEncoding	encoding = NSUTF8StringEncoding;
		NSError				*error = nil;

        bundle = [NSBundle bundleForClass:NSClassFromString(@"LensFilter")];
        code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"lens" ofType:@"cikernel"] encoding:encoding error:&error];
        kernels = [CIKernel kernelsWithString:code];
        _lensKernel = [[kernels objectAtIndex:0] retain];
        _ringKernel = [[kernels objectAtIndex:1] retain];
        path = [bundle pathForResource:@"emap1" ofType:@"tiff"];
        url = [NSURL fileURLWithPath:path];
        _ringMaterialImage = [[CIImage imageWithContentsOfURL:url] retain];
        path = [bundle pathForResource:@"lensShine" ofType:@"tiff"];
        url = [NSURL fileURLWithPath:path];
        _lensShineImage = [[CIImage imageWithContentsOfURL:url] retain];
    }
    return [super init];
}


- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:200.0 Y:200.0],       kCIAttributeDefault,
            kCIAttributeTypePosition,           kCIAttributeType,
            nil],                               @"inputCenter",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  1.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:500.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:250.00], kCIAttributeDefault,
            [NSNumber numberWithDouble:250.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputWidth",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  1.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:500.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble: 22.00], kCIAttributeDefault,
            [NSNumber numberWithDouble:  1.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputRingWidth",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  1.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble: 30.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  9.20], kCIAttributeDefault,
            [NSNumber numberWithDouble:  7.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputRingFilletRadius",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  1.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble: 10.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  3.00], kCIAttributeDefault,
            [NSNumber numberWithDouble:  1.00], kCIAttributeIdentity,
            kCIAttributeTypeScalar,             kCIAttributeType,
            nil],                               @"inputMagnification",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  0.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.86], kCIAttributeDefault,
            [NSNumber numberWithDouble:  1.00], kCIAttributeIdentity,
            kCIAttributeTypeScalar,             kCIAttributeType,
            nil],                               @"inputRoundness",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  0.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.50], kCIAttributeDefault,
            [NSNumber numberWithDouble:  1.00], kCIAttributeIdentity,
            kCIAttributeTypeScalar,             kCIAttributeType,
            nil],                               @"inputShineOpacity",

        nil];
}

- (CGRect)lensROI:(int)sampler forRect:(CGRect)R userInfo:(NSArray *)array
{
    CIVector *oCenter;
    NSNumber *oWidth, *oMagnification;
    CISampler *shine;
    
    oCenter = [array objectAtIndex:0];
    oWidth = [array objectAtIndex:1];
    oMagnification = [array objectAtIndex:2];
    shine = [array objectAtIndex:3];
    if (sampler == 2)
        return [shine extent];
    // determine the area of the original image used with the lens where it is
    // currently we only need R, because the lens is a magnifier
    if (sampler == 1)
    {
        float cx, cy, width, mag;
        
        cx = [oCenter X];
        cy = [oCenter Y];
        width = [oWidth floatValue];
        mag = [oMagnification floatValue];
        width /= mag;
        R = CGRectMake(cx - width, cy - width, width*2.0, width*2.0);
    }
    return R;
}

- (CGRect)ringROI:(int)sampler forRect:(CGRect)R userInfo:(CISampler *)material
{
    if (sampler == 0)
        return [material extent];
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    float radius, cx, cy, ringwidth, mag;
    CGRect R, extent;
    CISampler *src, *shine, *material;
    CIImage *lensedImage, *ringImage;
    CIFilter *f;
    NSArray *array;
    CISampler *magsrc;
    CGAffineTransform CT;
    CIVector *shineSize, *materialSize;
    
    // get a non-magnified sampler for the image
    src = [CISampler samplerWithImage:inputImage];
    shine = [CISampler samplerWithImage:_lensShineImage];
    // establish a magnified sampler for the image
    cx = [inputCenter X];
    cy = [inputCenter Y];
    mag = [inputMagnification floatValue];
    CT = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeTranslation(cx, cy), mag, mag), -cx, -cy);
    magsrc = [CISampler samplerWithImage:[inputImage imageByApplyingTransform:CT]];
    radius = [inputWidth floatValue] * 0.5;
    // calculate rectangle for lens effect
    R.origin.x = cx - radius;
    R.size.width = 2.0 * radius;
    R.origin.y = cy - radius;
    R.size.height = 2.0 * radius;
    // get size of shine map
    extent = [shine extent];
    shineSize = [CIVector vectorWithX:extent.size.width Y:extent.size.height];
    // set up ROI calculation for lens
    array = [NSArray arrayWithObjects:inputCenter, inputWidth, inputMagnification, shine, nil];
    [_lensKernel setROISelector:@selector(lensROI:forRect:userInfo:)];
    lensedImage = [self apply:_lensKernel, src, magsrc, shine, inputCenter, [NSNumber numberWithFloat:radius + 2.0],
      inputMagnification, inputRoundness, inputShineOpacity, shineSize,
      kCIApplyOptionDefinition, [[src definition] unionWithRect:R], kCIApplyOptionUserInfo, array, nil];
    // now put the ring over it
    material = [CISampler samplerWithImage:_ringMaterialImage];
    ringwidth = [inputRingWidth floatValue];
    // compute rectangle for the ring
    R.origin.x = cx - radius - ringwidth;
    R.size.width = 2.0 * (radius + ringwidth);
    R.origin.y = cy - radius - ringwidth;
    R.size.height = 2.0 * (radius + ringwidth);
    extent = [material extent];
    materialSize = [CIVector vectorWithX:extent.size.width Y:extent.size.height];
    // set up ROI calculation for the ring
    [_ringKernel setROISelector:@selector(ringROI:forRect:userInfo:)];
    ringImage = [self apply:_ringKernel, material, inputCenter, [NSNumber numberWithFloat:radius], [NSNumber numberWithFloat:radius+ringwidth], inputRingFilletRadius,
      materialSize,
      kCIApplyOptionDefinition, [CIFilterShape shapeWithRect:R], kCIApplyOptionUserInfo, material, nil];
    // place ring over lensed image
    f = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:@"inputImage", ringImage, @"inputBackgroundImage", lensedImage, nil];
    return [f valueForKey:@"outputImage"];
}

@end
