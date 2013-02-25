//---------------------------------------------------------------------------
//
//	File: GLSLUnit.h
//
//  Abstract: A utility toolkit for managing shaders along with their 
//            uniforms
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

//---------------------------------------------------------------------------

#import "MemObject.h"

#import "GLSLUnit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const GLuint kSizeOfGLint   = sizeof(GLint);
static const GLuint kSizeOfGLfloat = sizeof(GLfloat);

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation GLSLUnit

//------------------------------------------------------------------------

#pragma mark -- initializer --

//------------------------------------------------------------------------

- (void) initUniformLocForIntValue:(NSDictionary *)theSamplerDict
{
	NSString *theSamplerKey;
	
	NSNumber  *theSamplerNumber;
	
	GLint  theSamplerLoc   = 0;
	GLint  theSamplerValue = 0;
	
	[self enable];
	
		for (theSamplerKey in theSamplerDict) 
		{
			theSamplerNumber = [theSamplerDict objectForKey:theSamplerKey];
			theSamplerValue  = [theSamplerNumber integerValue];
			theSamplerLoc    = [self uniformLocation:theSamplerKey];
					
			glUniform1iARB(theSamplerLoc, theSamplerValue);
		} // for
	
	[self disable];
} // initUniformLocForIntValue

//------------------------------------------------------------------------

- (id) initWithShadersInAppBundleAndSamplers:(NSString *)theShadersName
										size:(const NSSize *)theSize
										samplers:(NSDictionary *)theSamplersDict
{
	self = [super initWithGLSLShadersInAppBundle:theShadersName];
	
	if ( self )
	{
		// Get sampler uniforms
		
		[self initUniformLocForIntValue:theSamplersDict];

		// Initialize a quad of size for rendering the results
		
		quad = [[OpenGLQuad alloc] initQuadWithSize:theSize range:1];
	} // if
	
	return self;
} // initWithShadersInAppBundleAndSamplers

//------------------------------------------------------------------------

#pragma mark -- Deallocating Resources --

//------------------------------------------------------------------------

- (void) dealloc
{
	// Quad is no longer needed
	
	if ( quad )
	{
		[quad release];
		
		quad = nil;
	} // if
	
	// Dealloc the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Integer Scalar Uniforms --

//---------------------------------------------------------------------------

- (void) uniform1i:(const GLint)theUniformLocation
			value:(const GLint)theUniformValue
{
	[self enable];
	
		glUniform1iARB( theUniformLocation, theUniformValue );
		
	[self disable];
} // uniform1i

//---------------------------------------------------------------------------

- (void) uniform2i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform2iARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1] );		
		
	[self disable];
} // uniform2i

//---------------------------------------------------------------------------

- (void) uniform3i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform3iARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1], 
						theUniformValues[2] );		
		
	[self disable];
} // uniform3i

//---------------------------------------------------------------------------

- (void) uniform4i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform4iARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1], 
						theUniformValues[2], 
						theUniformValues[3] );		
		
	[self disable];
} // uniform4i

//------------------------------------------------------------------------

#pragma mark -- Scalar Float Uniforms --

//---------------------------------------------------------------------------

- (void) uniform1f:(const GLint)theUniformLocation
			value:(const GLfloat)theUniformValue
{
	[self enable];
	
		glUniform1fARB( theUniformLocation, theUniformValue );
		
	[self disable];
} // uniform1f

//---------------------------------------------------------------------------

- (void) uniform2f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform2fARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1] );		
		
	[self disable];
} // uniform2f

//---------------------------------------------------------------------------

- (void) uniform3f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform3fARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1], 
						theUniformValues[2] );		
		
	[self disable];
} // uniform3f

//---------------------------------------------------------------------------

- (void) uniform4f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform4fARB(	theUniformLocation, 
						theUniformValues[0], 
						theUniformValues[1], 
						theUniformValues[2], 
						theUniformValues[3] );		
		
	[self disable];
} // uniform4f

//------------------------------------------------------------------------

#pragma mark -- Integer Vector Uniforms --

//---------------------------------------------------------------------------

- (void) uniform1iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform1ivARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform1iv

//---------------------------------------------------------------------------

- (void) uniform2iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform2ivARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform2iv

//---------------------------------------------------------------------------

- (void) uniform3iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform3ivARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform3iv

//---------------------------------------------------------------------------

- (void) uniform4iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues
{
	[self enable];
	
		glUniform4ivARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform4iv

//------------------------------------------------------------------------

#pragma mark -- Float Vector Uniforms --

//---------------------------------------------------------------------------

- (void) uniform1fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform1fvARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform1fv

//---------------------------------------------------------------------------

- (void) uniform2fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform2fvARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform2fv

//---------------------------------------------------------------------------

- (void) uniform3fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform3fvARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform3fv

//---------------------------------------------------------------------------

- (void) uniform4fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniform4fvARB( theUniformLocation, theUniformCount, theUniformValues );
		
	[self disable];
} // uniform4fv

//------------------------------------------------------------------------

#pragma mark -- Float Matrix Uniforms --

//---------------------------------------------------------------------------

- (void) uniformMatrix2fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniformMatrix2fvARB(	theUniformLocation, 
								theUniformCount, 
								theTransposeFlag, 
								theUniformValues );
		
	[self disable];
} // uniformMatrix2fv

//---------------------------------------------------------------------------

- (void) uniformMatrix3fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniformMatrix3fvARB(	theUniformLocation, 
								theUniformCount, 
								theTransposeFlag, 
								theUniformValues );
		
	[self disable];
} // uniformMatrix3fv

//---------------------------------------------------------------------------

- (void) uniformMatrix4fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues
{
	[self enable];
	
		glUniformMatrix4fvARB(	theUniformLocation, 
								theUniformCount, 
								theTransposeFlag, 
								theUniformValues );
		
	[self disable];
} // uniformMatrix4fv

//------------------------------------------------------------------------

#pragma mark -- Setting Integer Uniform Dictionaries --

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformIntScalar:(const GLint)theUniformLoc 
									value:(const GLint)theUniformValue
{
	NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
														kUniformTypeKey,
														kUniformValueKey,
														nil ];
	
	NSArray *uniformObjects = [NSArray arrayWithObjects:[NSNumber numberWithInt:theUniformLoc],
														[NSNumber numberWithInt:kUniform1i],
														[NSNumber numberWithInt:theUniformValue],
														nil ];
	
	NSDictionary *uniformDict = [[NSDictionary alloc] initWithObjects:uniformObjects
															  forKeys:uniformKeys];
	return  uniformDict;
} // getDictUniform1i

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformIntScalars:(const GLint)theUniformLoc
									type:(const UniformScalarTypes)theUniformScalarType
									value:(const GLint *)theUniformValue
{
	NSDictionary *uniformDict = nil;
	
	if ( ( theUniformScalarType > kScalar ) && ( theUniformScalarType <= k4Scalars ) )
	{
		NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
															kUniformTypeKey,
															kUniformValueKey,
															nil ];
		
		NSNumber    *uniformLoc     = [NSNumber numberWithInt:theUniformLoc];
		NSUInteger   uniformLength  = theUniformScalarType * kSizeOfGLint;
		NSData      *uniformValues  = [NSData dataWithBytes:theUniformValue length:uniformLength];
		NSNumber    *uniformType    = nil;
		NSArray     *uniformObjects = nil;
		
		switch( theUniformScalarType )
		{
			case k2Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform2i];
				break;
			case k3Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform3i];
				break;
			case k4Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform4i];
				break;
		} // switch
		
		uniformObjects = [NSArray arrayWithObjects:uniformLoc,uniformType,uniformValues,nil];
		uniformDict    = [[NSDictionary alloc] initWithObjects:uniformObjects forKeys:uniformKeys];
	} // if
	
	return  uniformDict;
} // getDictUniformIntScalars

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformIntVectors:(const GLint)theUniformLoc
									type:(const UniformVectorTypes)theUniformVectorType
									count:(const GLuint)theUniformVectorCount
									vectors:(const GLint *)theUniformVectors
{
	NSDictionary *uniformDict = nil;
	
	if ( theUniformVectorCount >= 1 )
	{
		NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
															kUniformTypeKey,
															kUniformValueKey,
															kUniformCountKey,
															nil ];
		
		NSNumber    *uniformLoc     = [NSNumber numberWithInt:theUniformLoc];
		NSNumber    *uniformCount   = [NSNumber numberWithInt:theUniformVectorCount];
		NSUInteger   uniformLength  = theUniformVectorType * theUniformVectorCount * kSizeOfGLint;
		NSData      *uniformValues  = [NSData dataWithBytes:theUniformVectors length:uniformLength];
		NSNumber    *uniformType    = nil;
		NSArray     *uniformObjects = nil;
		
		switch( theUniformVectorType )
		{
			case kVector:
				uniformType  = [NSNumber numberWithInt:kUniform1iv];
				break;
			case k2Vector:
				uniformType  = [NSNumber numberWithInt:kUniform2iv];
				break;
			case k3Vector:
				uniformType  = [NSNumber numberWithInt:kUniform3iv];
				break;
			case k4Vector:
				uniformType  = [NSNumber numberWithInt:kUniform4iv];
				break;
		} // switch
		
		uniformObjects = [NSArray arrayWithObjects:uniformLoc,uniformType,uniformValues,uniformCount,nil];
		uniformDict    = [[NSDictionary alloc] initWithObjects:uniformObjects forKeys:uniformKeys];
	} // if
	
	return  uniformDict;
} // getDictUniformIntVectors

//------------------------------------------------------------------------

#pragma mark -- Setting Float Uniform Dictionaries --

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformFloatScalar:(const GLint)theUniformLoc 
										value:(const GLfloat)theUniformValue
{
	NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
														kUniformTypeKey,
														kUniformValueKey,
														nil ];
	
	NSArray *uniformObjects = [NSArray arrayWithObjects:[NSNumber numberWithInt:theUniformLoc],
														[NSNumber numberWithInt:kUniform1f],
														[NSNumber numberWithFloat:theUniformValue],
														nil ];
	
	NSDictionary *uniformDict = [[NSDictionary alloc] initWithObjects:uniformObjects
															  forKeys:uniformKeys];
	return  uniformDict;
} // getDictUniformFloatScalar

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformFloatScalars:(const GLint)theUniformLoc
									type:(const UniformScalarTypes)theUniformType
									value:(const GLfloat *)theUniformValue
{
	NSDictionary *uniformDict = nil;
	
	if ( (  theUniformType > kScalar ) && (  theUniformType <= k4Scalars ) )
	{
		NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
															kUniformTypeKey,
															kUniformValueKey,
															nil ];
		
		NSNumber    *uniformLoc     = [NSNumber numberWithInt:theUniformLoc];
		NSUInteger   uniformLength  = theUniformType * kSizeOfGLfloat;
		NSData      *uniformValues  = [NSData dataWithBytes:theUniformValue length:uniformLength];
		NSNumber    *uniformType    = nil;
		NSArray     *uniformObjects = nil;
		
		switch( theUniformType )
		{
			case k2Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform2f];
				break;
			case k3Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform3f];
				break;
			case k4Scalars:
				uniformType  = [NSNumber numberWithInt:kUniform4f];
				break;
		} // switch
		
		uniformObjects = [NSArray arrayWithObjects:uniformLoc,uniformType,uniformValues,nil];
		uniformDict    = [[NSDictionary alloc] initWithObjects:uniformObjects forKeys:uniformKeys];
	} // if
	
	return  uniformDict;
} // getDictUniformFloatScalars

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformFloatVectors:(const GLint)theUniformLoc
									type:(const UniformVectorTypes)theUniformVectorType
									count:(const GLuint)theUniformVectorCount
									vectors:(const GLfloat *)theUniformVectors
{
	NSDictionary *uniformDict = nil;
	
	if ( theUniformVectorCount >= 1 )
	{
		NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
															kUniformTypeKey,
															kUniformValueKey,
															kUniformCountKey,
															nil ];
		
		NSNumber    *uniformLoc     = [NSNumber numberWithInt:theUniformLoc];
		NSNumber    *uniformCount   = [NSNumber numberWithInt:theUniformVectorCount];
		NSUInteger   uniformLength  = theUniformVectorType * theUniformVectorCount * kSizeOfGLfloat;
		NSData      *uniformValues  = [NSData dataWithBytes:theUniformVectors length:uniformLength];
		NSNumber    *uniformType    = nil;
		NSArray     *uniformObjects = nil;
		
		switch( theUniformVectorType )
		{
			case kVector:
				uniformType  = [NSNumber numberWithInt:kUniform1fv];
				break;
			case k2Vector:
				uniformType  = [NSNumber numberWithInt:kUniform2fv];
				break;
			case k3Vector:
				uniformType  = [NSNumber numberWithInt:kUniform3fv];
				break;
			case k4Vector:
				uniformType  = [NSNumber numberWithInt:kUniform4fv];
				break;
		} // switch
		
		uniformObjects = [NSArray arrayWithObjects:uniformLoc,uniformType,uniformValues,uniformCount,nil];
		uniformDict    = [[NSDictionary alloc] initWithObjects:uniformObjects forKeys:uniformKeys];
	} // if
	
	return  uniformDict;
} // getDictUniformFloatVectors

//------------------------------------------------------------------------

- (NSDictionary *) getDictUniformFloatMatrices:(const GLint)theUniformLoc
										type:(const UniformMatrixTypes)theUniformMatrixType
										count:(const GLuint)theUniformMatrixCount
										transpose:(const GLboolean)theUniformMatrixTranspose
										matrices:(const GLfloat *)theUniformMatrices
{
	NSDictionary *uniformDict = nil;
	
	if ( theUniformMatrixCount >= 1 )
	{
		NSArray *uniformKeys = [NSArray arrayWithObjects:	kUniformLocKey,
															kUniformTypeKey,
															kUniformValueKey,
															kUniformCountKey,
															kUniformTransposeKey,
															nil ];
		
		NSNumber    *uniformLoc       = [NSNumber numberWithInt:theUniformLoc];
		NSNumber    *uniformCount     = [NSNumber numberWithInt:theUniformMatrixCount];
		NSNumber    *uniformTranspose = [NSNumber numberWithInt:theUniformMatrixTranspose];
		NSUInteger   uniformLength    = theUniformMatrixType * theUniformMatrixType * theUniformMatrixCount * kSizeOfGLfloat;
		NSData      *uniformValues    = [NSData dataWithBytes:theUniformMatrices length:uniformLength];
		NSNumber    *uniformType      = nil;
		NSArray     *uniformObjects   = nil;
		
		switch( theUniformMatrixType )
		{
			case k2x2Matrix:
				uniformType  = [NSNumber numberWithInt:kUniformMatrix2fv];
				break;
			case k3x3Matrix:
				uniformType  = [NSNumber numberWithInt:kUniformMatrix3fv];
				break;
			case k4x4Matrix:
				uniformType  = [NSNumber numberWithInt:kUniformMatrix4fv];
				break;
		} // switch
		
		uniformObjects = [NSArray arrayWithObjects:uniformLoc,uniformType,uniformValues,uniformCount,uniformTranspose,nil];
		uniformDict    = [[NSDictionary alloc] initWithObjects:uniformObjects forKeys:uniformKeys];
	} // if
	
	return  uniformDict;
} // getDictUniformFloatMatrices

//------------------------------------------------------------------------

#pragma mark -- Setting Integer Scalar Uniforms --

//------------------------------------------------------------------------

- (void) setUniform1i:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	NSNumber *uniformINum   = [theUniformDict objectForKey:kUniformValueKey];
	GLint     uniformIValue = [uniformINum intValue];
	
	glUniform1iARB( theUniformLoc, uniformIValue );
} // setUniform1i

//------------------------------------------------------------------------

- (void) setUniform2i:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLint   uniformIVec2[2] = { 0, 0 };
	NSData *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformIData getBytes:uniformIVec2];
	
	glUniform2iARB(	theUniformLoc, 
				   uniformIVec2[0], 
				   uniformIVec2[1] );	
} // setUniform2i

//------------------------------------------------------------------------

- (void) setUniform3i:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLint   uniformIVec3[3] = { 0, 0, 0 };
	NSData *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformIData getBytes:uniformIVec3];
	
	glUniform3iARB(	theUniformLoc, 
					uniformIVec3[0], 
					uniformIVec3[1],
					uniformIVec3[2] );	
} // setUniform3i

//------------------------------------------------------------------------

- (void) setUniform4i:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLint   uniformIVec4[4] = { 0, 0, 0, 0 };
	NSData *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformIData getBytes:uniformIVec4];
	
	glUniform4iARB(	theUniformLoc, 
					uniformIVec4[0], 
					uniformIVec4[1],
					uniformIVec4[2],
					uniformIVec4[3] );	
} // setUniform4i

//------------------------------------------------------------------------

#pragma mark -- Setting Integer Vector Uniforms --

//------------------------------------------------------------------------

- (void) setUniform1iv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = uniformCount * kSizeOfGLint;
	GLint    *uniformIVec     = (GLint *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformIVec != NULL )
	{
		[uniformIData getBytes:uniformIVec];
		
		glUniform1ivARB( theUniformLoc, uniformCount, uniformIVec );
	} // if
} // setUniform1iv

//------------------------------------------------------------------------

- (void) setUniform2iv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 2 * uniformCount * kSizeOfGLint;
	GLint    *uniformIVec     = (GLint *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformIVec != NULL )
	{
		[uniformIData getBytes:uniformIVec];
		
		glUniform2ivARB( theUniformLoc, uniformCount, uniformIVec );
	} // if
} // setUniform2iv

//------------------------------------------------------------------------

- (void) setUniform3iv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 3 * uniformCount * kSizeOfGLint;
	GLint    *uniformIVec     = (GLint *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformIVec != NULL )
	{
		[uniformIData getBytes:uniformIVec];
		
		glUniform3ivARB( theUniformLoc, uniformCount, uniformIVec );
	} // if
} // setUniform3iv

//------------------------------------------------------------------------

- (void) setUniform4iv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformIData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 4 * uniformCount * kSizeOfGLint;
	GLint    *uniformIVec     = (GLint *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformIVec != NULL )
	{
		[uniformIData getBytes:uniformIVec];
		
		glUniform4ivARB( theUniformLoc, uniformCount, uniformIVec );
	} // if
} // setUniform4iv

//------------------------------------------------------------------------

#pragma mark -- Setting Float Scalar Uniforms --

//------------------------------------------------------------------------

- (void) setUniform1f:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	NSNumber *uniformFNum   = [theUniformDict objectForKey:kUniformValueKey];
	GLfloat   uniformFValue = [uniformFNum floatValue];
	
	glUniform1fARB( theUniformLoc, uniformFValue );
} // setUniform1f

//------------------------------------------------------------------------

- (void) setUniform2f:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLfloat  uniformFVec2[2] = { 0.0f, 0.0f };
	NSData  *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformFData getBytes:uniformFVec2];
	
	glUniform2fARB(	theUniformLoc, 
					uniformFVec2[0], 
					uniformFVec2[1] );	
} // setUniform2f

//------------------------------------------------------------------------

- (void) setUniform3f:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLfloat uniformFVec3[3] = { 0.0f, 0.0f, 0.0f };
	NSData *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformFData getBytes:uniformFVec3];
	
	glUniform3fARB(	theUniformLoc, 
					uniformFVec3[0], 
					uniformFVec3[1],
					uniformFVec3[2] );	
} // setUniform3f

//------------------------------------------------------------------------

- (void) setUniform4f:(const GLuint)theUniformLoc 
		  dictionaary:(NSDictionary *)theUniformDict
{
	GLfloat uniformFVec4[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	NSData *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	
	[uniformFData getBytes:uniformFVec4];

	glUniform4iARB(	theUniformLoc, 
					uniformFVec4[0], 
					uniformFVec4[1],
					uniformFVec4[2],
					uniformFVec4[3] );	
} // setUniform4f

//------------------------------------------------------------------------

#pragma mark -- Setting Float Vector Uniforms --

//------------------------------------------------------------------------

- (void) setUniform1fv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = uniformCount * kSizeOfGLfloat;
	GLfloat  *uniformFVec     = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniform1fvARB( theUniformLoc, uniformCount, uniformFVec );
	} // if
} // setUniform1fv

//------------------------------------------------------------------------

- (void) setUniform2fv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 2 * uniformCount * kSizeOfGLfloat;
	GLfloat  *uniformFVec     = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniform2fvARB( theUniformLoc, uniformCount, uniformFVec );
	} // if
} // setUniform2fv

//------------------------------------------------------------------------

- (void) setUniform3fv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 3 * uniformCount * kSizeOfGLfloat;
	GLfloat  *uniformFVec     = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniform3fvARB( theUniformLoc, uniformCount, uniformFVec );
	} // if
} // setUniform3fv

//------------------------------------------------------------------------

- (void) setUniform4fv:(const GLuint)theUniformLoc
		   dictionaary:(NSDictionary *)theUniformDict
{
	NSData   *uniformFData    = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber *uniformCountNum = [theUniformDict objectForKey:kUniformCountKey];
	GLuint    uniformCount    = [uniformCountNum intValue];
	GLuint    uniformCapacity = 4 * uniformCount * kSizeOfGLfloat;
	GLfloat  *uniformFVec     = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniform4fvARB( theUniformLoc, uniformCount, uniformFVec );
	} // if
} // setUniform4fv

//------------------------------------------------------------------------

#pragma mark -- Setting Float Matrix Uniforms --

//------------------------------------------------------------------------

- (void) setUniformMatrix2fv:(const GLuint)theUniformLoc
				 dictionaary:(NSDictionary *)theUniformDict
{
	NSData     *uniformFData        = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber   *uniformCountNum     = [theUniformDict objectForKey:kUniformCountKey];
	GLuint      uniformCount        = [uniformCountNum intValue];
	GLuint      uniformCapacity     = 4 * uniformCount * kSizeOfGLfloat;
	NSNumber   *uniformTransposeNum = [theUniformDict objectForKey:kUniformTransposeKey];
	GLboolean   uniformTranspose    = [uniformTransposeNum intValue];
	GLfloat    *uniformFVec         = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniformMatrix2fvARB( theUniformLoc, uniformCount, uniformTranspose, uniformFVec );
	} // if
} // setUniformMatrix2fv

//------------------------------------------------------------------------

- (void) setUniformMatrix3fv:(const GLuint)theUniformLoc
				 dictionaary:(NSDictionary *)theUniformDict
{
	NSData     *uniformFData        = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber   *uniformCountNum     = [theUniformDict objectForKey:kUniformCountKey];
	GLuint      uniformCount        = [uniformCountNum intValue];
	GLuint      uniformCapacity     = 9 * uniformCount * kSizeOfGLfloat;
	NSNumber   *uniformTransposeNum = [theUniformDict objectForKey:kUniformTransposeKey];
	GLboolean   uniformTranspose    = [uniformTransposeNum intValue];
	GLfloat    *uniformFVec         = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniformMatrix3fvARB( theUniformLoc, uniformCount, uniformTranspose, uniformFVec );
	} // if
} // setUniformMatrix3fv

//------------------------------------------------------------------------

- (void) setUniformMatrix4fv:(const GLuint)theUniformLoc
				 dictionaary:(NSDictionary *)theUniformDict
{
	NSData     *uniformFData        = [theUniformDict objectForKey:kUniformValueKey];
	NSNumber   *uniformCountNum     = [theUniformDict objectForKey:kUniformCountKey];
	GLuint      uniformCount        = [uniformCountNum intValue];
	GLuint      uniformCapacity     = 16 * uniformCount * kSizeOfGLfloat;
	NSNumber   *uniformTransposeNum = [theUniformDict objectForKey:kUniformTransposeKey];
	GLboolean   uniformTranspose    = [uniformTransposeNum intValue];
	GLfloat    *uniformFVec         = (GLfloat *)[[MemObject memoryWithType:kMemAlloc size:uniformCapacity] pointer];
	
	if ( uniformFVec != NULL )
	{
		[uniformFData getBytes:uniformFVec];
		
		glUniformMatrix4fvARB( theUniformLoc, uniformCount, uniformTranspose, uniformFVec );
	} // if
} // setUniformMatrix4fv

//------------------------------------------------------------------------

- (void) setUniformsUsingDicts:(NSArray *)theUniforms
{
	NSDictionary *uniformDict    = nil;
	NSNumber     *uniformLocNum  = nil;
	NSNumber     *uniformTypeNum = nil;
	GLuint        uniformLoc     = 0;
	GLuint        uniformType    = 0;
	
	for (uniformDict in theUniforms) 
	{
		uniformLocNum  = [uniformDict objectForKey:kUniformLocKey];
		uniformLoc     = [uniformLocNum intValue];
		uniformTypeNum = [uniformDict objectForKey:kUniformTypeKey];
		uniformType    = [uniformTypeNum intValue];

		switch( uniformType )
		{
			case kUniformSampler1D:
			case kUniformSampler2D:
			case kUniformSampler3D:
			case kUniformSampler2DRect:
			case kUniform1i:
				
				[self setUniform1i:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform2i:

				[self setUniform2i:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform3i:

				[self setUniform3i:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform4i:

				[self setUniform4i:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform1iv:
				
				[self setUniform1iv:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform2iv:

				[self setUniform2iv:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform3iv:

				[self setUniform3iv:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform4iv:

				[self setUniform4iv:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform1f:

				[self setUniform1f:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform2f:

				[self setUniform2f:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform3f:

				[self setUniform3f:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform4f:
				
				[self setUniform4f:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform1fv:
				
				[self setUniform1fv:uniformLoc dictionaary:uniformDict];					
				break;

			case kUniform2fv:
				
				[self setUniform2fv:uniformLoc dictionaary:uniformDict];
				break;

			case kUniform3fv:
				
				[self setUniform3fv:uniformLoc dictionaary:uniformDict];
				break;
				
			case kUniform4fv:
				
				[self setUniform4fv:uniformLoc dictionaary:uniformDict];					
				break;

			case kUniformMatrix2fv:
				
				[self setUniformMatrix2fv:uniformLoc dictionaary:uniformDict];
				break;

			case kUniformMatrix3fv:
				
				[self setUniformMatrix3fv:uniformLoc dictionaary:uniformDict];
				break;

			case kUniformMatrix4fv:
				
				[self setUniformMatrix4fv:uniformLoc dictionaary:uniformDict];
				break;
		} // switch
	} // for
} // setUniformsUsingDicts

//------------------------------------------------------------------------

- (void) setUniforms:(NSArray *)theUniforms
{
	[self enable];
	
		[self setUniformsUsingDicts:theUniforms];
	
	[self disable];
} // setUniforms

//------------------------------------------------------------------------

#pragma mark -- Shader Execution --

//---------------------------------------------------------------------------

- (void) excuteWithCVTexture:(CVOpenGLTextureRef)theVideoFrame
{
	// Get the texture target

	GLenum target = CVOpenGLTextureGetTarget( theVideoFrame );

	// Get the texture target id

	GLuint name = CVOpenGLTextureGetName( theVideoFrame );

	[self enable];
	
		glEnable( target );
		
		glBindTexture( target, name );
		
		[quad draw];
	
	[self disable];
} // excuteWithCVTexture

//---------------------------------------------------------------------------

- (void) executeWithCVTextureAndUniforms:(CVOpenGLTextureRef)theVideoFrame uniforms:(NSArray *)theUniforms
{
	// Get the texture target

	GLenum target = CVOpenGLTextureGetTarget( theVideoFrame );

	// Get the texture target id

	GLuint name = CVOpenGLTextureGetName( theVideoFrame );

	[self enable];
	
		[self setUniformsUsingDicts:theUniforms];
		
		glEnable( target );
		
		glBindTexture( target, name );
		
		[quad draw];
	
	[self disable];
} // executeWithCVTextureAndUniforms

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

