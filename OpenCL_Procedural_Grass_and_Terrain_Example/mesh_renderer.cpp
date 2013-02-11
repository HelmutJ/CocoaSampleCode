//
// File:       mesh_renderer.cpp
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

#include "mesh_renderer.h"
#include "compute_math.h"

#define odd(x) (x%2)

MeshRenderer::MeshRenderer() :
    m_afVertexData(0),
    m_uiVertexBytes(0),
    m_uiVertexCount(0),
    m_uiVertexComponents(0),
    m_uiVertexBufferId(0),
    m_bVertexDataOwner(0),
    m_afNormalData(0),
    m_uiNormalBytes(0),
    m_uiNormalCount(0),
    m_uiNormalComponents(0),
    m_uiNormalBufferId(0),
    m_bNormalDataOwner(0),
    m_afTexCoordData(0),
    m_uiTexCoordBytes(0),
    m_uiTexCoordCount(0),
    m_uiTexCoordComponents(0),
    m_uiTexCoordBufferId(0),
    m_bTexCoordDataOwner(0),
    m_afColorData(0),
    m_uiColorBytes(0),
    m_uiColorCount(0),
    m_uiColorComponents(0),
    m_uiColorBufferId(0),
    m_bColorDataOwner(0),
    m_auiIndexData(0),  
    m_uiIndexBytes(0),       
    m_uiIndexBufferId(0),
    m_uiIndexCount(0),       
    m_bIndexBufferDataOwner(0)
{
    // EMPTY!
}

MeshRenderer::~MeshRenderer()
{
    if(m_bVertexDataOwner && m_afVertexData)
        delete [] m_afVertexData;
    
    m_afVertexData = 0;
    m_uiVertexComponents = 0;
    m_uiVertexCount = 0;

    if(m_bNormalDataOwner && m_afNormalData)
        delete [] m_afNormalData;

    m_afNormalData = 0;
    m_uiNormalComponents = 0;
    m_uiNormalCount = 0;

    if(m_bTexCoordDataOwner && m_afTexCoordData)
        delete [] m_afTexCoordData;
    
    m_afTexCoordData = 0;
    m_uiTexCoordComponents = 0;
    m_uiTexCoordCount = 0;

    if(m_bColorDataOwner && m_afColorData)
        delete [] m_afColorData;
    
    m_afColorData = 0;
    m_uiColorComponents = 0;
    m_uiColorCount = 0;
}

void MeshRenderer::setVertexBuffer(
    uint uiId, uint uiComponents, uint uiCount)
{
    m_uiVertexBufferId = uiId;
    m_uiVertexComponents = uiComponents;
    m_uiVertexCount = uiCount;
    m_uiVertexBytes = m_uiVertexComponents * m_uiVertexCount * sizeof(float);
}


void MeshRenderer::setNormalBuffer(
    uint uiId, uint uiComponents, uint uiCount)
{
    m_uiNormalBufferId = uiId;
    m_uiNormalComponents = uiComponents;
    m_uiNormalCount = uiCount;
    m_uiNormalBytes = m_uiNormalComponents * m_uiNormalCount * sizeof(float);

}

void MeshRenderer::setTexCoordBuffer(
    uint uiId, uint uiComponents, uint uiCount)
{
    m_uiTexCoordBufferId = uiId;
    m_uiTexCoordComponents = uiComponents;
    m_uiTexCoordCount = uiCount;
    m_uiTexCoordBytes = m_uiTexCoordComponents * m_uiTexCoordCount * sizeof(float);
}

void MeshRenderer::setColorBuffer(
    uint uiId, uint uiComponents, uint uiCount)
{
    m_uiColorBufferId = uiId;
    m_uiColorComponents = uiComponents;
    m_uiColorCount = uiCount;
    m_uiColorBytes = m_uiColorComponents * m_uiColorCount * sizeof(float);
}

void MeshRenderer::setVertexData(
    float *afData, 
    uint uiComponents, 
    uint uiCount, 
    bool bCopy)
{
    if(bCopy)
    {
        if(m_bVertexDataOwner && m_afVertexData)
            delete [] m_afVertexData;
        
        m_afVertexData = new float[uiComponents * uiCount];
        m_uiVertexComponents = uiComponents;
        m_uiVertexCount = uiCount;

        for(uint i = 0; i < uiComponents * uiCount; i++)
        {
            m_afVertexData[i] = afData[i];
        }   
        m_bVertexDataOwner = true;
    }
    else
    {
        m_afVertexData = afData;
        m_bVertexDataOwner = false;
    }

    m_uiVertexBytes = m_uiVertexComponents * m_uiVertexCount * sizeof(float);
}

void MeshRenderer::setNormalData(
    float *afData, 
    uint uiComponents, 
    uint uiCount, 
    bool bCopy)
{
    if(bCopy)
    {
        if(m_afNormalData)
            delete [] m_afNormalData;
        
        m_afNormalData = new float[uiComponents * uiCount];
        m_uiNormalComponents = uiComponents;
        m_uiNormalCount = uiCount;

        for(uint i = 0; i < uiComponents * uiCount; i++)
        {
            m_afNormalData[i] = afData[i];
        }   
        m_bNormalDataOwner = true;
    }
    else
    {
        m_afNormalData = afData;
        m_bNormalDataOwner = false;
    }
    
    m_uiNormalBytes = m_uiNormalComponents * m_uiNormalCount * sizeof(float);
}

void MeshRenderer::setTexCoordData(
    float *afData, 
    uint uiComponents, 
    uint uiCount, 
    bool bCopy)
{
    if(bCopy)
    {
        if(m_afTexCoordData)
            delete [] m_afTexCoordData;
        
        m_afTexCoordData = new float[uiComponents * uiCount];
        m_uiTexCoordComponents = uiComponents;
        m_uiTexCoordCount = uiCount;

        for(uint i = 0; i < uiComponents * uiCount; i++)
        {
            m_afTexCoordData[i] = afData[i];
        }   
        m_bTexCoordDataOwner = true;
    }
    else
    {
        m_afTexCoordData = afData;
        m_bTexCoordDataOwner = false;
    }
    m_uiTexCoordBytes = m_uiTexCoordComponents * m_uiTexCoordCount * sizeof(float);
}

void MeshRenderer::setColorData(
    float *afData, 
    uint uiComponents, 
    uint uiCount, 
    bool bCopy)
{
    if(bCopy)
    {
        if(m_afColorData)
            delete [] m_afColorData;
        
        m_afColorData = new float[uiComponents * uiCount];
        m_uiColorComponents = uiComponents;
        m_uiColorCount = uiCount;

        for(uint i = 0; i < uiComponents * uiCount; i++)
        {
            m_afColorData[i] = afData[i];
        }   
        m_bColorDataOwner = true;
    }
    else
    {
        m_afColorData = afData;
        m_bColorDataOwner = false;
    }
    m_uiColorBytes = m_uiColorComponents * m_uiColorCount * sizeof(float);
}

bool
MeshRenderer::createGridIndexBuffer(
    uint uiCountX, uint uiCountY)
{   
    m_uiIndexCount =  2 * (uiCountY - 1) * uiCountX;
    m_auiIndexData = new uint[m_uiIndexCount];
    if(!m_uiIndexCount)
        return false;
    
    int i = 0;
    for(uint y = 0; y < uiCountY - 1; y++)
    {
        if(odd(y))
        {
            for(int x = uiCountX - 1; x >= 0; x--)
            {
                m_auiIndexData[i++] = (uiCountX*(y+1)+x);
                m_auiIndexData[i++] = (uiCountX*y+x);
            }
        }
        else
        {
            for(uint x = 0; x < uiCountX; x++)
            {
                m_auiIndexData[i++] = (uiCountX*y+x);
                m_auiIndexData[i++] = (uiCountX*(y+1)+x);
            }
        }
    }

    m_uiIndexBytes = m_uiIndexCount * sizeof(uint);

    glGenBuffersARB(1, &m_uiIndexBufferId);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, m_uiIndexBufferId);
    glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, m_uiIndexBytes, m_auiIndexData, GL_STATIC_DRAW_ARB);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
    
    return true;
}

bool MeshRenderer::render(
    uint uiPrimitiveType, uint uiColorMode)
{
    glPushMatrix();
    {        
        if(m_uiVertexBufferId)
        {
            glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);

            if(m_afVertexData)
                glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, 
                                m_uiVertexComponents * m_uiVertexCount * sizeof(float), 
                                m_afVertexData);
            
            glVertexPointer(m_uiVertexComponents, GL_FLOAT, 0, 0);
            glEnableClientState(GL_VERTEX_ARRAY);                
        }
        
        if(uiColorMode)
        {
            if(m_uiColorBufferId)
            {
                glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_uiColorBufferId);
                if(m_afColorData)
                    glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, 
                                    m_uiColorComponents * m_uiColorCount * sizeof(float), 
                                    m_afColorData);

                glColorPointer(m_uiColorComponents, GL_FLOAT, 0, 0);
                glEnableClientState(GL_COLOR_ARRAY);
            }        
        }
        else
        {
            if(m_uiNormalBufferId)
            {
                glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_uiNormalBufferId);
                if(m_afNormalData)
                    glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, 
                                    m_uiNormalComponents * m_uiNormalCount * sizeof(float), 
                                    m_afNormalData);

                glNormalPointer(GL_FLOAT, m_uiNormalComponents * sizeof(float), 0);
                glEnableClientState(GL_NORMAL_ARRAY);

            }
        }
        
        if(m_uiTexCoordBufferId)
        {
            glBindBuffer(GL_ARRAY_BUFFER_ARB, m_uiTexCoordBufferId);
        
            if(m_afTexCoordData)
                glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, 
                                m_uiTexCoordComponents * m_uiTexCoordCount * sizeof(float), 
                                m_afTexCoordData);

            glTexCoordPointer(m_uiTexCoordComponents,  GL_FLOAT, 0, 0);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        }
        
        if(m_uiIndexBufferId)
        {
            glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, m_uiIndexBufferId);
            glDrawElements(uiPrimitiveType, m_uiIndexCount, GL_UNSIGNED_INT, 0);
            glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
        }
        else
        {
            glDrawArrays(uiPrimitiveType, 0, m_uiVertexCount);
        }
        
        glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        glDisableClientState(GL_VERTEX_ARRAY);
    
    }
	glPopMatrix();
    return true;
}
