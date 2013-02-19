/*
	    File: AppController.m
	Abstract: View and Controller classes.
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

#import <OpenGL/gl.h>
#import <OpenGL/CGLMacro.h>

#import "AppController.h"

#define __FLOAT_RENDERING__ 0 //Only activate on supported hardware and this might have rendering artifacts

@implementation AppView

- (BOOL) renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
	[(AppController*)[NSApp delegate] setRenderTime:time];
	
	return [super renderAtTime:time arguments:arguments];
}

@end

@implementation AppController

- (id) init
{
	if(self = [super init]) {
		/* Set defaults */
		posterWidth = 1600;
		posterHeight = 900;
		tilingFactor = 4;
	}
	
	return self;
}

- (void) dealloc
{
	[_compositionPath release];
	
	[super dealloc];
}

- (void) setRenderTime:(NSTimeInterval)time
{
	_renderTime = time;
}

- (void) windowWillClose:(NSNotification*)notification
{
	[NSApp terminate:self];
}

- (IBAction) loadComposition:(id)sender
{
	NSOpenPanel*							openPanel = [NSOpenPanel openPanel];
	
	/* Load user selected composition on the QCView */
	if([openPanel runModalForTypes:[NSArray arrayWithObject:@"qtz"]] == NSFileHandlingPanelOKButton) {
		if(![qcView loadCompositionFromFile:[openPanel filename]])
		NSBeep();
		else {
			[_compositionPath release];
			_compositionPath = [[openPanel filename] copy];
			[qcView startRendering];
		}
	}
}

- (IBAction) exportPoster:(id)sender
{
	NSUInteger								tileWidth = posterWidth / tilingFactor,
											tileHeight = posterHeight / tilingFactor;
	NSSavePanel*							savePanel = [NSSavePanel savePanel];
	NSOpenGLPixelFormatAttribute			attributes[] = {NSOpenGLPFAAccelerated, NSOpenGLPFAPixelBuffer, NSOpenGLPFADepthSize, 24,
#if __FLOAT_RENDERING__
															NSOpenGLPFAColorSize, 128, NSOpenGLPFAColorFloat,
#else
															NSOpenGLPFAColorSize, 32,
#endif															
															0};
	QCRenderer*								renderer = nil;
	NSOpenGLContext*						context = nil;
	NSOpenGLPixelFormat*					pixelFormat = nil;
	NSOpenGLPixelBuffer*					pixelBuffer = nil;
	CGContextRef							bitmapRef = NULL;
	void*									bufferPtr = NULL;
	CGColorSpaceRef							colorSpaceRef = NULL;
	CGLContextObj							cgl_ctx;
	CGImageRef								imageRef;
	CGImageDestinationRef					destinationRef;
	unsigned								row,
											column,
											rowBytes;
	NSDictionary*							properties;
	QCComposition*							composition;
	
	/* Make sure we have a composition */
	if(![qcView loadedComposition]) {
		NSBeep();
		return;
	}
	[qcView pauseRendering];
	
	/* Display the save panel */
#if __FLOAT_RENDERING__
	[savePanel setRequiredFileType:@"tiff"];
#else
	[savePanel setRequiredFileType:@"png"];
#endif
	if([savePanel runModalForDirectory:nil file:@"My Poster"] != NSFileHandlingPanelOKButton) {
		[qcView resumeRendering];
		return;
	}
	
	/* Get our rendering colorspace */
	colorSpaceRef = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	if(colorSpaceRef == NULL) {
		NSLog(@"Failed creating CGColorSpace");
		goto CleanUp;
	}
	
	/* Create the OpenGL context */
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
	context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
	if(context == nil) {
		NSLog(@"Failed creating NSOpenGLContext");
		goto CleanUp;
	}
	
	/* Define "cgl_ctx" for CGLMacro.h */
	cgl_ctx = [context CGLContextObj];
	
	/* Create the rendering pixel buffer and set it as the rendering target for the context */
	pixelBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:GL_TEXTURE_RECTANGLE_EXT textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:tileWidth pixelsHigh:tileHeight];
	if(pixelBuffer == nil) {
		NSLog(@"Failed creating NSOpenGLPixelBuffer");
		goto CleanUp;
	}
	[context setPixelBuffer:pixelBuffer cubeMapFace:0 mipMapLevel:0 currentVirtualScreen:[context currentVirtualScreen]];
	
	/* Create the QCRenderer */
	if(composition = [QCComposition compositionWithFile:_compositionPath])
	renderer = [[QCRenderer alloc] initWithCGLContext:[context CGLContextObj] pixelFormat:[pixelFormat CGLPixelFormatObj] colorSpace:colorSpaceRef composition:composition];
	if(renderer == nil) {
		NSLog(@"Failed creating QCRenderer");
		goto CleanUp;
	}
	
	/* Create bitmap for poster image */
	rowBytes = tilingFactor * tileWidth * 4;
#if __FLOAT_RENDERING__
	rowBytes *= 4;
#endif
	bufferPtr = calloc(1, tilingFactor * tileHeight * rowBytes);
	if(bufferPtr == NULL) {
		NSLog(@"Failed creating buffer");
		goto CleanUp;
	}
#if __FLOAT_RENDERING__
	bitmapRef = CGBitmapContextCreate(bufferPtr, tilingFactor * tileWidth, tilingFactor * tileHeight, 32, rowBytes, colorSpaceRef, kCGBitmapFloatComponents | kCGImageAlphaPremultipliedLast);
#else
	bitmapRef = CGBitmapContextCreate(bufferPtr, tilingFactor * tileWidth, tilingFactor * tileHeight, 8, rowBytes, colorSpaceRef, kCGImageAlphaPremultipliedLast);
#endif
	if(bitmapRef == NULL) {
		NSLog(@"Failed creating CGBitmapContext");
		goto CleanUp;
	}
	
	/* Render tiles and assemble poster image - NOTE: So that aspect ratio if properly preserved when rendering we need to have the same number of tiles vertically and horizontally */
	for(row = 0; row < tilingFactor; ++row) {
		for(column = 0; column < tilingFactor; ++column) {
			/* Configure projection matrix to zoom on current tile */
			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			glPushMatrix();
			glTranslatef((GLfloat)(tilingFactor - column - 1) * 2.0 - (GLfloat)tilingFactor + 1.0, (GLfloat)(tilingFactor - row - 1) * 2.0 - (GLfloat)tilingFactor + 1.0, 0.0);
			glScalef((GLfloat)tilingFactor, (GLfloat)tilingFactor, 1.0);
			
			/* Render tile */
			if(![renderer renderAtTime:_renderTime arguments:nil]) {
				NSLog(@"QCRenderer failed rendering at time %f", _renderTime);
				goto CleanUp;
			}
			
			/* Restore projection matrix */
			glMatrixMode(GL_PROJECTION);
			glPopMatrix();
			
			/* Grab tile as image */
			imageRef = (CGImageRef)[renderer createSnapshotImageOfType:@"CGImage"];
			if(imageRef == NULL) {
				NSLog(@"Failed retrieving image at time %f", _renderTime);
				goto CleanUp;
			}
			
			/* Draw image in context */
			CGContextDrawImage(bitmapRef, CGRectMake(column * tileWidth, row * tileHeight, tileWidth, tileHeight), imageRef);
			CGImageRelease(imageRef);
		}
	}
	
	/* Save poster image */
	if(imageRef = CGBitmapContextCreateImage(bitmapRef)) {
#if __FLOAT_RENDERING__
		properties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:5] forKey:(NSString*)kCGImagePropertyTIFFCompression] forKey:(NSString*)kCGImagePropertyTIFFDictionary]; //LZW compression
		if(destinationRef = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[savePanel filename]], kUTTypeTIFF, 1, NULL))
#else
		properties = nil;
		if(destinationRef = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[savePanel filename]], kUTTypePNG, 1, NULL))
#endif
		{
			CGImageDestinationAddImage(destinationRef, imageRef, (CFDictionaryRef)properties);
			if(!CGImageDestinationFinalize(destinationRef))
			NSLog(@"CGImageDestinationFinalize() failed");
			CFRelease(destinationRef);
		}
		else
		NSLog(@"Failed creating CGImageDestination");
		CGImageRelease(imageRef);
	}
	else
	NSLog(@"Failed creating image from bitmapRef");
	
CleanUp:
	/* Clean up */
	CGContextRelease(bitmapRef);
	if(bufferPtr)
	free(bufferPtr);
	[context clearDrawable];
	[pixelBuffer release];
	[renderer release];
	[context release];
	[pixelFormat release];
	CGColorSpaceRelease(colorSpaceRef);
	[qcView resumeRendering];
}

@end
