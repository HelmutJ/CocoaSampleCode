//---------------------------------------------------------------------------------
//
//	File: CIFramebuffer.m
//
// Abstract: Utility class for managing Core Image context and framebuffer.
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

#import "OpenGLBitmap.h"
#import "OpenGLFramebuffer2D.h"
#import "OpenGLQuad.h"

#import "CIGLFramebuffer.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------------

struct CIGLFramebufferData
{
    CGRect               bounds;
    CIContext           *context;
    CIImage             *image;
    OpenGLQuad          *quad;
    OpenGLBitmap        *bitmap;
    OpenGLFramebuffer2D *framebuffer;
};

typedef struct CIGLFramebufferData  CIGLFramebufferData;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteContext(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->context )
	{
		[pFramebuffer->context release];
		
		pFramebuffer->context = nil;
	} // if
} // CIFramebufferDeleteContext

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteImage(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->image )
	{
		[pFramebuffer->image release];
		
		pFramebuffer->image = nil;
	} // if
} // CIFramebufferDeleteImage

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteQuad(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->quad )
	{
		[pFramebuffer->quad release];
		
		pFramebuffer->quad = nil;
	} // if
} // CIFramebufferDeleteQuad

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteBitmap(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->bitmap )
	{
		[pFramebuffer->bitmap release];
		
		pFramebuffer->bitmap = nil;
	} // if
} // CIFramebufferDeleteBitmap

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteFramebuffer(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->framebuffer )
	{
		[pFramebuffer->framebuffer release];
		
		pFramebuffer->framebuffer = nil;
	} // if
} // CIFramebufferDeleteFramebuffer

//---------------------------------------------------------------------------------

static void CIFramebufferDeleteAssets(CIGLFramebufferDataRef pFramebuffer)
{
    CIFramebufferDeleteContext(pFramebuffer);
    CIFramebufferDeleteImage(pFramebuffer);
    CIFramebufferDeleteQuad(pFramebuffer);
    CIFramebufferDeleteBitmap(pFramebuffer);
    CIFramebufferDeleteFramebuffer(pFramebuffer);
} // CIFramebufferDeleteAssets

//---------------------------------------------------------------------------------

static void CIFramebufferDelete(CIGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer != NULL )
	{
        CIFramebufferDeleteAssets(pFramebuffer);
        
		free(pFramebuffer);
		
		pFramebuffer = NULL;
	} // if
} // CIFramebufferDelete

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------------
//
// Generate a VBO quad.  This quad will be used in a display method to draw a 
// texture.
//
//---------------------------------------------------------------------------------

static BOOL CIFramebufferCreateQuad(const NSSize *pSize, 
                                    CIGLFramebufferDataRef pFramebuffer)
{
    if( pFramebuffer->quad == nil )
    {
        pFramebuffer->quad = [OpenGLQuad new];
        
        if( pFramebuffer->quad )
        {
            [pFramebuffer->quad setSize:pSize];
            [pFramebuffer->quad setTarget:[pFramebuffer->framebuffer target]];
            [pFramebuffer->quad acquire];
        } // if
    } // if
    
    return( pFramebuffer->quad != nil );
} // CIFramebufferCreateQuad

//---------------------------------------------------------------------------

static BOOL CIFramebufferCreateFramebuffer(const NSSize *pSize,
                                           CIGLFramebufferDataRef pFramebuffer)
{
    pFramebuffer->framebuffer = [[OpenGLFramebuffer2D alloc] initFramebuffer2DWithSize:pSize
                                                                target:GL_TEXTURE_RECTANGLE_ARB
                                                                format:GL_BGRA
                                                                 level:0];
    
    BOOL success = pFramebuffer->framebuffer != nil;
    
    if( !success )
    {
        NSLog( @">> ERROR: CI Framebuffer - Creating a FBO failed!" );
    } // if
    
    return( pFramebuffer->framebuffer != nil );
} // CIFramebufferCreateFramebuffer

//---------------------------------------------------------------------------

static inline BOOL CIFramebufferCreateBitmap(const NSSize *pSize,
                                             CIGLFramebufferDataRef pFramebuffer)
{
    pFramebuffer->bitmap = [[OpenGLBitmap alloc] initBitmapWithSize:pSize];
    
    return( pFramebuffer->bitmap != nil );
} // CIFramebufferCreateBitmap

//---------------------------------------------------------------------------------
//
// Create CIContext based on OpenGL context and pixel format.
//
//---------------------------------------------------------------------------------

static BOOL CIFramebufferCreateContext(NSOpenGLContext *pContext,
                                       NSOpenGLPixelFormat *pPixelFormat,
                                       CIGLFramebufferDataRef pFramebuffer)
{
	BOOL success = NO;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	if( colorSpace != NULL )
	{
		// Create CIContext from an OpenGL context.
		pFramebuffer->context = [CIContext contextWithCGLContext:[pContext CGLContextObj] 
                                                     pixelFormat:[pPixelFormat CGLPixelFormatObj]
                                                      colorSpace:colorSpace
                                                         options:nil];
		
        success = pFramebuffer->context != nil;
        
		if( !success )
		{ 
            NSLog( @">> ERROR: CI Framebuffer - CoreImage context creation failed!" );
		} // if
		else 
		{
			[pFramebuffer->context retain];
		} // else
		
		CGColorSpaceRelease(colorSpace);
	} // if
	
	return( success );
} // CIFramebufferCreateContext

//---------------------------------------------------------------------------

static BOOL CIFramebufferSetImage(CIImage *image,
                                  CIGLFramebufferDataRef pFramebuffer)
{
    BOOL success = image != nil;
    
    if( success )
    {
        CIFramebufferDeleteImage(pFramebuffer);
        
        pFramebuffer->image = [image retain];
    } // if
    
    return( success );
} // CIFramebufferSetImage

//---------------------------------------------------------------------------
//
// Initialize Core Image with the contents of a file.
//
//---------------------------------------------------------------------------

static BOOL CIFramebufferCreateImageFromFile(NSString *pPathname,
                                             CIGLFramebufferDataRef pFramebuffer)
{
    BOOL success = NO;
    
    if( pPathname )
    {
        NSURL *pImageURL = [NSURL fileURLWithPath:pPathname];
        
        if( pImageURL )
        {            
            CIImage *image = [CIImage imageWithContentsOfURL:pImageURL];
            
            success = CIFramebufferSetImage(image, pFramebuffer);
        } // if
    } // if
    
    return( success );
} // CIFramebufferCreateImageFromFile

//---------------------------------------------------------------------------

static BOOL CIFramebufferCreateImageWithData(NSData *pData,
                                             CIGLFramebufferDataRef pFramebuffer)
{
    BOOL success = NO;
    
    if( pData )
    {
        CIImage *image = [CIImage imageWithData:pData];
        
        success = CIFramebufferSetImage(image, pFramebuffer);
    } // if
    
    return( success );
} // CIFramebufferCreateImageWithData

//---------------------------------------------------------------------------------

static void CIFramebufferCreateRenderer(CIGLFramebufferDataRef pFramebuffer)
{
    pFramebuffer->bounds = [pFramebuffer->image extent];
    
    NSSize size = NSMakeSize(pFramebuffer->bounds.size.width, 
                             pFramebuffer->bounds.size.height);
    
    if( CIFramebufferCreateFramebuffer(&size, pFramebuffer) )
    {
        CIFramebufferCreateQuad(&size, pFramebuffer);
        CIFramebufferCreateBitmap(&size, pFramebuffer);
    } // if
} // CIFramebufferCreateRenderer

//---------------------------------------------------------------------------------

static void CIFramebufferCreateAssetsFromFile(NSString *pPathname,
                                              NSOpenGLContext *pContext,
                                              NSOpenGLPixelFormat *pFormat,
                                              CIGLFramebufferDataRef pFramebuffer)
{
    if( CIFramebufferCreateImageFromFile(pPathname, pFramebuffer) )
    {
        CIFramebufferCreateContext(pContext, pFormat, pFramebuffer);
        CIFramebufferCreateRenderer(pFramebuffer);
    } // if
} // CIFramebufferCreateAssetsFromFile

//---------------------------------------------------------------------------------

static CIGLFramebufferDataRef CIFramebufferCreateFromFile(NSString *pPathname,
                                                          NSOpenGLContext *pContext,
                                                          NSOpenGLPixelFormat *pFormat)
{
    CIGLFramebufferDataRef pFramebuffer = (CIGLFramebufferDataRef)calloc(1, sizeof(CIGLFramebufferData));
    
    if( pFramebuffer != NULL )
    {
        CIFramebufferCreateAssetsFromFile(pPathname, pContext, pFormat, pFramebuffer);
    } // if
    
    return( pFramebuffer );
} // CIFramebufferCreateFromFile

//---------------------------------------------------------------------------------

static void CIFramebufferCreateAssetsWithData(NSData *pData,
                                              NSOpenGLContext *pContext,
                                              NSOpenGLPixelFormat *pFormat,
                                              CIGLFramebufferDataRef pFramebuffer)
{
    if( CIFramebufferCreateImageWithData(pData, pFramebuffer) )
    {
        CIFramebufferCreateContext(pContext, pFormat, pFramebuffer);
        CIFramebufferCreateRenderer(pFramebuffer);
    } // if
} // CIFramebufferCreateAssetsWithData

//---------------------------------------------------------------------------------

static CIGLFramebufferDataRef CIFramebufferCreateWithData(NSData *pData,
                                                          NSOpenGLContext *pContext,
                                                          NSOpenGLPixelFormat *pFormat)
{
    CIGLFramebufferDataRef pFramebuffer = (CIGLFramebufferDataRef)calloc(1, sizeof(CIGLFramebufferData));
    
    if( pFramebuffer != NULL )
    {
        CIFramebufferCreateAssetsWithData(pData, pContext, pFormat, pFramebuffer);
    } // if
    
    return( pFramebuffer );
} // CIFramebufferCreateWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Updating

//---------------------------------------------------------------------------------

static void CIFramebufferResize(CIGLFramebufferDataRef pFramebuffer)
{
    pFramebuffer->bounds = [pFramebuffer->image extent];
    
    NSSize size = NSMakeSize(pFramebuffer->bounds.size.width, 
                             pFramebuffer->bounds.size.height);
    
    [pFramebuffer->framebuffer setSize:&size];
    [pFramebuffer->quad        setSize:&size];
    [pFramebuffer->bitmap      setSize:&size];
} // CIFramebufferResize

//---------------------------------------------------------------------------------

static BOOL CIFramebufferUpdateImageWithData(NSData *pData,
                                             CIGLFramebufferDataRef pFramebuffer)
{
	// Load an image from data
    BOOL success = CIFramebufferCreateImageWithData(pData, pFramebuffer);
    
    if( success )
    {
        // Now update the CI image
        CIFramebufferResize(pFramebuffer);
    } // if
    
    return( success );
} // CIFramebufferUpdateImageWithData

//---------------------------------------------------------------------------------

static BOOL CIFramebufferUpdateImageFromFile(NSString *pPathname,
                                             CIGLFramebufferDataRef pFramebuffer)
{
	// Load an image from a file
    BOOL success = CIFramebufferCreateImageFromFile(pPathname, pFramebuffer);
    
    if( success )
    {
        // Now update the CI image
        CIFramebufferResize(pFramebuffer);
    } // if
    
    return( success );
} // CIFramebufferUpdateImageFromFile

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------------

static void CIFramebufferDisplayBegin(CIGLFramebufferDataRef pFramebuffer)
{    
    glMatrixMode(GL_TEXTURE);
    
	glScalef(pFramebuffer->bounds.size.width, 
             pFramebuffer->bounds.size.height, 
             1.0f);
    
    glMatrixMode(GL_MODELVIEW);
} // CIFramebufferDisplayBegin

//---------------------------------------------------------------------------------

static void CIFramebufferDisplayEnd(CIGLFramebufferDataRef pFramebuffer)
{    
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
} // CIFramebufferDisplayEnd

//---------------------------------------------------------------------------------

static void CIFramebufferRender(CIGLFramebufferDataRef pFramebuffer)
{    
    [pFramebuffer->framebuffer bind];
    [pFramebuffer->quad display];
    [pFramebuffer->framebuffer unbind];
} // CIFramebufferRender

//---------------------------------------------------------------------------------

static void CIFramebufferDisplay(CIGLFramebufferDataRef pFramebuffer)
{    
    CIFramebufferDisplayBegin(pFramebuffer);
    CIFramebufferRender(pFramebuffer);
    CIFramebufferDisplayEnd(pFramebuffer);
} // CIFramebufferDisplay

//---------------------------------------------------------------------------------

static BOOL CIFramebufferReadback(CIGLFramebufferDataRef pFramebuffer)
{
    BOOL success = [pFramebuffer->framebuffer map];
    
    if( success )
    {
        success = [pFramebuffer->bitmap setBuffer:[pFramebuffer->framebuffer buffer] 
                                          needsVR:YES];
    } // if
    
    [pFramebuffer->framebuffer unmap];
    
    return( success );
} // CIFramebufferReadback

//---------------------------------------------------------------------------------

static inline BOOL CIFramebufferSaveAs(CFStringRef pName,
                                       CFStringRef pUTType,
                                       CIGLFramebufferDataRef pFramebuffer)
{
    return( [pFramebuffer->bitmap saveAs:pName 
                                  UTType:pUTType] );
} // CIFramebufferSaveAs

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation CIGLFramebuffer

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated initializers

//---------------------------------------------------------------------------------

- (id) initFramebufferFromFile:(NSString *)thePathname
                       context:(NSOpenGLContext *)theContext
                   pixelFormat:(NSOpenGLPixelFormat *)theFormat
{
	self = [super init];
    
    if( self )
    {
        mpFramebuffer = CIFramebufferCreateFromFile(thePathname,
                                                    theContext,
                                                    theFormat);
    } // if
	
	return( self );
} // initFramebufferFromFile

//---------------------------------------------------------------------------------

- (id) initFramebufferWithData:(NSData *)theData
                       context:(NSOpenGLContext *)theContext
                   pixelFormat:(NSOpenGLPixelFormat *)theFormat
{
	self = [super init];
    
    if( self )
    {
        mpFramebuffer = CIFramebufferCreateWithData(theData,
                                                    theContext,
                                                    theFormat);
    } // if
	
	return( self );
} // initFramebufferWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------------

- (void) dealloc
{
	CIFramebufferDelete(mpFramebuffer);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities - Render Context

//---------------------------------------------------------------------------------

- (void) display
{ 
    CIFramebufferDisplay(mpFramebuffer);
} // display

//---------------------------------------------------------------------------------

- (BOOL) readback
{
    return( CIFramebufferReadback(mpFramebuffer) );
} // readback

//---------------------------------------------------------------------------------

- (BOOL) saveAs:(CFStringRef)theName
         UTType:(CFStringRef)theUTType
{
    return( CIFramebufferSaveAs(theName, theUTType, mpFramebuffer) );
} // saveAs

//---------------------------------------------------------------------------------

- (void) enable
{
    [mpFramebuffer->framebuffer enable];
} // enable

//---------------------------------------------------------------------------------

- (void) disable
{
    [mpFramebuffer->framebuffer disable];
} // disable

//---------------------------------------------------------------------------------

- (void) bind
{
    [mpFramebuffer->framebuffer bind];
} // bind

//---------------------------------------------------------------------------------

- (void) unbind
{
    [mpFramebuffer->framebuffer unbind];
} // unbind

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities - Updating

//---------------------------------------------------------------------------------

- (BOOL) updateWithData:(NSData *)theData
{
	return( CIFramebufferUpdateImageWithData(theData, mpFramebuffer) );
} // updateWithData

//---------------------------------------------------------------------------------

- (BOOL) updateFromFile:(NSString *)thePathname
{
	return( CIFramebufferUpdateImageFromFile(thePathname, mpFramebuffer) );
} // updateFromFile

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------------

- (GLenum) target
{
	return( [mpFramebuffer->framebuffer target] );
} // target

//---------------------------------------------------------------------------------

- (GLfloat) aspect
{
	return( [mpFramebuffer->framebuffer aspect] );
} // aspect

//---------------------------------------------------------------------------------

- (CGRect) extent
{
	return( mpFramebuffer->bounds );
} // extent

//---------------------------------------------------------------------------------

- (CGSize) size
{
	return( mpFramebuffer->bounds.size );
} // size

//---------------------------------------------------------------------------------

- (CIContext *) context
{
    return( mpFramebuffer->context );
} // context

//---------------------------------------------------------------------------------

- (CIImage *) image
{
    return( mpFramebuffer->image );
} // image

//---------------------------------------------------------------------------------

- (CGImageRef) snapshot
{
    return( [mpFramebuffer->bitmap image] ); 
} // snapshot

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

