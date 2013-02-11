//
// File:       compute_types.h
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

#ifndef __COMPUTE_TYPES__
#define __COMPUTE_TYPES__

#include <math.h>
#include <memory.h>
#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <limits.h>

#define CL_SDK_USE_SSE
#ifdef CL_SDK_USE_SSE
#include <xmmintrin.h>
#endif

////////////////////////////////////////////////////////////////////////////////

typedef unsigned int uint;
typedef unsigned char uchar;

#define make_float2 float2
#define make_float3 float3
#define make_float4 float4
#define make_float16 float16

#define make_int2 int2
#define make_int3 int3
#define make_int4 int4

#define make_uint2 uint2
#define make_uint3 uint3
#define make_uint4 uint4

////////////////////////////////////////////////////////////////////////////////


struct float2
{
	float2(void)
	{
        // EMPTY!
	}
	
    float2(const float2 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
    }
    
	float2 (float fC0, float fC1)
    { 
        columns[0] = fC0;
        columns[1] = fC1;
    }

    float &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 2);
        return (columns[iColumn]);
	}

    float operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 2);
        return (columns[iColumn]);
	}

	float2 &operator= (const float2 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        return (*this); 
    }

    bool operator== (const float2 &rkR) const
    {
        return (x == rkR.x && y == rkR.y);
    }

    bool operator!= (const float2 &rkR) const
    {
        return (x != rkR.x || y != rkR.y);
    }

	friend float2 operator+ (const float2 &rkL, const float2 &rkR) 
    { 
        return float2(rkL.x + rkR.x, 
                      rkL.y + rkR.y);        
    }

	float2 &operator+= (const float2 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        return (*this); 
    }

	friend float2 operator- (const float2 &rkL, const float2 &rkR) 
    { 
        return float2(rkL.x - rkR.x, 
                      rkL.y - rkR.y);        
    } 

	float2 &operator-= (const float2 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        return (*this);
    }  
    
	friend float2 operator* (const float2 &rkL, const float2 &rkR) 
    { 
        return float2(rkL.x * rkR.x, 
                      rkL.y * rkR.y);        
    } 

	friend float2 operator* (const float2 &rkL, float fR)
    {
        return float2(rkL.x * fR, 
                      rkL.y * fR);        
    }

    friend float2 operator* (float fL, const float2 &rkR)
    {
        return float2(fL * rkR.x, 
                      fL * rkR.y);        
    }

	float2 &operator*= (const float2 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        return (*this);
    }

    float2 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        return (*this);
    }

	friend float2 operator/ (const float2 &rkL, const float2 &rkR) 
    { 
        return float2(rkL.x / rkR.x, 
                      rkL.y / rkR.y);        
    }

    friend float2 operator/ (const float2 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return float2(rkL.x * fInv, 
                      rkL.y * fInv);        
    }

	float2 &operator/= (const float2 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        return (*this);
    }

    float2 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        return (*this);
    }

    float2 operator - ( void ) const
    {
        return float2( -x, -y );
    }

    union
    {
        float columns[2];

        struct
        {
            float x;
            float y;
        };

        struct
        {
            float r;
            float b;
        };

        struct
        {
            float s;
            float t;
        };

        struct
        {
            float u;
            float v;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct float3
{
	float3()
	{
        // EMPTY!
	}
	
    float3(const float3 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
    }
    
	float3 (float fC0, float fC1, float fC2)
    { 
        columns[0] = fC0;
        columns[1] = fC1;
        columns[2] = fC2;
    }

    float &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 3);
        return (columns[iColumn]);
	}

    float operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 3);
        return (columns[iColumn]);
	}

	float3 &operator= (const float3 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        return (*this); 
    }

    bool operator== (const float3 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z);
    }

    bool operator!= (const float3 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z);
    }

	friend float3 operator+ (const float3 &rkL, const float3 &rkR) 
    { 
        return float3(rkL.x + rkR.x, 
                      rkL.y + rkR.y, 
                      rkL.z + rkR.z);        
    }

	float3 &operator+= (const float3 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        return (*this); 
    }

	friend float3 operator- (const float3 &rkL, const float3 &rkR) 
    { 
        return float3(rkL.x - rkR.x, 
                      rkL.y - rkR.y, 
                      rkL.z - rkR.z);        
    } 

	float3 &operator-= (const float3 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        return (*this);
    }  
    
	friend float3 operator* (const float3 &rkL, const float3 &rkR) 
    { 
        return float3(rkL.x * rkR.x, 
                      rkL.y * rkR.y, 
                      rkL.z * rkR.z);        
    } 

	friend float3 operator* (const float3 &rkL, float fR)
    {
        return float3(rkL.x * fR, 
                      rkL.y * fR, 
                      rkL.z * fR);        
    }

    friend float3 operator* (float fL, const float3 &rkR)
    {
        return float3(fL * rkR.x, 
                      fL * rkR.y, 
                      fL * rkR.z);        
    }

	float3 &operator*= (const float3 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        return (*this);
    }

    float3 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        return (*this);
    }

	friend float3 operator/ (const float3 &rkL, const float3 &rkR) 
    { 
        return float3(rkL.x / rkR.x, 
                      rkL.y / rkR.y, 
                      rkL.z / rkR.z);        
    }

    friend float3 operator/ (const float3 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return float3(rkL.x * fInv, 
                      rkL.y * fInv, 
                      rkL.z * fInv);        
    }

	float3 &operator/= (const float3 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        return (*this);
    }

    float3 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        return (*this);
    }

    float3 operator - ( void ) const
    {
        return float3( -x, -y, -z );
    }

    union
    {
        float columns[3];

        struct
        {
            float x;
            float y;
            float z;
        };

        struct
        {
            float r;
            float b;
            float g;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct float4;

float
dot(const float4 &rkA, const float4 &rkB);

////////////////////////////////////////////////////////////////////////////////

struct float4
{
	float4 ()
	{
        // EMPTY!
	}
	
    float4 (const float4 &rkOther)
    {
#ifdef CL_SDK_USE_SSE
        vector = rkOther.vector;
#else
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = rkOther.w;
#endif
    }
	
    float4(const float3 &rkOther, float fW = 0.0f)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = fW;
    }

#ifdef CL_SDK_USE_SSE
	float4 (__m128 kVector)
    { 
        vector = kVector;
        return;
    }
#endif

	float4 (float fC0, float fC1, float fC2, float fC3)
    { 
#ifdef CL_SDK_USE_SSE
        vector = _mm_setr_ps (fC0, fC1, fC2, fC3);
#else
        columns[0] = fC0;
        columns[1] = fC1;
        columns[2] = fC2;
        columns[3] = fC3;
#endif
        return;
    }

#ifdef CL_SDK_USE_SSE
	operator __m128()
    { 
        return (vector);
    }
#endif

    operator float*()
    {
        return columns;
    }

    operator const float*() const
    {
        return columns;
    }

    float &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 4);
        return (columns[iColumn]);
	}

    float operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 4);
        return (columns[iColumn]);
	}

	float4 &operator= (const float4 &rkOther)
    { 
#ifdef CL_SDK_USE_SSE
        vector = rkOther.vector;
#else
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        columns[3] = rkOther.columns[3];
#endif
        return (*this); 
    }

#ifdef CL_SDK_USE_SSE
	float4 &operator= (const __m128 rkOther) 
    { 
        vector = rkOther;
        return (*this);
    }
#endif

    bool operator== (const float4 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z && w == rkR.w);
    }

    bool operator!= (const float4 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z || w != rkR.w);
    }

	friend float4 operator+ (const float4 &rkL, const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        return (_mm_add_ps (rkL.vector, rkR.vector)); 
#else
        return float4(rkL.x + rkR.x, 
                      rkL.y + rkR.y, 
                      rkL.z + rkR.z, 
                      rkL.w + rkR.w);        
#endif
    }

	float4 &operator+= (const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        vector = _mm_add_ps (vector, rkR.vector);
#else
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        w += rkR.w;
#endif
        return (*this); 
    }

	friend float4 operator- (const float4 &rkL, const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        return (_mm_sub_ps (rkL.vector, rkR.vector)); 
#else
        return float4(rkL.x - rkR.x, 
                      rkL.y - rkR.y, 
                      rkL.z - rkR.z, 
                      rkL.w - rkR.w);        
#endif
    } 

	float4 &operator-= (const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        vector = _mm_sub_ps (vector, rkR.vector);
#else
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        w -= rkR.w;
#endif
        return (*this);
    }  
    
	friend float4 operator* (const float4 &rkL, const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        return (_mm_mul_ps (rkL.vector , rkR.vector)); 
#else
        return float4(rkL.x * rkR.x, 
                      rkL.y * rkR.y, 
                      rkL.z * rkR.z, 
                      rkL.w * rkR.w);        
#endif
    } 

	friend float4 operator* (const float4 &rkL, float fR)
    {
#ifdef CL_SDK_USE_SSE
        return (_mm_mul_ps (rkL.vector, _mm_set_ps1 (fR)));
#else
        return float4(rkL.x * fR, 
                      rkL.y * fR, 
                      rkL.z * fR, 
                      rkL.w * fR);        
#endif
    }

    friend float4 operator* (float fL, const float4 &rkR)
    {
#ifdef CL_SDK_USE_SSE
        return (_mm_mul_ps (_mm_set_ps1 (fL), rkR.vector));
#else
        return float4(fL * rkR.x, 
                      fL * rkR.y, 
                      fL * rkR.z, 
                      fL * rkR.w);        
#endif
    }

	float4 &operator*= (const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        vector = _mm_mul_ps (vector, rkR.vector); 
#else
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        w *= rkR.w;
#endif
        return (*this);
    }

    float4 &operator*= (float fR)
    {
#ifdef CL_SDK_USE_SSE
        vector = _mm_mul_ps (vector, _mm_set_ps1 (fR));
#else
        x *= fR;
        y *= fR;
        z *= fR;
        w *= fR;
#endif
        return (*this);
    }

	friend  float4 operator/ (const float4 &rkL, const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        return (_mm_div_ps (rkL.vector, rkR.vector)); 
#else
        return float4(rkL.x / rkR.x, 
                      rkL.y / rkR.y, 
                      rkL.z / rkR.z, 
                      rkL.w / rkR.w);        
#endif
    }

    friend  float4 operator/ (const float4 &rkL, float fR)
    {
#ifdef CL_SDK_USE_SSE
        return (_mm_div_ps (rkL.vector, _mm_set_ps1 (fR)));
#else
        float fInv = 1.0f / fR;
        return float4(rkL.x * fInv, 
                      rkL.y * fInv, 
                      rkL.z * fInv, 
                      rkL.w * fInv);        
#endif
    }

	float4 &operator/= (const float4 &rkR) 
    { 
#ifdef CL_SDK_USE_SSE
        vector = _mm_div_ps (vector, rkR.vector); 
#else
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        w /= rkR.w;
#endif
        return (*this);
    }

    float4 &operator/= (float fR)
    {
#ifdef CL_SDK_USE_SSE
        vector = _mm_div_ps (vector, _mm_set_ps1 (fR));
#else
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        w *= fInv;
#endif
        return (*this);
    }

    float4 operator - ( void ) const
    {
#ifdef CL_SDK_USE_SSE
        static const float4 s_kZero = float4(0.0f, 0.0f, 0.0f, 0.0f);
        return (_mm_sub_ps(s_kZero.vector, vector));
#else
        return float4( -x, -y, -z, -w );
#endif
    }

    union
    {
#ifdef CL_SDK_USE_SSE
        __m128 vector;
#endif
        float columns[4];

        struct
        {
            float x;
            float y;
            float z;
            float w;
        };

        struct
        {
            float r;
            float b;
            float g;
            float a;
        };

        struct
        {
            float s;
            float t;
            float u;
            float v;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct float16
{
    float16()
    {
        identity();
    }

    float16( float afM[16] )
    {
        this->rows[0] = make_float4(afM[ 0], afM[ 1], afM[ 2], afM[ 3]);
        this->rows[1] = make_float4(afM[ 4], afM[ 5], afM[ 6], afM[ 7]);
        this->rows[2] = make_float4(afM[ 8], afM[ 9], afM[10], afM[11]);
        this->rows[3] = make_float4(afM[12], afM[13], afM[14], afM[15]);
    }

    float16(
        const float4 &rkRow0,
        const float4 &rkRow1,
        const float4 &rkRow2,
        const float4 &rkRow3)
    {
        this->rows[0] = rkRow0;
        this->rows[1] = rkRow1;
        this->rows[2] = rkRow2;
        this->rows[3] = rkRow3;
    }
    
    float16(
        float f00, float f01, float f02, float f03,
        float f04, float f05, float f06, float f07,
        float f08, float f09, float f10, float f11,
        float f12, float f13, float f14, float f15)
    {
        this->rows[0] = make_float4(f00, f01, f02, f03);
        this->rows[1] = make_float4(f04, f05, f06, f07);
        this->rows[2] = make_float4(f08, f09, f10, f11);
        this->rows[3] = make_float4(f12, f13, f14, f15);
    }

    float4 getRow(uint uiIndex) const
    {
        assert(uiIndex >= 0 && uiIndex < 4);
        return this->rows[uiIndex];
        
    }

    float4 getColumn(uint uiIndex) const
    {
        assert(uiIndex >= 0 && uiIndex < 4);
        return make_float4(this->rows[0][uiIndex],
                           this->rows[1][uiIndex],
                           this->rows[2][uiIndex],
                           this->rows[3][uiIndex]);
    }
    
    float3 operator * (const float3 &rkV) const
    {
        const float4 kC0 = this->getColumn(0);
        const float4 kC1 = this->getColumn(1);
        const float4 kC2 = this->getColumn(2);
        const float4 kC3 = this->getColumn(3);
        
        float4 kR4 = make_float4(rkV.x, rkV.y, rkV.z, 1.0f);
        float fInvW = 1.0f / dot(kR4, kC3);

        return (make_float3(dot(kC0, kR4) * fInvW, 
                            dot(kC1, kR4) * fInvW, 
                            dot(kC2, kR4) * fInvW));
    }

    float4 operator * (const float4 &rkR) const
    {
        const float4 kC0 = this->getColumn(0);
        const float4 kC1 = this->getColumn(1);
        const float4 kC2 = this->getColumn(2);
        const float4 kC3 = this->getColumn(3);
        
        return (make_float4(dot(kC0, rkR), 
                            dot(kC1, rkR), 
                            dot(kC2, rkR), 
                            dot(kC3, rkR)));
    }

    float16 &operator*= (const float16 &rkR)
    {
        const float4 kR0 = this->getRow(0);
        const float4 kR1 = this->getRow(1);
        const float4 kR2 = this->getRow(2);
        const float4 kR3 = this->getRow(3);

        const float4 kC0 = rkR.getColumn(0);
        const float4 kC1 = rkR.getColumn(1);
        const float4 kC2 = rkR.getColumn(2);
        const float4 kC3 = rkR.getColumn(3);

        this->rows[0] = make_float4(dot(kR0, kC0), dot(kR0, kC1), dot(kR0, kC2), dot(kR0, kC3));
        this->rows[1] = make_float4(dot(kR1, kC0), dot(kR1, kC1), dot(kR1, kC2), dot(kR1, kC3));
        this->rows[2] = make_float4(dot(kR2, kC0), dot(kR2, kC1), dot(kR2, kC2), dot(kR2, kC3));
        this->rows[3] = make_float4(dot(kR3, kC0), dot(kR3, kC1), dot(kR3, kC2), dot(kR3, kC3));
        
        return (*this);
    }

    float16 operator * (const float16 &rkR) const
    {
        if (rkR.isIdentity())
        {
            return *this;
        }

        if (this->isIdentity())
        {
            return rkR;
        }

        const float4 kR0 = this->getRow(0);
        const float4 kR1 = this->getRow(1);
        const float4 kR2 = this->getRow(2);
        const float4 kR3 = this->getRow(3);

        const float4 kC0 = rkR.getColumn(0);
        const float4 kC1 = rkR.getColumn(1);
        const float4 kC2 = rkR.getColumn(2);
        const float4 kC3 = rkR.getColumn(3);

        return make_float16(
            make_float4(dot(kR0, kC0), dot(kR0, kC1), dot(kR0, kC2), dot(kR0, kC3)),
            make_float4(dot(kR1, kC0), dot(kR1, kC1), dot(kR1, kC2), dot(kR1, kC3)),
            make_float4(dot(kR2, kC0), dot(kR2, kC1), dot(kR2, kC2), dot(kR2, kC3)),
            make_float4(dot(kR3, kC0), dot(kR3, kC1), dot(kR3, kC2), dot(kR3, kC3))
        );
    }


    friend float16 operator+ (float16 &rkL, float16 &rkR)
    {
        return (make_float16(rkL.rows[0] + rkR.rows[0], 
                             rkL.rows[1] + rkR.rows[1], 
                             rkL.rows[2] + rkR.rows[2], 
                             rkL.rows[3] + rkR.rows[3]));
    }

    float16 &operator+= (float16 &rkR)
    {
        rows[0] += rkR.rows[0];
        rows[1] += rkR.rows[1];
        rows[2] += rkR.rows[2];
        rows[3] += rkR.rows[3];
        return (*this);
    }

    friend float16 operator- (float16 &rkL, float16 &rkR)
    {
        return (make_float16(rkL.rows[0] - rkR.rows[0], 
                             rkL.rows[1] - rkR.rows[1], 
                             rkL.rows[2] - rkR.rows[2], 
                             rkL.rows[3] - rkR.rows[3]));
    }

    float16 &operator-= (float16 &rkR)
    {
        rows[0] -= rkR.rows[0];
        rows[1] -= rkR.rows[1];
        rows[2] -= rkR.rows[2];
        rows[3] -= rkR.rows[3];
        return (*this);
    }

    friend float16 operator* (float16 &rkL, float fR)
    {
        return (make_float16(rkL.rows[0] * fR, 
                             rkL.rows[1] * fR, 
                             rkL.rows[2] * fR, 
                             rkL.rows[3] * fR));
    }

    friend float16 operator* (float fL, float16 &rkR)
    {
        return (make_float16(fL * rkR.rows[0], 
                             fL * rkR.rows[1], 
                             fL * rkR.rows[2], 
                             fL * rkR.rows[3]));
    }

    float16 &operator*= (float fR)
    {
        rows[0] *= fR;
        rows[1] *= fR;
        rows[2] *= fR;
        rows[3] *= fR;
        return (*this);
    }
    
    void identity()
    {
        rows[0] = make_float4( 1.0f, 0.0f, 0.0f, 0.0f);
        rows[1] = make_float4( 0.0f, 1.0f, 0.0f, 0.0f);
        rows[2] = make_float4( 0.0f, 0.0f, 1.0f, 0.0f);
        rows[3] = make_float4( 0.0f, 0.0f, 0.0f, 1.0f);
    }

    bool operator ==(const float16& rkM) const
    {
        return (rows[0] == rkM.rows[0] &&
                rows[1] == rkM.rows[1] &&
                rows[2] == rkM.rows[2] &&
                rows[3] == rkM.rows[3]);
    }

    bool operator !=(const float16& rkM) const
    {
        return (rows[0] != rkM.rows[0] ||
                rows[1] != rkM.rows[1] ||
                rows[2] != rkM.rows[2] ||
                rows[3] != rkM.rows[3]);
    }


    bool isIdentity() const
    {
        static float16 s_Identity = make_float16( 1.0f, 0.0f, 0.0f, 0.0f,
                                                  0.0f, 1.0f, 0.0f, 0.0f,
                                                  0.0f, 0.0f, 1.0f, 0.0f,
                                                  0.0f, 0.0f, 0.0f, 1.0f );

        return (rows[0] == s_Identity.rows[0] &&
                rows[1] == s_Identity.rows[1] &&
                rows[2] == s_Identity.rows[2] &&
                rows[3] == s_Identity.rows[3]);
    }

    operator float*()
    {
        return this->rows[0];
    }

    operator const float*() const
    {
        return this->rows[0];
    }

    float4& operator[](int iIndex)
    {
        return this->rows[iIndex];
    }

    float4& operator[](unsigned int uiIndex)
    {
        return this->rows[uiIndex];
    }

    const float4& operator[](int iIndex) const
    {
        return this->rows[iIndex];
    }

    const float4& operator[](unsigned int uiIndex) const
    {
        return this->rows[uiIndex];
    }

    float4 rows[4];
};


////////////////////////////////////////////////////////////////////////////////

struct int2
{
	int2 ()
	{
        // EMPTY!
	}
	
    int2 (const int2 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
    }

	int2 (int iC0, int iC1)
	{
        columns[0] = iC0;
        columns[1] = iC1;
    }

    operator int*()
    {
        return columns;
    }

    operator const int*() const
    {
        return columns;
    }

    int &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 2);
        return (columns[iColumn]);
	}

    int operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 2);
        return (columns[iColumn]);
	}

	int2 &operator= (const int2 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        return (*this); 
    }

    bool operator== (const int2 &rkR) const
    {
        return (x == rkR.x && y == rkR.y);
    }

    bool operator!= (const int2 &rkR) const
    {
        return (x != rkR.x || y != rkR.y );
    }

	friend int2 operator+ (const int2 &rkL, const int2 &rkR) 
    { 
        return int2(rkL.x + rkR.x, 
                    rkL.y + rkR.y);        
    }

	int2 &operator+= (const int2 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        return (*this); 
    }

	friend int2 operator- (const int2 &rkL, const int2 &rkR) 
    { 
        return int2(rkL.x - rkR.x, 
                    rkL.y - rkR.y);        
    } 

	int2 &operator-= (const int2 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        return (*this);
    }  
    
	friend int2 operator* (const int2 &rkL, const int2 &rkR) 
    { 
        return int2(rkL.x * rkR.x, 
                    rkL.y * rkR.y);        
    } 

	friend int2 operator* (const int2 &rkL, int iR)
    {
        return int2(rkL.x * iR, 
                    rkL.y * iR);        
    }

    friend int2 operator* (int iL, const int2 &rkR)
    {
        return int2(iL * rkR.x, 
                    iL * rkR.y);        
    }

	friend int2 operator* (const int2 &rkL, float fR)
    {
        return int2(rkL.x * fR, 
                    rkL.y * fR);        
    }

    friend int2 operator* (float fL, const int2 &rkR)
    {
        return int2(fL * rkR.x, 
                    fL * rkR.y);        
    }

	int2 &operator*= (const int2 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        return (*this);
    }

    int2 &operator*= (int iR)
    {
        x *= iR;
        y *= iR;
        return (*this);
    }

    int2 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        return (*this);
    }

	friend int2 operator/ (const int2 &rkL, const int2 &rkR) 
    { 
        return int2(rkL.x / rkR.x, 
                    rkL.y / rkR.y);        
    }

    friend int2 operator/ (const int2 &rkL, int iR)
    {
        return int2(rkL.x / iR, 
                    rkL.y / iR);        
    }

    friend int2 operator/ (const int2 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return int2(rkL.x * fInv, 
                    rkL.y * fInv);        
    }

	int2 &operator/= (const int2 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        return (*this);
    }

    int2 &operator/= (int iR)
    {
        x /= iR;
        y /= iR;
        return (*this);
    }

    int2 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        return (*this);
    }

    int2 operator - ( void ) const
    {
        return int2( -x, -y );
    }

    union
    {
        int columns[2];

        struct
        {
            int x;
            int y;
        };

        struct
        {
            int r;
            int g;
        };

        struct
        {
            int s;
            int t;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct int3
{
	int3 ()
	{
        // EMPTY!
	}
	
    int3 (const int3 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
    }

	int3 (int iC0, int iC1, int iC2)
    { 
        columns[0] = iC0;
        columns[1] = iC1;
        columns[2] = iC2;
    }

    operator int*()
    {
        return columns;
    }

    operator const int*() const
    {
        return columns;
    }

    int &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 3);
        return (columns[iColumn]);
	}

    int operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 3);
        return (columns[iColumn]);
	}

	int3 &operator= (const int3 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        return (*this); 
    }

    bool operator== (const int3 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z);
    }

    bool operator!= (const int3 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z );
    }

	friend int3 operator+ (const int3 &rkL, const int3 &rkR) 
    { 
        return int3(rkL.x + rkR.x, 
                    rkL.y + rkR.y, 
                    rkL.z + rkR.z);        
    }

	int3 &operator+= (const int3 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        return (*this); 
    }

	friend int3 operator- (const int3 &rkL, const int3 &rkR) 
    { 
        return int3(rkL.x - rkR.x, 
                    rkL.y - rkR.y, 
                    rkL.z - rkR.z);        
    } 

	int3 &operator-= (const int3 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        return (*this);
    }  
    
	friend int3 operator* (const int3 &rkL, const int3 &rkR) 
    { 
        return int3(rkL.x * rkR.x, 
                    rkL.y * rkR.y, 
                    rkL.z * rkR.z);        
    } 

	friend int3 operator* (const int3 &rkL, int iR)
    {
        return int3(rkL.x * iR, 
                    rkL.y * iR, 
                    rkL.z * iR);        
    }

    friend int3 operator* (int iL, const int3 &rkR)
    {
        return int3(iL * rkR.x, 
                    iL * rkR.y, 
                    iL * rkR.z);        
    }

	friend int3 operator* (const int3 &rkL, float fR)
    {
        return int3(rkL.x * fR, 
                    rkL.y * fR, 
                    rkL.z * fR);        
    }

    friend int3 operator* (float fL, const int3 &rkR)
    {
        return int3(fL * rkR.x, 
                    fL * rkR.y, 
                    fL * rkR.z);        
    }

	int3 &operator*= (const int3 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        return (*this);
    }

    int3 &operator*= (int iR)
    {
        x *= iR;
        y *= iR;
        z *= iR;
        return (*this);
    }

    int3 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        return (*this);
    }

	friend int3 operator/ (const int3 &rkL, const int3 &rkR) 
    { 
        return int3(rkL.x / rkR.x, 
                    rkL.y / rkR.y, 
                    rkL.z / rkR.z);        
    }

    friend int3 operator/ (const int3 &rkL, int iR)
    {
        return int3(rkL.x / iR, 
                    rkL.y / iR, 
                    rkL.z / iR);        
    }

    friend int3 operator/ (const int3 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return int3(rkL.x * fInv, 
                    rkL.y * fInv, 
                    rkL.z * fInv);        
    }

	int3 &operator/= (const int3 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        return (*this);
    }

    int3 &operator/= (int iR)
    {
        x /= iR;
        y /= iR;
        z /= iR;
        return (*this);
    }

    int3 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        return (*this);
    }

    int3 operator - ( void ) const
    {
        return int3( -x, -y, -z );
    }

    union
    {
        int columns[3];

        struct
        {
            int x;
            int y;
            int z;
        };

        struct
        {
            int r;
            int g;
            int b;
        };

        struct
        {
            int s;
            int t;
            int u;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct int4
{
	int4 ()
	{
        // EMPTY!
	}
	
    int4 (const int4 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = rkOther.w;
    }
	
    int4(const int3 &rkOther, int iW = 0)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = iW;
    }

	int4 (int iC0, int iC1, int iC2, int iC3)
    { 
        columns[0] = iC0;
        columns[1] = iC1;
        columns[2] = iC2;
        columns[3] = iC3;
        return;
    }

    operator int*()
    {
        return columns;
    }

    operator const int*() const
    {
        return columns;
    }

    int &operator[] (int iColumn)
	{
	    assert(iColumn >= 0 && iColumn < 4);
        return (columns[iColumn]);
	}

    int operator[] (int iColumn) const
	{
	    assert(iColumn >= 0 && iColumn < 4);
        return (columns[iColumn]);
	}

	int4 &operator= (const int4 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        columns[3] = rkOther.columns[3];
        return (*this); 
    }

    bool operator== (const int4 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z && w == rkR.w);
    }

    bool operator!= (const int4 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z || w != rkR.w);
    }

	friend int4 operator+ (const int4 &rkL, const int4 &rkR) 
    { 
        return int4(rkL.x + rkR.x, 
                    rkL.y + rkR.y, 
                    rkL.z + rkR.z, 
                    rkL.w + rkR.w);        
    }

	int4 &operator+= (const int4 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        w += rkR.w;
        return (*this); 
    }

	friend int4 operator- (const int4 &rkL, const int4 &rkR) 
    { 
        return int4(rkL.x - rkR.x, 
                    rkL.y - rkR.y, 
                    rkL.z - rkR.z, 
                    rkL.w - rkR.w);        
    } 

	int4 &operator-= (const int4 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        w -= rkR.w;
        return (*this);
    }  
    
	friend int4 operator* (const int4 &rkL, const int4 &rkR) 
    { 
        return int4(rkL.x * rkR.x, 
                    rkL.y * rkR.y, 
                    rkL.z * rkR.z, 
                    rkL.w * rkR.w);        
    } 

	friend int4 operator* (const int4 &rkL, int iR)
    {
        return int4(rkL.x * iR, 
                    rkL.y * iR, 
                    rkL.z * iR, 
                    rkL.w * iR);        
    }

    friend int4 operator* (int iL, const int4 &rkR)
    {
        return int4(iL * rkR.x, 
                    iL * rkR.y, 
                    iL * rkR.z, 
                    iL * rkR.w);        
    }

	friend int4 operator* (const int4 &rkL, float fR)
    {
        return int4(rkL.x * fR, 
                    rkL.y * fR, 
                    rkL.z * fR, 
                    rkL.w * fR);        
    }

    friend int4 operator* (float fL, const int4 &rkR)
    {
        return int4(fL * rkR.x, 
                    fL * rkR.y, 
                    fL * rkR.z, 
                    fL * rkR.w);        
    }

	int4 &operator*= (const int4 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        w *= rkR.w;
        return (*this);
    }

    int4 &operator*= (int iR)
    {
        x *= iR;
        y *= iR;
        z *= iR;
        w *= iR;
        return (*this);
    }

    int4 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        w *= fR;
        return (*this);
    }

	friend  int4 operator/ (const int4 &rkL, const int4 &rkR) 
    { 
        return int4(rkL.x / rkR.x, 
                    rkL.y / rkR.y, 
                    rkL.z / rkR.z, 
                    rkL.w / rkR.w);        
    }

    friend  int4 operator/ (const int4 &rkL, int iR)
    {
        return int4(rkL.x / iR, 
                    rkL.y / iR, 
                    rkL.z / iR, 
                    rkL.w / iR);        
    }

    friend  int4 operator/ (const int4 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return int4(rkL.x * fInv, 
                    rkL.y * fInv, 
                    rkL.z * fInv, 
                    rkL.w * fInv);        
    }

	int4 &operator/= (const int4 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        w /= rkR.w;
        return (*this);
    }

    int4 &operator/= (int iR)
    {
        x /= iR;
        y /= iR;
        z /= iR;
        w /= iR;
        return (*this);
    }

    int4 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        w *= fInv;
        return (*this);
    }

    int4 operator - ( void ) const
    {
        return int4( -x, -y, -z, -w );
    }

    union
    {
        int columns[4];

        struct
        {
            int x;
            int y;
            int z;
            int w;
        };

        struct
        {
            int r;
            int g;
            int b;
            int a;
        };

        struct
        {
            int s;
            int t;
            int u;
            int v;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct uint2
{
	uint2 ()
	{
        // EMPTY!
	}
	
    uint2 (const uint2 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
    }

	uint2 (uint uiC0, uint uiC1)
	{
        columns[0] = uiC0;
        columns[1] = uiC1;
    }

    operator uint*()
    {
        return columns;
    }

    operator const uint*() const
    {
        return columns;
    }

    uint &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

    uint operator[] (int uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

	uint2 &operator= (const uint2 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        return (*this); 
    }

    bool operator== (const uint2 &rkR) const
    {
        return (x == rkR.x && y == rkR.y);
    }

    bool operator!= (const uint2 &rkR) const
    {
        return (x != rkR.x || y != rkR.y );
    }

	friend uint2 operator+ (const uint2 &rkL, const uint2 &rkR) 
    { 
        return uint2(rkL.x + rkR.x, 
                     rkL.y + rkR.y);        
    }

	uint2 &operator+= (const uint2 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        return (*this); 
    }

	friend uint2 operator- (const uint2 &rkL, const uint2 &rkR) 
    { 
        return uint2(rkL.x - rkR.x, 
                     rkL.y - rkR.y);        
    } 

	uint2 &operator-= (const uint2 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        return (*this);
    }  
    
	friend uint2 operator* (const uint2 &rkL, const uint2 &rkR) 
    { 
        return uint2(rkL.x * rkR.x, 
                     rkL.y * rkR.y);        
    } 

	friend uint2 operator* (const uint2 &rkL, uint uiR)
    {
        return uint2(rkL.x * uiR, 
                     rkL.y * uiR);        
    }

    friend uint2 operator* (uint uiL, const uint2 &rkR)
    {
        return uint2(uiL * rkR.x, 
                    uiL * rkR.y);        
    }

	friend uint2 operator* (const uint2 &rkL, float fR)
    {
        return uint2(rkL.x * fR, 
                    rkL.y * fR);        
    }

    friend uint2 operator* (float fL, const uint2 &rkR)
    {
        return uint2(fL * rkR.x, 
                    fL * rkR.y);        
    }

	uint2 &operator*= (const uint2 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        return (*this);
    }

    uint2 &operator*= (uint uiR)
    {
        x *= uiR;
        y *= uiR;
        return (*this);
    }

    uint2 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        return (*this);
    }

	friend uint2 operator/ (const uint2 &rkL, const uint2 &rkR) 
    { 
        return uint2(rkL.x / rkR.x, 
                     rkL.y / rkR.y);        
    }

    friend uint2 operator/ (const uint2 &rkL, uint uiR)
    {
        return uint2(rkL.x / uiR, 
                     rkL.y / uiR);        
    }

    friend uint2 operator/ (const uint2 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uint2(rkL.x * fInv, 
                     rkL.y * fInv);        
    }

	uint2 &operator/= (const uint2 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        return (*this);
    }

    uint2 &operator/= (uint fR)
    {
        x /= fR;
        y /= fR;
        return (*this);
    }

    uint2 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        return (*this);
    }

    uint2 operator - ( void ) const
    {
        return uint2( -x, -y );
    }

    union
    {
        uint columns[2];

        struct
        {
            uint x;
            uint y;
        };

        struct
        {
            uint r;
            uint g;
        };

        struct
        {
            uint s;
            uint t;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct uint3
{
	uint3 ()
	{
        // EMPTY!
	}
	
    uint3 (const uint3 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
    }

	uint3 (uint uiC0, uint uiC1, uint uiC2)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
    }

    operator uint*()
    {
        return columns;
    }

    operator const uint*() const
    {
        return columns;
    }

    uint &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

    uint operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

	uint3 &operator= (const uint3 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        return (*this); 
    }

    bool operator== (const uint3 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z);
    }

    bool operator!= (const uint3 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z );
    }

	friend uint3 operator+ (const uint3 &rkL, const uint3 &rkR) 
    { 
        return uint3(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z);        
    }

	uint3 &operator+= (const uint3 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        return (*this); 
    }

	friend uint3 operator- (const uint3 &rkL, const uint3 &rkR) 
    { 
        return uint3(rkL.x - rkR.x, 
                     rkL.y - rkR.y, 
                     rkL.z - rkR.z);        
    } 

	uint3 &operator-= (const uint3 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        return (*this);
    }  
    
	friend uint3 operator* (const uint3 &rkL, const uint3 &rkR) 
    { 
        return uint3(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z);        
    } 

	friend uint3 operator* (const uint3 &rkL, uint uiR)
    {
        return uint3(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR);        
    }

    friend uint3 operator* (uint uiL, const uint3 &rkR)
    {
        return uint3(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z);        
    }

	friend uint3 operator* (const uint3 &rkL, float fR)
    {
        return uint3(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR);        
    }

    friend uint3 operator* (float fL, const uint3 &rkR)
    {
        return uint3(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z);        
    }

	uint3 &operator*= (const uint3 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        return (*this);
    }

    uint3 &operator*= (uint uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        return (*this);
    }

    uint3 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        return (*this);
    }

	friend uint3 operator/ (const uint3 &rkL, const uint3 &rkR) 
    { 
        return uint3(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z);        
    }

    friend uint3 operator/ (const uint3 &rkL, uint uiR)
    {
        return uint3(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR);        
    }

    friend uint3 operator/ (const uint3 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uint3(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv);        
    }

	uint3 &operator/= (const uint3 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        return (*this);
    }

    uint3 &operator/= (uint uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        return (*this);
    }

    uint3 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        return (*this);
    }

    uint3 operator - ( void ) const
    {
        return uint3( -x, -y, -z );
    }

    union
    {
        uint columns[3];

        struct
        {
            uint x;
            uint y;
            uint z;
        };

        struct
        {
            uint r;
            uint g;
            uint b;
        };

        struct
        {
            uint s;
            uint t;
            uint u;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct uint4
{
	uint4 ()
	{
        // EMPTY!
	}
	
    uint4 (const uint4 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = rkOther.w;
    }
	
    uint4(const uint3 &rkOther, uint uiW = 0)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = uiW;
    }

	uint4 (uint uiC0, uint uiC1, uint uiC2, uint uiC3)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
        columns[3] = uiC3;
    }

    operator uint*()
    {
        return columns;
    }

    operator const uint*() const
    {
        return columns;
    }

    uint &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

    uint operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

	uint4 &operator= (const uint4 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        columns[3] = rkOther.columns[3];
        return (*this); 
    }

    bool operator== (const uint4 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z && w == rkR.w);
    }

    bool operator!= (const uint4 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z || w != rkR.w);
    }

	friend uint4 operator+ (const uint4 &rkL, const uint4 &rkR) 
    { 
        return uint4(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z, 
                     rkL.w + rkR.w);        
    }

	uint4 &operator+= (const uint4 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        w += rkR.w;
        return (*this); 
    }

	friend uint4 operator- (const uint4 &rkL, const uint4 &rkR) 
    { 
        return uint4(rkL.x - rkR.x, 
                     rkL.y - rkR.y, 
                     rkL.z - rkR.z, 
                     rkL.w - rkR.w);        
    } 

	uint4 &operator-= (const uint4 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        w -= rkR.w;
        return (*this);
    }  
    
	friend uint4 operator* (const uint4 &rkL, const uint4 &rkR) 
    { 
        return uint4(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z, 
                     rkL.w * rkR.w);        
    } 

	friend uint4 operator* (const uint4 &rkL, uint uiR)
    {
        return uint4(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR, 
                     rkL.w * uiR);        
    }

    friend uint4 operator* (uint uiL, const uint4 &rkR)
    {
        return uint4(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z, 
                     uiL * rkR.w);        
    }

	friend uint4 operator* (const uint4 &rkL, float fR)
    {
        return uint4(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR, 
                     rkL.w * fR);        
    }

    friend uint4 operator* (float fL, const uint4 &rkR)
    {
        return uint4(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z, 
                     fL * rkR.w);        
    }

	uint4 &operator*= (const uint4 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        w *= rkR.w;
        return (*this);
    }

    uint4 &operator*= (uint uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        w *= uiR;
        return (*this);
    }

    uint4 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        w *= fR;
        return (*this);
    }

	friend  uint4 operator/ (const uint4 &rkL, const uint4 &rkR) 
    { 
        return uint4(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z, 
                     rkL.w / rkR.w);        
    }

    friend  uint4 operator/ (const uint4 &rkL, uint uiR)
    {
        return uint4(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR, 
                     rkL.w / uiR);        
    }

    friend  uint4 operator/ (const uint4 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uint4(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv, 
                     rkL.w * fInv);        
    }

	uint4 &operator/= (const uint4 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        w /= rkR.w;
        return (*this);
    }

    uint4 &operator/= (uint uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        w /= uiR;
        return (*this);
    }

    uint4 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        w *= fInv;
        return (*this);
    }

    uint4 operator - ( void ) const
    {
        return uint4( -x, -y, -z, -w );
    }

    union
    {
        uint columns[4];

        struct
        {
            uint x;
            uint y;
            uint z;
            uint w;
        };

        struct
        {
            uint r;
            uint g;
            uint b;
            uint a;
        };

        struct
        {
            uint s;
            uint t;
            uint u;
            uint v;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct uchar2
{
	uchar2 ()
	{
        // EMPTY!
	}
	
    uchar2 (const uchar2 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
    }

	uchar2 (uchar uiC0, uchar uiC1)
	{
        columns[0] = uiC0;
        columns[1] = uiC1;
    }

    operator uchar*()
    {
        return columns;
    }

    operator const uchar*() const
    {
        return columns;
    }

    uchar &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

    uchar operator[] (int uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

	uchar2 &operator= (const uchar2 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        return (*this); 
    }

    bool operator== (const uchar2 &rkR) const
    {
        return (x == rkR.x && y == rkR.y);
    }

    bool operator!= (const uchar2 &rkR) const
    {
        return (x != rkR.x || y != rkR.y );
    }

	friend uchar2 operator+ (const uchar2 &rkL, const uchar2 &rkR) 
    { 
        return uchar2(rkL.x + rkR.x, 
                     rkL.y + rkR.y);        
    }

	uchar2 &operator+= (const uchar2 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        return (*this); 
    }

	friend uchar2 operator- (const uchar2 &rkL, const uchar2 &rkR) 
    { 
        return uchar2(rkL.x - rkR.x, 
                     rkL.y - rkR.y);        
    } 

	uchar2 &operator-= (const uchar2 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        return (*this);
    }  
    
	friend uchar2 operator* (const uchar2 &rkL, const uchar2 &rkR) 
    { 
        return uchar2(rkL.x * rkR.x, 
                     rkL.y * rkR.y);        
    } 

	friend uchar2 operator* (const uchar2 &rkL, uchar uiR)
    {
        return uchar2(rkL.x * uiR, 
                     rkL.y * uiR);        
    }

    friend uchar2 operator* (uchar uiL, const uchar2 &rkR)
    {
        return uchar2(uiL * rkR.x, 
                    uiL * rkR.y);        
    }

	friend uchar2 operator* (const uchar2 &rkL, float fR)
    {
        return uchar2(rkL.x * fR, 
                    rkL.y * fR);        
    }

    friend uchar2 operator* (float fL, const uchar2 &rkR)
    {
        return uchar2(fL * rkR.x, 
                    fL * rkR.y);        
    }

	uchar2 &operator*= (const uchar2 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        return (*this);
    }

    uchar2 &operator*= (uchar uiR)
    {
        x *= uiR;
        y *= uiR;
        return (*this);
    }

    uchar2 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        return (*this);
    }

	friend uchar2 operator/ (const uchar2 &rkL, const uchar2 &rkR) 
    { 
        return uchar2(rkL.x / rkR.x, 
                     rkL.y / rkR.y);        
    }

    friend uchar2 operator/ (const uchar2 &rkL, uchar uiR)
    {
        return uchar2(rkL.x / uiR, 
                     rkL.y / uiR);        
    }

    friend uchar2 operator/ (const uchar2 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uchar2(rkL.x * fInv, 
                     rkL.y * fInv);        
    }

	uchar2 &operator/= (const uchar2 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        return (*this);
    }

    uchar2 &operator/= (uchar fR)
    {
        x /= fR;
        y /= fR;
        return (*this);
    }

    uchar2 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        return (*this);
    }

    uchar2 operator - ( void ) const
    {
        return uchar2( -x, -y );
    }

    union
    {
        uchar columns[2];

        struct
        {
            uchar x;
            uchar y;
        };

        struct
        {
            uchar r;
            uchar g;
        };

        struct
        {
            uchar s;
            uchar t;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct uchar3
{
	uchar3 ()
	{
        // EMPTY!
	}
	
    uchar3 (const uchar3 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
    }

	uchar3 (uchar uiC0, uchar uiC1, uchar uiC2)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
    }

    operator uchar*()
    {
        return columns;
    }

    operator const uchar*() const
    {
        return columns;
    }

    uchar &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

    uchar operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

	uchar3 &operator= (const uchar3 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        return (*this); 
    }

    bool operator== (const uchar3 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z);
    }

    bool operator!= (const uchar3 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z );
    }

	friend uchar3 operator+ (const uchar3 &rkL, const uchar3 &rkR) 
    { 
        return uchar3(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z);        
    }

	uchar3 &operator+= (const uchar3 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        return (*this); 
    }

	friend uchar3 operator- (const uchar3 &rkL, const uchar3 &rkR) 
    { 
        return uchar3(rkL.x - rkR.x, 
                      rkL.y - rkR.y, 
                      rkL.z - rkR.z);        
    } 

	uchar3 &operator-= (const uchar3 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        return (*this);
    }  
    
	friend uchar3 operator* (const uchar3 &rkL, const uchar3 &rkR) 
    { 
        return uchar3(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z);        
    } 

	friend uchar3 operator* (const uchar3 &rkL, uchar uiR)
    {
        return uchar3(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR);        
    }

    friend uchar3 operator* (uchar uiL, const uchar3 &rkR)
    {
        return uchar3(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z);        
    }

	friend uchar3 operator* (const uchar3 &rkL, float fR)
    {
        return uchar3(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR);        
    }

    friend uchar3 operator* (float fL, const uchar3 &rkR)
    {
        return uchar3(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z);        
    }

	uchar3 &operator*= (const uchar3 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        return (*this);
    }

    uchar3 &operator*= (uchar uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        return (*this);
    }

    uchar3 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        return (*this);
    }

	friend uchar3 operator/ (const uchar3 &rkL, const uchar3 &rkR) 
    { 
        return uchar3(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z);        
    }

    friend uchar3 operator/ (const uchar3 &rkL, uchar uiR)
    {
        return uchar3(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR);        
    }

    friend uchar3 operator/ (const uchar3 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uchar3(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv);        
    }

	uchar3 &operator/= (const uchar3 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        return (*this);
    }

    uchar3 &operator/= (uchar uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        return (*this);
    }

    uchar3 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        return (*this);
    }

    uchar3 operator - ( void ) const
    {
        return uchar3( -x, -y, -z );
    }

    union
    {
        uchar columns[3];

        struct
        {
            uchar x;
            uchar y;
            uchar z;
        };

        struct
        {
            uchar r;
            uchar g;
            uchar b;
        };

        struct
        {
            uchar s;
            uchar t;
            uchar u;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct uchar4
{
	uchar4 ()
	{
        // EMPTY!
	}
	
    uchar4 (const uchar4 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = rkOther.w;
    }
	
    uchar4(const uchar3 &rkOther, uchar uiW = 0)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = uiW;
    }

	uchar4 (uchar uiC0, uchar uiC1, uchar uiC2, uchar uiC3)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
        columns[3] = uiC3;
    }

    operator uchar*()
    {
        return columns;
    }

    operator const uchar*() const
    {
        return columns;
    }

    uchar &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

    uchar operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

	uchar4 &operator= (const uchar4 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        columns[3] = rkOther.columns[3];
        return (*this); 
    }

    bool operator== (const uchar4 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z && w == rkR.w);
    }

    bool operator!= (const uchar4 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z || w != rkR.w);
    }

	friend uchar4 operator+ (const uchar4 &rkL, const uchar4 &rkR) 
    { 
        return uchar4(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z, 
                     rkL.w + rkR.w);        
    }

	uchar4 &operator+= (const uchar4 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        w += rkR.w;
        return (*this); 
    }

	friend uchar4 operator- (const uchar4 &rkL, const uchar4 &rkR) 
    { 
        return uchar4(rkL.x - rkR.x, 
                     rkL.y - rkR.y, 
                     rkL.z - rkR.z, 
                     rkL.w - rkR.w);        
    } 

	uchar4 &operator-= (const uchar4 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        w -= rkR.w;
        return (*this);
    }  
    
	friend uchar4 operator* (const uchar4 &rkL, const uchar4 &rkR) 
    { 
        return uchar4(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z, 
                     rkL.w * rkR.w);        
    } 

	friend uchar4 operator* (const uchar4 &rkL, uchar uiR)
    {
        return uchar4(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR, 
                     rkL.w * uiR);        
    }

    friend uchar4 operator* (uchar uiL, const uchar4 &rkR)
    {
        return uchar4(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z, 
                     uiL * rkR.w);        
    }

	friend uchar4 operator* (const uchar4 &rkL, float fR)
    {
        return uchar4(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR, 
                     rkL.w * fR);        
    }

    friend uchar4 operator* (float fL, const uchar4 &rkR)
    {
        return uchar4(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z, 
                     fL * rkR.w);        
    }

	uchar4 &operator*= (const uchar4 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        w *= rkR.w;
        return (*this);
    }

    uchar4 &operator*= (uchar uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        w *= uiR;
        return (*this);
    }

    uchar4 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        w *= fR;
        return (*this);
    }

	friend  uchar4 operator/ (const uchar4 &rkL, const uchar4 &rkR) 
    { 
        return uchar4(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z, 
                     rkL.w / rkR.w);        
    }

    friend  uchar4 operator/ (const uchar4 &rkL, uchar uiR)
    {
        return uchar4(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR, 
                     rkL.w / uiR);        
    }

    friend  uchar4 operator/ (const uchar4 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return uchar4(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv, 
                     rkL.w * fInv);        
    }

	uchar4 &operator/= (const uchar4 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        w /= rkR.w;
        return (*this);
    }

    uchar4 &operator/= (uchar uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        w /= uiR;
        return (*this);
    }

    uchar4 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        w *= fInv;
        return (*this);
    }

    uchar4 operator - ( void ) const
    {
        return uchar4( -x, -y, -z, -w );
    }

    union
    {
        uchar columns[4];

        struct
        {
            uchar x;
            uchar y;
            uchar z;
            uchar w;
        };

        struct
        {
            uchar r;
            uchar g;
            uchar b;
            uchar a;
        };

        struct
        {
            uchar s;
            uchar t;
            uchar u;
            uchar v;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct char2
{
	char2 ()
	{
        // EMPTY!
	}
	
    char2 (const char2 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
    }

	char2 (char uiC0, char uiC1)
	{
        columns[0] = uiC0;
        columns[1] = uiC1;
    }

    operator char*()
    {
        return columns;
    }

    operator const char*() const
    {
        return columns;
    }

    char &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

    char operator[] (int uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 2);
        return (columns[uiColumn]);
	}

	char2 &operator= (const char2 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        return (*this); 
    }

    bool operator== (const char2 &rkR) const
    {
        return (x == rkR.x && y == rkR.y);
    }

    bool operator!= (const char2 &rkR) const
    {
        return (x != rkR.x || y != rkR.y );
    }

	friend char2 operator+ (const char2 &rkL, const char2 &rkR) 
    { 
        return char2(rkL.x + rkR.x, 
                     rkL.y + rkR.y);        
    }

	char2 &operator+= (const char2 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        return (*this); 
    }

	friend char2 operator- (const char2 &rkL, const char2 &rkR) 
    { 
        return char2(rkL.x - rkR.x, 
                     rkL.y - rkR.y);        
    } 

	char2 &operator-= (const char2 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        return (*this);
    }  
    
	friend char2 operator* (const char2 &rkL, const char2 &rkR) 
    { 
        return char2(rkL.x * rkR.x, 
                     rkL.y * rkR.y);        
    } 

	friend char2 operator* (const char2 &rkL, char uiR)
    {
        return char2(rkL.x * uiR, 
                     rkL.y * uiR);        
    }

    friend char2 operator* (char uiL, const char2 &rkR)
    {
        return char2(uiL * rkR.x, 
                    uiL * rkR.y);        
    }

	friend char2 operator* (const char2 &rkL, float fR)
    {
        return char2(rkL.x * fR, 
                    rkL.y * fR);        
    }

    friend char2 operator* (float fL, const char2 &rkR)
    {
        return char2(fL * rkR.x, 
                    fL * rkR.y);        
    }

	char2 &operator*= (const char2 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        return (*this);
    }

    char2 &operator*= (char uiR)
    {
        x *= uiR;
        y *= uiR;
        return (*this);
    }

    char2 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        return (*this);
    }

	friend char2 operator/ (const char2 &rkL, const char2 &rkR) 
    { 
        return char2(rkL.x / rkR.x, 
                     rkL.y / rkR.y);        
    }

    friend char2 operator/ (const char2 &rkL, char uiR)
    {
        return char2(rkL.x / uiR, 
                     rkL.y / uiR);        
    }

    friend char2 operator/ (const char2 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return char2(rkL.x * fInv, 
                     rkL.y * fInv);        
    }

	char2 &operator/= (const char2 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        return (*this);
    }

    char2 &operator/= (char fR)
    {
        x /= fR;
        y /= fR;
        return (*this);
    }

    char2 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        return (*this);
    }

    char2 operator - ( void ) const
    {
        return char2( -x, -y );
    }

    union
    {
        char columns[2];

        struct
        {
            char x;
            char y;
        };

        struct
        {
            char r;
            char g;
        };

        struct
        {
            char s;
            char t;
        };
	};
};


////////////////////////////////////////////////////////////////////////////////

struct char3
{
	char3 ()
	{
        // EMPTY!
	}
	
    char3 (const char3 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
    }

	char3 (char uiC0, char uiC1, char uiC2)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
    }

    operator char*()
    {
        return columns;
    }

    operator const char*() const
    {
        return columns;
    }

    char &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

    char operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 3);
        return (columns[uiColumn]);
	}

	char3 &operator= (const char3 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        return (*this); 
    }

    bool operator== (const char3 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z);
    }

    bool operator!= (const char3 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z );
    }

	friend char3 operator+ (const char3 &rkL, const char3 &rkR) 
    { 
        return char3(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z);        
    }

	char3 &operator+= (const char3 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        return (*this); 
    }

	friend char3 operator- (const char3 &rkL, const char3 &rkR) 
    { 
        return char3(rkL.x - rkR.x, 
                     rkL.y - rkR.y, 
                     rkL.z - rkR.z);        
    } 

	char3 &operator-= (const char3 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        return (*this);
    }  
    
	friend char3 operator* (const char3 &rkL, const char3 &rkR) 
    { 
        return char3(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z);        
    } 

	friend char3 operator* (const char3 &rkL, char uiR)
    {
        return char3(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR);        
    }

    friend char3 operator* (char uiL, const char3 &rkR)
    {
        return char3(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z);        
    }

	friend char3 operator* (const char3 &rkL, float fR)
    {
        return char3(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR);        
    }

    friend char3 operator* (float fL, const char3 &rkR)
    {
        return char3(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z);        
    }

	char3 &operator*= (const char3 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        return (*this);
    }

    char3 &operator*= (char uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        return (*this);
    }

    char3 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        return (*this);
    }

	friend char3 operator/ (const char3 &rkL, const char3 &rkR) 
    { 
        return char3(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z);        
    }

    friend char3 operator/ (const char3 &rkL, char uiR)
    {
        return char3(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR);        
    }

    friend char3 operator/ (const char3 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return char3(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv);        
    }

	char3 &operator/= (const char3 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        return (*this);
    }

    char3 &operator/= (char uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        return (*this);
    }

    char3 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        return (*this);
    }

    char3 operator - ( void ) const
    {
        return char3( -x, -y, -z );
    }

    union
    {
        char columns[3];

        struct
        {
            char x;
            char y;
            char z;
        };

        struct
        {
            char r;
            char g;
            char b;
        };

        struct
        {
            char s;
            char t;
            char u;
        };
	};
};

////////////////////////////////////////////////////////////////////////////////

struct char4
{
	char4 ()
	{
        // EMPTY!
	}
	
    char4 (const char4 &rkOther)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = rkOther.w;
    }
	
    char4(const char3 &rkOther, char uiW = 0)
    {
        x = rkOther.x;
        y = rkOther.y;
        z = rkOther.z;
        w = uiW;
    }

	char4 (char uiC0, char uiC1, char uiC2, char uiC3)
    { 
        columns[0] = uiC0;
        columns[1] = uiC1;
        columns[2] = uiC2;
        columns[3] = uiC3;
    }

    operator char*()
    {
        return columns;
    }

    operator const char*() const
    {
        return columns;
    }

    char &operator[] (uint uiColumn)
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

    char operator[] (uint uiColumn) const
	{
	    assert(uiColumn >= 0 && uiColumn < 4);
        return (columns[uiColumn]);
	}

	char4 &operator= (const char4 &rkOther)
    { 
        columns[0] = rkOther.columns[0];
        columns[1] = rkOther.columns[1];
        columns[2] = rkOther.columns[2];
        columns[3] = rkOther.columns[3];
        return (*this); 
    }

    bool operator== (const char4 &rkR) const
    {
        return (x == rkR.x && y == rkR.y && z == rkR.z && w == rkR.w);
    }

    bool operator!= (const char4 &rkR) const
    {
        return (x != rkR.x || y != rkR.y || z != rkR.z || w != rkR.w);
    }

	friend char4 operator+ (const char4 &rkL, const char4 &rkR) 
    { 
        return char4(rkL.x + rkR.x, 
                     rkL.y + rkR.y, 
                     rkL.z + rkR.z, 
                     rkL.w + rkR.w);        
    }

	char4 &operator+= (const char4 &rkR) 
    { 
        x += rkR.x;
        y += rkR.y;
        z += rkR.z;
        w += rkR.w;
        return (*this); 
    }

	friend char4 operator- (const char4 &rkL, const char4 &rkR) 
    { 
        return char4(rkL.x - rkR.x, 
                     rkL.y - rkR.y, 
                     rkL.z - rkR.z, 
                     rkL.w - rkR.w);        
    } 

	char4 &operator-= (const char4 &rkR) 
    { 
        x -= rkR.x;
        y -= rkR.y;
        z -= rkR.z;
        w -= rkR.w;
        return (*this);
    }  
    
	friend char4 operator* (const char4 &rkL, const char4 &rkR) 
    { 
        return char4(rkL.x * rkR.x, 
                     rkL.y * rkR.y, 
                     rkL.z * rkR.z, 
                     rkL.w * rkR.w);        
    } 

	friend char4 operator* (const char4 &rkL, char uiR)
    {
        return char4(rkL.x * uiR, 
                     rkL.y * uiR, 
                     rkL.z * uiR, 
                     rkL.w * uiR);        
    }

    friend char4 operator* (char uiL, const char4 &rkR)
    {
        return char4(uiL * rkR.x, 
                     uiL * rkR.y, 
                     uiL * rkR.z, 
                     uiL * rkR.w);        
    }

	friend char4 operator* (const char4 &rkL, float fR)
    {
        return char4(rkL.x * fR, 
                     rkL.y * fR, 
                     rkL.z * fR, 
                     rkL.w * fR);        
    }

    friend char4 operator* (float fL, const char4 &rkR)
    {
        return char4(fL * rkR.x, 
                     fL * rkR.y, 
                     fL * rkR.z, 
                     fL * rkR.w);        
    }

	char4 &operator*= (const char4 &rkR) 
    { 
        x *= rkR.x;
        y *= rkR.y;
        z *= rkR.z;
        w *= rkR.w;
        return (*this);
    }

    char4 &operator*= (char uiR)
    {
        x *= uiR;
        y *= uiR;
        z *= uiR;
        w *= uiR;
        return (*this);
    }

    char4 &operator*= (float fR)
    {
        x *= fR;
        y *= fR;
        z *= fR;
        w *= fR;
        return (*this);
    }

	friend  char4 operator/ (const char4 &rkL, const char4 &rkR) 
    { 
        return char4(rkL.x / rkR.x, 
                     rkL.y / rkR.y, 
                     rkL.z / rkR.z, 
                     rkL.w / rkR.w);        
    }

    friend  char4 operator/ (const char4 &rkL, char uiR)
    {
        return char4(rkL.x / uiR, 
                     rkL.y / uiR, 
                     rkL.z / uiR, 
                     rkL.w / uiR);        
    }

    friend  char4 operator/ (const char4 &rkL, float fR)
    {
        float fInv = 1.0f / fR;
        return char4(rkL.x * fInv, 
                     rkL.y * fInv, 
                     rkL.z * fInv, 
                     rkL.w * fInv);        
    }

	char4 &operator/= (const char4 &rkR) 
    { 
        x /= rkR.x;
        y /= rkR.y;
        z /= rkR.z;
        w /= rkR.w;
        return (*this);
    }

    char4 &operator/= (char uiR)
    {
        x /= uiR;
        y /= uiR;
        z /= uiR;
        w /= uiR;
        return (*this);
    }

    char4 &operator/= (float fR)
    {
        float fInv = 1.0f / fR;
        x *= fInv;
        y *= fInv;
        z *= fInv;
        w *= fInv;
        return (*this);
    }

    char4 operator - ( void ) const
    {
        return char4( -x, -y, -z, -w );
    }

    union
    {
        char columns[4];

        struct
        {
            char x;
            char y;
            char z;
            char w;
        };

        struct
        {
            char r;
            char g;
            char b;
            char a;
        };

        struct
        {
            char s;
            char t;
            char u;
            char v;
        };
	};
};

/////////////////////////////////////////////////////////////////////////////////////////

struct ltstr
{
    bool operator()(const char* s1, const char* s2) const
    {
        return strcmp(s1, s2) < 0;
    }
};

struct ltf2
{
    bool operator()(const float2 &rkA, const float2 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y);
    }
};

struct ltf3
{
    bool operator()(const float3 &rkA, const float3 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y &&
                rkA.z < rkB.z);
    }
};

struct ltf4
{
    bool operator()(const float4 &rkA, const float4 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y &&
                rkA.z < rkB.z &&
                rkA.w < rkB.w);
    }
};

struct eqi2
{
    bool operator()(const int2 &rkA, const int2 &rkB) const
    {
        return (rkA.x == rkB.x && 
                rkA.y == rkB.y);
    }
};

struct lti2
{
    bool operator()(const int2 &rkA, const int2 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y);
    }
};

struct lti3
{
    bool operator()(const int3 &rkA, const int3 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y &&
                rkA.z < rkB.z);
    }
};

struct lti4
{
    bool operator()(const int4 &rkA, const int4 &rkB) const
    {
        return (rkA.x < rkB.x && 
                rkA.y < rkB.y && 
                rkA.z < rkB.z &&
                rkA.w < rkB.w);
    }
};



////////////////////////////////////////////////////////////////////////////////

#endif
