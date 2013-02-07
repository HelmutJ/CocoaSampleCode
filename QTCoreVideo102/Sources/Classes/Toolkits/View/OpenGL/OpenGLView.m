//---------------------------------------------------------------------------
//
//	File: OpenGLView.m
//
//  Abstract: OpenGL view base class.
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
//  Copyright (c) 2008-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLPixelFormat.h"
#import "OpenGLRotation.h"
#import "OpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const unichar kESCKey = 27;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLClippingPlanes
{
	GLdouble scale;		// Scale factor
	GLdouble aspect;	// Aspect ratio
	GLdouble left;		// Coordinate for the left vertical clipping plane
	GLdouble right;		// Coordinate for the right vertical clipping plane
	GLdouble bottom;	// Coordinate for the bottom horizontal clipping plane
	GLdouble top;		// Coordinate for the top horizontal clipping plane
	GLdouble zNear;		// Distance to the near depth clipping plane
	GLdouble zFar;		// Distance to the far depth clipping plane
};

typedef struct OpenGLClippingPlanes  OpenGLClippingPlanes;

//---------------------------------------------------------------------------

struct OpenGLViewport
{
	NSPoint  mousePoint;	// last place the mouse was
	GLfloat	 zoom;			// zooming within a viewport
	NSRect   bounds;		// view bounds
};

typedef struct OpenGLViewport  OpenGLViewport;

//---------------------------------------------------------------------------

struct OpenGLScreen
{
    NSScreen      *screen;
    NSDictionary  *options;
};

typedef struct OpenGLScreen  OpenGLScreen;

//---------------------------------------------------------------------------

struct OpenGLSceneRotation
{
    BOOL             isRotating;
    GLdouble         frequency;
    OpenGLRotation  *rotation;
};

typedef struct OpenGLSceneRotation  OpenGLSceneRotation;

//---------------------------------------------------------------------------

struct OpenGLViewRep
{
    NSOpenGLView    *view;
    NSOpenGLContext *context;
    CGLContextObj    object;
    GLint            alignment;
};

typedef struct OpenGLViewRep  OpenGLViewRep;

//---------------------------------------------------------------------------

struct OpenGLViewData
{
    OpenGLPixelFormat     *format;
	OpenGLViewport         port;
	OpenGLClippingPlanes   planes;
    OpenGLScreen           mode;
    OpenGLSceneRotation    scene;
    OpenGLViewRep          rep;
};

typedef struct OpenGLViewData  OpenGLViewData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initializers

//---------------------------------------------------------------------------

static void OpenGLViewInitFullScreen(OpenGLViewDataRef pGLView)
{
	pGLView->mode.options = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]  
                                                         forKey:NSFullScreenModeSetting] retain];
	
	pGLView->mode.screen = [[NSScreen mainScreen] retain];
} // OpenGLViewInitFullScreen

//---------------------------------------------------------------------------

static void OpenGLViewInitStates(OpenGLViewDataRef pGLView)
{
	// shading mathod: GL_SMOOTH or GL_FLAT
    glShadeModel(GL_SMOOTH);
	
	// 4-byte pixel alignment
    glPixelStorei(GL_UNPACK_ALIGNMENT, pGLView->rep.alignment);
	
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
	
	glTranslatef(0.0f, 0.0f, -2.0f);
	
	// Turn on depth test
    glEnable(GL_DEPTH_TEST);
	
	// track material ambient and diffuse from surface color, 
	// call it before glEnable(GL_COLOR_MATERIAL)
	
    glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
    glEnable(GL_COLOR_MATERIAL);
	
	// Clear to black nothing fancy.
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	// clear stencil buffer
    glClearStencil(0);
	
	// 0 is near, 1 is far
    glClearDepth(1.0f);
    
    glDepthFunc(GL_LEQUAL);
	
	// Setup blending function 
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
} // initOpenGLStates

//---------------------------------------------------------------------------

static BOOL OpenGLViewInitContext(OpenGLViewDataRef pGLView)
{	
    pGLView->rep.context = [pGLView->rep.view openGLContext];
    
    BOOL success = pGLView->rep.context != nil;
    
    if( success )
    {
        pGLView->rep.object = (CGLContextObj)[pGLView->rep.context CGLContextObj];
    } // if
    
    return( success );
} // initOpenGLSyncToVBL

//---------------------------------------------------------------------------
//
// Turn on VBL syncing for swaps
//
//---------------------------------------------------------------------------

static inline void OpenGLViewInitSyncToVBL(OpenGLViewDataRef pGLView)
{	
    GLint syncVBL = 1;
    
    [pGLView->rep.context setValues:&syncVBL 
                       forParameter:NSOpenGLCPSwapInterval];
} // OpenGLViewInitSyncToVBL

//---------------------------------------------------------------------------

static inline void OpenGLViewInitMTEngine(OpenGLViewDataRef pGLView)
{
	// Enable the multi-threaded OpenGL engine
	
	CGLError cglError = CGLEnable( pGLView->rep.object, kCGLCEMPEngine );
	
	if( cglError != kCGLNoError )
	{
		// Multi-threaded execution is possibly not available
		// so what was the returned CGL error?
		
		NSLog( @">> ERROR[%d]: OpenGL View  - Initializing multi-threaded OpenGL Engine failed!", (int)cglError);
	} // if    
} // OpenGLViewInitMTEngine

//---------------------------------------------------------------------------
//
// Initialize scene rotation
//
//---------------------------------------------------------------------------

static inline void OpenGLViewInitRotation(OpenGLViewDataRef pGLView)
{
    pGLView->scene.isRotating = YES;
	pGLView->scene.rotation   = [OpenGLRotation new];
} // OpenGLViewInitRotation

//---------------------------------------------------------------------------
//
// Initialize other miscellaneous parameters
//
//---------------------------------------------------------------------------

static void OpenGLViewSetParams(NSOpenGLView *pViewObj,
                                OpenGLPixelFormat *pFormat,
                                OpenGLViewDataRef pGLView)
{
    // Pixel format
    
    pGLView->format = pFormat;
    
    // Actual OpenGL view object
    
    pGLView->rep.view = pViewObj;
    
    // Initialize OpenGL viewport parameters
    
	pGLView->port.zoom = 1.0f;
    
    // Initialize OpenGL clipping planes' parameters
    
    pGLView->planes.scale =  0.5;
	pGLView->planes.zNear =  1.0;
	pGLView->planes.zFar  = 10.0;
    
    // Pixel byte alignment
    
    pGLView->rep.alignment = 4;
} // OpenGLViewInitParams

//---------------------------------------------------------------------------

static void OpenGLViewInitAssets(NSOpenGLView *pViewObj,
                                 OpenGLPixelFormat *pFormat,
                                 OpenGLViewDataRef pGLView)
{
    OpenGLViewSetParams(pViewObj, pFormat, pGLView);
    
    if( OpenGLViewInitContext(pGLView) )
    {
        OpenGLViewInitSyncToVBL(pGLView);
        OpenGLViewInitMTEngine(pGLView);
        OpenGLViewInitStates(pGLView);
        OpenGLViewInitRotation(pGLView);
        OpenGLViewInitFullScreen(pGLView);
    } // if
} // OpenGLViewInitAssets

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------
//
// Create an OpenGL view opaque data reference
//
//---------------------------------------------------------------------------

static OpenGLViewDataRef OpenGLViewCreate(NSOpenGLView *pViewObj,
                                          OpenGLPixelFormat *pFormat)
{
	OpenGLViewDataRef pGLView = (OpenGLViewDataRef)calloc( 1, sizeof(OpenGLViewData) );
	
	if( pGLView != NULL )
	{
        OpenGLViewInitAssets(pViewObj, pFormat, pGLView);
	} // if
	else
	{
		NSLog( @">> ERROR: OpenGL View - Allocating Memory For OpenGL View Data Failed!" );
	} // else
    
    return( pGLView );
} // OpenGLViewCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLViewDeleteOptions(OpenGLViewDataRef pGLView)
{
	if( pGLView->mode.options )
	{
		[pGLView->mode.options release];
		
		pGLView->mode.options = nil;
	} // if
} // OpenGLViewDeleteOptions

//---------------------------------------------------------------------------

static void OpenGLViewDeleteScreen(OpenGLViewDataRef pGLView)
{
	if( pGLView->mode.screen )
	{
		[pGLView->mode.screen release];
		
		pGLView->mode.screen = nil;
	} // if
} // OpenGLViewDeleteScreen

//---------------------------------------------------------------------------

static void OpenGLViewDeleteRotation(OpenGLViewDataRef pGLView)
{
	if( pGLView->scene.rotation )
	{
		[pGLView->scene.rotation release];
		
		pGLView->scene.rotation = nil;
	} // if
} // OpenGLViewDeleteRotation

//---------------------------------------------------------------------------

static void OpenGLViewDeleteFormat(OpenGLViewDataRef pGLView)
{
	if( pGLView->format )
	{
		[pGLView->format release];
		
		pGLView->format = nil;
	} // if
} // OpenGLViewDeleteRotation

//---------------------------------------------------------------------------

static void OpenGLViewDeleteAssets(OpenGLViewDataRef pGLView)
{
	OpenGLViewDeleteOptions(pGLView);
	OpenGLViewDeleteScreen(pGLView);
	OpenGLViewDeleteRotation(pGLView);
    OpenGLViewDeleteFormat(pGLView);
} // OpenGLViewDeleteAssets

//---------------------------------------------------------------------------

static void OpenGLViewDelete(OpenGLViewDataRef pGLView)
{
	if( pGLView != NULL )
	{
        OpenGLViewDeleteAssets(pGLView);
        
		free( pGLView );
		
		pGLView = NULL;
	} // if
} // OpenGLViewDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - View port

//---------------------------------------------------------------------------

static void OpenGLViewSetPrespective(OpenGLViewDataRef pGLView)
{
	pGLView->port.bounds   =  [pGLView->rep.view bounds];
	pGLView->planes.aspect =  pGLView->port.bounds.size.width / pGLView->port.bounds.size.height;
	pGLView->planes.right  =  pGLView->planes.aspect * pGLView->planes.scale * pGLView->port.zoom;
	pGLView->planes.left   = -pGLView->planes.right;
	pGLView->planes.top    =  pGLView->planes.scale * pGLView->port.zoom;
	pGLView->planes.bottom = -pGLView->planes.top;
	
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	
	glFrustum(pGLView->planes.left, 
			  pGLView->planes.right, 
			  pGLView->planes.bottom, 
			  pGLView->planes.top, 
			  pGLView->planes.zNear, 
			  pGLView->planes.zFar );
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
} // OpenGLViewSetPrespective

//---------------------------------------------------------------------------

static void OpenGLViewSetPort(OpenGLViewDataRef pGLView)
{
	GLint    x      = (GLint)(pGLView->port.bounds.origin.x);
	GLint    y      = (GLint)(pGLView->port.bounds.origin.y);
	GLsizei  width  = (GLsizei)(pGLView->port.bounds.size.width);
	GLsizei  height = (GLsizei)(pGLView->port.bounds.size.height);
	
	glViewport( x, y, width, height );
	
	glTranslatef( 0.0f, 0.0f, -3.0f );
} // OpenGLViewSetPort

//---------------------------------------------------------------------------
//
// Set perspective and viewport, update pitch and rotation
//
//---------------------------------------------------------------------------

static void OpenGLViewUpdatePort(OpenGLViewDataRef pGLView)
{
	// Set our viewport with correct presperctive
	
	OpenGLViewSetPrespective(pGLView);
	OpenGLViewSetPort(pGLView);
	
	// Constant rotation of the 3D objects
	
    if( pGLView->scene.isRotating )
    {
        [pGLView->scene.rotation update];
    } // if
} // OpenGLViewUpdatePort

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - OpenGL Context

//---------------------------------------------------------------------------
//
// Make the GL context the current context & Clear the viewport
//
//---------------------------------------------------------------------------

static inline void OpenGLViewMakeCurrentContext(OpenGLViewDataRef pGLView)
{
	// Make the GL context the current context
	
	[pGLView->rep.context makeCurrentContext];
	
	// Clear the viewport
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
} // OpenGLViewMakeCurrentContext

//---------------------------------------------------------------------------
//
// Async flush buffer
//
//---------------------------------------------------------------------------

static inline void OpenGLViewFlushBuffer(OpenGLViewDataRef pGLView)
{
	[pGLView->rep.context flushBuffer];
} // OpenGLViewFlushBuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Full Screen Mode

//---------------------------------------------------------------------------

static inline void OpenGLViewFullScreenEnable(OpenGLViewDataRef pGLView)
{
	[pGLView->rep.view enterFullScreenMode:pGLView->mode.screen  
                               withOptions:pGLView->mode.options];
} // OpenGLViewFullScreenEnable

//---------------------------------------------------------------------------

static inline void OpenGLViewFullScreenDisable(OpenGLViewDataRef pGLView)
{
	[pGLView->rep.view exitFullScreenModeWithOptions:pGLView->mode.options];
} // OpenGLViewFullScreenDisable

//---------------------------------------------------------------------------

static inline BOOL OpenGLViewFullScreenSetMode(OpenGLViewDataRef pGLView)
{
    BOOL isInFullScreenMode = [pGLView->rep.view isInFullScreenMode];
    
	if( !isInFullScreenMode )
	{
		OpenGLViewFullScreenEnable(pGLView);
	} // if
    
    return( isInFullScreenMode );
} // OpenGLViewFullScreenSetMode

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Key Events

//---------------------------------------------------------------------------

static void OpenGLViewKeyDown(NSEvent *pEvent,
                              OpenGLViewDataRef pGLView)
{
    if( pEvent )
    {
        NSString  *characters = [pEvent charactersIgnoringModifiers];
        unichar    keyPressed = [characters characterAtIndex:0];
        
        if( keyPressed == kESCKey )
        {
            if( [pGLView->rep.view isInFullScreenMode] )
            {
                OpenGLViewFullScreenDisable(pGLView);
            } // if
            else
            {
                OpenGLViewFullScreenEnable(pGLView);
            } // if
        } // if
    } // if
} // OpenGLViewKeyDown

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Mouse Events

//---------------------------------------------------------------------------

static inline void OpenGLViewMouseDown(NSEvent *pEvent,
                                       OpenGLViewDataRef pGLView)
{
    if( pEvent )
    {
        NSPoint point = [pEvent locationInWindow];
        
        pGLView->port.mousePoint = [pGLView->rep.view convertPoint:point 
                                                          fromView:nil];
    } // if
} // OpenGLViewMouseDown

//---------------------------------------------------------------------------

static inline void OpenGLViewRightMouseDown(NSEvent *pEvent,
                                            OpenGLViewDataRef pGLView)
{
    if( pEvent )
    {
        NSPoint point = [pEvent locationInWindow];
        
        pGLView->port.mousePoint = [pGLView->rep.view convertPoint:point 
                                                          fromView:nil];
    } // if
} // OpenGLViewRightMouseDown

//---------------------------------------------------------------------------

static void OpenGLViewMouseDragged(NSEvent *pEvent,
                                   OpenGLViewDataRef pGLView)
{
    if( pEvent )
    {
        if( [pEvent modifierFlags] & NSRightMouseDown )
        {
            [pGLView->rep.view rightMouseDragged:pEvent];
        } // if
        else
        {
            NSPoint point = [pEvent locationInWindow];
            NSPoint mouse = [pGLView->rep.view convertPoint:point 
                                                   fromView:nil];
            
            if( pGLView->scene.isRotating )
            {
                [pGLView->scene.rotation setRotation:&pGLView->port.mousePoint
                                               start:&mouse];
            } // if
            
            pGLView->port.mousePoint = mouse;
            
            [pGLView->rep.view setNeedsDisplay:YES];
        } // else
    }
} // OpenGLViewMouseDragged

//---------------------------------------------------------------------------

static void OpenGLViewRightMouseDragged(NSEvent *pEvent,
                                        OpenGLViewDataRef pGLView)
{
    if( pEvent )
    {
        NSPoint point = [pEvent locationInWindow];
        NSPoint mouse = [pGLView->rep.view convertPoint:point 
                                               fromView:nil];
        
        pGLView->port.zoom += 0.01f * ( pGLView->port.mousePoint.y - mouse.y );
        
        if( pGLView->port.zoom < 0.05f )
        {
            pGLView->port.zoom = 0.05f;
        } // if
        else if( pGLView->port.zoom > 2.0f )
        {
            pGLView->port.zoom = 2.0f;
        } // else if
        
        pGLView->port.mousePoint = mouse;
        
        OpenGLViewSetPrespective(pGLView);
        
        [pGLView->rep.view setNeedsDisplay:YES];
    } // if
} // OpenGLViewRightMouseDragged

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLView

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)frameRect
{
    OpenGLPixelFormat *pixelFormat = [[OpenGLPixelFormat alloc] initPixelFormatWithPListInAppBundle:@"PixelFormat"];
	
	if( pixelFormat )
	{
		self = [super initWithFrame:frameRect 
						pixelFormat:[pixelFormat pixelFormat]];
		
		if( self )
		{
            mpGLView = OpenGLViewCreate(self, pixelFormat);
		} // if
        else
        {
            NSLog(@">> ERROR: OpenGL View - Failed initializing a frame with the pixel format!");
            
            [pixelFormat release];
        } // else
	} // if
	
	return( self );
} // initWithFrame

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructors

//---------------------------------------------------------------------------
//
// It's important to clean up our rendering objects before we terminate -- 
// Cocoa will not specifically release everything on application termination, 
// so we explicitly call our clean up routine ourselves.
//
//---------------------------------------------------------------------------

- (void) cleanUp
{
	OpenGLViewDelete( mpGLView );
} // cleanUp

//---------------------------------------------------------------------------

- (void) dealloc 
{
	OpenGLViewDelete( mpGLView );
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Viewport Utility

//---------------------------------------------------------------------------
//
// Set perspective and viewport, update pitch and rotation
//
//---------------------------------------------------------------------------

- (void) updateViewport
{
    OpenGLViewUpdatePort( mpGLView );
} // updateViewport

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - OpenGL Context

//---------------------------------------------------------------------------
//
// Make the GL context the current context & Clear the viewport
//
//---------------------------------------------------------------------------

- (void) makeCurrentContext
{
	OpenGLViewMakeCurrentContext(mpGLView);
} // makeCurrentContext

//---------------------------------------------------------------------------
//
// Async flush buffer
//
//---------------------------------------------------------------------------

- (void) flushBuffer
{
	OpenGLViewFlushBuffer(mpGLView);
} // flushBuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (void) setFrequency:(const GLdouble)theFrequency
{
    [mpGLView->scene.rotation  setFrequency:theFrequency];
} // setFrequency

//---------------------------------------------------------------------------

- (void) setRotating:(const BOOL)theRotation
{
    mpGLView->scene.isRotating = theRotation;
} // setRotating

//---------------------------------------------------------------------------

- (void) setScale:(const GLdouble)theScale
{
	mpGLView->planes.scale = theScale;
} // setScale

//---------------------------------------------------------------------------

- (NSOpenGLContext *) context
{
    return( mpGLView->rep.context );
} // context

//---------------------------------------------------------------------------

- (CGLContextObj) contextObj
{
    return( mpGLView->rep.object );
} // contextObj

//---------------------------------------------------------------------------

- (NSOpenGLPixelFormat *) pixelFormat
{
    return( [mpGLView->format pixelFormat] );
} // pixelFormat

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Full Screen Mode

//---------------------------------------------------------------------------

- (BOOL) setFullScreenMode
{
	return( OpenGLViewFullScreenSetMode(mpGLView) );
} // setFullScreenMode

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Key Events

//---------------------------------------------------------------------------

- (void) keyDown:(NSEvent *)theEvent
{
	OpenGLViewKeyDown(theEvent, mpGLView);
} // keyDown

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Mouse Events

//---------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)theEvent
{
	OpenGLViewMouseDown(theEvent,mpGLView);
} // mouseDown

//---------------------------------------------------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent
{
	OpenGLViewRightMouseDown(theEvent,mpGLView);
} // rightMouseDown

//---------------------------------------------------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	OpenGLViewMouseDragged(theEvent,mpGLView);
} // mouseDragged

//---------------------------------------------------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	OpenGLViewRightMouseDragged(theEvent,mpGLView);
} // rightMouseDragged

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
