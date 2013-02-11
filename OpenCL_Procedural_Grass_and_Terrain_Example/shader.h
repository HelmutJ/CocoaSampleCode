//
// File:       shader.h
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

#ifndef __SHADER_H__
#define __SHADER_H__

#include "compute_types.h"

#include <OpenGL/gl.h>
#include <map>

class Shader
{

public:

    struct Uniform
    {
        union 
        {
            int i[16];
            float f[16];

        } value;
        
        int location;
        int length;
        bool integer;
        bool changed;
        
        Uniform() :
            location(0), length(0), integer(false), changed(false) 
        { 
            memset(value.i, 0, 16 * sizeof(int)); 
        }
        
        Uniform(const Uniform& rkOther) :
            location(rkOther.location), 
            length(rkOther.length), 
            integer(rkOther.integer), 
            changed(rkOther.changed) 
        { 
            memcpy(value.i, rkOther.value.i, 16 * sizeof(int));
        }
    };

public:

    Shader();
    ~Shader();

    void enable();
    void disable();
    void destroy();
    
    bool setUniform1f(const char* acName, float fV);
    bool setUniform2f(const char* acName, const float2 &rkV);
    bool setUniform3f(const char* acName, const float3 &rkV);
    bool setUniform4f(const char* acName, const float4 &rkV);
    bool setUniform16f(const char* acName, const float16 &rkVV);
    bool setUniform1i(const char* acName, int iV);
	GLuint getVertexAttribLocation(const char *name); 	
    
    bool compile(const char* acVertexSource, const char* acFragmentSource);
    bool loadAndCompile(const char* acVertexFilename, const char* acFragmentFilename);
    
protected:

    void checkStatus(const char* acMessage);
    
    typedef std::map<const char*, Uniform>::iterator UniformMapIter;
	std::map<const char*, Uniform, ltstr> m_akUniforms;
    uint m_uiProgram;

};

#endif
