//---------------------------------------------------------------------------
//
//	File: OpenCLKernel.cpp
//
//  Abstract: A utility class to manage OpenCL kernels
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
#include <map>

//---------------------------------------------------------------------------

#include <OpenCL/opencl.h>

//---------------------------------------------------------------------------

#include "OpenCLKernel.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

using namespace OpenCL;

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const size_t kOpenCLBufferSize = sizeof(cl_mem);

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

typedef std::map<std::string,cl_uint>    OpenCLWorkDimMap;
typedef std::map<std::string,cl_kernel>  OpenCLKernelMap;

typedef OpenCLWorkDimMap::iterator   OpenCLWorkDimMapIterator;
typedef OpenCLKernelMap::iterator    OpenCLKernelMapIterator;

//---------------------------------------------------------------------------

class OpenCL::KernelStruct
{
public:
	size_t             mnLocalDomainSize;
	cl_int             mnError;
	cl_device_id       mnDeviceId;
	cl_command_queue   mpCommandQueue;
	cl_program         mpProgram;
	
	OpenCLWorkDimMap         maWorkDimMap;		// Per kernel work dimension associative array
	OpenCLKernelMap          maKernelMap;		// Kernels associated array
	OpenCLKernelMapIterator  mpKernelMapIter;	// Kernel associative array iterator
};

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Kernel

//---------------------------------------------------------------------------
//
// The core of the OpenCL execution model is defined by how the kernels 
// execute. When a kernel is submitted for execution by the host, an 
// index space is defined. An instance of the kernel executes for each 
// point in this index space. This kernel instance is called a work-item 
// and is identified by its point in the index space, which provides a 
// global ID for the work-item. Each work-item executes the same code but 
// the specific execution pathway through the code and the data operated 
// upon can vary per work-item.
//
// Work-items are organized into work-groups. The work-groups provide a 
// more coarse-grained decomposition of the index space.	Work-groups 
// are assigned a unique work-group ID with the same dimensionality as 
// the index space used for the work-items. Work-items are assigned a 
// unique local ID within a work-group so that a single work-item can 
// be uniquely identified by its global ID or by a combination of its 
// local ID and work-group ID. The work-items in a given work-group 
// execute concurrently on the processing elements of a single compute 
// unit.
//
//---------------------------------------------------------------------------
//
// For a complete discussion of OpenCL Kernel APIs refer to, 
//
// http://www.khronos.org/registry/cl/specs/opencl-1.0.33.pdf
//
//---------------------------------------------------------------------------

static bool OpenCLKernelCreate(const std::string &rKernelName,
							   OpenCL::KernelStruct *pKernel)
{
	const char *pKernelName = rKernelName.c_str();
	
	cl_kernel pKernelMem = clCreateKernel(pKernel->mpProgram, 
										  pKernelName, 
										  &pKernel->mnError);
	
	bool bCreatedKernel = ( pKernelMem != NULL ) && ( pKernel->mnError == CL_SUCCESS );
	
	if( !bCreatedKernel )
	{
		std::cerr << ">> ERROR: OpenCL Kernel - Failed to create a compute kernel!" << std::endl;
	} // if
	else 
	{
		// Insert the allocated kernel memory object into the associative array
		
		pKernel->maKernelMap.insert(std::make_pair(rKernelName,pKernelMem));
		
		// Check to see if now you can find the kernel memory object
		
		pKernel->mpKernelMapIter = pKernel->maKernelMap.find(rKernelName);
		
		// If the end of the associative arry was reached then the memory 
		// object was not inserted
		
		if( pKernel->mpKernelMapIter == pKernel->maKernelMap.end() )
		{
			std::cerr << ">> ERROR: OpenCL Kernel - Failed to insert the kernel \"" << rKernelName << "\" into the map!" << std::endl;
		} // if
	} // else
	
	return( bCreatedKernel );
} // OpenCLKernelCreate

//---------------------------------------------------------------------------

static inline bool OpenCLKernelSetParameter(OpenCL::KernelStruct *pKernel,
											const cl_uint nParamIndex,
											const size_t nParamSize,
											const void *pParam)
{
    pKernel->mnError = clSetKernelArg(pKernel->mpKernelMapIter->second,  
									  nParamIndex, 
									  nParamSize, 
									  pParam);
	
	bool bParamSet = pKernel->mnError == CL_SUCCESS;
	
    if( !bParamSet )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to set kernel arguments!" << std::endl;
    } // if
	
	return( bParamSet );
} // OpenCLKernelSetParameter

//---------------------------------------------------------------------------

static inline bool OpenCLKernelEnqueueNDRange(OpenCL::KernelStruct *pKernel,
											  const size_t *pGlobalWorkOffset,
											  const size_t *pGlobalWorkSize,
											  const size_t *pLocalWorkSize)
{
	cl_uint nWorkDim = pKernel->maWorkDimMap[pKernel->mpKernelMapIter->first];
	
	pKernel->mnError = clEnqueueNDRangeKernel(pKernel->mpCommandQueue, 
											  pKernel->mpKernelMapIter->second, 
											  nWorkDim, 
											  pGlobalWorkOffset, 
											  pGlobalWorkSize,
											  pLocalWorkSize, 
											  0, 
											  NULL, 
											  NULL);
	
	bool bEnqueued = pKernel->mnError == CL_SUCCESS;
	
	if( !bEnqueued )
	{
		std::cerr << ">> ERROR: OpenCL Kernel - Failed to execute kernel!" << std::endl;
	} // if
	
	return( bEnqueued );
} // OpenCLKernelEnqueueNDRange

//---------------------------------------------------------------------------

static inline bool OpenCLKernelGetWorkGroupSize( OpenCL::KernelStruct *pKernel )
{
    pKernel->mnError = clGetKernelWorkGroupInfo(pKernel->mpKernelMapIter->second, 
												pKernel->mnDeviceId, 
												CL_KERNEL_WORK_GROUP_SIZE, 
												sizeof(size_t), 
												&pKernel->mnLocalDomainSize,
												NULL);
	
	bool bGotKernelWGS = pKernel->mnError == CL_SUCCESS;
	
    if( !bGotKernelWGS )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to retrieve kernel work group info!" << std::endl;
    } // if
	
	return( bGotKernelWGS );
} // OpenCLKernelGetWorkGroupSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Misc.

//---------------------------------------------------------------------------
//
// Execute the kernel using the global work offset, global work size,
// and local work size.  If the input local work size was NULL, then
// determine the local domain size of the device.
//
//---------------------------------------------------------------------------

static bool OpenCLKernelExecute(OpenCL::KernelStruct *pKernel,
								const size_t *pGlobalWorkOffset,
								const size_t *pGlobalWorkSize,
								const size_t *pLocalWorkSize)
{
	bool bKernelExeced = false;
	
	if( pLocalWorkSize == NULL )
	{
		// Get the maximum work group size for executing the kernel on the device
		
		bKernelExeced = OpenCLKernelGetWorkGroupSize( pKernel );
		
		if( bKernelExeced )
		{
			bKernelExeced = OpenCLKernelEnqueueNDRange(pKernel,
													   pGlobalWorkOffset,
													   pGlobalWorkSize,
													   &pKernel->mnLocalDomainSize);
		} // if
	} // if
	else 
	{
		bKernelExeced = OpenCLKernelEnqueueNDRange(pKernel,
												   pGlobalWorkOffset,
												   pGlobalWorkSize,
												   pLocalWorkSize);
	} // else
	
	return( bKernelExeced );
} // OpenCLKernelExecute

//---------------------------------------------------------------------------
//
// Acquire a kernel object.  If the kernel object was previously acquired,
// then return its pointer.
//
//---------------------------------------------------------------------------

static bool OpenCLKernelAcquire(const std::string &rKernelName,
								OpenCL::KernelStruct *pKernel)
{
	bool bKernelAcquired = false;
	
	if( rKernelName.length() )
	{
		OpenCLKernelMapIterator pKernelMapIterEnd = pKernel->maKernelMap.end();
		
		pKernel->mpKernelMapIter = pKernel->maKernelMap.find(rKernelName);
		
		if( pKernel->mpKernelMapIter == pKernelMapIterEnd )
		{
			bKernelAcquired = OpenCLKernelCreate(rKernelName, pKernel );
		} // if
		else 
		{
			bKernelAcquired = pKernel->mpKernelMapIter != pKernelMapIterEnd;
		} // else
	} // if
	else 
	{
		std::cerr << ">> ERROR: OpenCL Kernel - Invalid kernel name!" << std::endl;
	} // else
	
	return( bKernelAcquired );
} // OpenCLKernelAcquire

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Memory

//---------------------------------------------------------------------------
//
// Release the kernel object memory structure.
//
//---------------------------------------------------------------------------

static void OpenCLKernelRelease( OpenCL::KernelStruct *pKernel )
{
	if( pKernel != NULL )
	{
		OpenCLKernelMapIterator  pKernelMapPos;	
		OpenCLKernelMapIterator  pKernelMapPosBegin = pKernel->maKernelMap.begin();
		OpenCLKernelMapIterator  pKernelMapPosEnd   = pKernel->maKernelMap.end();	
		
		for(pKernelMapPos = pKernelMapPosBegin; 
			pKernelMapPos != pKernelMapPosEnd; 
			++pKernelMapPos )
		{
			if( pKernelMapPos->second )
			{
				clReleaseKernel(pKernelMapPos->second);
			} // if
		} // for
		
		pKernel->maKernelMap.clear();
		pKernel->maWorkDimMap.clear();
		
		delete pKernel;
	} // if
} // OpenCLKernelRelease

//---------------------------------------------------------------------------
//
// Clone kernels' work dimension associative array.
//
//---------------------------------------------------------------------------

static void OpenCLKernelWorkDimMapClone(OpenCL::KernelStruct *pSrcKernel,
										OpenCL::KernelStruct *pDstKernel) 
{
	OpenCLWorkDimMapIterator  pSrcWorkDimMapPos;	
	OpenCLWorkDimMapIterator  pSrcWorkDimMapPosBegin = pSrcKernel->maWorkDimMap.begin();
	OpenCLWorkDimMapIterator  pSrcWorkDimMapPosEnd   = pSrcKernel->maWorkDimMap.end();	
	
	for(pSrcWorkDimMapPos =  pSrcWorkDimMapPosBegin; 
		pSrcWorkDimMapPos != pSrcWorkDimMapPosEnd; 
		++pSrcWorkDimMapPos )
	{
		pDstKernel->maWorkDimMap.insert(std::make_pair(pSrcWorkDimMapPos->first,
													   pSrcWorkDimMapPos->second));
	} // for
} // OpenCLKernelWorkDimMapClone

//---------------------------------------------------------------------------
//
// Clone all kernels in the associative array.
//
//---------------------------------------------------------------------------

static bool OpenCLKernelMapClone(OpenCL::KernelStruct *pSrcKernel,
								 OpenCL::KernelStruct *pDstKernel) 
{
	OpenCLKernelMapIterator  pSrcKernelMapPos;	
	OpenCLKernelMapIterator  pSrcKernelMapPosBegin = pSrcKernel->maKernelMap.begin();
	OpenCLKernelMapIterator  pSrcKernelMapPosEnd   = pSrcKernel->maKernelMap.end();	
	
	for(pSrcKernelMapPos =  pSrcKernelMapPosBegin; 
		pSrcKernelMapPos != pSrcKernelMapPosEnd; 
		++pSrcKernelMapPos )
	{
		OpenCLKernelAcquire(pSrcKernelMapPos->first, pDstKernel);
	} // for
} // OpenCLKernelMapClone

//---------------------------------------------------------------------------
//
// Clone a kernel structure.
//
//---------------------------------------------------------------------------

static bool OpenCLKernelClone(OpenCL::KernelStruct *pSrcKernel,
							  OpenCL::KernelStruct *pDstKernel) 
{
	bool bKernelsCopied = false;
	
	pDstKernel = new OpenCL::KernelStruct;
	
	if( pDstKernel != NULL )
	{
		pDstKernel->mnLocalDomainSize = pSrcKernel->mnLocalDomainSize;
		pDstKernel->mnDeviceId        = pSrcKernel->mnDeviceId;
		pDstKernel->mpCommandQueue    = pSrcKernel->mpCommandQueue;
		pDstKernel->mpProgram         = pSrcKernel->mpProgram;
		pDstKernel->mpKernelMapIter   = pSrcKernel->mpKernelMapIter;
		
		OpenCLKernelWorkDimMapClone(pSrcKernel, pDstKernel);
		OpenCLKernelMapClone(pSrcKernel, pDstKernel);
		
		bKernelsCopied = true;
	} // if
	
	return( bKernelsCopied );
} // OpenCLKernelClone

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------
//
// Construct a kernel object from a program object alias.
//
//---------------------------------------------------------------------------

Kernel::Kernel( const Program &rProgram )
{
	mpKernel =  new OpenCL::KernelStruct;
	
	if( mpKernel != NULL )
	{
		mpKernel->mnLocalDomainSize = 0;
		mpKernel->mnDeviceId        = rProgram.GetDeviceId();
		mpKernel->mpCommandQueue    = rProgram.GetCommandQueue();
		mpKernel->mpProgram         = rProgram.GetProgram();
	} // if
} // Constructor

//---------------------------------------------------------------------------
//
// Construct a kernel object from a program object reference.
//
//---------------------------------------------------------------------------

Kernel::Kernel( const Program *pProgram )
{
	mpKernel =  new OpenCL::KernelStruct;
	
	if( mpKernel != NULL )
	{
		mpKernel->mnLocalDomainSize = 0;
		mpKernel->mnDeviceId        = pProgram->GetDeviceId();
		mpKernel->mpCommandQueue    = pProgram->GetCommandQueue();
		mpKernel->mpProgram         = pProgram->GetProgram();
	} // if
} // Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Copy Constructor

//---------------------------------------------------------------------------
//
// Construct a deep copy of a kernel object from another. 
//
//---------------------------------------------------------------------------

Kernel::Kernel( const Kernel &rKernel ) 
{
	if( rKernel.mpKernel != NULL )
	{
		OpenCLKernelClone( rKernel.mpKernel, mpKernel );
	} // if
} // Copy Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Assignment Operator

//---------------------------------------------------------------------------
//
// Construct a deep copy of a kernel object from another using the 
// assignment operator.
//
//---------------------------------------------------------------------------

Kernel &Kernel::operator=(const Kernel &rKernel)
{
	if( ( this != &rKernel ) && ( rKernel.mpKernel != NULL ) )
	{
		OpenCLKernelRelease( mpKernel );
		OpenCLKernelClone( rKernel.mpKernel, mpKernel );
	} // if
	
	return( *this );
} // Assignment Operator

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// Release the kernel object.
//
//---------------------------------------------------------------------------

Kernel::~Kernel()
{
	OpenCLKernelRelease( mpKernel );
} // Destructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------
//
// Set the kernel's work dimension.
//
//---------------------------------------------------------------------------

void Kernel::SetWorkDimension(const std::string &rKernelName, 
							  const cl_uint nWorkDim)
{
	mpKernel->maWorkDimMap[rKernelName] = nWorkDim;
} // SetWorkDimension

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// Using a buffer object alias, bind a buffer object to this kernel, with
// its index and memory.
//
//---------------------------------------------------------------------------

bool Kernel::BindBuffer(Buffer &rBuffer)
{
	const cl_uint   nParamIndex = rBuffer.GetBufferIndex();
	const void     *pParam      = rBuffer.GetBuffer();
	
	return( OpenCLKernelSetParameter(mpKernel, 
									 nParamIndex,
									 kOpenCLBufferSize, 
									 &pParam) );
} // BindBuffer

//---------------------------------------------------------------------------
//
// Using a buffer object reference, bind a buffer object to this kernel,
// with its index and memory.
//
//---------------------------------------------------------------------------

bool Kernel::BindBuffer(Buffer *pBuffer)
{
	const cl_uint   nParamIndex = pBuffer->GetBufferIndex();
	const void     *pParam      = pBuffer->GetBuffer();
	
	return( OpenCLKernelSetParameter(mpKernel, 
									 nParamIndex,
									 kOpenCLBufferSize, 
									 &pParam) );
} // BindBuffer

//---------------------------------------------------------------------------
//
// Bind a parameter to this kernel, using its index and size.
//
//---------------------------------------------------------------------------

bool Kernel::BindParameter(const cl_uint nParamIndex,
						   const size_t nParamSize)
{
	return( OpenCLKernelSetParameter(mpKernel, 
									 nParamIndex, 
									 nParamSize, 
									 NULL) );
} // BindParameter

//---------------------------------------------------------------------------
//
// Bind a parameter to this kernel; using its index, size, and memory 
// contents.
//
//---------------------------------------------------------------------------

bool Kernel::BindParameter(const cl_uint nParamIndex,
						   const size_t nParamSize,
						   const void *pParam)
{
	return( OpenCLKernelSetParameter(mpKernel, 
									 nParamIndex, 
									 nParamSize, 
									 pParam) );
} // BindParameter

//---------------------------------------------------------------------------
//
// After kernel work dimension is set, acquire a named kernel from an
// OpenCL program.
//
//---------------------------------------------------------------------------

bool Kernel::Acquire( const std::string &rKernelName )
{
	return( OpenCLKernelAcquire(rKernelName,mpKernel) );
} // Acquire

//---------------------------------------------------------------------------
//
// For a detailed discussion on global and local work size refer to the
// OpenCL documentation:
//
// http://www.khronos.org/registry/cl/specs/opencl-1.0.33.pdf
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// Excute an acquired kernel using a global work size.
//
//---------------------------------------------------------------------------

bool Kernel::Execute(const size_t *pGlobalWorkSize)
{
	return( OpenCLKernelExecute(mpKernel, 
								NULL, 
								pGlobalWorkSize, 
								NULL) );
} // Execute

//---------------------------------------------------------------------------
//
// Excute an acquired kernel using a global work offset and size.
//
//---------------------------------------------------------------------------

bool Kernel::Execute(const size_t *pGlobalWorkOffset,
					 const size_t *pGlobalWorkSize)
{
	return( OpenCLKernelExecute(mpKernel, 
								pGlobalWorkOffset, 
								pGlobalWorkSize, 
								NULL) );
} // Execute

//---------------------------------------------------------------------------
//
// Excute an acquired kernel using a global work offset and size, and the
// local work size.
//
//---------------------------------------------------------------------------

bool Kernel::Execute(const size_t *pGlobalWorkOffset,
					 const size_t *pGlobalWorkSize,
					 const size_t *pLocalWorkSize)
{
	return( OpenCLKernelExecute(mpKernel, 
								pGlobalWorkOffset, 
								pGlobalWorkSize, 
								pLocalWorkSize) );
} // Execute

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
