//-------------------------------------------------------------------------
//
//	File: Noise3DTexture.c
//
//  Abstract: Coherent noise function over 3 dimensions
//            Based on the work by Ken Perlin
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
//
//  Copyright (c) Ken Perlin
//
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

#include <cmath>

//-------------------------------------------------------------------------

#include <valarray>

//-------------------------------------------------------------------------

#include "Vector.hpp"

//-------------------------------------------------------------------------

#include "Noise3DTexture.h"

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

static const GLint kMaxB  = 0x100;
static const GLint kN     = 0x1000;
static const GLint kCount = 2 * ( kMaxB + 1 );

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

typedef std::valarray<GLubyte>  GLUByteValArray;

//-------------------------------------------------------------------------

typedef struct
{
	GLint  start;
	GLint  freqBase[2];
} Noise3DBase;

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

static inline GLvoid SCurve(const DPosition3& p, DPosition3& q)
{
	q.x = p.x * p.x * (3.0 - 2.0 * p.x);
	q.y = p.y * p.y * (3.0 - 2.0 * p.y);
	q.z = p.z * p.z * (3.0 - 2.0 * p.z);
} // SCurve

//-------------------------------------------------------------------------

static inline GLdouble LinearInterpolation(const GLdouble t, const GLdouble *a)
{
	return ( a[0] + t * (a[1] - a[0]) );
} // LinearInterpolation

//-------------------------------------------------------------------------

static inline GLvoid SetNoiseFrequency(const GLint frequency, Noise3DBase& noise3DBase)
{
	noise3DBase.start = 1;
	
	noise3DBase.freqBase[0] = frequency;
	noise3DBase.freqBase[1] = noise3DBase.freqBase[0] - 1;
} // SetNoiseFrequency

//-------------------------------------------------------------------------
//
//  Here we're computing
//
//		T(f) = ((rand() % ( 2 * f)) - f) / f; 
//
// where f is the frequency.  Equivalently, we may write
//
//		T(f) = ((rand() % ( 2 * f)) - f) * P(f); 
//
// where P(f) is the period, that is to say,
//
//		P(f) = 1 / f.
//	
//-------------------------------------------------------------------------

static inline GLvoid NormalizedRandomNoise( const GLint *f, const GLdouble p, DVector3& v)
{
	v.x = (GLdouble)( ( rand( ) % f[1] ) - f[0] ) * p;
	v.y = (GLdouble)( ( rand( ) % f[1] ) - f[0] ) * p;
	v.z = (GLdouble)( ( rand( ) % f[1] ) - f[0] ) * p;

	v = v.normalize();
} // NormalizedRandomNoise

//-------------------------------------------------------------------------

static GLvoid InitNoise3D(Noise3DBase& noise3DBase, GLint *iptr, DVector3 *v)
{
	GLint i;
	GLint j;
	GLint k;
	GLint l;
	
	GLint  f[2];
	GLint  fMax = noise3DBase.freqBase[0];
	
	f[0] = fMax;
	f[1] = f[0] << 1; // 2 * frequency
	
	GLdouble p = 1.0 / (GLdouble)f[0]; // period = 1 / frequency
	
	srand(30757);
	
	for (i = 0; i < fMax; i++)
	{
		iptr[i] = i;
		
		NormalizedRandomNoise(f, p, v[i]);
	} // for i

	while (--i)
	{
		k = iptr[i];
		j = rand() % f[0];

		iptr[i] = iptr[j];
		iptr[j] = k;
	} // while

	fMax = f[0] + 2;
	
	for (i = 0; i < fMax; i++)
	{
		l = f[0] + i;
		
		iptr[l] = iptr[i];
		v[l]    = v[i];
	} // for i
} // InitNoise3D

//-------------------------------------------------------------------------

static GLvoid SetupNoise3D( const Noise3DBase& noise3DBase, const GLdouble *v, GLint n[2][3], DPosition3 *r)
{
	GLdouble t;
	
	GLint  s;
	GLint  i;
	GLint  f = noise3DBase.freqBase[1];
	
	for( i = 0; i < 3; i++ )
	{
		t = v[i] + kN;
		s = (GLint)t;
		
		n[0][i] = s & f;
		n[1][i] = (n[0][i]+1) & f;
		
		r[0].V[i] = t - s;
		r[1].V[i] = r[0].V[i] - 1.0;
	} // for i
} // SetupNoise3D

//-------------------------------------------------------------------------

static GLdouble GenerateNoise3D(Noise3DBase& noise3DBase, GLint *iptr, DVector3 *v, GLdouble *w)
{
	GLint  h;
	GLint  i;
	GLint  j;
	GLint  k;
	
	GLdouble  u[2];
	GLdouble  l[2][2];
	
	GLint  m[2][2];
	GLint  n[2][3];
	
	DPosition3  r[2];
	DPosition3  s;
	
	DVector3  t;

	if (noise3DBase.start)
	{
		noise3DBase.start = 0;
		InitNoise3D(noise3DBase, iptr, v);
	} // if

	SetupNoise3D(noise3DBase, w, n, r);
	
	i = iptr[n[0][0]];
	j = iptr[n[1][0]];

	m[0][0] = iptr[i + n[0][1]];
	m[1][0] = iptr[j + n[0][1]];
	m[0][1] = iptr[i + n[1][1]];
	m[1][1] = iptr[j + n[1][1]];

	SCurve(r[0], s);

	for ( i = 0; i < 2; i++ )
	{
		for ( j = 0; j < 2; j++ )
		{
			for ( k = 0; k < 2; k++ )
			{
				t.x = r[k].x;
				t.y = r[j].y;
				t.z = r[i].z;
				
				h = m[k][j] + n[i][2];
				
				u[k] = t * v[h];   // interior dot product
			} // for k
			
			l[0][j] = LinearInterpolation(s.x, u);
		} // for j
		
		l[1][i] = LinearInterpolation(s.y, l[0]);
	} // for i

	return LinearInterpolation(s.z, l[1]);
} // GenerateNoise3D

//-------------------------------------------------------------------------

static GLvoid GetNoise3DTexture(GLint texSize, GLUByteValArray&  noise3DTexArray)
{
	GLubyte *texPtr = &noise3DTexArray[0];
	
	glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	
	glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA8, texSize, texSize, texSize, 0, GL_RGBA, GL_UNSIGNED_BYTE, texPtr);
} // GetNoise3DTexture

//-------------------------------------------------------------------------

static GLvoid NewNoise3DTexture(const GLint noise3DTexSize, GLUByteValArray&  noise3DTexArray)
{
	DVector3   v[kCount];
	GLint      ptr[kCount];

	GLint  iptr           = 0;
	GLint  startFrequency = 4;
	GLint  numOctaves     = 4;
	GLint  frequency      = startFrequency;
	
	GLint  f;
	GLint  i;
	GLint  j;
	GLint  k;
	GLint  inc;

	GLdouble  inci;
	GLdouble  incj;
	GLdouble  inck;
	GLdouble  ni[3];
	GLdouble  wavelengthInv; // wavelength = speed / frequency => Inv(wavelength) = 1 / wavelength = frequency / speed
	
	GLdouble  amplitude  = 0.5;
	GLdouble  texSizeInv = 1.0 / (GLdouble)noise3DTexSize;
	
	Noise3DBase noise3DBase;
	
	for (f = 0, inc = 0; f < numOctaves; ++f, frequency *= 2, ++inc, amplitude *= 0.5)
	{
		SetNoiseFrequency(frequency, noise3DBase);
		
		iptr = 0;
		
		ni[0] = 0;
		ni[1] = 0;
		ni[2] = 0;

		wavelengthInv = (GLdouble)frequency * texSizeInv;
		
		inci = wavelengthInv;
		
		for (i = 0; i < noise3DTexSize; ++i, ni[0] += inci)
		{
			incj = wavelengthInv;
			
			for (j = 0; j < noise3DTexSize; ++j, ni[1] += incj)
			{
				inck = wavelengthInv;
				
				for (k = 0; k < noise3DTexSize; ++k, ni[2] += inck, iptr += 4)
				{
					noise3DTexArray[iptr+inc] = (GLubyte)(((GenerateNoise3D(noise3DBase, ptr, v, ni) + 1.0) * amplitude)  * 128.0);
				} // for k
			} // for j
		} // for i
	} // for f
} // NewNoise3DTexture

//-------------------------------------------------------------------------

GLvoid CreateNoise3D(const GLint noise3DTexSize)
{
	GLuint noise3DTexArraySize = noise3DTexSize * noise3DTexSize * noise3DTexSize * sizeof(GLdouble);

	GLUByteValArray  noise3DTexArray(noise3DTexArraySize);
	
	NewNoise3DTexture(noise3DTexSize, noise3DTexArray);
	GetNoise3DTexture(noise3DTexSize, noise3DTexArray);
} // CreateNoise3D

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
