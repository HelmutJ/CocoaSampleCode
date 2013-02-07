//---------------------------------------------------------------------------------
//
//	File: CIGLFilter.m
//
// Abstract: Utility base class for managing a Core Image filter.
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

#import "CIGLFramebuffer.h"
#import "CIGLFilter.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------------

struct CIGLFilterData
{
    CIFilter  *filter;
    CIContext *context;
    CIImage   *image;
    CGRect     extent;
    
    CIGLFramebuffer  *framebuffer;
};

typedef struct CIGLFilterData  CIGLFilterData;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------------

static void CIGLFilterDeleteFilter(CIGLFilterDataRef pFilter)
{
	if( pFilter->filter )
	{
		[pFilter->filter release];
		
		pFilter->filter = nil;
	} // if
} // CIGLFilterDeleteFilter

//---------------------------------------------------------------------------------

static void CIGLFilterDeleteFramebuffer(CIGLFilterDataRef pFilter)
{
	if( pFilter->framebuffer )
	{
		[pFilter->framebuffer release];
		
		pFilter->framebuffer = nil;
	} // if
} // CIGLFilterDeleteFramebuffer

//---------------------------------------------------------------------------------

static void CIGLFilterDeleteAssets(CIGLFilterDataRef pFilter)
{
    CIGLFilterDeleteFilter(pFilter);
    CIGLFilterDeleteFramebuffer(pFilter);
} // CIGLFilterDeleteAssets

//---------------------------------------------------------------------------------

static void CIGLFilterDelete(CIGLFilterDataRef pFilter)
{
	if( pFilter != NULL )
	{
        CIGLFilterDeleteAssets(pFilter);
        
		free(pFilter);
		
		pFilter = NULL;
	} // if
} // CIGLFilterDelete

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------------
//
// Create the Core Image denoise filters
//
//---------------------------------------------------------------------------------

static void CIGLFilterGetImageUnit(NSString *pName,
                                   CIGLFilterDataRef pFilter)
{
    if( pName )
    {
        pFilter->filter = [CIFilter filterWithName:pName];
        
        if( pFilter->filter )
        {
            [pFilter->filter setDefaults];
            [pFilter->filter setValue:pFilter->image forKey:@"inputImage"];
            [pFilter->filter retain];
        } // if
    } // if
    else
    {
        NSLog( @">> ERROR: CI GL Filter - Filter name is NULL!" );
    } // if
} // CIGLFilterGetImageUnits

//---------------------------------------------------------------------------------
//
// Set the bounds for the image we are going to use throughout.
//
//---------------------------------------------------------------------------------

static inline void CIGLFilterUpdateProperties(CIGLFilterDataRef pFilter)
{
    pFilter->context = [pFilter->framebuffer context];
    pFilter->image   = [pFilter->framebuffer image];
    pFilter->extent  = [pFilter->framebuffer extent];
} // CIGLFilterSetParams

//---------------------------------------------------------------------------------

static BOOL CIGLFilterCreateFramebufferFromFile(NSString *pPathname,
                                                NSOpenGLContext *pContext,
                                                NSOpenGLPixelFormat *pFormat,
                                                CIGLFilterDataRef pFilter)
{
    pFilter->framebuffer = [[CIGLFramebuffer alloc] initFramebufferFromFile:pPathname
                                                                    context:pContext
                                                                pixelFormat:pFormat];
    
    BOOL success = pFilter->framebuffer != nil;
    
    if( !success )
    {
        NSLog( @">> ERROR: CI GL Filter - Creating a framebuffer failed!" );
    } // if
    
    return( pFilter->framebuffer != nil );
} // CIGLFilterCreateFramebufferFromFile

//---------------------------------------------------------------------------------

static void CIGLFilterCreateAssetsFromFile(NSString *pPathname,
                                           NSOpenGLContext *pContext,
                                           NSOpenGLPixelFormat *pFormat,
                                           NSString *pFilterName,
                                           CIGLFilterDataRef pFilter)
{
    if( CIGLFilterCreateFramebufferFromFile(pPathname, pContext, pFormat, pFilter) )
    {
        CIGLFilterUpdateProperties(pFilter);
        CIGLFilterGetImageUnit(pFilterName, pFilter);
    } // if
} // CIGLFilterCreateAssetsFromFile

//---------------------------------------------------------------------------------

static CIGLFilterDataRef CIGLFilterCreateFromFile(NSString *pPathname,
                                                  NSOpenGLContext *pContext,
                                                  NSOpenGLPixelFormat *pFormat,
                                                  NSString *pFilterName)
{
    CIGLFilterDataRef pFilter = (CIGLFilterDataRef)calloc(1, sizeof(CIGLFilterData));
    
    if( pFilter != NULL )
    {
        CIGLFilterCreateAssetsFromFile(pPathname, 
                                       pContext,
                                       pFormat,
                                       pFilterName,
                                       pFilter);
    } // if
    
    return( pFilter );
} // CIGLFilterCreateFromFile

//---------------------------------------------------------------------------------

static BOOL CIGLFilterCreateFramebufferWithData(NSData *pData,
                                                NSOpenGLContext *pContext,
                                                NSOpenGLPixelFormat *pFormat,
                                                CIGLFilterDataRef pFilter)
{
    pFilter->framebuffer = [[CIGLFramebuffer alloc] initFramebufferWithData:pData
                                                                    context:pContext
                                                                pixelFormat:pFormat];
    
    BOOL success = pFilter->framebuffer != nil;
    
    if( !success )
    {
        NSLog( @">> ERROR: CI GL Filter - Creating a framebuffer failed!" );
    } // if
    
    return( pFilter->framebuffer != nil );
} // CIGLFilterCreateFramebufferWithData

//---------------------------------------------------------------------------------

static void CIGLFilterCreateAssetsWithData(NSData *pData,
                                           NSOpenGLContext *pContext,
                                           NSOpenGLPixelFormat *pFormat,
                                           NSString *pFilterName,
                                           CIGLFilterDataRef pFilter)
{
    if( CIGLFilterCreateFramebufferWithData(pData, pContext, pFormat, pFilter) )
    {
        CIGLFilterUpdateProperties(pFilter);
        CIGLFilterGetImageUnit(pFilterName, pFilter);
    } // if
} // CIGLFilterCreateAssetsWithData

//---------------------------------------------------------------------------------

static CIGLFilterDataRef CIGLFilterCreateWithData(NSData *pData,
                                                  NSOpenGLContext *pContext,
                                                  NSOpenGLPixelFormat *pFormat,
                                                  NSString *pFilterName)
{
    CIGLFilterDataRef pFilter = (CIGLFilterDataRef)calloc(1, sizeof(CIGLFilterData));
    
    if( pFilter != NULL )
    {
        CIGLFilterCreateAssetsWithData(pData, 
                                       pContext,
                                       pFormat,
                                       pFilterName,
                                       pFilter);
    } // if
    
    return( pFilter );
} // CIGLFilterCreateWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------------

static BOOL CIGLFilterUpdateWithData(NSData *pData,
                                     CIGLFilterDataRef pFilter)
{
	BOOL success = [pFilter->framebuffer updateWithData:pData];
    
    if( success )
    {
        CIGLFilterUpdateProperties(pFilter);
    } // if
    
    return( success );
} // CIGLFilterUpdateWithData

//---------------------------------------------------------------------------------

static BOOL CIGLFilterUpdateFromFile(NSString *pPathname,
                                     CIGLFilterDataRef pFilter)
{
	BOOL success = [pFilter->framebuffer updateFromFile:pPathname];
    
    if( success )
    {
        CIGLFilterUpdateProperties(pFilter);
    } // if
    
    return( success );
} // CIGLFilterUpdateFromFile

//---------------------------------------------------------------------------------

static inline void CIGLFilterRender(CIGLFilterDataRef pFilter)
{  
	// Update images
	[pFilter->filter setValue:pFilter->image 
                       forKey:@"inputImage"];
	
	// Render CI 
	[pFilter->context drawImage:[pFilter->filter valueForKey:@"outputImage"]
                        atPoint:CGPointZero  
                       fromRect:pFilter->extent];
} // CIGLFilterRender

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation CIGLFilter

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initFilterFromFile:(NSString *)thePathname
                  context:(NSOpenGLContext *)theContext
                   format:(NSOpenGLPixelFormat *)theFormat
                   filter:(NSString *)theFilter
{
	self = [super init];
    
    if( self )
    {
        mpFilter = CIGLFilterCreateFromFile(thePathname,
                                            theContext,
                                            theFormat,
                                            theFilter);
    } // if
	
	return( self );
} // initFilterFromFile

//---------------------------------------------------------------------------

- (id) initFilterWithData:(NSData *)theData
                  context:(NSOpenGLContext *)theContext
                   format:(NSOpenGLPixelFormat *)theFormat
                   filter:(NSString *)theFilter
{
	self = [super init];
    
    if( self )
    {
        mpFilter = CIGLFilterCreateWithData(theData,
                                            theContext,
                                            theFormat,
                                            theFilter);
    } // if
	
	return( self );
} // initFilterWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------------

- (void) dealloc
{
	CIGLFilterDelete(mpFilter);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------------

- (void) render
{
    CIGLFilterRender(mpFilter); 
} // render

//---------------------------------------------------------------------------------

- (void) enable
{
    [mpFilter->framebuffer enable]; 
} // median

//---------------------------------------------------------------------------------

- (void) disable
{
    [mpFilter->framebuffer disable]; 
} // disable

//---------------------------------------------------------------------------------

- (void) bind
{
    [mpFilter->framebuffer bind];
} // bind

//---------------------------------------------------------------------------------

- (void) unbind
{
    [mpFilter->framebuffer unbind];
} // unbind

//---------------------------------------------------------------------------------

- (void) display
{ 
    [mpFilter->framebuffer display];
} // display

//---------------------------------------------------------------------------------

- (BOOL) readback
{
    return( [mpFilter->framebuffer readback] );
} // readback

//---------------------------------------------------------------------------------

- (BOOL) saveAs:(CFStringRef)theName
         UTType:(CFStringRef)theUTType
{
    return( [mpFilter->framebuffer saveAs:theName
                                   UTType:theUTType] );
} // saveAs

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities - Updating

//---------------------------------------------------------------------------------

- (BOOL) updateWithData:(NSData *)theData
{
	return( CIGLFilterUpdateWithData(theData, mpFilter) );
} // updateWithData

//---------------------------------------------------------------------------------

- (BOOL) updateFromFile:(NSString *)thePathname
{
	return( CIGLFilterUpdateFromFile(thePathname, mpFilter) );
} // updateFromFile

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------------

- (GLenum) target
{
	return( [mpFilter->framebuffer target] );
} // target

//---------------------------------------------------------------------------------

- (GLfloat) aspect
{
	return( [mpFilter->framebuffer aspect] );
} // aspect

//---------------------------------------------------------------------------------

- (CGRect) extent
{
	return( mpFilter->extent );
} // extent

//---------------------------------------------------------------------------------

- (CGSize) size
{
	return( mpFilter->extent.size );
} // size

//---------------------------------------------------------------------------------

- (CIFilter *) filter
{
	return( mpFilter->filter );
} // filter

//---------------------------------------------------------------------------------

- (CGImageRef) snapshot
{
    return( [mpFilter->framebuffer snapshot] );
} // snapshot

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

