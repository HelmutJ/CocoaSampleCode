/*

File: Fur.m

Abstract: Fur Exhibit

Author: "OpenGL Shading Language" book.
		  (a.k.a "the orange book")

© Copyright 2004 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*/

#import "Fur.h"

@implementation Fur

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
		NSBitmapImageRep *bitmapimagerep;
		NSRect rect;

		bundle = [NSBundle bundleForClass: [self class]];

		/* Create noise texture */
		glGenTextures(1, &noiseTexture);
		glBindTexture(GL_TEXTURE_2D, noiseTexture);
		string = [bundle pathForResource: @"Noise512x512xRGB" ofType: @"png"];

		bitmapimagerep = LoadImage(string, 1);
		rect = NSMakeRect(0, 0, [bitmapimagerep pixelsWide], [bitmapimagerep pixelsHigh]);

		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rect.size.width, rect.size.height, 0,
						 (([bitmapimagerep hasAlpha])?(GL_RGBA):(GL_RGB)), GL_UNSIGNED_BYTE, 
						 [bitmapimagerep bitmapData]);
		
		/* Create color Texture */
		glGenTextures(1, &colorTexture);
		glBindTexture(GL_TEXTURE_2D, colorTexture);
		string = [bundle pathForResource: @"Leopard" ofType: @"jpg"];
		
		bitmapimagerep = LoadImage(string, 1);
		rect = NSMakeRect(0, 0, [bitmapimagerep pixelsWide], [bitmapimagerep pixelsHigh]);

		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rect.size.width, rect.size.height, 0,
						 (([bitmapimagerep hasAlpha])?(GL_RGBA):(GL_RGB)), GL_UNSIGNED_BYTE, 
						 [bitmapimagerep bitmapData]);
		
		/* Load vertex and fragment shader */
		vertex_string   = [bundle pathForResource: @"Fur" ofType: @"vert"];
		vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
		fragment_string = [bundle pathForResource: @"Fur" ofType: @"frag"];
		fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load Fur");

		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform1fARB(glGetUniformLocationARB(program_object, "ambient"), 0.2);
		glUniform3fARB(glGetUniformLocationARB(program_object, "lightPosition"), 0.0, 0.0, 5.0);
		glUniform1fARB(glGetUniformLocationARB(program_object, "spacing"), 1);
		glUniform1iARB(glGetUniformLocationARB(program_object, "noiseTexture"), 0);
		glUniform1iARB(glGetUniformLocationARB(program_object, "colorTexture"), 1);
		
		/* Create a display list for the teapot (especially important with the number of
		teapots per frame in this shell-based approach) */
		teapotList = glGenLists(1);
		glNewList(teapotList, GL_COMPILE);
		teapot(8, 0.5, GL_FILL);
		glEndList();
	}
}

- (void) dealloc
{
	glDeleteTextures(1, &noiseTexture);
	glDeleteTextures(1, &colorTexture);
	glDeleteLists(teapotList, 1);
	[super dealloc];
}

- (NSString *) name
{
	return @"Fur";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
	string = [bundle pathForResource: @"Fur" ofType: @"rtf"];
	
	return string;
}

#define SHELLS 10
#define FUR_HEIGHT .25
#define SHELL_TRANSPARENCY .3

- (void) renderFrame
{
	int i;
	
	[super renderFrame];
	
	glPushAttrib(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_CURRENT_BIT);
	
	glDisable(GL_TEXTURE_3D);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	/* Draw the skin before the fur */
	glColor3f(0.9, 0.65, 0.4);
	glEnable(GL_COLOR_MATERIAL);
	glCallList(teapotList);
	glUseProgramObjectARB(program_object);
	glColor3f(1.0, 1.0, 1.0);
	glDisable(GL_COLOR_MATERIAL);
	
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, noiseTexture);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, colorTexture);
	glActiveTexture(GL_TEXTURE0);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glUniform1fARB(glGetUniformLocationARB(program_object, "transparency"), 1);
	glUniform1fARB(glGetUniformLocationARB(program_object, "furHeight"), 0);
	
	glUniform1fARB(glGetUniformLocationARB(program_object, "transparency"), SHELL_TRANSPARENCY);
	glEnable(GL_CULL_FACE);
	for (i = 1; i < SHELLS; i++)
	{
		glUniform1fARB(glGetUniformLocationARB(program_object, "furHeight"), (float)i / (SHELLS / FUR_HEIGHT));
		glCallList(teapotList);
	}
	
	glUseProgramObjectARB(NULL);
	
	glPopAttrib();
}

- (BOOL) reflect
{
	return NO;
}

@end
