//---------------------------------------------------------------------------
//
//	File: OpenGLFilterUtilityToolKit.m
//
//       Portions derived from the work authored by Mark J. Harris
//       and Mike Weiblen.
//
//  Abstract: Utility class for installing an image processing filter
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

//------------------------------------------------------------------------

#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>

#import "OpenGLFilterUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct FilterAttributes
{
	GLint    *uniformLocation;	// Texture unit in this case
	GLint     uniformValue;		// The uniform initial value
	GLdouble  orth2DRange[4];	// Frame for 2D orthographic projection matrix
};

typedef struct FilterAttributes   FilterAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLFilterUtilityToolKit

//------------------------------------------------------------------------

#pragma mark -- Kernel Utilities --

//------------------------------------------------------------------------

- (void) setUniformValue:(NSDictionary *)theUniformDictionary  uniformKeys:(NSArray *)theUniformKeys
{
	NSString  *theUniformKey = [theUniformKeys objectAtIndex:0];
	
	if ( theUniformKey )
	{
		NSNumber *theUniformNumber = [theUniformDictionary objectForKey:theUniformKey];
		
		if ( theUniformNumber )
		{
			filterAttributes->uniformValue = [theUniformNumber integerValue];

			// Identify the bound texture unit as input to the filter
			
			// For details on glUniform1iARB refer to:
			//
			// http://developer.3dlabs.com/openGL2/slapi/UniformARB.htm
			
			glUniform1iARB(	filterAttributes->uniformLocation[0], 
							filterAttributes->uniformValue );
		} // if
	} // if
} // setUniformValue

//------------------------------------------------------------------------

#pragma mark -- Initializing a new filter --

//------------------------------------------------------------------------

- (void) initComputationalKernel:(NSString *)theFilterName
						uniformDictionary:(NSDictionary *)theUniformDictionary
						bounds:(NSRect)theBounds
{
	// If one has a uniform associated with a fragment shader
	// initiliaze its dictionary here
	
	NSArray *theUniformKeys = [theUniformDictionary allKeys];
	
	if ( theUniformKeys )
	{
		// Compile, link and get a program object
		
		kernel = [[OpenGLFragmentShaderUtilityToolkit alloc] initWithFragmentShaderInAppBundle:theFilterName 
																						uniformKeys:theUniformKeys
																						bounds:theBounds];

		if ( kernel )
		{
			// Once the fragment shader has been compiled, linked and 
			// bound to a program object, cache the uniform location.
			
			filterAttributes->uniformLocation = [kernel uniformLocation];
			
			[kernel enable];
			
			[self setUniformValue:theUniformDictionary uniformKeys:theUniformKeys];
			
			[kernel disable];
		} // if
	} // if
} // initComputationalKernel

//------------------------------------------------------------------------

 - (void) initOrth2DRange:(NSRect)theBounds
{
	filterAttributes->orth2DRange[0] = theBounds.origin.x;		// left
	filterAttributes->orth2DRange[1] = theBounds.size.width;	// right
	filterAttributes->orth2DRange[2] = theBounds.origin.y;		// bottom
	filterAttributes->orth2DRange[3] = theBounds.size.height;	// top
} // initOrth2DRange
 
//------------------------------------------------------------------------

 - (void) initFilterAttributes
{
	filterAttributes = (FilterAttributesRef)malloc( sizeof( FilterAttributes ) );
	
	if ( filterAttributes != NULL )
	{
		filterAttributes->uniformLocation = NULL;
		filterAttributes->uniformValue    = 0;
		filterAttributes->orth2DRange[0]  = 0;
		filterAttributes->orth2DRange[1]  = 0;
		filterAttributes->orth2DRange[2]  = 0;
		filterAttributes->orth2DRange[3]  = 0;
	} // if
} // initFilterAttributes

//------------------------------------------------------------------------

- (id) initWithFilterInAppBundle:(NSString *)theFilterName 
						uniformDictionary:(NSDictionary *)theUniformDictionary
						bounds:(NSRect)theBounds
						size:(NSSize)theSize
{
	if ( theFilterName )
	{
		[self initFilterAttributes];
		
		if ( filterAttributes != NULL )
		{
			// Framebuffer object is initialized here
			
			fbo = [[OpenGLFBOUtilityToolKit alloc] initWithTextureSize:theSize bounds:theBounds];
			
			// Fragment shader is initialized here
			
			[self initComputationalKernel:theFilterName uniformDictionary:theUniformDictionary bounds:theBounds];
			
			// Map the domain values into 2D range used for orthographic 
			// projection matrix
			
			[self initOrth2DRange:theBounds];
		} // if
	} // if
	
	return self;
} // initWithFilterInAppBundle

//------------------------------------------------------------------------

#pragma mark -- Deleting the filter --

//------------------------------------------------------------------------

- (void) deallocFilterAttributes
{
	// Delete filter resources
	
	if ( filterAttributes != NULL )
	{
		free( filterAttributes );
	} // if
	
	filterAttributes = NULL;
} // deallocFilterAttributes

//------------------------------------------------------------------------

- (void) dealloc
{
	// The FBO is no longer needed
	
	[fbo dealloc];
	
	// The fragment shader is not needed
	
	[kernel dealloc];
	
	// Delete the filter opaque data reference
	
	[self deallocFilterAttributes];
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Utility routine for filter application --

//------------------------------------------------------------------------
//
// Here we shall demonstrate one-to-one pixel to texel mapping via the 
// use of a data-dimensioned viewport.  Namely, we need a one-to-one 
// mapping of pixels to texels in order to ensure every element of our 
// texture is processed. By setting our viewport to the dimensions of 
// our destination texture and drawing a screen-sized quad, we ensure 
// that every pixel of our texel is generated and processed in the 
// fragment program.
//
//------------------------------------------------------------------------

- (void) prepare
{	
	// Bind to the FBO and draw into it and set the viewport to 
	// the dimensions of our texture

	[fbo bind];
	
	// Initialize some states before rendering a geometry/model
	
	glClear( GL_COLOR_BUFFER_BIT );
	
	glMatrixMode( GL_MODELVIEW );

	// After this stage, one would normally feed data into a filter
	// by, for example, rendering some 3D models
} // prepare

//------------------------------------------------------------------------
//
// This method updates the texture by rendering a geometry, or a model,
// and then copying the rendered image to a texture.  During a second
// rendering pass, the same geometry, or the model, is re-rendered using  
// the texture as input to a filter.  Lastly, the output from the filter 
// are copied to the texture. The texture can now be used for displaying 
// the results.
//
//------------------------------------------------------------------------

-(void) run 
{
	// Copy the results to the FBO bound texture

	[fbo draw];

		// Execute the computational kernel
		
		[kernel execute];
	
	// Display the results
	
	[fbo unbind];
} // updateView

//------------------------------------------------------------------------
//
// Properly set the viewport bounds
//
//------------------------------------------------------------------------

- (void) setViewport:(NSRect)theBounds
{
	GLsizei theWidth  = (GLsizei)theBounds.size.width;
	GLsizei theHeight = (GLsizei)theBounds.size.height;
	
    if ( theHeight == 0 )
	{
		theHeight = 1;
	} //if 
    
    glViewport( 0, 0, theWidth, theHeight );
} // setViewport

//------------------------------------------------------------------------
//
// To demonstrate the concept of a one-to-one mapping of pixels to texels, 
// here we shall set the projection matrix to orthographic, in a closed 
// domain with bounds of [X,Y'] in the coordinate system with dimensions 
// determined by {x,y}.
//
//------------------------------------------------------------------------

- (void) mapPixelsToTexels
{
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity( );
	
    gluOrtho2D(	filterAttributes->orth2DRange[0], 
				filterAttributes->orth2DRange[1], 
				filterAttributes->orth2DRange[2], 
				filterAttributes->orth2DRange[3] );
	
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity( );          
} // mapPixelsToTexels

//------------------------------------------------------------------------
//
// Our data domain here is defined by
//
//      D = { [X,Y]x[X',Y'] }
//
// where
//
//      [X,Y] represents the origin,
//
//      [X',Y'] represents the coordinates defined by X'=X+W 
//              and the Y'=Y+H, with W=Width and H=Height.
//
// Here we shall set the frustum to orthographic, and the frustum
// dimensions to [X,Y'].  Hence, our viewport-sized quad vertices 
// becomes the corners of the viewport or 
//
//          [X,Y']             [X',Y']
//            +-------------------+
//            |                   |
//            |                   |
//            |                   |
//            +-------------------+
//          [X,Y]              [X',Y]
//
//------------------------------------------------------------------------

- (void) resize:(NSRect)theBounds
{
	// Properly resize the viewport
	
	[self setViewport:theBounds];
	
    // One-to-one Pixel to texel mapping using an orthographic 
	// projection matrix

	[self mapPixelsToTexels];
} // resize

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

