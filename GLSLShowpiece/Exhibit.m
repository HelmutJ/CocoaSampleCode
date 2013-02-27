/*

File: Exhibit.m

Abstract: Exhibit base class.  Subclass this to create
			 your own additional exhibits
			 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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

  Copyright (c) 2004-2006 Apple Computer, Inc., All rights reserved.

*/

#import "Exhibit.h"

@implementation Exhibit

- (id) init
{
	[super init];
	gpuProcessingInit = NO;
	
	return self;
}

- (void) initLazy
{
	/* Subclass should put initialisation code that can be performaned
	   lazily (on first frame render) here */
	initialised = TRUE;
	
	/* Create a GLU quadric, used for rendering certain geometry */
	quadric = gluNewQuadric();
	gluQuadricDrawStyle(quadric, GLU_FILL);
	gluQuadricNormals(quadric, GL_SMOOTH);
	gluQuadricTexture(quadric, GL_TRUE);

}

- (void) dealloc
{
	/* Free the GLU quadric */
	if (quadric)
		gluDeleteQuadric(quadric);

	[super dealloc];
}

- (NSString *) name
{
	return @"Unnamed Exhibit";
}

- (NSString *) descriptionFilename
{
	return NULL;
}

- (unsigned int) loadVertexShader: (NSString *) vertexString fragmentShader: (NSString *) fragmentString
{
	const GLcharARB *vertex_string, *fragment_string;
	GLint vertex_compiled, fragment_compiled;
	GLint linked;
	
	/* Delete any existing program object */
	if (program_object) {
		glDeleteObjectARB(program_object);
		program_object = NULL;
	}
	
	/* Load and compile both shaders */
	if (vertexString) {
		vertex_shader   = glCreateShaderObjectARB(GL_VERTEX_SHADER_ARB);
		vertex_string   = (GLcharARB *) [vertexString cString];
		glShaderSourceARB(vertex_shader, 1, &vertex_string, NULL);
		glCompileShaderARB(vertex_shader);
		glGetObjectParameterivARB(vertex_shader, GL_OBJECT_COMPILE_STATUS_ARB, &vertex_compiled);
		/* TODO - Get info log */
	} else {
		vertex_shader   = NULL;
		vertex_compiled = 1;
	}
		
	if (fragmentString) {
		fragment_shader   = glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
		fragment_string   = [fragmentString cString];
		glShaderSourceARB(fragment_shader, 1, &fragment_string, NULL);
		glCompileShaderARB(fragment_shader);
		glGetObjectParameterivARB(fragment_shader, GL_OBJECT_COMPILE_STATUS_ARB, &fragment_compiled);
		/* TODO - Get info log */
	} else {
		fragment_shader   = NULL;
		fragment_compiled = 1;
	}
	
	/* Ensure both shaders compiled */
	if (!vertex_compiled || !fragment_compiled) {
		if (vertex_shader) {
			glDeleteObjectARB(vertex_shader);
			vertex_shader   = NULL;
		}
		if (fragment_shader) {
			glDeleteObjectARB(fragment_shader);
			fragment_shader = NULL;
		}
		return 1;
	}
		
	/* Create a program object and link both shaders */
	program_object = glCreateProgramObjectARB();
	if (vertex_shader != NULL)
	{
		glAttachObjectARB(program_object, vertex_shader);
		glDeleteObjectARB(vertex_shader);   /* Release */
	}
	if (fragment_shader != NULL)
	{
		glAttachObjectARB(program_object, fragment_shader);
		glDeleteObjectARB(fragment_shader); /* Release */
	}
	glLinkProgramARB(program_object);
	glGetObjectParameterivARB(program_object, GL_OBJECT_LINK_STATUS_ARB, &linked);
	/* TODO - Get info log */
	
	if (!linked) {
		glDeleteObjectARB(program_object);
		program_object = NULL;
		return 1;
	}
	
	return 0;
}

- (void) renderFrame
{
	if (!initialised)
		[self initLazy];
}

- (BOOL) reflect
{
	if(!gpuProcessingInit)
	{
		/* Check if this will fall back to software rasterization or
		   software vertex processing and don't reflect if it is. */

		GLint fragmentGPUProcessing, vertexGPUProcessing;
		gpuProcessingInit = YES;

		glPushAttrib(GL_VIEWPORT_BIT);
		glViewport(0,0,0,0);
		glPushMatrix();
		[self renderFrame];
		glPopMatrix();
		CGLGetParameter(CGLGetCurrentContext(), kCGLCPGPUFragmentProcessing, &fragmentGPUProcessing);
		CGLGetParameter(CGLGetCurrentContext(), kCGLCPGPUVertexProcessing, &vertexGPUProcessing);
		gpuProcessing = (fragmentGPUProcessing && vertexGPUProcessing) ? YES : NO;
		glPopAttrib();
	}

	return gpuProcessing;
}

@end


// Utility Functions

int NextHighestPowerOf2(int n)
{
	n--;
	n |= n >> 1; 
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n++;
	return n;
}

void CopyFramebufferToTexture(GLuint texture)
{
	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	glBindTexture(GL_TEXTURE_2D, texture);
	glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, viewport[0], viewport[1], NextHighestPowerOf2(viewport[2]), NextHighestPowerOf2(viewport[3]), 0);
}

NSBitmapImageRep *LoadImage(NSString *path, int shouldFlipVertical)
{
	NSBitmapImageRep *bitmapimagerep;
	NSImage *image;
	image = [[[NSImage alloc] initWithContentsOfFile: path] autorelease];
	bitmapimagerep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	
	if (shouldFlipVertical)
	{
		int bytesPerRow, lowRow, highRow;
		unsigned char *pixelData, *swapRow;
		
		bytesPerRow = [bitmapimagerep bytesPerRow];
		pixelData = [bitmapimagerep bitmapData];

		swapRow = (unsigned char *)malloc(bytesPerRow);
		for (lowRow = 0, highRow = [bitmapimagerep pixelsHigh]-1; lowRow < highRow; lowRow++, highRow--)
		{
			memcpy(swapRow, &pixelData[lowRow*bytesPerRow], bytesPerRow);
			memcpy(&pixelData[lowRow*bytesPerRow], &pixelData[highRow*bytesPerRow], bytesPerRow);
			memcpy(&pixelData[highRow*bytesPerRow], swapRow, bytesPerRow);
		}
		free(swapRow);
	}

	return bitmapimagerep;
}
