//---------------------------------------------------------------------------
//
//	File: GLSLKit.m
//
//  Abstract: Utility toolkit for fragement and vertex shaders
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
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//------------------------------------------------------------------------

#import "AlertPanelKit.h"
#import "GLSLKit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct GLSLAttributes
{
	const GLcharARB    *fragmentShaderSource;	// the GLSL source for our fragment Shader
	const GLcharARB    *vertexShaderSource;		// the GLSL source for our vertex Shader
	GLhandleARB		    programObject;			// the program object
};

typedef struct GLSLAttributes   GLSLAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Compiling shaders & linking a program object --

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static GLhandleARB CompileShader(GLenum theShaderType, const GLcharARB **theShader, GLint *theShaderCompiled) 
{
	GLhandleARB shaderObject = NULL;
	
	if ( *theShader != NULL ) 
	{
		GLint infoLogLength = 0;
		
		shaderObject = glCreateShaderObjectARB(theShaderType);
		
		glShaderSourceARB(shaderObject, 1, theShader, NULL);
		glCompileShaderARB(shaderObject);
		
		glGetObjectParameterivARB(shaderObject, GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength);
		
		if (infoLogLength > 0) 
		{
			GLcharARB *infoLog = (GLcharARB *)malloc(infoLogLength);
			
			if (infoLog != NULL)
			{
				glGetInfoLogARB(shaderObject, infoLogLength, &infoLogLength, infoLog);
				
				NSLog(@">> [OpenGL Shader Kit] Shader compile log:\n%s\n", infoLog);
				
				free(infoLog);
			} // if
		} // if

		glGetObjectParameterivARB(shaderObject, GL_OBJECT_COMPILE_STATUS_ARB, theShaderCompiled);
		
		if ( *theShaderCompiled == 0 )
		{
			[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
							  message:@"WARNING: Failed to compile shader!"
								 exit:NO] displayAlertPanel];

			NSLog(@">> [OpenGL Shader Kit] WARNING: Failed to compile shader!\n%s\n", theShader);
		} // if
	} // if
	else 
	{
		*theShaderCompiled = 0;
	} // else
	
	return shaderObject;
} // CompileShader

//------------------------------------------------------------------------

static BOOL LinkProgram(GLhandleARB programObject) 
{
	GLint  infoLogLength = 0;
	GLint  programLinked = 0;
	BOOL   linkSuccess   = NO;
	
	glLinkProgramARB(programObject);
	
	glGetObjectParameterivARB(programObject , GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength);
	
	if (infoLogLength >  0) 
	{
		GLcharARB *infoLog = (GLcharARB *)malloc(infoLogLength);
		
		if (infoLog != NULL)
		{
			glGetInfoLogARB(programObject, infoLogLength, &infoLogLength, infoLog);
			
			NSLog(@">> [OpenGL Shader Kit] Program link log:\n%s\n", infoLog);
			
			free(infoLog);
		} // if
	} // if
	
	glGetObjectParameterivARB(programObject, GL_OBJECT_LINK_STATUS_ARB, &programLinked);
	
	if ( programLinked == 0 )
	{
		[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
						  message:@"WARNING: Failed to link program!"
							 exit:NO] displayAlertPanel];

		NSLog(@">> [OpenGL Shader Kit] WARNING: Failed to link program 0x%lx\n", (GLint)&programObject);
	} // if
	else
	{
		linkSuccess = YES;
	} // else
	
	return  linkSuccess;
} // LinkProgram

//------------------------------------------------------------------------

static GLhandleARB GetShader(GLenum theShaderType, GLSLAttributesRef theShaderAttributes)
{
	GLhandleARB  shaderHandle   = NULL;
	GLint        shaderCompiled = GL_FALSE;
		
	switch( theShaderType )
	{
		case GL_VERTEX_SHADER_ARB:
			
			shaderHandle = CompileShader(theShaderType, &theShaderAttributes->vertexShaderSource, &shaderCompiled);
			break;
			
		case GL_FRAGMENT_SHADER_ARB:
		
		default:
			
			shaderHandle = CompileShader(theShaderType, &theShaderAttributes->fragmentShaderSource, &shaderCompiled);
			break;
	} // switch
			
	if ( !shaderCompiled ) 
	{
		if ( shaderHandle ) 
		{
			glDeleteObjectARB(shaderHandle);
			shaderHandle = NULL;
		} // if
	} // if
	
	return shaderHandle;
} // GetShader

//------------------------------------------------------------------------

static GLhandleARB NewProgramObject(GLhandleARB theVertexShader, GLhandleARB theFragmentShader)
{
	GLhandleARB programObject = NULL;
	
	// Create a program object and link shaders
	
	if ( ( theVertexShader != NULL ) || ( theFragmentShader != NULL ) )
	{
		programObject = glCreateProgramObjectARB( );
		
		if ( programObject != NULL )
		{
			BOOL fragmentShaderAttached = NO;
			BOOL vertexShaderAttached   = NO;
			BOOL programObjectLinked    = NO;
			
			if ( theVertexShader != NULL )
			{
				vertexShaderAttached = YES;
				
				glAttachObjectARB(programObject, theVertexShader);
				glDeleteObjectARB(theVertexShader);   // Release
				
				theVertexShader = NULL;
			} // if
			
			if ( theFragmentShader != NULL )
			{
				fragmentShaderAttached = YES;
				
				glAttachObjectARB(programObject, theFragmentShader);
				glDeleteObjectARB(theFragmentShader); // Release
				
				theFragmentShader = NULL;
			} // if
			
			if ( vertexShaderAttached || fragmentShaderAttached )
			{
				programObjectLinked = LinkProgram(programObject);

				if ( !programObjectLinked ) 
				{
					glDeleteObjectARB(programObject);
					
					programObject = NULL;
				} // if
			} // if
		} // if
	} // if
	
	return programObject;
} // NewProgramObject

//------------------------------------------------------------------------

static BOOL GetProgramObject(GLSLAttributesRef theShaderAttributes)
{
	BOOL  newProgramObject = NO;
	
	// Load and compile both shaders
	
	GLhandleARB vertexShader   = GetShader(GL_VERTEX_SHADER_ARB, theShaderAttributes);
	GLhandleARB fragmentShader = GetShader(GL_FRAGMENT_SHADER_ARB, theShaderAttributes);
	
	// Create a program object and link both shaders
			
	theShaderAttributes->programObject = NewProgramObject(vertexShader, fragmentShader);
	
	if ( theShaderAttributes->programObject != NULL )
	{
		newProgramObject = YES;
	} // if
	
	return  newProgramObject;
} // GetProgramObject

//------------------------------------------------------------------------

static BOOL ValidateProgramObject(GLSLAttributesRef theShaderAttributes)
{
	BOOL  programObjectValidated = YES;
	GLint validateStatusSuccess;

	glValidateProgramARB(theShaderAttributes->programObject);
	
	glGetObjectParameterivARB(theShaderAttributes->programObject, GL_VALIDATE_STATUS, &validateStatusSuccess);
	
	if ( !validateStatusSuccess )
	{
		GLint  infoLogLength = 0;
		
		glGetObjectParameterivARB(theShaderAttributes->programObject , GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength);
		
		if (infoLogLength >  0) 
		{
			GLcharARB *infoLog = (GLcharARB *)malloc(infoLogLength);
			
			if (infoLog != NULL)
			{
				glGetInfoLogARB(theShaderAttributes->programObject, infoLogLength, &infoLogLength, infoLog);				

				[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
								  message:@"ERROR: In validating program object!"
									 exit:NO] displayAlertPanel];

				NSLog(@">> [OpenGL Shader Kit] ERROR: In validating program object!\n%s\n", infoLog);
				
				free( infoLog );
			} // if
		} // if
		
		programObjectValidated = NO;
	} // if
	
	return  programObjectValidated;
} // ValidateProgramObject

//------------------------------------------------------------------------

static GLint GetUniformLocation(GLhandleARB theProgramObject, const GLcharARB *theUniformName)
{
	GLint uniformLoacation = glGetUniformLocationARB(theProgramObject, theUniformName);
	
	if (uniformLoacation == -1) 
	{
		NSString *alertMessage = [NSString stringWithFormat:@"WARNING: No such uniform named \"%s\"",theUniformName];
		
		if ( alertMessage )
		{
			[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
							  message:alertMessage
								 exit:NO] displayAlertPanel];
		} // if
		
		NSLog( @">> [OpenGL Shader Kit] WARNING: No such uniform named \"%s\"!", theUniformName );
	} // if

	return uniformLoacation;
} // getUniformLocation

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Check for extensions --

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static inline GLboolean CheckForExtension(const char *extensionName, const GLubyte *extensions)
{
	GLboolean  bExtensionAvailable = gluCheckExtension((GLubyte *)extensionName, extensions);
	
	return bExtensionAvailable;
} // CheckForExtension

//------------------------------------------------------------------------

static inline void CheckForAndLogExtensionAvailable(const GLboolean extensionAvailable, const char *extensionName)
{
	if (extensionAvailable == GL_FALSE)
	{
		NSString *alertMessage = [NSString stringWithFormat:@"WARNING: \"%s\" extension is not available!",extensionName];
		
		if ( alertMessage )
		{
			[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
							  message:alertMessage
								 exit:NO] displayAlertPanel];
		} // if
		
		NSLog(@">> [OpenGL Shader Kit] WARNING: \"%s\" extension is not available!", extensionName);
	} // if
} // CheckForExtensions

//------------------------------------------------------------------------

static BOOL SoftwareRendering( )
{
	const GLubyte *extensions = glGetString(GL_EXTENSIONS);
	
	GLboolean  bShaderObjectAvailable      = CheckForExtension(       "GL_ARB_shader_objects", extensions);
	GLboolean  bShaderLanguage100Available = CheckForExtension( "GL_ARB_shading_language_100", extensions);
	GLboolean  bVertexShaderAvailable      = CheckForExtension(        "GL_ARB_vertex_shader", extensions);
	GLboolean  bFragmentShaderAvailable    = CheckForExtension(      "GL_ARB_fragment_shader", extensions);
	
	BOOL  bSoftwareRendering =		( bShaderObjectAvailable      == GL_FALSE )
								||	( bShaderLanguage100Available == GL_FALSE )
								||	( bVertexShaderAvailable      == GL_FALSE ) 
								||	( bFragmentShaderAvailable    == GL_FALSE );
	
	if ( bSoftwareRendering )
	{
		// Software rendering, so fragment shaders will excuteWithCVTexture

		CheckForAndLogExtensionAvailable(      bShaderObjectAvailable,       "GL_ARB_shader_objects" );
		CheckForAndLogExtensionAvailable( bShaderLanguage100Available, "GL_ARB_shading_language_100" );
		CheckForAndLogExtensionAvailable(      bVertexShaderAvailable,        "GL_ARB_vertex_shader" );
		CheckForAndLogExtensionAvailable(    bFragmentShaderAvailable,      "GL_ARB_fragment_shader" );
	} // if
	
	return  bSoftwareRendering;
} // SoftwareRendering

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation GLSLKit

//------------------------------------------------------------------------

#pragma mark -- Get shaders from resource --

//------------------------------------------------------------------------

- (GLcharARB *) getShaderSourceFromResource:(NSString *)theShaderResourceName extension:(NSString *)theExtension
{
	NSBundle  *appBundle         = [NSBundle mainBundle];
	NSString  *shaderTempSource  = [appBundle pathForResource:theShaderResourceName ofType:theExtension];
	GLcharARB *shaderSource      = NULL;
	
	shaderTempSource = [NSString stringWithContentsOfFile:shaderTempSource];
	shaderSource     = (GLcharARB *)[shaderTempSource cStringUsingEncoding:NSASCIIStringEncoding];
	
	return  shaderSource;
} // getShaderSourceFromResource

//------------------------------------------------------------------------

- (void) getFragmentShaderSourceFromResource:(NSString *)theFragmentShaderResourceName
{
	shaderAttributes->fragmentShaderSource 
		= [self getShaderSourceFromResource:theFragmentShaderResourceName extension:@"fs" ];
} // getFragmentShaderSourceFromResource

//------------------------------------------------------------------------

- (void) getVertexShaderSourceFromResource:(NSString *)theVertexShaderResourceName
{
	shaderAttributes->vertexShaderSource 
		= [self getShaderSourceFromResource:theVertexShaderResourceName extension:@"vs" ];
} // getVertexShaderSourceFromResource

//------------------------------------------------------------------------

- (BOOL) getProgramObject:(NSString *)theShadersName
{
	BOOL  gotProgramObject       = NO;
	BOOL  validatedProgramObject = NO;

	gotProgramObject = GetProgramObject(shaderAttributes);
	
	if (!gotProgramObject)
	{
		NSString *alertMessage = [NSString stringWithFormat:@"WARNING: Failed to compile+link GLSL \"%@\" fragment and/or vertex shader(s)!",theShadersName];
		
		if ( alertMessage )
		{
			[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
							  message:alertMessage
								 exit:NO] displayAlertPanel];
		} // if

		NSLog(@">> [OpenGL Shader Kit] WARNING: Failed to compile+link GLSL \"%@\" fragment and/or vertex shader(s)!", theShadersName);
	} // if
	else
	{
		validatedProgramObject = ValidateProgramObject(shaderAttributes);
		
		if (!validatedProgramObject)
		{
			[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
							  message:@">> WARNING: Failed to validate the program object!"
								 exit:NO] displayAlertPanel];

			NSLog(@">> [OpenGL Shader Kit] WARNING: Failed to validate the program object!");
		} // if
	} // else
	
	return ( gotProgramObject && validatedProgramObject );
} // getProgramObject

//------------------------------------------------------------------------

- (BOOL) getShadersFromResource:(NSString *)theShadersName
{
	BOOL  shadersReadyToUse = NO;
	
	shaderAttributes = (GLSLAttributesRef)[self pointer];
	
	if ( [self isPointerValid] )
	{
		// Load vertex and fragment shaders
		
		[self getVertexShaderSourceFromResource:theShadersName];
		[self getFragmentShaderSourceFromResource:theShadersName];

		shadersReadyToUse = [self getProgramObject:theShadersName];
	} // if
	else
	{
		[[AlertPanelKit withTitle:@"OpenGL Shader Kit" 
						  message:@"Failure Allocating Memory For Shader Attributes"
							 exit:NO] displayAlertPanel];
	} // else
	
	return  shadersReadyToUse;
} // getShadersFromResource

//------------------------------------------------------------------------

#pragma mark -- Designated initializer --

//------------------------------------------------------------------------

- (id) initWithGLSLShadersInAppBundle:(NSString *)theShadersName
{	
	self = [super initMemoryWithType:kMemAlloc size:sizeof(GLSLAttributes)];
	
	if ( self )
	{
		if ( !SoftwareRendering( ) )
		{	
			[self getShadersFromResource:theShadersName];
		} // if
	} // if
	
	return self;
} // initWithShadersInAppBundle

//------------------------------------------------------------------------

#pragma mark -- Deallocating Resources --

//------------------------------------------------------------------------

- (void) dealloc
{
	// Delete OpenGL resources
	
	if ( shaderAttributes->programObject != NULL )
	{
		glDeleteObjectARB( shaderAttributes->programObject );
	} // if
	
	//Dealloc the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Accessors --

//------------------------------------------------------------------------

- (void) enable
{
	// For details on glUseProgramObjectARB refer to:
	//
	// http://developer.3dlabs.com/openGL2/slapi/UseProgramObjectARB.htm
	
	glUseProgramObjectARB( shaderAttributes->programObject );
} // enable

//------------------------------------------------------------------------

- (void) disable
{
	glUseProgramObjectARB( NULL );
} // disable

//------------------------------------------------------------------------

- (GLint) uniformLocation:(NSString *)theUniformName
{
	GLint uniformLoacation = -1;
	
	if ( theUniformName )
	{
		const GLcharARB *uniformName = (GLcharARB *)[theUniformName cStringUsingEncoding:NSASCIIStringEncoding];
		
		uniformLoacation = GetUniformLocation( shaderAttributes->programObject, uniformName );
	} // if
	
	return uniformLoacation;
} // getUniformLocation

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

