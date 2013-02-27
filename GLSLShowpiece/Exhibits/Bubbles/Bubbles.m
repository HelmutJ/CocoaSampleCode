/*

File: Bubbles.m

Abstract: Bubbles Exhibit

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

#import "Bubbles.h"
#import "BlobbyCloudSupport.h"

@implementation Bubbles

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
      NSString *string, *vertex_string, *fragment_string;
		NSImage *image;
		NSBitmapImageRep *bitmapimagerep;
		NSRect rect;

      bundle = [NSBundle bundleForClass: [self class]];

		/* house texture */
		glGenTextures(1, &house_texture);
		string = [bundle pathForResource: @"House" ofType: @"jpg"];

		bitmapimagerep = LoadImage(string, 1);
		rect = NSMakeRect(0, 0, [bitmapimagerep pixelsWide], [bitmapimagerep pixelsHigh]);

		glBindTexture(GL_TEXTURE_2D, house_texture);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rect.size.width, rect.size.height, 0,
						 (([bitmapimagerep hasAlpha])?(GL_RGBA):(GL_RGB)), GL_UNSIGNED_BYTE, 
						 [bitmapimagerep bitmapData]);

		/* frameBuffer texture */
		glGenTextures(1, &frameBuffer_texture);
		glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		GLint viewport[4];
		glGetIntegerv(GL_VIEWPORT,viewport);
		CopyFramebufferToTexture(frameBuffer_texture);

		/* rainbow texture */
		glGenTextures(1, &rainbow_texture);
		string = [bundle pathForResource: @"rainbow" ofType: @"jpg"];
		image = [[[NSImage alloc] initWithContentsOfFile: string] autorelease];

		bitmapimagerep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
		rect = NSMakeRect(0, 0, [bitmapimagerep pixelsWide], [bitmapimagerep pixelsHigh]);

		glBindTexture(GL_TEXTURE_2D, rainbow_texture);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rect.size.width, rect.size.height, 0,
						 (([bitmapimagerep hasAlpha])?(GL_RGBA):(GL_RGB)), GL_UNSIGNED_BYTE, 
						 [bitmapimagerep bitmapData]);

		/* Load vertex and fragment shader */
      vertex_string   = [bundle pathForResource: @"Bubbles" ofType: @"vert"];
      vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
      fragment_string = [bundle pathForResource: @"Bubbles" ofType: @"frag"];
      fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load Bubbles");
			
		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform3fARB(glGetUniformLocationARB(program_object, "LightPos"), 0.0, 0.0, 4.0);
		glUniform3fARB(glGetUniformLocationARB(program_object, "BaseColor"), 1.0, 1.0, 1.0);
		glUniform1fARB(glGetUniformLocationARB(program_object, "MixRatio"), 1.0);
		glUniform1fARB(glGetUniformLocationARB(program_object, "FrameWidth"), viewport[2]);
		glUniform1fARB(glGetUniformLocationARB(program_object, "FrameHeight"), viewport[3]);
		glUniform1iARB(glGetUniformLocationARB(program_object, "EnvMap"), 0);
		glUniform1iARB(glGetUniformLocationARB(program_object, "RefractionMap"), 1);
		glUniform1iARB(glGetUniformLocationARB(program_object, "RainbowMap"), 2);
		glUniform1fARB(glGetUniformLocationARB(program_object, "RadiusOfInfluence"), 0.75);
		glUniform1iARB(glGetUniformLocationARB(program_object, "BailOut"), 20);

	}
	cloud = newCloud(program_object, (double)[NSDate timeIntervalSinceReferenceDate]);

}

- (void) dealloc
{
	[super dealloc];
	glDeleteTextures(1, &house_texture);
	glDeleteTextures(1, &frameBuffer_texture);
	glDeleteTextures(1, &rainbow_texture);
	deleteCloud(cloud);
}

- (NSString *) name
{
	return @"Bubbles";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
   string = [bundle pathForResource: @"Bubbles" ofType: @"rtf"];
	
	return string;
}

- (void) renderFrame
{
	[super renderFrame];
	
	glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glUseProgramObjectARB(program_object);
	
	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT,viewport);
	glUniform1fARB(glGetUniformLocationARB(program_object, "FrameWidth"), viewport[2]);
	glUniform1fARB(glGetUniformLocationARB(program_object, "FrameHeight"), viewport[3]);
	glUniform1fARB(glGetUniformLocationARB(program_object, "textureWidth"), NextHighestPowerOf2(viewport[2]));
	glUniform1fARB(glGetUniformLocationARB(program_object, "textureHeight"), NextHighestPowerOf2(viewport[3]));

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, house_texture);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
	CopyFramebufferToTexture(frameBuffer_texture);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, rainbow_texture);
	glActiveTexture(GL_TEXTURE0);

	updateDrawCloud(cloud, program_object, (double)[NSDate timeIntervalSinceReferenceDate]);

	glUseProgramObjectARB(NULL);

	glPopAttrib();
}

@end
