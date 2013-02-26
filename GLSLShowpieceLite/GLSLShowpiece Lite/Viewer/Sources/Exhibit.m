//-------------------------------------------------------------------------
//
//	File: Exhibit.m
//
//  Abstract: GLSL Exhibit base class.  Subclass this to create
//            your own additional exhibits
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
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#import <Accelerate/Accelerate.h>

//------------------------------------------------------------------------

#import "Exhibit.h"
#import "Numerics.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const GLint kNoise3DTexSize = 64;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef struct
{
	GLint          imageBorder;
	GLint          imageLevel;
	GLenum         imageTarget;
	GLenum         imageInternalFormat;
	GLenum         imageFormat;
	GLenum         imageType;
	GLuint         imageBitsPerComponent;
	GLuint         imageSamplesPerPixel;
	GLuint         imageStorageSize;
	vImage_Buffer  imageBuffer;
} GLImageBitmap;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static GLvoid GLImageBitmapMemset( GLImageBitmap *imageBitmap )
{
	imageBitmap->imageBorder           = 0;
	imageBitmap->imageLevel            = 0;
	imageBitmap->imageTarget           = 0;
	imageBitmap->imageInternalFormat   = 0;
	imageBitmap->imageFormat           = 0;
	imageBitmap->imageType             = 0;
	imageBitmap->imageBitsPerComponent = 0;
	imageBitmap->imageSamplesPerPixel  = 0;
	imageBitmap->imageStorageSize      = 0;
	imageBitmap->imageBuffer.width     = 0;
	imageBitmap->imageBuffer.height    = 0;
	imageBitmap->imageBuffer.rowBytes  = 0;
	imageBitmap->imageBuffer.data      = NULL;
} // GLImageBitmapMemset

//------------------------------------------------------------------------

static BOOL GLImageBitmapMalloc( CGImageRef imageRef, GLImageBitmap *imageBitmap )
{
	BOOL  imageBitmapAllocated = NO;
	
	imageBitmap->imageBorder           = 0;
	imageBitmap->imageLevel            = 0;
	imageBitmap->imageTarget           = GL_TEXTURE_2D;
	imageBitmap->imageInternalFormat   = GL_RGBA8;
	imageBitmap->imageFormat           = GL_BGRA;
	imageBitmap->imageType             = GL_UNSIGNED_INT_8_8_8_8_REV;
	imageBitmap->imageBitsPerComponent = 8;
	imageBitmap->imageSamplesPerPixel  = 4;
	imageBitmap->imageBuffer.width     = CGImageGetWidth( imageRef );
	imageBitmap->imageBuffer.height    = CGImageGetHeight( imageRef );
	imageBitmap->imageBuffer.rowBytes  = imageBitmap->imageBuffer.width * imageBitmap->imageSamplesPerPixel;
	imageBitmap->imageStorageSize      = imageBitmap->imageBuffer.rowBytes * imageBitmap->imageBuffer.height;
	imageBitmap->imageBuffer.data      = (GLvoid *)malloc( imageBitmap->imageStorageSize );
	
	if ( imageBitmap->imageBuffer.data != NULL )
	{
		imageBitmapAllocated = YES;
	} // if
	else
	{
		GLImageBitmapMemset( imageBitmap );
	} // else
	
	return imageBitmapAllocated;
} // GLImageBitmapMalloc

//------------------------------------------------------------------------

static BOOL GLImageBitmapFree( GLImageBitmap *imageBitmap )
{
	BOOL  imageBitmapFreed = NO;
	
	if ( imageBitmap->imageBuffer.data != NULL )
	{
		free( imageBitmap->imageBuffer.data );
		
		imageBitmapFreed = YES;
	} // if
	
	GLImageBitmapMemset( imageBitmap );
	
	return imageBitmapFreed;
} // GLImageBitmapFree

//------------------------------------------------------------------------

static CGContextRef GLImageBitmapContexMalloc( GLImageBitmap *imageBitmap )
{
	CGContextRef     imageContextRef    = NULL;
	CGColorSpaceRef  imageColorSpaceRef = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );

	if ( imageColorSpaceRef != NULL )
	{
		CGBitmapInfo  imageBitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;

		imageContextRef = CGBitmapContextCreate( imageBitmap->imageBuffer.data, 
												 imageBitmap->imageBuffer.width, 
												 imageBitmap->imageBuffer.height, 
												 imageBitmap->imageBitsPerComponent,
												 imageBitmap->imageBuffer.rowBytes, 
												 imageColorSpaceRef, 
						 						 imageBitmapInfo 
											   );
		
		CGColorSpaceRelease( imageColorSpaceRef );
	} // if

	return  imageContextRef;
} // GLImageBitmapContexMalloc

//------------------------------------------------------------------------

static BOOL GLImageBitmapVerticalReflect( CGImageRef imageRef, GLImageBitmap *imageBitmap )
{
	BOOL          imageBitmapReflected = NO;
	CGContextRef  imageContextRef      = GLImageBitmapContexMalloc( imageBitmap );

	if ( imageContextRef != NULL )
	{
		CGRect imageRect = { { 0, 0 }, { imageBitmap->imageBuffer.width, imageBitmap->imageBuffer.height } };

		CGContextDrawImage( imageContextRef, imageRect, imageRef );
		
		vImageVerticalReflect_ARGB8888( &(imageBitmap->imageBuffer), &(imageBitmap->imageBuffer), kvImageNoFlags );

		CGContextRelease( imageContextRef );
		
		imageBitmapReflected = YES;
	} // if bitmap context
	
	return imageBitmapReflected;
} // GLImageBitmapVerticalReflect

//------------------------------------------------------------------------

static BOOL  GLImageBitmapFromImageFile( const NSString *imageFilePath, GLImageBitmap *imageBitmap )
{
	BOOL  imageBitmapVerticalReflected = NO;
	
	if ( imageFilePath != NULL )
	{
		CFURLRef imageURL = CFURLCreateWithFileSystemPath( NULL, (CFStringRef)imageFilePath, kCFURLPOSIXPathStyle, 0);
		
		if ( imageURL != NULL )
		{
			CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL( imageURL, NULL );
			
			if ( imageSourceRef != NULL )
			{
				CGImageRef imageRef = CGImageSourceCreateImageAtIndex( imageSourceRef, 0, NULL );

				if ( imageRef != NULL )
				{
					if ( GLImageBitmapMalloc( imageRef, imageBitmap ) )
					{
						if ( GLImageBitmapVerticalReflect( imageRef, imageBitmap ) )
						{
							imageBitmapVerticalReflected = YES;
						}
					} // if bitmap data
											
					CGImageRelease( imageRef );
				} // if image
				
				CFRelease( imageSourceRef );			
			} // if image source
			
			CFRelease( imageURL );	
		} // if url
	} // if path
	
	return  imageBitmapVerticalReflected;
} // GLImageBitmapFromImageFile

//------------------------------------------------------------------------

static inline GLvoid GLImageBitmapGetTexImage2D( GLImageBitmap *imageBitmap )
{
	glTexImage2D( imageBitmap->imageTarget, 
				  imageBitmap->imageLevel, 
				  imageBitmap->imageInternalFormat, 
				  imageBitmap->imageBuffer.width, 
				  imageBitmap->imageBuffer.height, 
				  imageBitmap->imageBorder, 
				  imageBitmap->imageFormat, 
				  imageBitmap->imageType, 
				  imageBitmap->imageBuffer.data );
} // GLImageBitmapGetTexImage2D

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static void CopyFramebufferToTexture(GLuint textureID)
{
	GLint viewport[4];
	
	glGetIntegerv(GL_VIEWPORT, viewport);
	glBindTexture(GL_TEXTURE_2D, textureID);
	
	glCopyTexImage2D
		(
			GL_TEXTURE_2D, 
			0, 
			GL_RGBA8, 
			viewport[0], 
			viewport[1], 
			NextHighestPowerOf2FromInt(viewport[2]), 
			NextHighestPowerOf2FromInt(viewport[3]), 
			0
		);
} // CopyFramebufferToTexture

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static GLhandleARB LoadShader( GLenum shaderType, const GLcharARB **shader, GLint *shaderCompiled ) 
{
	GLhandleARB shaderObj = NULL;
	
	if ( shader != NULL ) 
	{
		GLint infoLogLength = 0;
		
		shaderObj = glCreateShaderObjectARB( shaderType );
		
		glShaderSourceARB( shaderObj, 1, shader, NULL );
		glCompileShaderARB( shaderObj );
		
		glGetObjectParameterivARB( shaderObj, GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength );
		
		if ( infoLogLength > 0 ) 
		{
			GLcharARB *infoLog = (GLcharARB *)malloc( infoLogLength );
			
			if ( infoLog != NULL )
			{
				glGetInfoLogARB( shaderObj, infoLogLength, &infoLogLength, infoLog );
				
				NSLog( @">> Shader compile log:\n%s\n", infoLog );
				
				free( infoLog );
			} // if
		} // if

		glGetObjectParameterivARB( shaderObj, GL_OBJECT_COMPILE_STATUS_ARB, shaderCompiled );
		
		if ( *shaderCompiled == 0 )
		{
			NSLog( @">> Failed to compile shader %s\n", shader );
		} // if
	} // if
	else 
	{
		*shaderCompiled = 1;
	} // else
	
	return shaderObj;
} // LoadShader

//------------------------------------------------------------------------

static void LinkProgram( GLhandleARB program, GLint *program_linked ) 
{
	GLint  infoLogLength = 0;
	
	glLinkProgramARB(program);
	
	glGetObjectParameterivARB( program, GL_OBJECT_INFO_LOG_LENGTH_ARB, &infoLogLength );
	
	if ( infoLogLength >  0) 
	{
		GLcharARB *infoLog = malloc( infoLogLength );
		
		if ( infoLog != NULL )
		{
			glGetInfoLogARB( program, infoLogLength, &infoLogLength, infoLog );
			
			NSLog( @">> Program link log:\n%s\n", infoLog );
			
			free( infoLog );
		} // if
	} // if
	
	glGetObjectParameterivARB( program, GL_OBJECT_LINK_STATUS_ARB, program_linked );
	
	if ( *program_linked == 0 )
	{
		NSLog( @">> Failed to link program %d\n", (int)program );
	} // if
} // LinkProgram

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLExhibit

//------------------------------------------------------------------------

- (id) init
{
	[super init];
	
	appBundle = [NSBundle mainBundle];
	
	gpuProcessingInit = NO;
	programObject     = NULL;

	return self;
} // init

//------------------------------------------------------------------------

- (void) initLazy
{
	// Subclass should put initialisation code that can be performed
	// lazily (on first frame render) here
	
	initialised = TRUE;
} // initLazy

//------------------------------------------------------------------------

- (void) dealloc
{
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (void) awakeFromNib
{
} // awakeFromNib

//------------------------------------------------------------------------

- (NSString *) name
{
	return @"Unnamed OpenGLExhibit";
} // name

//------------------------------------------------------------------------

- (NSString *) descriptionFilename
{
	return nil;
} // descriptionFilename

//------------------------------------------------------------------------

- (GLint) getUniformLocation:(GLhandleARB)theProgramObject uniformName:(const GLcharARB *)theUniformName
{
	GLint uniformLoacation = glGetUniformLocationARB(theProgramObject, theUniformName);
	
	if (uniformLoacation == -1) 
	{
		NSLog( @">> WARNING: No such uniform named \"%s\"\n", theUniformName );
	} // if

	return uniformLoacation;
} // getUniformLocation

//------------------------------------------------------------------------

- (GLcharARB *) getShaderSourceFromResource:(NSString *)theShaderResourceName extension:(NSString *)theExtension
{
	NSString  *shaderTempSource  = [appBundle pathForResource:theShaderResourceName ofType:theExtension];
	GLcharARB *shaderSource      = NULL;
	
	shaderTempSource = [NSString stringWithContentsOfFile:shaderTempSource];
	shaderSource     = (GLcharARB *)[shaderTempSource cStringUsingEncoding:NSASCIIStringEncoding];
	
	return  shaderSource;
} // getShaderSourceFromResource

//------------------------------------------------------------------------

- (void) getFragmentShaderSourceFromResource:(NSString *)theFragmentShaderResourceName
{
	fragmentShaderSource = [self getShaderSourceFromResource:theFragmentShaderResourceName extension:@"frag" ];
} // getFragmentShaderSourceFromResource

//------------------------------------------------------------------------

- (void) getVertexShaderSourceFromResource:(NSString *)theVertexShaderResourceName
{
	vertexShaderSource = [self getShaderSourceFromResource:theVertexShaderResourceName extension:@"vert" ];
} // getVertexShaderSourceFromResource

//------------------------------------------------------------------------

- (GLhandleARB) loadShader:(GLenum)theShaderType shaderSource:(const GLcharARB **)theShaderSource
{
	GLint       shaderCompiled = 0;
	GLhandleARB shaderHandle   = LoadShader(theShaderType, theShaderSource, &shaderCompiled);
	
	if (!shaderCompiled) 
	{
		if (shaderHandle) 
		{
			glDeleteObjectARB(shaderHandle);
			shaderHandle = NULL;
		} // if
	} // if
	
	return shaderHandle;
} // loadShader

//------------------------------------------------------------------------

- (BOOL) newProgramObject:(GLhandleARB)theVertexShader  fragmentShaderHandle:(GLhandleARB)theFragmentShader
{
	GLint programLinked = 0;

	// Create a program object and link both shaders
	
	programObject = glCreateProgramObjectARB();
	
	glAttachObjectARB(programObject, theVertexShader);
	glDeleteObjectARB(theVertexShader);   // Release
	
	glAttachObjectARB(programObject, theFragmentShader);
	glDeleteObjectARB(theFragmentShader); // Release
	
	LinkProgram(programObject, &programLinked);

	if (!programLinked) 
	{
		glDeleteObjectARB(programObject);
		
		programObject = NULL;
		
		return NO;
	} // if
	
	return YES;
} // newProgramObject

//------------------------------------------------------------------------

- (BOOL) setProgramObject
{
	BOOL  programObjectSet = NO;
	
	// Load and compile both shaders
	
	GLhandleARB vertexShader = [self loadShader:GL_VERTEX_SHADER_ARB shaderSource:&vertexShaderSource];
	
	// Ensure vertex shader compiled
	
	if (vertexShader != NULL)
	{
		GLhandleARB fragmentShader = [self loadShader:GL_FRAGMENT_SHADER_ARB shaderSource:&fragmentShaderSource];
		
		// Ensure fragment shader compiled
		
		if (fragmentShader != NULL) 
		{
			// Create a program object and link both shaders
			
			programObjectSet = [self newProgramObject:vertexShader fragmentShaderHandle:fragmentShader];
		} // if
	} // if
	
	return  programObjectSet;
} // setProgramObject

//------------------------------------------------------------------------

- (BOOL) loadShadersFromResource:(NSString *)theShadersName
{
	BOOL  loadedShaders = NO;
	
	// Load vertex and fragment shader
	
	[self getVertexShaderSourceFromResource:theShadersName];
	
	if (vertexShaderSource != NULL)
	{
		[self getFragmentShaderSourceFromResource:theShadersName];

		if (fragmentShaderSource != NULL)
		{
			loadedShaders = [self setProgramObject];
			
			if (!loadedShaders)
			{
				NSLog(@">> Failed to load GLSL \"%@\" fragment & vertex shaders!\n", theShadersName);
			} // if
		} // if
	} // if
	
	return  loadedShaders;
} // loadShadersFromResource

//------------------------------------------------------------------------

- (GLuint) loadNoiseTexture
{
	GLuint  textureID;
	
	glGenTextures(1, &textureID);
	
	glBindTexture(GL_TEXTURE_3D, textureID);
	
	CreateNoise3D( kNoise3DTexSize );
	
	return textureID;
} // loadNoiseTexture

//------------------------------------------------------------------------

- (GLuint) loadTextureFromResource:(NSString *)textureResourceName
{
	GLuint     textureID       = 0;
	NSString  *texturePathname = [appBundle pathForResource:textureResourceName ofType: @"jpg"];
	
	if ( texturePathname != nil )
	{
		GLImageBitmap  imageBitmap;
		
		if( GLImageBitmapFromImageFile( texturePathname, &imageBitmap ) )
		{
			glGenTextures(1, &textureID);
			glBindTexture(GL_TEXTURE_2D, textureID);
			
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	

			GLImageBitmapGetTexImage2D( &imageBitmap );
			
			GLImageBitmapFree( &imageBitmap );
		} // if
	} // if
	
	return textureID;
} // loadTextureFromResource

//------------------------------------------------------------------------

- (void) copyFramebufferToTexture:(GLuint)textureID
{
	CopyFramebufferToTexture( textureID );
} // copyFramebufferToTexture

//------------------------------------------------------------------------

- (GLuint) loadFrameBufferTexture:(GLint  *)viewport
{
	GLuint textureID;
	
	glGenTextures(1, &textureID);
	glBindTexture(GL_TEXTURE_2D, textureID);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glGetIntegerv(GL_VIEWPORT,viewport);
	
	CopyFramebufferToTexture(textureID);
	
	return textureID;
} // loadFrameBufferTexture

//------------------------------------------------------------------------

- (void) renderFrame
{
	if (!initialised)
	{
		[self initLazy];
	} // if
} // renderFrame

//------------------------------------------------------------------------

- (BOOL) gpuProcessingShaders:(BOOL)logResults
{
	GLint          fragmentGPUProcessing = 0;
	GLint          vertexGPUProcessing   = 0;
	BOOL           gpuProcessedShaders   = NO;
	CGLContextObj  currentCGContext      = CGLGetCurrentContext();
	
	CGLGetParameter( currentCGContext, kCGLCPGPUFragmentProcessing, &fragmentGPUProcessing );
	CGLGetParameter( currentCGContext,   kCGLCPGPUVertexProcessing, &vertexGPUProcessing   );

	if ( logResults )
	{
		NSLog(@">> Fragment Processing = %d, Vertex Processing = %d\n", fragmentGPUProcessing, vertexGPUProcessing );
	} //if
	
	gpuProcessedShaders = ( fragmentGPUProcessing && vertexGPUProcessing ) ? YES : NO;
	
	return  gpuProcessedShaders;
} // gpuProcessingShaders

//------------------------------------------------------------------------

- (BOOL) isGPUProcessingShaders
{
	return [self gpuProcessingShaders:NO];
} // isGPUProcessingShaders

//------------------------------------------------------------------------

- (BOOL) isGPUProcessingShadersLogResults
{
	return [self gpuProcessingShaders:YES];
} // isGPUProcessingShaders

//------------------------------------------------------------------------

- (BOOL) reflect
{
	if( !gpuProcessingInit )
	{
		// Check if this will fall back to software rasterization or
		// software vertex processing and don't reflect if it is.

		gpuProcessingInit = YES;

		glPushAttrib(GL_VIEWPORT_BIT);
		
			glViewport(0,0,0,0);
			
			glPushMatrix();
			
				[self renderFrame];
			
			glPopMatrix();
			
			gpuProcessing = [self gpuProcessingShaders:NO];
		
		glPopAttrib();
	} // if

	return gpuProcessing;
} // reflect

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------
