/*

File: ImageFilter.m

Abstract: ImageFilter.m class implementation

Version: <1.0>

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

Copyright © 2005-2012 Apple Inc. All Rights Reserved.

*/

#import "ImageFilter.h"
#import "ImageDoc.h"

@implementation ImageFilter

- (void) dealloc
{
    CGImageRelease(mImage);
}


- (id) initWithImage:(CGImageRef)image
{
    if ((self = [super init]))
    {
        mImage = CGImageRetain(image);
        mCIImage = [CIImage imageWithCGImage:mImage];
    }
    return self;
}


//
// Build a 3D lookup texture for use with soft-proofing
// The resulting table is suitable for use in OpenGL to accelerate   
// color management in hardware.
//

- (void) setColorCubeFilterDataForGridPoints:(size_t)gridPoints
{
    CFDataRef   data = NULL;
    
    Boolean     success = true;
    size_t      count = (gridPoints*gridPoints*gridPoints) * 4;
    size_t      size = count * sizeof(float);
    float*      floatData = (float*) malloc (size);
    
    if (floatData == NULL)
        success = false;
    
    if (success) 
    {
        Profile*    linRGB = [Profile profileWithLinearRGB];
        
        if (linRGB == nil)
            success = false;
        
        if (success) 
        {
            const void *keys[] = {kColorSyncProfile, kColorSyncRenderingIntent, kColorSyncTransformTag};
            
            const void *srcVals[] = {[linRGB ref],  kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformDeviceToPCS};
            const void *midVals[] = {[mProfile ref],    kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformPCSToPCS};
            const void *dstVals[] = {[linRGB ref],  kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformPCSToDevice};
            
            CFDictionaryRef srcDict = CFDictionaryCreate (
                                                          NULL,
                                                          (const void **)keys,
                                                          (const void **)srcVals,
                                                          3,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
            
            CFDictionaryRef midDict = CFDictionaryCreate (
                                                          NULL,
                                                          (const void **)keys,
                                                          (const void **)midVals,
                                                          3,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
            
            CFDictionaryRef dstDict = CFDictionaryCreate (
                                                          NULL,
                                                          (const void **)keys,
                                                          (const void **)dstVals,
                                                          3,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
            
            const void* arrayVals[] = {srcDict, midDict, dstDict, NULL};
            
            CFArrayRef profileSequence = CFArrayCreate(NULL, (const void **)arrayVals, 3, &kCFTypeArrayCallBacks);
            
            ColorSyncTransformRef transform = ColorSyncTransformCreate (profileSequence, NULL);
            
            if (srcDict) CFRelease (srcDict);
            if (midDict) CFRelease (midDict);
            if (dstDict) CFRelease (dstDict);
            
            if (profileSequence) CFRelease (profileSequence);
            
            if (transform == NULL)
                success = false;
            
            if (success) 
            {
                CFDataRef colorSyncTexture = NULL;
                
                uint8_t gridPoints8Bit = (uint8_t) gridPoints;
                
                const void* optKeys[] = {kColorSyncConversionGridPoints, NULL};
                
                const void* optVals[] = {CFNumberCreate (NULL, kCFNumberSInt8Type, &gridPoints8Bit), NULL};
                
                CFDictionaryRef options = CFDictionaryCreate (
                                                              NULL,
                                                              (const void **)optKeys,
                                                              (const void **)optVals,
                                                              1,
                                                              &kCFTypeDictionaryKeyCallBacks,
                                                              &kCFTypeDictionaryValueCallBacks);
                
                CFRelease (optVals[0]);
                
                CFArrayRef array = ColorSyncTransformCopyProperty(transform,
                                                                  kColorSyncTransformSimplifiedConversionData,
                                                                  options);
                
                if (options) CFRelease (options);
                
                if (transform) CFRelease (transform);
                
                if (array)
                {
                    CFDictionaryRef dict = (CFDictionaryRef) CFArrayGetValueAtIndex (array, 0);
                    
                    if (dict)
                    {
                        colorSyncTexture = (CFDataRef) CFDictionaryGetValue (dict, kColorSyncConversion3DLut);
                    }
                }
                
                if (colorSyncTexture)
                {
                    uint16_t* clutPtr, *clutBase = (uint16_t*)CFDataGetBytePtr (colorSyncTexture);
                    size_t rr, gg, bb;
                    
                    float*    ptrFl;
                    ptrdiff_t clutOffset = 0, dataOffset = 0;
                    
                    for (bb = 0; bb < gridPoints; bb++)
                    {
                        for (gg = 0; gg < gridPoints; gg++)
                        {
                            for (rr = 0; rr < gridPoints; rr++)
                            {
                                dataOffset = (bb * gridPoints * gridPoints + gg *gridPoints + rr) * 4;
                                clutOffset = (rr * gridPoints * gridPoints + gg *gridPoints + bb) * 3;
                                
                                clutPtr = clutBase + clutOffset;
                                
                                ptrFl = floatData + dataOffset;
                                ptrFl[0] = ((float)clutPtr[0])/(float)65535.0;
                                if (ptrFl[0] > (float) 1.0) ptrFl[0] = 1.0f;
                                if (ptrFl[0] < (float) 0.0) ptrFl[0] = 0.0f;
                                ptrFl[1] = ((float)clutPtr[1])/(float)65535.0;
                                if (ptrFl[1] > (float) 1.0) ptrFl[1] = 1.0f;
                                if (ptrFl[1] < (float) 0.0) ptrFl[1] = 0.0f;
                                ptrFl[2] = ((float)clutPtr[2])/(float)65535.0;
                                if (ptrFl[2] > (float) 1.0) ptrFl[2] = 1.0f;
                                if (ptrFl[2] < (float) 0.0) ptrFl[2] = 0.0f;
                                ptrFl[3] = 1.0f;
                            }
                        }
                    }
                }
                
                if (array) 
                {
                    CFRelease (array);
                }
                
                data = CFDataCreate (NULL, (uint8_t*)floatData, size);
                
                [mCIColorCube setValue:(__bridge id)data forKey:@"inputCubeData"];
                
                CFRelease (data);

            }

        }

    }

    if (floatData) 
        free(floatData);
}


// specify profile for use with image effect transform
- (void) setProfile:(Profile*)profile
{
    mProfile = profile;

    if (mProfile == nil)
    {
        mCIColorCube = nil;
    }
    else
    {
        // Use the CIColorCube filter three-dimensional color table 
        // to transform the source image pixels
        if (mCIColorCube == nil)
            mCIColorCube = [CIFilter filterWithName: @"CIColorCube"];
        
        // Get the transformed data
        static const int kSoftProofGrid = 32;

        // Specify Cube Data for the CIColorCube filter
        [self setColorCubeFilterDataForGridPoints:kSoftProofGrid];
        
        [mCIColorCube setValue:[NSNumber numberWithInt:kSoftProofGrid]
            forKey:@"inputCubeDimension"];
    }
}

// Use CIExposureAdjust Color adjustment filter change color values.
// The CIExposureAdjust filter adjusts the exposure setting for an image by mimicking 
// a camera’s F-stop adjustment. 
//
- (void) setExposure:(NSNumber *)exposure
{
    if (mCIExposure == nil)
        mCIExposure = [CIFilter filterWithName: @"CIExposureAdjust"];

    [mCIExposure setValue:exposure
        forKey: @"inputEV"];
}

// Use the CIColorControls filter to adjust saturation 
//
- (void) setSaturation:(NSNumber *)saturation
{
    if (mCIColorControls == nil)
        mCIColorControls = [CIFilter filterWithName: @"CIColorControls"];

    // set new saturation value
    [mCIColorControls setValue:saturation
        forKey: @"inputSaturation"];

    // hold brightness unchanged. kCIAttributeIdentity = A value that results 
    // in no effect on the input image.
    [mCIColorControls setValue:[[[mCIColorControls attributes]
                                    objectForKey: @"inputBrightness"]
                                        objectForKey: @"CIAttributeIdentity"]
        forKey: @"inputBrightness"];

    // hold contrast unchanged. kCIAttributeIdentity = A value that results 
    // in no effect on the input image.
    [mCIColorControls setValue:[[[mCIColorControls attributes]
                                    objectForKey: @"inputContrast"]
                                        objectForKey: @"CIAttributeIdentity"]
        forKey: @"inputContrast"];
}


- (CIImage*) imageWithTransform:(CGAffineTransform)ctm
{
    // Returns a new image representing the original image with the transform
    // 'ctm' appended to it.
    CIImage* ciimg = [mCIImage imageByApplyingTransform:ctm];

    // exposure adjustment
    if (mCIExposure)
    {
        [mCIExposure setValue:ciimg forKey:@"inputImage"];
        ciimg = [mCIExposure valueForKey: @"outputImage"];
    }

    // saturation adjustment
    if (mCIColorControls)
    {
        [mCIColorControls setValue:ciimg forKey:@"inputImage"];
        ciimg = [mCIColorControls valueForKey: @"outputImage"];
    }

    // three-dimensional color table adjustment
    if (mCIColorCube)
    {
        [mCIColorCube setValue:ciimg forKey: @"inputImage"];
        ciimg = [mCIColorCube valueForKey: @"outputImage"];
    }

    return ciimg;
}



-(size_t)imageBytesPerRow:(icColorSpaceSignature)colorSpace
{
    size_t bytesPerRow = 0;
    size_t width = CGImageGetWidth(mImage);
    
    switch (colorSpace)
    {
        case icSigGrayData:
            bytesPerRow = width;
            break;
        case icSigRgbData:
            bytesPerRow = width*4;
            break;
        case icSigCmykData:
            bytesPerRow = width*4;
            break;
        default:
            break;
    }
    
    return (bytesPerRow);
}

-(CGImageAlphaInfo)imageAlphaInfo:(icColorSpaceSignature)colorSpace
{
    CGImageAlphaInfo alphaInfo = kCGImageAlphaNone;
    
    switch (colorSpace)
    {
        case icSigGrayData:
            alphaInfo = kCGImageAlphaNone; /* RGB. */
            break;
        case icSigRgbData:
            alphaInfo = kCGImageAlphaPremultipliedLast; /* premultiplied RGBA */
            break;
        case icSigCmykData:
            alphaInfo = kCGImageAlphaNone; /* RGB. */
            break;
        default:
            break;
    }

    return (alphaInfo);
}

-(void)fillContextWithWhite:(CGContextRef)context fillRect:(CGRect)fillRect
{
    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    const CGFloat whiteComps[2] = {1.0, 1.0};
    CGColorRef whiteColor = CGColorCreate(graySpace, whiteComps);
    CFRelease(graySpace);
    CGContextSetFillColorWithColor(context, whiteColor);
    CGContextFillRect(context, fillRect);
    CFRelease(whiteColor);
}

-(void)renderImageWithExposureAdjustment:(CIImage *)ciimg context:(CIContext *)cicontext rect:(CGRect)rect
{
    // exposure adjustment
    if (mCIExposure)
    {
        [mCIExposure setValue:ciimg forKey:@"inputImage"];
        ciimg = [mCIExposure valueForKey: @"outputImage"];
    }
    
    // three-dimensional color table adjustment
    if (mCIColorControls)
    {
        [mCIColorControls setValue:ciimg forKey:@"inputImage"];
        ciimg = [mCIColorControls valueForKey: @"outputImage"];
    }
    
    CGRect extent = [ciimg extent];
    
    [cicontext drawImage: ciimg inRect:rect fromRect:extent];
}

-(void)drawFilteredImage:(CGContextRef) drawContext imageRect:(CGRect)drawImageRect
{
    if (mImage==nil)
        return;
    
    // calculate bits per pixel and row bytes and alphaInfo
    size_t bitsPerComponent = 8;
    
    Profile* prof = mProfile;
    if (mProfile==nil)
        prof = [Profile profileWithSRGB];

    size_t bytesPerRow = [self imageBytesPerRow:[prof spaceType]];
    
    CGImageAlphaInfo alphaInfo = [self imageAlphaInfo:[prof spaceType]];
        
    CGContextRef context = CGBitmapContextCreate(nil, CGImageGetWidth(mImage), CGImageGetHeight(mImage),
                                                 bitsPerComponent, bytesPerRow,
                                                 [prof colorspace], alphaInfo);
    
    CIContext* cicontext = [CIContext contextWithCGContext: context options: nil];

    CGRect rect = CGRectMake (
                              0,
                              0,
                              CGImageGetWidth(mImage),
                              CGImageGetHeight(mImage)
                              );

    // If context doesn't support alpha then first fill it with white.
    // That is most likely to be desireable.
    if (alphaInfo == kCGImageAlphaNone)
    {
        [self fillContextWithWhite:context fillRect:rect];        
    }
    
    [self renderImageWithExposureAdjustment:mCIImage context:cicontext rect:rect];
    
    // create filtered image
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);

    
    // draw image to destination context
    CGContextDrawImage(drawContext, drawImageRect, image);

    CGImageRelease(image);
}


- (BOOL) writeImageToURL:(NSURL *)absURL ofType:(NSString *)typeName properties:(CFDictionaryRef)properties error:(NSError **)outError
{
    BOOL success = YES;
    CGImageDestinationRef dest = nil;
    
    if (mImage==nil)
        success = NO;
    
    if (success == YES) 
    {
        // Create an image destination writing to `url'
        dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)absURL, (__bridge CFStringRef)typeName, 1, nil);
        if (dest==nil)
            success = NO;
    }
    
    if (success == YES) 
    {
        // calculate bits per pixel and row bytes and alphaInfo
        size_t bitsPerComponent = 8;

        Profile* prof = mProfile;
        if (mProfile==nil)
        {
            prof = [Profile profileWithSRGB];
        }

        size_t bytesPerRow = [self imageBytesPerRow:[prof spaceType]];

        CGImageAlphaInfo alphaInfo = [self imageAlphaInfo:[prof spaceType]];

        CGContextRef context = CGBitmapContextCreate(nil, CGImageGetWidth(mImage), CGImageGetHeight(mImage),
                                                     bitsPerComponent, bytesPerRow,
                                                     [prof colorspace], alphaInfo);

        CIContext* cicontext = [CIContext contextWithCGContext: context options: nil];

        CGRect rect = CGRectMake (
                                  0,
                                  0,
                                  CGImageGetWidth(mImage),
                                  CGImageGetHeight(mImage)
                                  );

        // If context doesn't support alpha then first fill it with white.
        // That is most likely to be desireable.
        if (alphaInfo == kCGImageAlphaNone)
        {
            [self fillContextWithWhite:context fillRect:rect];        
        }

        [self renderImageWithExposureAdjustment:mCIImage context:cicontext rect:rect];

        CGImageRef image = nil;
        
        // create filtered image
        image = CGBitmapContextCreateImage(context);

        CGContextRelease(context);

        // Set the image in the image destination to be `image' with
        // optional properties specified in saved properties dict.
        CGImageDestinationAddImage(dest, image, properties);
        
        success = CGImageDestinationFinalize(dest);
        
        CFRelease(dest);
        
        CGImageRelease(image);
    }
    
    if (success==NO && outError)
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    
    return success; 
}

@end
