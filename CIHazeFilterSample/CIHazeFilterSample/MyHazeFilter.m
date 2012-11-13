
/*
     File: MyHazeFilter.m
 Abstract: Custom CIFilter.
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

#import "MyHazeFilter.h"


@implementation MyHazeFilter
{
    CIImage   *inputImage;
    CIColor   *inputColor;
    NSNumber  *inputDistance;
    NSNumber  *inputSlope;
}

static CIKernel *hazeRemovalKernel = nil;

+ (void)registerFilter
{
    NSArray *filterCategories = @[kCICategoryColorAdjustment, kCICategoryVideo, kCICategoryStillImage,
    kCICategoryInterlaced, kCICategoryNonSquarePixels];
    
    NSDictionary *attributes = @{
        kCIAttributeFilterDisplayName : @"Haze Remover",
        kCIAttributeFilterCategories : filterCategories };
    
    [CIFilter registerFilterName:@"MyHazeRemover" constructor:(id <CIFilterConstructor>)self classAttributes:attributes];
}


+ (CIFilter *)filterWithName:(NSString *)name
{
    return [[self alloc] init];
}


- (id)init
{
    self = [super init];
    
    if (self) {
        
        if (hazeRemovalKernel == nil)
        {
            // Load the haze removal kernel.
            NSBundle *bundle = [NSBundle bundleForClass: [self class]];
            NSURL *kernelURL = [bundle URLForResource:@"MyHazeRemoval" withExtension:@"cikernel"];
            
            NSError *error;
            NSString *kernelCode = [NSString stringWithContentsOfURL:kernelURL encoding:NSUTF8StringEncoding error:&error];
            if (kernelCode == nil) {
                NSLog(@"Error loading kernel code string in %@\n%@", NSStringFromSelector(_cmd), [error localizedDescription]);
                abort();
            }
            
            NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
            hazeRemovalKernel = [kernels objectAtIndex:0];
        }
    }
    
    return self;
}


- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage: inputImage];

    return [self apply: hazeRemovalKernel, src, inputColor, inputDistance,
        inputSlope, kCIApplyOptionDefinition, [src definition], nil];
}


- (NSDictionary *)customAttributes
{
    NSDictionary *distanceDictionary = @{
        kCIAttributeMin : @0.0,
        kCIAttributeMax : @1.0,
        kCIAttributeSliderMin : @0.0,
        kCIAttributeSliderMax : @0.7,
        kCIAttributeDefault : @0.2,
        kCIAttributeIdentity : @0.0,
        kCIAttributeType : kCIAttributeTypeScalar };
    
    
    NSDictionary *slopeDictionary = @{
        kCIAttributeSliderMin : @-0.01,
        kCIAttributeSliderMax : @0.01,
        kCIAttributeDefault : @0.00,
        kCIAttributeIdentity : @0.00,
        kCIAttributeType : kCIAttributeTypeScalar
    };

    NSDictionary *colorDictionary = @{
        kCIAttributeDefault : [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
    };
    
    return @{
        @"inputDistance" : distanceDictionary,
        @"inputSlope" : slopeDictionary,
        @"inputColor": colorDictionary,
        // This is needed because the filter is registered under a different name than the class.
        kCIAttributeFilterName : @"MyHazeRemover"
    };
}

@end
