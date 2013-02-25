//---------------------------------------------------------------------------
//
//	File: OpenGLViewKit.m
//
//  Abstract: OpenGL glView base class
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "AlertPanelKit.h"
#import "OpenGLViewKit.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

static const GLdouble kViewRotationDegreesPerSecond = 20.0;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct OpenGLViewAttributes
{
	GLfloat   offset;					// delta change
	GLfloat	  zoom;						// zoom used for animation
	GLfloat   angle;					// angle used for animation
	GLfloat   pitch;					// pitch used for animation
	GLdouble  lastFrameReferenceTime;	// used to compute change in time
	BOOL      leftMouseIsDown;			// was the left mouse button pressed?
	BOOL      rightMouseIsDown;			// was the right mouse button pressed?
	NSPoint   lastMousePoint;			// last place the mouse was 
};

typedef struct OpenGLViewAttributes  OpenGLViewAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLViewKit

//---------------------------------------------------------------------------

#pragma mark -- Prepare the OpenGL View --

//---------------------------------------------------------------------------

- (void) prepareOpenGLMTEngine
{
	CGLError       cglError   = kCGLNoError;
	CGLContextObj  cglContext = CGLGetCurrentContext( );

	// Enable the multi-threaded OpenGL engine
	
	cglError = CGLEnable( cglContext, kCGLCEMPEngine );

	if ( cglError != kCGLNoError )
	{
		// Multi-threaded execution is possibly not available
		// so what was the returned CGL error?
		
		[[AlertPanelKit withTitle:@"OpenGL View Kit" 
						  message:@"Initializing multi-threaded OpenGL Engine"
							 exit:NO] displayAlertPanelWithError:cglError];
	} // if    
} // prepareOpenGLMTEngine

//---------------------------------------------------------------------------

- (void) prepareOpenGLStates
{
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);

	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	glShadeModel( GL_SMOOTH );					// enable smooth shading
    glEnable( GL_DEPTH_TEST );					// enable depth testing
 
	glDisable( GL_LIGHTING );
	
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );		// black background
    glClearStencil( 0 );						// clear stencil image
	glClearDepth( 1.0f );						// 0 is near, 1 is far
    glDepthFunc( GL_LEQUAL );					// type of depth test to do

	// For some OpenGL implementations, glAttribs.texture coordinates generated 
	// during rasterization aren't perspective correct. However, you 
	// can usually make them perspective correct by calling the API
	// glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST).  Colors 
	// generated at the rasterization stage aren't perspective correct 
	// in almost every OpenGL implementation, / and can't be made so. 
	// For this reason, you're more likely to encounter this problem 
	// with colors than glAttribs.texture coordinates.
	
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
} // prepareOpenGLStates

//---------------------------------------------------------------------------
//
// Set up the GL contexts swap interval -- passing 1 means that the buffers 
// are swapped only during the vertical retrace of the monitor.
//	
//---------------------------------------------------------------------------

- (void) prepareOpenGLSwapInterval
{
	GLint swapInterval = 1;
    
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
} // prepareOpenGLSwapInterval

//---------------------------------------------------------------------------
//
// Set up the OpenGL environment
//
//---------------------------------------------------------------------------

- (void) prepareOpenGLView
{
	[self prepareOpenGLMTEngine];
	[self prepareOpenGLSwapInterval];
 	[self prepareOpenGLStates];
} // prepareOpenGL

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (void) prepareOpenGL
{
	glViewMemObj = [[MemObject alloc] initMemoryWithType:kMemAlloc size:sizeof(OpenGLViewAttributes)];
	
	if ( glViewMemObj )
	{
		glView = (OpenGLViewAttributesRef)[glViewMemObj pointer];
		
		if ( [glViewMemObj isPointerValid] )
		{
			glView->lastMousePoint.x       = 0.0f;
			glView->lastMousePoint.y       = 0.0f;
			glView->lastFrameReferenceTime = -1.0;
			glView->leftMouseIsDown        = NO;
			glView->rightMouseIsDown       = NO;
			glView->angle                  = 0.0f;
			glView->pitch                  = 0.0f;
			glView->zoom                   = 1.0f;
			
			[self prepareOpenGLView];
		} // if
		else
		{
			[[AlertPanelKit withTitle:@"OpenGL View Kit" 
							  message:@"Failure Allocating Memory For OpenGL View Attributes"
								 exit:YES] displayAlertPanel];
		} // else
	} // if
} // prepareOpenGL

//---------------------------------------------------------------------------

#pragma mark -- Cleanup all the Resources --

//---------------------------------------------------------------------------

- (void) dealloc 
{
	if ( glViewMemObj )
	{
		[glViewMemObj release];
		
		glViewMemObj = nil;
	} // if
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -- Basic Setup for OpenGL Drawing --

//---------------------------------------------------------------------------

- (void) setupPrespectiveMatrix:(GLfloat)theWidth  
					boundsHeight:(GLfloat)theHeight
					scaleFactor:(GLfloat)theScaleFactor
{
	GLdouble  aspect =  theWidth / theHeight;
	GLdouble  right  =  theScaleFactor * aspect * glView->zoom;
	GLdouble  left   = -right;
	GLdouble  top    =  theScaleFactor * glView->zoom;
	GLdouble  bottom = -top;
	GLdouble  zNear  =  1.0;
	GLdouble  zFar   =  10.0;

	glMatrixMode( GL_PROJECTION );
	
		glLoadIdentity( );
		glFrustum( left, right, bottom, top, zNear, zFar );
		
	glMatrixMode( GL_MODELVIEW );
} // setupPrespectiveMatrix

//------------------------------------------------------------------------

- (void) setupViewport:(GLfloat)theScaleFactor
{
	NSRect   theBounds = [self bounds];
	GLfloat  theWidth  = NSWidth( theBounds );
	GLfloat  theHeight = NSHeight( theBounds );

	[self setupPrespectiveMatrix:theWidth 
					boundsHeight:theHeight 
					scaleFactor:theScaleFactor];
	
	glViewport( 0, 0, theWidth, theHeight );
} // setupViewport

//---------------------------------------------------------------------------

- (void) setupView:(GLfloat)theScaleFactor
{
	[self setupViewport:theScaleFactor];
	
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT );

	glMatrixMode( GL_TEXTURE );
	glLoadIdentity( );

	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity( );

	glTranslatef( 0.0f, 0.0f, -3.0f );
} // drawSetup

//---------------------------------------------------------------------------

#pragma mark -- Set Angle & Pitch --

//---------------------------------------------------------------------------

- (GLdouble) updateChangeInTime
{
	GLdouble  timeDelta = 0.0;
	GLdouble  timeNow   = (GLdouble)[NSDate timeIntervalSinceReferenceDate];

	if ( glView->lastFrameReferenceTime < 0 )
	{
		timeDelta = 0;
	} // if
	else
	{
		timeDelta = timeNow - glView->lastFrameReferenceTime;
	} // else

	glView->lastFrameReferenceTime = timeNow;
	
	return  timeDelta;
} // updateChangeInTime

//------------------------------------------------------------------------

- (void) updatePitch
{
	if ( glView->pitch < -45.0f )
	{
		glView->pitch = -45.0f;
	} // if
	else if ( glView->pitch > 90.0f )
	{
		glView->pitch = 90.0f;
	} // else if

	glRotatef( glView->pitch, 1.0f, 0.0f, 0.0f );
} // updatePitch

//------------------------------------------------------------------------

- (void) updateAngle
{
	if ( !glView->leftMouseIsDown && !glView->rightMouseIsDown )
	{
		GLdouble timeDelta = [self updateChangeInTime];

		glView->angle += kViewRotationDegreesPerSecond * timeDelta;
		
		if ( glView->angle >= 360.0f )
		{
			glView->angle -= 360.0f;
		} // if
	} // if
	
	glRotatef( glView->angle, 0.0f, 1.0f, 0.0f );
	
	// Increment the rotation angle
	
	glView->angle += 0.2f;
} // updateAngle

//------------------------------------------------------------------------

#pragma mark -- Handling mouse events --

//------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)theEvent
{
	glView->lastMousePoint  = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	glView->leftMouseIsDown = YES;
} // mouseDown

//------------------------------------------------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent
{
	glView->lastMousePoint   = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	glView->rightMouseIsDown = YES;
} // rightMouseDown

//------------------------------------------------------------------------

- (void)mouseUp:(NSEvent *)theEvent
{
	glView->leftMouseIsDown = NO;
} // mouseUp

//------------------------------------------------------------------------

- (void)rightMouseUp:(NSEvent *)theEvent
{
	glView->rightMouseIsDown = NO;
} // rightMouseUp

//------------------------------------------------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	if ( [theEvent modifierFlags] & NSRightMouseDown )
	{
		[self rightMouseDragged:theEvent];
	} // if
	else
	{
		NSPoint mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];

		glView->pitch += glView->lastMousePoint.y - mouse.y;
		glView->angle -= glView->lastMousePoint.x - mouse.x;

		glView->lastMousePoint = mouse;
	} // else
} // mouseDragged

//------------------------------------------------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	glView->zoom += 0.01f * ( glView->lastMousePoint.y - mouse.y );
	
	if ( glView->zoom < 0.05f )
	{
		glView->zoom = 0.05f;
	} // if
	else if ( glView->zoom > 2.0f )
	{
		glView->zoom = 2.0f;
	} // else if

	glView->lastMousePoint = mouse;
} // rightMouseDragged

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
