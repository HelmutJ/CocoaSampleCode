/*

File: FunHouseMirrorFilter.m

Abstract:   Obj-C part of the filter.

Version: 1.0

© Copyright 2005-2009 Apple, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*/ 

#import "FunHouseMirrorFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation FunHouseMirrorFilter

static CIKernel *_funHouseMirrorKernel = nil;

- (id)init
{
    if(_funHouseMirrorKernel == nil)
    {
		NSError		*err;
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"FunHouseMirrorFilter")];
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"funHouseMirror" ofType:@"cikernel"] encoding:NSUTF8StringEncoding error:&err];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_funHouseMirrorKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}


- (CGRect)regionOf: (int)sampler  destRect: (CGRect)rect  userInfo: (NSNumber *)radius
{
    return CGRectInset(rect, -[radius floatValue], 0);
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
            [NSNumber numberWithDouble:1000.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:400.00], kCIAttributeDefault,
            [NSNumber numberWithDouble:400.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputWidth",

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.00], kCIAttributeMin,
            [NSNumber numberWithDouble:  0.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  2.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.50], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.00], kCIAttributeIdentity,
            kCIAttributeTypeDistance,           kCIAttributeType,
            nil],                               @"inputAmount",

        nil];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    float radius;
    CISampler *src;
    
    src = [CISampler samplerWithImage:inputImage];
    radius = [inputWidth floatValue] * 0.5;
    return [self apply:_funHouseMirrorKernel, src,
        [NSNumber numberWithFloat:[inputCenter X]],
        [NSNumber numberWithFloat:1.0 / radius],
        [NSNumber numberWithFloat:radius],
        [NSNumber numberWithFloat: 1.0 / pow(10.0, [inputAmount floatValue])],
	    kCIApplyOptionDefinition, [[src definition] insetByX:-radius Y:-radius],
            kCIApplyOptionUserInfo, [NSNumber numberWithFloat:radius], nil];
}

@end
