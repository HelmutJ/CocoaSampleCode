/*
     File: MyOpenGLView.m
 Abstract: MyOpenGLView.h
  Version: 1.2
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
*/
#import "MyOpenGLView.h"

@implementation MyOpenGLView

//////////////////////////////////////////////////////
//Override NSView's initWithFrame: to specify our pixel format:
//Note: initWithFrame is called only if a "Custom View" is used in Interface BBuilder 
//and the custom class is a subclass of NSView. For more information on resource loading
//see: developer.apple.com (ADC Home > Documentation > Cocoa > Resource Management > Loading Resources)	
- (id) initWithFrame: (NSRect) frame
{
	GLuint attribs[] = 
    {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFADepthSize, 16,
        0
    };
	
	NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs]; 
	
	if (!fmt)
		NSLog(@"No OpenGL pixel format");
    
    self = [super initWithFrame:frame pixelFormat: [fmt autorelease]];
    
	if (self)
		scene = [[Scene alloc] init];
	
	return self;
}

- (void) dealloc
{
	//remember to clean up!
	[scene release];
	[super dealloc];
}

#pragma mark OpenGL drawing

// update the projection matrix based on view size
- (void) updateProjection {
	//get bounds
	NSRect bounds = [self bounds];
	
	//define the viewport
	glViewport(0, 0, (GLsizei) bounds.size.width, (GLsizei)bounds.size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	//define "the world" window
	gluOrtho2D(0.0, bounds.size.width, 0.0, bounds.size.height);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

//	Override the view's drawRect: to draw our GL content. 
- (void) drawRect: (NSRect) rect
{
	[[self openGLContext] makeCurrentContext];
	[self updateProjection];
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	//draw Objects
	[scene drawObjects];
	
	[[self openGLContext] flushBuffer];
}

#pragma mark Mouse Click Handling 
- (void)mouseUp:(NSEvent *)theEvent {
	[scene resetCurrentObject]; //selects "No object"
	
	/*
		could return a bool and if yes then redraw, it means that an object had to be manually relocated to not be out of bounds
		
	*/
	
	
}

//View Accepts Mouse down events
- (void)mouseDown:(NSEvent*) event {
	NSPoint eventLocation = [self convertPoint:[event locationInWindow] fromView:nil];

	//set the listener position to the new mouse location
	if([scene selectCurrentObject:&eventLocation] >=0) {
		[scene setObjectPosition:&eventLocation];
	}	
	
	//redraw screen, calls drawRect
	[self setNeedsDisplay:YES];
}

- (void) mouseDragged:(NSEvent*) event {
	[self mouseDown:event];
}

#pragma mark FirstResponder Changes

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return  YES;
}

- (BOOL)resignFirstResponder
{
	return YES;
}
#pragma mark Get/Set

- (Scene *)scene {
    return [[scene retain] autorelease];
}

- (void)setScene:(Scene *)value {
    if (scene != value) {
        [scene release];
        scene = [value copy];
    }
}

@end