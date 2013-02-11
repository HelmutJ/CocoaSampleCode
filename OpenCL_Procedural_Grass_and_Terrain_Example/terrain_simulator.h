//
// File:       terrain_simulator.h
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


#ifndef __TERRAIN_SIMULATOR__
#define __TERRAIN_SIMULATOR__ 

#include "compute_engine.h"

/////////////////////////////////////////////////////////////////////////////

class TerrainSimulator
{

public:

    TerrainSimulator();
    ~TerrainSimulator();

    bool reset(ComputeEngine &rkCompute);
    bool setup(ComputeEngine &rkCompute, uint uiSizeX, uint uiSizeY);
    bool update(ComputeEngine &rkCompute, uint uiIteration);
    bool compute(ComputeEngine &rkCompute, uint uiIteration);
    
public:

    void setProjectedCorners(const float4 afCorners[4]);
    void setRangeMatrix(const float16 &rkM){ m_kRangeMatrix = rkM; }
    void setInverseModelViewProjectionMatrix(const float16 &rkM) { m_kInverseModelViewProjectionMatrix = rkM; }
    void setFalloffDistance(float fV)      { m_fFalloff = fV; }
    void setCameraFov(float fV)            { m_fCameraFov = fV;    }
    void setCameraPosition(float4 fV)      { m_kCameraPosition = fV;    }
    void setCameraRotation(float4 fV)      { m_kCameraRotation = fV; }
    void setCameraFrame(float4 fUp, float4 fView, float4 fLeft)
                                           { m_kCameraUp = fUp;
                                             m_kCameraView = fView;
                                             m_kCameraLeft = fLeft; }
    void setNoiseBias(float2 fV)           { m_kNoiseBias = fV; }
    void setNoiseScale(float2 fV)          { m_kNoiseScale = fV; }
    void setNoiseAmplitude(float fV)       { m_fNoiseAmplitude = fV; }
    void setProjectedRange(float4 fV)      { m_kProjectedRange = fV;    }
    
    void setVertexBufferAttachment(uint uiId, bool bCopy)    { m_uiVertexBufferId = uiId; m_bCopyVertexData = bCopy; }
    void setNormalBufferAttachment(uint uiId, bool bCopy)    { m_uiNormalBufferId = uiId; m_bCopyNormalData = bCopy; }
    void setTexCoordBufferAttachment(uint uiId, bool bCopy)  { m_uiTexCoordBufferId = uiId; m_bCopyTexCoordData = bCopy; }
                                            
public:
                                             
    float getFalloffDistance()             { return m_fFalloff;         }
    float getCameraFov()                   { return m_fCameraFov;       }
    const float4& getCameraPosition(float4 fV)      { return m_kCameraPosition;    }
    const float2& getNoiseBias()           { return m_kNoiseBias; }
    const float2& getNoiseScale()          { return m_kNoiseScale; }
    float getNoiseAmplitude()              { return m_fNoiseAmplitude; }
    
    float* getVertexData()                  { return m_afVertexData;   }
    uint getVertexCount()                   { return m_uiVertexCount;  }
    uint getVertexBytes()                   { return m_uiVertexBytes;  }
    uint getVertexComponentCount()          { return m_uiVertexComponents; }
    uint getVertexBufferAttachment()        { return m_uiVertexBufferId; }

    float* getNormalData()                  { return m_afNormalData;   }
    uint getNormalCount()                   { return m_uiNormalCount;     }
    uint getNormalBytes()                   { return m_uiNormalBytes;  }
    uint getNormalComponentCount()          { return m_uiNormalComponents; }
    uint getNormalBufferAttachment()        { return m_uiNormalBufferId; }
    
    float* getTexCoordData()                { return m_afTexCoordData;    }
    uint getTexCoordCount()                 { return m_uiTexCoordCount;     }
    uint getTexCoordBytes()                 { return m_uiTexCoordBytes;   }
    uint getTexCoordComponentCount()        { return m_uiTexCoordComponents; }
    uint getTexCoordBufferAttachment()      { return m_uiTexCoordBufferId; }

    uint getRequiredVertexBufferSize(uint uiSizeX, uint uiSizeZ);
    uint getRequiredNormalBufferSize(uint uiSizeX, uint uiSizeZ);
    uint getRequiredTexCoordBufferSize(uint uiSizeX, uint uiSizeZ);
    
protected:

    virtual void destroy();
    virtual bool allocate(uint uiSizeX, uint uiSizeY);

    void attachMemory(ComputeEngine &rkCompute);
    void detachMemory(ComputeEngine &rkCompute);
    void clearMemory(ComputeEngine &rkCompute);
    void updateOutputs(ComputeEngine &rkCompute);
    
protected:

    bool m_bInitialized;
	uint m_uiKernelArgCount;
	uint m_auiLocalDim[2];
	uint m_auiGlobalDim[2];

	void** m_apvKernelArgValues;
	size_t* m_atKernelArgSizes;
    
    uint m_uiSizeX;
    uint m_uiSizeY;
    
    float m_fJitterAmount;
    float m_fCameraFov;
    float4 m_kCameraPosition;
    float4 m_kCameraRotation;
    float4 m_kCameraUp;
    float4 m_kCameraView;
    float4 m_kCameraLeft;
    
    float4 m_kProjectedRange;
    float4 m_akProjectedCorners[4];

    float2 m_kNoiseBias;
    float2 m_kNoiseScale;
    float m_fNoiseAmplitude;
        
    float *m_afVertexData;
    uint m_uiVertexBytes;
    uint m_uiVertexCount;
    uint m_uiVertexComponents;
    uint m_uiVertexBufferId;
    bool m_bCopyVertexData;
    
    float *m_afNormalData;
    uint m_uiNormalBytes;
    uint m_uiNormalCount;
    uint m_uiNormalComponents;
    uint m_uiNormalBufferId;
    bool m_bCopyNormalData;
    
    float *m_afTexCoordData;
    uint m_uiTexCoordBytes;
    uint m_uiTexCoordCount;
    uint m_uiTexCoordComponents;
    uint m_uiTexCoordBufferId;
    bool m_bCopyTexCoordData;
    
    float2 m_kClipRange;
    float m_fFalloff;
    
    float16 m_kRangeMatrix;
    float16 m_kInverseModelViewProjectionMatrix;

};

/////////////////////////////////////////////////////////////////////////////


#endif
