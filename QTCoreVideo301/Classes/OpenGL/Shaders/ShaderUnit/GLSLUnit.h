//-------------------------------------------------------------------------
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
//-------------------------------------------------------------------------

// Required Includes

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#import "OpenGLQuad.h"
#import "GLSLUnitDictConsts.h"
#import "GLSLKit.h"

// The OpenGL Shader Unit

@interface GLSLUnit : GLSLKit
{
	@private
		OpenGLQuad  *quad;
} // GLSLUnit

// Designated initializer
										
- (id) initWithShadersInAppBundleAndSamplers:(NSString *)theShadersName
										size:(const NSSize *)theSize
										samplers:(NSDictionary *)theSamplersDict;

// Setting individual uniforms
										
- (void) uniform1i:(const GLint)theUniformLocation
			value:(const GLint)theUniformValue;
				
- (void) uniform2i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues;
			
- (void) uniform3i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues;
			
- (void) uniform4i:(const GLint)theUniformLocation
			values:(const GLint *)theUniformValues;
			
- (void) uniform1f:(const GLint)theUniformLocation
			value:(const GLfloat)theUniformValue;

- (void) uniform2f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues;
			
- (void) uniform3f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues;
			
- (void) uniform4f:(const GLint)theUniformLocation
			values:(const GLfloat *)theUniformValues;
			
- (void) uniform1iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues;
				
- (void) uniform2iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues;
			
- (void) uniform3iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues;
			
- (void) uniform4iv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLint *)theUniformValues;
			
- (void) uniform1fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues;

- (void) uniform2fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues;
				
- (void) uniform3fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues;
				
- (void) uniform4fv:(const GLint)theUniformLocation
			count:(const GLsizei)theUniformCount
			values:(const GLfloat *)theUniformValues;
				
- (void) uniformMatrix2fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues;

- (void) uniformMatrix3fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues;

- (void) uniformMatrix4fv:(const GLint)theUniformLocation
					count:(const GLsizei)theUniformCount
					tanspose:(const GLboolean)theTransposeFlag
					values:(const GLfloat *)theUniformValues;

// Getting dictionaries for different uniform types
										
- (NSDictionary *) getDictUniformIntScalar:(const GLint)theUniformLoc 
									value:(const GLint)theUniformValue;


- (NSDictionary *) getDictUniformIntScalars:(const GLint)theUniformLoc
									type:(const UniformScalarTypes)theScalarType
									value:(const GLint *)theUniformValue;

- (NSDictionary *) getDictUniformIntVectors:(const GLint)theUniformLoc
									type:(const UniformVectorTypes)theUniformVectorType
									count:(const GLuint)theUniformVectorCount
									vectors:(const GLint *)theUniformVectors;
									
- (NSDictionary *) getDictUniformFloatScalar:(const GLint)theUniformLoc 
										value:(const GLfloat)theUniformValue;

- (NSDictionary *) getDictUniformFloatScalars:(const GLint)theUniformLoc
									type:(const UniformScalarTypes)theUniformType
									value:(const GLfloat *)theUniformValue;
									
- (NSDictionary *) getDictUniformFloatVectors:(const GLint)theUniformLoc
									type:(const UniformVectorTypes)theUniformVectorType
									count:(const GLuint)theUniformVectorCount
									vectors:(const GLfloat *)theUniformVectors;
									
- (NSDictionary *) getDictUniformFloatMatrices:(const GLint)theUniformLoc
										type:(const UniformMatrixTypes)theUniformMatrixType
										count:(const GLuint)theUniformMatrixCount
										transpose:(const GLboolean)theUniformMatrixTranspose
										matrices:(const GLfloat *)theUniformMatrices;
										
// Setting a group of uniforms stored in an array of dictionaries
										
- (void) setUniforms:(NSArray *)theUniforms;

// Executing a shader after uniforms have been set

- (void) excuteWithCVTexture:(CVOpenGLTextureRef)theVideoFrame;

// Executing a shader along with a group of uniforms

- (void) executeWithCVTextureAndUniforms:(CVOpenGLTextureRef)theVideoFrame uniforms:(NSArray *)theUniforms;

@end
