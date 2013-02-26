//---------------------------------------------------------------------------
//
//	File: OpenGLExtUtilityToolkit.m
//
//  Abstract: Utility toolkit for checking hardware capabilities
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

#import <OpenGL/CGLRenderers.h>
#import <OpenGL/glext.h>
#import <OpenGL/gl.h>

#import "OpenGLPixelFormatAttribDictUtilityToolkit.h"
#import "OpenGLExtUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct OpenGLHardwareAttributes
{
	GLboolean  shaderObjectAvailable;
	GLboolean  shaderLanguage100Available;
	GLboolean  vertexShaderAvailable;
	GLboolean  fragmentShaderAvailable;
	GLboolean  clipVolumeHintExtAvailable;
	GLboolean  forceSoftwareRendering;
	
	NSInteger  pixelFormatAttributesCount;
	NSInteger  pixelFormatAttributesSize;
	
	NSOpenGLPixelFormatAttribute  *pixelFormatAttributes;
};

typedef struct OpenGLHardwareAttributes   OpenGLHardwareAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Check for extensions --

//------------------------------------------------------------------------

static inline GLboolean CheckForGLExtension( const char *extensionName, const GLubyte *extensions )
{
	GLboolean  bExtensionAvailable = gluCheckExtension( (GLubyte *)extensionName, extensions );
	
	return bExtensionAvailable;
} // CheckForExtension

//------------------------------------------------------------------------

static inline GLvoid AlertExtensionIsNotAvailable( const GLboolean extensionAvailable, const char *extensionName )
{
	if ( extensionAvailable == GL_FALSE )
	{
		NSRunAlertPanel
			(
				@"WARNING!", 
				@"\"%s\" extension is not available!", 
				@"OK", 
				nil, 
				nil, 
				extensionName
			);
	} // if
} // CheckForExtensions

//------------------------------------------------------------------------

static GLvoid CheckForShaders( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	const GLubyte *extensions = glGetString( GL_EXTENSIONS );
	
	theHardwareAttributes->shaderObjectAvailable      = CheckForGLExtension(       "GL_ARB_shader_objects", extensions );
	theHardwareAttributes->shaderLanguage100Available = CheckForGLExtension( "GL_ARB_shading_language_100", extensions );
	theHardwareAttributes->vertexShaderAvailable      = CheckForGLExtension(        "GL_ARB_vertex_shader", extensions );
	theHardwareAttributes->fragmentShaderAvailable    = CheckForGLExtension(      "GL_ARB_fragment_shader", extensions );
} // CheckForShaders

//------------------------------------------------------------------------
//
// Normally, one would use realloc() function here; but, we need to
// return NSOpenGLPixelFormatAttribute array with proper attributes
// set to force software rendering, without the concern for realloc()
// freeing the original memory.  For this reason we'll try a
// custom memory allocation routine.
//
//------------------------------------------------------------------------
	 
static GLvoid UpdateHardwareAttributesForForcedSoftwareRendering( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	
	NSInteger pixelFormatAttributesCount     = theHardwareAttributes->pixelFormatAttributesCount + 2;
	NSInteger pixelFormatAttributesSize      = pixelFormatAttributesCount * sizeof(NSOpenGLPixelFormatAttribute);
	NSInteger pixelFormatAttributesLastIndex = theHardwareAttributes->pixelFormatAttributesCount - 1; // Start with the old

	NSOpenGLPixelFormatAttribute *pixelFormatAttributes 
										= (NSOpenGLPixelFormatAttribute *)malloc( pixelFormatAttributesSize );
	
	if ( pixelFormatAttributes != NULL )
	{
		// The last index of NSOpenGLPixelFormatAttribute array
		
		NSInteger pixelFormatAttributesIndex;
		
		// Copy the old values (minus the last entry, becuase we know that one is zero)
		 
		for(	pixelFormatAttributesIndex = 0;
				pixelFormatAttributesIndex < pixelFormatAttributesLastIndex;
				pixelFormatAttributesIndex++ )
		{
			pixelFormatAttributes[pixelFormatAttributesIndex] 
					= theHardwareAttributes->pixelFormatAttributes[pixelFormatAttributesIndex];
		} // for
		
		// Update the last index value
		
		pixelFormatAttributesLastIndex = pixelFormatAttributesCount - 1;
				
		// This will designate the end of NSOpenGLPixelFormatAttribute array, 
		// akin to a null terminated array
		
		pixelFormatAttributes[pixelFormatAttributesLastIndex] = 0;
		
		// Now copy all the new values into the structure
		
		theHardwareAttributes->pixelFormatAttributesCount = pixelFormatAttributesCount;
		theHardwareAttributes->pixelFormatAttributesSize  = pixelFormatAttributesSize;
		
		// We don't need the old pixel attributes
		
		free( theHardwareAttributes->pixelFormatAttributes );
		
		// Now we point to the new pixel attributes
		
		theHardwareAttributes->pixelFormatAttributes = pixelFormatAttributes;
	} // if

	// For software rendering we want these to be the last two elements in
	// our NSOpenGLPixelFormatAttribute array

	pixelFormatAttributes[pixelFormatAttributesLastIndex - 2] = NSOpenGLPFARendererID;
	pixelFormatAttributes[pixelFormatAttributesLastIndex - 1] = kCGLRendererGenericFloatID;
} // UpdateHardwareAttributesForForcedSoftwareRendering

//------------------------------------------------------------------------

static GLvoid CheckForExecShadersInGPU( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	GLboolean  bForceSoftwareRendering = GL_FALSE;
	
	CheckForShaders( theHardwareAttributes );
	
	theHardwareAttributes->forceSoftwareRendering =		  
						   ( theHardwareAttributes->shaderObjectAvailable      == GL_FALSE )
						|| ( theHardwareAttributes->shaderLanguage100Available == GL_FALSE )
						|| ( theHardwareAttributes->vertexShaderAvailable      == GL_FALSE ) 
						|| ( theHardwareAttributes->fragmentShaderAvailable    == GL_FALSE );
	
	if ( bForceSoftwareRendering )
	{
		// Force software rendering, so fragment shaders will execute

		AlertExtensionIsNotAvailable(      theHardwareAttributes->shaderObjectAvailable, "GL_ARB_shader_objects"       );
		AlertExtensionIsNotAvailable( theHardwareAttributes->shaderLanguage100Available, "GL_ARB_shading_language_100" );
		AlertExtensionIsNotAvailable(      theHardwareAttributes->vertexShaderAvailable, "GL_ARB_vertex_shader"        );
		AlertExtensionIsNotAvailable(    theHardwareAttributes->fragmentShaderAvailable, "GL_ARB_fragment_shader"      );

		UpdateHardwareAttributesForForcedSoftwareRendering( theHardwareAttributes );
	} // if
} // CheckForExecShadersInGPU

//------------------------------------------------------------------------

static GLvoid CheckForClipVolumeHint( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	const GLubyte *extensions = glGetString(GL_EXTENSIONS);

	// Inform OpenGL that the geometry is entirely within the view volume and that view-volume 
	// clipping is unnecessary. Normal clipping can be resumed by setting this hint to GL_DONT_CARE. 
	// When clipping is disabled with this hint, results are undefined if geometry actually falls 
	// outside the view volume.

	theHardwareAttributes->clipVolumeHintExtAvailable = CheckForGLExtension( "GL_EXT_clip_volume_hint", extensions );
	
	if (  theHardwareAttributes->clipVolumeHintExtAvailable == GL_TRUE )
	{
		glHint( GL_CLIP_VOLUME_CLIPPING_HINT_EXT,GL_FASTEST );
	} // if
} // CheckForClipVolumeHint

//------------------------------------------------------------------------

static GLvoid CheckForGLSLHardwareSupport( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	// Create a pre-flight context to check for GLSL hardware support
	
	NSOpenGLPixelFormatAttribute  *pixelFormatAttributes = theHardwareAttributes->pixelFormatAttributes;
	NSOpenGLPixelFormat           *pixelFormat           = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
	
	if ( pixelFormat != nil )
	{
		NSOpenGLContext *preflight = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
		
		if ( preflight != nil )
		{
			[preflight makeCurrentContext];
		
				CheckForExecShadersInGPU( theHardwareAttributes );
				CheckForClipVolumeHint( theHardwareAttributes );
		
			[preflight release];
		} // if
	
		[pixelFormat release];
	} // if
} // CheckForGLSLHardwareSupport

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Allocate memory for hardware attributes --

//------------------------------------------------------------------------

static GLvoid MallocHardwareAttributesWithDefaultPixelFormat( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	theHardwareAttributes->pixelFormatAttributesCount = 6;
			
	theHardwareAttributes->pixelFormatAttributesSize  
			= 6 * sizeof(NSOpenGLPixelFormatAttribute);

	theHardwareAttributes->pixelFormatAttributes 
			= (NSOpenGLPixelFormatAttribute *)malloc( theHardwareAttributes->pixelFormatAttributesSize );

	if ( theHardwareAttributes->pixelFormatAttributes != NULL )
	{
		theHardwareAttributes->pixelFormatAttributes[0] = NSOpenGLPFADoubleBuffer;
		theHardwareAttributes->pixelFormatAttributes[1] = NSOpenGLPFADepthSize;
		theHardwareAttributes->pixelFormatAttributes[2] = 24;
		theHardwareAttributes->pixelFormatAttributes[3] = NSOpenGLPFAStencilSize;
		theHardwareAttributes->pixelFormatAttributes[4] = 8;
		theHardwareAttributes->pixelFormatAttributes[5] = 0;
	} // if
} // MallocHardwareAttributesWithDefaultPixelFormat

//------------------------------------------------------------------------

static GLvoid MallocHardwareAttributesWithPixelFormat(	OpenGLHardwareAttributesRef   theHardwareAttributes,
														NSDictionary                 *thePixelFormatAttributesDictionary )
{
	NSInteger thePixelFormatAttributesCount = 0;
	
	id thePixelFormatAttributesKey;

	OpenGLPixelFormatAttribDictUtilityToolkit *thePixelFormatAttributesDefaultDictionary
													= [OpenGLPixelFormatAttribDictUtilityToolkit withOpenGLPixelFormatAttributesDefaultDictionary];

	// Since we need to construct a pixel format attributes numerical array
	// we need to figure out how many elements it should contain
	
	for (thePixelFormatAttributesKey in thePixelFormatAttributesDictionary) 
	{
		if ( [thePixelFormatAttributesDefaultDictionary containsKeyMappingIntoBoolValue:thePixelFormatAttributesKey] )
		{
			// For keys that are paired with boolean values, advance the
			// the count once - since in our numerical array we need a
			// single entry
			
			thePixelFormatAttributesCount++;
		} // if
		else if ( [thePixelFormatAttributesDefaultDictionary containsKeyMappingIntoIntValue:thePixelFormatAttributesKey] )
		{
			// For keys that are paired with integer values, advance the
			// the count twice - since in our numerical array we need
			// two entries

			thePixelFormatAttributesCount += 2;
		} // else if
	} // for

	// Advance the count once more as the last value
	// in our numerical array must contain the value 
	// zero - signifying the end of our array
	
	thePixelFormatAttributesCount++;
	
	// Now allocate an array for our numerical representation

	theHardwareAttributes->pixelFormatAttributesCount 
			= thePixelFormatAttributesCount;

	theHardwareAttributes->pixelFormatAttributesSize
			= thePixelFormatAttributesCount * sizeof(NSOpenGLPixelFormatAttribute);

	theHardwareAttributes->pixelFormatAttributes 
			= (NSOpenGLPixelFormatAttribute *)malloc( theHardwareAttributes->pixelFormatAttributesSize );
	
	// If memory was allocated for our numerical representation then
	// copy the values from our dictionary into our numerical array
	
	if ( theHardwareAttributes->pixelFormatAttributes != NULL )
	{
		NSInteger  pixelFormatAttributesIndex = 0;

		for (thePixelFormatAttributesKey in thePixelFormatAttributesDictionary) 
		{
			NSInteger  thePixelFormatKeyIntRep 
							= [thePixelFormatAttributesDefaultDictionary getIntValueForTheKey:thePixelFormatAttributesKey];
			
			theHardwareAttributes->pixelFormatAttributes[pixelFormatAttributesIndex] = thePixelFormatKeyIntRep;
			
			pixelFormatAttributesIndex++;

			if ( [thePixelFormatAttributesDefaultDictionary containsKeyMappingIntoIntValue:thePixelFormatAttributesKey] )
			{
				NSNumber  *thePixelFormatValueNumRep = [thePixelFormatAttributesDictionary objectForKey:thePixelFormatAttributesKey];
				NSInteger  thePixelFormatValueIntRep = [thePixelFormatValueNumRep integerValue];

				theHardwareAttributes->pixelFormatAttributes[pixelFormatAttributesIndex] = thePixelFormatValueIntRep;
				
				pixelFormatAttributesIndex++;
			} // if
		} // for
		
		theHardwareAttributes->pixelFormatAttributes[pixelFormatAttributesIndex] = 0;
	} // if
} // MallocHardwareAttributesWithPixelFormat

//------------------------------------------------------------------------

static OpenGLHardwareAttributesRef MallocHardwareAttributesRef( NSDictionary *thePixelFormatAttributesDictionary )
{
	OpenGLHardwareAttributesRef theHardwareAttributes = (OpenGLHardwareAttributesRef)malloc( sizeof( OpenGLHardwareAttributes ) );

	if ( theHardwareAttributes != NULL )
	{
		if ( thePixelFormatAttributesDictionary == nil )
		{
			MallocHardwareAttributesWithDefaultPixelFormat( theHardwareAttributes );
		} // if
		else
		{
			MallocHardwareAttributesWithPixelFormat( theHardwareAttributes, thePixelFormatAttributesDictionary );
		} // if
	} // if
	
	return  theHardwareAttributes;
} // MallocHardwareAttributesRef

//------------------------------------------------------------------------

static GLvoid FreePixelFormatAttributesRef( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	if ( theHardwareAttributes->pixelFormatAttributes != NULL )
	{
		free( theHardwareAttributes->pixelFormatAttributes );
	} // if
} // FreePixelFormatAttributesRef

//------------------------------------------------------------------------

static GLvoid FreeHardwareAttributesRef( OpenGLHardwareAttributesRef theHardwareAttributes )
{
	if ( theHardwareAttributes != NULL )
	{
		FreePixelFormatAttributesRef( theHardwareAttributes );
		
		free( theHardwareAttributes );
	} // if
} // FreeHardwareAttributesRef

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLExtUtilityToolkit

//------------------------------------------------------------------------

- (id) initWithOpenGLPixelFormatAttributesDictionary:(NSDictionary *)thePixelFormatAttributesDictionary
{	
	self = [super init];
	
	hardwareAttributes = MallocHardwareAttributesRef( thePixelFormatAttributesDictionary );

	if ( hardwareAttributes != NULL )
	{
		CheckForGLSLHardwareSupport( hardwareAttributes );
		
		if ( hardwareAttributes->pixelFormatAttributes != NULL )
		{
			pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:hardwareAttributes->pixelFormatAttributes];
		} // if
	} // if
		
	return self;
} // initWithOpenGLPixelFormatAttributesDictionary

//------------------------------------------------------------------------

+ (id) withOpenGLPixelFormatAttributesDictionary:(NSDictionary *)thePixelFormatAttributesDictionary
{
	return  [[[OpenGLExtUtilityToolkit allocWithZone:[self zone]] 
						initWithOpenGLPixelFormatAttributesDictionary:thePixelFormatAttributesDictionary] autorelease];
} // withOpenGLPixelFormatAttributesDictionary

//------------------------------------------------------------------------

- (void) dealloc
{
	// Release hardware attributes opaque reference

	FreeHardwareAttributesRef( hardwareAttributes );
	
	// Pixel format object is no longer needed
	
	if ( pixelFormat )
	{
		[pixelFormat release];
	} // if
	
	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (BOOL) isShaderObjectAvailable
{
	BOOL  shaderObjectAvailable = NO;
	
	if ( hardwareAttributes->shaderObjectAvailable == GL_TRUE )
	{
		shaderObjectAvailable = YES;
	} // if
	
	return shaderObjectAvailable;
} // isShaderObjectAvailable

//------------------------------------------------------------------------

- (BOOL) isShaderLanguage100Available
{
	BOOL  shaderLanguage100Available = NO;
	
	if ( hardwareAttributes->shaderLanguage100Available == GL_TRUE )
	{
		shaderLanguage100Available = YES;
	} // if
	
	return shaderLanguage100Available;
} // isShaderLanguage100Available

//------------------------------------------------------------------------

- (BOOL) isVertexShaderAvailable
{
	BOOL  vertexShaderAvailable = NO;
	
	if ( hardwareAttributes->vertexShaderAvailable == GL_TRUE )
	{
		vertexShaderAvailable = YES;
	} // if
	
	return vertexShaderAvailable;
} // isVertexShaderAvailable

//------------------------------------------------------------------------

- (BOOL) isFragmentShaderAvailable
{
	BOOL  fragmentShaderAvailable = NO;
	
	if ( hardwareAttributes->fragmentShaderAvailable == GL_TRUE )
	{
		fragmentShaderAvailable = YES;
	} // if
	
	return fragmentShaderAvailable;
} // isFragmentShaderAvailable

//------------------------------------------------------------------------

- (BOOL) isClipVolumeHintExtAvailable
{
	BOOL  clipVolumeHintExtAvailable = NO;
	
	if ( hardwareAttributes->clipVolumeHintExtAvailable == GL_TRUE )
	{
		clipVolumeHintExtAvailable = YES;
	} // if
	
	return clipVolumeHintExtAvailable;
} // isClipVolumeHintExtAvailable

//------------------------------------------------------------------------

- (BOOL) isForcedSoftwareRendering
{
	BOOL  forceSoftwareRendering = NO;
	
	if ( hardwareAttributes->forceSoftwareRendering == GL_TRUE )
	{
		forceSoftwareRendering = YES;
	} // if
	
	return forceSoftwareRendering;
} // isForcedSoftwareRendering

//------------------------------------------------------------------------

- (NSOpenGLPixelFormat *) pixelFormat
{
	return pixelFormat;
} // pixelFormat

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

