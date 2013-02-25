//---------------------------------------------------------------------------------
//
//	File: GLSLHardwareSupport.c
//
//  Abstract: Check to see if fragment & vertex shader can execute in hardware.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
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
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#import "GLSLHardwareSupport.h"

//---------------------------------------------------------------------------------

#import <OpenGL/CGLRenderers.h>

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

static inline GLboolean CheckForExtension(const GLchar *extensionName, 
										  const GLubyte *extensions)
{
	GLboolean  bExtensionAvailable = gluCheckExtension((GLubyte *)extensionName, 
													   extensions);
	
	return bExtensionAvailable;
} // CheckForExtension

//---------------------------------------------------------------------------------

static inline void CheckForAndLogExtensionAvailable(const GLboolean extensionAvailable, 
													const GLchar *extensionName)
{
	if( extensionAvailable == GL_FALSE )
	{
		NSLog(@">> WARNING: \"%s\" extension is not available!\n", 
			  extensionName);
	} // if
} // CheckForExtensions

//---------------------------------------------------------------------------------

static void CheckForShaders(NSOpenGLPixelFormatAttribute *thePixelAttributes)
{
	const GLubyte *extensions = glGetString(GL_EXTENSIONS);
	
	GLboolean  bShaderObjectAvailable      = CheckForExtension("GL_ARB_shader_objects", extensions);
	GLboolean  bShaderLanguage100Available = CheckForExtension("GL_ARB_shading_language_100", extensions);
	GLboolean  bVertexShaderAvailable      = CheckForExtension("GL_ARB_vertex_shader", extensions);
	GLboolean  bFragmentShaderAvailable    = CheckForExtension("GL_ARB_fragment_shader", extensions);
	
	GLboolean  bForceSoftwareRendering =	(bShaderObjectAvailable == GL_FALSE)
	||	(bShaderLanguage100Available == GL_FALSE)
	||	(bVertexShaderAvailable == GL_FALSE) 
	||	(bFragmentShaderAvailable == GL_FALSE);
	
	if( bForceSoftwareRendering )
	{
		// Force software rendering, so fragment shaders will execute
		
		CheckForAndLogExtensionAvailable(bShaderObjectAvailable, "GL_ARB_shader_objects");
		CheckForAndLogExtensionAvailable(bShaderLanguage100Available, "GL_ARB_shading_language_100");
		CheckForAndLogExtensionAvailable(bVertexShaderAvailable, "GL_ARB_vertex_shader");
		CheckForAndLogExtensionAvailable(bFragmentShaderAvailable, "GL_ARB_fragment_shader");
		
		thePixelAttributes [3] = NSOpenGLPFARendererID;
		thePixelAttributes [4] = kCGLRendererGenericFloatID;
	} // if
} // CheckForShaders

//---------------------------------------------------------------------------------

static void CheckForClipVolumeHint(NSOpenGLPixelFormatAttribute *thePixelAttributes)
{
	const GLubyte *extensions = glGetString(GL_EXTENSIONS);
	
	// Inform OpenGL that the geometry is entirely within the 
	// view volume and that view-volume clipping is unnecessary. 
	// Normal clipping can be resumed by setting this hint to 
	// GL_DONT_CARE.  When clipping is disabled with this hint, 
	// results are undefined if geometry actually falls outside 
	//the view volume.
	
	GLboolean  bClipVolumeHintExtAvailable = CheckForExtension("GL_EXT_clip_volume_hint", 
															   extensions);
	
	if(   bClipVolumeHintExtAvailable == GL_TRUE)
	{
		glHint(GL_CLIP_VOLUME_CLIPPING_HINT_EXT,GL_FASTEST);
	} // if
} // CheckForClipVolumeHint

//---------------------------------------------------------------------------------

void CheckForGLSLHardwareSupport(NSOpenGLPixelFormatAttribute *thePixelAttributes)
{
	// Create a pre-flight context to check for GLSL hardware support
	
	NSOpenGLPixelFormat  *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:thePixelAttributes];
	
	if( pixelFormat != nil )
	{
		NSOpenGLContext *preflight = [[NSOpenGLContext alloc] initWithFormat:pixelFormat
																shareContext:nil];
		
		if( preflight != nil )
		{
			[preflight makeCurrentContext];
			
			CheckForShaders(thePixelAttributes);
			CheckForClipVolumeHint(thePixelAttributes);
			
			[preflight   release];
		} // if
		
		[pixelFormat release];
	} // if
} // CheckForGLSLHardwareSupport

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------
