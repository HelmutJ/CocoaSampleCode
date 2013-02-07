//---------------------------------------------------------------------------
//
//	File: OpenGLImage2DAuthor.m
//
//  Abstract: A facade for handling PBO Read or draw pixels.
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

#import "OpenGLImage2DAuthorProtocol.h"

#import "OpenGLImage2DReader.h"
#import "OpenGLImage2DWriter.h"
#import "OpenGLImage2DAuthor.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLImage2DAuthorData
{
    BOOL isReadOnly;
    BOOL isWriteOnly;
    
    NSSize size;
    
    id<OpenGLImage2DAuthorProtocol> author;
};

typedef struct OpenGLImage2DAuthorData   OpenGLImage2DAuthorData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static OpenGLImage2DAuthorDataRef OpenGLImage2DAuthorCreate(const NSSize *pSize,
                                                            const GLenum  usage,
                                                            const GLenum format)
{
	OpenGLImage2DAuthorDataRef pImage2DAuthor = (OpenGLImage2DAuthorDataRef)calloc(1, sizeof(OpenGLImage2DAuthorData));
	
	if( pImage2DAuthor != NULL )
	{
        pImage2DAuthor->isWriteOnly = (usage == GL_STREAM_DRAW) || (usage == GL_STATIC_DRAW) || (usage == GL_DYNAMIC_DRAW);
        pImage2DAuthor->isReadOnly  = (usage == GL_STREAM_READ) || (usage == GL_STATIC_READ) || (usage == GL_DYNAMIC_READ);
        
        if( pImage2DAuthor->isWriteOnly )
        {
            pImage2DAuthor->author = [[OpenGLImage2DWriter alloc] initImage2DWriterWithSize:pSize
                                                                                      usage:usage
                                                                                     format:format];
        } // if
        else
        {
            if( !pImage2DAuthor->isReadOnly )
            {
                NSLog( @">> WARNING: OpenGL Image 2D Author - Invalid usage!" );
                NSLog( @">> WARNING: OpenGL Image 2D Author - Usage is set to stream read!" );
            } // if
            
            pImage2DAuthor->author = [[OpenGLImage2DReader alloc] initImage2DReaderWithSize:pSize
                                                                                      usage:usage
                                                                                     format:format];
        } // else
        
        if( pImage2DAuthor->author )
        {
            pImage2DAuthor->size.width  = (CGFloat)[pImage2DAuthor->author width];
            pImage2DAuthor->size.height = (CGFloat)[pImage2DAuthor->author height];
        } // if
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL Image 2D Author - Allocating memory for authoring failed!" );
    } // else
	
	return( pImage2DAuthor );
} // OpenGLImage2DAuthorCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLImage2DAuthorDelete(OpenGLImage2DAuthorDataRef pImage2DAuthor)
{
	if( pImage2DAuthor != NULL )
	{
        if( pImage2DAuthor->author )
        {
            [pImage2DAuthor->author release];
            
            pImage2DAuthor->author = nil;
        } // if
        
		free( pImage2DAuthor );
		
		pImage2DAuthor = NULL;
	} // if
} // OpenGLImage2DAuthorDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLImage2DAuthor

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initImage2DAuthorWithSize:(const NSSize *)theSize
                           usage:(const GLenum)theUsage
                          format:(const GLenum)theFormat;
{
	self = [super init];
	
	if( self )
	{
		mpImage2DAuthor = OpenGLImage2DAuthorCreate(theSize, 
                                                    theUsage, 
                                                    theFormat);
	} // if
	
	return  self;
} // initImage2DAuthorWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLImage2DAuthorDelete(mpImage2DAuthor);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( [mpImage2DAuthor->author width] );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( [mpImage2DAuthor->author height] );
} // height

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( [mpImage2DAuthor->author size] );
} // size

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
    return( [mpImage2DAuthor->author rowBytes] );
} // rowbytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
    return( [mpImage2DAuthor->author samplesPerPixel] );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( [mpImage2DAuthor->author buffer] );
} // buffer

//---------------------------------------------------------------------------

- (NSSize) bounds
{
    return( mpImage2DAuthor->size );
} // bounds

//---------------------------------------------------------------------------

- (BOOL) isReadOnly
{
    return( mpImage2DAuthor->isReadOnly );
} // isReadOnly

//---------------------------------------------------------------------------

- (BOOL) isWriteOnly
{
    return( mpImage2DAuthor->isWriteOnly );
} // isWriteOnly

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( [mpImage2DAuthor->author setSize:theSize] );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) map
{
    return( [mpImage2DAuthor->author map] );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( [mpImage2DAuthor->author unmap] );
} // unmap

//---------------------------------------------------------------------------

- (BOOL) copy:(const GLvoid *)theBuffer
      needsVR:(const BOOL)doVR
{
    return( [mpImage2DAuthor->author copy:theBuffer
                                  needsVR:doVR] );
} // write

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
