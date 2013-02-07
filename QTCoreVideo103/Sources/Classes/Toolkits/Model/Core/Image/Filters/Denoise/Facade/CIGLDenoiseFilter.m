//---------------------------------------------------------------------------------
//
//	File: CIGLDenoiseFilter.m
//
// Abstract: Utility class for managing Core Image denoise filters.
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

#import "CIGLDenoiseFilterProtocol.h"
#import "CIGLMedianFilter.h"
#import "CIGLNoiseReductionFilter.h"
#import "CIGLDenoiseFilter.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------------

struct CIGLDenoiseFilterData
{    
    CIGLMedianFilter          *filterMedian;
    CIGLNoiseReductionFilter  *filterNR;
    
    id<CIGLDenoiseFilterProtocol> filter;
};

typedef struct CIGLDenoiseFilterData  CIGLDenoiseFilterData;

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

static CIGLDenoiseFilterDataRef CIGLDenoiseFilterCreateFromFile(NSString *pPathname,
                                                                NSOpenGLContext *pContext,
                                                                NSOpenGLPixelFormat *pFormat)
{
    CIGLDenoiseFilterDataRef pDenoiseFilter = (CIGLDenoiseFilterDataRef)calloc(1, sizeof(CIGLDenoiseFilterData));
    
    if( pDenoiseFilter != NULL )
    {
        pDenoiseFilter->filterMedian = [[CIGLMedianFilter alloc] initMedianFilterFromFile:pPathname 
                                                                                  context:pContext 
                                                                                   format:pFormat];
        
        pDenoiseFilter->filterNR = [[CIGLNoiseReductionFilter alloc] initNoiseReductionFilterFromFile:pPathname 
                                                                                              context:pContext 
                                                                                               format:pFormat];
        
        pDenoiseFilter->filter = pDenoiseFilter->filterMedian;
    } // if
    
    return( pDenoiseFilter );
} // CIGLDenoiseFilterCreateFromFile

//---------------------------------------------------------------------------------

static CIGLDenoiseFilterDataRef CIGLDenoiseFilterCreateWithData(NSData *pData,
                                                                NSOpenGLContext *pContext,
                                                                NSOpenGLPixelFormat *pFormat)
{
    CIGLDenoiseFilterDataRef pDenoiseFilter = (CIGLDenoiseFilterDataRef)calloc(1, sizeof(CIGLDenoiseFilterData));
    
    if( pDenoiseFilter != NULL )
    {
        pDenoiseFilter->filterMedian = [[CIGLMedianFilter alloc] initMedianFilterWithData:pData 
                                                                                  context:pContext 
                                                                                   format:pFormat];
        
        pDenoiseFilter->filterNR = [[CIGLNoiseReductionFilter alloc] initNoiseReductionFilterWithData:pData 
                                                                                              context:pContext 
                                                                                               format:pFormat];
        
        pDenoiseFilter->filter = pDenoiseFilter->filterMedian;
    } // if
    
    return( pDenoiseFilter );
} // CIGLDenoiseFilterCreateWithData

//---------------------------------------------------------------------------------

static void CIGLDenoiseFilterDelete(CIGLDenoiseFilterDataRef pDenoiseFilter)
{
	if( pDenoiseFilter != NULL )
	{ 
        if( pDenoiseFilter->filterMedian )
        {
            [pDenoiseFilter->filterMedian release];
            
            pDenoiseFilter->filterMedian = nil;
        } // if
        
        if( pDenoiseFilter->filterNR )
        {
            [pDenoiseFilter->filterNR release];
            
            pDenoiseFilter->filterNR = nil;
        } // if
        
		free(pDenoiseFilter);
		
		pDenoiseFilter = NULL;
	} // if
} // CIGLDenoiseFilterDelete

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation CIGLDenoiseFilter

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initDenoiseFilterFromFile:(NSString *)thePathname
                         context:(NSOpenGLContext *)theContext
                          format:(NSOpenGLPixelFormat *)theFormat
{
	self = [super init];
    
    if( self )
    {
        mpDenoiseFilter = CIGLDenoiseFilterCreateFromFile(thePathname,
                                                          theContext,
                                                          theFormat);
    } // if
	
	return( self );
} // initDenoiseFilterFromFile

//---------------------------------------------------------------------------

- (id) initDenoiseFilterWithData:(NSData *)theData
                         context:(NSOpenGLContext *)theContext
                          format:(NSOpenGLPixelFormat *)theFormat
{
	self = [super init];
    
    if( self )
    {
        mpDenoiseFilter = CIGLDenoiseFilterCreateWithData(theData,
                                                          theContext,
                                                          theFormat);
    } // if
	
	return( self );
} // initDenoiseFilterWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------------

- (void) dealloc
{
	CIGLDenoiseFilterDelete(mpDenoiseFilter);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------------

- (void) bind
{
    [mpDenoiseFilter->filter bind];
} // bind

//---------------------------------------------------------------------------------

- (void) unbind
{
    [mpDenoiseFilter->filter unbind];
} // unbind

//---------------------------------------------------------------------------------

- (void) update
{
    [mpDenoiseFilter->filter update];
} // update

//---------------------------------------------------------------------------------

- (void) display
{ 
    [mpDenoiseFilter->filter display];
} // display

//---------------------------------------------------------------------------------

- (BOOL) readback
{
    return( [mpDenoiseFilter->filter readback] );
} // readback

//---------------------------------------------------------------------------------

- (BOOL) saveAs:(CFStringRef)theName
         UTType:(CFStringRef)theUTType
{
    return( [mpDenoiseFilter->filter saveAs:theName
                                     UTType:theUTType] );
} // saveAs

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities - Updating

//---------------------------------------------------------------------------------

- (BOOL) updateWithData:(NSData *)theData
{
	return( [mpDenoiseFilter->filter updateWithData:theData] );
} // updateWithData

//---------------------------------------------------------------------------------

- (BOOL) updateFromFile:(NSString *)thePathname
{
	return( [mpDenoiseFilter->filter updateFromFile:thePathname] );
} // updateFromFile

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities - Filter Selection

//---------------------------------------------------------------------------------

- (void) median
{
    mpDenoiseFilter->filter = mpDenoiseFilter->filterMedian;
    
    [mpDenoiseFilter->filter update];
} // median

//---------------------------------------------------------------------------------

- (void) noiseReduction
{
    mpDenoiseFilter->filter = mpDenoiseFilter->filterNR;
    
    [mpDenoiseFilter->filter update];
} // noiseReduction

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------------

- (GLenum) target
{
	return( [mpDenoiseFilter->filter target] );
} // target

//---------------------------------------------------------------------------------

- (GLfloat) aspect
{
	return( [mpDenoiseFilter->filter aspect] );
} // aspect

//---------------------------------------------------------------------------------

- (CGRect) extent
{
	return( [mpDenoiseFilter->filter extent] );
} // extent

//---------------------------------------------------------------------------------

- (CGSize) size
{
	return( [mpDenoiseFilter->filter size] );
} // size

//---------------------------------------------------------------------------------

- (CGImageRef) snapshot
{
    return( [mpDenoiseFilter->filter snapshot] );
} // snapshot

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Setters

//---------------------------------------------------------------------------------

- (BOOL) setNoiseLevel:(const CGFloat)theNoiseLevel
{
    return( [mpDenoiseFilter->filter setNoiseLevel:theNoiseLevel] );
} // setNoiseLevel

//---------------------------------------------------------------------------------

- (BOOL) setSharpness:(const CGFloat)theSharpness
{
    return( [mpDenoiseFilter->filter setSharpness:theSharpness] );
} // setSharpness

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

