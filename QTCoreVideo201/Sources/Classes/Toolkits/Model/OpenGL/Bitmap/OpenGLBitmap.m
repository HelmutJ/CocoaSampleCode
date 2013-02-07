//---------------------------------------------------------------------------------
//
// File: OpenGLBitmap.m
//
// Abstract: Utility toolkit to save pixels as bmp, pict, png, gif, jpeg, tga, or
//           jp2000 file(s).
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
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#import "OpenGLImage2DBuffer.h"
#import "OpenGLCopier.h"
#import "OpenGLBitmap.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------------

static const GLuint kImageMaxSPP = 4;		// Image maximum samples-per-pixel
static const GLuint kImageMaxBPC = 8;		// Image maximum bits-per-component

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------------

struct OpenGLBitmapContext
{
    GLuint          bpc;            // Bitmap bits per component
    GLenum          format;         // Bitmap (texture equivalent) format
    CGBitmapInfo    bitmapInfo;     // Bitmap type
    CGColorSpaceRef colorSpace;     // Bitmap color space
    CGContextRef    graphics;       // Bitmap actual context
    CGImageRef      image;          // Image representation of Bitmap
    
    CFMutableDictionaryRef dictionary;
};

typedef struct OpenGLBitmapContext  OpenGLBitmapContext;

//---------------------------------------------------------------------------------

struct OpenGLBitmapData
{
    OpenGLCopier        *copier;
    OpenGLImage2DBuffer  buffer;
    OpenGLBitmapContext  context;
};

typedef struct OpenGLBitmapData  OpenGLBitmapData;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------------

static void OpenGLBitmapDeleteColorSpace(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap->context.colorSpace != NULL )
    {
        CGColorSpaceRelease( pBitmap->context.colorSpace );
        
        pBitmap->context.colorSpace = NULL;
    } // if
} // OpenGLBitmapDeleteColorSpace

//---------------------------------------------------------------------------------

static void OpenGLBitmapDeleteDictionary(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap->context.dictionary != NULL )
    {
        CFRelease( pBitmap->context.dictionary );
        
        pBitmap->context.dictionary = NULL;
    } // if
} // OpenGLBitmapDeleteDictionary

//---------------------------------------------------------------------------------

static void OpenGLBitmapDeleteContext(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap->context.graphics != NULL )
    {
        CGContextRelease( pBitmap->context.graphics );
        
        pBitmap->context.graphics = NULL;
    } // if
} // OpenGLBitmapDeleteContext

//---------------------------------------------------------------------------------

static void OpenGLBitmapDeleteImage(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap->context.image != NULL )
    {
        CGImageRelease( pBitmap->context.image );
        
        pBitmap->context.image = NULL;
    } // if
} // OpenGLBitmapDeleteImage

//---------------------------------------------------------------------------

static void OpenGLBitmapDeleteCopier(OpenGLBitmapDataRef pBitmap) 
{
    if( pBitmap->copier )
    {
        [pBitmap->copier release];
        
        pBitmap->copier = nil;
    } // if
} // OpenGLBitmapDeleteCopier

//---------------------------------------------------------------------------------

static void OpenGLBitmapDeleteAssets(OpenGLBitmapDataRef pBitmap)
{
    OpenGLBitmapDeleteColorSpace( pBitmap );
    OpenGLBitmapDeleteDictionary( pBitmap );
    OpenGLBitmapDeleteContext( pBitmap );
    OpenGLBitmapDeleteImage( pBitmap );
    OpenGLBitmapDeleteCopier( pBitmap );
} // OpenGLBitmapDeleteAssets

//---------------------------------------------------------------------------------

static void OpenGLBitmapDelete(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap != NULL )
    {
        OpenGLBitmapDeleteAssets( pBitmap );
        
        free( pBitmap );
        
        pBitmap = NULL;
    } // if
} // OpenGLBitmapDelete

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------------

static void OpenGLBitmapSetContext(OpenGLBitmapDataRef pBitmap)
{
    CFIndex capacity = 1;
    
    pBitmap->context.bpc        = kImageMaxBPC;
    pBitmap->context.format     = GL_BGRA;
    pBitmap->context.image      = NULL;
    pBitmap->context.graphics   = NULL;
    pBitmap->context.bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little;	// XRGB Little Endian
    pBitmap->context.colorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );
    pBitmap->context.dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 
                                                            capacity,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &kCFTypeDictionaryValueCallBacks);
} // OpenGLBitmapSetContext

//---------------------------------------------------------------------------------

static void OpenGLBitmapCalcSize(const NSSize *pSize,
                                 OpenGLBitmapDataRef pBitmap)
{
    pBitmap->buffer.width    = (GLuint)pSize->width;
    pBitmap->buffer.height   = (GLuint)pSize->height;
    pBitmap->buffer.spp      = kImageMaxSPP;
    pBitmap->buffer.rowBytes = pBitmap->buffer.spp    * pBitmap->buffer.width;
    pBitmap->buffer.size     = pBitmap->buffer.height * pBitmap->buffer.rowBytes;
    pBitmap->buffer.aspect   = (GLfloat)(pSize->width  / pSize->height);
} // OpenGLBitmapCalcSize

//---------------------------------------------------------------------------------
//
// Create a bitmap context of size = spp * width * height
//
//---------------------------------------------------------------------------------

static BOOL OpenGLBitmapCreateContext(OpenGLBitmapDataRef pBitmap)
{
    pBitmap->context.graphics = CGBitmapContextCreate(NULL, 
                                                      pBitmap->buffer.width, 
                                                      pBitmap->buffer.height, 
                                                      pBitmap->context.bpc,
                                                      pBitmap->buffer.rowBytes, 
                                                      pBitmap->context.colorSpace, 
                                                      pBitmap->context.bitmapInfo);
    
    BOOL success = pBitmap->context.graphics != NULL;
    
    if( success )
    {
        pBitmap->buffer.data = CGBitmapContextGetData(pBitmap->context.graphics);
    } // if
    
    return( success ); 
} // OpenGLBitmapCreateContext

//---------------------------------------------------------------------------

static inline void OpenGLBitmapCreateCopier(OpenGLBitmapDataRef pBitmap)
{
    if( pBitmap->copier )
    {
        [pBitmap->copier setProperties:pBitmap->context.format 
                                 width:pBitmap->buffer.width 
                                height:pBitmap->buffer.height]; 
    } // if
    else
    {
        pBitmap->copier = [[OpenGLCopier alloc] initCopierWithFormat:pBitmap->context.format
                                                               width:pBitmap->buffer.width 
                                                              height:pBitmap->buffer.height];
        
        if( pBitmap->copier )
        {
            [pBitmap->copier setFixAlpha:NO];
        } // if
    } // else
} // OpenGLBitmapCreateCopier

//---------------------------------------------------------------------------------

static BOOL OpenGLBitmapCreateAssets(const NSSize *pSize,
                                     OpenGLBitmapDataRef pBitmap)
{
    OpenGLBitmapSetContext(pBitmap);
    OpenGLBitmapCalcSize(pSize, pBitmap);
    
    OpenGLBitmapCreateCopier(pBitmap);
        
    return( OpenGLBitmapCreateContext(pBitmap) );
} // OpenGLBitmapCreateAssets

//---------------------------------------------------------------------------------

static OpenGLBitmapDataRef OpenGLBitmapCreateWithSize(const NSSize *pSize)
{
	OpenGLBitmapDataRef pBitmap = (OpenGLBitmapDataRef)calloc(1, sizeof(OpenGLBitmapData));
	
	if( pBitmap != NULL )
	{
        OpenGLBitmapCreateAssets(pSize, pBitmap);
	} // if
	
	return( pBitmap );
} // OpenGLBitmapCreate

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------------
//
// Save an opaque image reference as bmp, tng, pict, png, gif, jpeg, 
// or jp2000 file.
//
//---------------------------------------------------------------------------------

static BOOL OpenGLBitmapSaveAs(CFStringRef name,
                               CFStringRef uttype,
                               OpenGLBitmapDataRef pBitmap)
{
	BOOL success = NO;
	
	if( (pBitmap->context.image != NULL) && (name != NULL) )
	{
		BOOL isDirectory = NO;
		
		// Get a URL associated with an image file name
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, 
														 name,
														 kCFURLPOSIXPathStyle, 
														 isDirectory);
		
		if(fileURL != NULL)
		{
			// Set the properties for authoring an image file
			CFIndex                 fileImageIndex = 1;
			CFMutableDictionaryRef  fileDict       = NULL;
			CFStringRef             fileUTType     = (uttype != NULL) ? (uttype) : kUTTypeJPEG;
			
			// Create an context destination opaque reference for authoring an image file
			CGImageDestinationRef imageDest = CGImageDestinationCreateWithURL(fileURL, 
																			  fileUTType, 
																			  fileImageIndex, 
																			  fileDict);
			
			if(imageDest != NULL)
			{
				// Add an opaque context reference to the destination
				CGImageDestinationAddImage(imageDest, 
										   pBitmap->context.image,
										   pBitmap->context.dictionary);
				
				// Close the context.image file
				CGImageDestinationFinalize( imageDest ) ;
				
				// Image destination opaque reference is not needed
				CFRelease( imageDest );
				
				success = YES;
			} // if
			
			CFRelease( fileURL );
		} // if
	} // if
	
	return( success );
} // OpenGLBitmapSaveAs

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessor

//---------------------------------------------------------------------------------
//
// Utility to update a pixel backing store with new data of a certain rectangular
// size with width and height.
//
//---------------------------------------------------------------------------------

static BOOL OpenGLBitmapSetBuffer(const BOOL doVR,
                                  const GLvoid *pBuffer,
                                  OpenGLBitmapDataRef pBitmap)
{
	BOOL success = NO;
	
	if( pBuffer != NULL )
	{
        if( pBitmap->copier )
        {
            [pBitmap->copier setNeedsVR:doVR];
            
            success = [pBitmap->copier copy:pBitmap->buffer.data
                                     source:pBuffer];
        } // if
        
		if( success )
		{
			// Release an old opaque image reference in favor of a new one
			OpenGLBitmapDeleteImage( pBitmap );
			
			// Get an opaque image reference from bitmap context
			pBitmap->context.image = CGBitmapContextCreateImage( pBitmap->context.graphics );
            
			success = pBitmap->context.image != NULL;
		} // if
	} // if
	
	return( success );
} // OpenGLBitmapSetBuffer

//---------------------------------------------------------------------------------

static BOOL OpenGLBitmapSetSize(const NSSize *pSize,
                                OpenGLBitmapDataRef pBitmap)
{
    BOOL success = pSize != NULL;
    
    if( success )
    {
        GLuint width  = (GLuint)pSize->width;
        GLuint height = (GLuint)pSize->height;
        
        success =       ( width  != pBitmap->buffer.width ) 
                    ||	( height != pBitmap->buffer.height );
        
        if( success )
        {
            OpenGLBitmapDeleteImage(pBitmap);
            OpenGLBitmapDeleteContext(pBitmap);
            
            OpenGLBitmapCalcSize(pSize, pBitmap);   
            
            OpenGLBitmapCreateCopier(pBitmap);
            OpenGLBitmapCreateContext(pBitmap);
        } // if
    } // if
    
    return( success );
} // OpenGLBitmapSetSize

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation OpenGLBitmap

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------------
//
// Designated initializer for setting basic properties for authoring an image file.
//
//---------------------------------------------------------------------------------

- (id) initBitmapWithSize:(const NSSize *)theSize
{
	self = [super init];
	
	if( self )
	{
        mpBitmap = OpenGLBitmapCreateWithSize(theSize);
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------------

- (void) dealloc
{
    OpenGLBitmapDelete(mpBitmap);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors - Setters

//---------------------------------------------------------------------------------
//
// Utility to update a pixel backing store with new data of a certain rectangular
// size with width and height.
//
//---------------------------------------------------------------------------------

- (BOOL) setBuffer:(const GLvoid *)theBuffer
           needsVR:(const BOOL)doVR
{
	return( OpenGLBitmapSetBuffer(doVR, theBuffer, mpBitmap) );
} // setBuffer

//---------------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLBitmapSetSize(theSize, mpBitmap) );
} // setSize

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors - Getters

//---------------------------------------------------------------------------------

- (GLuint) width
{
	return( mpBitmap->buffer.width );
} // width

//---------------------------------------------------------------------------------

- (GLuint) height
{
	return( mpBitmap->buffer.height );
} // height

//---------------------------------------------------------------------------------

- (GLuint) rowBytes
{
	return( mpBitmap->buffer.rowBytes );
} // rowBytes

//---------------------------------------------------------------------------------

- (GLuint) bitsPerComponent
{
	return( mpBitmap->context.bpc );
} // bitsPerComponent

//---------------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
	return( mpBitmap->buffer.spp );
} // samplesPerPixel

//---------------------------------------------------------------------------------

- (GLuint) size
{
	return( mpBitmap->buffer.size );
} // size

//---------------------------------------------------------------------------------

- (GLvoid *) buffer
{
	return( mpBitmap->buffer.data );
} // buffer

//---------------------------------------------------------------------------------

- (CGBitmapInfo) bitmapInfo
{
	return( mpBitmap->context.bitmapInfo );
}

//---------------------------------------------------------------------------------

- (CGColorSpaceRef) colorSpace;
{
	return( mpBitmap->context.colorSpace );
} // context.colorSpace

//---------------------------------------------------------------------------------

- (CGImageRef) image
{
	return( mpBitmap->context.image );
} // context.image

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------------
//
// Save an opaque image reference as bmp, pict, png, gif, jpeg, or jp2000 file.
//
//---------------------------------------------------------------------------------

- (BOOL) saveAs:(CFStringRef)theName
         UTType:(CFStringRef)theUTType
{
	return( OpenGLBitmapSaveAs(theName, theUTType, mpBitmap) );
} // saveAs

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------
