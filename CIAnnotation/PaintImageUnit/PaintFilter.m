
/*
     File: PaintFilter.m
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

#import "PaintFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation PaintFilter

static CIKernel *_paintKernel = nil;

- (id)init
{
    if(_paintKernel == nil)
    {
		NSStringEncoding	encoding = NSUTF8StringEncoding;
		NSError				*error = nil;
        NSBundle			*bundle = [NSBundle bundleForClass:NSClassFromString(@"PaintFilter")];
        NSString			*code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"paint" ofType:@"cikernel"] encoding:encoding error:&error];
        NSArray				*kernels = [CIKernel kernelsWithString:code];
        _paintKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}


- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:200.0 Y:200.0],       kCIAttributeDefault,
            kCIAttributeTypePosition,           kCIAttributeType,
            nil],                               @"inputPoint1",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:300.0 Y:250.0],       kCIAttributeDefault,
            kCIAttributeTypePosition,           kCIAttributeType,
            nil],                               @"inputPoint2",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  1.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:500.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble: 30.00], kCIAttributeDefault,
            [NSNumber numberWithDouble: 30.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputWidth",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0], kCIAttributeDefault,
            nil],                               @"inputColor",

        nil];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    float radius, p0x, p0y, p1x, p1y, dx, dy, len;
    CIVector *v01;
    CGRect R;
    
    radius = [inputWidth floatValue] * 0.5;
    p0x = [inputPoint1 X];
    p0y = [inputPoint1 Y];
    p1x = [inputPoint2 X];
    p1y = [inputPoint2 Y];
    if (p0x < p1x)
    {
        R.origin.x = p0x - radius;
        R.size.width = p1x - p0x + 2.0 * radius;
    }
    else
    {
        R.origin.x = p1x - radius;
        R.size.width = p0x - p1x + 2.0 * radius;
    }
    if (p0y < p1y)
    {
        R.origin.y = p0y - radius;
        R.size.height = p1y - p0y + 2.0 * radius;
    }
    else
    {
        R.origin.y = p1y - radius;
        R.size.height = p0y - p1y + 2.0 * radius;
    }
    dx = [inputPoint1 X] - [inputPoint2 X];
    dy = [inputPoint1 Y] - [inputPoint2 Y];
    len = sqrt(dx*dx + dy*dy);
    if (len != 0.0)
        len = 1.0 / len;
    dx *= len;
    dy *= len;
    v01 = [CIVector vectorWithX:dx Y:dy];
    return [self apply:_paintKernel, inputPoint1, inputPoint2, [NSNumber numberWithFloat:radius], v01, inputColor,
	    kCIApplyOptionDefinition, [CIFilterShape shapeWithRect:R], nil];
}

@end
