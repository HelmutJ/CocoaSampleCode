//---------------------------------------------------------------------------
//
//	File: Buffer.cpp
//
//  Abstract: A utility class to create an OpenCL memory buffer
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

#include "OpenCLBuffer.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

using namespace OpenCL;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

class OpenCL::BufferStruct
{
	public:
		cl_context        mpContext;
		cl_command_queue  mpCommandQueue;
		cl_mem_flags      mnBufferFlags;
		cl_int            mnError;
		cl_mem            mpBuffer;
		cl_uint           mnBufferIndex;
		size_t            mnBufferSize;
		bool              mbIsBlocking;
};

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Math

//---------------------------------------------------------------------------
//
// Get the next power of 2.  If already a power of 2 then returns the same
// input value.
//
//---------------------------------------------------------------------------

static size_t GetPOTSize(const size_t nSize) 
{
	size_t nPOTSize = nSize;
	
	if( nPOTSize != 0 )
	{
		nPOTSize--;
		
		size_t i;
		size_t iMax = sizeof(size_t)*CHAR_BIT;
		
		for( i = 1; i < iMax; i <<= 1 )
		{
			nPOTSize = nPOTSize | nPOTSize >> i;
		} // for
		
		nPOTSize++;
	} // if
	else
	{
		nPOTSize = 1;
	} // else
	
	
	return( nPOTSize );
} // GetPOTSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Buffer

//---------------------------------------------------------------------------
//
// For a complete discussion of OpenCL buffer APIs refer to,
//
// http://www.khronos.org/registry/cl/specs/opencl-1.0.33.pdf
//
//---------------------------------------------------------------------------

static inline bool OpenCLCreateBuffer(OpenCL::BufferStruct *pBuffer,
									  void *pHost)
{
    pBuffer->mpBuffer = clCreateBuffer(pBuffer->mpContext, 
									   pBuffer->mnBufferFlags, 
									   pBuffer->mnBufferSize, 
									   pHost, 
									   &pBuffer->mnError);
	
	bool bBufferCreated = ( pBuffer->mpBuffer != NULL ) && ( pBuffer->mnError == CL_SUCCESS );
	
    if( !bBufferCreated )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to create buffer!" << std::endl;
    } // if
	
	return( bBufferCreated ); 
} // OpenCLCreateBuffer

//---------------------------------------------------------------------------

static inline bool OpenCLReleaseBufferMemory(OpenCL::BufferStruct *pBuffer)
{
	cl_int nBufferRefCount = 0;
	
	pBuffer->mnError = clGetMemObjectInfo(pBuffer->mpBuffer, 
										  CL_MEM_REFERENCE_COUNT, 
										  sizeof(cl_int), 
										  &nBufferRefCount,
										  NULL);
	
	bool bValidRefCount = ( nBufferRefCount ) && ( pBuffer->mnError == CL_SUCCESS );
	
	if( !bValidRefCount )
	{
		std::cerr << ">> ERROR: OpenCL Kernel - Failed to validate the reference count!" << std::endl;
	} // if
	else
	{
		clReleaseMemObject(pBuffer->mpBuffer);
	} // else
	
	return( bValidRefCount );
} // OpenCLReleaseBufferMemory

//---------------------------------------------------------------------------

static void OpenCLReleaseBuffer(OpenCL::BufferStruct *pBuffer)
{
	if( pBuffer != NULL )
	{
		OpenCLReleaseBufferMemory( pBuffer );
		
		delete pBuffer;
		
		pBuffer = NULL;
	} // if
} // OpenCLReleaseBuffer

//---------------------------------------------------------------------------

static inline bool OpenCLEnqueueReadBuffer(OpenCL::BufferStruct *pBuffer,
										   const size_t nBufferSize, 
										   void *pHost)
{
    pBuffer->mnError = clEnqueueReadBuffer(pBuffer->mpCommandQueue, 
										   pBuffer->mpBuffer, 
										   pBuffer->mbIsBlocking, 
										   0, 
										   nBufferSize, 
										   pHost, 
										   0, 
										   NULL, 
										   NULL);
	
	bool bReadSource = pBuffer->mnError == CL_SUCCESS;
	
    if( !bReadSource )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to Read from the device!" << std::endl;
    } // if
	
	return( bReadSource ); 
} // OpenCLEnqueueReadBuffer

//---------------------------------------------------------------------------

static inline bool OpenCLEnqueueWriteBuffer(OpenCL::BufferStruct *pBuffer,
											const size_t nBufferSize, 
											const void * const pHost)
{
    pBuffer->mnError = clEnqueueWriteBuffer(pBuffer->mpCommandQueue, 
											pBuffer->mpBuffer, 
											pBuffer->mbIsBlocking, 
											0, 
											nBufferSize, 
											pHost, 
											0, 
											NULL, 
											NULL);
	
	bool bWroteSource = pBuffer->mnError == CL_SUCCESS;
	
    if( !bWroteSource )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to write to source array!" << std::endl;
    } // if
	
	return( bWroteSource ); 
} // OpenCLEnqueueWriteBuffer

//---------------------------------------------------------------------------

static inline bool OpenCLGetBufferSize(OpenCL::BufferStruct *pBuffer,
									   cl_mem pBufferMem,
									   size_t  *pBufferSize)
{
    pBuffer->mnError = clGetMemObjectInfo(pBufferMem, 
										  CL_MEM_SIZE, 
										  sizeof(size_t), 
										  pBufferSize,
										  NULL);
	
	bool bGotBufferSize = pBuffer->mnError == CL_SUCCESS;
	
    if( !bGotBufferSize )
    {
        std::cerr << ">> ERROR: OpenCL Kernel - Failed to retrieve the buffer size!" << std::endl;
    } // if
	
	return( bGotBufferSize );
} // OpenCLGetBufferSize

//---------------------------------------------------------------------------

static inline bool OpenCLEnqueueCopyBuffer(OpenCL::BufferStruct *pBuffer,
										   const size_t nBufferSize, 
										   cl_mem pSrcBuffer)
{
	pBuffer->mnError = clEnqueueCopyBuffer(pBuffer->mpCommandQueue, 
										   pSrcBuffer,
										   pBuffer->mpBuffer, 
										   0,
										   0,
										   nBufferSize, 
										   0,
										   NULL,
										   NULL);
	
	bool bCopiedSource = pBuffer->mnError == CL_SUCCESS;
	
	if( !bCopiedSource )
	{
		std::cerr << ">> ERROR: OpenCL Kernel - Failed to make a copy of the source array!" << std::endl;
	} // if
	
	return( bCopiedSource ); 
} // OpenCLEnqueueCopyBuffer

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Opaque Structure

//---------------------------------------------------------------------------
//
// Copy from the OpenCL memory associated with the source buffer into the 
// OpenCL memory instance variable of the buffer structure.  If the buffer 
// copy size that is passed in, is 0, then make a full copy from source to 
// destination.
//
//---------------------------------------------------------------------------

static bool OpenCLCopyBuffer(OpenCL::BufferStruct *pBuffer,
							 cl_mem pMemBuffer, 
							 const size_t nBufferCopySize)
{
	bool    bBufferCopied = false;
	size_t  nBufferSize   = 0;
	
	if( nBufferCopySize == 0 )
	{
		bBufferCopied = OpenCLGetBufferSize(pBuffer, 
											pMemBuffer,
											&nBufferSize);
	} // if
	else
	{
		bBufferCopied = true;
		nBufferSize   = nBufferCopySize;
	} // else
	
	if( bBufferCopied )
	{
		bBufferCopied = OpenCLEnqueueCopyBuffer(pBuffer, 
												nBufferSize, 
												pMemBuffer);
	} // if
	
	return( bBufferCopied );
} // OpenCLCopyBuffer

//---------------------------------------------------------------------------
//
// Clone all buffer attributes.
//
//---------------------------------------------------------------------------

static bool OpenCLCloneBuffer(OpenCL::BufferStruct *pDstBuffer,
							  OpenCL::BufferStruct *pSrcBuffer,
							  const size_t nBufferCopySize)
{
	bool  bBufferCopied = false;
	
	pDstBuffer->mpContext      = pSrcBuffer->mpContext;
	pDstBuffer->mpCommandQueue = pSrcBuffer->mpCommandQueue;
	pDstBuffer->mnError        = CL_SUCCESS;
	pDstBuffer->mpBuffer       = NULL;
	pDstBuffer->mnBufferFlags  = pSrcBuffer->mnBufferFlags;
	pDstBuffer->mnBufferSize   = pSrcBuffer->mnBufferSize;
	pDstBuffer->mnBufferIndex  = pSrcBuffer->mnBufferIndex;
	
	if( OpenCLCreateBuffer(pDstBuffer, NULL) )
	{
		bBufferCopied = OpenCLCopyBuffer(pDstBuffer,
										 pSrcBuffer->mpBuffer,
										 nBufferCopySize);
	} // if
	
	return( bBufferCopied );
} // OpenCLCloneBuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------
//
// Construct a buffer object from a program object alias.
//
//---------------------------------------------------------------------------

Buffer::Buffer( const Program &rProgram )
{
	mpBuffer =  new OpenCL::BufferStruct;
	
	if( mpBuffer != NULL )
	{
		mpBuffer->mpContext      = rProgram.GetContext();
		mpBuffer->mpCommandQueue = rProgram.GetCommandQueue();
		mpBuffer->mnBufferFlags  = CL_MEM_READ_WRITE;
		mpBuffer->mnError        = CL_SUCCESS;
		mpBuffer->mnBufferSize   = 0;
		mpBuffer->mnBufferIndex  = 0;
		mpBuffer->mpBuffer       = NULL;
		mpBuffer->mbIsBlocking   = true;
	} // if
} // Constructor

//---------------------------------------------------------------------------
//
// Construct a buffer object from a program object reference.
//
//---------------------------------------------------------------------------

Buffer::Buffer( const Program *pProgram )
{
	mpBuffer =  new OpenCL::BufferStruct;
	
	if( mpBuffer != NULL )
	{
		mpBuffer->mpContext      = pProgram->GetContext();
		mpBuffer->mpCommandQueue = pProgram->GetCommandQueue();
		mpBuffer->mnError        = CL_SUCCESS;
		mpBuffer->mnBufferFlags  = CL_MEM_READ_WRITE;
		mpBuffer->mnBufferSize   = 0;
		mpBuffer->mnBufferIndex  = 0;
		mpBuffer->mpBuffer       = NULL;
		mpBuffer->mbIsBlocking   = true;
	} // if
} // Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Copy Constructor

//---------------------------------------------------------------------------
//
// Construct a deep copy of a buffer object from another. 
//
//---------------------------------------------------------------------------

Buffer::Buffer( const Buffer &rBuffer ) 
{
	if( rBuffer.mpBuffer != NULL )
	{
		mpBuffer = new OpenCL::BufferStruct;
		
		if( mpBuffer != NULL )
		{
			OpenCLCloneBuffer(mpBuffer, rBuffer.mpBuffer, 0);
		} // if
	} // if
} // Copy Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Assignment Operator

//---------------------------------------------------------------------------
//
// Construct a deep copy of a buffer object from another using the 
// assignment operator.
//
//---------------------------------------------------------------------------

Buffer &Buffer::operator=(const Buffer &rBuffer)
{
	if( ( this != &rBuffer ) && ( rBuffer.mpBuffer != NULL ) )
	{
		OpenCLReleaseBuffer( mpBuffer );
		
		mpBuffer = new OpenCL::BufferStruct;
		
		if( mpBuffer != NULL )
		{
			OpenCLCloneBuffer(mpBuffer, rBuffer.mpBuffer, 0);
		} // if
	} // if
	
	return( *this );
} // Assignment Operator

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// Release the buffer object.
//
//---------------------------------------------------------------------------

Buffer::~Buffer()
{
	OpenCLReleaseBuffer(mpBuffer);
} // Destructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------
//
// Set the buffer to be blocking and read/write.
//
//---------------------------------------------------------------------------

void Buffer::SetDefaults()
{
	mpBuffer->mnBufferFlags   = CL_MEM_READ_WRITE;
	mpBuffer->mbIsBlocking = true;
} // SetDefaults

//---------------------------------------------------------------------------
//
// Set the buffer to be read-only.
//
//---------------------------------------------------------------------------

void Buffer::SetReadOnly()
{
	mpBuffer->mnBufferFlags = CL_MEM_READ_ONLY;
} // SetReadOnly

//---------------------------------------------------------------------------
//
// Set the buffer to be write-only.
//
//---------------------------------------------------------------------------

void Buffer::SetWriteOnly()
{
	mpBuffer->mnBufferFlags = CL_MEM_WRITE_ONLY;
} // SetWriteOnly

//---------------------------------------------------------------------------
//
// Set the buffer to be read/write.
//
//---------------------------------------------------------------------------

void Buffer::SetReadWrite()
{
	mpBuffer->mnBufferFlags = CL_MEM_READ_WRITE;
} // SetReadWrite

//---------------------------------------------------------------------------
//
// Set the buffer to be blocking.
//
//---------------------------------------------------------------------------

void Buffer::SetIsBlocking()
{
	mpBuffer->mbIsBlocking = true;
} // SetIsBlocking

//---------------------------------------------------------------------------
//
// Set the buffer to be non-blocking.
//
//---------------------------------------------------------------------------

void Buffer::SetIsNonBlocking()
{
	mpBuffer->mbIsBlocking = false;
} // SetIsNonBlocking

//---------------------------------------------------------------------------
//
// Get the OpenCL memory buffer.
//
//---------------------------------------------------------------------------

const cl_mem Buffer::GetBuffer() const
{
	return( mpBuffer->mpBuffer );
} // GetBuffer

//---------------------------------------------------------------------------
//
// Get the OpenCL memory buffer size - POT on return.
//
//---------------------------------------------------------------------------

const size_t Buffer::GetBufferSize() const
{
	return( mpBuffer->mnBufferSize );
} // GetBufferSize

//---------------------------------------------------------------------------
//
// Get the OpenCL memory buffer parameter index.
//
//---------------------------------------------------------------------------

const cl_uint Buffer::GetBufferIndex() const
{
	return( mpBuffer->mnBufferIndex );
} // GetBufferIndex

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// Once the buffer attributes have been set, acquire an actual buffer from
// the OpenCL stack.
//
//---------------------------------------------------------------------------

bool Buffer::Acquire(const cl_uint nBufferIndex, 
					 const size_t nBufferSize)
{
	mpBuffer->mnBufferIndex = nBufferIndex;
	mpBuffer->mnBufferSize  = GetPOTSize(nBufferSize);
	
	return( OpenCLCreateBuffer(mpBuffer, NULL) ); 
} // CreateReadOnlyBuffer

//---------------------------------------------------------------------------
//
// Once the buffer attributes have been set, acquire an actual buffer from
// the OpenCL stack with the contents of host memory.
//
//---------------------------------------------------------------------------

bool Buffer::Acquire(const cl_uint nBufferIndex, 
					 const size_t nBufferSize, 
					 void *pHost)
{
	mpBuffer->mnBufferIndex = nBufferIndex;
	mpBuffer->mnBufferSize  = GetPOTSize(nBufferSize);
	
	return( OpenCLCreateBuffer(mpBuffer, pHost) ); 
} // Create

//---------------------------------------------------------------------------
//
// Write to the buffer object with the contents of host memory.
//
//---------------------------------------------------------------------------

bool Buffer::Write(const size_t nBufferSize, 
				   const void * const pHost)
{
	return( OpenCLEnqueueWriteBuffer(mpBuffer, 
									 nBufferSize, 
									 pHost) ); 
} // Write

//---------------------------------------------------------------------------
//
// Read from the buffer object with the contents of host memory.
//
//---------------------------------------------------------------------------

bool Buffer::Read(const size_t nBufferSize, 
				  void *pHost)
{
	return( OpenCLEnqueueReadBuffer(mpBuffer, 
									nBufferSize, 
									pHost) ); 
} // Read

//---------------------------------------------------------------------------
//
// Make a full copy of the memory associated with the source buffer object.
//
//---------------------------------------------------------------------------

bool Buffer::Copy(Buffer &rSrcBuffer)
{
	cl_mem pSrcBuffer = rSrcBuffer.GetBuffer();
	
	return( OpenCLCopyBuffer(mpBuffer, pSrcBuffer, 0) );
} // Copy

//---------------------------------------------------------------------------
//
// Make a copy of the memory associated with the source buffer object.
//
//---------------------------------------------------------------------------

bool Buffer::Copy(const size_t nBufferSize, 
				  Buffer &rSrcBuffer)
{
	bool bBufferCopied = false;
	
	if( nBufferSize > 0 )
	{
		cl_mem pSrcBuffer = rSrcBuffer.GetBuffer();
		
		bBufferCopied = OpenCLCopyBuffer(mpBuffer, pSrcBuffer, nBufferSize );
	} // if
	
	return( bBufferCopied );
} // Copy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
