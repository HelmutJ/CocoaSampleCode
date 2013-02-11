/*
     File: GeoUtils.h
 Abstract: Utilities for handling geometry.
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

#ifndef __GEO_UTILS__
#define __GEO_UTILS__

#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <math.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif
	
typedef struct _vec2
{
	float x,y;
} vec2;

typedef struct _vec3
{
	float x,y,z;
} vec3;

typedef struct _vec4
{
	float x,y,z,w;
} vec4;
	
typedef	union _mat4union 
{
	vec4 columns[4];
	float m[16];
	float mm[4][4];
} mat4;
	
static const mat4 ZeroMatrix = 
{
	0.0,0.0,0.0,0.0,
	0.0,0.0,0.0,0.0,
	0.0,0.0,0.0,0.0,
	0.0,0.0,0.0,0.0,
};

static const mat4 IdentityMatrix = 
{
	1.0,0.0,0.0,0.0,
	0.0,1.0,0.0,0.0,
	0.0,0.0,1.0,0.0,
	0.0,0.0,0.0,1.0,
};

static const mat4 FacingPlusXMatrix =
{
	0.0, 0.0, 1.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	-1.0,0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0,
};

static const mat4 FacingMinusXMatrix =
{
	0.0, 0.0,-1.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	1.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0,
};
	
inline float dotproduct(vec4* a, vec4* b)
{
	return	a->x*b->x+
			a->y*b->y+
			a->z*b->z+ 
			a->w*b->w;
}
	
inline void matMul(const mat4* a, const mat4* b, mat4* dst)
{
	assert(a != b && b != dst && a != dst);
	//column 0
	dst->m[0] = a->m[0] *b->m[0] +
				a->m[4] *b->m[1] +
				a->m[8] *b->m[2] +
				a->m[12]*b->m[3];
	dst->m[1] = a->m[1] *b->m[0] +
				a->m[5] *b->m[1] +
				a->m[9] *b->m[2] +
				a->m[13]*b->m[3];
	dst->m[2] = a->m[2] *b->m[0] +
				a->m[6] *b->m[1] +
				a->m[10]*b->m[2] +
				a->m[14]*b->m[3];
	dst->m[3] = a->m[3] *b->m[0] +
				a->m[7] *b->m[1] +
				a->m[11]*b->m[2] +
				a->m[15]*b->m[3];
	//column 1
	dst->m[4] = a->m[0] *b->m[4] +
				a->m[4] *b->m[5] +
				a->m[8] *b->m[6] +
				a->m[12]*b->m[7];
	dst->m[5] = a->m[1] *b->m[4] +
				a->m[5] *b->m[5] +
				a->m[9] *b->m[6] +
				a->m[13]*b->m[7];
	dst->m[6] = a->m[2] *b->m[4] +
				a->m[6] *b->m[5] +
				a->m[10]*b->m[6] +
				a->m[14]*b->m[7];
	dst->m[7] = a->m[3] *b->m[4] +
				a->m[7] *b->m[5] +
				a->m[11]*b->m[6] +
				a->m[15]*b->m[7];
	//column 2
	dst->m[8] = a->m[0] *b->m[8] +
				a->m[4] *b->m[9] +
				a->m[8] *b->m[10] +
				a->m[12]*b->m[11];
	dst->m[9] = a->m[1] *b->m[8] +
				a->m[5] *b->m[9] +
				a->m[9] *b->m[10] +
				a->m[13]*b->m[11];
	dst->m[10]= a->m[2] *b->m[8] +
				a->m[6] *b->m[9] +
				a->m[10]*b->m[10] +
				a->m[14]*b->m[11];
	dst->m[11]= a->m[3] *b->m[8] +
				a->m[7] *b->m[9] +
				a->m[11]*b->m[10] +
				a->m[15]*b->m[11];
	//column 3
	dst->m[12]= a->m[0] *b->m[12] +
				a->m[4] *b->m[13] +
				a->m[8] *b->m[14] +
				a->m[12]*b->m[15];
	dst->m[13]= a->m[1] *b->m[12] +
				a->m[5] *b->m[13] +
				a->m[9] *b->m[14] +
				a->m[13]*b->m[15];
	dst->m[14]= a->m[2] *b->m[12] +
				a->m[6] *b->m[13] +
				a->m[10]*b->m[14] +
				a->m[14]*b->m[15];
	dst->m[15]= a->m[3] *b->m[12] +
				a->m[7] *b->m[13] +
				a->m[11]*b->m[14] +
				a->m[15]*b->m[15];
}
inline void matVecMul(mat4* m, vec4* v, vec4* dst)
{
	assert(v != dst);
	dst->x =	m->m[0]*v->x +
				m->m[4]*v->y +
				m->m[8]*v->z +
				m->m[12]*v->w;
	dst->y =	m->m[1]*v->x +
				m->m[5]*v->y +
				m->m[9]*v->z +
				m->m[13]*v->w;
	dst->z =	m->m[2]*v->x +
				m->m[6]*v->y +
				m->m[10]*v->z +
				m->m[14]*v->w;
	dst->w =	m->m[3]*v->x +
				m->m[7]*v->y +
				m->m[11]*v->z +
				m->m[15]*v->w;
}
	
inline void makeTransformMatrix(float x,float y,float z, mat4* dst)	
{
	memcpy(dst, &IdentityMatrix, sizeof(mat4));
	dst->columns[3].x = x;
	dst->columns[3].y = y;
	dst->columns[3].z = z;
	dst->columns[3].w = 1.0;
}

typedef struct _QuadricStruct
{
	GLuint vertCount;
	GLuint indexCount;
	GLuint vertsID;
	GLuint normalsID;
	GLuint colorsID;
	GLuint texCoordsID;
	GLuint indexesID;
} quadric;

void createTriangleToothedGear(quadric* q, float radius, float innerradius, float toothRadius, float thickness, int slices);
void createTriangleToothedGearFlat(quadric* q, float radius, float innerradius, float toothRadius, float thickness, int slices);
void normalizeVec3(vec3* in, vec3* out);
float *GenHeightMap(int wide, int deep, int seed);
	
#ifdef __cplusplus
}
#endif

#endif