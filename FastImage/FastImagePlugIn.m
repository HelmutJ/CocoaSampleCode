/*
	    File: FastImagePlugIn.m
	Abstract: FastImagePlugin class.
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

#import "FastImagePlugIn.h"
#import "ArgumentKeys.h"

#define	kQCPlugIn_Name				@"FastImage"
#define	kQCPlugIn_Description		@"Outputs a texture based image directly from the host application."

@implementation FastImagePlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic outputImage;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"outputImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a provider (it outputs an image coming from an outside source) */
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) but needs idling */
	return kQCPlugInTimeModeIdle;
}

@end

@implementation FastImagePlugIn (Execution)

static void _BufferReleaseCallback(const void* address, void* context)
{
	/* Destroy the CGContext and its backing */
	free((void*)address);
}

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	CGContextRef				bitmapContext;
	CGImageSourceRef			source;
	CGImageRef					image;
	void*						baseAddress;
	size_t						rowBytes;
	NSString*					path;
	CGRect						bounds;
	
	/* Make sure there is not already a running instance in this Quartz Composer environment */
	if([[[context userInfo] objectForKey:kArgumentKeyPrefix] boolValue])
	return NO;
	
	/* Create CGImage from image file */
	path = [[NSBundle bundleForClass:[FastImagePlugIn class]] pathForResource:@"PlaceHolder" ofType:@"png"];
	if(path == nil)
	return NO;
	source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
	if(source == NULL)
	return NO;
	image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	if(image == NULL)
	return NO;
	
	/* Create CGContext backing */
	rowBytes = CGImageGetWidth(image) * 4;
	if(rowBytes % 16)
	rowBytes = ((rowBytes / 16) + 1) * 16;
	baseAddress = valloc(CGImageGetHeight(image) * rowBytes);
	if(baseAddress == NULL) {
		CGImageRelease(image);
		return NO;
	}
	
	/* Create CGContext and draw image into it */
	bitmapContext = CGBitmapContextCreate(baseAddress, CGImageGetWidth(image), CGImageGetHeight(image), 8, rowBytes, [context colorSpace], kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
	if(bitmapContext == NULL) {
		free(baseAddress);
		CGImageRelease(image);
		return NO;
	}
	bounds = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGContextClearRect(bitmapContext, bounds);
	CGContextDrawImage(bitmapContext, bounds, image);
	
	/* We don't need the image and context anymore */
	CGImageRelease(image);
	CGContextRelease(bitmapContext);
	
	/* Create image provider from backing */
#if __BIG_ENDIAN__
	_placeHolderProvider = [[context outputImageProviderFromBufferWithPixelFormat:QCPlugInPixelFormatARGB8 pixelsWide:CGImageGetWidth(image) pixelsHigh:CGImageGetHeight(image) baseAddress:baseAddress bytesPerRow:rowBytes releaseCallback:_BufferReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES] retain];
#else
	_placeHolderProvider = [[context outputImageProviderFromBufferWithPixelFormat:QCPlugInPixelFormatBGRA8 pixelsWide:CGImageGetWidth(image) pixelsHigh:CGImageGetHeight(image) baseAddress:baseAddress bytesPerRow:rowBytes releaseCallback:_BufferReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES] retain];
#endif
	if(_placeHolderProvider == nil) {
		free(baseAddress);
		return NO;
	}
	
	/* Remember there's a running instance in the current Quartz Composer environment */
	[[context userInfo] setObject:[NSNumber numberWithBool:YES] forKey:kArgumentKeyPrefix];
	
	return YES;
}

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* context)
{
	/* Delete the OpenGL texture */
	glDeleteTextures(1, &name);
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	GLuint						name = [[arguments objectForKey:kArgumentKey_TextureName] unsignedIntValue];
	CGLContextObj				cgl_ctx = [context CGLContextObj];
	id							provider;
	
	/* Create a image provider from the OpenGL texture passed through the execution arguments if any - The provider acquires ownership of the texture */
	if(name) {
		provider = [context outputImageProviderFromTextureWithPixelFormat:[arguments objectForKey:kArgumentKey_TextureFormat] pixelsWide:[[arguments objectForKey:kArgumentKey_TextureWidth] unsignedIntValue] pixelsHigh:[[arguments objectForKey:kArgumentKey_TextureHeight] unsignedIntValue] name:name flipped:YES releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:(CGColorSpaceRef)[arguments objectForKey:kArgumentKey_TextureColorSpace] shouldColorMatch:YES];
		if(provider == nil) {
			glDeleteTextures(1, &name);
			return NO;
		}
	}
	
	/* Set output image */
	self.outputImage = (name ? provider : _placeHolderProvider);
	
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/* Our instance is about to stop running */
	[[context userInfo] removeObjectForKey:kArgumentKeyPrefix];
	
	/* Release placeholder image provider */
	[_placeHolderProvider release];
}

@end
