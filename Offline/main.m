/*
	    File: main.m
	Abstract: Main file.
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
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

#import <libgen.h>
#import <AppKit/AppKit.h>
#import <Quartz/Quartz.h>
#import <OpenGL/CGLMacro.h>

@interface OfflineRenderer : NSObject
{
	QCRenderer*					_renderer;
#ifndef MAC_OS_X_VERSION_10_5
	NSOpenGLPixelBuffer*		_pixelBuffer;
	NSOpenGLContext*			_openGLContext;
	void*						_scratchBufferPtr;
	unsigned					_scratchBufferRowBytes;
#endif
}
- (id) initWithCompositionPath:(NSString*)path pixelsWide:(unsigned)width pixelsHigh:(unsigned)height;
- (NSBitmapImageRep*) bitmapImageForTime:(NSTimeInterval)time;
@end

@implementation OfflineRenderer

- (id) init
{
	return [self initWithCompositionPath:nil pixelsWide:0 pixelsHigh:0];
}

#ifdef MAC_OS_X_VERSION_10_5

- (NSBitmapImageRep*) bitmapImageForTime:(NSTimeInterval)time
{
	//Render a frame from the composition at the specified time
	if(![_renderer renderAtTime:time arguments:nil])
	return nil;
	
	//Grab a snapshot of rendered image
	return [[_renderer createSnapshotImageOfType:@"NSBitmapImageRep"] autorelease];
}

- (id) initWithCompositionPath:(NSString*)path pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
{
	CGColorSpaceRef					colorSpace;
	QCComposition*					composition;
	
	//Check parameters - Rendering at sizes smaller than 16x16 will likely produce garbage
	if(![path length] || (width < 16) || (height < 16)) {
		[self release];
		return nil;
	}
	
	if(self = [super init]) {
		//Select the colorspace to use for rendering
		colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		
		//Create the offscreen QCRenderer
		if(composition = [QCComposition compositionWithFile:path])
		_renderer = [[QCRenderer alloc] initOffScreenWithSize:NSMakeSize(width, height) colorSpace:colorSpace composition:composition];
		CGColorSpaceRelease(colorSpace);
		if(_renderer == nil) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

#else

- (id) initWithCompositionPath:(NSString*)path pixelsWide:(unsigned)width pixelsHigh:(unsigned)height
{
	NSOpenGLPixelFormatAttribute	attributes[] = {
														NSOpenGLPFAPixelBuffer,
														NSOpenGLPFANoRecovery,
														NSOpenGLPFAAccelerated,
														NSOpenGLPFADepthSize, 24,
														(NSOpenGLPixelFormatAttribute) 0
													};
	NSOpenGLPixelFormat*			format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
	
	//Check parameters - Rendering at sizes smaller than 16x16 will likely produce garbage
	if(![path length] || (width < 16) || (height < 16)) {
		[self release];
		return nil;
	}
	
	if(self = [super init]) {
		//Create the OpenGL pixel buffer to render into
		_pixelBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:GL_TEXTURE_RECTANGLE_EXT textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:width pixelsHigh:height];
		if(_pixelBuffer == nil) {
			NSLog(@"Cannot create OpenGL pixel buffer");
			[self release];
			return nil;
		}
		
		//Create the OpenGL context to render with (with color and depth buffers)
		_openGLContext = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
		if(_openGLContext == nil) {
			NSLog(@"Cannot create OpenGL context");
			[self release];
			return nil;
		}
		[_openGLContext setPixelBuffer:_pixelBuffer cubeMapFace:0 mipMapLevel:0 currentVirtualScreen:[_openGLContext currentVirtualScreen]];
		
		//Create the QuartzComposer Renderer with that OpenGL context and the specified composition file
		_renderer = [[QCRenderer alloc] initWithOpenGLContext:_openGLContext pixelFormat:format file:path];
		if(_renderer == nil) {
			NSLog(@"Cannot create QCRenderer");
			[self release];
			return nil;
		}
		
		//Create a scratch buffer used to downloads the pixels from the OpenGL pixel buffer - For optimal performances the buffer is paged-aligned and the rowbytes is a multiple of 64 bytes
		_scratchBufferRowBytes = (width * 4 + 63) & ~63;
		_scratchBufferPtr = valloc(height * _scratchBufferRowBytes);
		if(_scratchBufferPtr == NULL) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (NSBitmapImageRep*) bitmapImageForTime:(NSTimeInterval)time
{
	//IMPORTANT: We use the macros provided by <OpenGL/CGLMacro.h> which provide better performances and allows us not to bother with making sure the current context is valid
	CGLContextObj					cgl_ctx = [_openGLContext CGLContextObj];
	int								width = [_pixelBuffer pixelsWide],
									height = [_pixelBuffer pixelsHigh],
									bitmapRowBytes = 4 * width;
	NSBitmapImageRep*				bitmap;
	GLint							save;
	int								i;
	
	//Render a frame from the composition at the specified time
	if(![_renderer renderAtTime:time arguments:nil])
	return nil;
	
	//Read pixels back from the OpenGL pixel buffer in ARGB 32 bits format - For extra safety, we save / restore the OpenGL states we change 
	glGetIntegerv(GL_PACK_ROW_LENGTH, &save);
	glPixelStorei(GL_PACK_ROW_LENGTH, _scratchBufferRowBytes / 4);
#if __BIG_ENDIAN__
	glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, _scratchBufferPtr);
#else
	glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, _scratchBufferPtr);
#endif
	glPixelStorei(GL_PACK_ROW_LENGTH, save);
	if(glGetError())
	return nil;
	
	//User NSBitmapImageRep to allocate a memory buffer of ARGB 32 bits pixels - We use the "NSCalibratedRGBColorSpace" so that no color profile is embedded in the bitmap
	bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat bytesPerRow:bitmapRowBytes bitsPerPixel:32];
	if(bitmap == nil)
	return nil;
	
	//Copy the pixels line by line from the scratch buffer to the bitmap and flip vertically - OpenGL downloaded images are upside-down
	for(i = 0; i < height; ++i)
	bcopy(_scratchBufferPtr + i * _scratchBufferRowBytes, (char*)[bitmap bitmapData] + (height - i - 1) * bitmapRowBytes, bitmapRowBytes);
	
	return [bitmap autorelease];
}

#endif

- (void) dealloc 
{
#ifndef MAC_OS_X_VERSION_10_5
	//Destroy the scratch buffer
	if(_scratchBufferPtr)
	free(_scratchBufferPtr);
#endif
	
	//Destroy the renderer
	[_renderer release];
	
#ifndef MAC_OS_X_VERSION_10_5
	//Destroy the OpenGL context
	[_openGLContext clearDrawable];
	[_openGLContext release];
	
	//Destroy the OpenGL pixel buffer
	[_pixelBuffer release];
#endif
	
	[super dealloc];
}

@end

int main(int argc, const char* argv[])
{
	NSAutoreleasePool*			pool = [NSAutoreleasePool new];
	NSString*					compositionPath;
	NSString*					folderPath;
	OfflineRenderer*			renderer;
	NSBitmapImageRep*			bitmapImage;
	NSTimeInterval				time;
	NSData*						tiffData;
	NSString*					fileName;
	
	//Make sure we have the correct number of arguments
	if(argc >= 3) {
		//Process the arguments
		compositionPath = [[NSString stringWithUTF8String:argv[1]] stringByStandardizingPath];
		folderPath = [[NSString stringWithUTF8String:argv[2]] stringByStandardizingPath];
		
		//Create an offline renderer
		renderer = [[OfflineRenderer alloc] initWithCompositionPath:compositionPath pixelsWide:640 pixelsHigh:480];
		if(renderer) {
			//Render a frame every second for 10 seconds and save the resulting images as LZW compressed TIFF files
			printf("Rendering composition \"%s\"...\n", [[compositionPath lastPathComponent] UTF8String]);
			for(time = 0.0; time <= 10.0; time += 1.0) {
				bitmapImage = [renderer bitmapImageForTime:time];
				if(bitmapImage) {
					tiffData = [bitmapImage TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0];
					fileName = [NSString stringWithFormat:@"%@-%g.tiff", [[compositionPath lastPathComponent] stringByDeletingPathExtension], time];
					if([tiffData writeToFile:[folderPath stringByAppendingPathComponent:fileName] atomically:YES])
					printf("\tRendered image \"%s\" at time %.3f\n", [fileName UTF8String], time);
					else
					NSLog(@"Image writing to disk failed (%s)", fileName);
				}
				else
				NSLog(@"Image rendering at time %f failed", time);
			}
			printf("...done!\n");
			[renderer release];
		}
		else
		NSLog(@"Offline renderer creation for composition failed (%@)", compositionPath);
	}
	else
	printf("Usage: %s sourceComposition destinationFolder\n", basename((char*)argv[0]));
	
	[pool release];
	
	return 0;
}
