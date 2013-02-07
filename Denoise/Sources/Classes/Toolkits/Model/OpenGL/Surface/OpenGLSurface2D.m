//---------------------------------------------------------------------------
//
//	File: OpenGLSurface2D.m
//
//  Abstract: Utility toolkit for 2D I/O surfaces. 
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
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLImage2DBuffer.h"
#import "OpenGLUtilities.h"
#import "OpenGLCopier.h"

#import "OpenGLSurface2D.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct IOSurface2DBuffer
{
	GLenum                  format;     // Texture format
    GLenum                  type;       // Texture type
    GLuint                  plane;      // I/O surface plane
    IOSurfaceRef            data;       // I/O surface backing store
    CFMutableDictionaryRef  props;      // I/O surface properties
};

typedef struct IOSurface2DBuffer  IOSurface2DBuffer;

//---------------------------------------------------------------------------

struct OpenGLSurface2DData
{
    BOOL                 isVideo;       // Texture is video format
    BOOL                 isBGRA;        // Texture is BGRA format
    BOOL                 hasSufrace;    // Uses I/O surface
    BOOL                 hasBuffer;     // Uses memory buffer
    GLvoid              *base;          // Base address of the buffer
    IOSurface2DBuffer    surface;       // I/O surface buffer
    OpenGLImage2DBuffer  buffer;        // Image 2D memeory buffer
    OpenGLCopier        *copier;        // For Memory copy
};

typedef struct OpenGLSurface2DData  OpenGLSurface2DData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Dictionary

//---------------------------------------------------------------------------

static void OpenGLSurface2DSetInteger(const int value,
                                      CFStringRef key,
                                      OpenGLSurface2DDataRef pSurface2D)
{
    CFNumberRef  number = CFNumberCreate(kCFAllocatorDefault, 
                                         kCFNumberIntType,
                                         &value);
	
    if( number!= NULL )
	{
		CFDictionarySetValue(pSurface2D->surface.props, 
                             key, 
                             number );
		
		CFRelease( number );
	} // if
} // OpenGLSurface2DSetInteger

//---------------------------------------------------------------------------

static inline void OpenGLSurface2DSetBoolean(CFBooleanRef value, 
                                             CFStringRef key,
                                             OpenGLSurface2DDataRef pSurface2D)
{
    CFDictionarySetValue(pSurface2D->surface.props, 
                         key, 
                         value);
} // OpenGLSurface2DSetBoolean

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initializers - I/O surface

//---------------------------------------------------------------------------

static BOOL OpenGLSurface2DCreateSurfaceOptions(OpenGLSurface2DDataRef pSurface2D)
{
    pSurface2D->surface.props = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                          5,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
    
    return( pSurface2D->surface.props != NULL );
} // OpenGLSurface2DCreateSurfaceOptions

//---------------------------------------------------------------------------
//
// Format              Type                           Internal   Sized
//                                                    Format     Internal
//                                                               Format
//---------------------------------------------------------------------------
//
// Non-linear RGBA
//----------------
// GL_BGRA             GL_UNSIGNED_INT_8_8_8_8_REV   GL_RGBA     GL_RGBA8
//
// "Video" format
// ---------------
// GL_YCBCR_422_APPLE  GL_UNSIGNED_SHORT_8_8_APPLE   GL_RGB      GL_RGB8
//
//---------------------------------------------------------------------------

static void OpenGLSurface2DSetFormat(const GLenum format,
                                     OpenGLSurface2DDataRef pSurface2D)
{
    BOOL isVideo = format == GL_YCBCR_422_APPLE;
    BOOL isBGRA  = format == GL_BGRA;
    BOOL isValid = isVideo || isBGRA;
    
    pSurface2D->isVideo = isVideo;
    pSurface2D->isBGRA  = isBGRA;
    
    pSurface2D->surface.format = isValid ? format : GL_BGRA;
    pSurface2D->surface.type   = isVideo ? GL_UNSIGNED_SHORT_8_8_APPLE : GL_UNSIGNED_INT_8_8_8_8_REV;
} // OpenGLSurface2DSetFormat

//---------------------------------------------------------------------------

static void OpenGLSurface2DSetSize(const GLuint width,
                                   const GLuint height,
                                   OpenGLSurface2DDataRef pSurface2D)
{
    pSurface2D->buffer.width    = width; 
    pSurface2D->buffer.height   = height; 
    pSurface2D->buffer.spp      = OpenGLUtilitiesGetSPP(pSurface2D->surface.type);
	pSurface2D->buffer.rowBytes = pSurface2D->buffer.width  * pSurface2D->buffer.spp;
	pSurface2D->buffer.size     = pSurface2D->buffer.height * pSurface2D->buffer.rowBytes;
} // OpenGLSurface2DSetSize

//---------------------------------------------------------------------------

static void OpenGLSurface2DCreateOptions(const BOOL isGlobal,
                                         OpenGLSurface2DDataRef pSurface2D)
{
    OpenGLSurface2DSetInteger(pSurface2D->buffer.width,
                              kIOSurfaceWidth, 
                              pSurface2D);
    
    OpenGLSurface2DSetInteger(pSurface2D->buffer.height,
                              kIOSurfaceHeight, 
                              pSurface2D);
    
    OpenGLSurface2DSetInteger(pSurface2D->buffer.spp,
                              kIOSurfaceBytesPerElement, 
                              pSurface2D);
    
    if( pSurface2D->isVideo )
    {
        OpenGLSurface2DSetInteger(kCVPixelFormatType_422YpCbCr8,
                                  kIOSurfacePixelFormat, 
                                  pSurface2D);
    } // if
    else
    {
        OpenGLSurface2DSetInteger(kCVPixelFormatType_32BGRA,
                                  kIOSurfacePixelFormat, 
                                  pSurface2D);
    } // else
    
    if( isGlobal )
    {
        OpenGLSurface2DSetBoolean(kCFBooleanTrue, 
                                  kIOSurfaceIsGlobal,
                                  pSurface2D);
    } // if
    else
    {
        OpenGLSurface2DSetBoolean(kCFBooleanFalse, 
                                  kIOSurfaceIsGlobal,
                                  pSurface2D);
    } // else
} // OpenGLSurface2DCreateOptions

//---------------------------------------------------------------------------

static void OpenGLSurface2DCreateSurface(OpenGLSurface2DDataRef pSurface2D)
{    
    pSurface2D->surface.data = IOSurfaceCreate(pSurface2D->surface.props);
    
    pSurface2D->hasSufrace = pSurface2D->surface.data != NULL;
    
    if( pSurface2D->hasSufrace )
    {
        pSurface2D->base = IOSurfaceGetBaseAddressOfPlane(pSurface2D->surface.data, 0);
    } // if
    else
    {
        NSLog(@">> WARNING: OpenGL Surface 2D - Failed creating I/O surface with properties \n{\n%@\n}!", 
              pSurface2D->surface.props);
        
        NSLog(@">> MESSAGE: OpenGL Surface 2D - Will try allocating using malloc!");
        
        pSurface2D->buffer.data = calloc(1, pSurface2D->buffer.size);
        
        pSurface2D->hasBuffer = pSurface2D->buffer.data != NULL;
        
        if( pSurface2D->hasBuffer )
        {
            pSurface2D->base = pSurface2D->buffer.data;
        } // if
        else
        {
            NSLog(@">> ERROR: OpenGL Surface 2D - Failed creating a backing store!");
        } // else
    } // else
    
    CFRelease(pSurface2D->surface.props);
    
    pSurface2D->surface.props = NULL;
} // OpenGLSurface2DCreateSurface

//---------------------------------------------------------------------------

static inline void OpenGLSurface2DCreateCopier(OpenGLSurface2DDataRef pSurface2D)
{
    pSurface2D->copier = [[OpenGLCopier alloc] initCopierWithFormat:pSurface2D->surface.format 
                                                              width:pSurface2D->buffer.width 
                                                             height:pSurface2D->buffer.height];    
} // OpenGLSurface2DCreateCopier

//---------------------------------------------------------------------------

static void OpenGLSurface2DCreateAssets(const GLuint width,
                                        const GLuint height,
                                        const GLenum format,
                                        const BOOL isGlobal,
                                        OpenGLSurface2DDataRef pSurface2D)
{    
    if( OpenGLSurface2DCreateSurfaceOptions(pSurface2D) )
    {
        OpenGLSurface2DSetFormat(format, pSurface2D);
        OpenGLSurface2DSetSize(width, height, pSurface2D);
        OpenGLSurface2DCreateOptions(isGlobal, pSurface2D);
        OpenGLSurface2DCreateSurface(pSurface2D);
        OpenGLSurface2DCreateCopier(pSurface2D);
    } // if
} // OpenGLSurface2DCreateAssets

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static OpenGLSurface2DDataRef OpenGLSurface2DCreateWithSize(const GLuint width,
                                                            const GLuint height,
                                                            const GLenum format,
                                                            const BOOL isGlobal)
{
    OpenGLSurface2DDataRef pSurface2D = (OpenGLSurface2DDataRef)calloc(1, sizeof(OpenGLSurface2DData));
    
    if( pSurface2D != NULL )
    {
        OpenGLSurface2DCreateAssets(width, 
                                    height, 
                                    format, 
                                    isGlobal, 
                                    pSurface2D);
    } // if
    else
    {
        NSLog(@">> ERROR: OpenGL Surface 2D - Failed allocating memory for 2D a surface backing store!");
    }  // else
	
	return( pSurface2D );
} // OpenGLSurface2DCreateWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLSurface2DDeleteSurface(OpenGLSurface2DDataRef pSurface2D) 
{
    if( pSurface2D->surface.data != NULL )
    {
        CFRelease(pSurface2D->surface.data);
        
        pSurface2D->surface.data = NULL;
    } // if
} // OpenGLSurface2DDeleteSurface

//---------------------------------------------------------------------------

static void OpenGLSurface2DDeleteBuffer(OpenGLSurface2DDataRef pSurface2D) 
{
    if( pSurface2D->buffer.data != NULL )
    {
        free(pSurface2D->buffer.data);
        
        pSurface2D->buffer.data = NULL;
    } // if
} // OpenGLSurface2DDeleteBuffer

//---------------------------------------------------------------------------

static void OpenGLSurface2DDeleteCopier(OpenGLSurface2DDataRef pSurface2D) 
{
    if( pSurface2D->copier )
    {
        [pSurface2D->copier release];
        
        pSurface2D->copier = nil;
    } // if
} // OpenGLSurface2DDeleteCopier

//---------------------------------------------------------------------------

static void OpenGLSurface2DDeleteAssets(OpenGLSurface2DDataRef pSurface2D) 
{
    OpenGLSurface2DDeleteSurface( pSurface2D );
    OpenGLSurface2DDeleteBuffer( pSurface2D );
    OpenGLSurface2DDeleteCopier( pSurface2D );
} // OpenGLSurface2DDeleteAssets

//---------------------------------------------------------------------------

static void OpenGLSurface2DDelete(OpenGLSurface2DDataRef pSurface2D) 
{
    if( pSurface2D != NULL )
    {
        OpenGLSurface2DDeleteAssets(pSurface2D);
        
        free( pSurface2D );
        
        pSurface2D = NULL;
    } // if
} // OpenGLSurface2DDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utlities - Copy

//---------------------------------------------------------------------------

static void OpenGLSurface2DCopy(const BOOL doVR,
                                const BOOL doFixAlpha,
                                const GLvoid *pBaseSrc,   
                                OpenGLSurface2DDataRef pSurface2D)
{
    [pSurface2D->copier setNeedsVR:doVR];
    [pSurface2D->copier setFixAlpha:doFixAlpha];
    [pSurface2D->copier copy:pSurface2D->base 
                      source:pBaseSrc];
} // OpenGLSurface2DCopy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLSurface2D

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initSurface2DWithWidth:(const GLuint)theWidth
                       height:(const GLuint)theHeight
                       format:(const GLenum)theFormat
                     isGlobal:(const BOOL)theGlobalFlag
{
	self = [super init];
	
	if( self )
	{
		mpSurface2D = OpenGLSurface2DCreateWithSize(theWidth, 
                                                    theHeight,
                                                    theFormat,
                                                    theGlobalFlag);
	} // if
	
	return  self;
} // initSurface2DWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLSurface2DDelete(mpSurface2D);
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (void) copy:(const GLvoid *)theBuffer
     fixAlpha:(const BOOL)doFixAlpha
      needsVR:(const BOOL)doVR
{
    OpenGLSurface2DCopy( doVR, doFixAlpha, theBuffer, mpSurface2D );
} // copy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (BOOL) isVideo
{
    return(mpSurface2D->isVideo);
} // isVideo

//---------------------------------------------------------------------------

- (BOOL) hasSurface
{
    return(mpSurface2D->hasSufrace);
} // hasSurface

//---------------------------------------------------------------------------

- (BOOL) hasBuffer
{
    return(mpSurface2D->hasBuffer);
} // hasBuffer

//---------------------------------------------------------------------------

- (GLuint) format
{
    return(mpSurface2D->surface.format);
} // format

//---------------------------------------------------------------------------

- (GLenum) type
{
    return( mpSurface2D->surface.type );
} // type

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( mpSurface2D->buffer.width );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( mpSurface2D->buffer.height );
} // height

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( mpSurface2D->buffer.size );
} // size

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
    return( mpSurface2D->buffer.rowBytes );
} // rowbytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
    return( mpSurface2D->buffer.spp );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLvoid *) base
{
    return( mpSurface2D->base );
} // base

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
