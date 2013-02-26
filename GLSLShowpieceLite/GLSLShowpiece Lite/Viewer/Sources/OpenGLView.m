//-------------------------------------------------------------------------
//
//	File: OpenGLView.m
//
//  Abstract: Main rendering class
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
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
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

//------------------------------------------------------------------------

#import <Accelerate/Accelerate.h>

//------------------------------------------------------------------------

#import "OpenGLView.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const double          kViewRotationDegreesPerSecond        = 20.0;
static const double          kExhibitHeightMovementUnitsPerSecond = 0.5;
static const NSTimeInterval  kScheduledTimerInSeconds             = 1.0f/150.0f; 

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef struct
{
	GLuint         imageBitsPerPixel;
	GLuint         imageBitsPerComponent;
	GLuint         imageSamplesPerPixel;
	GLuint         imageStorageSize;
	CGBitmapInfo   imageBitmapInfo;
	vImage_Buffer  imageBuffer;
} CGImageBitmap;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static inline GLboolean CheckForExtension( const char *extensionName, const GLubyte *extensions )
{
	GLboolean  bExtensionAvailable = gluCheckExtension( (GLubyte *)extensionName, extensions );
	
	return bExtensionAvailable;
} // CheckForExtension

//------------------------------------------------------------------------

static inline void CheckForAndLogExtensionAvailable( const GLboolean extensionAvailable, const char *extensionName )
{
	if ( extensionAvailable == GL_FALSE )
	{
		NSLog( @">> WARNING: \"%s\" extension is not available!\n", extensionName );
	} // if
} // CheckForExtensions

//------------------------------------------------------------------------

static void CheckForShaders( NSOpenGLPixelFormatAttribute *thePixelAttributes )
{
	const GLubyte *extensions = glGetString( GL_EXTENSIONS );
	
	GLboolean  bShaderObjectAvailable      = CheckForExtension(       "GL_ARB_shader_objects", extensions );
	GLboolean  bShaderLanguage100Available = CheckForExtension( "GL_ARB_shading_language_100", extensions );
	GLboolean  bVertexShaderAvailable      = CheckForExtension(        "GL_ARB_vertex_shader", extensions );
	GLboolean  bFragmentShaderAvailable    = CheckForExtension(      "GL_ARB_fragment_shader", extensions );
	
	GLboolean  bForceSoftwareRendering =      ( bShaderObjectAvailable      == GL_FALSE )
										   || ( bShaderLanguage100Available == GL_FALSE )
										   || ( bVertexShaderAvailable      == GL_FALSE ) 
										   || ( bFragmentShaderAvailable    == GL_FALSE );
	
	if ( bForceSoftwareRendering )
	{
		// Force software rendering, so fragment shaders will execute

		CheckForAndLogExtensionAvailable(      bShaderObjectAvailable, "GL_ARB_shader_objects"       );
		CheckForAndLogExtensionAvailable( bShaderLanguage100Available, "GL_ARB_shading_language_100" );
		CheckForAndLogExtensionAvailable(      bVertexShaderAvailable, "GL_ARB_vertex_shader"        );
		CheckForAndLogExtensionAvailable(    bFragmentShaderAvailable, "GL_ARB_fragment_shader"      );

		thePixelAttributes [3] = NSOpenGLPFARendererID;
		thePixelAttributes [4] = kCGLRendererGenericFloatID;
	} // if
} // CheckForShaders

//------------------------------------------------------------------------

static void CheckForClipVolumeHint( NSOpenGLPixelFormatAttribute *thePixelAttributes )
{
	const GLubyte *extensions = glGetString(GL_EXTENSIONS);

	// Inform OpenGL that the geometry is entirely within the view volume and that view-volume 
	// clipping is unnecessary. Normal clipping can be resumed by setting this hint to GL_DONT_CARE. 
	// When clipping is disabled with this hint, results are undefined if geometry actually falls 
	// outside the view volume.

	GLboolean  bClipVolumeHintExtAvailable = CheckForExtension( "GL_EXT_clip_volume_hint", extensions );
	
	if (  bClipVolumeHintExtAvailable == GL_TRUE )
	{
		glHint( GL_CLIP_VOLUME_CLIPPING_HINT_EXT,GL_FASTEST );
	} // if
} // CheckForClipVolumeHint

//------------------------------------------------------------------------

static void CheckForGLSLHardwareSupport( NSOpenGLPixelFormatAttribute *thePixelAttributes )
{
	// Create a pre-flight context to check for GLSL hardware support
	
	NSOpenGLPixelFormat  *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: thePixelAttributes];
	
	if ( pixelFormat != nil )
	{
		NSOpenGLContext *preflight = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
		
		if ( preflight != nil )
		{
			[preflight makeCurrentContext];
		
				CheckForShaders( thePixelAttributes );
				CheckForClipVolumeHint( thePixelAttributes );
		
			[preflight   release];
		} // if
	
		[pixelFormat release];
	} // if
} // CheckForGLSLHardwareSupport

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static void OpenGLSetupProjections()
{
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.3, 0.3, 0.0, 0.6, 1.0, 8.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0, 0.0, -2.0);
} // OpenGLSetupProjections

//------------------------------------------------------------------------

static void OpenGLSetupBlending()
{
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
} // OpenGLSetupBlending

//------------------------------------------------------------------------

static void OpenGLSetup( const GLboolean setupBlending )
{
	// For some OpenGL implementations, texture coordinates generated during rasterization 
	// aren't perspective correct. However, you can usually make them perspective correct 
	// by calling glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST). Colors generated at the 
	// rasterization stage aren't perspective correct in almost every OpenGL implementation, 
	// and can't be made so. For this reason, you're more likely to encounter this problem 
	// with colors than texture coordinates.
	
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
	
	// Set up the projection

	OpenGLSetupProjections();

	// Use blending
	
	if ( setupBlending )
	{
		OpenGLSetupBlending();
	} // if
	
	// Turn on depth test
	
    glEnable( GL_DEPTH_TEST );
	
	// front- or back-facing facets can be culled
	
    glEnable( GL_CULL_FACE );
} // OpenGLSetup

//------------------------------------------------------------------------

static void OpenGLNoError( )
{
    while( glGetError() != GL_NO_ERROR )
	{
		;
	} // while
} // OpenGLNoError

//------------------------------------------------------------------------

static void OpenGLDisableCapabilitiesForCopy( )
{
	glDisable(GL_COLOR_TABLE);
	glDisable(GL_CONVOLUTION_1D);
	glDisable(GL_CONVOLUTION_2D);
	glDisable(GL_HISTOGRAM);
	glDisable(GL_MINMAX);
	glDisable(GL_POST_COLOR_MATRIX_COLOR_TABLE);
	glDisable(GL_POST_CONVOLUTION_COLOR_TABLE);
	glDisable(GL_SEPARABLE_2D);
} // OpenGLDisableCapabilitiesForCopy

//------------------------------------------------------------------------

static void OpenGLPixelMap( )
{
	GLfloat values = 0.0f;
	
	glPixelMapfv(GL_PIXEL_MAP_R_TO_R, 1, &values);
	glPixelMapfv(GL_PIXEL_MAP_G_TO_G, 1, &values);
	glPixelMapfv(GL_PIXEL_MAP_B_TO_B, 1, &values);
	glPixelMapfv(GL_PIXEL_MAP_A_TO_A, 1, &values);
} // OpenGLPixelMap

//------------------------------------------------------------------------

static void OpenGLPixelStore( NSPoint *origin, NSRect *rect1, NSRect *rect2 )
{
	glPixelStorei(GL_PACK_SWAP_BYTES, 0);
	glPixelStorei(GL_PACK_LSB_FIRST, 0);
	glPixelStorei(GL_PACK_IMAGE_HEIGHT, 0);
	glPixelStoref(GL_PACK_ROW_LENGTH, NSWidth(*rect2)); 
	glPixelStoref(GL_PACK_SKIP_PIXELS, origin->x);
	glPixelStoref(GL_PACK_SKIP_ROWS, NSHeight(*rect2) - (origin->y + NSHeight(*rect1)));
	glPixelStorei(GL_PACK_SKIP_IMAGES, 0);
} // OpenGLPixelStore

//------------------------------------------------------------------------

static void OpenGLPixelTransfer( )
{
	glPixelTransferi(GL_MAP_COLOR, 0);
	glPixelTransferf(GL_RED_SCALE, 1.0f);
	glPixelTransferf(GL_RED_BIAS, 0.0f);
	glPixelTransferf(GL_GREEN_SCALE, 1.0f);
	glPixelTransferf(GL_GREEN_BIAS, 0.0f);
	glPixelTransferf(GL_BLUE_SCALE, 1.0f);
	glPixelTransferf(GL_BLUE_BIAS, 0.0f);
	glPixelTransferf(GL_ALPHA_SCALE, 1.0f);
	glPixelTransferf(GL_ALPHA_BIAS, 0.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_RED_SCALE, 1.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_RED_BIAS, 0.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_SCALE, 1.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_BIAS, 0.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_SCALE, 1.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_BIAS, 0.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_SCALE, 1.0f);
	glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_BIAS, 0.0f);
} // OpenGLPixelTransfer

//------------------------------------------------------------------------

static inline void OpenGLReadRGBAPixels( NSRect *rect, GLvoid *pixels )
{
	GLint    x      = (GLint) NSMinX(*rect);
	GLint    y      = (GLint) NSMinY(*rect);
	GLsizei  width  = (GLsizei) NSWidth(*rect);
	GLsizei  height = (GLsizei) NSHeight(*rect);
	GLenum   format = GL_RGBA;
	GLenum   type   = GL_UNSIGNED_BYTE;

	glReadPixels( x, y, width, height, format, type, pixels );
} // OpenGLReadRGBAPixels

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static GLvoid CGImageBitmapMemset( CGImageBitmap *imageBitmap )
{
	imageBitmap->imageBitsPerPixel     = 0;
	imageBitmap->imageBitsPerComponent = 0;
	imageBitmap->imageSamplesPerPixel  = 0;
	imageBitmap->imageBitmapInfo       = 0;
	imageBitmap->imageStorageSize      = 0;
	imageBitmap->imageBuffer.width     = 0;
	imageBitmap->imageBuffer.height    = 0;
	imageBitmap->imageBuffer.rowBytes  = 0;
	imageBitmap->imageBuffer.data      = NULL;
} // CGImageBitmapMemset

//------------------------------------------------------------------------

static BOOL CGImageBitmapMalloc( CGImageRef imageRef, CGImageBitmap *imageBitmap )
{
	BOOL  imageBitmapAllocated = NO;
	
	imageBitmap->imageBitsPerPixel     = 32;
	imageBitmap->imageBitsPerComponent = 8;
	imageBitmap->imageSamplesPerPixel  = 4;
	imageBitmap->imageBitmapInfo       = kCGImageAlphaPremultipliedLast; // RGBA
	imageBitmap->imageBuffer.width     = CGImageGetWidth( imageRef );
	imageBitmap->imageBuffer.height    = CGImageGetHeight( imageRef );
	imageBitmap->imageBuffer.rowBytes  = imageBitmap->imageBuffer.width * imageBitmap->imageSamplesPerPixel;
	imageBitmap->imageStorageSize      = imageBitmap->imageBuffer.rowBytes * imageBitmap->imageBuffer.height;
	imageBitmap->imageBuffer.data      = (GLvoid *)malloc( imageBitmap->imageStorageSize );
	
	if ( imageBitmap->imageBuffer.data != NULL )
	{
		imageBitmapAllocated = YES;
	} // if
	else
	{
		CGImageBitmapMemset( imageBitmap );
	} // else
	
	return imageBitmapAllocated;
} // CGImageBitmapMalloc

//------------------------------------------------------------------------

static BOOL CGImageBitmapFree( CGImageBitmap *imageBitmap )
{
	BOOL  imageBitmapFreed = NO;
	
	if ( imageBitmap->imageBuffer.data != NULL )
	{
		free( imageBitmap->imageBuffer.data );
		
		imageBitmapFreed = YES;
	} // if
	
	CGImageBitmapMemset( imageBitmap );
	
	return imageBitmapFreed;
} // CGImageBitmapFree

//------------------------------------------------------------------------

static CGContextRef CGImageBitmapContexMalloc( CGImageBitmap *imageBitmap )
{
	CGContextRef     imageContextRef    = NULL;
	CGColorSpaceRef  imageColorSpaceRef = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );

	if ( imageColorSpaceRef != NULL )
	{
		imageContextRef = CGBitmapContextCreate( imageBitmap->imageBuffer.data, 
												 imageBitmap->imageBuffer.width, 
												 imageBitmap->imageBuffer.height, 
												 imageBitmap->imageBitsPerComponent,
												 imageBitmap->imageBuffer.rowBytes, 
												 imageColorSpaceRef, 
						 						 imageBitmap->imageBitmapInfo 
											   );
		
		CGColorSpaceRelease( imageColorSpaceRef );
	} // if

	return  imageContextRef;
} // CGImageBitmapContexMalloc

//------------------------------------------------------------------------

static BOOL CGImageBitmapVerticalReflect( CGImageRef imageRef, CGImageBitmap *imageBitmap )
{
	BOOL          imageBitmapReflected = NO;
	CGContextRef  imageContextRef      = CGImageBitmapContexMalloc( imageBitmap );

	if ( imageContextRef != NULL )
	{
		CGRect imageRect = { { 0, 0 }, { imageBitmap->imageBuffer.width, imageBitmap->imageBuffer.height } };

		// The alpha will be added here
		
		CGContextDrawImage( imageContextRef, imageRect, imageRef );
		
		vImageVerticalReflect_ARGB8888( &(imageBitmap->imageBuffer), &(imageBitmap->imageBuffer), kvImageNoFlags );

		CGContextRelease( imageContextRef );
		
		imageBitmapReflected = YES;
	} // if bitmap context
	
	return imageBitmapReflected;
} // CGImageBitmapVerticalReflect

//------------------------------------------------------------------------

static CGImageRef CGImageGetFromCGImageBitmap( CGImageBitmap  *imageBitmap )
{
	CGImageRef imageRef = NULL;
	
	// Create a data provider
	
	CGDataProviderRef imageDataProvider = CGDataProviderCreateWithData(	NULL,
																		imageBitmap->imageBuffer.data,
																		imageBitmap->imageStorageSize,
																		NULL );
	if ( imageDataProvider != NULL )
	{
		// Create a color space for the image
		
		CGColorSpaceRef imageColorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );

		if ( imageColorSpace != NULL )
		{
			// Create the actual image
			
			GLfloat                  *imageDecode            = NULL;
			bool                      imageShouldInterpolate = true;
			CGColorRenderingIntent    imageRenderingIntent   = kCGRenderingIntentDefault;
			
			imageRef = CGImageCreate(	imageBitmap->imageBuffer.width,
										imageBitmap->imageBuffer.height,
										imageBitmap->imageBitsPerComponent,
										imageBitmap->imageBitsPerPixel,
										imageBitmap->imageBuffer.rowBytes,
										imageColorSpace,
										imageBitmap->imageBitmapInfo,
										imageDataProvider,
										imageDecode,
										imageShouldInterpolate,
										imageRenderingIntent );

			// the image will retain the data provider & colorspace as needed, so we can release them now
			
			CGColorSpaceRelease( imageColorSpace );
		} //if
		
		CGDataProviderRelease( imageDataProvider );
	} // if
	
	return  imageRef;
} // CGImageGetFromCGImageBitmap

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static NSImage *NSImageGetFromCGImage( CGImageRef imageRef )
{
	NSImage  *image = nil;
	
	if ( imageRef != NULL )
	{
		NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);

		// Get the image dimensions
		
		imageRect.size.height = CGImageGetHeight( imageRef );
		imageRect.size.width  = CGImageGetWidth( imageRef );

		// Create a new image to receive the Quartz image data
		
		image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease]; 
		
		if ( image != nil )
		{
			[image lockFocus];

				// Get the Quartz context and draw
				
				CGContextRef  imageContextRef = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
				
				if ( imageContextRef != NULL )
				{
					CGContextDrawImage( imageContextRef, *(CGRect*)&imageRect, imageRef );
				} // if
				
			[image unlockFocus];
		} // if
	} // if
	
	return image;
} // NSImageGetFromCGImage

//------------------------------------------------------------------------

static NSImage *NSImageGetFromCGImageAddAlphaAndVerticalReflect( CGImageRef imageRefSrc )
{
	NSImage *imageDst = nil;
	
	if ( imageRefSrc != NULL )
	{
		CGImageBitmap  imageBitmap;
		
		if ( CGImageBitmapMalloc( imageRefSrc, &imageBitmap ) )
		{
			if ( CGImageBitmapVerticalReflect( imageRefSrc, &imageBitmap ) )
			{
				CGImageRef  imageRefDst = CGImageGetFromCGImageBitmap( &imageBitmap );
				
				if ( imageRefDst != NULL )
				{
					imageDst = NSImageGetFromCGImage( imageRefDst );
					
					CGImageRelease( imageRefDst );
				} // if
			} // if image vertical reflect
		} // if bitmap data
	} // if image ref
	
	return  imageDst;
} // NSImageGetFromCGImageAddAlphaAndVerticalReflect

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLView

//------------------------------------------------------------------------

- (GLdouble) getExhibitChangeInTime:(GLdouble *)theLastTime
{
	GLdouble  deltaTime = 0.0;
	GLdouble  now       = (GLdouble)[NSDate timeIntervalSinceReferenceDate];

	if ( *theLastTime < 0 )
	{
		deltaTime = 0;
	} // if
	else
	{
		deltaTime = now - *theLastTime;
	} // else

	*theLastTime = now;
	
	return  deltaTime;
} // getExhibitChangeInTime

//------------------------------------------------------------------------

- (void) renderExhibit
{
	glPushMatrix( );

		glTranslatef(0.0f, 0.45f, 0.0f); 			
		glScalef(0.2f, 0.2f, 0.2f);

		if ( targetExhibit )
		{
			[targetExhibit renderFrame];
		} // if

	glPopMatrix( );
} // renderExhibit

//------------------------------------------------------------------------

- (void) setExhibitPitch
{
	if (pitch < -45.0f)
	{
		pitch = -45.0f;
	} // if
	else if (pitch > 90.0f)
	{
		pitch = 90.0f;
	} // else if

	glRotatef(pitch, 1.0f, 0.0f, 0.0f);
} // setExhibitPitch

//------------------------------------------------------------------------

- (void) setExhibitAngle
{
	if ( !leftMouseIsDown && !rightMouseIsDown )
	{
		GLdouble deltaTime = [self getExhibitChangeInTime:&lastFrameReferenceTime];

		angle += kViewRotationDegreesPerSecond * deltaTime;
		
		if ( angle >= 360.0f )
		{
			angle -= 360.0f;
		} // if
	} // if
	
	glRotatef( angle, 0.0f, 1.0f, 0.0f );
} // setExhibitAngle

//------------------------------------------------------------------------

-(void) rotateExhibit
{
	glPushMatrix( );
	
		// Constant rotation of the subject
		
		[self setExhibitPitch];
		
		glTranslatef(0.0f, -0.5f, -0.15f);

		[self setExhibitAngle];

		// Draw the exhibit
		
		[self renderExhibit];

	glPopMatrix( );
} // rotateExhibit

//------------------------------------------------------------------------

- (void) setExhibitPrespectiveMatrix:(GLfloat)theWidth  boundsHeight:(GLfloat)theHeight
{
	GLfloat   aspect =  theWidth / theHeight;
	GLdouble  right  =  0.15 * aspect * zoom;
	GLdouble  left   = -right;
	GLdouble  top    =  0.15 * zoom;
	GLdouble  bottom = -top;
	GLdouble  zNear  =  1.0;
	GLdouble  zFar   =  8.0;

	glMatrixMode( GL_PROJECTION );
	
		glLoadIdentity( );
		glFrustum( left, right, bottom, top, zNear, zFar );
		
	glMatrixMode( GL_MODELVIEW );
} // setExhibitPrespectiveMatrix

//------------------------------------------------------------------------

- (void) setExhibitViewport
{
	NSRect   theBounds = [self bounds];
	GLfloat  theWidth  = NSWidth(theBounds);
	GLfloat  theHeight = NSHeight(theBounds);

	[self setExhibitPrespectiveMatrix:theWidth boundsHeight:theHeight];
	
	glViewport( 0, 0, theWidth, theHeight );
} // setExhibitViewport

//------------------------------------------------------------------------

- (void) drawExhibit
{
	[[self openGLContext] makeCurrentContext];
	
	[self setExhibitViewport];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	[self rotateExhibit];
} // drawExhibit

//------------------------------------------------------------------------

- (void) updateExhibit
{
	[self drawExhibit];
	[self setNeedsDisplay:YES];
} // updateExhibit

//------------------------------------------------------------------------

- (void) setExhibit: (OpenGLExhibit *) newExhibit
{
	if ( newExhibit ) 
	{
		[targetExhibit release];
		targetExhibit = [newExhibit retain];
	} // if
} // setExhibit

//------------------------------------------------------------------------

-(void) setupOpenGL
{
	OpenGLSetup( GL_FALSE );
} // setupOpenGL

//------------------------------------------------------------------------

- (void) newUpdateTimer
{	
	GLint  swapInterval = 1;
	
	timer = [NSTimer timerWithTimeInterval: kScheduledTimerInSeconds 
						target: self
						selector: @selector(updateExhibit) 
						userInfo: nil
						repeats: YES];
	
	[timer retain];

	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSEventTrackingRunLoopMode];
	
	lastFrameReferenceTime = -1;
	leftMouseIsDown        = NO;
	rightMouseIsDown       = NO;

	angle = 0;
	pitch = 25;
	zoom  = 1;

	// Sync to VBL to avoid tearing.
		
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
} // newUpdateTimer

//------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)theFrame pixelFormat:(NSOpenGLPixelFormat*)thePixelFormat
{	
	// Create a GL Context to use - i.e. init the superclass
	
	if( thePixelFormat == nil )
	{
		NSOpenGLPixelFormatAttribute pixelAttributes [] 
												=	{
														NSOpenGLPFADoubleBuffer,
														NSOpenGLPFADepthSize, 24,
														NSOpenGLPFAStencilSize, 8,
														0
													};

		CheckForGLSLHardwareSupport( pixelAttributes );
		
		thePixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes: pixelAttributes] autorelease];
	} //  if
		
	if ( ( self = [super initWithFrame:theFrame pixelFormat:thePixelFormat] ) )
	{
		// Basic GL initializations
		
		[[self openGLContext] makeCurrentContext];
		
		[self setupOpenGL];
		
		// Basic initializations
		
		[self setFrameSize:theFrame.size];

		// Create an update timer
		
		[self newUpdateTimer];
		
		// Did the frame change?
		
		[self setPostsFrameChangedNotifications:YES];
	} // if	
	
	return self;
} // initWithFrame

//------------------------------------------------------------------------

- (id)init 
{
    if ( ( self = [super init] ) ) 
	{
		// superclass may return nil
		
        targetExhibit = nil;
		timer         = nil;
    } // if
	
    return self;
} // init

//------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)theFrame
{
	return [self initWithFrame:theFrame pixelFormat:nil];
} // initWithFrame

- (void)update		// moved or resized
{
	[super update];
	[self drawExhibit];
} // update

//------------------------------------------------------------------------

- (void)reshape	// scrolled, moved or resized
{
	[super reshape];
	[self drawExhibit];
} // reshape

//------------------------------------------------------------------------

- (void) dealloc
{
	// Release the update timer
	
	if (timer) 
	{
		[timer invalidate];
		[timer release];
	} // if
	
	//Dealloc the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (void) drawRect: (NSRect) theRect
{
	[[self openGLContext] flushBuffer];
} // drawRect

//------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)event
{
	lastMousePoint  = [self convertPoint:[event locationInWindow] fromView:nil];
	leftMouseIsDown = YES;
} // mouseDown

//------------------------------------------------------------------------

- (void)rightMouseDown:(NSEvent *)event
{
	lastMousePoint   = [self convertPoint:[event locationInWindow] fromView:nil];
	rightMouseIsDown = YES;
} // rightMouseDown

//------------------------------------------------------------------------

- (void)mouseUp:(NSEvent *)event
{
	leftMouseIsDown = NO;
} // mouseUp

//------------------------------------------------------------------------

- (void)rightMouseUp:(NSEvent *)event
{
	rightMouseIsDown = NO;
} // rightMouseUp

//------------------------------------------------------------------------

- (void)mouseDragged:(NSEvent *)event
{
	if ( [event modifierFlags] & NSRightMouseDown )
	{
		[self rightMouseDragged:event];
	} // if
	else
	{
		NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];

		pitch += lastMousePoint.y - mouse.y;
		angle -= lastMousePoint.x - mouse.x;

		lastMousePoint = mouse;
		
		[self setNeedsDisplay:YES];
	} // else
} // mouseDragged

//------------------------------------------------------------------------

- (void)rightMouseDragged:(NSEvent *)event
{
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];

	zoom += 0.01f * (lastMousePoint.y - mouse.y);
	
	if (zoom < 0.05f)
	{
		zoom = 0.05f;
	} // if
	else if (zoom > 2.0f)
	{
		zoom = 2.0f;
	} // else if

	lastMousePoint = mouse;

	[self setNeedsDisplay:YES];
} // rightMouseDragged

//------------------------------------------------------------------------

- (void)pageLayoutDidEnd: (NSPageLayout *)pageLayout returnCode: (int)returnCode contextInfo: (id)printInfo
{
    if(returnCode == NSOKButton) 
	{
        [NSPrintInfo setSharedPrintInfo: printInfo];
    } // if
} // pageLayoutDidEnd

//------------------------------------------------------------------------

- (void)runPageLayout: (id)sender
{
   NSPageLayout  *pageLayout = [NSPageLayout pageLayout];
   NSPrintInfo   *printInfo  = [NSPrintInfo sharedPrintInfo];
   
   [pageLayout beginSheetWithPrintInfo: printInfo
               modalForWindow: [self window]
               delegate: self
               didEndSelector: @selector(pageLayoutDidEnd:returnCode:contextInfo:)
               contextInfo: printInfo];
} // runPageLayout

//------------------------------------------------------------------------

- (void)copyPixelsTo: (GLvoid *)imageData sourceRect:(NSRect)srcRect baseView:(NSView *)view
{	
    NSRect    rect   = NSIntersectionRect([self bounds], srcRect);
	NSPoint   origin = [self convertPoint:rect.origin toView:view];
    GLvoid   *pixels = imageData;

    [self lockFocus];
	
		OpenGLNoError();
		
			glPushAttrib(GL_ALL_ATTRIB_BITS);
			
				glReadBuffer(GL_BACK);
				
				OpenGLDisableCapabilitiesForCopy( );
				
				OpenGLPixelMap( );
				OpenGLPixelStore( &origin, &rect, &srcRect );
				OpenGLPixelTransfer( );
				
				OpenGLReadRGBAPixels( &rect, pixels );
								
			glPopAttrib();
		
		// Get rid of any error, in order to not mislead the rest of the app
		
		OpenGLNoError();
	
    [self unlockFocus];
} // copyPixelsTo

//------------------------------------------------------------------------

- (NSImage *)getImageFromRect:(NSRect)rect
{
   if( NSIsEmptyRect(rect) )
   {
        rect = [self bounds];
   } // if
   
	NSImage *image = nil;
	
	GLuint   imageWidth           = NSWidth( rect );
	GLuint   imageHeight          = NSHeight( rect );
	GLuint   imageSamplesPerPixel = 4;
	GLuint   imageRowBytes        = imageWidth * imageSamplesPerPixel;
	GLuint   imageStorageSize     = imageRowBytes * imageHeight;
	GLvoid  *imageData            = (GLvoid *)malloc( imageStorageSize );

	if ( imageData != NULL )
	{
		// Create a data provider
		
		CGDataProviderRef imageDataProvider = CGDataProviderCreateWithData(	NULL, imageData, imageStorageSize, NULL );
		
		if ( imageDataProvider != NULL )
		{
			// Create a color space for the image
			
			CGColorSpaceRef  imageColorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );

			if ( imageColorSpace != NULL )
			{
				// Create an empty CGImageRef so that we may utilize OpenGL read pixels to copy the
				// pixels from OpenGL view into this newly created CGImageRef
				
				GLuint                    imageBitsPerPixel      = 32;
				GLuint                    imageBitsPerComponent  = 8;
				GLfloat                  *imageDecode            = NULL;
				bool                      imageShouldInterpolate = true;
				CGColorRenderingIntent    imageRenderingIntent   = kCGRenderingIntentDefault;
				CGBitmapInfo              imageBitmapInfo        = kCGImageAlphaNone; // For now RGB; but later we'll fix the alpha
			
				CGImageRef imageRef = CGImageCreate(	imageWidth,
														imageHeight,
														imageBitsPerComponent,
														imageBitsPerPixel,
														imageRowBytes,
														imageColorSpace,
														imageBitmapInfo,
														imageDataProvider,
														imageDecode,
														imageShouldInterpolate,
														imageRenderingIntent );

				
				if ( imageRef != NULL )
				{
					[self copyPixelsTo:imageData sourceRect:rect baseView:self];
					
					// Get an NSImage from CGImageRef, add alpha (RGBA from RGB) and
					// vertically reflect the image
					
					image = NSImageGetFromCGImageAddAlphaAndVerticalReflect( imageRef );
					
					CGImageRelease( imageRef );
				} // if
				
				CGColorSpaceRelease( imageColorSpace );
			} //if
			
			CGDataProviderRelease( imageDataProvider );
		} // if
	} // if
	
	return  image;
} // getImageFromRect

//------------------------------------------------------------------------

- (void)print:(id)sender
{
	NSImage      *tiffImage = [self getImageFromRect:[self bounds]];
    NSImageView  *imageView = [[[NSImageView alloc] initWithFrame:[self bounds]] autorelease];
	
    [imageView setImage: tiffImage];
    
    if( imageView && tiffImage ) 
	{
        // setup some reasonable state for GL printing. To get better output results,
		// fine tune this section of the code for better scaling.
		
        NSPrintInfo *printinfo = [NSPrintInfo sharedPrintInfo];
		
        [printinfo setHorizontalPagination: NSAutoPagination];
        [printinfo setVerticalPagination: NSAutoPagination];
        [printinfo setTopMargin: 0.0f];
        [printinfo setBottomMargin: 0.0f];
        [printinfo setRightMargin: 7.0f];
        [printinfo setLeftMargin: 7.0f];
		
        if ([imageView bounds].size.height < [imageView bounds].size.width)
		{
            [printinfo setOrientation: NSLandscapeOrientation];
		} // if
        else
		{
            [printinfo setOrientation: NSPortraitOrientation];
		} // else
		
        // print imageView
		
        NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView: imageView printInfo: printinfo];
		
        [printOperation	runOperationModalForWindow: [self window]
                        delegate: nil
                        didRunSelector: nil
                        contextInfo: nil];
    } // if
	else
	{
        NSRunCriticalAlertPanel(@"Print Error",@"Could not generate image data for printing.", @"OK", nil, nil);
    } // else
} // sender

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

