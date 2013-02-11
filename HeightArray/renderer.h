/*
     File: renderer.h
 Abstract: The renderer class creates and draws the OpenGL shaders.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#ifndef __RENDERER__
#define __RENDERER__

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>
#include <stdint.h>
#include <stdio.h>
#include "GeoUtils.h"

const uint32_t kShaderCount = 4;
const uint32_t kProgramCount = 2;
const uint32_t kNumMRT = 1;
const uint32_t kNumFBO = 1;
const uint32_t kNumTextures = 5;
const uint32_t kNumVBO = 4;

const GLuint kWaterPlane	= 0;
const GLuint kQuadIndex		= 1;
const GLuint kBlitQuad		= 2;

class OpenGLRenderer
{
	const GLubyte* rendererString;
	char* resourcePath;
	
	uint32_t width, height;
	
	GLint shaders[kShaderCount];
	GLint programs[kProgramCount];
	GLuint cameraMatrixLocation, textureMatrixLocation, samplerLocation;	
	GLuint displaySamplerLocation, sliceLocation;
	
	GLuint fbos[kNumFBO];
	GLuint tex[kNumTextures];
	
	GLuint vbo[kNumVBO];
	
	uint8_t animationStep, animate;
	float animationDelta;
	uint32_t kAnimationLoopValue;
	GLfloat zAxisAngle, xAxisAngle;
	
	uint32_t iHeightMapSize;
	GLfloat* map;
	GLuint* terrain;
	
	mat4 cameraMatrix, textureMatrix;
	
	bool displayTexture;
	float slice;
	
public:
	OpenGLRenderer();
	OpenGLRenderer(const char* pathToResources, size_t len);
	~OpenGLRenderer();
	const char* getRendererString()
	{
		return (const char*) rendererString;
	}
	bool setupScene();
	bool setupGL();
	void reshape(uint32_t w, uint32_t h);
	void draw();
	GLshort loadShaders();
	GLboolean loadShaderFromFile(const char* shaderName, GLenum shaderType, GLint* shaderID);
	bool loadTexture(const char* filename, uint32_t* wide, uint32_t* high, GLenum* format, GLenum* type, void** data);
	void toggleAnimation()
	{
		animate = !animate;
	}
	void resetAnimation()
	{
		animationStep = 0;
	}
	void setAnimationDelta(float d)
	{
		animationDelta = d;
		kAnimationLoopValue = 360.0 / animationDelta;
	}
	void toggleTextureDisplay()
	{
		displayTexture = !displayTexture;
	}
	void displaySlice(float s) 
	{
		slice = s;
	}
	void applyCameraMovement(float dx, float dy);
private:
	void regenCameraMatrix();
};

#endif