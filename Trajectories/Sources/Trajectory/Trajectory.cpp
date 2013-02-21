//---------------------------------------------------------------------------
//
//	File: Trajectory.cpp
//
//  Abstract: A class to compute trajectories using an OpenCL kernel
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
//  Copyright (c) 2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#include <iostream>

//---------------------------------------------------------------------------

#include "OpenCLKit.h"
#include "Trajectory.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const int   kFParamCount = 4;
static const int   kBufferCount = 5;
static const int   kFloatSize   = sizeof(float);

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

class TrajectoryStruct
{
	public:
		size_t           mnBufferSize;
		size_t           mnBufferCount;
		size_t           mnGlobalWorkSize;
		float            mnTimeMax;
		float            maKFParam[kFParamCount];
		float           *mpKResult[kBufferCount];
		OpenCL::Buffer  *mpKBuffer[kBufferCount];
		OpenCL::Kernel  *mpKernel;
};

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------
//
// Create buffer objects and then acquire buffer memories from OpenCL.
//
//---------------------------------------------------------------------------

static bool TrajectoryBuffersCreate(OpenCL::Program *pProgram,
									TrajectoryStruct *pTrajectory)
{
	bool bBuffersCreated = true;
	
	size_t nBufferIndex = 0;
	
	// Compute the expected buffer size.
	
	pTrajectory->mnBufferCount = pTrajectory->mnTimeMax / pTrajectory->maKFParam[1];
	pTrajectory->mnBufferSize  = pTrajectory->mnBufferCount * kFloatSize;
	
	// Acquire the memory buffers for the kernels
	//
	// NOTE: On a successful return if the expected buffer size was not POT,
	//       a POT buffer size will be acquired.
	
	while( bBuffersCreated  && ( nBufferIndex < kBufferCount ) )  
	{
		pTrajectory->mpKBuffer[nBufferIndex] = new OpenCL::Buffer(pProgram);
		
		bBuffersCreated = pTrajectory->mpKBuffer[nBufferIndex] != NULL;
		
		if( bBuffersCreated )
		{
			bBuffersCreated = bBuffersCreated && ( pTrajectory->mpKBuffer[nBufferIndex]->Acquire(nBufferIndex,
																								 pTrajectory->mnBufferSize) );
		} // if
		
		nBufferIndex++;
	} // while
	
	return( bBuffersCreated );
} // TrajectoryBuffersCreate

//---------------------------------------------------------------------------
//
// Create arrays for reading back the compute results from the kernel.
//
//---------------------------------------------------------------------------

static bool TrajectoryArraysCreate(TrajectoryStruct *pTrajectory)
{
	bool bArrayCreated = true;
	
	size_t nArrayIndex = 0;
	size_t nArrayCount = pTrajectory->mnBufferCount;
	
	while( bArrayCreated  && ( nArrayIndex < kBufferCount ) )  
	{
		pTrajectory->mpKResult[nArrayIndex] = new float[nArrayCount];
		
		bArrayCreated = pTrajectory->mpKResult[nArrayIndex] != NULL;
		
		if( bArrayCreated )
		{
			std::memset(pTrajectory->mpKResult[nArrayIndex], 0, pTrajectory->mnBufferSize);		
		} // if
		
		nArrayIndex++;
	} // while
	
	return( bArrayCreated );
} // TrajectoryArraysCreate

//---------------------------------------------------------------------------
//
// Instantiate an OpenCL kernel object from a program object.
//
//---------------------------------------------------------------------------

static inline bool TrajectoryKernelsCreate(OpenCL::Program *pProgram,
										   TrajectoryStruct *pTrajectory)
{
	pTrajectory->mpKernel = new OpenCL::Kernel(pProgram);

	return( pTrajectory->mpKernel != NULL );
} // TrajectoryKernelsCreate

//---------------------------------------------------------------------------
//
// Set the global dimensions for the execution
//
//---------------------------------------------------------------------------

static inline void TrajectorySetGlobalWorkSize(TrajectoryStruct *pTrajectory)
{
	// Get the actual buffer size, which if it wasn't POT, now it is

	size_t nBufferSize = pTrajectory->mpKBuffer[0]->GetBufferSize();

	// Compute the actual number of elements based on POT buffer size

	size_t nBufferCount = nBufferSize / kFloatSize;
	
	// Set the global work size
	
	pTrajectory->mnGlobalWorkSize = nBufferCount;
} // TrajectorySetGlobalWorkSize

//---------------------------------------------------------------------------
//
// Create an opaque trajectory data object by,
//
// (1) acquiring a program from OpenCL,
// (2) creating a kernel object, 
// (3) acquiring a kernel from OpenCL,
// (4) creating buffer objects, 
// (5) acquiring buffer memories from OpenCL,
// (6) creating arrays for readback,
// (7) setting global dimensions for the execution.
//
//---------------------------------------------------------------------------

static TrajectoryStruct *TrajectoryCreate(OpenCL::Program *pProgram, 
										  const float nTimeMax, 
										  const float nTimeDelta)
{
	TrajectoryStruct *pTrajectory = new TrajectoryStruct;
	
	if( pTrajectory != NULL )
	{
		// Maximum length of time for the simulation
		
		pTrajectory->mnTimeMax = nTimeMax;
		
		// Initialize parameters for this trajectory
		
		pTrajectory->maKFParam[0] = 0.0f;
		pTrajectory->maKFParam[1] = nTimeDelta;
		pTrajectory->maKFParam[2] = 0.0f;
		pTrajectory->maKFParam[3] = 0.0f;
		
		// Acquire an OpenCL program from an instantiated program object
		
		if( pProgram->Acquire() )
		{
			TrajectoryKernelsCreate(pProgram, pTrajectory);
			TrajectoryBuffersCreate(pProgram, pTrajectory);
			TrajectoryArraysCreate(pTrajectory);
			TrajectorySetGlobalWorkSize(pTrajectory);
		} // if
	} // if
	
	return( pTrajectory );
} // TrajectoryCreate

//---------------------------------------------------------------------------
//
// Release trajectory data object; along with its kernels, buffers, and
// arrays.
//
//---------------------------------------------------------------------------

static bool TrajectoryRelease(TrajectoryStruct *pTrajectory)
{
	if( pTrajectory != NULL )
	{
		size_t i;
		
		for( i = 0; i < kBufferCount; i++ )
		{
			if( pTrajectory->mpKResult[i] != NULL ) 
			{
				delete [] pTrajectory->mpKResult[i];
			} // if
			
			if( pTrajectory->mpKBuffer[i] != NULL ) 
			{
				delete pTrajectory->mpKBuffer[i];
			} // if
		} // for
		
		if( pTrajectory->mpKernel != NULL ) 
		{
			delete pTrajectory->mpKernel;
		} // if
		
		delete pTrajectory;
	} // if
} // TrajectoryRelease

//---------------------------------------------------------------------------
//
// Bind the buffers to this kernel
//
//---------------------------------------------------------------------------

static bool TrajectoryBindBuffers(TrajectoryStruct *pTrajectory)
{
	bool bBuffersBound = true;
	
	size_t nBufferIndex = 0;
	
	while( bBuffersBound && ( nBufferIndex < kBufferCount ) )
	{
		bBuffersBound = bBuffersBound && pTrajectory->mpKernel->BindBuffer( pTrajectory->mpKBuffer[nBufferIndex] );
		
		nBufferIndex++;
	} // for
	
	return( bBuffersBound );
} // TrajectoryBindBuffers

//---------------------------------------------------------------------------
//
// Bind the constant float parameters to this kernel
//
//---------------------------------------------------------------------------

static bool TrajectoryBindParameters(TrajectoryStruct *pTrajectory)
{
	bool bParametersBound = true;
	
	size_t nParamIndex = 0;
	
	while( bParametersBound && ( nParamIndex < kFParamCount ) )
	{
		bParametersBound = bParametersBound && pTrajectory->mpKernel->BindParameter(nParamIndex+5, 
																					kFloatSize, 
																					&pTrajectory->maKFParam[nParamIndex]);
		
		nParamIndex++;
	} // while
	
	return( bParametersBound );
} // TrajectoryBindParameters

//---------------------------------------------------------------------------
//
// Read back the results that were computed on the device
//
//---------------------------------------------------------------------------

static bool TrajectoryReadBuffers(TrajectoryStruct *pTrajectory)
{
	bool bReadBuffers = true;
	
	size_t nBufferIndex = 0;
	
	while( bReadBuffers && ( nBufferIndex < kBufferCount ) )
	{
		bReadBuffers = bReadBuffers  && pTrajectory->mpKBuffer[nBufferIndex]->Read(pTrajectory->mnBufferSize,
																				   pTrajectory->mpKResult[nBufferIndex]);
		
		nBufferIndex++;
	} // while
	
	return( bReadBuffers );
} // TrajectoryReadBuffers

//---------------------------------------------------------------------------
//
// Execute the kernel once
//
//---------------------------------------------------------------------------

static inline bool TrajectoryExecuteKernel(TrajectoryStruct *pTrajectory)
{
	return( pTrajectory->mpKernel->Execute( &pTrajectory->mnGlobalWorkSize ) );
} // TrajectoryExecuteKernel

//---------------------------------------------------------------------------
//
// Print the results to the standard output device.
//
//---------------------------------------------------------------------------

static void TrajectoryLog(TrajectoryStruct *pTrajectory)
{
	size_t  i;
	float   t = 0.0f;
	
	std::cout << ">> BEGIN" << std::endl;

    for( i = 0; i < pTrajectory->mnBufferCount; i++ )
    {
		t = i * pTrajectory->maKFParam[1];
		
        std::cout << ">>      Time: t = " << t << std::endl;
        std::cout << "    Position: ( " << pTrajectory->mpKResult[0][i] << ", " << pTrajectory->mpKResult[1][i] << " )" << std::endl;
		std::cout << "    Velocity: ( " << pTrajectory->mpKResult[2][i] << ", " << pTrajectory->mpKResult[3][i] << " )" << std::endl;
        std::cout << "       speed: || v(t) || = " << pTrajectory->mpKResult[4][i] << std::endl;
	} // for

	std::cout << ">> END" << std::endl;
} // TrajectoryLog

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------

Trajectory::Trajectory(const std::string &rProgramSource, 
					   const float nTimeMax, 
					   const float nTimeDelta) : OpenCL::Program(rProgramSource)
{
	mpTrajectory = TrajectoryCreate(this, nTimeMax, nTimeDelta);
} // Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

Trajectory::~Trajectory()
{
	TrajectoryRelease(mpTrajectory);
} // Destructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

bool Trajectory::Acquire(const std::string &rkernelName)
{
	bool bFlagIsValid = false;
	
	// Set the work dimension of an OpenCL kernel
	
	mpTrajectory->mpKernel->SetWorkDimension(rkernelName, 1);

	// Get a compute kernel from OpenCL
	
	bFlagIsValid = mpTrajectory->mpKernel->Acquire(rkernelName);
	
	// Bind the buffers associated to this kernel
	
	if( bFlagIsValid )
	{
		bFlagIsValid = TrajectoryBindBuffers(mpTrajectory);
	} // if

	return( bFlagIsValid );
} // Acquire

//---------------------------------------------------------------------------
//
// Last parameter can be the initial angle or the initial height, depending
// on the acquired lernel.
//
//---------------------------------------------------------------------------

bool Trajectory::Compute(const float nInitialTime,
						 const float nInitialSpeed,
						 const float nInitialParam)
{
	bool computed = false;
	
	// Initialize the constant parameters to the kernel

	mpTrajectory->maKFParam[0] = nInitialTime;
	mpTrajectory->maKFParam[2] = nInitialSpeed;
	mpTrajectory->maKFParam[3] = nInitialParam;
	
	// Bind the constant parameters to the kernel
	
	if( TrajectoryBindParameters(mpTrajectory) )
	{
		// Execute the kernel
		
		if( TrajectoryExecuteKernel(mpTrajectory) )
		{
			this->Flush();
			
			// Readback the results
			
			computed = TrajectoryReadBuffers(mpTrajectory);
		} // if
	} // if
	
    return( computed );
} // Compute

//---------------------------------------------------------------------------

void Trajectory::Log()
{
	TrajectoryLog(mpTrajectory);
} // Log

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

const float *Trajectory::PositionX() const
{
	return( mpTrajectory->mpKResult[0] );
} // PositionX

//---------------------------------------------------------------------------

const float *Trajectory::PositionY() const
{
	return( mpTrajectory->mpKResult[1] );
} // PositionY

//---------------------------------------------------------------------------

const float *Trajectory::VelocityX() const
{
	return( mpTrajectory->mpKResult[2] );
} // VelocityX

//---------------------------------------------------------------------------

const float *Trajectory::VelocityY() const
{
	return( mpTrajectory->mpKResult[3] );
} // VelocityY

//---------------------------------------------------------------------------

const float *Trajectory::Speed() const
{
	return( mpTrajectory->mpKResult[4] );
} // Speed

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
