//---------------------------------------------------------------------------
//
//	File: OpenGLFragmentShaderUtilityToolkit.m
//
//  Abstract: Utility class for compiling a fragment shader and binding
//            it to a program object
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

#import "OpenGLAlertsUtilityToolkit.h"
#import "OpenGLFragmentShaderUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct FragmentShaderAttributes
{
	GLint         *uniformLocation;				// A parameter to the fragment program
	GLuint         uniformCount;				// the number of uniforms
	GLhandleARB    programObject;				// The program used to update
	BOOL           fragmentShaderIsInstalled;	// True if the fragment shader installed
};

typedef struct FragmentShaderAttributes   FragmentShaderAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Compiling, link & bind to a program object --

//------------------------------------------------------------------------

static GLvoid DisplayAlertWithStatus( GLenum theStatus )
{
	OpenGLAlertsUtilityToolkit *alert = [OpenGLAlertsUtilityToolkit withAlertType:alertIsForOpenGLShaders];
	
	if ( alert )
	{
		[alert displayAlertBox:theStatus];
	} // if
} // DisplayAlertWithStatus

//------------------------------------------------------------------------

static GLhandleARB LoadShader( GLenum theShaderType, const GLcharARB **theShader, GLint *theShaderCompiled ) 
{
	GLhandleARB shaderObj = NULL;
	
	if ( theShader != NULL ) 
	{
		GLint infoLogLength = 0;
		
		// For details on glCreateShaderObjectARB refer to:
		//
		// http://developer.3dlabs.com/openGL2/slapi/CreateShaderObjectARB.htm

		shaderObj = glCreateShaderObjectARB( theShaderType );

		// For details onn glShaderSourceARB refer to:
		//
		// http://developer.3dlabs.com/openGL2/slapi/ShaderSourceARB.htm
		
		glShaderSourceARB( shaderObj, 1, theShader, NULL );
		
		// For details on glCompileShaderARB refer to:
		// 
		// http://developer.3dlabs.com/openGL2/slapi/CompileShaderARB.htm

		glCompileShaderARB( shaderObj );
		
		// For details on glGetObjectParameterARB refer to:
		//
		// http://developer.3dlabs.com/openGL2/slapi/GetObjectParameterARB.htm
		
		glGetObjectParameterivARB( shaderObj, GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength );
		
		if ( infoLogLength > 0 ) 
		{
			GLchar *infoLog = (GLchar *)malloc( infoLogLength );
			
			if ( infoLog != NULL )
			{
				// For details on glGetInfoLogARB refer to:
				//
				// http://developer.3dlabs.com/openGL2/slapi/GetInfoLogARB.htm
		
				glGetInfoLogARB( shaderObj, infoLogLength, &infoLogLength, infoLog );
				
				NSLog( @">> MESSAGE: Shader compile log:\n%s\n", infoLog );
				
				free( infoLog );
			} // if
		} // if

		glGetObjectParameterivARB( shaderObj, GL_OBJECT_COMPILE_STATUS_ARB, theShaderCompiled );
		
		if ( *theShaderCompiled == 0 )
		{
			DisplayAlertWithStatus( GL_OBJECT_COMPILE_STATUS_ARB );
			
			NSLog( @">> ERROR: Failed to compile shader %s\n", theShader );
		} // if 
	} // if
	else 
	{
		*theShaderCompiled = 0;
	} // else
	
	return shaderObj;
} // LoadShader

//------------------------------------------------------------------------

static BOOL GetFragmentShader( const GLchar  *theFragmentShaderSource, GLhandleARB *theFragmentShader )
{
	GLhandleARB  fragmentShader                   = NULL;  // the fragment shader to update
	GLint        fragmentShaderCompiled           = 0;
	BOOL         fragmentShaderCompilationSuccess = YES;
	
	// Load and compile both shaders
	
	fragmentShader = LoadShader( GL_FRAGMENT_SHADER_ARB, &theFragmentShaderSource, &fragmentShaderCompiled );

	// Ensure both shaders compiled
	
	if ( !fragmentShaderCompiled ) 
	{
		if ( fragmentShader != NULL ) 
		{
			// For details on glDeleteObjectARB refer to:
			// 
			// http://developer.3dlabs.com/openGL2/slapi/DeleteObjectARB.htm
	
			glDeleteObjectARB( fragmentShader );
			
			fragmentShader = NULL;
		} // if
		
		fragmentShaderCompilationSuccess = NO;
	} // if
	
	*theFragmentShader = fragmentShader;
	
	return  fragmentShaderCompilationSuccess;
} // GetFragmentShader

//------------------------------------------------------------------------

static BOOL LinkProgram( GLhandleARB theProgramObject ) 
{
	GLint  infoLogLength      = 0;
	GLint  programLinked      = 0;
	BOOL   programLinkSuccess = YES;
	
	// For details on glLinkProgramARB refer to:
	//
	// http://developer.3dlabs.com/openGL2/slapi/LinkProgramARB.htm
	
	glLinkProgramARB( theProgramObject );
	
	glGetObjectParameterivARB( theProgramObject , GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength );
	
	if ( infoLogLength >  0) 
	{
		GLchar *infoLog = (GLchar *)malloc( infoLogLength );
		
		glGetInfoLogARB( theProgramObject, infoLogLength, &infoLogLength, infoLog );
		
		NSLog( @">> MESSAGE: Program link log:\n%s\n", infoLog );
		
		free( infoLog );
	} // if
	
	glGetObjectParameterivARB( theProgramObject, GL_OBJECT_LINK_STATUS_ARB, &programLinked );
	
	if ( programLinked == 0 )
	{
		DisplayAlertWithStatus( GL_OBJECT_LINK_STATUS_ARB );

		NSLog( @">> ERROR: Failed to link program %ld\n", (GLint)theProgramObject );
		
		programLinkSuccess = NO;
	} // if
	
	return  programLinkSuccess;
} // LinkProgram

//------------------------------------------------------------------------

static BOOL GetProgramObject( GLhandleARB *theFragmentShader, GLhandleARB *theProgramObject )
{
	BOOL   programLinked = YES;
	
	// Create a program object and link with the fragment shaders
	
	// For details on glCreateProgramObjectARB refer to:
	//
	// http://developer.3dlabs.com/openGL2/slapi/CreateProgramObjectARB.htm

	*theProgramObject = glCreateProgramObjectARB();
	
	if ( *theFragmentShader != NULL )
	{
		// For details on glAttachObjectARB refer to:
		//
		// http://developer.3dlabs.com/openGL2/slapi/AttachObjectARB.htm
		
		glAttachObjectARB( *theProgramObject, *theFragmentShader );
		
		glDeleteObjectARB( *theFragmentShader); // Release
		
		*theFragmentShader = NULL;
	} // if
	
	programLinked = LinkProgram( *theProgramObject );

	if ( !programLinked ) 
	{
		glDeleteObjectARB( *theProgramObject );
		
		*theProgramObject = NULL;
		
		programLinked = NO;
	} // if
	
	return  programLinked;
} // GetProgramObject

//------------------------------------------------------------------------

static GLint *GetUniformLocationsFromNames(	GLhandleARB theProgramObject, NSArray *theUniformKeys )
{
	GLint  *theUniformLocation = NULL;
	
	if ( theUniformKeys )
	{
		GLuint theUniformLocationsCount = [theUniformKeys count];
		
		theUniformLocation = (GLint *)malloc( theUniformLocationsCount * sizeof(GLint) );
		
		if ( theUniformLocation != NULL )
		{
			id          theUniformKey           = nil;
			GLcharARB  *theUniformName          = NULL;
			GLint       theUniformLocationIndex = 0;
		
			for (theUniformKey in theUniformKeys)
			{
				theUniformName = (GLcharARB *)[theUniformKey cStringUsingEncoding:NSASCIIStringEncoding];
				
				// For details on glGetUniformLocationARB refer to:
				//
				// http://developer.3dlabs.com/openGL2/slapi/GetUniformLocationARB.htm
				
				theUniformLocation[theUniformLocationIndex] = glGetUniformLocationARB( theProgramObject, theUniformName );
				
				theUniformLocationIndex++;
			} // for
		} // if
	} // if
	
	return  theUniformLocation;
} // GetUniformNamesFromArray

//------------------------------------------------------------------------

static BOOL GetNewProgramObject(	const GLchar                 *theFragmentShaderSource,
									NSArray                      *theUniformKeys,
									FragmentShaderAttributesRef   theFragmentShaderAttributesRef )
{
	GLhandleARB  programObject    = NULL;		// the program used to update
	GLhandleARB  fragmentShader   = NULL;		// the fragment shader to update
	BOOL         gotProgramObject = NO;
	
	// Load and compile the fragment shader and bind this to a program object
	
	if ( GetFragmentShader( theFragmentShaderSource, &fragmentShader ) )
	{
		// If we succeeded in compiling the fragment shader, now link and
		// bind it to a program object
		
		if( GetProgramObject( &fragmentShader, &programObject ) )
		{
			// Get location of the uniform(s)
			
			theFragmentShaderAttributesRef->programObject   = programObject;
			theFragmentShaderAttributesRef->uniformLocation = GetUniformLocationsFromNames( programObject, theUniformKeys );
			theFragmentShaderAttributesRef->uniformCount    = [theUniformKeys count];
			
			gotProgramObject = YES;
		} // if
	} // if
	
	return gotProgramObject;
} // GetNewProgramObject

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Load the fragment shader source --

//------------------------------------------------------------------------

static GLcharARB *GetFragmentShaderSourceFromResource( NSString *theFragmentShaderResourceName )
{
	GLcharARB  *fragmentShaderSource = NULL;
	NSBundle   *applicationBundle    = [NSBundle mainBundle];
	
	if ( applicationBundle )
	{
		// Load the fragment shader source (text file) from the application bundle
		
		NSString  *fragmentShaderTempSource = [applicationBundle pathForResource:theFragmentShaderResourceName ofType: @"frag"];
		
		if ( fragmentShaderTempSource )
		{
			// Convert the shader source from a NSString into a C-string
			
			fragmentShaderTempSource = [NSString stringWithContentsOfFile:fragmentShaderTempSource];
			fragmentShaderSource     = (GLcharARB *)[fragmentShaderTempSource cStringUsingEncoding:NSASCIIStringEncoding];
		} //if
	}  // if
	
	return  fragmentShaderSource;
} // getFragmentShaderSourceFromResource

//------------------------------------------------------------------------
//
// A fragment shader represents a computational kernel applied in parallel 
// to multiple fragments simultaneously.
//
//------------------------------------------------------------------------

static BOOL GetFragmentShaderFromSource(	NSString                    *theFragmentshaderName, 
											NSArray                     *theUniformKeys, 
											FragmentShaderAttributesRef  theFragmentShaderAttributesRef )
{
	BOOL fragmentShaderIsLoaded = NO;
	
	// Get the GLSL fragment shader source (a text file) from the
	// application bundle and return it as a C-String

	GLcharARB *fragmentShaderSource = GetFragmentShaderSourceFromResource( theFragmentshaderName );
	
	if ( fragmentShaderSource != NULL )
	{
		// Get the program object by first compiling the fragment shader source,
		// then linking the compiled shader, and binding it to a program object

		fragmentShaderIsLoaded = GetNewProgramObject( fragmentShaderSource, theUniformKeys, theFragmentShaderAttributesRef );

		if ( !fragmentShaderIsLoaded )
		{
			NSLog( @">> ERROR:  Failed to load, compile and bind the fragment \"%@\" shader to the program object!\n",  theFragmentshaderName );
		} // if
	} // if
	
	return  fragmentShaderIsLoaded;
} // GetFragmentShaderFromSource

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Handling opaque data reference memory --

//------------------------------------------------------------------------

static FragmentShaderAttributesRef CallocFragmentShaderAttributesRef( )
{
	FragmentShaderAttributesRef fragmentShaderAttributes = (FragmentShaderAttributesRef)malloc( sizeof( FragmentShaderAttributes ) );
	
	if ( fragmentShaderAttributes != NULL )
	{
		fragmentShaderAttributes->programObject             = NULL;
		fragmentShaderAttributes->uniformLocation           = NULL;
		fragmentShaderAttributes->uniformCount              = 0;
		fragmentShaderAttributes->fragmentShaderIsInstalled = NO;
	} // if
	
	return  fragmentShaderAttributes;
} // CallocFragmentShaderAttributesRef

//------------------------------------------------------------------------

static GLvoid FreeFragmentShaderAttributesRef( FragmentShaderAttributesRef theFragmentShaderAttributesRef )
{
	// Delete OpenGL resources
	
	if ( theFragmentShaderAttributesRef->programObject != NULL )
	{
		glDeleteObjectARB( theFragmentShaderAttributesRef->programObject );
	} // if
	
	if ( theFragmentShaderAttributesRef->uniformLocation != NULL )
	{
		free( theFragmentShaderAttributesRef->uniformLocation );
	} // if

	if ( theFragmentShaderAttributesRef != NULL )
	{
		free( theFragmentShaderAttributesRef );
	} // if
	
	theFragmentShaderAttributesRef = NULL;
} // FreeFragmentShaderAttributesRef

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLFragmentShaderUtilityToolkit

//------------------------------------------------------------------------

- (id) initWithFragmentShaderInAppBundle:(NSString *)theFragmentShaderName 
			uniformKeys:(NSArray *)theUniformKeys
			bounds:(NSRect)thebounds
{
	self = [super initWithBounds:thebounds];
	
	if ( theFragmentShaderName != nil )
	{
		fragmentShaderAttributes = CallocFragmentShaderAttributesRef( );
		
		if ( fragmentShaderAttributes != NULL )
		{
			fragmentShaderAttributes->fragmentShaderIsInstalled 
							= GetFragmentShaderFromSource(	theFragmentShaderName, 
															theUniformKeys, 
															fragmentShaderAttributes );
		} // if
	} // if
	
	return self;
} // initWithFragmentShaderInAppBundle

//------------------------------------------------------------------------

- (void) dealloc
{
	// Delete OpenGL resources
	
	FreeFragmentShaderAttributesRef( fragmentShaderAttributes );

	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (GLint *) uniformLocation
{
	return  fragmentShaderAttributes->uniformLocation;
} // uniformLocation

//------------------------------------------------------------------------

- (GLuint) uniformCount
{
	return  fragmentShaderAttributes->uniformCount;
} // uniformCount

//------------------------------------------------------------------------

- (void) enable
{
	// For details on glUseProgramObjectARB refer to:
	//
	// http://developer.3dlabs.com/openGL2/slapi/UseProgramObjectARB.htm
	
	glUseProgramObjectARB( fragmentShaderAttributes->programObject );
} // enable

//------------------------------------------------------------------------

- (void) disable
{
	glUseProgramObjectARB( NULL );
} // disable

//------------------------------------------------------------------------
//
// Run the  fragment shader over the geometry/model texture.
//
//------------------------------------------------------------------------

- (void) execute
{
	// Enable the computational kernel
	
	glUseProgramObjectARB( fragmentShaderAttributes->programObject );
	
		// Generate data in the form of a quad the size of our viewport

		[self quads];
	
	// Disable the computational kernel
	
	glUseProgramObjectARB( NULL );
} // execute

//------------------------------------------------------------------------

- (BOOL) installed
{
	return  fragmentShaderAttributes->fragmentShaderIsInstalled;
} // installed

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

