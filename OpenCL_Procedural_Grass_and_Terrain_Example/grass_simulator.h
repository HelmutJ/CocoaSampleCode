//
// File:       grass_simulator.h
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


#ifndef __GRASS_SIMULATOR__
#define __GRASS_SIMULATOR__ 

#include "compute_engine.h"

/////////////////////////////////////////////////////////////////////////////

class GrassSimulator
{

public:

    GrassSimulator();
    ~GrassSimulator();

    bool reset(ComputeEngine &rkCompute);
    
    bool setup(ComputeEngine &rkCompute, 
            uint uiBladeCount, uint uiRows, uint uiColumns);

    bool computeGrassOnTerrain(ComputeEngine &rkCompute, uint uiIteration);

    bool computeBlades(ComputeEngine &rkCompute, uint uiIteration);
    bool computeCurves(ComputeEngine &rkCompute, uint uiIteration);
    
public:
    
    void setJitterAmount(float fV)         { m_fJitterAmount = fV; }
    void setClipRange(float2 fV)           { m_kClipRange = fV; }
    void setFalloffDistance(float fV)      { m_fFalloff = fV; }
    void setCameraFov(float fV)            { m_fCameraFov = fV;    }
    void setCameraPosition(float4 fV)      { m_kCameraPosition = fV;    }
    void setCameraRotation(float4 fV)      { m_kCameraRotation = fV;    }
    void setCameraFrame(float4 fUp, float4 fView, float4 fLeft)
                                           { m_kCameraUp = fUp;
                                             m_kCameraView = fView;
                                             m_kCameraLeft = fLeft; }
    void setMaxSegmentCount(uint uiV)      { m_uiMaxSegmentCount = uiV; }
    void setMaxElementCount(uint uiV)      { m_uiMaxElementCount = uiV; }
    void setBladeIntensity(float fV)       { m_fBladeIntensity = fV; }
    void setBladeOpacity(float fV)         { m_fBladeOpacity = fV; }
    void setFlowScale(float fV)            { m_fFlowScale = fV; }
    void setFlowSpeed(float fV)            { m_fFlowSpeed = fV; }
    void setFlowAmount(float fV)           { m_fFlowAmount = fV; }
    void setNoiseBias(float2 fV)           { m_kNoiseBias = fV; }
    void setNoiseScale(float2 fV)          { m_kNoiseScale = fV; }
    void setNoiseAmplitude(float fV)       { m_fNoiseAmplitude = fV; }
    void setBladeLengthRange(float2 fV)    { m_kBladeLengthRange = fV; }    
    void setBladeThicknessRange(float2 fV) { m_kBladeThicknessRange = fV; }
    
    void setVertexBufferAttachment(uint uiId, bool bCopy) { m_uiVertexBufferId = uiId; m_bCopyVertexData = bCopy; }
    void setColorBufferAttachment(uint uiId, bool bCopy)  { m_uiColorBufferId = uiId; m_bCopyColorData = bCopy; }

    void setHeightFieldBufferAttachment(
        const char* acMemObjName,
        uint uiVId, uint uiNId, 
        uint uiSizeX, uint uiSizeY,
        bool bCopy)
    {
        m_acHeightFieldMemObjName = acMemObjName; // pointer copy
        m_uiHeightFieldVertexBufferId = uiVId;
        m_uiHeightFieldNormalBufferId = uiNId;
        m_uiHeightFieldSizeX = uiSizeX;
        m_uiHeightFieldSizeY = uiSizeY;    
        m_bCopyHeightFieldData = bCopy;
    }
                                            
public:
                                             
    const float2& getClipRange()           { return m_kClipRange;       }
    float getJitterAmount()                { return m_fJitterAmount;    }
    float getFalloffDistance()             { return m_fFalloff;         }
    float getCameraFov()                   { return m_fCameraFov;       }
    const float4& getCameraPosition(float4 fV)      { return m_kCameraPosition;    }
    float getBladeIntensity()              { return m_fBladeIntensity; }
    float getBladeOpacity()                { return m_fBladeOpacity; }
    float getFlowScale()                   { return m_fFlowScale; }
    float getFlowSpeed()                   { return m_fFlowSpeed; }
    float getFlowAmount()                  { return m_fFlowAmount; }
    const float2& getNoiseBias()           { return m_kNoiseBias; }
    const float2& getNoiseScale()          { return m_kNoiseScale; }
    float getNoiseAmplitude()              { return m_fNoiseAmplitude; }
    const float2& getBladeLengthRange()    { return m_kBladeLengthRange; }    
    const float2& getBladeThicknessRange() { return m_kBladeThicknessRange; }    
    
    uint getVertexBufferAttachment()       { return m_uiVertexBufferId; }
    uint getColorBufferAttachment()        { return m_uiColorBufferId; }

    float* getVertexData()                 { return m_afVertexData;   }
    float* getColorData()                  { return m_afColorData;    }
    uint* getSegmentData()                 { return m_auiSegmentData; }
    uint* getElementData()                 { return m_auiElementData; }

    uint getVertexBytes()                  { return m_uiVertexBytes;  }
    uint getVertexComponentCount()         { return m_uiVertexComponents; }
    uint getColorBytes()                   { return m_uiColorBytes;   }
    uint getColorComponentCount()          { return m_uiColorComponents; }
    uint getSegmentBytes()                 { return m_uiSegmentBytes; }
    uint getElementBytes()                 { return m_uiElementBytes; }

    uint getMaxSegmentCount()              { return m_uiMaxSegmentCount; }
    uint getMaxElementCount()              { return m_uiMaxElementCount; }
    uint getMaxVertexCount()               { return m_uiMaxVertexCount;  }
    
    uint getRequiredVertexBufferSize(uint uiBladeCount);
    uint getRequiredColorBufferSize(uint uiBladeCount);
    
protected:

    virtual void destroy();
    virtual bool allocate(uint uiBladeCount);

    void attachMemory(ComputeEngine &rkCompute);
    void detachMemory(ComputeEngine &rkCompute);
    void clearMemory(ComputeEngine &rkCompute);
    void updateOutputs(ComputeEngine &rkCompute);
    
protected:

    bool m_bInitialized;
	uint m_uiKernelArgCount;
	uint m_auiLocalDim[2];
	uint m_auiGlobalDim[2];
	uint m_uiWorkItemCount;

    uint m_uiRowCount;
    uint m_uiColumnCount;
    uint m_uiBladeCount;
    
    uint m_uiMaxSegmentCount;
    uint m_uiMaxElementCount;
    uint m_uiMaxVertexCount;
    
    float m_fJitterAmount;
    float m_fCameraFov;
    float4 m_kCameraPosition;
    float4 m_kCameraRotation;
    float4 m_kCameraUp;
    float4 m_kCameraView;
    float4 m_kCameraLeft;
    
    float2 m_kBladeLengthRange;
    float2 m_kBladeThicknessRange;
    
    float2 m_kNoiseBias;
    float2 m_kNoiseScale;
    float m_fNoiseAmplitude;
            
    float m_fBladeIntensity;
    float m_fBladeOpacity;
    
    float m_fFlowScale;
    float m_fFlowSpeed;
    float m_fFlowAmount;
    
    float *m_afVertexData;
    uint m_uiVertexBytes;
    uint m_uiVertexCount;
    uint m_uiVertexComponents;
    bool m_bCopyVertexData;

    float *m_afColorData;
    uint m_uiColorBytes;
    uint m_uiColorCount;
    uint m_uiColorComponents;
    bool m_bCopyColorData;

    uint *m_auiSegmentData;
    uint m_uiSegmentBytes;
    uint m_uiSegmentCount;

    uint *m_auiElementData;
    uint m_uiElementBytes;
    uint m_uiElementCount;
    
    uint m_uiVertexBufferId;
    uint m_uiColorBufferId;
    
    uint m_uiVertexElementCount;
        
    const char* m_acHeightFieldMemObjName;
    uint m_uiHeightFieldVertexBufferId;
    uint m_uiHeightFieldNormalBufferId;
    uint m_uiHeightFieldSizeX;
    uint m_uiHeightFieldSizeY;    
    bool m_bCopyHeightFieldData;
    
    float2 m_kClipRange;
    float m_fFalloff;
};

/////////////////////////////////////////////////////////////////////////////


#endif
