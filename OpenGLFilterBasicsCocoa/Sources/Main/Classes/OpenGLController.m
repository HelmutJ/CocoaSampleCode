//---------------------------------------------------------------------------
//
//	File: OpenGLController.m
//
//  Abstract: Controller for passing data to the filter and updating
//            the OpenGL view with the results of the computation
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

#import "OpenGLController.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLController

//------------------------------------------------------------------------

- (void) initFilter
{
	self = [super init];
	
	textureSize = NSMakeSize( 1024, 1024 );		// Texture size = array size = 1024 x 1024
	dataBounds  = NSMakeRect( -1, -1, 1, 1 );	// Data bounds = orthographic projection 2D range
	
	// Dictionary for the uniform(s) associated with our fragment shader
	
	NSArray      *theUniformKeys       = [NSArray arrayWithObjects: @"textureUnit", nil];
	NSArray      *theUniformValues     = [NSArray arrayWithObjects: [NSNumber numberWithInt:0], nil];
	NSDictionary *theUniformDictionary = [NSDictionary dictionaryWithObjects:theUniformValues forKeys:theUniformKeys];

	// Instantiate a filter with the fragment shader, uniforms, data domain, 
	// and data capacity the size of our texture
	
	filter = [[OpenGLFilterUtilityToolKit alloc] initWithFilterInAppBundle:@"LaplacianEdgeDetectionFilter" 
														uniformDictionary:theUniformDictionary
														bounds:dataBounds
														size:textureSize];
} // initFilter

//------------------------------------------------------------------------

- (id) init
{
	// Initialize the Laplacian edge detection filter and its uniforms
	
	[self initFilter];
	
	// To demonstrate the capabilities of our filter, instantiate a rotating model
	// object so that we can continously generate and feed data into our filter
	
	models = [[OpenGLRotateModels alloc] init];
	
	return self;
} // initWithTimerAttributes

//------------------------------------------------------------------------

- (void) dealloc
{
	// The models are no longer needed

	[models dealloc];
	
	// The filter is no longer needed

	[filter dealloc];
	
	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Reshaping & updating the state --

//------------------------------------------------------------------------

- (void) reshape:(NSRect)theBounds
{
	[filter resize:theBounds];
} // reshape

//------------------------------------------------------------------------

#pragma mark -- Updating & Rendering textures --

//------------------------------------------------------------------------
//
// This method updates the texture by rendering the models (a rotating
// Stanford Bunny and 3 tori) and copying the image to a texture. Further-
// more in a second pass we render again by using the generated texture 
// as input to the installed filter.  The results produced by the filter 
// are then copied to the allocated texture. The resulting texture is 
// then used for visualizing the results of our computation.
//
//------------------------------------------------------------------------

- (void) update 
{
	[filter prepare];
	
	[models rotate];
	
	[filter run];
} // update

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

