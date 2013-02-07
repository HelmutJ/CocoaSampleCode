//---------------------------------------------------------------------------
//
//	File: QTCVOpenGLView.m
//
//  Abstract: Main view class
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

#import "OpenGLQuad.h"
#import "OpenGLTeapot.h"

#import "CVGLImagebuffer.h"

#import "QTCVOpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct QTCVOpenGLViewData
{
    CVGLImagebuffer *imagebuffer;
    OpenGLQuad      *quad;
    OpenGLTeapot    *teapot;
    GeometryType     geometry;
};

typedef struct QTCVOpenGLViewData   QTCVOpenGLViewData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Methods

//---------------------------------------------------------------------------

@interface QTCVOpenGLView(Private)

- (void) deleteQuad;
- (void) deleteTeapot;
- (void) deleteImagebuffer;
- (void) deleteObjects;

- (void) drawObjects;

- (void) prepareQuad:(const NSSize *)theFrameSize;
- (void) prepareTeapot:(const NSSize *)theFrameSize;
- (void) prepareImagebuffer:(const NSSize *)theFrameSize;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation QTCVOpenGLView

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Application Startup

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (void) awakeFromNib
{
    mpQTCVGLView = (QTCVOpenGLViewDataRef)malloc(sizeof(QTCVOpenGLViewData));
    
    if( mpQTCVGLView != NULL )
    {
        mpQTCVGLView->geometry    = kGeometryQuad;
        mpQTCVGLView->teapot      = nil;
        mpQTCVGLView->quad        = nil;
        mpQTCVGLView->imagebuffer = nil;
    } // if
} // awakeFromNib

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) deleteQuad
{
	if( mpQTCVGLView->quad )
	{
		[mpQTCVGLView->quad release];
		
		mpQTCVGLView->quad = nil;
	} // if
} // deleteQuad

//---------------------------------------------------------------------------

- (void) deleteTeapot
{
	if( mpQTCVGLView->teapot )
	{
		[mpQTCVGLView->teapot release];
		
		mpQTCVGLView->teapot = nil;
	} // if
} // deleteTeapot

//---------------------------------------------------------------------------

- (void) deleteImagebuffer
{
	if( mpQTCVGLView->imagebuffer )
	{
		[mpQTCVGLView->imagebuffer release];
		
		mpQTCVGLView->imagebuffer = nil;
	} // if
} // deleteImagebuffer

//---------------------------------------------------------------------------

- (void) deleteObjects
{
    [self deleteImagebuffer];
    [self deleteQuad];
    [self deleteTeapot];
} // deleteObjects

//---------------------------------------------------------------------------

- (void) cleanUp
{
	[super cleanUp];
    
    if( mpQTCVGLView != NULL )
    {
        [self deleteObjects];
        
        free( mpQTCVGLView );
        
        mpQTCVGLView = NULL;
    } // if
} // cleanUp

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUp];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Draw into a OpenGL view

//---------------------------------------------------------------------------

- (void) drawObjects
{
	if( mpQTCVGLView->geometry == kGeometryTeapot ) 
	{
		[mpQTCVGLView->teapot display];
	} // if
	else
	{
		[mpQTCVGLView->quad display];
	} // else
} // drawObjects

//---------------------------------------------------------------------------

- (void) drawScene
{
    if( [self isValid] )
    {
        // Update the imagebuffer
        
        [mpQTCVGLView->imagebuffer update:[self pixelBuffer]];
        
        // Update the viewport properties
        
        [self updateViewport];
        
        // Get the texture from the imagebuffer
        
        [mpQTCVGLView->imagebuffer bind];
        
        // Draw the 3D objects
        
        [self drawObjects];
        
        // Disable texture target
        
        [mpQTCVGLView->imagebuffer unbind];
    } // if
} // drawScene

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initialize OpenGL resources for a movie

//---------------------------------------------------------------------------

- (void) prepareQuad:(const NSSize *)theFrameSize
{
	// Delete the old quad object
	
	[self deleteQuad];
	
	// Instantiate a new quad object
	
    mpQTCVGLView->quad = [OpenGLQuad new];
    
    if( mpQTCVGLView->quad )
    {
        GLfloat texCoords[8];
        
        texCoords[0] = 0.0f;
        texCoords[1] = 0.0f;
        texCoords[2] = 0.0f;
        texCoords[3] = theFrameSize->height;
        texCoords[4] = theFrameSize->width;
        texCoords[5] = theFrameSize->height;
        texCoords[6] = theFrameSize->width;
        texCoords[7] = 0.0f;
        
        [mpQTCVGLView->quad setSize:theFrameSize];
        [mpQTCVGLView->quad setTexCoords:texCoords];
        
        [mpQTCVGLView->quad acquire];
    } // if
} // prepareQuad

//---------------------------------------------------------------------------

- (void) prepareTeapot:(const NSSize *)theFrameSize
{
	// Delete the old teapot object
	
	[self deleteTeapot];
	
	// Instantiate a new teapot object
	
	mpQTCVGLView->teapot = [[OpenGLTeapot alloc] initTeapotWithPListInAppBundle:@"Teapot"
                                                                           size:theFrameSize
                                                                         target:[mpQTCVGLView->imagebuffer target]];
} // prepareTeapot

//---------------------------------------------------------------------------

- (void) prepareImagebuffer:(const NSSize *)theFrameSize
{
	// Delete the old CoreVideo imagebuffer
	
	[self deleteImagebuffer];
	
	// Instantiate a new pbo object
	
    mpQTCVGLView->imagebuffer = [[CVGLImagebuffer alloc] initImagebufferWithSize:theFrameSize
                                                                          target:GL_TEXTURE_RECTANGLE_ARB
                                                                          format:[self format]];
} // prepareImagebuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Acquire OpenGL Resources

//---------------------------------------------------------------------------
//
// Concrete implementation in order to acquire 3D objects.
//
//---------------------------------------------------------------------------

- (void) prepareScene
{
	NSSize frameSize = [self size];
    
    [self prepareImagebuffer:&frameSize];
	[self prepareQuad:&frameSize];
	[self prepareTeapot:&frameSize];
} // prepareScene

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------
//
// Geometry for drawing
//
//---------------------------------------------------------------------------

- (void) setGeometry:(const GeometryType)theGeometry;
{
	mpQTCVGLView->geometry = theGeometry;
} // setGeometry

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
