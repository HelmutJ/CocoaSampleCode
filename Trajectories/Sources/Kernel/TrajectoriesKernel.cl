//---------------------------------------------------------------------------
//
//	File: TrajectoriesKernel.cl
//
//  Abstract: Kernels to compute various trajectory forms
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
//  license, under Apple'v1 copyrights in this original Apple software (the
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
//  Copyright (c) 2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#define g (9.81f)

//---------------------------------------------------------------------------
//
// Compute trajectory when target and launch point are at the same level.
// Inputs are the initial time, time delta, initial speed, and the initial
// angle.  Outputs are the position vector, velocity vector, and speed.
// This kernel uses the parametric representation of projectile trajectory.
// To recover equations in the documentation use back substitution.
//
//---------------------------------------------------------------------------

__kernel void Trajectory1( 
	__global float *x, 
    __global float *y, 
    __global float *vx, 
    __global float *vy, 
    __global float *v, 
	const float t0,
	const float delta,
	const float v0,
	const float angle)
{
	int gid = get_global_id(0);
	
	float t1 = gid * delta + t0;
	float v1 = g * t1;
	float v2 = v0 * cos( angle );
	float v3 = v0 * sin( angle );
	float v4 = 2.0f * v3;
	float v5 = v4 - v1;
	float v6 = v0 * v0 - v1 * v5;

	x[gid]  = v2 * t1;
	y[gid]  = 0.5f * v5 * t1;
	vx[gid] = v2;
	vy[gid] = v3 - v1;
	v[gid]  = sqrt(v6);
} // Trajectory1

//---------------------------------------------------------------------------
//
// Compute trajectory when projectile is dropped from a moving system.
// Inputs are the initial time, time delta, initial speed, and the initial
// height.  Outputs are the position vector, velocity vector, and speed.
// This kernel uses the parametric representation of projectile trajectory.
// To recover equations in the documentation use back substitution.
//
//---------------------------------------------------------------------------

__kernel void Trajectory2(
    __global float *x, 
    __global float *y, 
	__global float *vx, 
    __global float *vy, 
    __global float *v,
	const float t0,
	const float delta,
	const float v0,
	const float height)
{
	int gid = get_global_id(0);
	
	float t1 = gid * delta + t0;
	float v1 = g * t1;
	float v2 = v0 * v0 + v1 * v1;

	x[gid]  = v0 * t1;
	y[gid]  = height - 0.5 * v1 * t1;
	vx[gid] = v0;
	vy[gid] = -v1;
	v[gid]  = sqrt(v2);
} // Trajectory2

//---------------------------------------------------------------------------
