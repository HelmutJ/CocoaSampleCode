//---------------------------------------------------------------------------
//
//	File: QTVisualContextKit.m
//
//  Abstract: Utility class for maintaining a QT visual context
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
#import "QTVisualContextKit.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct QTVisualContextAttributes
{
	GLuint              width;			// Width of the pixel buffer
	GLuint              height;			// Height of the pixel buffer
	QTVisualContextRef  context;		// Pixel buffer or texture visual context
};

typedef struct QTVisualContextAttributes   QTVisualContextAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -- Set Dictionary Values --

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

static BOOL DictionarySetValue( CFMutableDictionaryRef dict, CFStringRef key, SInt32 value )
{
	BOOL         setNumber = NO;
    CFNumberRef  number    = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &value);
	
    if ( number!= NULL )
	{
		CFDictionarySetValue( dict, key, number );

		CFRelease( number );
		
		setNumber = YES;
	} // if
	
    return setNumber;
} // DictionarySetValue

//---------------------------------------------------------------------------

static inline BOOL DictionarySetPixelBufferPixelFormatType( CFMutableDictionaryRef dict )
{
	BOOL setPixelBufferOptions = NO;
	
	#if __BIG_ENDIAN__
		setPixelBufferOptions = DictionarySetValue( dict, kCVPixelBufferPixelFormatTypeKey, k32ARGBPixelFormat );
	#else
		setPixelBufferOptions = DictionarySetValue( dict, kCVPixelBufferPixelFormatTypeKey, k32BGRAPixelFormat );
	#endif
	
	return  setPixelBufferOptions;
} // DictionarySetPixelBufferPixelFormatType

//---------------------------------------------------------------------------

static inline BOOL DictionarySetPixelBufferSize(	const GLuint            width,
													const GLuint            height,
													CFMutableDictionaryRef  dict )
{
	BOOL setSize = NO;

	setSize = DictionarySetValue( dict, kCVPixelBufferWidthKey, width );
	setSize = setSize && DictionarySetValue( dict, kCVPixelBufferHeightKey, height );
	
	return setSize;
} // DictionarySetPixelBufferSize

//---------------------------------------------------------------------------

static inline BOOL DictionarySetPixelBufferBytesPerRowAlignment( CFMutableDictionaryRef dict )
{
	BOOL setAlignment = NO;
	
	setAlignment = DictionarySetValue( dict, kCVPixelBufferBytesPerRowAlignmentKey, 1 );
	
	return  setAlignment;
} // DictionarySetPixelBufferSize

//---------------------------------------------------------------------------

static inline void DictionarySetPixelBufferOpenGLCompatibility( CFMutableDictionaryRef dict )
{
	CFDictionarySetValue(dict, kCVPixelBufferOpenGLCompatibilityKey, kCFBooleanTrue);
} // DictionarySetPixelBufferOpenGLCompatibility

//---------------------------------------------------------------------------

static BOOL DictionarySetPixelBufferOptions(	const GLuint            width,
												const GLuint            height,
												CFMutableDictionaryRef *pixelBufferOptions )
{
	BOOL  setPixelBufferOptions = NO;
	
    CFMutableDictionaryRef  pixelBufferDict
								= CFDictionaryCreateMutable(	kCFAllocatorDefault, 
																0,
																&kCFTypeDictionaryKeyCallBacks,
																&kCFTypeDictionaryValueCallBacks );

    if ( pixelBufferDict != NULL )
	{
		if ( DictionarySetPixelBufferPixelFormatType( pixelBufferDict ) )
		{
			if ( DictionarySetPixelBufferSize( width, height, pixelBufferDict ) )
			{
				if ( DictionarySetPixelBufferBytesPerRowAlignment( pixelBufferDict ) )
				{
					DictionarySetPixelBufferOpenGLCompatibility( pixelBufferDict );
					
					*pixelBufferOptions = pixelBufferDict;
					
					setPixelBufferOptions = YES;
				} // if
			} // if
		} // if
	} // if
	
	return  setPixelBufferOptions;
} // DictionarySetPixelBufferOptions

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation QTVisualContextKit

//---------------------------------------------------------------------------

#pragma mark -- Initialize QT Visual Context --

//---------------------------------------------------------------------------

- (CFMutableDictionaryRef) initQTVisualContextOptions
{
	CFMutableDictionaryRef  visualContextOptions = NULL;
    CFMutableDictionaryRef  pixelBufferOptions   = NULL;
												   
	BOOL  setPixelBufferOptions = DictionarySetPixelBufferOptions(	visualContext->width, 
																	visualContext->height,
																	&pixelBufferOptions );
	
	if ( pixelBufferOptions != NULL )
	{
		if ( setPixelBufferOptions )
		{
			visualContextOptions = CFDictionaryCreateMutable(	kCFAllocatorDefault, 
																0,
																&kCFTypeDictionaryKeyCallBacks,
																&kCFTypeDictionaryValueCallBacks );
			if ( visualContextOptions != NULL )
			{
				// set the pixel image attributes for the visual context
				
				CFDictionarySetValue(visualContextOptions,
									 kQTVisualContextPixelBufferAttributesKey,
									 pixelBufferOptions);
			} // if
		} // if
			
		CFRelease( pixelBufferOptions );
	} // if
	
	return  visualContextOptions;
} // initQTVisualContextOptions

//---------------------------------------------------------------------------

- (BOOL) initQTPixelBufferContext
{
    BOOL  visualContextIsValid = NO;

	CFMutableDictionaryRef visualContextOptions = [self initQTVisualContextOptions];
	
	if ( visualContextOptions != NULL )
	{
		CFAllocatorRef  allocator = kCFAllocatorDefault;
		
		OSStatus err = QTPixelBufferContextCreate(	allocator,
													visualContextOptions,
													&visualContext->context);

		if ( err == noErr )
		{
			visualContextIsValid = YES;
		} // if
		
		CFRelease( visualContextOptions );
	} // if
	
	return visualContextIsValid;
} // initQTPixelBufferContext

//---------------------------------------------------------------------------

- (BOOL) initQTOpenGLTextureContext:(NSOpenGLContext *)theOpenGLContext
						pixelFormat:(NSOpenGLPixelFormat *)theOpenGLPixelFormat

{
	BOOL  visualContextIsValid = NO;

	if ( ( theOpenGLContext != nil ) && ( theOpenGLPixelFormat != nil ) )
	{
		CFAllocatorRef     allocator      = kCFAllocatorDefault;
		CGLContextObj      cglContext     = (CGLContextObj)[theOpenGLContext CGLContextObj];
		CGLPixelFormatObj  cglPixelFormat = (CGLPixelFormatObj)[theOpenGLPixelFormat CGLPixelFormatObj];
		CFDictionaryRef    dictAttribs    = NULL;

		// Creates a new OpenGL texture context for a specified OpenGL context and pixel format
		
		OSStatus err = QTOpenGLTextureContextCreate(	allocator,					// an allocator to Create functions
														cglContext,					// the OpenGL context
														cglPixelFormat,				// pixelformat object that specifies 
																					// buffer types and other attributes 
																					// of the context
														dictAttribs,				// a CF Dictionary of attributes
														&visualContext->context );	// returned OpenGL texture context
		
		if ( err == noErr )
		{
			visualContextIsValid = YES;
		} // if
	} // if
	
	return  visualContextIsValid;
} // initQTOpenGLTextureContext

//---------------------------------------------------------------------------

- (BOOL) initQTVisualContext:(QTVisualContextType)theQTVisualContextType
					context:(NSOpenGLContext *)theOpenGLContext
					pixelFormat:(NSOpenGLPixelFormat *)theOpenGLPixelFormat
{
	BOOL visualContextIsValid = NO;
	
	switch( theQTVisualContextType )
	{
		case kQTPixelBufferContext:
			visualContextIsValid = [self initQTPixelBufferContext];
			break;
			
		case kQTOpenGLTextureContext:
		default:
			visualContextIsValid = [self initQTOpenGLTextureContext:theOpenGLContext 
														pixelFormat:theOpenGLPixelFormat];
	} // switch
	
	return  visualContextIsValid;
} // initQTVisualContext

//---------------------------------------------------------------------------
//
// Designated initializer
//
//---------------------------------------------------------------------------

- (id) initQTVisualContextWithSize:(NSSize)theSize
							type:(QTVisualContextType)theQTVisualContextType
							context:(NSOpenGLContext *)theOpenGLContext
							pixelFormat:(NSOpenGLPixelFormat *)theOpenGLPixelFormat
{
	self = [super initMemoryWithType:kMemAlloc size:sizeof(QTVisualContextAttributes)];
	
	if ( self )
	{
		visualContext = (QTVisualContextAttributesRef)[self pointer];
		
		if ( [self isPointerValid] )
		{
			visualContext->width  = (GLuint)theSize.width;
			visualContext->height = (GLuint)theSize.height;

			BOOL visualContextIsValid = [self initQTVisualContext:theQTVisualContextType 
															context:theOpenGLContext 
															pixelFormat:theOpenGLPixelFormat];
			
			if ( !visualContextIsValid )
			{
				[[AlertPanelKit withTitle:@"QTVisualContext Kit" 
								  message:@"Failure Obtaining a Visual Context"
									 exit:YES] displayAlertPanel];
			} // if
		} // if
		else
		{
			[[AlertPanelKit withTitle:@"QTVisualContext Kit" 
							  message:@"Failure Allocating Memory For Attributes"
								 exit:YES] displayAlertPanel];
		} // else
	} // if
	
	return self;
} // initQTVisualContextWithSize

//---------------------------------------------------------------------------

#pragma mark -- Cleanup all the Resources --

//---------------------------------------------------------------------------

- (void) dealloc 
{
	if ( visualContext->context != NULL )
	{
		QTVisualContextRelease( visualContext->context );
		
		visualContext->context = NULL;
	} // if

    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -- Utilities --

//---------------------------------------------------------------------------

- (BOOL) isValidVisualContext
{
	return  ( visualContext->context != NULL );
} // isValidVisualContext

//---------------------------------------------------------------------------

- (BOOL) isNewImageAvailable:(const CVTimeStamp *)theTimeStamp 
{
	BOOL newImageAvailable = NO;
	
	newImageAvailable 
		= QTVisualContextIsNewImageAvailable(	visualContext->context, 
												theTimeStamp );
	
	return  newImageAvailable; 
} // isNewImageAvailable

//---------------------------------------------------------------------------
//
// Get a "frame" (image image) from the Visual Context, indexed by the 
// provided time.
//
//---------------------------------------------------------------------------

- (CVImageBufferRef) copyImageForTime:(const CVTimeStamp *)theTimeStamp
{
	CVImageBufferRef  imageBuffer = NULL;
	CFAllocatorRef    allocator   = kCFAllocatorDefault;
	
	OSStatus status = QTVisualContextCopyImageForTime(	visualContext->context, 
														allocator, 
														theTimeStamp, 
														&imageBuffer );
														
	if ( ( status != noErr ) && ( imageBuffer != NULL ) )
	{
		CFRelease( imageBuffer );
		
		imageBuffer = NULL;
	} // if
	
	return  imageBuffer;
} // copyImageForTime

//---------------------------------------------------------------------------

- (BOOL) setMovie:(QTMovie *)theQTMovie
{
	BOOL  movieIsSet = NO;
	Movie movie      = [theQTMovie quickTimeMovie];
	
	if ( ( movie != NULL ) && ( *movie != NULL ) )
	{
		OSStatus status = SetMovieVisualContext(movie, visualContext->context);
		
		if ( status == noErr )
		{
			movieIsSet = YES;
		} // if
	} // if
	
	return  movieIsSet;
} // setMovie

//---------------------------------------------------------------------------
//
// Give time to the Visual Context so it can release internally held 
// resources for later re-use this function should be called in every 
// rendering pass, after old images have been released, new images 
// have been used and all rendering has been flushed to the screen.
//
//---------------------------------------------------------------------------

- (void) task
{
	QTVisualContextTask( visualContext->context );
} // task
 
//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
