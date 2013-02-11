//
// File:       compute_engine.cpp
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

#include "compute_engine.h"
#include "data_loader.h"
#include "compute_math.h"

#include <assert.h>
#include <math.h>

#include <OpenCL/opencl.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

#define SEPARATOR ("----------------------------------------------------------------------------\n")
#define STRINGIFY(A) #A

////////////////////////////////////////////////////////////////////////////////////////////////////

unsigned int ComputeEngine::ms_uiMaxDeviceCount = 256;

////////////////////////////////////////////////////////////////////////////////////////////////////

static const char*
MemSetKernelSourceString = STRINGIFY(

__kernel void 
cl_memset(__global float *mem, float value, unsigned int count)
{
    int tx = get_global_id(0);
    int ty = get_global_id(1);
    int tz = get_global_id(2);
    int sx = get_global_size(0);
    int sy = get_global_size(1);
    int index = tz * sy * sx + ty * sx + tx;
    if(index >= count)
        return;
    mem[index] = value;
}

);

////////////////////////////////////////////////////////////////////////////////////////////////////

static void
DumpBufferValues(
    const char* acMemObjName,
    void* pvData,
    uint uiStart,
    size_t kBytes,
    uint uiDumpType,
    uint uiDumpComponents)
{
    printf(SEPARATOR);
    
    if(uiDumpType == 1)
    {
        float *afMin = new float[uiDumpComponents];
        float *afMax = new float[uiDumpComponents];
        
        memset(afMin,  999999, sizeof(float) * uiDumpComponents);
        memset(afMax, -999999, sizeof(float) * uiDumpComponents);
        
        uint uiElemCount = (kBytes) / (sizeof(float));
        float* afData = (float*)pvData;
        for(uint i = uiStart; i < uiElemCount / 4; i++)
        {
            for(uint j = 0; j < uiDumpComponents; j++)
            {
                float fValue = afData[i*uiDumpComponents+j];
                afMin[j] = afMin[j] < fValue ? afMin[j] : fValue;
                afMax[j] = afMax[j] > fValue ? afMax[j] : fValue;
            }
            
            printf("%s[%6d]: ", acMemObjName, i);
            for(uint j = 0; j < uiDumpComponents; j++)
                printf("%15.3f ", afData[i*uiDumpComponents+j]);
            printf("\n");
        }
        
        printf("%s:  Count[%6d] ", acMemObjName, uiElemCount / 4);
        printf("Min[");
        for(uint j = 0; j < uiDumpComponents; j++)
            printf("%8.5f ", afMin[j]);
        printf("] Max[");
        for(uint j = 0; j < uiDumpComponents; j++)
            printf("%8.5f ", afMax[j]);
        printf("]\n");
        
        delete [] afMin;
        delete [] afMax;
    }
    else if(uiDumpType == 2)
    {
        uint uiElemCount = (kBytes) / (sizeof(int));
        int* aiData = (int*)pvData;
        for(uint i = uiStart; i < uiElemCount / 4; i++)
        {
            printf("%s[%6d]: ", acMemObjName, i);
            for(uint j = 0; j < uiDumpComponents; j++)
                printf("%6d ", aiData[i*uiDumpComponents+j]);
            printf("\n");
        }
    }
    else if(uiDumpType == 3)
    {
        uint uiElemCount = (kBytes) / (sizeof(uint));
        uint* auiData = (uint*)pvData;
        for(uint i = uiStart; i < uiElemCount / 4; i++)
        {
            printf("%s[%6d]: ", acMemObjName, i);
            for(uint j = 0; j < uiDumpComponents; j++)
                printf("%6d ", auiData[i*uiDumpComponents+j]);
            printf("\n");
        }
    }
    printf(SEPARATOR);
    
}

////////////////////////////////////////////////////////////////////////////////

static int 
LoadProgramSourceFromFile(
    const char *file_name, 
    char **result_string,
    size_t *string_len)
{
	int fd;
	unsigned file_len; 
	struct stat file_status;
	int ret;
	
	*string_len = 0;
	fd = open(file_name, O_RDONLY);
	if (fd == -1) 
	{
		printf("Error opening file %s\n", file_name);
		return -1;
	}
	ret = fstat(fd, &file_status);
	if (ret) 
	{
		printf("Error reading status for file %s\n", file_name);
		return -1;
	}
	file_len = file_status.st_size;
	
	*result_string = new char[file_len+1];
	ret = read(fd, *result_string, file_len);
	if (!ret) 
	{
		printf("Error reading from file %s\n", file_name);
		return -1;
	}
	(*result_string)[file_len] = '\0';
	close(fd);
	
	*string_len = file_len;
	return 0;
}

////////////////////////////////////////////////////////////////////////////////

static void
ReportBuildLog(cl_program kProgram, cl_device_id kDeviceId)
{
	static uint s_uiBufferSize = 4096;
	size_t kLogLength = 0;
	
	char * acBuildLog = new char[s_uiBufferSize];
	memset(acBuildLog, 0, s_uiBufferSize * sizeof(char));
	
    clGetProgramBuildInfo(kProgram, kDeviceId, CL_PROGRAM_BUILD_LOG, sizeof(acBuildLog), acBuildLog, &kLogLength);
    if(strlen(acBuildLog) < 1)
        printf("Compute Engine: Empty Build Log! Unkown Error!\n");
    
    else
        printf("%s\n", acBuildLog);
    
    delete[] acBuildLog;

    printf(SEPARATOR);
}

////////////////////////////////////////////////////////////////////////////////
    
static bool
GetErrorString(int iError, char** acString, size_t *kStringLength)
{
    const char* acErrorString = 0;
    
	switch(iError)
	{
    case(CL_SUCCESS):
        break;
    case(CL_DEVICE_NOT_FOUND):
        acErrorString = "Device not found!";
        break;
    case(CL_DEVICE_NOT_AVAILABLE):
        acErrorString = "Device not available!";
        break;
    case(CL_COMPILER_NOT_AVAILABLE):
        acErrorString = "Device compiler not available!";
        break;
    case(CL_MEM_OBJECT_ALLOCATION_FAILURE):
        acErrorString = "Memory object allocation failure!";
        break;
    case(CL_OUT_OF_RESOURCES):
        acErrorString = "Out of resources!";
        break;
    case(CL_OUT_OF_HOST_MEMORY):
        acErrorString = "Out of host memory!";
        break;
    case(CL_PROFILING_INFO_NOT_AVAILABLE):
        acErrorString = "Profiling information not available!";
        break;
    case(CL_MEM_COPY_OVERLAP):
        acErrorString = "Overlap detected in memory copy operation!";
        break;
    case(CL_IMAGE_FORMAT_MISMATCH):
        acErrorString = "Image format mismatch detected!";
        break;
    case(CL_IMAGE_FORMAT_NOT_SUPPORTED):
        acErrorString = "Image format not supported!";
        break;
    case(CL_INVALID_VALUE):
        acErrorString = "Invalid value!";
        break;
    case(CL_INVALID_DEVICE_TYPE):
        acErrorString = "Invalid device type!";
        break;
    case(CL_INVALID_DEVICE):
        acErrorString = "Invalid device!";
        break;
    case(CL_INVALID_CONTEXT):
        acErrorString = "Invalid context!";
        break;
    case(CL_INVALID_QUEUE_PROPERTIES):
        acErrorString = "Invalid queue properties!";
        break;
    case(CL_INVALID_COMMAND_QUEUE):
        acErrorString = "Invalid command queue!";
        break;
    case(CL_INVALID_HOST_PTR):
        acErrorString = "Invalid host pointer address!";
        break;
    case(CL_INVALID_MEM_OBJECT):
        acErrorString = "Invalid memory object!";
        break;
    case(CL_INVALID_IMAGE_FORMAT_DESCRIPTOR):
        acErrorString = "Invalid image format descriptor!";
        break;
    case(CL_INVALID_IMAGE_SIZE):
        acErrorString = "Invalid image size!";
        break;
    case(CL_INVALID_SAMPLER):
        acErrorString = "Invalid sampler!";
        break;
    case(CL_INVALID_BINARY):
        acErrorString = "Invalid binary!";
        break;
    case(CL_INVALID_BUILD_OPTIONS):
        acErrorString = "Invalid build options!";
        break;
    case(CL_INVALID_PROGRAM):
        acErrorString = "Invalid program object!";
        break;
    case(CL_INVALID_PROGRAM_EXECUTABLE):
        acErrorString = "Invalid program executable!";
        break;
    case(CL_INVALID_KERNEL_NAME):
        acErrorString = "Invalid kernel name!";
        break;
    case(CL_INVALID_KERNEL):
        acErrorString = "Invalid kernel object!";
        break;
    case(CL_INVALID_ARG_INDEX):
        acErrorString = "Invalid index for kernel argument!";
        break;
    case(CL_INVALID_ARG_VALUE):
        acErrorString = "Invalid value for kernel argument!";
        break;
    case(CL_INVALID_ARG_SIZE):
        acErrorString = "Invalid size for kernel argument!";
        break;
    case(CL_INVALID_KERNEL_ARGS):
        acErrorString = "Invalid kernel arguments!";
        break;
    case(CL_INVALID_WORK_DIMENSION):
        acErrorString = "Invalid work dimension!";
        break;
    case(CL_INVALID_WORK_GROUP_SIZE):
        acErrorString = "Invalid work group size!";
        break;
    case(CL_INVALID_GLOBAL_OFFSET):
        acErrorString = "Invalid global offset!";
        break;
    case(CL_INVALID_EVENT_WAIT_LIST):
        acErrorString = "Invalid event wait list!";
        break;
    case(CL_INVALID_EVENT):
        acErrorString = "Invalid event!";
        break;
    case(CL_INVALID_OPERATION):
        acErrorString = "Invalid operation!";
        break;
    case(CL_INVALID_GL_OBJECT):
        acErrorString = "Invalid OpenGL object!";
        break;
    case(CL_INVALID_BUFFER_SIZE):
        acErrorString = "Invalid buffer size!";
        break;
    default:
        acErrorString = "Unknown error!";
        break;
    };
    
    if(!acErrorString)
        return false;
    
    size_t kLength = strlen(acErrorString);
    char * acResult = new char[kLength + 1];
    strcpy(acResult, acErrorString);

    (*acString) = acResult;
    (*kStringLength) = kLength;
    return true;
}

static void
ReportError(int iError)
{
    char *acErrorString = 0;
    size_t kLength;
    
    GetErrorString(iError, &acErrorString, &kLength);
    
    if(kLength)
    {
        printf("OpenCL Error[%d]: %s\n", iError, acErrorString);
        delete [] acErrorString;
    }
}

////////////////////////////////////////////////////////////////////////////////

ComputeEngine::ComputeEngine() :
    m_uiDeviceCount(0),
    m_kContext(0),
    m_akDeviceIds(0),
    m_akCommandQueues(0)
{
    m_akPrograms.clear();
    m_akKernels.clear();
    m_akMemObjects.clear();
}

ComputeEngine::~ComputeEngine()
{
    if(m_kContext)
        disconnect();
}

bool
ComputeEngine::connect(
    DeviceType eDeviceType, 
    uint uiCount,
    bool bUseOpenGLContext)
{   
    assert(uiCount < ms_uiMaxDeviceCount);

    if(m_kContext)
        disconnect();

    int iError = 0;
    
    size_t kReturnedSize;
    unsigned int uiDeviceCount;
    cl_device_id akAvailableDeviceIds[ms_uiMaxDeviceCount];
    cl_device_type kRequestedDeviceType = (cl_device_type)eDeviceType;
               
    if(bUseOpenGLContext)
    {
        printf(SEPARATOR);
        printf("Compute Engine: Using active OpenGL context...\n");
    
        CGLContextObj kCGLContext = CGLGetCurrentContext();              
        CGLShareGroupObj kCGLShareGroup = CGLGetShareGroup(kCGLContext);
        
        cl_context_properties akProperties[] = { 
            CL_CONTEXT_PROPERTY_USE_CGL_SHAREGROUP_APPLE, 
            (cl_context_properties)kCGLShareGroup, 0 
        };
            
        // Create a context from a CGL share group
        //
        m_kContext = clCreateContext(akProperties, 0, 0, clLogMessagesToStdoutAPPLE, 0, 0);
    }
    else
    {
        uint uiAvailableDeviceCount = 0;
        iError = clGetDeviceIDs(NULL, kRequestedDeviceType, uiCount, akAvailableDeviceIds, &uiAvailableDeviceCount);
        if (iError != CL_SUCCESS)
        {
            printf("Error: Failed to locate compute device!\n");
            return false;
        }      

        m_kContext = clCreateContext(0, uiAvailableDeviceCount, akAvailableDeviceIds, NULL, NULL, &iError);
    }
    
    if (!m_kContext)
    {
        printf("Compute Engine: Failed to create compute context!\n");
        return false;
    }
    
    iError = clGetContextInfo(m_kContext, CL_CONTEXT_DEVICES, 
                              sizeof(akAvailableDeviceIds), akAvailableDeviceIds, 
                              &kReturnedSize);

    if(iError != CL_SUCCESS || kReturnedSize < 1)
    {
        printf("Compute Engine: Error: Failed to retrieve compute devices for context!\n");
        return false;
    }

    uiDeviceCount = kReturnedSize / sizeof(cl_device_id);
    m_akDeviceIds = new cl_device_id[uiDeviceCount];
    m_akCommandQueues = new cl_command_queue[uiDeviceCount];
    if(!m_akDeviceIds || !m_akCommandQueues)
    {
        printf("Compute Engine: Error: Failed to allocate device ids!\n");
        return false;
    }        
    
    cl_device_type kDeviceType;	
    for(uint i = 0; i < uiDeviceCount; i++) 
    {
        m_akDeviceIds[i] = 0;
        clGetDeviceInfo(akAvailableDeviceIds[i], CL_DEVICE_TYPE, sizeof(cl_device_type), &kDeviceType, &kReturnedSize);
        if(kRequestedDeviceType == kDeviceType) 
        {
            m_akDeviceIds[m_uiDeviceCount++] = akAvailableDeviceIds[i];
        }	
    }

    for(uint i = 0; i < m_uiDeviceCount; i++)
    {
        cl_char acVendorName[1024] = {0};
        cl_char acDeviceName[1024] = {0};

        iError = clGetDeviceInfo(m_akDeviceIds[i], CL_DEVICE_VENDOR, sizeof(acVendorName), acVendorName, &kReturnedSize);
        iError|= clGetDeviceInfo(m_akDeviceIds[i], CL_DEVICE_NAME, sizeof(acDeviceName), acDeviceName, &kReturnedSize);
        if (iError != CL_SUCCESS)
        {
            printf("Error: Failed to retrieve device info!\n");
            return false;
        }
    
        printf(SEPARATOR);
        printf("Creating command queue for %s %s...\n", acVendorName, acDeviceName);
        
        m_akCommandQueues[i] = clCreateCommandQueue(m_kContext, m_akDeviceIds[i], 0, &iError);
        if (!m_akCommandQueues[i] || iError)
        {
            printf("Error: Failed to create a command queue!\n");
            return false;
        }
    }

    printf(SEPARATOR);

    m_akPrograms.clear();
    m_akKernels.clear();
    m_akMemObjects.clear();
    return true;
}

bool
ComputeEngine::disconnect()
{
    uint i;
    
    if(m_kContext)
    {
        for(i = 0; i < m_uiDeviceCount; i++)
            clFinish(m_akCommandQueues[i]);
    }
        
    MemObjectMapIter pkMemObjIter;
    for(pkMemObjIter = m_akMemObjects.begin(); pkMemObjIter != m_akMemObjects.end(); pkMemObjIter++)
    {
        if(pkMemObjIter->second)
            clReleaseMemObject(pkMemObjIter->second);
    }
    m_akMemObjects.clear();

    KernelMapIter pkKernelIter;
    for(pkKernelIter = m_akKernels.begin(); pkKernelIter != m_akKernels.end(); pkKernelIter++)
    {
        if(pkKernelIter->second)
            clReleaseKernel(pkKernelIter->second);
    }
    m_akKernels.clear();

    ProgramMapIter pkPgmIter;
    for(pkPgmIter = m_akPrograms.begin(); pkPgmIter != m_akPrograms.end(); pkPgmIter++)
    {
        if(pkPgmIter->second)
            clReleaseProgram(pkPgmIter->second);
    }
    m_akPrograms.clear();

    if(m_akCommandQueues)
    {
        for(uint i; i < m_uiDeviceCount; i++)
            clReleaseCommandQueue(m_akCommandQueues[i]);
            
        delete [] m_akCommandQueues;
        m_akCommandQueues = 0;
    }

    if(m_akDeviceIds)
    {
        delete [] m_akDeviceIds;
        m_akDeviceIds = 0;
    }

    if(m_kContext)
    {
        clReleaseContext(m_kContext);
        m_kContext = 0;
    }
    
    m_uiDeviceCount = 0;
    return true;
}

bool
ComputeEngine::createProgramFromFile(
    const char* acProgramName,
    const char* acFileName,
    const char* acMacroDefinitions)
{
    char* acSourceString = 0;
    size_t uiStringLength;
    
    if(!acProgramName)
        return false;

    if(!acFileName)
        return false;

    printf("Compute Engine: Loading program '%s' from file '%s'...\n", acProgramName, acFileName);
    
    char *acResource = 0;
    uint uiLength = 0;
    FindResourcePath(acFileName, &acResource, &uiLength);
    int iError = LoadProgramSourceFromFile(acResource, &acSourceString, &uiStringLength);
    free(acResource);
    if(iError)
	{
		printf("Compute Engine: Failed to load program source '%s'!\n", acFileName);
		ReportError(iError);
		return false;
	}

    bool bSuccess = false;
    if(acSourceString)
    {
        bSuccess = createProgramFromSourceString(acProgramName, acSourceString, acMacroDefinitions);
        delete [] acSourceString;
    }
    
    return bSuccess;
}

bool
ComputeEngine::createProgramFromSourceString(
    const char* acProgramName,
    const char* acSourceString,
    const char* acMacroDefinitions)    
{
    ProgramMapIter pkPgmIter = m_akPrograms.find(acProgramName);
    if(pkPgmIter != m_akPrograms.end())
    {
        clReleaseProgram(pkPgmIter->second);
        m_akPrograms.erase(pkPgmIter);
    }

    char *acProgramSource = 0; 
    if(acMacroDefinitions)
    {
        acProgramSource = new char[strlen(acSourceString) + strlen(acMacroDefinitions) + 2];
        if(!acProgramSource)
        {
            printf("Error: Failed to allocate program source! %s\n", acProgramName);
            return false;
        }
        acProgramSource[0] = '\0';
        sprintf(acProgramSource, "%s\n%s\n", acMacroDefinitions, acSourceString);
    }
    else
    {
        acProgramSource = new char[strlen(acSourceString) + 1];
        if(!acProgramSource)
        {
            printf("Error: Failed to allocate program source! %s\n", acProgramName);
            return false;
        }
        acProgramSource[0] = '\0';
        sprintf(acProgramSource, "%s\n", acSourceString);
    }

    int iError = CL_SUCCESS;
    cl_program kProgram = clCreateProgramWithSource(m_kContext, 1, (const char **) & acProgramSource, NULL, &iError);
    delete [] acProgramSource;

    if (!kProgram || iError != CL_SUCCESS)
    {
        printf("Error: Failed to create compute program! %s\n", acProgramName);
        ReportError(iError);
        if(kProgram)
            clReleaseProgram(kProgram);
        return false;
    }

    printf(SEPARATOR);
    printf("Building compute program '%s'...\n", acProgramName);
    iError = clBuildProgram(kProgram, m_uiDeviceCount, m_akDeviceIds, NULL, NULL, NULL);
    if (iError != CL_SUCCESS)
    {
        printf("Error: Failed to build program executable!\n");
        ReportError(iError);
        for(uint i = 0; i < m_uiDeviceCount; i++)
        {
            printf("Build log for device '%d':\n", i);
            ReportBuildLog(kProgram, m_akDeviceIds[i]);
        }
        clReleaseProgram(kProgram);
        return false;
    }

    printf(SEPARATOR);
    m_akPrograms[acProgramName] = kProgram;
    return true;
}

bool
ComputeEngine::createKernel(
    const char* acProgramName,
    const char* acKernelName)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter != m_akKernels.end())
    {
        printf("Compute Engine: Releasing existing kernel '%s'...\n", acKernelName);
        clReleaseKernel(pkKernelIter->second);
        m_akKernels.erase(pkKernelIter);
    }    
    
    ProgramMapIter pkPgmIter = m_akPrograms.find(acProgramName);
    if(pkPgmIter == m_akPrograms.end())
        return false;

    cl_program kProgram = pkPgmIter->second;
    
    printf("Compute Engine: Creating kernel '%s' for program '%s'...\n", acKernelName, acProgramName);
    
    int iError = CL_SUCCESS;
    cl_kernel kKernel = clCreateKernel(kProgram, acKernelName, &iError);
    if(!kKernel || iError != CL_SUCCESS)
    {
        printf("Compute Engine: Failed to create kernel '%s'\n", acKernelName);    
        ReportError(iError);
        return false;
    }
    
    m_akKernels[acKernelName] = kKernel;
    return true;
}

uint 
ComputeEngine::getKernelArgCount(
    const char* acKernelName)
{
    uint uiArgCount = 0;
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter == m_akKernels.end())
        return 0;
        
    cl_kernel kKernel = pkKernelIter->second;
    clGetKernelInfo(kKernel, CL_KERNEL_NUM_ARGS, sizeof(uiArgCount),  &uiArgCount, 0);
    return uiArgCount;
}

bool
ComputeEngine::setKernelArg(
    const char* acKernelName,
    uint uiIndex,  
    void *pvArgsValue, 
    size_t ptArgsSize)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter == m_akKernels.end())
        return false;
		
#ifdef DEBUG
	printf("Compute Engine SetKernelArg: %s %d %f (%d)\n", 
		acKernelName, uiIndex, *(float*)pvArgsValue, *(unsigned int*)pvArgsValue);
#endif

    cl_kernel kKernel = pkKernelIter->second;
    
    int iError = clSetKernelArg(kKernel, uiIndex, ptArgsSize, pvArgsValue);
    if(iError)
    {
        printf("Compute Engine: Error setting kernel argument '%d' for '%s'\n", uiIndex, acKernelName);
        ReportError(iError);
        return false;
    }

    return true;
}

bool
ComputeEngine::setKernelArgs(
    const char* acKernelName,
    uint uiNumArgs, 
    uint *piArgsIndices, 
    void **pvArgsValue, 
    size_t *ptArgsSize)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter == m_akKernels.end())
        return false;
       
    cl_kernel kKernel = pkKernelIter->second;
    for( uint i = 0; i < uiNumArgs; i++)
    {
        int iError = clSetKernelArg(kKernel, i, ptArgsSize[i], pvArgsValue[i]);
        if(iError)
        {
            printf("Compute Engine: Error setting kernel args '%s'\n", acKernelName);
            ReportError(iError);
            return false;
        }
    }	    
    return true;
}

bool
ComputeEngine::executeKernel(
    const char* acKernelName,
    uint uiDeviceIndex,
    size_t* auiGlobalDim,
    size_t* auiLocalDim,
    uint uiDimCount)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter == m_akKernels.end())
        return false;
                
    cl_kernel kKernel = pkKernelIter->second;
    
#ifdef DEBUG    
    printf("Compute Engine: Execute Kernel '%s': Global[%d, %d]  Local[%d, %d]\n",
        acKernelName, 
        auiGlobalDim[0], uiDimCount > 1 ? auiGlobalDim[1] : 0, 
        auiLocalDim[0], uiDimCount > 1 ? auiLocalDim[1] : 0);
#endif

    int iError = CL_SUCCESS;
    iError = clEnqueueNDRangeKernel(m_akCommandQueues[uiDeviceIndex], kKernel, 
                                    uiDimCount, NULL, auiGlobalDim, auiLocalDim, 
                                    0, NULL, NULL);

    if(iError != CL_SUCCESS)
	{
        printf("Compute Engine: Error executing kernel '%s'\n", acKernelName);
		ReportError(iError);
		return false;
	}  
    
	return true;
}


bool
ComputeEngine::createBuffer(
    const char* acMemObjName, 
    MemFlags eMemFlags, 
    size_t kBytes)
{
    printf("Compute Engine: Creating Buffer '%s' with %d bytes (%5.2f Mbytes) total)...\n",
        acMemObjName, (int)kBytes, (float)kBytes / 1024.0f / 1024.0f);
        
    MemObjectMapIter pkMemObjIter = m_akMemObjects.find(acMemObjName);
    if(pkMemObjIter != m_akMemObjects.end())
    {
        printf("Compute Engine: Releasing Existing Buffer\n");
        clReleaseMemObject(pkMemObjIter->second);
        m_akMemObjects.erase(pkMemObjIter);
    }
    
    int iError = CL_SUCCESS;
    cl_mem kBuffer = clCreateBuffer(m_kContext, (cl_mem_flags)eMemFlags, (size_t)kBytes, NULL, &iError);
    if(kBuffer == 0 || iError != CL_SUCCESS)
    {
        printf("Compute Engine: Error creating device array '%s'\n", acMemObjName);
        ReportError(iError);
        return false;
    }
    
    m_akMemObjects[acMemObjName] = kBuffer;
    return true;
}

bool
ComputeEngine::readBuffer(
    const char* acMemObjName,
    uint uiDeviceIndex,
    uint uiStart,
    size_t kBytes,
    void* pvData)
{
    cl_mem kBuffer = getMemObject(acMemObjName);
    if(kBuffer == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for reading buffer '%s'!\n", acMemObjName);
        return false;
    }   

    int iError = clEnqueueReadBuffer(m_akCommandQueues[uiDeviceIndex], kBuffer, CL_TRUE, 
                                     (size_t)uiStart, (size_t)kBytes, 
                                     pvData, 0, NULL, NULL);
    if(iError)
	{
        printf("Compute Engine: Error reading buffer %s\n", acMemObjName);
		ReportError(iError);
		return false;
	}

    return true;
}

bool
ComputeEngine::writeBuffer(
    const char* acMemObjName,
    uint uiDeviceIndex,
    uint uiStart,
    size_t kBytes,
    void* pvData)
{
    cl_mem kBuffer = getMemObject(acMemObjName);
    if(kBuffer == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for writing to buffer '%s'\n", acMemObjName);
        return false;
    }   
    
    int iError = clEnqueueWriteBuffer(m_akCommandQueues[uiDeviceIndex], kBuffer, CL_TRUE, 
                                     (size_t)uiStart, (size_t)kBytes, 
                                     pvData, 0, NULL, NULL);
    if(iError)
	{
	    printf("Compute Engine: Error writing buffer %s\n", acMemObjName);
		ReportError(iError);
		return false;
	}
	
    return true;
}

bool 
ComputeEngine::clearMemory(
    const char* acMemObjName,
    uint uiValue,
    size_t kBytes)
{
    static uint s_uiMinWorkGroupSize = 32;
    static uint s_uiMaxWorkGroupSize = 128;
    static const char acMemSetProgramName[] = "__cl_memset";
    static const char acMemSetKernelName[] = "cl_memset";

    cl_mem kMemObject = getMemObject(acMemObjName);
    if(kMemObject == 0)
        return false;
                
    KernelMapIter pkKernelIter = m_akKernels.find(acMemSetKernelName);
    if(pkKernelIter == m_akKernels.end())
    {
        createProgramFromSourceString(acMemSetProgramName, MemSetKernelSourceString);
        createKernel(acMemSetProgramName, acMemSetKernelName);
        s_uiMaxWorkGroupSize = getEstimatedWorkGroupSize(acMemSetKernelName);
        s_uiMinWorkGroupSize = (s_uiMinWorkGroupSize > s_uiMaxWorkGroupSize) ? s_uiMaxWorkGroupSize : s_uiMinWorkGroupSize;
        pkKernelIter = m_akKernels.find(acMemSetKernelName);
    }
    
    if(pkKernelIter == m_akKernels.end())
        return false;
        
    cl_kernel kKernel = pkKernelIter->second;

    uint uiElements = kBytes / sizeof(float);
    uint uiSqrt2 = (uint)(ceil(powf(uiElements, (1.0f/2.0f))));
    uiSqrt2 = uiSqrt2 < 1 ? 1 : uiSqrt2;
    uiSqrt2 = (int) ceil(uiSqrt2 / (float) 128.0f) * 128;
    
    uint uiMaxSize = s_uiMaxWorkGroupSize;
//    uint uiWorkItems = uiSqrt2 > uiMaxSize ? uiMaxSize : uiSqrt2;
//    uint uiWorkGroups = (int) ceil(uiSqrt2 / (float) uiWorkItems);
    uint uiActiveGroups = uiMaxSize / s_uiMinWorkGroupSize;
    
    float fValue = (float)(uiValue);
    
    void *pvArgsValue[3] = { (void *) &kMemObject, (void *) &fValue, (void *) &uiElements };
    size_t ptArgsSize[3] = { sizeof(cl_mem), sizeof(float), sizeof(unsigned int) };
        
    int size_x = uiActiveGroups;
    int size_y = s_uiMinWorkGroupSize;
    
    size_t auiGlobalDim[] ={ divide_up(uiSqrt2, size_x) * size_x, divide_up(uiSqrt2, size_y) * size_y };
    size_t auiLocalDim[] = { size_x, size_y };

#ifdef DEBUG    
    printf("Compute Engine: Clear Memory '%s': Value[%f]  Size[%d]  GroupSize[%d, %d] Global[%d, %d]  Local[%d, %d]\n",
        acMemObjName, fValue, uiElements, 
        s_uiMaxWorkGroupSize, s_uiMinWorkGroupSize,
        auiGlobalDim[0], auiGlobalDim[1], 
        auiLocalDim[0], auiLocalDim[1]);
#endif

    int iError = CL_SUCCESS;
    for(uint i = 0; i < 3; i++)
    {
        iError = clSetKernelArg(kKernel, i, ptArgsSize[i], pvArgsValue[i]);
        if(iError != CL_SUCCESS)
        {
            printf("Compute Engine: Error setting kernel args '%s'\n", acMemSetKernelName);
            ReportError(iError);
            return false;
        }
    }

    iError = CL_SUCCESS;
    for(uint i = 0; i < m_uiDeviceCount; i++)
    {
        iError |= clEnqueueNDRangeKernel(m_akCommandQueues[i], kKernel, 
                                        2, NULL, auiGlobalDim, auiLocalDim, 
                                        0, NULL, NULL);
    }
    if(iError != CL_SUCCESS)
	{
        printf("Compute Engine: Error executing kernel '%s'\n", acMemSetKernelName);
		ReportError(iError);
		return false;
	}  
    
    return true;
}

bool
ComputeEngine::swapMemObjects(
    const char* acMemObjNameA,
    const char* acMemObjNameB)
{
    cl_mem kA = getMemObject(acMemObjNameA);
    if(kA == 0)
        return false;

    cl_mem kB = getMemObject(acMemObjNameB);
    if(kB == 0)
        return false;

    m_akMemObjects[acMemObjNameA] = kB;
    m_akMemObjects[acMemObjNameB] = kA;
    return true;
}

cl_mem
ComputeEngine::getBuffer(
    const char* acMemObjName)
{
    return getMemObject(acMemObjName);
}
    
cl_kernel
ComputeEngine::getKernelObject(
    const char* acKernelName)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter != m_akKernels.end())
    {
        return pkKernelIter->second;
    }
    
    return (cl_kernel) 0;
}

bool 
ComputeEngine::createImage2D(
    const char* acMemObjName,
    MemFlags eMemFlags, 
    ChannelOrder eOrder,
    ChannelType eType,
    uint uiWidth,
    uint uiHeight,
    uint uiRowPitch,
    void* pvData)
{
    MemObjectMapIter pkMemObjIter = m_akMemObjects.find(acMemObjName);
    if(pkMemObjIter != m_akMemObjects.end())
    {
        printf("Compute Engine: Releasing Existing Image '%s'\n", acMemObjName);
        clReleaseMemObject(pkMemObjIter->second);
        m_akMemObjects.erase(pkMemObjIter);
    }

    uint uiChannelCount = getChannelCount(eOrder);
    if(uiChannelCount == 0)
        return false;

    printf("Compute Engine: Creating 2D image '%s' %d x %d with %d channels...\n",
        acMemObjName, uiWidth, uiHeight, uiChannelCount);

    cl_image_format kFormat;    
    kFormat.image_channel_order = (cl_channel_order) eOrder;
    kFormat.image_channel_data_type = (cl_channel_type) eType;
    cl_mem_flags kFlags = (cl_mem_flags) eMemFlags;

    int iError = CL_SUCCESS;
    cl_mem kImage = clCreateImage2D(m_kContext, kFlags, &kFormat, 
                                    (size_t)uiWidth, (size_t)uiHeight, (size_t)uiRowPitch, 
                                    pvData, &iError);

    if(kImage == 0 || iError != CL_SUCCESS)
    {
        printf("Compute Engine: Failed to create 2D image '%s'!\n", acMemObjName);
        ReportError(iError);
        return false;
    }
    
    m_akMemObjects[acMemObjName] = kImage;
    return true;
}

bool 
ComputeEngine::readImage(
    const char* acMemObjName,
    uint uiDeviceIndex,
    uint uiX, uint uiY, uint uiZ,
    uint uiWidth, uint uiHeight, uint uiDepth,
    uint uiRowPitch, uint uiSlicePitch,
    void* pvData)
{
    cl_mem kImage = getMemObject(acMemObjName);
    if(kImage == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for reading from image '%s'\n", acMemObjName);
        return false;
    }   
    
    size_t kOrigin[] = { uiX, uiY, uiZ };
    size_t kRegion[] = { uiWidth, uiHeight, uiDepth };

    int iError = clEnqueueReadImage(m_akCommandQueues[uiDeviceIndex],
                                    kImage, CL_TRUE,
                                    kOrigin, kRegion,
                                    uiRowPitch, uiSlicePitch,
                                    pvData, 0, 0, 0);
    if(iError)
    {
        printf("Compute Engine: Failed to read data from image '%s'!\n", acMemObjName);
        ReportError(iError);
        return false;
	}

    return true;
}

bool 
ComputeEngine::writeImage(
    const char* acMemObjName,
    uint uiDeviceIndex,
    uint uiX, uint uiY, uint uiZ,
    uint uiWidth, uint uiHeight, uint uiDepth,
    uint uiRowPitch, uint uiSlicePitch,
    void* pvData)
{
    cl_mem kImage = getMemObject(acMemObjName);
    if(kImage == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for reading from image '%s'\n", acMemObjName);
        return false;
    }   
    
    size_t kOrigin[] = { uiX, uiY, uiZ };
    size_t kRegion[] = { uiWidth, uiHeight, uiDepth };

    int iError = clEnqueueReadImage(m_akCommandQueues[uiDeviceIndex],
                                    kImage, CL_TRUE,
                                    kOrigin, kRegion,
                                    uiRowPitch, uiSlicePitch,
                                    pvData, 0, 0, 0);
    
    if(iError)
    {
        printf("Compute Engine: Failed to write data to image '%s'!\n", acMemObjName);
        ReportError(iError);
        return false;
	}

    return true;
}

cl_mem 
ComputeEngine::getMemObject(
    const char* acMemObjName)
{
    MemObjectMapIter pkMemObjIter = m_akMemObjects.find(acMemObjName);
    if(pkMemObjIter == m_akMemObjects.end())
	{
		printf("Compute Engine: Failed to locate memory object '%s'!\n", acMemObjName);
        return 0;
	}
	
    cl_mem kMemObject = pkMemObjIter->second;
	return kMemObject;
}
        
uint 
ComputeEngine::getChannelCount(
    ChannelOrder eOrder)
{
    uint uiChannelCount = 0;
   
    switch(eOrder)
    {
        case (R):
        case (A):
            uiChannelCount = 1;
            break;
        case (RG):
        case (RA):
            uiChannelCount = 2;
            break;
        case (RGB):
            uiChannelCount = 3;
            break;
        case (RGBA):
        case (ARGB):
            uiChannelCount = 4;
            break;
        default:
            printf("Compute Engine: Invalid channel order for creating image!\n");
            uiChannelCount = 0;
    }
    return uiChannelCount;    
}

bool
ComputeEngine::createGLBufferReference(
    const char* acMemObjName,
    MemFlags eMemFlags, 
    uint uiBufferId)
{
    printf("Compute Engine: Creating OpenGL buffer reference '%s' for buffer id '%d'...\n",
        acMemObjName, uiBufferId);
        
    MemObjectMapIter pkMemObjIter = m_akMemObjects.find(acMemObjName);
    if(pkMemObjIter != m_akMemObjects.end())
    {
        printf("Compute Engine: Releasing existing memory object '%s'...\n", acMemObjName);
        clReleaseMemObject(pkMemObjIter->second);
        m_akMemObjects.erase(pkMemObjIter);
    }

    int iError = CL_SUCCESS;
    cl_mem_flags kFlags = (cl_mem_flags) eMemFlags;
    cl_mem kReference = clCreateFromGLBuffer(m_kContext, kFlags, uiBufferId, &iError);
    if(kReference == 0 || iError != CL_SUCCESS)
    {
        printf("Compute Engine: Error creating OpenGL buffer reference '%s' for buffer id '%d'\n", 
            acMemObjName, uiBufferId);
        
        ReportError(iError);
        return false;
    }
    
    m_akMemObjects[acMemObjName] = kReference;
    return true;
}

bool
ComputeEngine::attachGLBuffer(
    const char* acMemObjName,
    uint uiDeviceIndex)
{
    cl_mem kMemObj = getMemObject(acMemObjName);
    if(kMemObj == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for attaching GL object!\n");
        return false;
    } 


    int iError = clEnqueueAcquireGLObjects(m_akCommandQueues[uiDeviceIndex], 1, &kMemObj, 0, NULL, NULL);
    if(iError)
	{
        printf("Compute Engine: Error attaching GL buffer %s\n", acMemObjName);
		ReportError(iError);
		return false;
	}

    return true;
}

bool
ComputeEngine::attachGLBuffer(
    cl_mem kMemObj,
    uint uiDeviceIndex)    
{
    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for attaching GL object!\n");
        return false;
    } 

    int iError = clEnqueueAcquireGLObjects(m_akCommandQueues[uiDeviceIndex], 1, &kMemObj, 0, NULL, NULL);
    if(iError)
	{
        printf("Compute Engine: Error attaching GL buffer %p\n", &kMemObj);
		ReportError(iError);
		return false;
	}

    return true;
}

bool
ComputeEngine::detachGLBuffer(
    const char* acMemObjName,
    uint uiDeviceIndex)
{
    cl_mem kMemObj = getMemObject(acMemObjName);
    if(kMemObj == 0)
        return false;

    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for attaching GL object!\n");
        return false;
    } 

    int iError = clEnqueueReleaseGLObjects(m_akCommandQueues[uiDeviceIndex], 1, &kMemObj, 0, NULL, NULL);
    if(iError)
	{
        printf("Compute Engine: Error attaching GL buffer %s\n", acMemObjName);
		ReportError(iError);
		return false;
	}

    return true;
}

bool
ComputeEngine::detachGLBuffer(
    cl_mem kMemObj,
    uint uiDeviceIndex)
{
    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for detaching GL object!\n");
        return false;
    } 
    
    int iError = clEnqueueReleaseGLObjects(m_akCommandQueues[uiDeviceIndex], 1, &kMemObj, 0, NULL, NULL);
    if(iError)
	{
        printf("Compute Engine: Error attaching GL buffer %p\n", &kMemObj);
		ReportError(iError);
		return false;
	}

    return true;
}

bool
ComputeEngine::createGLTexture2DReference(
    const char* acMemObjName,
    MemFlags eMemFlags, 
    GLenum eTarget,
    GLint iMipLevel,
    GLuint uiBufferId)
{
    printf("Compute Engine: Creating OpenGL buffer reference '%s' for buffer id '%d'...\n",
        acMemObjName, uiBufferId);
        
    MemObjectMapIter pkMemObjIter = m_akMemObjects.find(acMemObjName);
    if(pkMemObjIter != m_akMemObjects.end())
    {
        printf("Compute Engine: Releasing existing memory object '%s'...\n", acMemObjName);
        clReleaseMemObject(pkMemObjIter->second);
        m_akMemObjects.erase(pkMemObjIter);
    }

    int iError = CL_SUCCESS;
    cl_mem_flags kFlags = (cl_mem_flags) eMemFlags;
    cl_mem kReference = clCreateFromGLTexture2D(m_kContext, kFlags, eTarget, iMipLevel, uiBufferId, &iError);
    if(kReference == 0 || iError != CL_SUCCESS)
    {
        printf("Compute Engine: Error creating OpenGL buffer reference '%s' for buffer id '%d'\n", 
            acMemObjName, uiBufferId);
        
        ReportError(iError);
        return false;
    }
    
    m_akMemObjects[acMemObjName] = kReference;
    return true;
}

bool
ComputeEngine::barrier(
    uint uiDeviceIndex)
{
    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for barrier!\n");
        return false;
    }   
    
    int iError = clEnqueueBarrier(m_akCommandQueues[uiDeviceIndex]);
    if(iError != CL_SUCCESS)
    {
        printf("Failed to enqueue barrier for device: %d\n", uiDeviceIndex);
        ReportError(iError);
        return false;
    }   

    return true;
}

bool
ComputeEngine::flush(
    uint uiDeviceIndex)
{
    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for flush!\n");
        return false;
    }   
    
    int iError = clFlush(m_akCommandQueues[uiDeviceIndex]);
    if(iError != CL_SUCCESS)
    {
        printf("Failed to flush commands for device: %d\n", uiDeviceIndex);
        ReportError(iError);
        return false;
    }   

    return true;
}


bool
ComputeEngine::finish(
    uint uiDeviceIndex)
{
    if(uiDeviceIndex > m_uiDeviceCount)
    {
        printf("Invalid device index for finish!\n");
        return false;
    }   
    
    int iError = clFinish(m_akCommandQueues[uiDeviceIndex]);
    if(iError != CL_SUCCESS)
    {
        printf("Failed to finish commands for device: %d\n", uiDeviceIndex);
        ReportError(iError);
        return false;
    }   

    return true;
}

uint
ComputeEngine::getContextDeviceCount()
{
    if(!m_kContext)
        return 0;

    size_t kReturnedSize;
    cl_device_id akAvailableDeviceIds[ms_uiMaxDeviceCount];

    int iError = clGetContextInfo(m_kContext, CL_CONTEXT_DEVICES, 
                                  sizeof(akAvailableDeviceIds), 
                                  akAvailableDeviceIds,
                                  &kReturnedSize);
    if (iError)
    {
        printf("Compute Engine: Failed to retrieve device group info!\n");
        ReportError(iError);
        return 0;
    }
    
    uint uiAvailable = kReturnedSize / sizeof(cl_device_id);
    return uiAvailable;
}

unsigned long
ComputeEngine::getMaxAllocationSizeInBytes()
{
    unsigned long ulMaxBytes = 0;
    for(uint i = 0;  i < m_uiDeviceCount; i++)
    {
        size_t kReturnedSize = 0;
        unsigned long ulValue = 0;
        clGetDeviceInfo(m_akDeviceIds[i], CL_DEVICE_MAX_MEM_ALLOC_SIZE, sizeof(ulValue), &ulValue, &kReturnedSize);
        ulMaxBytes = ulMaxBytes ? ulMaxBytes : ulValue;  
        ulMaxBytes = (ulValue < ulMaxBytes) ? (ulValue) : ulMaxBytes;
    }
    return ulMaxBytes;
}

uint
ComputeEngine::getEstimatedWorkGroupSize(
    const char *acKernelName,
    uint uiDeviceIndex)
{
    KernelMapIter pkKernelIter = m_akKernels.find(acKernelName);
    if(pkKernelIter == m_akKernels.end())
    {
        printf("Compute Engine: Failed to retrieve kernel for work group size estimation!\n");
        return 0;
    }
    
    if(uiDeviceIndex >= m_uiDeviceCount)
    {
        printf("Compute Engine: Invalid device index specified for work group size estimation!\n");
        return 0;
    }
        
    size_t iMaxSize = 0;
    size_t kReturnedSize = 0;
    cl_kernel kKernel = pkKernelIter->second;
    int iError = clGetKernelWorkGroupInfo( kKernel, m_akDeviceIds[uiDeviceIndex], CL_KERNEL_WORK_GROUP_SIZE, 
                                           sizeof(iMaxSize), &iMaxSize, &kReturnedSize);

    if (iError)
    {
        printf("Compute Engine: Failed to retrieve kernel work group info!\n");
        ReportError(iError);
        return 0;
    }
    
    return iMaxSize;
}

void 
ComputeEngine::dumpBuffer(
    const char* acMemObjName,
    uint uiDeviceIndex,
    uint uiStart,
    size_t kBytes,
    uint uiDataType,
    uint uiComponents)
{
    char *acBuffer = new char[kBytes];
    if(!acBuffer)
        return;
        
    printf("DumpBuffer\n");
    memset(acBuffer, 0, kBytes);
    
    if(readBuffer(acMemObjName, uiDeviceIndex, uiStart, kBytes, acBuffer))
    {
        DumpBufferValues(acMemObjName, acBuffer, uiStart, kBytes, uiDataType, uiComponents);
    }
    
    delete [] acBuffer;
}

