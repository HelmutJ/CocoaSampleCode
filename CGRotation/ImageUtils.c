/*
    File: ImageUtils.c
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

#include "ImageUtils.h"

int IIGetImageOrientation(ImageInfo * image);
void FixupImageOrientation(ImageInfo * image);

void IIRotateContext(ImageInfo * image, CGContextRef context, CGRect bounds);
void IIScaleContext(ImageInfo * image, CGContextRef context, CGRect bounds);
void IITranslateContext(ImageInfo * image, CGContextRef context);

// Create a new image from a file at the given url
// Returns NULL if unsuccessful.
ImageInfo * IICreateImage(CFURLRef url)
{
	ImageInfo * ii = NULL;
	// Try to create an image source to the image passed to us
	CGImageSourceRef imageSrc = CGImageSourceCreateWithURL(url, NULL);
	if(imageSrc != NULL)
	{
		// And if we can, try to obtain the first image available
		CGImageRef image = CGImageSourceCreateImageAtIndex(imageSrc, 0, NULL);
		if(image != NULL)
		{
			// and if we could, create the ImageInfo struct with default values
			ii = (ImageInfo*)malloc(sizeof(ImageInfo));
			ii->rotation = 0.0;
			ii->scaleX = 1.0;
			ii->scaleY = 1.0;
			ii->translateX = 0.0;
			ii->translateY = 0.0;
			// the ImageInfo struct now owns this CGImageRef.
			ii->image = image;
			// the ImageInfo struct now owns this CFDictionaryRef.
			ii->properties = CGImageSourceCopyPropertiesAtIndex(imageSrc, 0, NULL);
			FixupImageOrientation(ii);
		}
		// cleanup the image source
		CFRelease(imageSrc);
	}
	return ii;
}

// Gets the orientation of the image from the properties dictionary if available
// If the kCGImagePropertyOrientation is not available or invalid,
// then 1, the default orientation, is returned.
int IIGetImageOrientation(ImageInfo * image)
{
	int result = 1;
	CFNumberRef orientation = CFDictionaryGetValue(image->properties, kCGImagePropertyOrientation);
	if(orientation != NULL)
	{
		int orient;
		if(CFNumberGetValue(orientation, kCFNumberIntType, &orient))
		{
			result = orient;
		}
	}
	return result;
}

// Converts an image that isn't in the default orientation (orientation 1) to orientation 1.
// Quartz assumes all images drawn are in orientation 1, so by doing this we reduce the amount of work needed to draw later.
void FixupImageOrientation(ImageInfo * image)
{
	int orientation = IIGetImageOrientation(image);
	// If the orientation isn't 1 (the default orientation) then we'll create a new image at orientation 1
	if(orientation != 1)
	{
		CGContextRef context;
		size_t width = CGImageGetWidth(image->image), height = CGImageGetHeight(image->image);
		if(orientation <= 4)
		{
			// Orientations 1-4 are rotated 0 or 180 degrees, so they retain the width/height of the image
			context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGImageGetColorSpace(image->image), kCGImageAlphaPremultipliedFirst);
		}
		else
		{
			// Orientations 5-8 are rotated ±90 degrees, so they swap width & height.
			context = CGBitmapContextCreate(NULL, height, width, 8, 0, CGImageGetColorSpace(image->image), kCGImageAlphaPremultipliedFirst);
		}
		switch(orientation)
		{
			case 2:
				// 2 = 0th row is at the top, and 0th column is on the right - Flip Horizontal
				CGContextConcatCTM(context, CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0));
				break;
				
			case 3:
				// 3 = 0th row is at the bottom, and 0th column is on the right - Rotate 180 degrees
				CGContextConcatCTM(context, CGAffineTransformMake(-1.0, 0.0, 0.0, -1.0, width, height));
				break;
				
			case 4:
				// 4 = 0th row is at the bottom, and 0th column is on the left - Flip Vertical
				CGContextConcatCTM(context, CGAffineTransformMake(1.0, 0.0, 0, -1.0, 0.0, height));
				break;
				
			case 5:
				// 5 = 0th row is on the left, and 0th column is the top - Rotate -90 degrees and Flip Vertical
				CGContextConcatCTM(context, CGAffineTransformMake(0.0, -1.0, -1.0, 0.0, height, width));
				break;
				
			case 6:
				// 6 = 0th row is on the right, and 0th column is the top - Rotate 90 degrees
				CGContextConcatCTM(context, CGAffineTransformMake(0.0, -1.0, 1.0, 0.0, 0.0, width));
				break;
				
			case 7:
				// 7 = 0th row is on the right, and 0th column is the bottom - Rotate 90 degrees and Flip Vertical
				CGContextConcatCTM(context, CGAffineTransformMake(0.0, 1.0, 1.0, 0.0, 0.0, 0.0));
				break;
				
			case 8:
				// 8 = 0th row is on the left, and 0th column is the bottom - Rotate -90 degrees
				CGContextConcatCTM(context, CGAffineTransformMake(0.0, 1.0, -1.0, 0.0, height, 0.0));
				break;
		}
		// Finally draw the image and replace the one in the ImageInfo struct.
		CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), image->image);
		CFRelease(image->image);
		image->image = CGBitmapContextCreateImage(context);
		CFRelease(context);
	}
}

// Save the given image to a file at the given url.
// Returns true if successful, false otherwise.
bool IISaveImage(ImageInfo * image, CFURLRef url, size_t width, size_t height)
{
	bool result = false;

	// If there is no image, no destination, or the width/height is 0, then fail early.
	require((image != NULL) && (url != NULL) && (width != 0) && (height != 0), bail);
	
	// Try to create a png image destination at the url given to us
	CGImageDestinationRef imageDest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	if(imageDest != NULL)
	{
		// And if we can, then we can start building our final image.
		// We begin by creating a CGBitmapContext to host our desintation image.
		
		// Create the bitmap context
		CGContextRef bitmapContext = CGBitmapContextCreate(
			NULL, // let Quartz allocate for us
			width, // width
			height, // height
			8, // 8 bits per component
			0, // bytes per pixel times number of pixels wide
			CGImageGetColorSpace(image->image), // use the same colorspace as the original image
			kCGImageAlphaPremultipliedFirst); // use premultiplied alpha
			
		// Check that all that went well
		if(bitmapContext != NULL)
		{
			// Now, we draw the image to the bitmap context
			IIDrawImageTransformed(image, bitmapContext, CGRectMake(0.0, 0.0, width, height));
			
			// We have now gotten our image data to the bitmap context, and correspondingly
			// into imageData. If we wanted to, we could look at any of the pixels of the image
			// and manipulate them in any way that we desire, but for this case, we're just
			// going to ask ImageIO to write this out to disk.
			
			// Obtain a CGImageRef from the bitmap context for ImageIO
			CGImageRef imageIOImage = CGBitmapContextCreateImage(bitmapContext);
			
			// Check to see if the image is not in orientation=1
			// If it is, then we need to replace the orientation key for the new image file.
			if(IIGetImageOrientation(image) != 1)
			{
				// If the orientation in the original image was not the default,
				// then we need to replace that key in a duplicate of that dictionary
				// and then pass that dictionary to ImageIO when adding the image.
				CFMutableDictionaryRef prop = CFDictionaryCreateMutableCopy(NULL, 0, image->properties);
				int orientation = 1;
				CFNumberRef cfOrientation = CFNumberCreate(NULL, kCFNumberIntType, &orientation);
				CFDictionarySetValue(prop, kCGImagePropertyOrientation, cfOrientation);
				
				// And add the image with the new properties
				CGImageDestinationAddImage(imageDest, imageIOImage, prop);
				
				// Clean up after ourselves
				CFRelease(prop);
				CFRelease(cfOrientation);
			}
			else
			{
				// Otherwise, the image was already in the default orientation and we can just save
				// it with the original properties.
				CGImageDestinationAddImage(imageDest, imageIOImage, image->properties);
			}
			
			// Release the image and the context, since we are done with both.
			CGImageRelease(imageIOImage);
			CGContextRelease(bitmapContext);
		}
		
		// Finalize the image destination
		result = CGImageDestinationFinalize(imageDest);
		CFRelease(imageDest);
	}
	
	bail:
	return result;
}

// Applies the transformations specified in the ImageInfo struct without drawing the actual image
void IIApplyTransformation(ImageInfo * image, CGContextRef context, CGRect bounds)
{
	// Whenever you do multiple CTM changes, you have to be very careful with order.
	// Changing the order of your CTM changes changes the outcome of the drawing operation.
	// For example, if you scale a context by 2.0 along the x-axis, and then translate
	// the context by 10.0 along the x-axis, then you will see your drawing will be
	// in a different position than if you had done the operations in the opposite order.

	// Our intent with this operation is that we want to change the location from which we start drawing
	// (translation), then rotate our axies so that our image appears at an angle (rotation), and finally
	// scale our axies so that our image has a different size (scale).
	// Changing the order of operations will markedly change the results.
	IITranslateContext(image, context);
	IIRotateContext(image, context, bounds);
	IIScaleContext(image, context, bounds);
}

// Draw the image to the given context centered inside the given bounds
void IIDrawImage(ImageInfo * image, CGContextRef context, CGRect bounds)
{
	CGRect imageRect;
	
	// Setup the image size so that the image fills it's natural boudaries in the base coordinate system.
	imageRect.size.width = CGImageGetWidth(image->image);
	imageRect.size.height = CGImageGetHeight(image->image);
	
	// Position the image such that it is centered in the parent view.
	// TODO: fix up for pixel boundaries
	imageRect.origin.x = (bounds.size.width - imageRect.size.width) / 2.0f;
	imageRect.origin.y = (bounds.size.height - imageRect.size.height) / 2.0f;

	// And draw the image.
	CGContextDrawImage(context, imageRect, image->image);
}

// Rotates the context around the center point of the given bounds
void IIRotateContext(ImageInfo * image, CGContextRef context, CGRect bounds)
{
	// First we translate the context such that the 0,0 location is at the center of the bounds
	CGContextTranslateCTM(context, bounds.size.width/2.0f, bounds.size.height/2.0f);
	
	// Then we rotate the context, converting our angle from degrees to radians
	CGContextRotateCTM(context, image->rotation * M_PI / 180.0f);
	
	// Finally we have to restore the center position
	CGContextTranslateCTM(context, -bounds.size.width/2.0f, -bounds.size.height/2.0f);	
}

// Scale the context around the center point of the given bounds
void IIScaleContext(ImageInfo * image, CGContextRef context, CGRect bounds)
{
	// First we translate the context such that the 0,0 location is at the center of the bounds
	CGContextTranslateCTM(context, bounds.size.width/2.0f, bounds.size.height/2.0f);
	
	// Next we scale the context to the size that we want
	CGContextScaleCTM(context, image->scaleX, image->scaleY);
	
	// Finally we have to restore the center position
	CGContextTranslateCTM(context, -bounds.size.width/2.0f, -bounds.size.height/2.0f);	
}

// Translate the context
void IITranslateContext(ImageInfo * image, CGContextRef context)
{
	// Translation is easy, just translate.
	CGContextTranslateCTM(context, image->translateX, image->translateY);
}

// Draw the image to the given context centered inside the given bounds with
// the transformation info. The CTM of the context is unchanged after this call
void IIDrawImageTransformed(ImageInfo * image, CGContextRef context, CGRect bounds)
{
	// We save the current graphics state so as to not disrupt it for the caller.
	CGContextSaveGState(context);
	
	// Apply the transformation
	IIApplyTransformation(image, context, bounds);
	
	// Draw the image centered in the context
	IIDrawImage(image, context, bounds);
	
	// Restore our original graphics state.
	CGContextRestoreGState(context);
}

// Release the ImageInfo struct and other associated data
// you should not refer to the reference after this call
// This function is NULL safe.
void IIRelease(ImageInfo * image)
{
	if(image != NULL)
	{
		CGImageRelease(image->image);
		if(image->properties != NULL)
		{
			CFRelease(image->properties);
		}
		free(image);
	}
}