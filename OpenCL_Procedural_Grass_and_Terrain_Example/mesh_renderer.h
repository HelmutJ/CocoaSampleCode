//
// File:       mesh_renderer.h
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

#ifndef __MESH_RENDERER__
#define __MESH_RENDERER__

#include "compute_types.h"
#include <OpenGL/gl.h>

class MeshRenderer
{

public:

    MeshRenderer();
    ~MeshRenderer();
    
    bool render(uint uiPrimitiveType = GL_QUAD_STRIP, uint uiColorMode = 0);
    
    void setVertexData(float *afData, uint uiComponents, uint uiCount, bool bCopy = false);
    void setVertexBuffer(uint uiId, uint uiComponents, uint uiCount);

    void setNormalData(float *afData, uint uiComponents, uint uiCount, bool bCopy = false);
    void setNormalBuffer(uint uiId, uint uiComponents, uint uiCount);

    void setTexCoordData(float *afData, uint uiComponents, uint uiCount, bool bCopy = false);
    void setTexCoordBuffer(uint uiId, uint uiComponents, uint uiCount);
    
    void setColorData(float *afData, uint uiComponents, uint uiCount, bool bCopy = false);
    void setColorBuffer(uint uiId, uint uiComponents, uint uiCount);
    
    bool createGridIndexBuffer(uint uiSizeX, uint uiSizeY);
    
protected:
    
    float *m_afVertexData;
    uint m_uiVertexBytes;
    uint m_uiVertexCount;
    uint m_uiVertexComponents;
    uint m_uiVertexBufferId;
    bool m_bVertexDataOwner;

    float *m_afNormalData;
    uint m_uiNormalBytes;
    uint m_uiNormalCount;
    uint m_uiNormalComponents;
    uint m_uiNormalBufferId;
    bool m_bNormalDataOwner;

    float *m_afTexCoordData;
    uint m_uiTexCoordBytes;
    uint m_uiTexCoordCount;
    uint m_uiTexCoordComponents;
    uint m_uiTexCoordBufferId;
    bool m_bTexCoordDataOwner;

    float *m_afColorData;
    uint m_uiColorBytes;
    uint m_uiColorCount;
    uint m_uiColorComponents;
    uint m_uiColorBufferId;
    bool m_bColorDataOwner;
    
    uint* m_auiIndexData;  
    uint m_uiIndexBytes;       
    uint m_uiIndexBufferId;
    uint m_uiIndexCount;       
    bool m_bIndexBufferDataOwner;
};

#endif
