/*
    File: ImageUtils.h
Abstract: Contains the core functionality of the sample.
 Version: 1.2

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

//	IICreateImage loads and creates the ImageInfo struct that is core to the sample
//	IISaveImage saves the transformed image to a PNG.
//	IIApplyTransformation shows how to rotate about center, scale, and translate the image
//	IIDrawImage draws the image into the given context
//	IIDrawImageTransformed calls IIApplyTransformation and IIDrawImage to do both at once while preserving the original context's CTM
//	IIRelease releases the ImageInfo struct allocated by IICreateImage

#include <ApplicationServices/ApplicationServices.h>

#ifdef __cplusplus
extern "C" {
#endif

struct ImageInfo
{
	CGFloat rotation;			// The rotation about the center of the image (degrees)
	CGFloat scaleX;				// The scaling of the image along it's X-axis
	CGFloat scaleY;				// The scaling of the image along it's Y-axis
	CGFloat translateX;			// Move the image along the X-axis
	CGFloat translateY;			// Move the image along the Y-axis
	CGImageRef image;			// The image itself
	CFDictionaryRef properties;	// Image properties
};
typedef struct ImageInfo ImageInfo;

// Create a new image from a file at the given url
// Returns NULL if unsuccessful.
ImageInfo * IICreateImage(CFURLRef url);

// Save the given image to a file at the given url with the given size.
// Returns true if successful, false otherwise.
bool IISaveImage(ImageInfo * image, CFURLRef url, size_t width, size_t height);

// Draw the image to the given context centered inside the given bounds
void IIDrawImage(ImageInfo * image, CGContextRef context, CGRect bounds);

// Applies the transformations specified in the ImageInfo struct without drawing the actual image
void IIApplyTransformation(ImageInfo * image, CGContextRef context, CGRect bounds);

// Draw the image to the given context centered inside the given bounds with
// the transformation info. The CTM of the context is unchanged after this call
void IIDrawImageTransformed(ImageInfo * image, CGContextRef context, CGRect bounds);

// Release the ImageInfo struct and other associated data
// you should not refer to the reference after this call
void IIRelease(ImageInfo * image);

#ifdef __cplusplus
}
#endif