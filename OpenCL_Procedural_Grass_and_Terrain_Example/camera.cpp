//
// File:       camera.cpp
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


#include "camera.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/glu.h>
#include <stdio.h>
#include <math.h>

static const float3 CAMERA_AXIS_X = make_float3(1.0f, 0.0f, 0.0f);
static const float3 CAMERA_AXIS_Y = make_float3(0.0f, 1.0f, 0.0f);
static const float3 CAMERA_AXIS_Z = make_float3(0.0f, 0.0f, 1.0f);

Camera::Camera() :
    m_bDebug(false),
    m_fInertia(0.1f),
    m_fYaw(0.0f),
    m_fPitch(0.0f),
    m_fRoll(0.0f),
    m_fZoom(1.0f),
    m_fFovX(60.0f),
    m_fFovY(60.0f),
    m_fAspect(1.0f),
    m_fNearClip(0.1f),
    m_fFarClip(10000.0f),
    m_uiViewportWidth(0),
    m_uiViewportHeight(0)
{
    m_kUp = m_kUpAxis = make_float3(0.0f, 1.0f, 0.0f);
    m_kView = m_kViewAxis = make_float3(0.0f, 0.0f, 1.0f);
    m_kLeft = m_kLeftAxis = normalize(cross(m_kViewAxis, m_kUpAxis));

    m_kPosition = make_float3(0.0f, 1.0f, 0.0f);
    m_kPositionLag = make_float3(0.0f, 1.0f, 0.0f);
}

Camera::Camera(
    const Camera& rkOther)
{
    m_bDebug = rkOther.m_bDebug;

    m_fInertia = rkOther.m_fInertia;

    m_fYaw = rkOther.m_fYaw;
    m_fPitch = rkOther.m_fPitch;
    m_fRoll = rkOther.m_fRoll;

    m_kRotation = rkOther.m_kRotation;
    m_kRotationLag = rkOther.m_kRotationLag;

    m_fZoom = rkOther.m_fZoom;
    m_fFovX = rkOther.m_fFovX;
    m_fFovY = rkOther.m_fFovY;

    m_fAspect = rkOther.m_fAspect;

    m_fNearClip = rkOther.m_fNearClip;
    m_fFarClip = rkOther.m_fFarClip;

    m_uiViewportWidth = rkOther.m_uiViewportWidth;
    m_uiViewportHeight = rkOther.m_uiViewportHeight;

    m_kPosition = rkOther.m_kPosition;
    m_kPositionLag = rkOther.m_kPositionLag;

    m_kUp = rkOther.m_kUp;
    m_kLeft = rkOther.m_kLeft;
    m_kView = rkOther.m_kView;

    m_kUpAxis = rkOther.m_kUpAxis;
    m_kLeftAxis = rkOther.m_kLeftAxis;
    m_kViewAxis = rkOther.m_kViewAxis;

    m_kProjectionMatrix = rkOther.m_kProjectionMatrix;
    m_kModelViewMatrix = rkOther.m_kModelViewMatrix;
    m_kInverseModelViewMatrix = rkOther.m_kInverseModelViewMatrix;
    m_kActualModelViewMatrix = rkOther.m_kActualModelViewMatrix;

    m_kModelViewProjectionMatrix = rkOther.m_kModelViewProjectionMatrix;
    m_kInverseModelViewProjectionMatrix = rkOther.m_kInverseModelViewProjectionMatrix; 
}

Camera::~Camera()
{
    // EMPTY!
}
    
void 
Camera::update(bool bOrbit)
{
    updateProjectionMatrix();
    updateModelViewMatrix(bOrbit);
    
    m_kInverseModelViewMatrix = inverse(m_kModelViewMatrix);
    m_kModelViewProjectionMatrix = m_kActualModelViewMatrix * m_kProjectionMatrix;
    m_kInverseModelViewProjectionMatrix = inverse(m_kModelViewProjectionMatrix);
}

void
Camera::enable()
{
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadMatrixf(m_kProjectionMatrix);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadMatrixf(m_kModelViewMatrix);   

}

void
Camera::disable()
{
    if(m_bDebug)
        drawFrustum();

    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();

    glMatrixMode(GL_PROJECTION);
    glPopMatrix();

    glMatrixMode(GL_MODELVIEW);
}

void
Camera::orbit(float fDX, float fDY)
{
    m_fPitch += fDY;
    m_fYaw += fDX;
}

void
Camera::yaw(float fAngle)
{
    m_fYaw += fAngle;
}
   
void 
Camera::pitch(float fAngle)
{
    m_fPitch += fAngle;
}

void 
Camera::roll(float fAngle)
{
    m_fRoll += fAngle;
}

void 
Camera::strafe(float fStep)
{
    m_kPosition += m_kLeft * fStep;
}

void 
Camera::forward(float fStep)
{
    m_kPosition += m_kView * fStep;
}

void 
Camera::elevate(float fStep)
{
    m_kPosition += m_kUp * fStep;
}

void
Camera::updateProjectionMatrix()
{
    m_fFovX = m_fFovY * m_fAspect;
	float fFar = (m_bDebug) ? (m_fFarClip * 1.2f) : m_fFarClip;
    float fFovRadians = radians(m_fZoom * m_fFovX);
    m_kProjectionMatrix = perspective(fFovRadians, m_fAspect, m_fNearClip, fFar);  
}

void
Camera::updateModelViewMatrix(bool bOrbit)
{
    m_kRotation.x = m_fYaw;
    m_kRotation.y = m_fPitch;
    m_kRotation.z = m_fRoll;
    
    m_kPositionLag += (m_kPosition - m_kPositionLag) * m_fInertia; 
    m_kRotationLag += (m_kRotation - m_kRotationLag) * m_fInertia; 

    float16 kRotate;
    
    if(bOrbit)
        kRotate = translation(-m_kPosition);
    
    if(m_kRotationLag.y)
        kRotate *= rotation(CAMERA_AXIS_X, radians(m_kRotationLag.y));

    if(m_kRotationLag.x)
        kRotate *= rotation(CAMERA_AXIS_Y, radians(m_kRotationLag.x));

    if(m_kRotationLag.z)
        kRotate *= rotation(CAMERA_AXIS_Z, radians(m_kRotationLag.z));

    m_kModelViewMatrix = kRotate;
    m_kActualModelViewMatrix = m_kModelViewMatrix;

    m_kView = normalize(m_kModelViewMatrix * m_kViewAxis);
    m_kUp = normalize(m_kModelViewMatrix * m_kUpAxis);
    m_kLeft = normalize(cross(m_kView, m_kUp));
    
    if(bOrbit == false)
    {
        float3 fUp = m_kUp; 
        float3 fLeft = m_kLeft; 
        float3 fView = m_kView; 
    
        float3 fPosition = m_kPositionLag;
        float3 fLookAt = fPosition + fView;
        
        m_kModelViewMatrix = look(fPosition, fLookAt, fUp);
        m_kActualModelViewMatrix = m_kModelViewMatrix;
    }
    
    if(m_bDebug)
    {
        float fD = 0.005f * m_fFarClip;

        float3 fUp = m_kUp; 
        float3 fLeft = m_kLeft; 
        float3 fView = m_kView; 
    
        float3 fPosition = m_kPositionLag;
        float3 fLookAt = fPosition + fView;

        fPosition = m_kPosition + fUp * fD + fLeft * fD - fView * fD;
        fLookAt =  m_kPosition + fView * m_fFarClip * 0.005f;
        
        m_kModelViewMatrix = look(fPosition, fLookAt, fUp);
    }
}

void
Camera::drawFrustum()
{
    static const float4 akPoints[24] = 
    { 
        make_float4(-1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(-1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, -1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, -1.0f, 1.0f),

        make_float4(-1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(-1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, +1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, +1.0f, 1.0f),

        make_float4(-1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(-1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, -1.0f, +1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, -1.0f, 1.0f),
        make_float4(-1.0f, +1.0f, +1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, -1.0f, 1.0f),
        make_float4(+1.0f, +1.0f, +1.0f, 1.0f)
    };

    float16 kInvViewPrj = inverse((m_kActualModelViewMatrix * m_kProjectionMatrix));

    glPushAttrib(GL_LIGHTING_BIT);
    glPushAttrib(GL_CURRENT_BIT);

    glPushMatrix();    
    {
        glColor3f(1.0f, 1.0f, 1.0f);
        glBegin(GL_LINES);
        for(uint i = 0; i < 24; i ++)
        {
            float4 kP = kInvViewPrj * akPoints[i];
            kP /= kP.w;
            
            glVertex3f(kP.x, kP.y, kP.z);
        }
        glEnd();
    }
    glPopMatrix();
    
    glPopAttrib();
    glPopAttrib();
}


