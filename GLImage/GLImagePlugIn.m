/*
	    File: GLImagePlugIn.m
	Abstract: GLImagePlugin and GLImage classes.
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

#import "GLImagePlugIn.h"

#define	kQCPlugIn_Name				@"OpenGL Image"
#define	kQCPlugIn_Description		@"Produces an image of a given size containing a diagonal color gradient."

#if !__USE_PROVIDER__

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

#endif

/* Generates a texture containing a linear gradient - Requires FBO support */
static GLuint _CreateTexture(CGLContextObj cgl_ctx, NSUInteger pixelsWide, NSUInteger pixelsHigh, const CGFloat topColor[4], const CGFloat bottomColor[4], NSRect bounds)
{
	GLsizei							width = bounds.size.width,
									height = bounds.size.height;
	GLuint							name,
									frameBuffer;
	GLint							saveName,
									saveViewport[4],
									saveMode;
	GLenum							status;
	
	/* Create texture to render into */
	glGenTextures(1, &name);
	glGetIntegerv(GL_TEXTURE_BINDING_RECTANGLE_EXT, &saveName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, name);
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, saveName);
	
	/* Create temporary FBO to render in texture */
	glGenFramebuffersEXT(1, &frameBuffer);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffer);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_EXT, name, 0);
	status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
	if(status == GL_FRAMEBUFFER_COMPLETE_EXT) {
		/* Setup OpenGL states */
		glGetIntegerv(GL_VIEWPORT, saveViewport);
		glViewport(0, 0, width, height);
		glGetIntegerv(GL_MATRIX_MODE, &saveMode);
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		glOrtho(bounds.origin.x, bounds.origin.x + bounds.size.width, bounds.origin.y, bounds.origin.y + bounds.size.height, -1, 1);
		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
		glLoadIdentity();
		
		/* Render gradient quad */
		glBegin(GL_QUADS);
			/* Set current color (no need to save / restore as the current color is part of the GL_CURRENT_BIT) */
			glColor4f(topColor[0], topColor[1], topColor[2], topColor[3]);
			
			/* Draw top vertices */
			glVertex2f(pixelsWide, pixelsHigh);
			glVertex2f(0, pixelsHigh);
			
			/* Set current color (no need to save / restore as the current color is part of the GL_CURRENT_BIT) */
			glColor4f(bottomColor[0], bottomColor[1], bottomColor[2], bottomColor[3]);
			
			/* Draw bottom vertices */
			glVertex2f(0, 0);
			glVertex2f(pixelsWide, 0);
		glEnd();
		
		/* Restore OpenGL states */
		glMatrixMode(GL_MODELVIEW);
		glPopMatrix();
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
		glMatrixMode(saveMode);
		glViewport(saveViewport[0], saveViewport[1], saveViewport[2], saveViewport[3]);
	}
	else {
		glDeleteTextures(1, &name);
		name = 0;
	}
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	glDeleteFramebuffersEXT(1, &frameBuffer);
	
	/* Check for OpenGL errors */
	status = glGetError();
	if(status) {
		NSLog(@"OpenGL error %04X", status);
		glDeleteTextures(1, &name);
		name = 0;
	}
	
	return name;
}

@implementation GLImagePlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputWidth, inputHeight, inputStartColor, inputEndColor, outputGradientImage;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputWidth"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image Pixels Width", QCPortAttributeNameKey, [NSNumber numberWithUnsignedInteger:1024], QCPortAttributeMaximumValueKey, [NSNumber numberWithUnsignedInteger:256], QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"inputHeight"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image Pixels Height", QCPortAttributeNameKey, [NSNumber numberWithUnsignedInteger:1024], QCPortAttributeMaximumValueKey, [NSNumber numberWithUnsignedInteger:256], QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"inputStartColor"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Top Color", QCPortAttributeNameKey, [(id)CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0) autorelease], QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"inputEndColor"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Bottom Color", QCPortAttributeNameKey, [(id)CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0) autorelease], QCPortAttributeDefaultValueKey, nil];
	if([key isEqualToString:@"outputGradientImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Gradient Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a processor */
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	return kQCPlugInTimeModeNone;
}

@end

@implementation GLImagePlugIn (Execution)

#if __USE_PROVIDER__

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	GLImage*						gradientImage = nil;
	
	/* If we have valid dimensions, create a result image object */
	if((self.inputWidth > 0) && (self.inputHeight > 0)) {
		gradientImage = [[GLImage alloc] initWithColorSpace:[context colorSpace] pixelsWide:self.inputWidth pixelsHigh:self.inputHeight topColor:self.inputStartColor bottomColor:self.inputEndColor];
		if(gradientImage == nil)
		return NO;
		self.outputGradientImage = gradientImage;
		[gradientImage release];
	}
	/* otherwise, don't produce any result image */
	else
	self.outputGradientImage = nil;
	
	return YES;
}

#else

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	CGLContextObj					cgl_ctx = [context CGLContextObj];
	id								provider;
	GLuint							name;
	
	/* If we have valid dimensions, create a result image object */
	if((self.inputWidth > 0) && (self.inputHeight > 0)) {
		/* Create texture */
		name = _CreateTexture(cgl_ctx, self.inputWidth, self.inputHeight, CGColorGetComponents(self.inputStartColor), CGColorGetComponents(self.inputEndColor), NSMakeRect(0, 0, self.inputWidth, self.inputHeight));
		if(name == 0)
		return NO;
		
		/* Make sure to flush as we use FBOs and the passed OpenGL context may not have a surface attached */
		glFlushRenderAPPLE();
		
		/* Create output image provider */
#if __BIG_ENDIAN__
		provider = [context outputImageProviderFromTextureWithPixelFormat:QCPlugInPixelFormatARGB8 pixelsWide:self.inputWidth pixelsHigh:self.inputHeight name:name flipped:NO releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES];
#else
		provider = [context outputImageProviderFromTextureWithPixelFormat:QCPlugInPixelFormatBGRA8 pixelsWide:self.inputWidth pixelsHigh:self.inputHeight name:name flipped:NO releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES];
#endif
		if(provider == nil) {
			glDeleteTextures(1, &name);
			return NO;
		}
	}
	/* otherwise, don't produce any result image */
	else
	provider = nil;
	
	self.outputGradientImage = provider;
	
	return YES;
}

#endif

@end

#if __USE_PROVIDER__

@implementation GLImage

- (id) initWithColorSpace:(CGColorSpaceRef)colorSpace pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height topColor:(CGColorRef)topColor bottomColor:(CGColorRef)bottomColor
{
	const CGFloat*				components;
	
	/* Make sure we have valid parameters */
	if(!colorSpace || !width || !height || !topColor || !bottomColor) {
		[self release];
		return nil;
	}
	
	/* Keep the parameters around */
	if(self = [super init]) {
		_colorSpace = CGColorSpaceRetain(colorSpace);
		_width = width;
		_height = height;
		
		components = CGColorGetComponents(topColor); //This CGColorRef is guaranteed to be of type RGBA
		_topColor[0] = components[0];
		_topColor[1] = components[1];
		_topColor[2] = components[2];
		_topColor[3] = components[3];
		
		components = CGColorGetComponents(bottomColor); //This CGColorRef is guaranteed to be of type RGBA
		_bottomColor[0] = components[0];
		_bottomColor[1] = components[1];
		_bottomColor[2] = components[2];
		_bottomColor[3] = components[3];
	}
	
	return self;
}

- (void) dealloc
{
	CGColorSpaceRelease(_colorSpace);
	
	[super dealloc];
}

- (NSRect) imageBounds
{
	/* Compute bounds from width and height */
	return NSMakeRect(0, 0, _width, _height);
}

- (CGColorSpaceRef) imageColorSpace
{
	/* We render in our initial colorspace */
	return _colorSpace;
}

#if __USE_RENDERED_TEXTURES__

- (NSArray*) supportedRenderedTexturePixelFormats
{
#if __BIG_ENDIAN__
	return [NSArray arrayWithObject:QCPlugInPixelFormatARGB8];
#else
	return [NSArray arrayWithObject:QCPlugInPixelFormatBGRA8];
#endif
}

- (GLuint) copyRenderedTextureForCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(NSString*)format bounds:(NSRect)bounds isFlipped:(BOOL*)flipped
{
	return _CreateTexture(cgl_ctx, _width, _height, _topColor, _bottomColor, bounds);
}

- (void) releaseRenderedTexture:(GLuint)name forCGLContext:(CGLContextObj)cgl_ctx
{
	glDeleteTextures(1, &name);
}

#else

- (BOOL) canRenderWithCGLContext:(CGLContextObj)cgl_ctx
{
	/* This image provider can render using any OpenGL context */
	return YES;
}

- (BOOL) renderWithCGLContext:(CGLContextObj)cgl_ctx forBounds:(NSRect)bounds
{
	GLint							saveMode;
	
	/* Set projection matrix to the image bounds (the viewport is already set and the projection and modelview matrices are identity) */
	glGetIntegerv(GL_MATRIX_MODE, &saveMode);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glOrtho(bounds.origin.x, bounds.origin.x + bounds.size.width, bounds.origin.y, bounds.origin.y + bounds.size.height, -1, 1);
	
	/* Render gradient quad */
	glBegin(GL_QUADS);
		/* Set current color (no need to save / restore as the current color is part of the GL_CURRENT_BIT) */
		glColor4f(_topColor[0], _topColor[1], _topColor[2], _topColor[3]);
		
		/* Draw top vertices */
		glVertex2f(_width, _height);
		glVertex2f(0, _height);
		
		/* Set current color (no need to save / restore as the current color is part of the GL_CURRENT_BIT) */
		glColor4f(_bottomColor[0], _bottomColor[1], _bottomColor[2], _bottomColor[3]);
		
		/* Draw bottom vertices */
		glVertex2f(0, 0);
		glVertex2f(_width, 0);
	glEnd();
	
	/* Restore projection matrix */
	glPopMatrix();
	glMatrixMode(saveMode);
	
	return YES;
}

#endif

@end

#endif
