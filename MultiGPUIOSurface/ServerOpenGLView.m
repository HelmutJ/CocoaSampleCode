/*
    File: ServerOpenGLView.m
Abstract: 
This class implements the server specific subclass of NSOpenGLView. 
It handles the server side rendering, which calls into the GLUT-based
Atlantis rendering code to draw into an IOSurface using an FBO.  It
also performs local rendering of each frame for display purposes.

It also shows how to bind IOSurface objects to OpenGL textures, and
how to use those for rendering with FBOs.

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

#import "ServerOpenGLView.h"
#import "ServerController.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <OpenGL/CGLIOSurface.h>

#include "atlantis.h"

@implementation ServerOpenGLView

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
		0
	};
	
	pix_fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	if(!pix_fmt)
	{
		NSLog(@"couldn't create pixel format\n");
		[NSApp terminate:nil];
	}
	
	self = [super initWithFrame:frame pixelFormat:pix_fmt];
	[pix_fmt release];
	
	[[self openGLContext] makeCurrentContext];

	if(self)
		InitFishs();
		
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
// Create an FBO using the name of this texture and bind the texture to the color attachment of the FBO
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
	
	// Generate an FBO using the same name with the same texture bound to it as a render target.

	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, name);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_EXT, name, 0);

	if(!_depthBufferName)
	{
	    glGenRenderbuffersEXT(1, &_depthBufferName);
	    glRenderbufferStorageEXT(GL_TEXTURE_RECTANGLE_EXT, GL_DEPTH, 512, 512);
	}
	glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_RECTANGLE_EXT, _depthBufferName);
	    
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

	return name;
}

// Render to the current IOSurface via the corresponding FBO previously setuped in -setupIOSurfaceTexture:
- (void)renderToCurrentIOSurface
{
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, [[NSApp delegate] currentTextureName]);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	AtlantisInit();
	AtlantisAnimate();
	AtlantisReshape(512, 512);
	AtlantisDisplay();
	
	glDisable(GL_LIGHTING);
	glDisable(GL_FOG);
	
	// Bind back to system drawable.
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

	glFlush();	
}

// Fill the view with the IOSurface backed texture 
- (void)textureFromCurrentIOSurface
{
	NSRect bounds = [self bounds];
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];

	// Render quad from our iosurface texture
	glViewport(0, 0, (GLint)bounds.size.width, (GLint)bounds.size.height);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();	
	glOrtho(0.0, (GLfloat)bounds.size.width, 0.0f, (GLfloat)bounds.size.height, -1.0f, 1.0f);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [[NSApp delegate] currentTextureName]);
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glTexEnvi(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	glBegin(GL_QUADS);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
	glTexCoord2f(0.0f, 0.0f);
	glVertex2f(0.0f, 0.0f);
	
	glTexCoord2f(512.0f, 0.0f);
	glVertex2f((GLfloat)bounds.size.width, 0.0f);

	glTexCoord2f(512.0f, 512.0f);
	glVertex2f((GLfloat)bounds.size.width, (GLfloat)bounds.size.height);

	glTexCoord2f(0.0f, 512.0f);
	glVertex2f(0.0f, (GLfloat)bounds.size.height);
	
	glEnd();

	glDisable(GL_TEXTURE_RECTANGLE_EXT);
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)theRect
{	
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];
		
	// Only the Master app renders to the IOSurface
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_DEPTH_TEST);
	[self renderToCurrentIOSurface];
	glDisable(GL_DEPTH_TEST);
	[self textureFromCurrentIOSurface];
	
	[[self openGLContext] flushBuffer];
	
	// This flush is necessary to ensure proper behavior if the MT engine is enabled.
	glFlush();
	
}


@end
