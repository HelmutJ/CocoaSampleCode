/*
	    File: PBufferRenderer.m
	Abstract: PBufferRenderer class.
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

#import <OpenGL/CGLMacro.h>

#import "PBufferRenderer.h"

@implementation PBufferRenderer

- (id) init
{
	return [self initWithCompositionPath:nil textureTarget:0 textureWidth:0 textureHeight:0 openGLContext:nil];
}

- (id) initWithCompositionPath:(NSString*)path textureTarget:(GLenum)target textureWidth:(unsigned)width textureHeight:(unsigned)height openGLContext:(NSOpenGLContext*)context
{
	//IMPORTANT: We use the macros provided by <OpenGL/CGLMacro.h> which provide better performances and allows us not to bother with making sure the current context is valid
	CGLContextObj					cgl_ctx = [context CGLContextObj];
	NSOpenGLPixelFormatAttribute	attributes[] = {
														NSOpenGLPFAPixelBuffer,
														NSOpenGLPFANoRecovery,
														NSOpenGLPFAAccelerated,
														NSOpenGLPFADepthSize, 24,
														(NSOpenGLPixelFormatAttribute) 0
													};
	NSOpenGLPixelFormat*			format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
	GLint							saveTextureName;
	
	//Check parameters - Rendering at sizes smaller than 16x16 will likely produce garbage and we only support 2D or RECT textures
	if(![path length] || ((target != GL_TEXTURE_2D) && (target != GL_TEXTURE_RECTANGLE_EXT)) || (width < 16) || (height < 16) || (context == nil)) {
		[self release];
		return nil;
	}
	
	if(self = [super init]) {
		//Keep the target OpenGL context around
		_textureContext = [context retain];
		
		//Create the OpenGL pBuffer to render into
		_pixelBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:target textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:width pixelsHigh:height];
		if(_pixelBuffer == nil) {
			NSLog(@"Cannot create OpenGL pixel buffer");
			[self release];
			return nil;
		}
		
		//Create the OpenGL context to use to render in the pBuffer (with color and depth buffers) - It needs to be shared to ensure both contexts have identical virtual screen lists
		_pixelBufferContext = [[NSOpenGLContext alloc] initWithFormat:format shareContext:_textureContext];
		if(_pixelBufferContext == nil) {
			NSLog(@"Cannot create OpenGL context");
			[self release];
			return nil;
		}
		
		//Attach the OpenGL context to the pBuffer (make sure it uses the same virtual screen as the primary OpenGL context)
		[_pixelBufferContext setPixelBuffer:_pixelBuffer cubeMapFace:0 mipMapLevel:0 currentVirtualScreen:[_textureContext currentVirtualScreen]];
		
		//Create the QuartzComposer Renderer with that OpenGL context and the specified composition file
		_renderer = [[QCRenderer alloc] initWithOpenGLContext:_pixelBufferContext pixelFormat:format file:path];
		if(_renderer == nil) {
			NSLog(@"Cannot create QCRenderer");
			[self release];
			return nil;
		}
		
		//Create the texture on the target OpenGL context
		_textureTarget = target;
		glGenTextures(1, &_textureName);
		
		//Configure the texture - For extra safety, we save and restore the currently bound texture
		glGetIntegerv((_textureTarget == GL_TEXTURE_RECTANGLE_EXT ? GL_TEXTURE_BINDING_RECTANGLE_EXT : GL_TEXTURE_BINDING_2D), &saveTextureName);
		glBindTexture(_textureTarget, _textureName);
		glTexParameteri(_textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(_textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		if(_textureTarget == GL_TEXTURE_RECTANGLE_EXT) {
			glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		}
		else {
			glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(_textureTarget, GL_TEXTURE_WRAP_T, GL_REPEAT);
		}
		glBindTexture(_textureTarget, saveTextureName);
		
		//Update the texture immediately
		[self updateTextureForTime:0.0];
	}
	
	return self;
}

- (void) _updateTextureOnTargetContext
{
	//IMPORTANT: We use the macros provided by <OpenGL/CGLMacro.h> which provide better performances and allows us not to bother with making sure the current context is valid
	CGLContextObj					cgl_ctx = [_textureContext CGLContextObj];
	GLint							saveTextureName;
	
	//Save the currently bound texture
	glGetIntegerv((_textureTarget == GL_TEXTURE_RECTANGLE_EXT ? GL_TEXTURE_BINDING_RECTANGLE_EXT : GL_TEXTURE_BINDING_2D), &saveTextureName);
	
	//Bind the texture and update its contents
	glBindTexture(_textureTarget, _textureName);
	[_textureContext setTextureImageToPixelBuffer:_pixelBuffer colorBuffer:GL_FRONT];
	
	//Restore the previously bound texture
	glBindTexture(_textureTarget, saveTextureName);
}

- (BOOL) updateTextureForTime:(NSTimeInterval)time
{
	//IMPORTANT: We use the macros provided by <OpenGL/CGLMacro.h> which provide better performances and allows us not to bother with making sure the current context is valid
	CGLContextObj					cgl_ctx = [_pixelBufferContext CGLContextObj];
	BOOL							success;
	GLenum							error;
	NSOpenGLPixelBuffer*			pBuffer;
	
	//Make sure the virtual screen for the pBuffer and its rendering context match the target one
	if([_textureContext currentVirtualScreen] != [_pixelBufferContext currentVirtualScreen]) {
		pBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:_textureTarget textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:[_pixelBuffer pixelsWide] pixelsHigh:[_pixelBuffer pixelsHigh]];
		if(pBuffer) {
			[_pixelBufferContext clearDrawable];
			[_pixelBuffer release];
			_pixelBuffer = pBuffer;
			[_pixelBufferContext setPixelBuffer:_pixelBuffer cubeMapFace:0 mipMapLevel:0 currentVirtualScreen:[_textureContext currentVirtualScreen]];
		}
		else {
			NSLog(@"%: Failed recreating OpenGL pixel buffer");
			return NO;
		}
	}
	
	//Render a frame from the composition at the specified time in the pBuffer
	success = [_renderer renderAtTime:time arguments:nil];
	
	//IMPORTANT: Make sure all OpenGL rendering commands were sent to the pBuffer OpenGL context
	glFlushRenderAPPLE();
	
	//Update the texture in the target OpenGL context from the contents of the pBuffer
	[self _updateTextureOnTargetContext];
	
	//Check for errors
	if(error = glGetError())
	NSLog(@"%@: OpenGL error 0x%04X", error);
	
	return success;
}

- (GLenum) textureTarget
{
	return _textureTarget;
}

- (GLuint) textureName
{
	return _textureName;
}

- (unsigned) textureWidth
{
	return [_pixelBuffer pixelsWide];
}

- (unsigned) textureHeight
{
	return [_pixelBuffer pixelsHigh];
}

- (float) textureCoordSMin
{
	return 0.0;
}

- (float) textureCoordSMax
{
	return (_textureTarget == GL_TEXTURE_RECTANGLE_EXT ? (float)[_pixelBuffer pixelsWide] : 1.0);
}

- (float) textureCoordTMin
{
	return 0.0;
}

- (float) textureCoordTMax
{
	return (_textureTarget == GL_TEXTURE_RECTANGLE_EXT ? (float)[_pixelBuffer pixelsHigh] : 1.0);
}

- (void) dealloc 
{
	//IMPORTANT: We use the macros provided by <OpenGL/CGLMacro.h> which provide better performances and allows us not to bother with making sure the current context is valid
	CGLContextObj					cgl_ctx = [_textureContext CGLContextObj];
	
	//Destroy the texture on the target OpenGL context
	if(_textureName)
	glDeleteTextures(1, &_textureName);
	
	//Destroy the renderer
	[_renderer release];
	
	//Destroy the OpenGL context
	[_pixelBufferContext clearDrawable];
	[_pixelBufferContext release];
	
	//Destroy the OpenGL pixel buffer
	[_pixelBuffer release];
	
	//Release target OpenGL context
	[_textureContext release];
	
	[super dealloc];
}

@end
