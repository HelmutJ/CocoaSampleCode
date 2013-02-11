//
// File:       compute_math.cpp
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////


#include "compute_math.h"
#include "memory.h"

////////////////////////////////////////////////////////////////////////////////

float
radians(float fDegrees)
{
    return (fDegrees * CL_SDK_DEG_TO_RAD_F32);
}

float
degrees(float fRadians)
{
    return (fRadians * CL_SDK_RAD_TO_DEG_F32);
}

////////////////////////////////////////////////////////////////////////////////

float
min(float a, float b)
{
    return (a < b) ? a : b;
}

float
max(float a, float b)
{
    return (a > b) ? a : b;
}

float
clamp(float c, float a, float b)
{
    if (c < a) c = a;
    if (c > b) c = b;
    else c = c;
    return c;
}


float 
fast_sqrt(float r) 
{
	float x,y;
	float v = r;
	uint *up = ((uint *)&v)+1;

	(*up) = (0xbfcd4600-(*up))>>1;
	x=v;
	y=r*0.5f; 
	x*=1.5f-x*x*y; 
	x*=1.5f-x*x*y;
	x*=1.5f-x*x*y; 
	x*=1.5f-x*x*y; 
	return x*r;
}

float 
fast_rsqrt(float v)
{
    float h = 0.5f * v;
    int i = *(int*)&v;
    i = 0x5f3759df - (i >> 1);
    v = *(float*)&i;
    v = v*(1.5f - h * v * v);
    return v;
}

////////////////////////////////////////////////////////////////////////////////

int
clamp(int c, int a, int b)
{
    if (c < a) c = a;
    if (c > b) c = b;
    else c = c;
    return c;
}

int
max(int a, int b)
{
    return (a > b) ? a : b;
}

int
min(int a, int b)
{
    return (a < b) ? a : b;
}

////////////////////////////////////////////////////////////////////////////////

uint
max(uint a, uint b)
{
    return (a > b) ? a : b;
}

uint
min(uint a, uint b)
{
    return (a < b) ? a : b;
}

////////////////////////////////////////////////////////////////////////////////

uint
nearest_power_of_two(uint x)
{
    int i, k;

    k = x;
    i = -1;
    while (k != 0)
    {
        k >>= 1;
        i++;
    }
    return 1 << (i + ((x >> (i - 1)) & 1));
}

uint
next_power_of_two(uint x)
{
    x = x - 1;
    x = x | ( x >> 1 );
    x = x | ( x >> 2 );
    x = x | ( x >> 4 );
    x = x | ( x >> 8 );
    x = x | ( x >> 16 );
    return x + 1;
}

int 
dilate_even(const int x)
{
	int u = ((x & 0x0000ff00) << 8) | (x & 0x000000ff);
	int v = ((u & 0x00f000f0) << 4) | (u & 0x000f000f);
	int w = ((v & 0x0c0c0c0c) << 2) | (v & 0x03030303);
	int r = ((w & 0x22222222) << 1) | (w & 0x11111111);
	return r;
}

int
dilate_odd(const int x)
{
    return (dilate_even(x) << 1);
}

int
morton_index2d(
    const int row, const int col)
{
    return (dilate_even(row) | dilate_odd(col));
}

int
morton_index2d_padded(
    const int row, const int col, const int size)
{
    return ((row < size) ? ((col < size) ? morton_index2d(row, col) : (size) * (size) + row) : (size) * (size + 1) + col);
}

////////////////////////////////////////////////////////////////////////////

int 
divide_up(int a, int b) 
{
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

////////////////////////////////////////////////////////////////////////////////
    
float
distance(const float2 &rkVA, const float2 &rkVB)
{
    float fDX = (rkVA.x - rkVB.x) * (rkVA.x - rkVB.x);
    float fDY = (rkVA.y - rkVB.y) * (rkVA.y - rkVB.y);
    return sqrtf(fDX + fDY);
}

float2
fast_normalize(
    const float2& rkV)
{
	float fInv = fast_rsqrt(rkV.x * rkV.x + rkV.y * rkV.y);
    return (rkV * fInv);
}

float2
normalize(
    const float2& rkV, float fZeroEpsilon)
{
    float fL = length(rkV);
    if (fL > fZeroEpsilon)
    {
        float fS = 1.0f / fL;
        return (rkV * fS);
    }

    return make_float2(0.0f, 0.0f);
}

float
dot(const float2 &rkVA, const float2 &rkVB)
{
    return (rkVA.x * rkVB.x +
            rkVA.y * rkVB.y);
}

float2
mix(const float2 &rkVA, const float2 &rkVB, float fT)
{
    return (rkVA * (1.0f - fT) + rkVB * fT);
}

float2
min(const float2 &rkVA, const float2 &rkVB)
{
    float2 kRV;
    kRV.x = fmin(rkVA.x, rkVB.x);
    kRV.y = fmin(rkVA.y, rkVB.y);
    return kRV;
}

float2
max(const float2 &rkVA, const float2 &rkVB)
{
    float2 kRV;
    kRV.x = fmax(rkVA.x, rkVB.x);
    kRV.y = fmax(rkVA.y, rkVB.y);
    return kRV;
}

float2
clamp(const float2 &rkV, float fMin, float fMax)
{
    float2 kRV;
    kRV.x = clamp(rkV.x, fMin, fMax);
    kRV.y = clamp(rkV.y, fMin, fMax);
    return kRV;
}

float2
floor(const float2 &rkV)
{
	return make_float2(floorf(rkV.x), floorf(rkV.y));
}

float
length(const float2 &rkV)
{
    return sqrtf(rkV.x * rkV.x +
                 rkV.y * rkV.y);
}

////////////////////////////////////////////////////////////////////////////////

float3
fast_normalize(
    const float3& rkV)
{
	float fInv = fast_rsqrt(rkV.x * rkV.x + rkV.y * rkV.y + rkV.z * rkV.z);
    return (rkV * fInv);
}

float3
normalize(
    const float3& rkV, float fZeroEpsilon)
{
    float fL = length(rkV);
    if (fL > fZeroEpsilon)
    {
        float fS = 1.0f / fL;
        return (rkV * fS);
    }

    return make_float3(0.0f, 0.0f, 0.0f);
}

float
dot(const float3 &rkVA, const float3 &rkVB)
{
    return (rkVA.x * rkVB.x +
            rkVA.y * rkVB.y +
            rkVA.z * rkVB.z);
}

float3
cross(const float3 &rkVA, const float3 &rkVB)
{
    return make_float3(
               rkVA.y*rkVB.z - rkVA.z*rkVB.y,
               rkVA.z*rkVB.x - rkVA.x*rkVB.z,
               rkVA.x*rkVB.y - rkVA.y*rkVB.x);
}

float
length(const float3 &rkV)
{
    return sqrtf(rkV.x * rkV.x +
                 rkV.y * rkV.y +
                 rkV.z * rkV.z);
}

float
distance(const float3 &rkVA, const float3 &rkVB)
{
    return length(rkVA - rkVB);
}

float3
mix(const float3 &rkVA, const float3 &rkVB, float fT)
{
    return (rkVA * (1.0f - fT) + rkVB * fT);
}

float3
min(const float3 &rkVA, const float3 &rkVB)
{
    float3 kRV;
    kRV.x = fmin(rkVA.x, rkVB.x);
    kRV.y = fmin(rkVA.y, rkVB.y);
    kRV.z = fmin(rkVA.z, rkVB.z);
    return kRV;
}

float3
max(const float3 &rkVA, const float3 &rkVB)
{
    float3 kRV;
    kRV.x = fmax(rkVA.x, rkVB.x);
    kRV.y = fmax(rkVA.y, rkVB.y);
    kRV.z = fmax(rkVA.z, rkVB.z);
    return kRV;
}

float3
clamp(const float3 &rkV, float fMin, float fMax)
{
    float3 kRV;
    kRV.x = clamp(rkV.x, fMin, fMax);
    kRV.y = clamp(rkV.y, fMin, fMax);
    kRV.z = clamp(rkV.z, fMin, fMax);
    return kRV;
}

float3
floor(const float3 &rkV)
{
	return make_float3(floorf(rkV.x), floorf(rkV.y), floorf(rkV.z));
}

////////////////////////////////////////////////////////////////////////////////

float4
fast_normalize(
    const float4& rkV)
{
	float fInv = fast_rsqrt(rkV.x * rkV.x + rkV.y * rkV.y + rkV.z * rkV.z + rkV.w * rkV.w);
    return (rkV * fInv);
}


float4
normalize(const float4& rkV, float fZeroEpsilon)
{
    float fL = length(rkV);

    if (fL > fZeroEpsilon)
    {
        float fS = 1.0f / fL;
        return (rkV * fS);
    }

    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
}

float
dot(const float4 &rkVA, const float4 &rkVB)
{
#ifdef CL_SDK_USE_SSE
	float4 kRV;
	kRV = _mm_mul_ps (rkVA.vector, rkVB.vector);
	kRV = _mm_add_ss (kRV, _mm_add_ss (_mm_shuffle_ps (kRV, kRV, 1), 
					       _mm_add_ss (_mm_shuffle_ps (kRV, kRV, 2),
							 		   _mm_shuffle_ps (kRV, kRV, 3))));
	return (kRV[0]);

#else
    return (rkVA.x * rkVB.x +
            rkVA.y * rkVB.y +
            rkVA.z * rkVB.z +
            rkVA.w * rkVB.w);
#endif
}

float
length(const float4 &rkV)
{
    return sqrtf(dot(rkV, rkV));
}

float
distance(const float4 &rkVA, const float4 &rkVB)
{
    return length(rkVA - rkVB);
}

float4
mix(const float4 &rkVA, const float4 &rkVB, float fT)
{
    return (rkVA * (1.0f - fT) + rkVB * fT);
}

float4
min(const float4 &rkVA, const float4 &rkVB)
{
#ifdef CL_SDK_USE_SSE
    return (_mm_min_ps(rkVA.vector, rkVB.vector));
#else
    float4 kRV;
    kRV.x = fmin(rkVA.x, rkVB.x);
    kRV.y = fmin(rkVA.y, rkVB.y);
    kRV.z = fmin(rkVA.z, rkVB.z);
    kRV.w = fmin(rkVA.w, rkVB.w);
    return kRV;
#endif
}

float4
max(const float4 &rkVA, const float4 &rkVB)
{
#ifdef CL_SDK_USE_SSE
    return (_mm_max_ps(rkVA.vector, rkVB.vector));
#else
    float4 kRV;
    kRV.x = fmax(rkVA.x, rkVB.x);
    kRV.y = fmax(rkVA.y, rkVB.y);
    kRV.z = fmax(rkVA.z, rkVB.z);
    kRV.w = fmax(rkVA.w, rkVB.w);
    return kRV;
#endif
}

float4
floor(const float4 &rkV)
{
	return make_float4(floorf(rkV.x), floorf(rkV.y), floorf(rkV.z), floorf(rkV.w));
}

////////////////////////////////////////////////////////////////////////////////


float16
inverse(const float16 &rkSrc, float fEpsilon)
{
    if (rkSrc.isIdentity())
        return rkSrc;

    float16 kDst;

    // affine
    if (rkSrc.rows[0][3] == 0.0f && rkSrc.rows[1][3] == 0.0f &&
        rkSrc.rows[2][3] == 0.0f && rkSrc.rows[3][3] == 1.0f)
    {
        float fDeterminant;
        float fPos, fNeg, fTmp;

        fPos = fNeg = 0.0f;

        fTmp = +rkSrc.rows[0][0] * rkSrc.rows[1][1] * rkSrc.rows[2][2];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fTmp = +rkSrc.rows[0][1] * rkSrc.rows[1][2] * rkSrc.rows[2][0];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fTmp = +rkSrc.rows[0][2] * rkSrc.rows[1][0] * rkSrc.rows[2][1];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fTmp = -rkSrc.rows[0][2] * rkSrc.rows[1][1] * rkSrc.rows[2][0];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fTmp = -rkSrc.rows[0][1] * rkSrc.rows[1][0] * rkSrc.rows[2][2];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fTmp = -rkSrc.rows[0][0] * rkSrc.rows[1][2] * rkSrc.rows[2][1];
        (fTmp >= 0.0f) ? (fPos += fTmp) : (fNeg += fTmp);

        fDeterminant = fPos + fNeg;

        if ((fDeterminant == 0.0f) || (fabs(fDeterminant / (fPos - fNeg)) < fEpsilon))
        {
            return rkSrc;
        }
        else
        {
            fDeterminant = 1.0f / fDeterminant;
            kDst.rows[0][0] = +(rkSrc.rows[1][1] * rkSrc.rows[2][2] -
                                rkSrc.rows[1][2] * rkSrc.rows[2][1]) * fDeterminant;
            kDst.rows[1][0] = -(rkSrc.rows[1][0] * rkSrc.rows[2][2] -
                                rkSrc.rows[1][2] * rkSrc.rows[2][0]) * fDeterminant;
            kDst.rows[2][0] = +(rkSrc.rows[1][0] * rkSrc.rows[2][1] -
                                rkSrc.rows[1][1] * rkSrc.rows[2][0]) * fDeterminant;
            kDst.rows[0][1] = -(rkSrc.rows[0][1] * rkSrc.rows[2][2] -
                                rkSrc.rows[0][2] * rkSrc.rows[2][1]) * fDeterminant;
            kDst.rows[1][1] = +(rkSrc.rows[0][0] * rkSrc.rows[2][2] -
                                rkSrc.rows[0][2] * rkSrc.rows[2][0]) * fDeterminant;
            kDst.rows[2][1] = -(rkSrc.rows[0][0] * rkSrc.rows[2][1] -
                                rkSrc.rows[0][1] * rkSrc.rows[2][0]) * fDeterminant;
            kDst.rows[0][2] = +(rkSrc.rows[0][1] * rkSrc.rows[1][2] -
                                rkSrc.rows[0][2] * rkSrc.rows[1][1]) * fDeterminant;
            kDst.rows[1][2] = -(rkSrc.rows[0][0] * rkSrc.rows[1][2] -
                                rkSrc.rows[0][2] * rkSrc.rows[1][0]) * fDeterminant;
            kDst.rows[2][2] = +(rkSrc.rows[0][0] * rkSrc.rows[1][1] -
                                rkSrc.rows[0][1] * rkSrc.rows[1][0]) * fDeterminant;
            kDst.rows[3][0] = -(rkSrc.rows[3][0] * kDst.rows[0][0] +
                                rkSrc.rows[3][1] * kDst.rows[1][0] +
                                rkSrc.rows[3][2] * kDst.rows[2][0]);
            kDst.rows[3][1] = -(rkSrc.rows[3][0] * kDst.rows[0][1] +
                                rkSrc.rows[3][1] * kDst.rows[1][1] +
                                rkSrc.rows[3][2] * kDst.rows[2][1]);
            kDst.rows[3][2] = -(rkSrc.rows[3][0] * kDst.rows[0][2] +
                                rkSrc.rows[3][1] * kDst.rows[1][2] +
                                rkSrc.rows[3][2] * kDst.rows[2][2]);

            kDst.rows[0][3] = kDst.rows[1][3] = kDst.rows[2][3] = 0.0f;
            kDst.rows[3][3] = 1.0f;
        }
    }
    else
    {
        float fMax, fSum, fTmp, fInvPivot;
        int afP[4];
        int i, j, k;

        kDst = rkSrc;

        for (k = 0; k < 4; k++)
        {
            fMax = 0.0f;
            afP[k] = 0;

            for (i = k; i < 4; i++)
            {
                fSum = 0.0f;
                for (j = k; j < 4; j++)
                    fSum += fabs(kDst.rows[i][j]);
                
                if (fSum > 0.0f)
                {
                    fTmp = fabs(kDst.rows[i][k]) / fSum;
                    if (fTmp > fMax)
                    {
                        fMax = fTmp;
                        afP[k] = i;
                    }
                }
            }

            if (fMax == 0.0f)
            {
                
                return rkSrc;
            }

            if (afP[k] != k)
            {
                for (j = 0; j < 4; j++)
                {
                    fTmp = kDst.rows[k][j];
                    kDst.rows[k][j] = kDst.rows[afP[k]][j];
                    kDst.rows[afP[k]][j] = fTmp;
                }
            }

            fInvPivot = 1.0f / kDst.rows[k][k];
            for (j = 0; j < 4; j++)
            {
                if (j != k)
                {
                    kDst.rows[k][j] = - kDst.rows[k][j] * fInvPivot;
                    for (i = 0; i < 4; i++)
                    {
                        if (i != k) kDst.rows[i][j] += kDst.rows[i][k] * kDst.rows[k][j];
                    }
                }
            }

            for (i = 0; i < 4; i++) kDst.rows[i][k] *= fInvPivot;
            kDst.rows[k][k] = fInvPivot;
        }

        for (k = 2; k >= 0; k--)
        {
            if (afP[k] != k)
            {
                for (i = 0; i < 4; i++)
                {
                    fTmp = kDst.rows[i][k];
                    kDst.rows[i][k] = kDst.rows[i][afP[k]];
                    kDst.rows[i][afP[k]] = fTmp;
                }
            }
        }
    }
    return kDst;
}

float16
transpose(const float16 &rkM)
{
    return make_float16(
        rkM.getColumn(0),
        rkM.getColumn(1),
        rkM.getColumn(2),
        rkM.getColumn(3));
}

float16
translation(
    const float3 &rkV)
{
    float16 kM;
    kM.rows[0][0] = 1.0f; kM.rows[1][0] = 0.0f; kM.rows[2][0] = 0.0f; kM.rows[3][0] = rkV.x;
    kM.rows[0][1] = 0.0f; kM.rows[1][1] = 1.0f; kM.rows[2][1] = 0.0f; kM.rows[3][1] = rkV.y;
    kM.rows[0][2] = 0.0f; kM.rows[1][2] = 0.0f; kM.rows[2][2] = 1.0f; kM.rows[3][2] = rkV.z;
    kM.rows[0][3] = 0.0f; kM.rows[1][3] = 0.0f; kM.rows[2][3] = 0.0f; kM.rows[3][3] = 1.0f;
    return kM;
}

float16
scaling(
    const float3 &rkV)
{
    float16 kM;
    kM.rows[0][0] = rkV.x; kM.rows[1][0] =  0.0f; kM.rows[2][0] =  0.0f; kM.rows[3][0] = 0.0f;
    kM.rows[0][1] =  0.0f; kM.rows[1][1] = rkV.y; kM.rows[2][1] =  0.0f; kM.rows[3][1] = 0.0f;
    kM.rows[0][2] =  0.0f; kM.rows[1][2] =  0.0f; kM.rows[2][2] = rkV.z; kM.rows[3][2] = 0.0f;
    kM.rows[0][3] =  0.0f; kM.rows[1][3] =  0.0f; kM.rows[2][3] =  0.0f; kM.rows[3][3] = 1.0f;
    return kM;
}

float16
rotation(
    const float3 &rkAxis,
    float fRadians)
{
    float16 kM;
    float fSin = sinf( fRadians );
    float fCos = cosf( fRadians );
    float fOneMinusCos = (1.0f - fCos);
    
    float3 kA = normalize(rkAxis);
    
    kM.rows[0][0] = fCos + fOneMinusCos * kA.x;
    kM.rows[0][1] = fOneMinusCos * kA.x * kA.y + fSin * kA.z;
    kM.rows[0][2] = fOneMinusCos * kA.x * kA.z - fSin * kA.y;
    kM.rows[0][3] = 0.0f;
    
    kM.rows[1][0] = fOneMinusCos * kA.y * kA.x - fSin * kA.z;
    kM.rows[1][1] = fCos + fOneMinusCos * (kA.y * kA.y);
    kM.rows[1][2] = fOneMinusCos * kA.y * kA.z + fSin * kA.x;
    kM.rows[1][3] = 0.0f;
    
    kM.rows[2][0] = fOneMinusCos * kA.z * kA.x + fSin * kA.y;
    kM.rows[2][1] = fOneMinusCos * kA.z * kA.z - fSin * kA.x;
    kM.rows[2][2] = fCos + fOneMinusCos * (kA.z * kA.z);
    kM.rows[2][3] = 0.0f;
    
    kM.rows[3][0] = 0.0f;
    kM.rows[3][1] = 0.0f;
    kM.rows[3][2] = 0.0f;
    kM.rows[3][3] = 1.0f;
    
    return kM;
}

float16 
ortho(
    float fLeft, float fRight, 
    float fBottom, float fTop, 
    float fNear, float fFar)
{
    float16 kM;
    
    float fRL = (fRight - fLeft);
    float fTB = (fTop - fBottom);
    float fFN = (fFar - fNear);

	kM.rows[0][0] = +2.0f / fRL;
	kM.rows[1][0] = +0.0f;
	kM.rows[2][0] = +0.0f;
	kM.rows[3][0] = -(fRight + fLeft) / fRL;

	kM.rows[0][1] = +0.0f;
	kM.rows[1][1] = +2.0f / fTB;
	kM.rows[2][1] = +0.0f;
	kM.rows[3][1] = -(fTop + fBottom) / fTB;

	kM.rows[0][2] = +0.0f;
	kM.rows[1][2] = +0.0f;
	kM.rows[2][2] = -2.0f / fFN;
	kM.rows[3][2] = -(fFar + fNear) / fFN;

	kM.rows[0][3] = +0.0f;
	kM.rows[1][3] = +0.0f;
	kM.rows[2][3] = +0.0f;
	kM.rows[3][3] = +1.0f;
    return kM;
}

float16
perspective(
    float fFovInRadians, float fAspect, 
    float fNear, float fFar) 
{
    float fY = tanf(fFovInRadians * 0.5f);
    float fX = fY * fAspect;
    
    float16 kM;
    kM.rows[0][0] = +1.0f / fX; 
    kM.rows[1][0] = +0.0f; 
    kM.rows[2][0] = +0.0f; 
    kM.rows[3][0] = +0.0f;
    
    kM.rows[0][1] = +0.0f; 
    kM.rows[1][1] = +1.0f / fY; 
    kM.rows[2][1] = +0.0f; 
    kM.rows[3][1] = +0.0f;
    
    kM.rows[0][2] = +0.0f; 
    kM.rows[1][2] = +0.0f; 
    kM.rows[2][2] = -(fFar + fNear) / (fFar - fNear); 
    kM.rows[3][2] = -(2.0f * fFar * fNear) / (fFar - fNear);

    kM.rows[0][3] = +0.0f; 
    kM.rows[1][3] = +0.0f; 
    kM.rows[2][3] = -1.0f; 
    kM.rows[3][3] = +0.0f;
    return kM;
}

float16 
perspective(
    float fLeft, float fRight, 
    float fBottom, float fTop, 
    float fNear, float fFar, 
    bool bInfinite)
{
    float16 kM;
    
    float fRL = (fRight - fLeft);
    float fTB = (fTop - fBottom);
    float fFN = (fFar - fNear);

	kM.rows[0][0] = (2.0f * fNear) / fRL;
	kM.rows[2][0] = (fRight + fLeft) / fRL;

	kM.rows[1][1] = (2.0f * fNear) / fTB;
	kM.rows[2][1] = (fTop + fBottom) / fTB;
	
	if ( bInfinite )
	{
		static const float fOffset = (1.0 - (1.0 / double(1<<22)));

        kM.rows[2][2] = -1.0f * fOffset;
        kM.rows[3][2] = -2.0f * fNear * fOffset;
	}
	else
    {
        kM.rows[2][2] = -(fFar + fNear) / fFN;
        kM.rows[3][2] = -(2.0f * fFar * fNear) / fFN;
	}

	kM.rows[2][3] = -1.0f;
	kM.rows[3][3] = +0.0f;
    return kM;

}
    
float16 
look(
    const float3 &rkPosition,
    const float3 &rkViewDirection,
    const float3 &rkUpDirection)
{
	float3 kZ = normalize(rkPosition - rkViewDirection);
	float3 kX = normalize(cross(rkUpDirection, kZ));
	float3 kY = normalize(cross(kZ, kX));

    float4 kR0 = make_float4(kX.x, kY.x, kZ.x, 0.0f);
    float4 kR1 = make_float4(kX.y, kY.y, kZ.y, 0.0f);
    float4 kR2 = make_float4(kX.z, kY.z, kZ.z, 0.0f);
    float4 kR3 = make_float4(0.0f, 0.0f, 0.0f, 1.0f);
    
    float16 kM = make_float16(kR0, kR1, kR2, kR3);
    kM = translation( -rkPosition ) * kM;
	return kM;
}

float16 
lookat(
    const float3 &rkPosition,
    const float3 &rkTarget,
    const float3 &rkUpDirection)
{
    return look(rkPosition, normalize(rkTarget - rkPosition), rkUpDirection);
}

