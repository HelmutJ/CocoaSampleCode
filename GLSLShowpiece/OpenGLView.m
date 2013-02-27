/*

File: OpenGLView.m

Abstract: Main rendering class
			 
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

#import "OpenGLView.h"

@implementation OpenGLView

- (void) heartbeat
{
	if(![[NSApplication sharedApplication] isHidden])
		[self setNeedsDisplay:YES];
}

- (id) initWithFrame: (NSRect) theFrame
{
	NSOpenGLPixelFormatAttribute attribs [] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAStencilSize, 8,
		0
   };
   NSOpenGLPixelFormat *fmt;
   
   {
	/* Create a pre-flight context to check for GLSL hardware support */
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: attribs];
	NSOpenGLContext *preflight = [[NSOpenGLContext alloc] initWithFormat:fmt shareContext:nil];
	[preflight makeCurrentContext];
	[fmt release];

	const GLubyte* extensions = glGetString(GL_EXTENSIONS);
	if ((GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_shader_objects",       extensions)) ||
		(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_shading_language_100", extensions)) ||
		(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_vertex_shader",        extensions)) ||
		(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_fragment_shader",      extensions)))
		{
			/* Force software rendering, so fragment shaders will execute */
			attribs [3] = NSOpenGLPFARendererID;
			attribs [4] = kCGLRendererGenericFloatID;
		}
	[preflight release];
   }
	
   /* Create a GL Context to use - i.e. init the superclass */
   fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: attribs];
   [super initWithFrame: theFrame pixelFormat: fmt];
   [[super openGLContext] makeCurrentContext];
   [fmt release];
   	
	/* Set up the projection */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.3, 0.3, 0.0, 0.6, 1.0, 8.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0, 0.0, -2.0);

#ifdef USE_BLENDING
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
#endif

	/* Turn on depth test */
	glEnable(GL_DEPTH_TEST);
	
	[self setFrameSize: theFrame.size];

	/* Create an update timer */
	timer = [NSTimer scheduledTimerWithTimeInterval: (1.0f/150.0f) target: self
                    selector: @selector(heartbeat) userInfo: nil
                    repeats: YES];
	[timer retain];

	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSEventTrackingRunLoopMode];

	/* Create the podium */
	podium = [[Podium alloc] init];
	
	lastFrameReferenceTime = -1;
	leftMouseIsDown = NO;
	rightMouseIsDown = NO;
	
	angle = 0;
	pitch = 25;
	zoom = 1;
	
	{
		/* Sync to VBL to avoid tearing. */
		long VBL = 1;
		[[self openGLContext] setValues:&VBL forParameter:NSOpenGLCPSwapInterval];
	}
	
	return self;
}

- (void) dealloc
{
	/* Release the update timer */
	if (timer) {
		[timer invalidate];
		[timer release];
	}
	
	/* Release the podium */
	[podium release];
	
	/* Dealloc the superclass */
	[super dealloc];
}

- (void)renewGState
{
	/* Overload this function to ensure the NSOpenGLView doesn't
	   flicker when you resize it.                               */
	NSWindow *window;
	[super renewGState];
	window = [self window];

	/* Only available in 10.4 and later, so check that it exists */
	if([window respondsToSelector:@selector(disableScreenUpdatesUntilFlush)])
		[window disableScreenUpdatesUntilFlush];
}

#define VIEW_ROTATION_DEGREES_PER_SECOND 20.0
#define EXHIBIT_HEIGHT_MOVEMENT_UNITS_PER_SECOND 0.5

- (void) drawRect: (NSRect) theRect
{
	NSRect bounds = [self bounds];
	double now, deltaTime;

	float aspect = NSWidth(bounds) / NSHeight(bounds);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	{
		float lr, bt;
		
		if (aspect > 1)
		{
			lr = 0.3 * aspect * zoom;
			bt = 0.3 * zoom;
		}
		else
		{
			lr = 0.3 * zoom;
			bt = 0.3 / aspect * zoom;
		}
		
		glFrustum(-lr, lr, -bt, bt, 1.0, 8.0);
	}
	glMatrixMode(GL_MODELVIEW);

	glViewport(0, 0, NSWidth(bounds), NSHeight(bounds));
	
	now = (double)[NSDate timeIntervalSinceReferenceDate];
	
	if (lastFrameReferenceTime < 0)
	{
		deltaTime = 0;
	}
	else
	{
		deltaTime = now - lastFrameReferenceTime;
	}
	
	lastFrameReferenceTime = now;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	glPushMatrix();
	
	/* Constant rotation of the subject */
	if (!leftMouseIsDown && !rightMouseIsDown)
	{
		angle += VIEW_ROTATION_DEGREES_PER_SECOND * deltaTime;
		if (angle >= 360.0f)
			angle -= 360.0f;
	}
	
	if (pitch < -45.f)
	{
		pitch = -45.f;
	}
	else if (pitch > 90.f)
	{
		pitch = 90.f;
	}

	glRotatef(pitch, 1.0f, 0.0f, 0.0f);
	glTranslatef(0.0f, -0.5f, -.15f);
	glRotatef(angle, 0.0f, 1.0f, 0.0f);

	/* Draw the exhibit */
	if (target_exhibit) {
		exhibit_height -= EXHIBIT_HEIGHT_MOVEMENT_UNITS_PER_SECOND * deltaTime;
		if (exhibit_height < 0.0f) {
			exhibit_height = 0.0f;
			current_exhibit = target_exhibit;
			target_exhibit  = NULL;
		}
	} else {
		exhibit_height += EXHIBIT_HEIGHT_MOVEMENT_UNITS_PER_SECOND * deltaTime;
		if (exhibit_height > 0.5f)
			exhibit_height = 0.5f;
	}

	/* Draw only the top of the podium with
	   the stencil being set as well. */
	[podium drawReflectionStencil];

	if(!(exhibit_height < 0.4f) && [current_exhibit reflect])
	{
		/* Draw the reflection only where the podium top is.
		   A clipping plane can also be used here, but be
		   sure to set the gl_ClipVertex in your shaders when
		   doing so. */

		glPushAttrib(GL_STENCIL_BUFFER_BIT | GL_POLYGON_BIT);
		glFrontFace(GL_CW);
		glEnable(GL_STENCIL_TEST);
		glStencilFunc(GL_EQUAL, 1, 0xffffffff);
		glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
		glPushMatrix();
		glScalef(1.0f, -1.0f, 1.0f);
		glTranslatef(0.0f, exhibit_height - 0.5f, 0.0f);
		glScalef(0.4f, 0.4f, 0.4f);
		if (current_exhibit)
			[current_exhibit renderFrame];
		glPopMatrix();
		glPopAttrib();
	}

	/* Draw the granite podium */
	
	[podium renderFrame:((exhibit_height - 0.4f) / 0.1f)];

	glPushMatrix();
	glTranslatef(0.0f, exhibit_height, 0.0f);
	glScalef(0.4f, 0.4f, 0.4f);
	if (current_exhibit)
		[current_exhibit renderFrame];
	glPopMatrix();
	
	glPopMatrix();

	[[self openGLContext] flushBuffer];
}

- (void) setExhibit: (Exhibit *) new_exhibit
{
	target_exhibit  = new_exhibit;
}

- (void)mouseDown:(NSEvent *)event
{
	lastMousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	leftMouseIsDown = YES;
}

- (void)rightMouseDown:(NSEvent *)event
{
	lastMousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	rightMouseIsDown = YES;
}

- (void)mouseUp:(NSEvent *)event
{
	leftMouseIsDown = NO;
}

- (void)rightMouseUp:(NSEvent *)event
{
	rightMouseIsDown = NO;
}

- (void)mouseDragged:(NSEvent *)event
{
	if ([event modifierFlags] & 1)
	{
		[self rightMouseDragged:event];
	}
	else
	{
		NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
		
		pitch += lastMousePoint.y - mouse.y;
		angle -= lastMousePoint.x - mouse.x;

		lastMousePoint = mouse;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)rightMouseDragged:(NSEvent *)event
{
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	zoom += .01f * (lastMousePoint.y - mouse.y);
	if (zoom < .05f)
	{
		zoom = .05f;
	}
	else if (zoom > 2.0f)
	{
		zoom = 2.0f;
	}

	lastMousePoint = mouse;

	[self setNeedsDisplay:YES];
}

@end
