//
// File:       compute_engine.h
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

#ifndef __COMPUTE_ENGINE_H__
#define __COMPUTE_ENGINE_H__

#define odd(x) (x%2)

#include <map>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <OpenGL/OpenGL.h>
#include <OpenCL/opencl.h>

#include "compute_types.h"

/////////////////////////////////////////////////////////////////////////////

class ComputeEngine
{

public:

    enum DeviceType
    {
        DEVICE_TYPE_CPU            = CL_DEVICE_TYPE_CPU,
        DEVICE_TYPE_GPU            = CL_DEVICE_TYPE_GPU,
        DEVICE_TYPE_DEFAULT        = CL_DEVICE_TYPE_DEFAULT,
        DEVICE_TYPE_ALL            = CL_DEVICE_TYPE_ALL        
    };
   
    enum MemFlags
    {
        MEM_READ_WRITE             = CL_MEM_READ_WRITE,
        MEM_WRITE_ONLY             = CL_MEM_WRITE_ONLY,
        MEM_READ_ONLY              = CL_MEM_READ_ONLY,
        MEM_USE_HOST_PTR           = CL_MEM_USE_HOST_PTR,
        MEM_COPY_HOST_PTR          = CL_MEM_COPY_HOST_PTR
    };

    enum ChannelOrder
    {
        R                          = CL_R,
        A                          = CL_A,
        RG                         = CL_RG,
        RA                         = CL_RA,
        RGB                        = CL_RGB,
        RGBA                       = CL_RGBA,
        ARGB                       = CL_ARGB
    };

    enum ChannelType 
    {
        SNORM_INT8                 = CL_SNORM_INT8,
        SNORM_INT16                = CL_SNORM_INT16,
        UNORM_INT8                 = CL_UNORM_INT8,
        UNORM_INT16                = CL_UNORM_INT16,
        SIGNED_INT8                = CL_SIGNED_INT8,
        SIGNED_INT16               = CL_SIGNED_INT16,
        SIGNED_INT32               = CL_SIGNED_INT32,
        UNSIGNED_INT8              = CL_UNSIGNED_INT8,
        UNSIGNED_INT16             = CL_UNSIGNED_INT16,
        UNSIGNED_INT32             = CL_UNSIGNED_INT32,
        HALF_FLOAT                 = CL_HALF_FLOAT,
        FLOAT                      = CL_FLOAT
    };

    ComputeEngine();
    ~ComputeEngine();
    
    bool connect(
        DeviceType eDeviceType = DEVICE_TYPE_ALL, 
        uint uiCount = 1,
        bool bUseOpenGLContext = false);
    
    bool disconnect();

    bool createProgramFromFile(
        const char* acProgramName,
        const char* acFileName,
        const char* acMacroDefinitions = 0);
        
    bool createProgramFromSourceString(
        const char* acProgramName,
        const char* aSourceString,
        const char* acMacroDefinitions = 0);        
        
    bool setKernelArg(
        const char* acKernelName,
        uint uiIndex,  
        void *pvArgsValue, 
        size_t ptArgsSize);
        
    bool setKernelArgs(
        const char* acKernelName,
        uint uiNumArgs, 
        uint *piArgsIndices, 
        void **pvArgsValue, 
        size_t *ptArgsSize);

    uint getKernelArgCount(
        const char* acKernelName);
        
    bool createKernel(
        const char* acProgramName,
        const char* acKernelName);
        
    bool executeKernel(
        const char* acKernelName,
        uint uiDeviceId,
        size_t* uiGlobalDim,
        size_t* uiLocalDim,
        uint uiDimCount);
        
    bool createBuffer(
        const char* acMemObjName, 
        MemFlags eMemFlags, 
        size_t kBytes);

    bool readBuffer(
        const char* acMemObjName,
        uint uiDeviceIndex,
        uint uiStart,
        size_t kBytes,
        void* pvData);
        
    bool writeBuffer(
        const char* acMemObjName,
        uint uiDeviceIndex,
        uint uiStart,
        size_t kBytes,
        void* pvData);
    
    cl_mem getBuffer(
        const char* acMemObjName);
    
    void dumpBuffer(
        const char* acMemObjName,
        uint uiDeviceIndex,
        uint uiStart,
        size_t kBytes,
        uint uiDataType,
        uint uiComponents);
        
    bool createImage2D(
        const char* acMemObjName,
        MemFlags eMemFlags, 
        ChannelOrder eOrder,
        ChannelType eType,
        uint uiWidth,
        uint uiHeight,
        uint uiRowPitch = 0,
        void* pvData = 0);
    
    bool readImage(
        const char* acMemObjName,
        uint uiDeviceIndex,
        uint uiX, uint uiY, uint uiZ,
        uint uiWidth, uint uiHeight, uint uiDepth,
        uint uiRowPitch, uint uiSlicePitch,
        void* pvData);
    
    bool writeImage(
        const char* acMemObjName,
        uint uiDeviceIndex,
        uint uiX, uint uiY, uint uiZ,
        uint uiWidth, uint uiHeight, uint uiDepth,
        uint uiRowPitch, uint uiSlicePitch,
        void* pvData);
        
    cl_kernel getKernelObject(
        const char* acKernelName);
        
    cl_mem getMemObject(
        const char* acMemObjName);

    bool clearMemory(
        const char* acMemObjName,
        uint uiValue,
        size_t kBytes);

    bool clearMemory(
        cl_mem kMemObject,
        uint uiValue,
        size_t kBytes);
        
    bool createGLBufferReference(
        const char* acMemObjName,
        MemFlags eMemFlags, 
        uint uiBufferId);
        
    bool attachGLBuffer(
        cl_mem kMemObject,
        uint uiDeviceIndex = 0);

    bool detachGLBuffer(
        cl_mem kMemObject,
        uint uiDeviceIndex = 0);

    bool attachGLBuffer(
        const char* acMemObjName,
        uint uiDeviceIndex = 0);

    bool detachGLBuffer(
        const char* acMemObjName,
        uint uiDeviceIndex = 0);

    bool createGLTexture2DReference(
        const char* acMemObjName,
        MemFlags eMemFlags, 
        GLenum eTarget,
        GLint iMipLevel,
        GLuint uiTextureId);
            
    bool swapMemObjects(
        const char* acMemObjNameA,
        const char* acMemObjNameB);        
    
    bool barrier(
        uint uiDeviceIndex= 0);

    bool flush(
        uint uiDeviceIndex= 0);

    bool finish(
        uint uiDeviceIndex = 0);

    uint getChannelCount(
        ChannelOrder eOrder);
        
    uint getContextDeviceCount();
    unsigned long getMaxAllocationSizeInBytes();
    uint getEstimatedWorkGroupSize(const char* acKernelName, uint uiDeviceIndex = 0 );
    
    bool isConnected()			{ return m_kContext != 0; }
    cl_context getContext()		{ return m_kContext; }
    uint getDeviceCount()       { return m_uiDeviceCount; }
    cl_device_id getDeviceId(uint uiIndex) { return (uiIndex < m_uiDeviceCount) ? (m_akDeviceIds[uiIndex]) : (cl_device_id)0; }

protected:

    typedef std::map<const char*, cl_kernel>::iterator KernelMapIter;
    typedef std::map<const char*, cl_program>::iterator ProgramMapIter;
    typedef std::map<const char*, cl_mem>::iterator MemObjectMapIter;
    
    static unsigned int ms_uiMaxDeviceCount;
    
    unsigned int      m_uiDeviceCount;
    cl_context        m_kContext;
    cl_device_id*     m_akDeviceIds;
    cl_command_queue* m_akCommandQueues;

	std::map<const char*, cl_program, ltstr> m_akPrograms;
	std::map<const char*, cl_kernel, ltstr> m_akKernels;
	std::map<const char*, cl_mem, ltstr> m_akMemObjects;

private:
    ComputeEngine(const ComputeEngine &rkCopy);
    
};


/////////////////////////////////////////////////////////////////////////////

#endif
