//
// File:       grid_mesh.cpp
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


#include "grid_mesh.h"
#include "compute_math.h"
#include <assert.h>

#define odd(x) (x%2)

GridMesh::GridMesh() :
    m_uiVertexBufferId(0),
    m_afVertexData(0),
    m_uiVertexCount(0),
    m_uiIndexBufferId(0),
    m_ausIndexData(0),
    m_uiIndexCount(0),
    m_uiFaceCount(0)
{
    // EMPTY!
}

GridMesh::~GridMesh()
{
    destroy();
}

bool 
GridMesh::setup(
	uint uiCountX, uint uiCountY, 
	float fX0, float fX1, 
	float fY0, float fY1, 
	bool bVertical)
{
    destroy();
    
    float fDX = (fX1 - fX0) / (uiCountX - 1);
    float fDY = (fY1 - fY0) / (uiCountY - 1);

    m_uiVertexCount = uiCountX * uiCountY;
    m_afVertexData = new GLfloat[m_uiVertexCount * 3];
    if(!m_afVertexData)
    {
        m_uiVertexCount = 0;
        return false;
    }    
    
    uint uiIndex = 0;
    for(uint y=0;  y < uiCountY; y++)
    {
        for(uint x=0; x < uiCountX; x++)
        {           
            float fX = fX0 + x * fDX;
            float fY = fY0 + y * fDY;
            
            if(bVertical)
            {
                m_afVertexData[uiIndex + 0] = fX;
                m_afVertexData[uiIndex + 1] = fY;
                m_afVertexData[uiIndex + 2] = 0.0f;            
            }
            else
            {
                m_afVertexData[uiIndex + 0] = fX;
                m_afVertexData[uiIndex + 1] = 0.0f;
                m_afVertexData[uiIndex + 2] = fY;            
            }
            uiIndex += 3;
        }
    }

    return createIndexData(uiCountX, uiCountY);
}

bool
GridMesh::setup(
    uint uiCountX, uint uiCountY, 
    float fA0, float fA1,
    float fRadialAngle, 
    bool bVertical)
{
    destroy();
    
    float fDY = 1.0f / ((float)uiCountY - 1.0f);
    float fRA = radians(90.0f);

    m_uiVertexCount = uiCountX * uiCountY;
    m_afVertexData = new GLfloat[m_uiVertexCount * 3];
    if(!m_afVertexData)
    {
        m_uiVertexCount = 0;
        return false;
    }    
    
    uint uiIndex = 0;
    for(uint y=0;  y < uiCountY; y++)
    {
        for(uint x=0; x < uiCountX; x++)
        {
            float fAngle = fRA + radians(fRadialAngle * 0.5f);
            
            float fR = fA0 + fA1 * powf((float)x, 4.0f);
            float fX = fR * cosf(fAngle * (float)y * fDY);
            float fY = fR * sinf(fAngle * (float)y * fDY);
            
            if(bVertical)
            {
                m_afVertexData[uiIndex + 0] = fX;
                m_afVertexData[uiIndex + 1] = fY;
                m_afVertexData[uiIndex + 2] = 0.0f;            
            }
            else
            {
                m_afVertexData[uiIndex + 0] = fX;
                m_afVertexData[uiIndex + 1] = 0.0f;
                m_afVertexData[uiIndex + 2] = fY;            
            }
            uiIndex += 3;
        }
    }

    return createIndexData(uiCountX, uiCountY);
}

bool
GridMesh::createIndexData(
    uint uiCountX, uint uiCountY)
{
    if(m_ausIndexData)
        delete [] m_ausIndexData;
    m_ausIndexData = 0;

    m_uiIndexCount =  2 * (uiCountY - 1) * uiCountX;
    m_ausIndexData = new unsigned short[m_uiIndexCount];
    if(!m_ausIndexData)
    {
        m_uiIndexCount = 0;
        return false;    
    }

    int i = 0;
    for(uint y = 0; y < uiCountY - 1; y++)
    {
        if(odd(y))
        {
            for(int x = uiCountX - 1; x >= 0; x--)
            {
                m_ausIndexData[i++] = (uiCountX*(y+1)+x);
                m_ausIndexData[i++] = (uiCountX*y+x);
            }
        }
        else
        {
            for(uint x = 0; x < uiCountX; x++)
            {
                m_ausIndexData[i++] = (uiCountX*y+x);
                m_ausIndexData[i++] = (uiCountX*(y+1)+x);
            }
        }
    }
    m_uiFaceCount = i-2;
    return true;
}

void 
GridMesh::createVBO()
{
    destroyVBO();
    
    glGenBuffersARB(1, &m_uiVertexBufferId);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
    glBufferDataARB(GL_ARRAY_BUFFER_ARB, 
                    m_uiVertexCount * 3 * sizeof(GLfloat),
                    m_afVertexData, GL_STATIC_DRAW_ARB);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

    glGenBuffersARB(1, &m_uiIndexBufferId);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, m_uiIndexBufferId);
    glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 
                    m_uiIndexCount * sizeof(unsigned short), 
                    m_ausIndexData, GL_STATIC_DRAW_ARB);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
}

void 
GridMesh::destroyVBO()
{
    if(m_uiVertexBufferId)
        glDeleteBuffersARB(1, &m_uiVertexBufferId);
    
    if(m_uiIndexBufferId)
        glDeleteBuffersARB(1, &m_uiIndexBufferId);
}

void 
GridMesh::render(GLenum eElementType, bool bUseVBO)
{
    if(bUseVBO)
    {
        if(!m_uiVertexBufferId)
            createVBO();
        
        assert(m_uiVertexBufferId);
        
        glBindBufferARB(GL_ARRAY_BUFFER_ARB, m_uiVertexBufferId);
        glVertexPointer(3, GL_FLOAT, 0, 0);
        glEnableClientState(GL_VERTEX_ARRAY);

        glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, m_uiIndexBufferId);
        glDrawElements(eElementType, m_uiIndexCount, GL_UNSIGNED_SHORT, 0);

        glDisableClientState(GL_VERTEX_ARRAY);
        glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
        glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
    }
    else
    {
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, m_afVertexData);
        glDrawElements(eElementType, m_uiIndexCount, GL_UNSIGNED_SHORT, m_ausIndexData);
        glDisableClientState(GL_VERTEX_ARRAY);    
    }
}

unsigned int 
GridMesh::getTriangleCount()
{
    return m_uiFaceCount;
}

void 
GridMesh::addVertex(
    float x, float y, float z)
{
    uint uiIndex = m_uiVertexCount * 3;
    m_afVertexData[uiIndex + 0] = x;
    m_afVertexData[uiIndex + 1] = y;
    m_afVertexData[uiIndex + 2] = z;
    m_uiVertexCount++;
}

void 
GridMesh::destroy()
{
    if(m_afVertexData)
        delete [] m_afVertexData;
    m_uiVertexCount = 0;
    
    if(m_ausIndexData)
        delete [] m_ausIndexData;
    m_uiIndexCount = 0;
}

