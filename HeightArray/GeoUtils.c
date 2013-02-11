/*
     File: GeoUtils.c
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

#include "GeoUtils.h"

vec3 r =  {1.0, 0.0, 0.0};
vec3 r1 = {0.5, 0.0, 0.0};
vec3 g =  {0.0, 1.0, 0.0};
vec3 g1 = {0.0, 0.5, 0.0};
vec3 b = {0.0, 0.0, 1.0};

void normalizeVec3(vec3* in, vec3* out)
{
	float reciplen = 1.0 / sqrt(in->x*in->x + in->y*in->y + in->z*in->z);
	out->x = in->x * reciplen;
	out->y = in->y * reciplen;
	out->z = in->z * reciplen;
}

void crossProduct(vec3* in1, vec3* in2, vec3* out)
{
	float x,y,z;
	x = (in1->y*in2->z) - (in1->z*in2->y);
	y = (in1->z*in2->x) - (in1->x*in2->z);
	z = (in1->x*in2->y) - (in1->y*in2->x);
	out->x = x;
	out->y = y;
	out->z = z;
}


void createTriangleToothedGear(quadric* q, float radius, float innerradius, float toothRadius, float thickness, int slices)
{
	int i = 0, ndx = 0;
	float zPos = thickness/2.0;
	float zNeg = -zPos;
	double phiDelta = (2 * M_PI) / slices;
	double phi = 0;
	q->vertCount = slices* 2 + slices * 4;
	vec3* vtx = (vec3*) malloc(q->vertCount * sizeof(vec3));
	vec3* colors = (vec3*) malloc(q->vertCount * sizeof(vec3));
	vec3* normals = (vec3*) malloc(q->vertCount * sizeof(vec3));
	
	for (; i < slices; i++) 
	{
		vec3 outerVtx, innerVtx, toothVtx, temp;
		//generate tooth location
		toothVtx.x = toothRadius * cos(phi+(phiDelta/2.0));
		toothVtx.y = toothRadius * sin(phi+(phiDelta/2.0));
		toothVtx.z = zPos;
		//front of gear
		//outermost vtx
		outerVtx.x = radius * cos(phi);
		outerVtx.y = radius * sin(phi);
		outerVtx.z = zPos;
		//normal (HACK)
		//the gear's face is pointing toward +z, the teeth average out to pointing in +r
		temp = outerVtx;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		temp.x /= 2.0;
		temp.y /= 2.0;
		temp.z = 0.5;
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;
		colors[ndx] = r;
		vtx[ndx++] = outerVtx;
		
		//innermost vtx
		innerVtx.x = innerradius * cos(phi);
		innerVtx.y = innerradius * sin(phi);
		innerVtx.z = zPos;
		//normal
		temp = innerVtx;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		temp.x /= -2.0;
		temp.y /= -2.0;
		temp.z = 0.5;
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;		
		colors[ndx] = r1;
		vtx[ndx++] = innerVtx;
		
		//backside
		//outermost
		outerVtx.z = zNeg;
		//normal (HACK)
		//the gear's face is pointing toward +z, the teeth average out to pointing in +r
		temp = outerVtx;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		temp.x /= 2.0;
		temp.y /= 2.0;
		temp.z = -0.5;
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;
		colors[ndx] = g;
		vtx[ndx++] = outerVtx;
		
		//innermost
		innerVtx.z = zNeg;
		//normal
		temp = innerVtx;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		temp.x /= -2.0;
		temp.y /= -2.0;
		temp.z = -0.5;
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;
		colors[ndx] = g1;
		vtx[ndx++] = innerVtx;
		
		//add tooth to buffer
		//calc normal
		/* These calculations are physically correct
		vec3 v1 = toothVtx, v2 = {0,0,zNeg-zPos};
		vec3 minusPhiFaceNormal, plusPhiFaceNormal;
		v1.x = outerVtx.x - v1.x;
		v1.y = outerVtx.y - v1.y;
		v1.z = 0;
		crossProduct(&v1, &v2, &temp);
		normalizeVec3(&temp, &minusPhiFaceNormal);
		
		v1.x = (radius * cos(phi+phiDelta)) - toothVtx.x;
		v1.y = (radius * sin(phi+phiDelta)) - toothVtx.y;
		v1.z = 0;
		
		crossProduct(&v2, &v1, &temp);
		normalizeVec3(&temp, &plusPhiFaceNormal);
		temp.x = (plusPhiFaceNormal.x + minusPhiFaceNormal.x) / 3.0;
		temp.y = (plusPhiFaceNormal.y + minusPhiFaceNormal.y) / 3.0;
		temp.z = 1.0 / 3.0;
		normalizeVec3(&temp, &temp);
		 */
		
		//and these are easier
		temp = toothVtx;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		
		temp.x /= 2.0,
		temp.y /= 2.0,
		temp.z = 0.5;
		normalizeVec3(&temp, &temp);		
		
		normals[ndx] = temp;
		colors[ndx] = b;
		vtx[ndx++] = toothVtx;
		//backside
		toothVtx.z = zNeg;
		//flip z for the backside normal
		temp.z *= -1.0;
		normals[ndx] = temp;
		colors[ndx] = b;
		vtx[ndx++] = toothVtx;
		
		phi += phiDelta;
	}
	
	//				one tooth per slice if multiplier == 1
	//				tooth face has 3 vtx on each side 
	//				6 vtx for each side of teeth
	//				6 vtx for face of gear slice on each side
	//				6 vtx for inward gear slice
	q->indexCount = slices * 6 + slices * 12 + slices * 12 + slices * 6;
	GLuint* indexes = (GLuint*) malloc(q->indexCount * sizeof(GLuint));
	for (i = 0, ndx = 0; i < slices-1; i++) {
		GLuint curSliceIndex = i*6;
		//front face
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+6; indexes[ndx++] = curSliceIndex+7;
		indexes[ndx++] = curSliceIndex+7; indexes[ndx++] = curSliceIndex+1; indexes[ndx++] = curSliceIndex;
		//tooth facing +phi
		indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex+5; indexes[ndx++] = curSliceIndex+8;
		indexes[ndx++] = curSliceIndex+8; indexes[ndx++] = curSliceIndex+6; indexes[ndx++] = curSliceIndex+4;
		//tooth facing -phi
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+5;
		indexes[ndx++] = curSliceIndex+5; indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex;
		//front tooth face
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex+6;
		//back tooth face
		indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+8; indexes[ndx++] = curSliceIndex+5;
		//back face
		indexes[ndx++] = curSliceIndex+8; indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+3;
		indexes[ndx++] = curSliceIndex+3; indexes[ndx++] = curSliceIndex+9; indexes[ndx++] = curSliceIndex+8;
		//inner edge
		indexes[ndx++] = curSliceIndex+1; indexes[ndx++] = curSliceIndex+7; indexes[ndx++] = curSliceIndex+9;
		indexes[ndx++] = curSliceIndex+9; indexes[ndx++] = curSliceIndex+3; indexes[ndx++] = curSliceIndex+1;
	}
	//wrap gear
	GLuint curSliceIndex = i*6;
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = 0;					indexes[ndx++] = 1;
	indexes[ndx++] = 1;					indexes[ndx++] = curSliceIndex+1;	indexes[ndx++] = curSliceIndex;
	//tooth facing +phi
	indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = curSliceIndex+5;	indexes[ndx++] = 2;
	indexes[ndx++] = 2;					indexes[ndx++] = 0;					indexes[ndx++] = curSliceIndex+4;
	//tooth facing -phi
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = curSliceIndex+5;
	indexes[ndx++] = curSliceIndex+5;	indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = curSliceIndex;
	//front tooth face
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = 0;
	//back tooth face
	indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = 2;					indexes[ndx++] = curSliceIndex+5;
	//back face
	indexes[ndx++] = 2;					indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = curSliceIndex+3;
	indexes[ndx++] = curSliceIndex+3;	indexes[ndx++] = 3;					indexes[ndx++] = 2;
	//inner edge
	indexes[ndx++] = curSliceIndex+1;	indexes[ndx++] = 1;					indexes[ndx++] = 3;
	indexes[ndx++] = 3;					indexes[ndx++] = curSliceIndex+3;	indexes[ndx++] = curSliceIndex+1;
	
	glBindBuffer(GL_ARRAY_BUFFER, q->vertsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), vtx, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, q->colorsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), colors, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, q->normalsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), normals, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, q->indexesID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, q->indexCount*sizeof(GLuint), indexes, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	free(vtx);
	free(colors);
	free(normals);
	free(indexes);
}

void createTriangleToothedGearFlat(quadric* q, float radius, float innerradius, float toothRadius, float thickness, int slices)
{
	int i = 0, ndx = 0;
	float zPos = thickness/2.0;
	float zNeg = -zPos;
	double phiDelta = (2 * M_PI) / slices;
	double phi = 0;
	q->vertCount = slices* 2 + slices * 4;
	vec3* vtx = (vec3*) malloc(q->vertCount * sizeof(vec3));
	vec3* colors = (vec3*) malloc(q->vertCount * sizeof(vec3));
	vec3* normals = (vec3*) malloc(q->vertCount * sizeof(vec3));
	
	for (; i < slices; i++) 
	{
		vec3 outerVtx, innerVtx, toothVtx, temp;
		//generate tooth location
		toothVtx.x = toothRadius * cos(phi+(phiDelta/2.0));
		toothVtx.y = toothRadius * sin(phi+(phiDelta/2.0));
		toothVtx.z = zPos;
		//front of gear
		//outermost vtx
		outerVtx.x = radius * cos(phi);
		outerVtx.y = radius * sin(phi);
		outerVtx.z = zPos;
		//normal for gear and tooth faces
		temp.x = 0.0;
		temp.y = 0.0;
		temp.z = 1.0;
		normals[ndx] = temp;
		colors[ndx] = r;
		vtx[ndx++] = outerVtx;
		
		//innermost vtx
		innerVtx.x = innerradius * cos(phi);
		innerVtx.y = innerradius * sin(phi);
		innerVtx.z = zPos;
		//normal for inner ring of gear
		temp.x = -toothVtx.x;
		temp.y = -toothVtx.y;
		temp.z = 0;
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;		
		colors[ndx] = r1;
		vtx[ndx++] = innerVtx;
		
		//backside
		//outermost
		outerVtx.z = zNeg;
		//normal for gear and tooth backfaces
		temp.x = 0.0;
		temp.y = 0.0;
		temp.z = -1.0;
		normals[ndx] = temp;
		colors[ndx] = g;
		vtx[ndx++] = outerVtx;
		
		//innermost
		innerVtx.z = zNeg;
		//normal (unused)
		temp.x = 0.0;
		temp.y = 0.0;
		temp.z = -1.0;
		normals[ndx] = temp;
		colors[ndx] = g1;
		vtx[ndx++] = innerVtx;
		
		//add tooth to buffer
		//calc normal
		//2 vectors making up the face of the -phi facing tooth surface
		vec3 v1 = toothVtx, v2 = {0,0,zNeg-zPos};
		v1.x = outerVtx.x - v1.x;
		v1.y = outerVtx.y - v1.y;
		v1.z = 0;
		crossProduct(&v1, &v2, &temp);
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;
		colors[ndx] = b;
		vtx[ndx++] = toothVtx;
		//backside
		toothVtx.z = zNeg;
		//normal denoting the +phi facing side of the tooth
		v1.x = (radius * cos(phi+phiDelta)) - toothVtx.x;
		v1.y = (radius * sin(phi+phiDelta)) - toothVtx.y;
		v1.z = 0;		
		crossProduct(&v2, &v1, &temp);
		normalizeVec3(&temp, &temp);
		normals[ndx] = temp;
		colors[ndx] = b;
		vtx[ndx++] = toothVtx;
		
		phi += phiDelta;
	}
	
	//				one tooth per slice if multiplier == 1
	//				tooth face has 3 vtx on each side 
	//				6 vtx for each side of teeth
	//				6 vtx for face of gear slice on each side
	//				6 vtx for inward gear slice
	q->indexCount = slices * 6 + slices * 12 + slices * 12 + slices * 6;
	GLuint* indexes = (GLuint*) malloc(q->indexCount * sizeof(GLuint));
	for (i = 0, ndx = 0; i < slices-1; i++) {
		GLuint curSliceIndex = i*6;
		//front face
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+6; indexes[ndx++] = curSliceIndex+7;
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+7; indexes[ndx++] = curSliceIndex+1;
		//tooth facing +phi
		indexes[ndx++] = curSliceIndex+5; indexes[ndx++] = curSliceIndex+8; indexes[ndx++] = curSliceIndex+6;
		indexes[ndx++] = curSliceIndex+5; indexes[ndx++] = curSliceIndex+6; indexes[ndx++] = curSliceIndex+4;
		//tooth facing -phi
		indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+2;
		indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+5;
		//front tooth face
		indexes[ndx++] = curSliceIndex;   indexes[ndx++] = curSliceIndex+4; indexes[ndx++] = curSliceIndex+6;
		//back tooth face
		indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+8; indexes[ndx++] = curSliceIndex+5;
		//back face
		indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+3; indexes[ndx++] = curSliceIndex+9;
		indexes[ndx++] = curSliceIndex+2; indexes[ndx++] = curSliceIndex+9; indexes[ndx++] = curSliceIndex+8;
		//inner edge
		indexes[ndx++] = curSliceIndex+1; indexes[ndx++] = curSliceIndex+7; indexes[ndx++] = curSliceIndex+9;
		indexes[ndx++] = curSliceIndex+1; indexes[ndx++] = curSliceIndex+9; indexes[ndx++] = curSliceIndex+3;
	}
	//wrap gear
	GLuint curSliceIndex = i*6;
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = 0;					indexes[ndx++] = 1;
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = 1;					indexes[ndx++] = curSliceIndex+1;
	//tooth facing +phi
	indexes[ndx++] = curSliceIndex+5;	indexes[ndx++] = 2;					indexes[ndx++] = 0;
	indexes[ndx++] = curSliceIndex+5;	indexes[ndx++] = 0;					indexes[ndx++] = curSliceIndex+4;
	//tooth facing -phi
	indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = curSliceIndex+2;
	indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = curSliceIndex+5;
	//front tooth face
	indexes[ndx++] = curSliceIndex;		indexes[ndx++] = curSliceIndex+4;	indexes[ndx++] = 0;
	//back tooth face
	indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = 2;					indexes[ndx++] = curSliceIndex+5;
	//back face
	indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = curSliceIndex+3;	indexes[ndx++] = 3;
	indexes[ndx++] = curSliceIndex+2;	indexes[ndx++] = 3;					indexes[ndx++] = 2;
	//inner edge
	indexes[ndx++] = curSliceIndex+1;	indexes[ndx++] = 1;					indexes[ndx++] = 3;
	indexes[ndx++] = curSliceIndex+1;	indexes[ndx++] = 3;					indexes[ndx++] = curSliceIndex+3;
	
	glBindBuffer(GL_ARRAY_BUFFER, q->vertsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), vtx, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, q->colorsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), colors, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, q->normalsID);
	glBufferData(GL_ARRAY_BUFFER, q->vertCount*sizeof(vec3), normals, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, q->indexesID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, q->indexCount*sizeof(GLuint), indexes, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	free(vtx);
	free(colors);
	free(normals);
	free(indexes);
}

static unsigned int randseed, m_lo, m_hi;
// ---------------------------------------------------------------------
// seed 32 bit RANROT-B PRNG
// ---------------------------------------------------------------------
static inline void rands(int seed){ randseed = m_lo = seed; m_hi = ~seed; }

// ---------------------------------------------------------------------
// get 32 bits of noise
// ---------------------------------------------------------------------
static inline int randi(void) { m_hi = (m_hi<<16) + (m_hi>>16); m_hi += m_lo; m_lo += m_hi; return m_hi; }

// ---------------------------------------------------------------------
// get random float in range [-x..x]
// ---------------------------------------------------------------------
static inline float randf(float x) { return (x * randi() / (float)0x7FFFFFFF); }

float *GenHeightMap(int wide, int deep, int seed)
{
    int i, ni, mi, pmi;
    int j, nj, mj, pmj;
    int w = wide;
    int d = deep;
    float noiseRange = (float)w * 0.5f;
    float r = 0.5;
    float *h = malloc(wide * deep * sizeof(float));
    float *map = calloc(1, wide * deep * sizeof(float) * 6);
    rands(seed);
    h[0] = randf(noiseRange);
    while(w > 0)
    {
    	// diamond midpoint displacement
        for (i = 0; i < wide; i += w)
        {
            for (j = 0; j < deep; j += d)
            {
                ni = (i + w) % wide;
                nj = (j + d) % deep;
                mi = (i + w / 2);
                mj = (j + d / 2);
                h[mi + wide * mj] = 
				(h[i  +  j * wide] + 
				 h[ni +  j * wide] + 
				 h[i  + nj * wide] + 
				 h[ni + nj * wide]) * 0.25f + randf(noiseRange);
            }
        }
        
		// square midpoint displacement
        for (i = 0; i < wide; i += w)
        {
            for (j = 0; j < deep; j += d)
            {
                ni = (i + w) % wide;
                nj = (j + d) % deep;
                mi = (i + w / 2);
                mj = (j + d / 2);
                pmi = (i - w / 2 + wide) % wide;
                pmj = (j - d / 2 + deep) % deep;
                h[mi + j * wide] = 
				(h[i  + j   * wide] + 
				 h[ni + j   * wide] + 
				 h[mi + pmj * wide] + 
				 h[mi + mj  * wide]) * 0.25f + randf(noiseRange);
                h[i + mj * wide] = 
				(h[i   + j  * wide] + 
				 h[i   + nj * wide] + 
				 h[pmi + mj * wide] + 
				 h[mi  + mj * wide]) * 0.25f +  randf(noiseRange);
            }
        }
		
        // fractal recursion
        w >>= 1;
        d >>= 1;
        noiseRange *= r;
    }
    
    // gen positions
    for (j = 0; j < deep; j++)
	{
    	for (i = 0; i < wide; i++)
    	{
    		int i0 = j*wide+i;
    		float h0 = h[i0];
			
    		map[i0*6 + 0] = i*2-wide;
    		map[i0*6 + 1] = j*2-deep;
    		map[i0*6 + 2] = h0;
			
 			// gen normals
 			if (j < deep-1 && i < wide-1)
 			{
 				int ih =  j   *wide+i+1;
 				int iv = (j+1)*wide+i;
 				int id = (j+1)*wide+i+1;
 				float dh, dv;
				
 				// add cross product of first tri
 				dh = h[ih]-h0;
 				dv = h[iv]-h0;
   				map[i0*6 + 3] += dh;
    			map[i0*6 + 4] += dv;
    			map[i0*6 + 5] += 1;
   				map[ih*6 + 3] += dh;
    			map[ih*6 + 4] += dv;
    			map[ih*6 + 5] += 1;
   				map[iv*6 + 3] += dh;
    			map[iv*6 + 4] += dv;
    			map[iv*6 + 5] += 1;
				
 				// add cross product of second tri
 				dh = h[id]-h[iv];
 				dv = h[id]-h[ih];
   				map[id*6 + 3] += dh;
    			map[id*6 + 4] += dv;
    			map[id*6 + 5] += 10;
   				map[ih*6 + 3] += dh;
    			map[ih*6 + 4] += dv;
    			map[ih*6 + 5] += 1;
   				map[iv*6 + 3] += dh;
    			map[iv*6 + 4] += dv;
    			map[iv*6 + 5] += 1;
 			} 
 		}
    }
    free(h);
    return map;
}
