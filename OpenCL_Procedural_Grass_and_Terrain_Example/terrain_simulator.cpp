//
// File:       terrain_simulator.cpp
//
// Abstract:   This example shows how OpenCL can be used to create a procedural field of 
//             grass on a generated terrain model which is then rendered with OpenGL.  
//             Because OpenGL buffers are shared with OpenCL, the data can remain on the 
//             graphics card, thus eliminating the API overhead of creating and submitting 
//             the vertices from the host.
//
//             All geometry is generated on the compute device, and outputted into
//             a shared OpenGL buffer.  The terrain gets generated only within the 
//             visible arc covering the camera's view frustum to avoid the need for 
//             culling.  A page of grass is computed on the surface of the terrain as
//             bezier patches, and flow noise is applied to the angle of the blades
//             to simulate wind.  Multiple instances of grass are rendered at jittered
//             offsets to add more grass coverage without having to compute new pages.
//             Finally, a physically based sky shader (via OpenGL) is applied to 
//             the background to provide an environment for the grass.
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


#include "terrain_simulator.h"
#include "compute_math.h"

#include <math.h>
#include <assert.h>

/////////////////////////////////////////////////////////////////////////////

TerrainSimulator::TerrainSimulator() :
    m_bInitialized(0),
    m_uiKernelArgCount(0),
    m_apvKernelArgValues(0),
    m_atKernelArgSizes(0),
    m_uiSizeX(128),
    m_uiSizeY(128),
    m_fJitterAmount(0),
    m_fCameraFov(0),
    m_fNoiseAmplitude(0),
    m_afVertexData(0),
    m_uiVertexBytes(0),
    m_uiVertexCount(0),
    m_uiVertexComponents(4),
    m_uiVertexBufferId(0),
    m_bCopyVertexData(false),
    m_afNormalData(0),
    m_uiNormalBytes(0),
    m_uiNormalCount(0),
    m_uiNormalComponents(4),
    m_uiNormalBufferId(0),
    m_bCopyNormalData(false),
    m_afTexCoordData(0),
    m_uiTexCoordBytes(0),
    m_uiTexCoordCount(0),
    m_uiTexCoordComponents(4),
    m_uiTexCoordBufferId(0),
    m_bCopyTexCoordData(false),
    m_fFalloff(0)
{
    m_auiGlobalDim[0] = m_auiGlobalDim[1] = 0;
}
    
TerrainSimulator::~TerrainSimulator()
{
	if(m_apvKernelArgValues)
		delete [] m_apvKernelArgValues;
	m_apvKernelArgValues = 0;
	
	if(m_atKernelArgSizes)
		delete [] m_atKernelArgSizes;
	m_atKernelArgSizes = 0;
	m_uiKernelArgCount = 0;
    
    destroy();
}

void
TerrainSimulator::destroy()
{
    if(m_afVertexData)
        delete [] m_afVertexData;
    m_afVertexData = 0;
    m_uiVertexBytes = 0;
    m_uiVertexCount = 0;

    if(m_afNormalData)
        delete [] m_afNormalData;
    m_afNormalData = 0;
    m_uiNormalBytes = 0;
    m_uiNormalCount = 0;
    
    if(m_afTexCoordData)
        delete [] m_afTexCoordData;
    m_afTexCoordData = 0;
    m_uiTexCoordBytes = 0;
    m_uiTexCoordCount = 0;
    
}

bool 
TerrainSimulator::allocate(uint uiSizeX, uint uiSizeY)
{
    destroy();
    
    m_uiVertexCount = uiSizeX * uiSizeY;
    if(!m_uiVertexBufferId || (m_uiVertexBufferId && m_bCopyVertexData))
    {
        m_afVertexData = new float[m_uiVertexCount * m_uiVertexComponents];
        m_uiVertexBytes = m_uiVertexCount * sizeof(float) * m_uiVertexComponents;
        for(long long i = 0; i <  m_uiVertexCount * m_uiVertexComponents; i++)
        {
            m_afVertexData[i] = 0.0f;
        }
    }

    m_uiNormalCount = uiSizeX * uiSizeY;
    if(!m_uiNormalBufferId || (m_uiNormalBufferId && m_bCopyNormalData))
    {
        m_afNormalData = new float[m_uiNormalCount * m_uiNormalComponents];
        m_uiNormalBytes = m_uiNormalCount * sizeof(float) * m_uiNormalComponents;
        for(long long i = 0; i <  m_uiNormalCount * m_uiNormalComponents; i++)
        {
            m_afNormalData[i] = 0.0f;
        }
    }

    m_uiTexCoordCount = uiSizeX * uiSizeY;
    if(!m_uiTexCoordBufferId || (m_uiTexCoordBufferId && m_bCopyTexCoordData))
    {
        m_afTexCoordData = new float[m_uiTexCoordCount * m_uiTexCoordComponents];
        m_uiTexCoordBytes = m_uiTexCoordCount * sizeof(float) * m_uiTexCoordComponents;
        for(long long i = 0; i <  m_uiTexCoordCount * m_uiTexCoordComponents; i++)
        {
            m_afTexCoordData[i] = 0.0f;
        }
    }
    
    return true;
}

uint
TerrainSimulator::getRequiredVertexBufferSize(
    uint uiSizeX, uint uiSizeY)
{
    uint uiVertexCount = uiSizeX * uiSizeY;
    uint uiVertexBytes = uiVertexCount * sizeof(float) * m_uiVertexComponents;
    return uiVertexBytes;
}

uint 
TerrainSimulator::getRequiredNormalBufferSize(
    uint uiSizeX, uint uiSizeY)
{
    uint uiNormalCount = uiSizeX * uiSizeY;
    uint uiNormalBytes = uiNormalCount * sizeof(float) * m_uiNormalComponents;
    return uiNormalBytes;
}
    
uint 
TerrainSimulator::getRequiredTexCoordBufferSize(
    uint uiSizeX, uint uiSizeY)
{
    uint uiTexCoordCount = uiSizeX * uiSizeY;
    uint uiTexCoordBytes = uiTexCoordCount * sizeof(float) * m_uiTexCoordComponents;
    return uiTexCoordBytes;
}


void
TerrainSimulator::setProjectedCorners(
    const float4 afCorners[4])
{
    for(uint i = 0; i < 4; i++)
        m_akProjectedCorners[i] = afCorners[i];
}

bool 
TerrainSimulator::reset(
    ComputeEngine &rkCompute)
{
	ComputeEngine::MemFlags eMemFlags = ComputeEngine::MEM_READ_WRITE;

	bool bOk = true;

    if(m_uiVertexBufferId && !m_bCopyVertexData)
        bOk |= rkCompute.createGLBufferReference("terrain_vertices",  eMemFlags, m_uiVertexBufferId);
    else
        bOk |= rkCompute.createBuffer("terrain_vertices",  eMemFlags,   m_uiVertexComponents * sizeof(float) * m_uiVertexCount);

    if(m_uiNormalBufferId && !m_bCopyNormalData)
        bOk |= rkCompute.createGLBufferReference("terrain_normals",  eMemFlags, m_uiNormalBufferId);
    
    else
        bOk |= rkCompute.createBuffer("terrain_normals",   eMemFlags,   m_uiNormalComponents * sizeof(float) * m_uiNormalCount);

    if(m_uiTexCoordBufferId && !m_bCopyTexCoordData)
        bOk |= rkCompute.createGLBufferReference("terrain_texcoords",  eMemFlags, m_uiTexCoordBufferId);
    
    else
        bOk |= rkCompute.createBuffer("terrain_texcoords", eMemFlags, m_uiTexCoordComponents  * sizeof(float) * m_uiTexCoordCount);

    if(!bOk)
    {
        printf("Terrain Simulator: Device memory allocation failed!\n");
        return false;
    }

    m_bInitialized = true;
    return true;
}

bool
TerrainSimulator::setup(
    ComputeEngine &rkCompute,
    uint uiSizeX, uint uiSizeY)
{
    if(!allocate(uiSizeX, uiSizeY))
        return false;
               
    m_uiSizeX = uiSizeX;
    m_uiSizeY = uiSizeY;

	printf("Terrain Simulator: Vertices[%d] Count[%d, %d]\n", 
            m_uiVertexCount, uiSizeX, uiSizeY);   
                
    bool bOk = true;
    bOk = bOk && rkCompute.createProgramFromFile("tk", "terrain_kernels.cl");
    bOk = bOk && rkCompute.createKernel("tk", "ComputeTerrainKernel");
    if(!bOk)
    {
        printf("Terrain Simulator: Failed to create device kernel!\n");
        return false;
    }
    
    return reset(rkCompute);
}


bool
TerrainSimulator::update(
    ComputeEngine &rkCompute,
    uint uiIteration)
{
     if(rkCompute.isConnected() == false || !m_bInitialized)
        return false;
        
    return compute(rkCompute, uiIteration);
}

bool
TerrainSimulator::compute(
    ComputeEngine &rkCompute,
    uint uiIteration)
{
     if(rkCompute.isConnected() == false || !m_bInitialized)
        return false;
    
    const char *acKernelName = "ComputeTerrainKernel";
    uint uiWorkItems = rkCompute.getEstimatedWorkGroupSize(acKernelName);
    
    uiWorkItems = round(m_uiSizeX * m_uiSizeY * uiWorkItems) / uiWorkItems;
    uiWorkItems = 1;
    
    int aiGridResolution[] = { m_uiSizeX, m_uiSizeY };
    size_t auiGlobalDim[2] = { m_uiSizeX * m_uiSizeY };
    size_t auiLocalDim[2]  = { uiWorkItems };   

/*
    float fFrequency = 0.0025f;
    float fAmplitude = 50.00f;
    float fPhase = 1.0f;
    float fLacunarity = 2.0345f;
    float fIncrement = 1.0f;
    float fOctaves = 1.0f;
    float fRoughness = 1.00f;
*/    
    cl_mem kVertices = rkCompute.getMemObject("terrain_vertices");
    cl_mem kNormals = rkCompute.getMemObject("terrain_normals");
    cl_mem kTexCoords = rkCompute.getMemObject("terrain_texcoords");
    
    attachMemory(rkCompute);

    uint uiArgIndex = 0;
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, aiGridResolution,    sizeof(int) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraPosition,  sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraRotation,  sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraView,      sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraLeft,      sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_fCameraFov,       sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fFrequency,         sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fAmplitude,         sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fPhase,             sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fLacunarity,        sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fIncrement,         sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fOctaves,           sizeof(float) * 1);
//    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fRoughness,         sizeof(float) * 1);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_uiVertexCount,    sizeof(uint)  * 1);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &kVertices,          sizeof(cl_mem));
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &kNormals,           sizeof(cl_mem));
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &kTexCoords,         sizeof(cl_mem));

    assert(uiArgIndex == rkCompute.getKernelArgCount(acKernelName));

    bool bSuccess = rkCompute.executeKernel(acKernelName, 0, auiGlobalDim, auiLocalDim, 1);

    updateOutputs(rkCompute);
    detachMemory(rkCompute);
    
    if(!bSuccess)
        return false;
        
    return true;
    
}

void
TerrainSimulator::attachMemory(
    ComputeEngine &rkCompute)
{
    if(m_uiVertexBufferId && !m_bCopyVertexData) 
        rkCompute.attachGLBuffer("terrain_vertices");//, m_uiVertexBufferId);
    
    if(m_uiNormalBufferId && !m_bCopyNormalData) 
        rkCompute.attachGLBuffer("terrain_normals");// m_uiNormalBufferId);

    if(m_uiTexCoordBufferId && !m_bCopyTexCoordData) 
        rkCompute.attachGLBuffer("terrain_texcoords");//m_uiTexCoordBufferId);
}

void 
TerrainSimulator::detachMemory(
    ComputeEngine &rkCompute)
{
    if(m_uiVertexBufferId && !m_bCopyVertexData) 
        rkCompute.detachGLBuffer("terrain_vertices");
    
    if(m_uiNormalBufferId && !m_bCopyNormalData) 
        rkCompute.detachGLBuffer("terrain_normals");

    if(m_uiTexCoordBufferId && !m_bCopyTexCoordData) 
        rkCompute.detachGLBuffer("terrain_texcoords");

    rkCompute.barrier();
}

void
TerrainSimulator::updateOutputs(
    ComputeEngine &rkCompute)
{
    if(m_afVertexData && m_bCopyVertexData)
    {
        rkCompute.readBuffer("terrain_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount, m_afVertexData);
        
        if(m_uiVertexBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount, m_afVertexData);
            glVertexPointer(m_uiVertexComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    
    if(m_afNormalData && m_bCopyNormalData)
    {
        rkCompute.readBuffer("terrain_normals", 0, 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount, m_afNormalData);

        if(m_uiNormalBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiNormalBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount, m_afNormalData);
            glNormalPointer(GL_FLOAT, m_uiNormalComponents * sizeof(float), 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    
    if(m_afTexCoordData && m_bCopyTexCoordData)
    {
        rkCompute.readBuffer("terrain_texcoords", 0, 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount, m_afTexCoordData);

        if(m_uiTexCoordBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiTexCoordBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount, m_afTexCoordData);
            glTexCoordPointer(m_uiTexCoordComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }    
}

void 
TerrainSimulator::clearMemory(
    ComputeEngine &rkCompute)
{    
    if(m_afVertexData)
    {
        for(long long i = 0; i < m_uiVertexCount * m_uiVertexComponents; i++)
            m_afVertexData[i] = 0.0f;
            
        rkCompute.writeBuffer("terrain_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount, m_afVertexData);
        rkCompute.readBuffer("terrain_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount, m_afVertexData);

        if(m_uiVertexBufferId && m_bCopyVertexData)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount, m_afVertexData);
            glVertexPointer(m_uiVertexComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    else if(m_uiVertexBufferId && !m_bCopyVertexData)
    {
        rkCompute.attachGLBuffer("terrain_vertices") ; //, m_uiVertexBufferId);
        rkCompute.clearMemory("terrain_vertices", 0, m_uiVertexComponents * sizeof(float) * m_uiVertexCount);  
        rkCompute.detachGLBuffer("terrain_vertices");
    }
    
    if(m_afNormalData)
    {
        for(long long i = 0; i < m_uiNormalCount * m_uiNormalComponents; i++)
            m_afNormalData[i] = 0.0f;
            
        rkCompute.writeBuffer("terrain_normals", 0, 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount, m_afNormalData);
        rkCompute.readBuffer("terrain_normals", 0, 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount, m_afNormalData);

        if(m_uiNormalBufferId && m_bCopyNormalData)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiNormalBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount, m_afNormalData);
            glNormalPointer(GL_FLOAT, m_uiNormalComponents * sizeof(float), 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }
    }
    else if(m_uiNormalBufferId && !m_bCopyNormalData)
    {
        rkCompute.attachGLBuffer("terrain_normals"); //, m_uiNormalBufferId);
        rkCompute.clearMemory("terrain_normals", 0, m_uiNormalComponents * sizeof(float) * m_uiNormalCount);  
        rkCompute.detachGLBuffer("terrain_normals");
    }
    
    if(m_afTexCoordData)
    {
        for(long long i = 0; i < m_uiTexCoordCount * m_uiTexCoordComponents; i++)
            m_afTexCoordData[i] = 0.0f;
            
        rkCompute.writeBuffer("terrain_texcoords", 0, 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount, m_afTexCoordData);
        rkCompute.readBuffer("terrain_texcoords", 0, 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount, m_afTexCoordData);

        if(m_uiTexCoordBufferId && m_bCopyTexCoordData)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiTexCoordBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount, m_afTexCoordData);
            glTexCoordPointer(m_uiTexCoordComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    

    }
    else if(m_uiTexCoordBufferId && !m_bCopyTexCoordData)
    {
        rkCompute.attachGLBuffer("terrain_texcoords"); // , m_uiTexCoordBufferId);
        rkCompute.clearMemory("terrain_texcoords", 0, m_uiTexCoordComponents * sizeof(float) * m_uiTexCoordCount);  
        rkCompute.detachGLBuffer("terrain_texcoords");
    }
}
