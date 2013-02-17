/*
     File: GLSquarePlugIn.m
 Abstract: GLSquartPlugin class.
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

#import "GLSquarePlugIn.h"

#define	kQCPlugIn_Name				@"OpenGL Square"
#define	kQCPlugIn_Description		@"Renders a colored square"

@implementation GLSquarePlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputX, inputY, inputColor, inputImage;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputX"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"X Position", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"inputY"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Y Position", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"inputColor"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Color", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"inputImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a consumer (it renders graphics using OpenGL) */
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	return kQCPlugInTimeModeNone;
}

@end

@implementation GLSquarePlugIn (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	CGLContextObj					cgl_ctx = [context CGLContextObj];
	id<QCPlugInInputImageSource>	image;
	GLuint							textureName;
	GLint							saveMode,
									saveName;
	GLboolean						saveEnabled;
	const CGFloat*					colorComponents;
	GLenum							error;
	
	if(cgl_ctx == NULL)
	return NO;
	
	/* Copy the image on the "inputImage" input port to a local variable */
	image = self.inputImage;
	
	/* Get a texture from the image in the context colorspace */
	if(image && [image lockTextureRepresentationWithColorSpace:([image shouldColorMatch] ? [context colorSpace] : [image imageColorSpace]) forBounds:[image imageBounds]])
	textureName = [image textureName];
	else
	textureName = 0;
	
	/* Save and set modelview matrix */
	glGetIntegerv(GL_MATRIX_MODE, &saveMode);
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glTranslatef(self.inputX, self.inputY, 0.0);
	
	/* Bind texture to unit */
	if(textureName)
	[image bindTextureRepresentationToCGLContext:cgl_ctx textureUnit:GL_TEXTURE0 normalizeCoordinates:YES];
		
	/* Get RGBA components from the color on the "inputColor" input port (the CGColorRef is guaranteed to be of type RGBA) */
	colorComponents = CGColorGetComponents(self.inputColor);
	
	/* Set current color (no need to save / restore as the current color is part of the GL_CURRENT_BIT) */
	glColor4f(colorComponents[0], colorComponents[1], colorComponents[2], colorComponents[3]);
	
	/* Render textured quad (we can use normalized texture coordinates independently of the texture target or the texture vertical flipping state thanks to -bindTextureRepresentationToCGLContext) */
	glBegin(GL_QUADS);
		glTexCoord2f(1.0, 1.0);
		glVertex3f(0.5, 0.5, 0);
		glTexCoord2f(0.0, 1.0);
		glVertex3f(-0.5, 0.5, 0);
		glTexCoord2f(0.0, 0.0);
		glVertex3f(-0.5, -0.5, 0);
		glTexCoord2f(1.0, 0.0);
		glVertex3f(0.5, -0.5, 0);
	glEnd();
	
	/* Unbind texture from unit */
	if(textureName)
	[image unbindTextureRepresentationFromCGLContext:cgl_ctx textureUnit:GL_TEXTURE0];
	
	/* Restore modelview matrix */
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	glMatrixMode(saveMode);
	
	/* Check for OpenGL errors */
	if(error = glGetError())
	[context logMessage:@"OpenGL error %04X", error];
	
	/* Release texture */
	if(textureName)
	[image unlockTextureRepresentation];
	
	return (error ? NO : YES);
}

@end
