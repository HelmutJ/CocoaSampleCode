/*

File: HeatHaze.m

Abstract: HeatHaze Exhibit

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

#import "HeatHaze.h"

@implementation HeatHaze

- (id) init
{
	[super init];
	
	return self;
}

- (void) initLazy
{
	[super initLazy];
	
	Offset.current[0] = 0;
	Offset.min[0] = 0;
	Offset.max[0] = 2*M_PI;
	Offset.delta[0] = 0.01;

	/* Setup GLSL */
   {
      NSBundle *bundle;
      NSString *vertex_string, *fragment_string;

      bundle = [NSBundle bundleForClass: [self class]];

		/* frameBuffer texture */
		glGenTextures(1, &frameBuffer_texture);
		glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		GLint viewport[4];
		glGetIntegerv(GL_VIEWPORT,viewport);
		CopyFramebufferToTexture(frameBuffer_texture);

		/* Load vertex and fragment shader */
		vertex_string   = [bundle pathForResource: @"HeatHaze" ofType: @"vert"];
		vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
		fragment_string = [bundle pathForResource: @"HeatHaze" ofType: @"frag"];
		fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load HeatHaze");
			
		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform1iARB(glGetUniformLocationARB(program_object, "FrameBuffer"), 0);
		glUniform1fARB(glGetUniformLocationARB(program_object, "FrameWidth"), viewport[2]);
		glUniform1fARB(glGetUniformLocationARB(program_object, "FrameHeight"), viewport[3]);
		glUniform1fARB(glGetUniformLocationARB(program_object, "Frequency"), 20.0);
		glUniform1iARB(glGetUniformLocationARB(program_object, "Speed"), 10);
		glUniform1fARB(glGetUniformLocationARB(program_object, "Fade"), 0.9);
		glUniform1fvARB(glGetUniformLocationARB(program_object, "Offset"), 1, PARAMETER_CURRENT(Offset));

	}

}

- (void) dealloc
{
	[super dealloc];
	glDeleteTextures(1, &frameBuffer_texture);
}

- (NSString *) name
{
	return @"HeatHaze";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
   string = [bundle pathForResource: @"HeatHaze" ofType: @"rtf"];
	
	return string;
}

- (void) renderFrame
{
	[super renderFrame];
	
	glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glDisable(GL_TEXTURE_3D);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_LIGHT1);
	glColor4f(1, 1, 1, 1);
	teapot(8, 0.4, GL_FILL);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glUseProgramObjectARB(program_object);
	
	PARAMETER_ANIMATE(Offset);
	glUniform1fvARB(glGetUniformLocationARB(program_object, "Offset"), 1, PARAMETER_CURRENT(Offset));

	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT,viewport);
	glUniform1fARB(glGetUniformLocationARB(program_object, "FrameWidth"), viewport[2]);
	glUniform1fARB(glGetUniformLocationARB(program_object, "FrameHeight"), viewport[3]);
	glUniform1fARB(glGetUniformLocationARB(program_object, "textureWidth"), NextHighestPowerOf2(viewport[2]));
	glUniform1fARB(glGetUniformLocationARB(program_object, "textureHeight"), NextHighestPowerOf2(viewport[3]));

	CopyFramebufferToTexture(frameBuffer_texture);

	glRotatef(90, 1.0, 0.0, 0.0);
	glDepthMask(GL_FALSE);
	gluSphere(quadric, 1, 16, 16);
	
	glUseProgramObjectARB(NULL);
	
	glPopAttrib();
}

@end
