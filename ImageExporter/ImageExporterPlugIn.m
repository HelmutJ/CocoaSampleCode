/*
	    File: ImageExporterPlugIn.m
	Abstract: ImageExporterPlugin class.
	 Version: 1.0
	
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
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "ImageExporterPlugIn.h"

#define	kQCPlugIn_Name				@"Image Exporter"
#define	kQCPlugIn_Description		@"Writes the input image as a series of .png files to disk."

@implementation ImageExporterPlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputImage, inputPath;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"inputPath"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Destination Path", QCPortAttributeNameKey, @"~/Desktop", QCPortAttributeDefaultValueKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a consumer (it renders to image files) */
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	return kQCPlugInTimeModeNone;
}

@end

@implementation ImageExporterPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/* Reset image file index */
	_index = 0;
	
	return YES;
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	id<QCPlugInInputImageSource>	qcImage = self.inputImage;
	NSString*						pixelFormat;
	CGColorSpaceRef					colorSpace;
	CGDataProviderRef				dataProvider;
	CGImageRef						cgImage;
	CGImageDestinationRef			imageDestination;
	NSURL*							fileURL;
	BOOL							success;
	
	/* Make sure we have a new image */
	if(![self didValueForInputKeyChange:@"inputImage"] || !qcImage || ![self.inputPath length])
	return YES;
	
	/* Figure out pixel format and colorspace to use */
	colorSpace = [qcImage imageColorSpace];
	if(CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
	pixelFormat = QCPlugInPixelFormatI8;
	else if(CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB)
#if __BIG_ENDIAN__
	pixelFormat = QCPlugInPixelFormatARGB8;
#else
	pixelFormat = QCPlugInPixelFormatBGRA8;
#endif
	else
	return NO;
	
	/* Get a buffer representation from the image in its native colorspace */
	if(![qcImage lockBufferRepresentationWithPixelFormat:pixelFormat colorSpace:colorSpace forBounds:[qcImage imageBounds]])
	return NO;
	
	/* Create CGImage from buffer */
	dataProvider = CGDataProviderCreateWithData(NULL, [qcImage bufferBaseAddress], [qcImage bufferPixelsHigh] * [qcImage bufferBytesPerRow], NULL);
	cgImage = CGImageCreate([qcImage bufferPixelsWide], [qcImage bufferPixelsHigh], 8, (pixelFormat == QCPlugInPixelFormatI8 ? 8 : 32), [qcImage bufferBytesPerRow], colorSpace, (pixelFormat == QCPlugInPixelFormatI8 ? 0 : kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host), dataProvider, NULL, false, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	if(cgImage == NULL) {
		[qcImage unlockBufferRepresentation];
		return NO;
	}
	
	/* Write CGImage to disk as PNG file */
	fileURL = [NSURL fileURLWithPath:[[self.inputPath stringByStandardizingPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Image-%05i.png", ++_index]]];
	imageDestination = (fileURL ? CGImageDestinationCreateWithURL((CFURLRef)fileURL, kUTTypePNG, 1, NULL) : NULL);
	if(imageDestination == NULL) {
		CGImageRelease(cgImage);
		[qcImage unlockBufferRepresentation];
		return NO;
	}
	CGImageDestinationAddImage(imageDestination, cgImage, NULL);
	success = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	
	/* Destroy CGImage */
	CGImageRelease(cgImage);
	
	/* Release buffer representation */
	[qcImage unlockBufferRepresentation];
	
	return success;
}

@end
