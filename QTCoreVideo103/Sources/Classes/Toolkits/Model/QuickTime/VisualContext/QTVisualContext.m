//---------------------------------------------------------------------------
//
//	File: QTVisualContext.m
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
//  Copyright (c) 2008-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "QTVisualContext.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct QTVisualContextData
{
	GLuint width;                           // Width of the pixel buffer
	GLuint height;                          // Height of the pixel buffer
 	GLuint align;                           // Pixel alignment
	OSType format;                          // Pixel format
    
    CFMutableDictionaryRef  attributes;     // Visual context attributes
    CFMutableDictionaryRef  options;        // Visual context options
	QTVisualContextRef      context;        // Pixel buffer or texture visual context
};

typedef struct QTVisualContextData   QTVisualContextData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Dictionary

//---------------------------------------------------------------------------

static BOOL CFDictionarySetInteger(CFMutableDictionaryRef dict, 
                                   CFStringRef            key, 
                                   SInt32                 value)
{
    CFNumberRef  number    = CFNumberCreate(kCFAllocatorDefault, 
											kCFNumberSInt32Type,
											&value);
	
    BOOL success = number!= NULL;

    if( success )
	{
		CFDictionarySetValue( dict, key, number );
		
		CFRelease( number );
	} // if
	
    return success;
} // CFDictionarySetInteger

//---------------------------------------------------------------------------

static inline BOOL QTVisualContextDictionarySetPixelBufferPixelFormatType(QTVisualContextDataRef pVisualCtx)
{
	BOOL success = NO;
	
    success = CFDictionarySetInteger(pVisualCtx->attributes, 
                                     kCVPixelBufferPixelFormatTypeKey, 
                                     pVisualCtx->format);
    
	return  success;
} // QTVisualContextDictionarySetPixelBufferPixelFormatType

//---------------------------------------------------------------------------

static inline BOOL QTVisualContextDictionarySetPixelBufferSize(QTVisualContextDataRef pVisualCtx)
{
	BOOL success = NO;
	
	success = CFDictionarySetInteger(pVisualCtx->attributes, 
                                     kCVPixelBufferWidthKey,
                                     pVisualCtx->width);
    
	success = success && CFDictionarySetInteger(pVisualCtx->attributes,
                                                kCVPixelBufferHeightKey,
                                                pVisualCtx->height);
	
	return success;
} // QTVisualContextDictionarySetPixelBufferSize

//---------------------------------------------------------------------------

static inline BOOL QTVisualContextDictionarySetPixelBufferBytesPerRowAlignment(QTVisualContextDataRef pVisualCtx)
{
	BOOL success = NO;
	
	success = CFDictionarySetInteger(pVisualCtx->attributes, 
                                     kCVPixelBufferBytesPerRowAlignmentKey, 
                                     pVisualCtx->align);
	
	return  success;
} // QTVisualContextDictionarySetPixelBufferSize

//---------------------------------------------------------------------------

static inline void QTVisualContextDictionarySetPixelBufferOpenGLCompatibility(QTVisualContextDataRef pVisualCtx)
{
	CFDictionarySetValue(pVisualCtx->attributes, 
                         kCVPixelBufferOpenGLCompatibilityKey, 
                         kCFBooleanTrue);
} // QTVisualContextDictionarySetPixelBufferOpenGLCompatibility

//---------------------------------------------------------------------------

static void QTVisualContextDictionarySetIOSurfaceProperties(QTVisualContextDataRef pVisualCtx)
{
    CFMutableDictionaryRef  properties = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                                   0,
                                                                   &kCFTypeDictionaryKeyCallBacks,
                                                                   &kCFTypeDictionaryValueCallBacks);
    
    if( properties != NULL )
    {
        CFDictionarySetValue(pVisualCtx->attributes, 
                             kCVPixelBufferIOSurfacePropertiesKey, 
                             properties);
        
        CFDictionarySetValue(pVisualCtx->attributes, 
                             kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey, 
                             kCFBooleanTrue);
        
        CFDictionarySetValue(pVisualCtx->attributes, 
                             kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey, 
                             kCFBooleanTrue);
        
        CFRelease(properties);
    } // if
} // QTVisualContextDictionarySetIOSurfaceProperties

//---------------------------------------------------------------------------

static BOOL QTVisualContextDictionarySetPixelBufferAttributes(QTVisualContextDataRef pVisualCtx)
{
	BOOL  success = NO;
	
    pVisualCtx->attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                       0,
                                                       &kCFTypeDictionaryKeyCallBacks,
                                                       &kCFTypeDictionaryValueCallBacks );
	
    if( pVisualCtx->attributes != NULL )
	{
		if( QTVisualContextDictionarySetPixelBufferPixelFormatType(pVisualCtx) )
		{
			if( QTVisualContextDictionarySetPixelBufferSize(pVisualCtx) )
			{
				if( QTVisualContextDictionarySetPixelBufferBytesPerRowAlignment(pVisualCtx) )
				{
					QTVisualContextDictionarySetPixelBufferOpenGLCompatibility(pVisualCtx);
					QTVisualContextDictionarySetIOSurfaceProperties(pVisualCtx);
                    
					success = YES;
				} // if
			} // if
		} // if
	} // if
	
	return  success;
} // QTVisualContextDictionarySetPixelBufferAttributes

//---------------------------------------------------------------------------

static BOOL QTVisualContextDictionarySetOptions(QTVisualContextDataRef pVisualCtx)
{
	BOOL  success = QTVisualContextDictionarySetPixelBufferAttributes(pVisualCtx);
	
	if( success )
	{
        pVisualCtx->options = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                        1,
                                                        &kCFTypeDictionaryKeyCallBacks,
                                                        &kCFTypeDictionaryValueCallBacks);
        
        success = pVisualCtx->options != NULL;
        
        if( success )
        {
            // set the pixel image attributes for the visual context
            
            CFDictionarySetValue(pVisualCtx->options,
                                 kQTVisualContextPixelBufferAttributesKey,
                                 pVisualCtx->attributes);
        } // if
		
		CFRelease( pVisualCtx->attributes );
        
        pVisualCtx->attributes = NULL;
	} // if
    
    return success;
} // QTVisualContextDictionarySetOptions

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Initializers

//---------------------------------------------------------------------------

static void QTVisualContextInitParams(const GLuint alignment, 
                                      QTVisualContextDataRef pVisualCtx)
{
    pVisualCtx->align      = alignment;
    pVisualCtx->attributes = NULL;
    pVisualCtx->options    = NULL;
    pVisualCtx->context    = NULL;
    pVisualCtx->format     = 0;
} // QTVisualContextInitParams

//---------------------------------------------------------------------------

static void QTVisualContextInitSize(const NSSize *pSize, 
                                    QTVisualContextDataRef pVisualCtx)
{
    if( pSize != NULL )
    {
        pVisualCtx->width  = (GLuint)pSize->width;
        pVisualCtx->height = (GLuint)pSize->height;
    } // if
    else
    {
        pVisualCtx->width  = 1920;
        pVisualCtx->height = 1080;
    } // else
} // QTVisualContextInitSize

//---------------------------------------------------------------------------

static void QTVisualContextInitFormat(const char *pFormat, 
                                      QTVisualContextDataRef pVisualCtx)
{
    if( pFormat != NULL )
    {
        pVisualCtx->format = ((OSType)pFormat[0]) 
        | (((OSType)pFormat[1]) << 8) 
        | (((OSType)pFormat[2]) << 16) 
        | (((OSType)pFormat[3]) << 24);
    } // if
    else
    {
        pVisualCtx->format = kCVPixelFormatType_422YpCbCr8;
    } // else
} // QTVisualContextInitFormat

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static QTVisualContextDataRef QTVisualContextCreateForPixelBuffers(const GLuint alignment,
                                                                   const NSSize *pSize,
                                                                   const char *pFormat)
{
    QTVisualContextDataRef pVisualCtx = (QTVisualContextDataRef)calloc(1, sizeof(QTVisualContextData));
    
    if( pVisualCtx != NULL )
    {
        QTVisualContextInitParams(alignment, pVisualCtx);
        QTVisualContextInitSize(pSize, pVisualCtx);
        QTVisualContextInitFormat(pFormat, pVisualCtx);
        
        BOOL  success = QTVisualContextDictionarySetOptions(pVisualCtx);
        
        if( success )
        {
            OSStatus err = QTPixelBufferContextCreate(kCFAllocatorDefault,
                                                      pVisualCtx->options,
                                                      &pVisualCtx->context);
            
            CFRelease( pVisualCtx->options );
            
            pVisualCtx->options = NULL;
            
            if( err != noErr )
            {
                NSLog( @">> ERROR: QT Visual Context - Failed creating a context with oprions!" );
            } // if
        } // if
        else
        {
            NSLog( @">> ERROR: QT Visual Context - Failed creating options!" );
        } // if
    } // if
    else
    {
        NSLog( @">> ERROR: QT Visual Context - Failed allocating memory!" );
    } // else
	
	return ( pVisualCtx );
} // QTVisualContextCreateForPixelBuffers

//---------------------------------------------------------------------------

static QTVisualContextDataRef QTVisualContextCreateForTextures(const NSSize *pSize,
                                                               NSOpenGLContext *pContext,
                                                               NSOpenGLPixelFormat *pFormat)
{
    QTVisualContextDataRef pVisualCtx = NULL;
    
    if( ( pContext != nil ) && ( pFormat != nil ) )
    {
        pVisualCtx = (QTVisualContextDataRef)calloc(1, sizeof(QTVisualContextData));
        
        if( pVisualCtx != NULL )
        {
            CFAllocatorRef     allocator      = kCFAllocatorDefault;
            CGLContextObj      cglContext     = (CGLContextObj)[pContext CGLContextObj];
            CGLPixelFormatObj  cglPixelFormat = (CGLPixelFormatObj)[pFormat CGLPixelFormatObj];
            CFDictionaryRef    attributes     = NULL;
            
            QTVisualContextInitParams(0, pVisualCtx);
            QTVisualContextInitSize(pSize, pVisualCtx);

            // Creates a new OpenGL texture context for a specified OpenGL context and pixel format
            
            OSStatus err = QTOpenGLTextureContextCreate(allocator,					// an allocator to Create functions
                                                        cglContext,					// the OpenGL context
                                                        cglPixelFormat,				// pixelformat object that specifies 
                                                                                    // buffer types and other attributes 
                                                                                    // of the context
                                                        attributes,                 // a CF Dictionary of attributes
                                                        &pVisualCtx->context );     // returned OpenGL texture context
            
            if( err != noErr )
            {
                NSLog( @">> ERROR: QT Visual Context - Failed creating a context for textures!" );
            } // if
        } // if
        else
        {
            NSLog( @">> ERROR: QT Visual Context - Failure Allocating Memory!" );
        } // else
    } // if

	return ( pVisualCtx );
} // QTVisualContextCreateForTextures

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void QTVisualContextDelete(QTVisualContextDataRef pVisualCtx) 
{
    if( pVisualCtx != NULL )
    {
        if( pVisualCtx->context != NULL )
        {
            QTVisualContextRelease( pVisualCtx->context );
            
            pVisualCtx->context = NULL;
        } // if
        
        free( pVisualCtx );
        
        pVisualCtx = NULL;
    } // if
} // QTVisualContextDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Pribvate - Utilities

//---------------------------------------------------------------------------

static BOOL QTVisualContextQueryForNewImage(const CVTimeStamp *pTimeStamp,
                                                   QTVisualContextDataRef pVisualCtx)
{
	BOOL success = pTimeStamp != NULL;
    
    if( success )
    {
        success = QTVisualContextIsNewImageAvailable(pVisualCtx->context, 
                                                     pTimeStamp );
	} // if
    
	return  success; 
} // QTVisualContextQueryForNewImage

//---------------------------------------------------------------------------
//
// Get a "frame" (image image) from the Visual Context, indexed by the 
// provided time.
//
//---------------------------------------------------------------------------

static CVImageBufferRef QTVisualContextCopyImageBuffer(const CVTimeStamp *pTimeStamp,
                                                       QTVisualContextDataRef pVisualCtx)
{
	CVImageBufferRef  pImageBuffer = NULL;
    
    if( pTimeStamp != NULL )
    {
        CFAllocatorRef allocator = kCFAllocatorDefault;
        
        OSStatus status = QTVisualContextCopyImageForTime(pVisualCtx->context, 
                                                          allocator, 
                                                          pTimeStamp, 
                                                          &pImageBuffer );
        
        if( ( status != noErr ) && ( pImageBuffer != NULL ) )
        {
            CFRelease( pImageBuffer );
            
            pImageBuffer = NULL;
        } // if
	} // if
    
	return( pImageBuffer );
} // QTVisualContextCopyImageBuffer

//---------------------------------------------------------------------------

static BOOL QTVisualContextSetMovie(QTMovie *pQTMovie,
                                    QTVisualContextDataRef pVisualCtx)
{
	BOOL success = NO;
    
    if( pQTMovie )
    {
        Movie movie = [pQTMovie quickTimeMovie];
        
        if( ( movie != NULL ) && ( *movie != NULL ) )
        {
            OSStatus status = SetMovieVisualContext(movie, 
                                                    pVisualCtx->context);
            
            success = status == noErr;
        } // if
    } // if
	
	return( success );
} // QTVisualContextSetMovie

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation QTVisualContext

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------
//
// Designated initializer
//
//---------------------------------------------------------------------------

- (id) initQTVisualContextWithSize:(const NSSize *)theSize
                            format:(const char *)theFormat
                         alignment:(const GLuint)theAlignment
{
	self = [super init];
	
	if( self )
	{
		mpVisualCtx = QTVisualContextCreateForPixelBuffers(theAlignment, 
                                                           theSize, 
                                                           theFormat);
	} // if
	
	return self;
} // initQTVisualContextWithSize

//---------------------------------------------------------------------------

- (id) initQTVisualContextWithSize:(const NSSize *)theSize
						   context:(NSOpenGLContext *)theContext
                            format:(NSOpenGLPixelFormat *)thePixelFormat
{
	self = [super init];
	
	if( self )
	{
		mpVisualCtx = QTVisualContextCreateForTextures(theSize,
                                                       theContext,
                                                       thePixelFormat);
	} // if
	
	return self;
} // initQTVisualContextWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    QTVisualContextDelete(mpVisualCtx);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) isValidVisualContext
{
	return  ( mpVisualCtx->context != NULL );
} // isValidVisualContext

//---------------------------------------------------------------------------

- (BOOL) isNewImageAvailable:(const CVTimeStamp *)theTimeStamp 
{
	return( QTVisualContextQueryForNewImage(theTimeStamp, mpVisualCtx) ); 
} // isNewImageAvailable

//---------------------------------------------------------------------------

- (CVImageBufferRef) copyImageForTime:(const CVTimeStamp *)theTimeStamp
{
	return( QTVisualContextCopyImageBuffer(theTimeStamp, mpVisualCtx) );
} // copyImageForTime

//---------------------------------------------------------------------------

- (BOOL) setMovie:(QTMovie *)theQTMovie
{
	return( QTVisualContextSetMovie(theQTMovie, mpVisualCtx) );
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
	QTVisualContextTask( mpVisualCtx->context );
} // task

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
