/*
     File: renderer.cpp
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

#include "renderer.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <GLUT/glut.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFURL.h>
#include <ApplicationServices/ApplicationServices.h>

#define glError() { \
	GLenum err = glGetError(); \
	while (err != GL_NO_ERROR) { \
		__builtin_printf("glError: %s caught at %s:%u\n", (char *)gluErrorString(err), __FILE__, __LINE__); \
		err = glGetError(); \
		exit(-1); \
	} \
}

#define VS0_NAME "HeightArray.vs"
#define FS0_NAME "HeightArray.fs"
#define VS1_NAME "passthrough.vs"
#define FS1_NAME "visualizeArrayTexture.fs"

#define TEXTURE0 "rock.jpg"
#define TEXTURE1 "grass.jpg"
#define TEXTURE2 "dirt.jpg"
#define TEXTURE3 "snow.jpg"

const uint32_t kHeightMapDefaultSize = 64;

GLboolean loadShader(GLenum shaderType, const GLchar** shaderText, GLint* shaderID);
GLboolean linkShaders(GLint* program, GLint vertShaderID, GLint fragShaderID);

#pragma mark Constructor/Destructor

OpenGLRenderer::OpenGLRenderer(const char* pathToResources, size_t len)
{
	resourcePath = (char*) malloc(len+1);
	resourcePath[len] = '\0';
	strncpy(resourcePath, pathToResources, len);
	rendererString = glGetString(GL_RENDERER);
	animate = GL_FALSE;
	animationStep = 0;
	animationDelta = 1.5;
	kAnimationLoopValue = 360.0 / animationDelta;
	iHeightMapSize = kHeightMapDefaultSize;
	slice = 0.0;
	displayTexture = false;
	xAxisAngle = -45.0;
	zAxisAngle = 43.0;
}

OpenGLRenderer::~OpenGLRenderer()
{
	glFinish();
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glDeleteBuffers(kNumVBO, vbo);
	glDeleteBuffers(iHeightMapSize, terrain);
	glDeleteTextures(kNumTextures, tex);
	glDeleteFramebuffersEXT(kNumFBO, fbos);
	free(resourcePath);
	glUseProgram(0);
	int i = 0;
	for (; i < kProgramCount; i++) {
		glDeleteProgram(programs[i]);
	}
	for (; i < kShaderCount; i++) {
		glDeleteShader(shaders[i]);
	}
	free(map);
	free(terrain);
}

#pragma mark Loading Utilities

#pragma mark Shader Loading

GLboolean OpenGLRenderer::loadShaderFromFile(const char* shaderName, GLenum shaderType, GLint* shaderID)
{
	char pathToShader[255];
	bzero(pathToShader, 255);
	sprintf(&pathToShader[0], "%s/%s", resourcePath, shaderName);
	FILE* f = fopen(pathToShader, "rb");
	if(!f)
	{
		__builtin_printf("Could not open file %s\n", pathToShader);
		return NULL;
	}
	fseek(f, 0, SEEK_END);
	size_t shaderLen = ftell(f);
	fseek(f, 0, SEEK_SET);
	GLchar* code = (GLchar*) malloc(shaderLen+1);
	fread(code, sizeof(char), shaderLen, f);
	fclose(f);
	code[shaderLen] = '\0';
	GLboolean r = loadShader(shaderType, (const GLchar**) &code, shaderID);
	if(!r)
	{
		__builtin_printf("Failed to load %s\n", shaderName);
	}
	free(code);
	return r;
}

GLboolean loadShader(GLenum shaderType, const GLchar** shaderText, GLint* shaderID)
{
	GLint status = 0;
	
	*shaderID = glCreateShader(shaderType);
	glShaderSource(*shaderID, 1, shaderText, NULL);
	glCompileShader(*shaderID);
	glGetShaderiv(*shaderID, GL_COMPILE_STATUS, &status);
	if(status == GL_FALSE)
	{
		GLint logLength = 0;
		glGetShaderiv(*shaderID, GL_INFO_LOG_LENGTH, &logLength);
		GLcharARB *log = (GLcharARB*) malloc(logLength);
		glGetShaderInfoLog(*shaderID, logLength, &logLength, log);
		printf("Shader compile log\n %s", log);
		free(log);
		return GL_FALSE;
	}
	return GL_TRUE;
}

GLboolean linkShaders(GLint* program, GLint vertShaderID, GLint fragShaderID)
{
	GLint status = 0;
	*program = glCreateProgram();
	glAttachShader(*program, vertShaderID);
	glAttachShader(*program, fragShaderID);
	
	GLint logLength;
	
	glLinkProgram(*program);
	glGetProgramiv(*program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar*) malloc(logLength);
		glGetProgramInfoLog(*program, logLength, &logLength, log);
		printf("Program link log:\n%s\n", log);
		free(log);
		glDeleteShader(vertShaderID);
		glDeleteShader(fragShaderID);
		return GL_FALSE;
	}
	glValidateProgram(*program);
	glGetProgramiv(*program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(*program, logLength, &logLength, log);
		printf("Program validate log:\n%s\n", log);
		free(log);
        return GL_FALSE;
	}
	
	glGetProgramiv(*program, GL_VALIDATE_STATUS, &status);
	if (status == 0)
    {
		printf("Failed to validate program %d\n", *program);
        return GL_FALSE;
    }
	return GL_TRUE;
}

GLshort OpenGLRenderer::loadShaders()
{
	if(!loadShaderFromFile(VS0_NAME, GL_VERTEX_SHADER, &shaders[0]))
		return 1;
	
	if(!loadShaderFromFile(FS0_NAME, GL_FRAGMENT_SHADER, &shaders[1]))
		return 2;
	
	if(!linkShaders(&programs[0], shaders[0], shaders[1]))
	{
		return 3;
	}
	
	cameraMatrixLocation = glGetUniformLocation(programs[0], "cameraMatrix");
	textureMatrixLocation = glGetUniformLocation(programs[0], "textureMatrix");
	samplerLocation = glGetUniformLocation(programs[0], "sampler");
	assert(cameraMatrixLocation != -1);
	assert(textureMatrixLocation != -1);
	assert(samplerLocation != -1);
	
	if(!loadShaderFromFile(VS1_NAME, GL_VERTEX_SHADER, &shaders[2]))
		return 1;
	
	if(!loadShaderFromFile(FS1_NAME, GL_FRAGMENT_SHADER, &shaders[3]))
		return 2;
	
	if(!linkShaders(&programs[1], shaders[2], shaders[3]))
	{
		return 3;
	}
	

	displaySamplerLocation = glGetUniformLocation(programs[1], "sampler");
	sliceLocation = glGetUniformLocation(programs[1], "slice");
	
	glError();
	
	return 0;
}

#pragma mark Texture Loading

bool OpenGLRenderer::loadTexture(const char* filename, uint32_t* wide, uint32_t* high, GLenum* format, GLenum* type, void** data)
{	
	CFStringRef string = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%s/%s"), resourcePath, filename);
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, string, kCFURLPOSIXPathStyle, false);
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, nil);
	CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
	CFRelease(string);
	CFRelease(url);
	
	*wide = CGImageGetWidth(image);
	*high = CGImageGetHeight(image);
	GLint bpr = CGImageGetBytesPerRow(image);
	
	//if you want more info about the texture, look at these values
//	CGBitmapInfo info = CGImageGetBitmapInfo(image);
//	GLint bpp = CGImageGetBitsPerPixel(image);
	
	size_t numBytes = bpr * (*high);
	
	*format = GL_RGBA;
	*type = GL_UNSIGNED_BYTE;
	
	// get copy of raw uncompressed data
	CGDataProviderRef provider = CGImageGetDataProvider(image);
	CFDataRef dataref = CGDataProviderCopyData(provider);
	*data = malloc(numBytes);
	memcpy(*data, CFDataGetBytePtr(dataref), numBytes);
	CFRelease(dataref);
	return true;
}

#pragma mark Geometry Loading

bool OpenGLRenderer::setupScene()
{
	float fHeightMapSize = (float) iHeightMapSize;
	GLfloat quad[] =
	{
		//      x               y          z    s    t
		-fHeightMapSize,-fHeightMapSize, -7.0, 0.0, 0.0,
		 fHeightMapSize,-fHeightMapSize, -7.0, 1.0, 0.0,
		 fHeightMapSize, fHeightMapSize, -7.0, 1.0, 1.0,
		-fHeightMapSize, fHeightMapSize, -7.0, 0.0, 1.0, 
	};
	GLfloat fsquad[] =
	{
		-1.0, -1.0, 0.0, 0.0,
		 1.0, -1.0, 1.0, 0.0,
		 1.0,  1.0, 1.0, 1.0,
		-1.0,  1.0, 0.0, 1.0,
	};
	GLushort indexes[] =
	{
		0,1,3,2,
	};
	glGenBuffers(kNumVBO, vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo[kWaterPlane]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(quad), &quad[0], GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, vbo[kBlitQuad]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(fsquad), fsquad, GL_STATIC_DRAW);
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo[kQuadIndex]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), &indexes[0], GL_STATIC_DRAW);
	
	//You can play around with the terrain generation here...
//	map = GenHeightMap(iHeightMapSize, iHeightMapSize, 0xDEADBEEF);
	map = GenHeightMap(iHeightMapSize, iHeightMapSize, 0xBEEFBEEF);
	
	terrain = (GLuint*) malloc(sizeof(GLuint)*iHeightMapSize);
	
	size_t bufsize = iHeightMapSize*12*sizeof(GLfloat);
	
	glGenBuffers(iHeightMapSize-1, terrain);
	//now let's load this heightmap into buffer objects
	int i, j;
	for (j = 0; j < iHeightMapSize-1; j++)
	{
		glBindBuffer(GL_ARRAY_BUFFER, terrain[j]);
		//allocate enough space in VRAM
		glBufferData(GL_ARRAY_BUFFER, bufsize, NULL, GL_STATIC_DRAW);
		//map the VBO into client memory and fill it
		float* buf = (float*) glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
		/*
			NOTE:
			The map buffer has 6 floats per vertex, position and normal
			This loads the terrain in, as vertical slices (think a cross section)
			We load from the current row and row+1 to fill out the tristrips
		 */
		for (i = 0; i < iHeightMapSize; i++)
		{
			int ndx = i*12;
			memcpy(&buf[ndx]  , &map[( j   *iHeightMapSize + i)*6]  , sizeof(GLfloat)*6);
			memcpy(&buf[ndx+6], &map[( (j+1) *iHeightMapSize + i)*6]  , sizeof(GLfloat)*6);
		}
		glUnmapBuffer(GL_ARRAY_BUFFER);
	}
	
	return true;
}


#pragma mark Camera Utility

void OpenGLRenderer::regenCameraMatrix()
{
	//set up a default camera matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0, 0, -2.25);
	glRotatef(xAxisAngle, 1, 0, 0);
	glRotatef(zAxisAngle, 0, 0, 1);
	glScalef(2.0/iHeightMapSize, 2.0/iHeightMapSize, 4.0/iHeightMapSize);
	glGetFloatv(GL_MODELVIEW_MATRIX, (GLfloat*) &cameraMatrix);
	glLoadIdentity();
}

void OpenGLRenderer::applyCameraMovement(float dx, float dy)
{
	xAxisAngle += dy/3.0;
	zAxisAngle += dx/3.0;
	regenCameraMatrix();
}

#pragma mark Main Setup

bool OpenGLRenderer::setupGL()
{
	int err = 0;
	err = loadShaders();
	if(err != 0)
	{
		assert(0);
		return false;
	}
	
	if(!setupScene())
	{
		assert(0);
		return false;
	}
	glError();
	
	/* load textures to sysmem */
	
	//NOTE: consider client storage here? would need to stitch together each slice....
	void* data0, *data1, *data2, *data3;
	uint32_t wide, high;
	GLenum format, type;

	if(!loadTexture(TEXTURE0, &wide, &high, &format, &type, &data0))
	{
		return false;
	}
	if(!loadTexture(TEXTURE1, &wide, &high, &format, &type, &data1))
	{
		return false;
	}
	if(!loadTexture(TEXTURE2, &wide, &high, &format, &type, &data2))
	{
		return false;
	}
	if(!loadTexture(TEXTURE3, &wide, &high, &format, &type, &data3))
	{
		return false;
	}
	glError();
	
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glPixelStorei(GL_PACK_ALIGNMENT, 1);
		
	//send textures to GPU
	glGenTextures(1, &tex[0]);
	glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, tex[0]);
	glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
	glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	glTexImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, GL_RGB8, wide, high, 4, 0, format, type, NULL);
	glTexSubImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, 0, 0, 0, wide, high, 1, format, type, data0);
	glTexSubImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, 0, 0, 1, wide, high, 1, format, type, data1);
	glTexSubImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, 0, 0, 2, wide, high, 1, format, type, data2);
	glTexSubImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, 0, 0, 3, wide, high, 1, format, type, data3);
	
	free(data0);
	free(data1);
	free(data2);
	free(data3);
	
	glViewport(0, 0, width, height);
	glClearColor(0.3, 0.4, 0.5, 1.0);
	glEnable(GL_DEPTH_TEST);
	
	regenCameraMatrix();
	
	glError();
	
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	glTranslatef(0.0, 0.0, -0.5);
	glScalef(1.0, 1.0, 4.0);
	glScalef(1.0/iHeightMapSize, 1.0/iHeightMapSize, 1.0/16.0);
	glTranslatef(0.0, 0.0, 8.0);
	glGetFloatv(GL_TEXTURE_MATRIX, (GLfloat*) &textureMatrix);
	glLoadIdentity();
	
	glError();

	return true;
}

void OpenGLRenderer::reshape(uint32_t w, uint32_t h)
{
	width = w;
	height = h;
	glViewport(0, 0, width, height);
}

#pragma mark Main Rendering Here:

void OpenGLRenderer::draw()
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	if (displayTexture) {
		glUseProgram(programs[1]);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, tex[0]);
		glUniform1i(displaySamplerLocation, 0);
		glUniform1f(sliceLocation, slice);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glBindBuffer(GL_ARRAY_BUFFER, vbo[kBlitQuad]);
		glVertexPointer(2, GL_FLOAT, sizeof(GLfloat)*4, NULL);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo[kQuadIndex]);
		glEnableClientState(GL_VERTEX_ARRAY);
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, NULL);
		glDisableClientState(GL_VERTEX_ARRAY);
		return;
	}
	
	
	// draw simple 3D terrain
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60.0, (float)width/height, 1, 100);
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf((const GLfloat*) &cameraMatrix);
	glMatrixMode(GL_TEXTURE);
	glLoadMatrixf((const GLfloat*) &textureMatrix);
	
	glUseProgram(programs[0]);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, tex[0]);
	glUniformMatrix4fv(cameraMatrixLocation, 1, GL_FALSE, (const GLfloat*) &cameraMatrix);
	glUniformMatrix4fv(textureMatrixLocation, 1, GL_FALSE, (const GLfloat*) &textureMatrix);
	glUniform1i(samplerLocation, 0);
	
	/*
		NOTE:
		This is NOT the most efficient way to draw terrain.
		You probably want Frustum-culled patches or something similar, instead of always
		drawing strips of terrain as this does.
	 */
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	int j;
	for (j = 0; j < iHeightMapSize-1; j++)
	{
		glBindBuffer(GL_ARRAY_BUFFER, terrain[j]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		glVertexPointer(3, GL_FLOAT, sizeof(GLfloat)*6, NULL);
		glTexCoordPointer(3, GL_FLOAT, sizeof(GLfloat)*6, NULL);
		glNormalPointer(GL_FLOAT, sizeof(GLfloat)*6, (const GLvoid*) (sizeof(GLfloat)*3));
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, iHeightMapSize*2);
	}
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glUseProgram(0);
		
	// water plane
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glColor4f(0.1, 0.3, 0.6, 0.4);
	glBindBuffer(GL_ARRAY_BUFFER, vbo[kWaterPlane]);
	glVertexPointer(3, GL_FLOAT, sizeof(GLfloat)*5, NULL);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo[kQuadIndex]);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, NULL);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_BLEND);		
	glColor4f(1.0, 1.0, 1.0, 1.0);
}