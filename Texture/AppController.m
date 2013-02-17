/*
	    File: AppController.m
	Abstract: Controller class.
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

#import "AppController.h"

#define kRenderFPS 60.0

@implementation AppController

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
	NSOpenGLPixelFormatAttribute	attributes[] = {NSOpenGLPFAAccelerated, NSOpenGLPFANoRecovery, NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, 24, 0};
	GLint							swapInterval = 1;
	
	//Create the OpenGL context used to render the animation and attach it to the rendering view
	_glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
	_glContext = [[NSOpenGLContext alloc] initWithFormat:_glPixelFormat shareContext:nil];
	[_glContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
	[_glContext setView:renderView];
	
	//Prompt the user for a Quartz Composer composition immediately
	[self openComposition:nil];
	
	//We need to know when the rendering view frame changes so that we can update the OpenGL context
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRenderView:) name:NSViewGlobalFrameDidChangeNotification object:renderView];
	
	//Create a timer which will regularly call our rendering method
	_renderTimer = [[NSTimer timerWithTimeInterval:(1.0 / (NSTimeInterval)kRenderFPS) target:self selector:@selector(_renderGLScene:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:_renderTimer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:_renderTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:_renderTimer forMode:NSEventTrackingRunLoopMode];
	_startTime = -1.0;
}

- (IBAction) openComposition:(id)sender
{
	NSOpenPanel*					openPanel = [NSOpenPanel openPanel];
	
	//Prompt the user for a Quartz Composer composition file
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	if([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"qtz"]] == NSOKButton) {
		//Destroy the current pBuffer renderer and create a new one
		[_pBufferRenderer release];
		_pBufferRenderer = [[PBufferRenderer alloc] initWithCompositionPath:[openPanel filename] textureTarget:GL_TEXTURE_2D textureWidth:512 textureHeight:512 openGLContext:_glContext];
	}
}

- (void) _renderGLScene:(NSTimer*)timer
{
	CGLContextObj			cgl_ctx = [_glContext CGLContextObj]; //By using CGLMacro.h there's no need to set the current OpenGL context
	NSTimeInterval			time = [NSDate timeIntervalSinceReferenceDate];
	GLint					viewport[4];
	
	//Compute the local time
	if(_startTime < 0.0)
	_startTime = time;
	time = time - _startTime;
	
	//Clear background
	glClearColor(0.25, 0.25, 0.25, 0.25);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//Save & configure projection matrix
	glMatrixMode(GL_PROJECTION_MATRIX);
	glGetIntegerv(GL_VIEWPORT, viewport);
	glPushMatrix();
	glOrtho(-1.0, 1.0, -1.0 * (float)viewport[3] / (float)viewport[2], 1.0 * (float)viewport[3] / (float)viewport[2], -1.0, 1.0);
	
	//Save & configure modelview matrix (make it rotate with time)
	glMatrixMode(GL_MODELVIEW_MATRIX);
	glPushMatrix();
	glRotatef(time * 360.0 / 5, 0.0, 0.0, 1.0);
	
	//Configure texturing
	if(_pBufferRenderer) {
		[_pBufferRenderer updateTextureForTime:time];
		glEnable([_pBufferRenderer textureTarget]);
		glBindTexture([_pBufferRenderer textureTarget], [_pBufferRenderer textureName]);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	}
	else
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	//Draw textured quad
	glBegin(GL_QUADS);
		glTexCoord2f([_pBufferRenderer textureCoordSMin], [_pBufferRenderer textureCoordTMin]);
		glVertex3f(-0.5, -0.5, 0.0);
		glTexCoord2f([_pBufferRenderer textureCoordSMax], [_pBufferRenderer textureCoordTMin]);
		glVertex3f(0.5, -0.5, 0.0);
		glTexCoord2f([_pBufferRenderer textureCoordSMax], [_pBufferRenderer textureCoordTMax]);
		glVertex3f(0.5, 0.5, 0.0);
		glTexCoord2f([_pBufferRenderer textureCoordSMin], [_pBufferRenderer textureCoordTMax]);
		glVertex3f(-0.5, 0.5, 0.0);
	glEnd();
	
	//Restore texturing settings
	if(_pBufferRenderer)
	glDisable([_pBufferRenderer textureTarget]);
	
	//Restore modelview and projection matrices
	glPopMatrix();
	glMatrixMode(GL_PROJECTION_MATRIX);
	glPopMatrix();
	
	//Display new frame
	[_glContext flushBuffer];
}

- (void) updateRenderView:(NSNotification*)notification
{
	CGLContextObj			cgl_ctx = [_glContext CGLContextObj]; //By using CGLMacro.h there's no need to set the current OpenGL context
	NSRect					frame = [renderView frame];
	
	//Notify the OpenGL context its rendering view has changed
	[_glContext update];
	
	//Update the OpenGL viewport
	glViewport(0, 0, frame.size.width, frame.size.height);
	
	//Render OpenGL scene immediately
	[self _renderGLScene:nil];
}

- (BOOL) windowShouldClose:(id)sender
{
	//Quits the app when the window is closed
	[NSApp terminate:self];
	
	return YES;
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
	//Stop the timer
	[_renderTimer invalidate];
	
	//Stop observing the rendering view
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:renderView];
}

- (void) dealloc
{
	//Release our objects
	[_renderTimer release];
	[_pBufferRenderer release];
	[_glContext release];
	[_glPixelFormat release];
	
	[super dealloc];
}

@end
