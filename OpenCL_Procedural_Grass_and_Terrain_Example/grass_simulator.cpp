//
// File:       grass_simulator.cpp
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

#include "grass_simulator.h"
#include "compute_math.h"

#include <math.h>
#include <assert.h>
#include <time.h>

/////////////////////////////////////////////////////////////////////////////

GrassSimulator::GrassSimulator() :
    m_bInitialized(0),
    m_uiWorkItemCount(0),
    m_uiRowCount(0),
    m_uiColumnCount(0),
    m_uiBladeCount(0),
    m_uiMaxSegmentCount(0),
    m_uiMaxElementCount(0),
    m_uiMaxVertexCount(0),
    m_fJitterAmount(0),
    m_fCameraFov(0),
    m_fNoiseAmplitude(0),
    m_fBladeIntensity(0),
    m_fBladeOpacity(0),
    m_fFlowScale(0),
    m_fFlowSpeed(0),
    m_fFlowAmount(0),
    m_afVertexData(0),
    m_uiVertexBytes(0),
    m_uiVertexComponents(4),
    m_bCopyVertexData(false),
    m_afColorData(0),
    m_uiColorBytes(0),
    m_uiColorCount(0),
    m_uiColorComponents(4),
    m_bCopyColorData(false),
    m_auiSegmentData(0),
    m_uiSegmentBytes(0),
    m_uiSegmentCount(0),
    m_auiElementData(0),
    m_uiElementBytes(0),
    m_uiElementCount(0),
    m_uiVertexBufferId(0),
    m_uiColorBufferId(0),
    m_uiVertexElementCount(0),
    m_acHeightFieldMemObjName(0),
    m_uiHeightFieldVertexBufferId(0),
    m_uiHeightFieldNormalBufferId(0),
    m_uiHeightFieldSizeX(0),
    m_uiHeightFieldSizeY(0),    
    m_bCopyHeightFieldData(false),
    m_fFalloff(0)
{
    m_auiGlobalDim[0] = m_auiGlobalDim[1] = 0;
}
    
GrassSimulator::~GrassSimulator()
{
    
    destroy();
}

void
GrassSimulator::destroy()
{
    if(m_afVertexData)
        delete [] m_afVertexData;
    m_afVertexData = 0;
    m_uiVertexBytes = 0;
    
    if(m_afColorData)
        delete [] m_afColorData;
    m_afColorData = 0;
    m_uiColorBytes = 0;

    if(m_auiSegmentData)
        delete [] m_auiSegmentData;
    m_auiSegmentData = 0;
    m_uiSegmentBytes = 0;
    
    if(m_auiElementData)
        delete [] m_auiElementData;
    m_auiElementData = 0;
    m_uiElementBytes = 0;
    
    m_uiVertexElementCount = 0;


}

bool 
GrassSimulator::allocate(uint uiCount)
{
    destroy();
    
    m_uiBladeCount = uiCount;
    m_uiVertexElementCount = m_uiBladeCount * m_uiMaxElementCount * m_uiMaxSegmentCount;
    m_uiMaxVertexCount = m_uiBladeCount * m_uiMaxElementCount * m_uiMaxSegmentCount;
    m_uiMaxVertexCount = m_uiMaxVertexCount;
    
    if(!m_uiVertexBufferId || (m_uiVertexBufferId && m_bCopyVertexData))
    {
        m_afVertexData = new float[m_uiMaxVertexCount * m_uiVertexComponents];
        m_uiVertexBytes = m_uiMaxVertexCount * sizeof(float) * m_uiVertexComponents;

        for(long long i = 0; i <  m_uiMaxVertexCount * m_uiVertexComponents; i++)
        {
            m_afVertexData[i] = 0.0f;
        }
    }

    if(!m_uiColorBufferId || (m_uiColorBufferId && m_bCopyColorData))
    {
        m_afColorData = new float[m_uiMaxVertexCount * m_uiColorComponents];
        m_uiColorBytes = m_uiMaxVertexCount * sizeof(float) * m_uiColorComponents;

        for(long long i = 0; i <  m_uiMaxVertexCount * m_uiColorComponents; i++)
        {
            m_afColorData[i] = 0.0f;
        }
    }
    
    m_auiSegmentData = new uint[m_uiBladeCount * m_uiMaxElementCount];
    m_uiSegmentBytes = m_uiBladeCount * m_uiMaxElementCount * sizeof(uint);
    memset(m_auiSegmentData, 0, m_uiSegmentBytes);
    
    m_auiElementData = new uint[m_uiBladeCount];
    m_uiElementBytes = m_uiBladeCount * sizeof(uint);
    memset(m_auiElementData, 0, m_uiElementBytes);
    
    return true;
}

uint
GrassSimulator::getRequiredVertexBufferSize(
    uint uiBladeCount)
{
    uint uiMaxVertexCount = uiBladeCount * m_uiMaxElementCount * m_uiMaxSegmentCount;
    uint uiVertexBytes = uiMaxVertexCount * sizeof(float) * m_uiVertexComponents;
    return uiVertexBytes;
}
    
uint 
GrassSimulator::getRequiredColorBufferSize(
    uint uiBladeCount)
{
    uint uiMaxVertexCount = uiBladeCount * m_uiMaxElementCount * m_uiMaxSegmentCount;
    uint uiVertexBytes = uiMaxVertexCount * sizeof(float) * m_uiColorComponents;
    return uiVertexBytes;
}

bool 
GrassSimulator::reset(
    ComputeEngine &rkCompute)
{
	bool bOk = true;
	ComputeEngine::MemFlags eMemFlags = ComputeEngine::MEM_READ_WRITE;
	
    if(m_uiVertexBufferId && !m_bCopyVertexData)
        bOk |=rkCompute.createGLBufferReference("grass_vertices", eMemFlags, m_uiVertexBufferId);
    
    else
        bOk |=rkCompute.createBuffer("grass_vertices", eMemFlags, m_uiVertexComponents * sizeof(float) * m_uiVertexElementCount);
    
    if(m_uiColorBufferId && !m_bCopyColorData)
        bOk |=rkCompute.createGLBufferReference("grass_colors", eMemFlags, m_uiColorBufferId);
    
    else
        bOk |=rkCompute.createBuffer("grass_colors",   eMemFlags, m_uiColorComponents  * sizeof(float) * m_uiVertexElementCount);
    
    if(!bOk)
    {
        printf("Grass Simulator: Device memory allocation failed!\n");
        return false;
    }

    m_bInitialized = true;
    return true;
}

bool
GrassSimulator::setup(
    ComputeEngine &rkCompute,
    uint uiBladeCount, uint uiRows, uint uiColumns)
{
    if(!allocate(uiBladeCount))
        return false;
               
    m_uiRowCount = uiRows;
    m_uiColumnCount = uiColumns;

	printf("Grass Simulator: BladeCount[%d] RowCount[%d] ColumnCount[%d]\n", 
            uiBladeCount, m_uiRowCount, m_uiColumnCount);   
                
    bool bOk = true;
    bOk = bOk && rkCompute.createProgramFromFile("gs", "grass_kernels.cl");
    bOk = bOk && rkCompute.createKernel("gs", "ComputeGrassOnTerrainKernel");
    if(!bOk)
    {
        printf("Grass Simulator: Failed to create device kernel!\n");
        return false;
    }

	m_uiWorkItemCount = rkCompute.getEstimatedWorkGroupSize("ComputeGrassOnTerrainKernel", 0);
    
    return reset(rkCompute);
}

bool
GrassSimulator::computeGrassOnTerrain(
    ComputeEngine &rkCompute,
    uint uiIteration)
{
    if(rkCompute.isConnected() == false || !m_bInitialized)
        return false;

	uint uiWorkItems = m_uiWorkItemCount; 

    float fSqrtElements = ceil(sqrtf(m_uiBladeCount));
    float fSqrtItems = floor(sqrtf(uiWorkItems));
    
    int aiGridResolution[] = { fSqrtElements, fSqrtElements };

    size_t auiGlobalDim[2] = { divide_up(fSqrtElements, fSqrtItems) * fSqrtItems, divide_up(fSqrtElements, fSqrtItems) * fSqrtItems };
    size_t auiLocalDim[2]  = { fSqrtItems, fSqrtItems };   

    float fDT = 0.01f * uiIteration;
    
    float fBladeLuminanceAlpha[2] = 
    {
        m_fBladeIntensity, 
        m_fBladeOpacity
    };

    float fFlowScaleSpeedAmount[4] = 
    {
        m_fFlowScale, 
        m_fFlowScale, 
        m_fFlowSpeed, 
        m_fFlowAmount 
    };
    
    float afNoiseBiasScale[4] = 
    { 
        m_kNoiseBias.x, m_kNoiseBias.y, 
        m_kNoiseScale.x, m_kNoiseScale.y 
    };

    uint auiBladeCurveSegmentCounts[4] = 
    { 
        m_uiBladeCount, 
        m_uiMaxElementCount, 
        m_uiMaxSegmentCount, 
        m_uiMaxVertexCount 
    };
        
    const char *acKernelName = "ComputeGrassOnTerrainKernel";

    cl_mem kGrassVertices = rkCompute.getMemObject("grass_vertices");
    cl_mem kGrassColors = rkCompute.getMemObject("grass_colors");
    
    uint uiArgIndex = 0;
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, aiGridResolution,    sizeof(int) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_fJitterAmount,                         sizeof(float) * 1);   
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fDT,                                     sizeof(float) * 1);   
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_fFalloff,                              sizeof(float) * 1);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_fCameraFov,                            sizeof(float) * 1);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraPosition,                       sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraRotation,                       sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraView,                           sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraLeft,                           sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kCameraUp,                             sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kClipRange,                            sizeof(float) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kBladeLengthRange,                     sizeof(float) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_kBladeThicknessRange,                  sizeof(float) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fBladeLuminanceAlpha,                    sizeof(float) * 2);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &fFlowScaleSpeedAmount,                   sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, afNoiseBiasScale,                         sizeof(float) * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &m_fNoiseAmplitude,                       sizeof(float) * 1);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, auiBladeCurveSegmentCounts,               sizeof(uint)  * 4);
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &kGrassVertices,                          sizeof(cl_mem));
    rkCompute.setKernelArg(acKernelName, uiArgIndex++, &kGrassColors,                            sizeof(cl_mem));
    
    assert(uiArgIndex == rkCompute.getKernelArgCount(acKernelName));

    attachMemory(rkCompute);

    bool bSuccess = rkCompute.executeKernel(acKernelName, 0, auiGlobalDim, auiLocalDim, 2);

    updateOutputs(rkCompute);
    detachMemory(rkCompute);
    
    if(!bSuccess)
        return false;
        
    return true;
}

void
GrassSimulator::attachMemory(
    ComputeEngine &rkCompute)
{
            
    if(m_uiVertexBufferId && !m_bCopyVertexData) 
        rkCompute.attachGLBuffer("grass_vertices");
    
    if(m_uiColorBufferId && !m_bCopyColorData) 
        rkCompute.attachGLBuffer("grass_colors"); 
}

void 
GrassSimulator::detachMemory(
    ComputeEngine &rkCompute)
{
    if(m_uiVertexBufferId && !m_bCopyVertexData) 
        rkCompute.detachGLBuffer("grass_vertices");
    
    if(m_uiColorBufferId && !m_bCopyColorData) 
        rkCompute.detachGLBuffer("grass_colors");

}

void
GrassSimulator::updateOutputs(
    ComputeEngine &rkCompute)
{
    if(m_afVertexData && m_bCopyVertexData)
    {
        rkCompute.readBuffer("grass_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount, m_afVertexData);
        
        if(m_uiVertexBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount, m_afVertexData);
            glVertexPointer(m_uiVertexComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    
    if(m_afColorData && m_bCopyColorData)
    {
        rkCompute.readBuffer("grass_colors", 0, 0, m_uiColorComponents * sizeof(float) * m_uiMaxVertexCount, m_afColorData);
        
        if(m_uiColorBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiColorBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiColorComponents * sizeof(float) * m_uiMaxVertexCount, m_afColorData);
            glColorPointer(m_uiColorComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
}

void 
GrassSimulator::clearMemory(
    ComputeEngine &rkCompute)
{    
    if(m_afVertexData)
    {
        for(long long i = 0; i < m_uiMaxVertexCount * m_uiVertexComponents; i++)
            m_afVertexData[i] = 0.0f;
            
        rkCompute.writeBuffer("grass_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount, m_afVertexData);
        rkCompute.readBuffer("grass_vertices", 0, 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount, m_afVertexData);

        if(m_uiVertexBufferId && m_bCopyVertexData)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount, m_afVertexData);
            glVertexPointer(m_uiVertexComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    else if(m_uiVertexBufferId && !m_bCopyVertexData)
    {
        rkCompute.attachGLBuffer("grass_vertices") ; //, m_uiVertexBufferId);
        rkCompute.clearMemory("grass_vertices", 0, m_uiVertexComponents * sizeof(float) * m_uiMaxVertexCount);  
        rkCompute.detachGLBuffer("grass_vertices");
    }


    if(m_afColorData)
    {
        for(long long i = 0; i < m_uiVertexElementCount * m_uiColorComponents; i++)
            m_afColorData[i] = 0.0f;
            
        rkCompute.writeBuffer("grass_colors", 0, 0, m_uiColorComponents * sizeof(float) * m_uiVertexElementCount, m_afColorData);
        rkCompute.readBuffer("grass_colors",  0, 0, m_uiColorComponents * sizeof(float) * m_uiVertexElementCount, m_afColorData);

        if(m_uiColorBufferId && m_bCopyColorData)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiColorBufferId);
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, m_uiColorComponents * sizeof(float) * m_uiMaxVertexCount, m_afColorData);
            glColorPointer(m_uiColorComponents, GL_FLOAT, 0, 0);
            glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
        }    
    }
    else if(m_uiColorBufferId && !m_bCopyColorData)
    {
        rkCompute.attachGLBuffer("grass_vertices") ; //, m_uiVertexBufferId);
        rkCompute.clearMemory("grass_vertices", 0, m_uiColorComponents * sizeof(float) * m_uiMaxVertexCount);  
        rkCompute.detachGLBuffer("grass_vertices");
    }
}

