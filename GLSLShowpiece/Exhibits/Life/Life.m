/*

File: Life.m

Abstract: Life Exhibit

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

#import "Life.h"

@implementation Life

- (id) init
{
	[super init];
	
	return self;
}

- (void) initLazy
{
	[super initLazy];

	/* Setup GLSL */
   {
      NSBundle *bundle;
      NSString *fragment_string;
      NSString *vertex_string;

      bundle = [NSBundle bundleForClass: [self class]];

		/* frameBuffer texture */
		glGenTextures(1, &currentGeneration);
		glBindTexture(GL_TEXTURE_2D, currentGeneration);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, lifeTextureWidth, lifeTextureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);

		/* Load vertex and fragment shader */
		vertex_string = [bundle pathForResource: @"Life" ofType: @"vert"];
		vertex_string = [NSString stringWithContentsOfFile: vertex_string];
		fragment_string = [bundle pathForResource: @"Life" ofType: @"frag"];
		fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load Life");
			
		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform1iARB(glGetUniformLocationARB(program_object, "currentGeneration"), 0);
		
		lifeTextureWidth = 0;
		lifeTextureHeight = 0;
		[self updateSimulationDimensions];
	}

}

- (void) dealloc
{
	[super dealloc];
	glDeleteTextures(1, &currentGeneration);
}

- (NSString *) name
{
	return @"Life";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
   string = [bundle pathForResource: @"Life" ofType: @"rtf"];
	
	return string;
}

- (void) updateSimulationDimensions
{
	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);

	//resize the life texture if need-be
	int newLifeTextureWidth;
	int newLifeTextureHeight;
	newLifeTextureWidth = NextHighestPowerOf2(viewport[2]);
	newLifeTextureHeight = NextHighestPowerOf2(viewport[3]);
	if (newLifeTextureWidth != lifeTextureWidth || newLifeTextureHeight != lifeTextureHeight)
	{
		CopyFramebufferToTexture(currentGeneration);
		lifeTextureWidth = newLifeTextureWidth;
		lifeTextureHeight = newLifeTextureHeight;

		//tell the GLSL program how big the life texture is
		glUniform4fARB(glGetUniformLocationARB(program_object, "pixelDimension"), 1.0/lifeTextureWidth, -1.0/lifeTextureWidth, 1.0/lifeTextureHeight, -1.0/lifeTextureHeight);
	}
}

- (void) renderFrame
{
	[super renderFrame];

	glPushAttrib(GL_TRANSFORM_BIT | GL_TEXTURE_BIT | GL_ENABLE_BIT);

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	//bind the current life generation
	glBindTexture(GL_TEXTURE_2D, currentGeneration);
	
	//set up our matrices
	{
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		
		GLint viewport[4];
		glGetIntegerv(GL_VIEWPORT, viewport);
		glOrtho(0, viewport[2], 0, viewport[3], 1, -1);
		
		{
			glMatrixMode(GL_MODELVIEW);
			glPushMatrix();
			glLoadIdentity();
			
			glUseProgramObjectARB(program_object);

			//compute the part of the power-of-two life texture we care about
			double useableTextureS, useableTextureT;
			useableTextureS = (double)viewport[2] / (double)lifeTextureWidth;
			useableTextureT = (double)viewport[3] / (double)lifeTextureHeight;
			
			//render a quad the size of the viewport which will end up being the next life generation!
			glBegin(GL_TRIANGLES);
			glTexCoord2d(0, 0);
			glVertex2d(0, 0);
			glTexCoord2d(useableTextureS, 0);
			glVertex2d(viewport[2], 0);
			glTexCoord2d(useableTextureS, useableTextureT);
			glVertex2d(viewport[2], viewport[3]);

			glTexCoord2d(useableTextureS, useableTextureT);
			glVertex2d(viewport[2], viewport[3]);
			glTexCoord2d(0, useableTextureT);
			glVertex2d(0, viewport[3]);
			glTexCoord2d(0, 0);
			glVertex2d(0, 0);
			glEnd();
			
			[self updateSimulationDimensions];

			//copy this next generation back to the currentGeneration texture
			CopyFramebufferToTexture(currentGeneration);

			glUseProgramObjectARB(NULL);

			//restore matrices
			glMatrixMode(GL_MODELVIEW);
			glPopMatrix();
		}
		
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
	}

	glPopAttrib();
}

- (BOOL) reflect
{
	/* Life can not be reflected (upon) */
	return NO;
}

@end
