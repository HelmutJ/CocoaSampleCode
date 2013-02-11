//
// File:       compute_math.h
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

#ifndef __COMPUTE_MATH__
#define __COMPUTE_MATH__

#include "compute_types.h"
#include <math.h>

////////////////////////////////////////////////////////////////////////////////

#define CL_SDK_ANALYTIC_PI                (4.0*atan( 1.0 ))

static const float CL_SDK_PI_F32          = ( float ) ( CL_SDK_ANALYTIC_PI );
static const float CL_SDK_TWO_PI_F32      = ( float ) ( 2.0 * CL_SDK_ANALYTIC_PI);
static const float CL_SDK_HALF_PI_F32     = ( float ) ( 0.5 * CL_SDK_ANALYTIC_PI);
static const float CL_SDK_INV_PI_F32      = ( float ) ( 1.0 / CL_SDK_ANALYTIC_PI);
static const float CL_SDK_INV_TWO_PI_F32  = ( float ) ( 1.0 / 2.0 * CL_SDK_ANALYTIC_PI);
static const float CL_SDK_DEG_TO_RAD_F32  = ( float ) ( CL_SDK_ANALYTIC_PI / 180.0 );
static const float CL_SDK_RAD_TO_DEG_F32  = ( float ) ( 180.0 / CL_SDK_ANALYTIC_PI );
static const float CL_SDK_QUARTER_PI_F32  = ( float ) ( CL_SDK_ANALYTIC_PI / 4.0 );
static const float CL_SDK_EIGHTH_PI_F32   = ( float ) ( CL_SDK_ANALYTIC_PI / 8.0 );
static const float CL_SDK_PI_SQUARED_F32  = ( float ) ( CL_SDK_ANALYTIC_PI * CL_SDK_ANALYTIC_PI );
static const float CL_SDK_PI_INVERSE_F32  = ( float ) ( 1.0 / CL_SDK_ANALYTIC_PI );
static const float CL_SDK_PI_OVER_180_F32 = ( float ) ( CL_SDK_ANALYTIC_PI / 180 );
static const float CL_SDK_PI_DIV_180_F32  = ( float ) ( 180 / CL_SDK_ANALYTIC_PI );

////////////////////////////////////////////////////////////////////////////////

float 
radians(float n);

float 
degrees(float n);

////////////////////////////////////////////////////////////////////////////////

float 
min(float a, float b);

float 
max(float a, float b);

float 
clamp(float c, float a, float b);

float
fast_sqrt(const float fV);
    
float
fast_rsqrt(const float fV);

float
sqrf(const float fV);

////////////////////////////////////////////////////////////////////////////////

int 
max(int a, int b);

int 
min(int a, int b);

int 
clamp(int c, int a, int b);

////////////////////////////////////////////////////////////////////////////////

uint 
max(uint a, uint b);

uint 
min(uint a, uint b);

int 
dilate_even(const int iX);

int
dilate_odd(const int iX);

int
morton_index2d(const int row, const int col);

int
morton_index2d_padded(const int row, const int col, const int size);

uint 
nearest_power_of_two(uint x);

uint 
next_power_of_two(uint x);

int 
divide_up(int a, int b);

////////////////////////////////////////////////////////////////////////////////

float 
distance(const float2 &rkVA, const float2 &rkVB);

float2
fast_normalize(const float2& rkV);

float2
normalize(const float2& rkV, float fZeroEpsilon = 1e-06f);

float 
dot(const float2 &rkVA, const float2 &rkVB);

float2
max(const float2 &rkVA, const float2 &rkVB);

float2
min(const float2 &rkVA, const float2 &rkVB);

float2
mix(const float2 &rkVA, const float2 &rkVB, float fT);

float2 
clamp(const float2 &rkV, float fMin, float fMax);

float2
floor(const float2 &rkV);

float
length(const float2 &rkV);

////////////////////////////////////////////////////////////////////////////////

float3
fast_normalize(const float3& rkV);

float3 
normalize(const float3& rkV, float fZeroEpsilon = 1e-06f);
    
float 
dot(const float3 &rkVA, const float3 &rkVB);

float3 
cross(const float3 &rkVA, const float3 &rkVB);

float3
max(const float3 &rkVA, const float3 &rkVB);

float3
min(const float3 &rkVA, const float3 &rkVB);

float3
mix(const float3 &rkVA, const float3 &rkVB, float fT);

float
length(const float3 &rkV);

float 
distance(const float3 &rkVA, const float3 &rkVB);

float3 
clamp(const float3 &rkV, float fMin, float fMax);

float3
floor(const float3 &rkV);

////////////////////////////////////////////////////////////////////////////////

float4 
fast_normalize(const float4& rkV);

float4 
normalize(const float4& rkV, float fZeroEpsilon = 1e-06f);

float 
dot(const float4 &rkVA, const float4 &rkVB);

float4
max(const float4 &rkVA, const float4 &rkVB);

float4
min(const float4 &rkVA, const float4 &rkVB);

float4
mix(const float4 &rkVA, const float4 &rkVB, float fT);

float
length(const float4 &rkV);

float 
distance(const float4 &rkVA, const float4 &rkVB);

float4
floor(const float4 &rkV);

////////////////////////////////////////////////////////////////////////////////

float16 
inverse(const float16 &rkM, float fEpsilon = 1e-06f);

float16
transpose(const float16 &rkM);

float16
translation(
    const float3 &rkV);

float16
scaling(
    const float3 &rkV);
        
float16
rotation(
    const float3 &rkAxis, 
    float fRadians);
    
float16 
ortho(
    float fLeft, float fRight, 
    float fBottom, float fTop, 
    float fNear, float fFar);

float16
perspective(
    float fFov, float fAspect, 
    float fNear, float fFar);
    
float16 
perspective(
    float fLeft, float fRight, 
    float fBottom, float fTop, 
    float fNear, float fFar, 
    bool bInfinite);
    
float16 
look(
    const float3 &rkPosition,
    const float3 &rkViewDirection,
    const float3 &rkUpDirection);

float16 
lookat(
    const float3 &rkPosition,
    const float3 &rkTarget,
    const float3 &rkUpDirection);
    
////////////////////////////////////////////////////////////////////////////////

#endif
