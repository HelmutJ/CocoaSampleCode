//---------------------------------------------------------------------------
//
//	File: Program.cpp
//
//  Abstract: A utility class to build an OpenCL program
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

#include <OpenCL/opencl.h>

//---------------------------------------------------------------------------

#include "OpenCLProgram.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

using namespace OpenCL;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

class OpenCL::ProgramStruct
{
	public:
		const size_t                 *mpProgramLengths;
		const char                   *mpProgramSource;
		cl_int                        mnError;
		cl_uint                       mnDeviceEntries;
		cl_uint                       mnDeviceCount;
		cl_uint                       mnProgramCount;
		cl_uint                       mnPlatformCount;
		cl_device_type                mnDeviceType;
		cl_platform_id                mnPlatformId;
		cl_device_id                  mnDeviceId;
		cl_context_properties        *mpContextProperties;
		cl_command_queue_properties   mnCmdQueueProperties;
		cl_context                    mpContext;
		cl_command_queue              mpCommandQueue;
		cl_program                    mpProgram;
};

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// For a detailed discussion of OpenCL device, context, command queue, and 
// program APIs refer to the reference,
//
// http://www.khronos.org/registry/cl/specs/opencl-1.0.33.pdf
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Device & Context

//---------------------------------------------------------------------------

static inline bool OpenCLGetPlatformIDs( OpenCL::ProgramStruct *pProgram )
{
	pProgram->mnError = clGetPlatformIDs(pProgram->mnDeviceEntries,
										 &pProgram->mnPlatformId,
										 &pProgram->mnPlatformCount);
	
	bool bGetPlatformIDs = pProgram->mnError == CL_SUCCESS;
	
	if( !bGetPlatformIDs )
	{
		std::cerr << ">> ERROR: OpenCL Program - Failed to get plaform attributes!" << std::endl;
	} // if
	
	return( bGetPlatformIDs );
} // OpenCLGetPlatformIDs

//---------------------------------------------------------------------------

static inline bool OpenCLGetDeviceIDs( OpenCL::ProgramStruct *pProgram )
{
	pProgram->mnError = clGetDeviceIDs(pProgram->mnPlatformId,
									   pProgram->mnDeviceType,
									   pProgram->mnDeviceEntries,
									   &pProgram->mnDeviceId,
									   &pProgram->mnDeviceCount);
	
	bool bGetDeviceIDs = pProgram->mnError == CL_SUCCESS;
	
	if( !bGetDeviceIDs )
	{
		std::cerr << ">> ERROR: OpenCL Program - Failed to create a device group!" << std::endl;
	} // if
	
	return( bGetDeviceIDs );
} // OpenCLGetDeviceIDs

//---------------------------------------------------------------------------

static inline bool OpenCLCreateContext( OpenCL::ProgramStruct *pProgram )
{
    pProgram->mpContext = clCreateContext(pProgram->mpContextProperties, 
										  pProgram->mnDeviceEntries, 
										  &pProgram->mnDeviceId, 
										  NULL, 
										  NULL, 
										  &pProgram->mnError);
	
	bool bCreatedContext = ( pProgram->mpContext != NULL ) && ( pProgram->mnError == CL_SUCCESS );
	
    if( !bCreatedContext )
    {
		std::cerr << ">> ERROR: OpenCL Program - Failed to create a compute context!" << std::endl;
    } // if
	
	return( bCreatedContext );
} // OpenCLCreateContext

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Command Queue

//---------------------------------------------------------------------------

static inline bool OpenCLCommandQueueCreate( OpenCL::ProgramStruct *pProgram )
{
    pProgram->mpCommandQueue = clCreateCommandQueue(pProgram->mpContext, 
													pProgram->mnDeviceId, 
													pProgram->mnCmdQueueProperties, 
													&pProgram->mnError);
	
	bool bCreatedCmdQueue = ( pProgram->mpCommandQueue != NULL ) && ( pProgram->mnError == CL_SUCCESS );
	
    if( !bCreatedCmdQueue )
    {
		std::cerr << ">> ERROR: OpenCL Program - Failed to create a command queue!" << std::endl;
    } // if
	
	return( bCreatedCmdQueue );
} // OpenCLCommandQueueCreate

//---------------------------------------------------------------------------

static inline void OpenCLCommandQueueFlush(OpenCL::ProgramStruct *pProgram)
{
	clFlush(pProgram->mpCommandQueue);
} // OpenCLCommandQueueFlush

//---------------------------------------------------------------------------

static inline void OpenCLCommandQueueFinish(OpenCL::ProgramStruct *pProgram)
{
	clFinish(pProgram->mpCommandQueue);
} // OpenCLCommandQueueFinish

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Program

//---------------------------------------------------------------------------

static inline bool OpenCLProgramCreateWithSource( OpenCL::ProgramStruct *pProgram )
{
    pProgram->mpProgram = clCreateProgramWithSource(pProgram->mpContext, 
													pProgram->mnProgramCount, 
													(const char **)&pProgram->mpProgramSource, 
													pProgram->mpProgramLengths, 
													&pProgram->mnError);
	
	bool bCreatedProgram = ( pProgram->mpProgram != NULL ) && ( pProgram->mnError == CL_SUCCESS );
	
    if( !bCreatedProgram )
    {
        std::cerr << ">> ERROR: OpenCL Program - Failed to create compute program!" << std::endl;
    } // if
	
	return( bCreatedProgram );
} // OpenCLProgramCreateWithSource

//---------------------------------------------------------------------------

static inline bool OpenCLProgramBuild( OpenCL::ProgramStruct *pProgram )
{
    pProgram->mnError = clBuildProgram(pProgram->mpProgram, 
									   0, 
									   NULL, 
									   NULL, 
									   NULL, 
									   NULL);
	
	bool bProgramBuilt = pProgram->mnError == CL_SUCCESS;
	
    if( !bProgramBuilt )
    {
        std::cerr << ">> ERROR: OpenCL Program - Failed to build program executable!" << std::endl;
    } // if
	
	return( bProgramBuilt );
} // OpenCLProgramBuild

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Opaque Structure

//---------------------------------------------------------------------------
//
// Release the OpenCL program, command queue, and context; along with the
// program object.
//
//---------------------------------------------------------------------------

static void OpenCLProgramRelease( OpenCL::ProgramStruct *pProgram )
{
	if( pProgram != NULL )
	{
		if( pProgram->mpProgram != NULL )
		{
			clReleaseProgram(pProgram->mpProgram);
		} // if
		
		if( pProgram->mpCommandQueue != NULL )
		{
			clReleaseCommandQueue(pProgram->mpCommandQueue);
		} // if
		
		if( pProgram->mpContext != NULL )
		{
			clReleaseContext(pProgram->mpContext);
		} // if
		
		delete pProgram;
	} // if
} // OpenCLProgramRelease

//---------------------------------------------------------------------------
//
// Create an OpenCL program by first getting device IDs, command queue, and 
// context.  The create an OpenCL program from a source file.
//
//---------------------------------------------------------------------------

static bool OpenCLProgramCreate(OpenCL::ProgramStruct *pProgram)
{
	bool bFlagIsValid = false;
	
	if( pProgram->mpProgramSource != NULL )
	{
		if( OpenCLGetPlatformIDs(pProgram) )
		{
			if( OpenCLGetDeviceIDs(pProgram) )
			{
				if( OpenCLCreateContext(pProgram) )
				{
					if( OpenCLCommandQueueCreate(pProgram) )
					{
						if( OpenCLProgramCreateWithSource(pProgram) )
						{
							bFlagIsValid = OpenCLProgramBuild(pProgram);
						} // if
					} // if
				} // if
			} // if
		} // if
	} // else
	else
	{
		std::cerr << ">> ERROR: OpenCL Program - Failed to open the file containing the source!" << std::endl;
	} // else

	return( bFlagIsValid );
} // OpenCLProgramCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------
//
// Construct a program object from a program source file.
//
// After instantiating a program object, for now and if you're running on 
// non-NVidia GPUs (e.g. ATI), use the public method 
//
//		SetDeviceType( const cl_device_type nDeviceType ) 
//
// with the device type CL_DEVICE_TYPE_CPU.
//
//---------------------------------------------------------------------------

Program::Program( const std::string &rFileName ) : File( rFileName )
{
	mpProgram =  new OpenCL::ProgramStruct;
	
	if( mpProgram != NULL )
	{
		mpProgram->mnDeviceType         = CL_DEVICE_TYPE_GPU;
		mpProgram->mnDeviceEntries      = 1;
		mpProgram->mnDeviceCount        = 1;
		mpProgram->mnPlatformCount      = 1;
		mpProgram->mnProgramCount       = 1;
		mpProgram->mnCmdQueueProperties = 0;
		mpProgram->mnDeviceId           = NULL;
		mpProgram->mnPlatformId         = NULL;
		mpProgram->mpContextProperties  = NULL;
		mpProgram->mpContext            = NULL;
		mpProgram->mpCommandQueue       = NULL;
		mpProgram->mpProgram            = NULL;
		mpProgram->mpProgramLengths     = NULL;
		mpProgram->mpProgramSource      = this->GetContents();
	} // if
} // Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Copy Constructor

//---------------------------------------------------------------------------
//
// Construct a deep copy of a program object from another. 
//
//---------------------------------------------------------------------------

Program::Program( const Program &rProgram ) : File(rProgram)
{
	if( rProgram.mpProgram != NULL )
	{
		mpProgram = new OpenCL::ProgramStruct;
		
		if( mpProgram != NULL )
		{
			mpProgram->mnDeviceType         = rProgram.mpProgram->mnDeviceType;
			mpProgram->mnDeviceEntries      = rProgram.mpProgram->mnDeviceEntries;
			mpProgram->mnDeviceId           = rProgram.mpProgram->mnDeviceId;
			mpProgram->mnDeviceCount        = rProgram.mpProgram->mnDeviceCount;
			mpProgram->mnPlatformId         = rProgram.mpProgram->mnPlatformId;
			mpProgram->mnPlatformCount      = rProgram.mpProgram->mnPlatformCount;
			mpProgram->mnProgramCount       = rProgram.mpProgram->mnProgramCount;
			mpProgram->mnCmdQueueProperties = rProgram.mpProgram->mnCmdQueueProperties;
			mpProgram->mpContextProperties  = NULL;
			mpProgram->mpContext            = NULL;
			mpProgram->mpCommandQueue       = NULL;
			mpProgram->mpProgram            = NULL;
			mpProgram->mpProgramLengths     = NULL;
			mpProgram->mpProgramSource      = this->GetContents();
			
			OpenCLProgramCreate(mpProgram);
		} // if
	} // if
} // Copy Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Assignment Operator

//---------------------------------------------------------------------------
//
// Construct a deep copy of a program object from another using the 
// assignment operator.
//
//---------------------------------------------------------------------------

Program &Program::operator=(const Program &rProgram)
{
	if( ( this != &rProgram ) && ( rProgram.mpProgram != NULL ) )
	{
		OpenCLProgramRelease( mpProgram );
		
		mpProgram = new OpenCL::ProgramStruct;
		
		if( mpProgram != NULL )
		{
			this->File::operator=(rProgram);
			
			mpProgram->mnDeviceType         = rProgram.mpProgram->mnDeviceType;
			mpProgram->mnDeviceEntries      = rProgram.mpProgram->mnDeviceEntries;
			mpProgram->mnDeviceId           = rProgram.mpProgram->mnDeviceId;
			mpProgram->mnDeviceCount        = rProgram.mpProgram->mnDeviceCount;
			mpProgram->mnPlatformId         = rProgram.mpProgram->mnPlatformId;
			mpProgram->mnPlatformCount      = rProgram.mpProgram->mnPlatformCount;
			mpProgram->mnProgramCount       = rProgram.mpProgram->mnProgramCount;
			mpProgram->mnCmdQueueProperties = rProgram.mpProgram->mnCmdQueueProperties;
			mpProgram->mpContextProperties  = NULL;
			mpProgram->mpContext            = NULL;
			mpProgram->mpCommandQueue       = NULL;
			mpProgram->mpProgram            = NULL;
			mpProgram->mpProgramLengths     = NULL;
			mpProgram->mpProgramSource      = this->GetContents();
			
			OpenCLProgramCreate(mpProgram);
		} // if
	} // if
	
	return( *this );
} // Assignment Operator

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// Release the program object.
//
//---------------------------------------------------------------------------

Program::~Program()
{
	OpenCLProgramRelease( mpProgram );
} // Destructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------
//
// For a detailed discussion of these various attributes refer to,
//
// http://www.khronos.org/registry/cl/specs/opencl-1.0.33.pdf
//
//---------------------------------------------------------------------------

void Program::SetDeviceType( const cl_device_type nDeviceType )
{
	mpProgram->mnDeviceType = nDeviceType;
} // SetDeviceType

//---------------------------------------------------------------------------

void Program::SetDeviceEntries( const cl_uint nEntries )
{
	mpProgram->mnDeviceEntries = nEntries;
} // SetDeviceEntries

//---------------------------------------------------------------------------

void Program::SetContextProperties( cl_context_properties *pContextProperties )
{
	mpProgram->mpContextProperties = pContextProperties;
} // SetContextProperties

//---------------------------------------------------------------------------

void Program::SetCommandQueueProperties( const cl_command_queue_properties nCmdQueueProperties )
{
	mpProgram->mnCmdQueueProperties = nCmdQueueProperties;
} // SetCommandQueueProperties

//---------------------------------------------------------------------------

const cl_device_id Program::GetDeviceId() const
{
	return(mpProgram->mnDeviceId);
} // GetDeviceId

//---------------------------------------------------------------------------

const cl_program Program::GetProgram() const
{
	return(mpProgram->mpProgram);
} // GetProgram

//---------------------------------------------------------------------------

const cl_context Program::GetContext() const
{
	return(mpProgram->mpContext);
} // GetContext

//---------------------------------------------------------------------------

const cl_command_queue Program::GetCommandQueue() const
{
	return(mpProgram->mpCommandQueue);
} // GetCommandQueue

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// After the program attributes have been set, build a program.
//
//---------------------------------------------------------------------------

bool Program::Acquire()
{
    return( OpenCLProgramCreate(mpProgram) );
} // Acquire

//---------------------------------------------------------------------------
//
// Issues all previously queued commands in the command queue to the device.
//
//---------------------------------------------------------------------------

void Program::Flush()
{
    OpenCLCommandQueueFlush(mpProgram);
} // Flush

//---------------------------------------------------------------------------
//
// Blocks until all previously queued commands in the command queue are 
// issued to the device and have completed.
//
//---------------------------------------------------------------------------

void Program::Finish()
{
    OpenCLCommandQueueFinish(mpProgram);
} // Finish

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
