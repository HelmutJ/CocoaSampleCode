//---------------------------------------------------------------------------------
//
//	File: GLSLBasicsView.m
//
//  Abstract: Main rendering class
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
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
//  Copyright (c) 2007-2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#import "GLSLHardwareSupport.h"
#import "GLSLBasicsView.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Constatnts

//---------------------------------------------------------------------------------

static const GLfloat         kPi                           = 3.1415927f; // IEEE-754 single precision
static const GLint           kFloatSize                    = sizeof(GLfloat);
static const GLfloat         kOffsetDelta                  = 1.0f/256.0f;
static const GLdouble        kViewRotationDegreesPerSecond = 20.0;
static const NSTimeInterval  kScheduledTimerInSeconds      = 1.0f/120.0f;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private Enumerated Types

//---------------------------------------------------------------------------------

enum UniformLocations
{
	kUniformLightPosition = 0,
	kUniformOffset,
	kUniformPattern,
	kUniformPalette
};

typedef enum UniformLocations UniformLocations;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation GLSLBasicsView

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Initialize 1D & 2D Textures

//---------------------------------------------------------------------------------

- (GLuint) initTexture1D:(const GLvoid *)thePixels
				   count:(const GLsizei)theCount
{
	GLuint textureID = 0;
	
	glActiveTexture(GL_TEXTURE1);
	glGenTextures(1, &textureID);
	glBindTexture(GL_TEXTURE_1D, textureID);
	
	glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	
	glTexImage1D(GL_TEXTURE_1D, 
				 0, 
				 GL_RGBA, 
				 theCount, 
				 0, 
				 GL_RGB, 
				 GL_FLOAT, 
				 thePixels);
	
	return textureID;
} // initTexture1D

//---------------------------------------------------------------------------------

- (GLuint) initTexture2D:(const GLvoid *)thePixels
				   width:(const GLsizei)theWidth
				  height:(const GLsizei)theHeight
{
	GLuint textureID = 0;
	
	glActiveTexture(GL_TEXTURE0);
	glGenTextures(1, &textureID);
	glBindTexture(GL_TEXTURE_2D, textureID);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	glTexImage2D(GL_TEXTURE_2D, 
				 0, 
				 GL_RGBA, 
				 theWidth, 
				 theHeight, 
				 0, 
				 GL_LUMINANCE, 
				 GL_FLOAT, 
				 thePixels);
	
	return textureID;
} // initTexture2D

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Initialize palette

//---------------------------------------------------------------------------------

- (void) initPalettePixels:(GLfloat *)thePixels
					 count:(const GLsizei)theCount
{
	GLfloat   a = (GLfloat)theCount;
	GLfloat   b = 0.5f * a;
	GLfloat   c = 1.5f * a;
	GLfloat   d = 2.0f / a;
	GLfloat   x[2];
	GLfloat   n;
	GLint     i;
	GLint     j;
	
	a = 1.0f / a;
	c = 1.0f / c;
	
	for( i = 0; i < theCount; i++ )
	{
		n = (GLfloat)i;
		
		x[0] = kPi * n;
		x[1] = sinf( a * x[0] );
		
		j = 3 * i;
		
		thePixels[j]   = 1.0f - x[1];
		thePixels[j+1] = b * c * ( 1.0f + sinf( d * x[0] ) );
		thePixels[j+2] = x[1];
	} // for
} // initPalettePixels

//---------------------------------------------------------------------------------

- (void) initPalette
{
	GLsizei count = 256;
	GLfloat *palettePixels = (GLfloat *)malloc( 3 * count * kFloatSize );
	
	if( palettePixels != NULL )
	{
		[self initPalettePixels:palettePixels 
						  count:count];
		
		paletteID = [self initTexture1D:palettePixels
								  count:count];
		
		free( palettePixels );
		
		palettePixels = NULL;
	} // if
} // initPalette

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Initialize pattern

//---------------------------------------------------------------------------------

- (void) initPatternPixels:(GLfloat *)thePixels
					 width:(const GLsizei)theWidth
					height:(const GLsizei)theHeight
{
	GLfloat   a = (GLfloat)theWidth;
	GLfloat   b =  0.25f * a;
	GLfloat   c = 0.125f * a;
	GLfloat   f;
	GLfloat   x;
	GLfloat   y;
	GLint     i;
	GLint     iMax = theWidth >> 1;
	GLint     j;
	GLint     jMax = theHeight >> 1;
	GLint     k = theWidth - 1;
	GLint     l;
	GLint     m;
	GLint     n;
	
	b = 1.0f / b;
	c = 1.0f / c;
	
	for( i = 0; i < iMax; i++ )
	{
		y = (GLfloat)i;
		
		for( j = 0; j < jMax; j++ )
		{
			x = (GLfloat) j;
			f = 0.25f*(sinf(b*x) + sinf(b*y) + sinf(b*(x+y)) + sinf(c*sqrtf(x*x+y*y)));
			
			l = i * theWidth;
			m = k * theWidth - l;
			n = k - j;
			
			thePixels[l+j] = f;
			thePixels[l+n] = f;
			thePixels[m+j] = f;
			thePixels[m+n] = f;
		} // for
	} // for
} // initPatternPixels

//---------------------------------------------------------------------------------

- (void) initPattern
{
	GLsizei   width  = 128;
	GLsizei   height = 128;
	GLfloat  *patternPixels = (GLfloat *)malloc(3 * width * height * kFloatSize);
	
	if( patternPixels != NULL )
	{
		[self initPatternPixels:patternPixels 
						  width:width 
						 height:height];

		patternID = [self initTexture2D:patternPixels
								  width:width
								 height:height];
		
		free( patternPixels );
		
		patternPixels = NULL;
	} // if
} // initPattern

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Setup OpenGL & shader uniforms

//---------------------------------------------------------------------------------

- (void) initShaderUniforms
{
	// Enable the program object
	
	glUseProgramObjectARB(programObject);
	
	// Store the values of the uniforms from the vertex 
	// and the fragment shaders
	
	locations[kUniformLightPosition] = [plasma getUniformLocation:"LightPosition"];
	locations[kUniformOffset]        = [plasma getUniformLocation:"offset"];
	locations[kUniformPattern]       = [plasma getUniformLocation:"pattern"];
	locations[kUniformPalette]       = [plasma getUniformLocation:"palette"];
	
	// Set the (x,y,z) coordinates of the light position
	
	glUniform3fARB(locations[kUniformLightPosition], 0.0, 0.0, 20.0);
	
	// Set the samplers
	
	glUniform1iARB(locations[kUniformPattern], 0);
	glUniform1iARB(locations[kUniformPalette], 1);
	
	// Disable the program object
	
	glUseProgramObjectARB(NULL);
} // initShaderUniforms

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Setup OpenGL

//---------------------------------------------------------------------------------

- (void) initOpenGLStates
{
	[[self openGLContext] makeCurrentContext];
	
	//-----------------------------------------------------------------
	//
	// For some OpenGL implementations, texture coordinates generated 
	// during rasterization aren't perspective correct. However, you 
	// can usually make them perspective correct by calling the API
	// glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST).  Colors 
	// generated at the rasterization stage aren't perspective correct 
	// in almost every OpenGL implementation, / and can't be made so. 
	// For this reason, you're more likely to encounter this problem 
	// with colors than texture coordinates.
	//
	//-----------------------------------------------------------------
	
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
	
	// Set up the projection
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glFrustum(-0.3, 0.3, 0.0, 0.6, 1.0, 8.0);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTranslatef(0.0, 0.0, -2.0);
	
	// Turn on depth test
	
    glEnable(GL_DEPTH_TEST);
	
	// front - or back - facing facets can be culled
	
    glEnable(GL_CULL_FACE);
} // initOpenGL

//---------------------------------------------------------------------------------

- (void) initTexturesForShader
{
	// Create the palette
	
	[self initPalette];
	
	// Create the plasma pattern
	
	[self initPattern];
} // initTexturesForShader

//---------------------------------------------------------------------------------

- (void) initGLSLShader
{
	// Initialize the plasma shader from the application bundle
	
	plasma = [[Shader alloc] initWithShadersInAppBundle:@"Plasma"];
	
	if( plasma )
	{
		// Get the program object for the plasma shader
		
		programObject = [plasma programObject];
		
		// Setup the uniforms for the plasma shader
		
		[self initShaderUniforms];
	} // if
} // initGLSLShader

//---------------------------------------------------------------------------------

- (void) initOpenGLDisplayList
{
	tranguloidTrefoil = [[TranguloidTrefoil alloc] initTranguloidTrefoilWithAttribbutes:128 
																				  ratio:16];
	
	if( tranguloidTrefoil )
	{
		tranguloidTrefoilDL = [tranguloidTrefoil displayList];
	} // if
} // initOpenGLDisplayList

//---------------------------------------------------------------------------------

 - (void) initGLUTString:(const NSRect *)theFrame
{
	NSSize  size   = theFrame->size;
	GLsizei width  = (GLsizei)size.width;
	GLsizei height = (GLsizei)size.height;
	
	NSPoint coordinates = NSMakePoint(10.0, 10.0);
	
	info = [[GLUTString alloc] initWithViewSizeAndDrawCoordinates:&size
													  coordinates:&coordinates];

	infoString = [[NSString alloc] initWithFormat:@"Bounds: %ld x %ld",width,height];
} // initGLUTString

//---------------------------------------------------------------------------------

- (void) initOpenGL:(const NSRect *)theFrame
{
	[self initOpenGLStates];
	[self initTexturesForShader];
	[self initGLSLShader];
	[self initOpenGLDisplayList];
	[self initGLUTString:theFrame];
} // initOpenGL

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Animation Timer

//---------------------------------------------------------------------------------

- (void) heartbeat
{
	[self drawRect:[self bounds]];
} // heartbeat

//---------------------------------------------------------------------------------

- (void) initUpdateTimer
{	
	timer = [NSTimer timerWithTimeInterval:kScheduledTimerInSeconds 
									target:self
								  selector:@selector(heartbeat) 
								  userInfo:nil
								   repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:timer 
								 forMode:NSDefaultRunLoopMode];
	
	[[NSRunLoop currentRunLoop] addTimer:timer 
								 forMode:NSEventTrackingRunLoopMode];
} // initUpdateTimer

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Initializations

//---------------------------------------------------------------------------------

- (void) initViewAttributes
{
	
	lastFrameReferenceTime = [NSDate timeIntervalSinceReferenceDate];
	
	leftMouseIsDown     = NO;
	rightMouseIsDown    = NO;
	
	angle =  0.0f;
	pitch = 25.0f;
	zoom  =  1.0f;
	
	bounds.origin.x    = 0.0f;
	bounds.origin.y    = 0.0f;
	bounds.size.width  = 0.0f;
	bounds.size.height = 0.0f;
} // initViewAttributes

//---------------------------------------------------------------------------------
//
// Sync to VBL to avoid tearing.
//
//---------------------------------------------------------------------------------

- (void) initSyncToVBL
{
	GLint  swapInterval = 1;
	
	[[self openGLContext] setValues:&swapInterval 
					   forParameter:NSOpenGLCPSwapInterval];
} // initSyncToVBL

//---------------------------------------------------------------------------------

- (void) initOpenGLView:(const NSRect *)theFrame
{
	// Setting the view's frame size
	
	[self setFrameSize:theFrame->size];
	
	// View attributes initilizations
	
	[self initViewAttributes];
	
	// New timer for updating OpenGL view
	
	[self initUpdateTimer];
	
	// Sync to VBL to avoid tearing
	
	[self initSyncToVBL];
	
	// OpenGL initializations
	
	[self initOpenGL:theFrame];
	
	// Did the frame change?
	
	[self setPostsFrameChangedNotifications:YES];
} // initOpenGLView

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Designated initializer

//---------------------------------------------------------------------------------

- (NSOpenGLPixelFormat *) initPixelFormat
{
	NSOpenGLPixelFormatAttribute pixelAttributes[] 
	=	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAStencilSize, 8,
		0
	};
	
	CheckForGLSLHardwareSupport( pixelAttributes );
	
	NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:pixelAttributes] 
										autorelease];
	
	return pixelFormat;
} // initPixelFormat

//---------------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)theFrame 
		 pixelFormat:(NSOpenGLPixelFormat *)thePixelFormat
{	
	// Create a GL Context to use - i.e. init the superclass
	
	if( thePixelFormat == nil )
	{
		thePixelFormat = [self initPixelFormat];
	} //  if
	
	self = [super initWithFrame:theFrame 
					pixelFormat:thePixelFormat];
	
	if( self )
	{
		[self initOpenGLView:&theFrame];
	} // if
	
	return self;
} // initWithFrame

//---------------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)theFrame
{
	return [self initWithFrame:theFrame 
				   pixelFormat:nil];
} // initWithFrame

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Deallocating Resources

//---------------------------------------------------------------------------------

- (void) deallocTimer
{
	if( timer ) 
	{
		[timer invalidate];
		[timer release];
		
		timer = nil;
	} // if
} // deallocTimer

//---------------------------------------------------------------------------------

- (void) deallocOpenGLResources
{
	if( tranguloidTrefoil )
	{
		[tranguloidTrefoil release];
		
		tranguloidTrefoil = nil;
	} // if
	
	if( patternID )
	{
		glDeleteTextures(1, &patternID);
	} // if
	
	if( paletteID )
	{
		glDeleteTextures(1, &paletteID);
	} // if
	
	if( plasma )
	{
		[plasma release];
		
		plasma = nil;
	} // if
	
	if( info )
	{
		[info release];
		
		info = nil;
	} // if
	
	if( infoString )
	{
		[infoString release];
		
		infoString = nil;
	} // if
} //deallocOpenGLResources

//---------------------------------------------------------------------------------

- (void) dealloc
{
	// Release the update timer
	
	[self deallocTimer];
	
	// Delete OpenGL resources
	
	[self deallocOpenGLResources];
	
	//Dealloc the superclass
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Binding palette & pattern

//---------------------------------------------------------------------------------

- (void) bindPalette
{
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_1D, paletteID);
} // bindPalette

//---------------------------------------------------------------------------------

- (void) bindPattern
{
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, patternID);
} // bindPattern

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Updating Drawing Parameters

//---------------------------------------------------------------------------------

- (void) updateOffset
{
	offset += kOffsetDelta;
	
	if( offset > 1.0f )
	{
		offset = 0.0f;
	} // if
} // updateOffset

//---------------------------------------------------------------------------------

- (NSTimeInterval) updateTimeDelta
{
	NSTimeInterval  timeNow   = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval  timeDelta = timeNow - lastFrameReferenceTime;
	
	return  timeDelta;
} // updateTimeDelta

//---------------------------------------------------------------------------------

- (void) updatePitch
{
	if( pitch < -45.0f )
	{
		pitch = -45.0f;
	} // if
	else if( pitch > 90.0f )
	{
		pitch = 90.0f;
	} // else if
	
	glRotatef(pitch, 1.0f, 0.0f, 0.0f);
} // updatePitch

//---------------------------------------------------------------------------------

- (void) updateAngle
{
	if( !leftMouseIsDown && !rightMouseIsDown )
	{
		NSTimeInterval updateTimeDelta = [self updateTimeDelta];
		
		angle += kViewRotationDegreesPerSecond * updateTimeDelta;
		
		if( angle >= 360.0f )
		{
			angle -= 360.0f;
		} // if
	} // if
	
	// update object rotation
	
	glRotatef( angle, 0.0f, 1.0f, 0.0f );
	
	//	reset time in all cases
	
	lastFrameReferenceTime = [NSDate timeIntervalSinceReferenceDate];
} // updateAngle

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Updating & Resizing

//---------------------------------------------------------------------------------

- (void) updatePrespectiveMatrix
{
	GLdouble  width  = (GLdouble)NSWidth(bounds);
	GLdouble  height = (GLdouble)NSHeight(bounds);
	GLdouble  aspect =  width / height;
	GLdouble  right  =  0.15 * aspect * zoom;
	GLdouble  left   = -right;
	GLdouble  top    =  0.15 * zoom;
	GLdouble  bottom = -top;
	GLdouble  zNear  =  1.0;
	GLdouble  zFar   =  8.0;
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glFrustum(left, right, bottom, top, zNear, zFar);
	
	glMatrixMode(GL_MODELVIEW);
} // updatePrespectiveMatrix

//---------------------------------------------------------------------------------
//
// Handles resizing/updating of OpenGL needs context update and if the window  
// dimensions change, window dimensions update, reseting of viewport and an update 
// of the projection matrix.
//
//---------------------------------------------------------------------------------

- (void) resizeView
{
	NSRect viewBounds = [self bounds];
	
	if( !NSEqualRects( viewBounds, bounds ) )
	{
		GLsizei  width  = (GLsizei)NSWidth(viewBounds);
		GLsizei  height = (GLsizei)NSHeight(viewBounds);
		
		// GLUT string object needs to know the view bounds have changed as well
		
		if( infoString )
		{
			[infoString release];
			
			infoString = nil;
		} // if
		
		infoString = [[NSString alloc] initWithFormat:@"Bounds: %ld x %ld",width,height];
		
		[info setViewSize:&viewBounds.size];

		// Update the view bounds
		
		bounds = viewBounds;
		
		// Prespective matrix & the OpenGL view needs an update as well
		
		[self updatePrespectiveMatrix];
		
		// View port has changed as well
		
		glViewport(0, 0, width, height);
	} // if	
} // resizeView

//---------------------------------------------------------------------------------
//
// Window resizes, moves and display changes.
//
//---------------------------------------------------------------------------------

- (void) update
{
	[super update];
} // update

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Draw Utilities

//---------------------------------------------------------------------------------

- (void) drawBegin
{
	[[self openGLContext] makeCurrentContext];
	
	[self resizeView];
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	glClearColor(0.075f, 0.075f, 0.075f, 1.0f);
	
	glPushMatrix();
} // drawBegin

//---------------------------------------------------------------------------------

- (void) drawEnd
{
	glPopMatrix();

	[info drawString:infoString];
	
	[[self openGLContext] flushBuffer];
} // drawEnd

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Drawing Utilities

//---------------------------------------------------------------------------------

- (void) scaleModel
{
	glScalef(0.055f, 0.055f, 0.055f);
	
	// Use our display list
	
	glCallList(tranguloidTrefoilDL);
} // scaleModel

//---------------------------------------------------------------------------------

- (void) applyShader
{
	// Bind the shader
	
	glUseProgramObjectARB(programObject);
	
	// Modify offset uniform
	
	glUniform1fvARB(locations[kUniformOffset], 1, &offset);
	
	// Use our display list
	
	[self scaleModel];
	
	// Unbind the shader
	
	glUseProgramObjectARB(NULL);
} // applyShader

//---------------------------------------------------------------------------------

- (void) drawModel
{
	[self bindPalette];
	
	[self bindPattern];
	
	[self applyShader];
	
	[self updateOffset];
} // drawModel

//---------------------------------------------------------------------------------

-(void) updateModel
{
	// Constant rotation of the subject
	
	[self updatePitch];
	
	[self updateAngle];
	
	// Draw the model
	
	[self drawModel];
} // updateModel

//---------------------------------------------------------------------------------

- (void) drawRect:(NSRect)theRect
{
	[self drawBegin];
	
	[self updateModel];
	
	[self drawEnd];
} // drawRect

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Handling mouse events

//---------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)theEvent
{
	lastMousePoint  = [self convertPoint:[theEvent locationInWindow] 
								fromView:nil];
	leftMouseIsDown = YES;
} // mouseDown

//---------------------------------------------------------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent
{
	lastMousePoint   = [self convertPoint:[theEvent locationInWindow] 
								 fromView:nil];
	rightMouseIsDown = YES;
} // rightMouseDown

//---------------------------------------------------------------------------------

- (void)mouseUp:(NSEvent *)theEvent
{
	leftMouseIsDown = NO;
} // mouseUp

//---------------------------------------------------------------------------------

- (void)rightMouseUp:(NSEvent *)theEvent
{
	rightMouseIsDown = NO;
} // rightMouseUp

//---------------------------------------------------------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	if( [theEvent modifierFlags] & NSRightMouseDown )
	{
		[self rightMouseDragged:theEvent];
	} // if
	else
	{
		NSPoint mouse = [self convertPoint:[theEvent locationInWindow] 
								  fromView:nil];
		
		pitch += lastMousePoint.y - mouse.y;
		angle -= lastMousePoint.x - mouse.x;
		
		lastMousePoint = mouse;
		
		[self setNeedsDisplay:YES];
	} // else
} // mouseDragged

//---------------------------------------------------------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint mouse = [self convertPoint:[theEvent locationInWindow] 
							  fromView:nil];
	
	zoom += 0.01f * (lastMousePoint.y - mouse.y);
	
	if( zoom < 0.05f )
	{
		zoom = 0.05f;
	} // if
	else if( zoom > 2.0f )
	{
		zoom = 2.0f;
	} // else if
	
	lastMousePoint = mouse;
	
	[self updatePrespectiveMatrix];
	
	[self setNeedsDisplay:YES];
} // rightMouseDragged

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

