//
// File:       camera.h
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

#ifndef __CAMERA_H__
#define __CAMERA_H__

#include "compute_types.h"
#include "compute_math.h"

////////////////////////////////////////////////////////////////////////////////

class Camera
{

public:
    Camera();
    Camera( const Camera& rkOther );
    ~Camera();
    
    void enable();
    void disable();
    void update(bool bOrbit = false);
    
    void orbit(float fDX, float fDY);
    void yaw(float fStep);
    void pitch(float fStep);
    void roll(float fStep);
    void strafe(float fStep);
    void forward(float fStep);
    void elevate(float fStep);
    void drawFrustum();
    
public:

    void setDebug(bool bV)                          { m_bDebug = bV;                }
    void setInertia(float fV)                       { m_fInertia = fV;              }
    void setYaw(float fV)                           { m_fYaw = fV;                  }
    void setPitch(float fV)                         { m_fPitch = fV;                }
    void setRoll(float fV)                          { m_fRoll = fV;                 }
    void setZoom(float fV)                          { m_fZoom = fV;                 }
    void setFovInDegrees(float fV)                  { m_fFovY = fV; 
                                                      m_fFovX = m_fAspect * m_fFovY;}
    void setAspect(float fV)                        { m_fAspect = fV; 
                                                      m_fFovX = m_fAspect * m_fFovY;}    
    void setNearClip(float fV)                      { m_fNearClip = fV;             }
    void setFarClip(float fV)                       { m_fFarClip = fV;              }
    void setViewport(uint uiW, uint uiH)            { m_uiViewportWidth = uiW; 
                                                      m_uiViewportHeight = uiH;     }
    void setPosition(float3 fV)                     { m_kPosition = fV; m_kPositionLag = fV; }
    void setRotation(float3 fV)                     { m_kRotation = fV; m_kRotationLag = fV; 
                                                      m_fPitch = fV.x; m_fYaw = fV.y; m_fRoll = fV.z; }
    void setFrame(float3 fUp, float3 fView, float3 fLeft)  
                                                    { m_kUp = fUp;
                                                      m_kLeft = fLeft;
                                                      m_kView = fView;              }
                                          
    bool getDebug() const                           { return m_bDebug;              }
    float getInertia() const                        { return m_fInertia;            }
    float getYaw()const                             { return m_fYaw;                }
    float getPitch()const                           { return m_fPitch;              }
    float getRoll() const                           { return m_fRoll;               }
    float getZoom() const                           { return m_fZoom;               }
    float getFovInDegrees() const                   { return m_fFovY;               }
    float getAspect() const                         { return m_fAspect;             }
    float getNearClip() const                       { return m_fNearClip;           }
    float getFarClip() const                        { return m_fFarClip;            }
    uint getViewportWidth() const                   { return m_uiViewportWidth;     }
    uint getViewportHeight() const                  { return m_uiViewportHeight;    }
    
    const float3& getPosition() const               { return m_kPositionLag;        }
    const float3& getRotation() const               { return m_kRotationLag;        }
    const float3& getUpDirection() const            { return m_kUp;                 }
    const float3& getLeftDirection() const          { return m_kLeft;               }
    const float3& getViewDirection() const          { return m_kView;               }
    const float16& getProjectionMatrix() const      { return m_kProjectionMatrix;   }
    const float16& getActualModelViewMatrix() const { return m_kActualModelViewMatrix; }
    const float16& getModelViewMatrix() const       { return m_kModelViewMatrix;    }
    const float16& getInverseModelViewMatrix() const           { return m_kInverseModelViewMatrix;    }
    const float16& getModelViewProjectionMatrix() const        { return m_kModelViewProjectionMatrix; }
    const float16& getInverseModelViewProjectionMatrix() const { return m_kInverseModelViewProjectionMatrix; }
    
protected:
    void updateProjectionMatrix();
    void updateModelViewMatrix(bool bOrbit);
    
protected:

    bool m_bDebug;
    
    float m_fInertia;
    
    float m_fYaw;
    float m_fPitch;
    float m_fRoll;
    
    float3 m_kRotation;
    float3 m_kRotationLag;
    
    float m_fZoom;
    float m_fFovX;
    float m_fFovY;
    
    float m_fAspect;
    
    float m_fNearClip;
    float m_fFarClip;
    
    uint m_uiViewportWidth;
    uint m_uiViewportHeight;
    
    float3 m_kPosition;
    float3 m_kPositionLag;
    
    float3 m_kUp;
    float3 m_kLeft;
    float3 m_kView;

    float3 m_kUpAxis;
    float3 m_kLeftAxis;
    float3 m_kViewAxis;
    
    float16 m_kProjectionMatrix;
    float16 m_kModelViewMatrix;
    float16 m_kInverseModelViewMatrix;
    float16 m_kActualModelViewMatrix;
    
    float16 m_kModelViewProjectionMatrix;
    float16 m_kInverseModelViewProjectionMatrix;
};

////////////////////////////////////////////////////////////////////////////////

#endif
