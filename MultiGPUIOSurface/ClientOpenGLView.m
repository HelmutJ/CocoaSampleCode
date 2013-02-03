/*
    File: ClientOpenGLView.m
Abstract: 
This class implements the client specific subclass of NSOpenGLView. 
It handles the client side rendering, which calls into the GLUT-based
BluePony rendering code, substituting the contents of an IOSurface from
the server application instead of the OpenGL logo.

It also shows how to bind IOSurface objects to OpenGL textures.

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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#import "ClientOpenGLView.h"
#import "ClientController.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <OpenGL/CGLIOSurface.h>

#include "bluepony.h"

@implementation ClientOpenGLView

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormat *pix_fmt;
	
	NSOpenGLPixelFormatAttribute attribs[] =
	{
		NSOpenGLPFAAllowOfflineRenderers,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAMultisample, 1,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 4,
		NSOpenGLPFANoRecovery,
		0
	};
	
	pix_fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	if(!pix_fmt)
	{
		// Try again without multisample
		NSOpenGLPixelFormatAttribute attribs_no_multisample[] =
		{
			NSOpenGLPFAAllowOfflineRenderers,
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFADepthSize, 24,
			NSOpenGLPFANoRecovery,
			0
		};

		pix_fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs_no_multisample];
		if(!pix_fmt)
			[NSApp terminate:nil];
	}
	
	self = [super initWithFrame:frame pixelFormat:pix_fmt];
	[pix_fmt release];
	
	[[self openGLContext] makeCurrentContext];

	return self;
}

- (void)update
{
	// Override to do nothing.
}

- (NSArray *)rendererNames
{
	NSMutableArray *rendererNames;
	GLint i, numScreens;
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];
	
	rendererNames = [[NSMutableArray alloc] init];
	
	numScreens = [[self pixelFormat] numberOfVirtualScreens];
	for(i = 0; i < numScreens; i++)
	{
		[[self openGLContext] setCurrentVirtualScreen:i];
		[rendererNames addObject:[NSString stringWithUTF8String:(const char *)glGetString(GL_RENDERER)]];
	}
	
	return [rendererNames autorelease];
}

- (void)setRendererIndex:(uint32_t)index
{
	[[self openGLContext] setCurrentVirtualScreen:index];
}

// Create an IOSurface backed texture
- (GLuint)setupIOSurfaceTexture:(IOSurfaceRef)ioSurfaceBuffer
{
	GLuint name;
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];
	
	glGenTextures(1, &name);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, name);
	CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_EXT, GL_RGBA, 512, 512, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV,
					ioSurfaceBuffer, 0);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);	
	
	return name;
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)theRect
{	
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];
		
	// Client draws bluepony, with current IO surface contents as logo texture....

	// There is a minor bug where drawRect: gets called before we really know for sure
	// if we are master or slave, so both apps wind up in here.  So, in order to avoid
	// BluePony GL state leaking into the Atlantis code, we disable any GL state that
	// might be problematic just in case we later wind up being the master.
	
	BluePonyIdle();
	BluePonyInit();
	BluePonyReshape(512, 512);
	BluePonyDisplay([[NSApp delegate] currentTextureName], 512, 512);
	
	glDisable(GL_NORMALIZE);
	glDisable(GL_LIGHTING);
	glShadeModel(GL_SMOOTH);
	
	[[self openGLContext] flushBuffer];
	
}


@end
