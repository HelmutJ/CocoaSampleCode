/*

File: RayTracer.m

Abstract: RayTracer Exhibit

Author: Nick Burns

© Copyright 2006 Apple Computer, Inc. All rights reserved.

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

#import "RayTracer.h"

@implementation RayTracer

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

      bundle = [NSBundle bundleForClass: [self class]];

		/* Load vertex and fragment shader */
      fragment_string = [bundle pathForResource: @"RayTracer" ofType: @"frag"];
      fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: nil fragmentShader: fragment_string])
			NSLog(@"Failed to load RayTracer");
			
		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform2fARB(glGetUniformLocationARB(program_object, "frame"), 255.0, 255.0);
		glUniform3fARB(glGetUniformLocationARB(program_object, "lightPosition"), 10.0, 10.0, 8.0);
		glUniform3fARB(glGetUniformLocationARB(program_object, "lightColor"), 0.8, 0.8, 0.7);
		glUniform1fARB(glGetUniformLocationARB(program_object, "radius"), 0.25);
		glUniform3fARB(glGetUniformLocationARB(program_object, "sphereColor"), 0.3, 0.3, 0.8);
		glUniform3fARB(glGetUniformLocationARB(program_object, "spherePosition"), 0.0, 0.1, 0.0);
	}

}

- (void) dealloc
{
	[super dealloc];
}

- (NSString *) name
{
	return @"RayTracer";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
   string = [bundle pathForResource: @"RayTracer" ofType: @"rtf"];
	
	return string;
}

- (void) renderFrame
{
	[super renderFrame];
	
	glUseProgramObjectARB(program_object);

	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT,viewport);
	glUniform2fARB(glGetUniformLocationARB(program_object, "frame"), viewport[2], viewport[3]);

	glBegin(GL_QUADS);
	glNormal3f(0.0, 0.0, 1.0);
	glVertex2f(-0.5, -0.5);
	glVertex2f( 0.5, -0.5);
	glVertex2f( 0.5,  0.5);
	glVertex2f(-0.5,  0.5);
	glEnd();
	
	glUseProgramObjectARB(NULL);
	
	glPushAttrib(GL_COLOR_BUFFER_BIT | GL_ENABLE_BIT | GL_POLYGON_BIT);
	
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glColor3f(1, 1, 1);
	glBegin(GL_LINE_LOOP);
	glVertex2f(-0.52, -0.52);
	glVertex2f( 0.52, -0.52);
	glVertex2f( 0.52,  0.52);
	glVertex2f(-0.52,  0.52);
	glEnd();

	glPopAttrib();
}

@end
