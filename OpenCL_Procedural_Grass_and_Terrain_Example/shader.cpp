//
// File:       shader.cpp
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

#include <stdio.h>

#include "shader.h"
#include "data_loader.h"

////////////////////////////////////////////////////////////////////////////////

Shader::Shader() :
    m_uiProgram(0)
{
    m_akUniforms.clear();
}

Shader::~Shader()
{
    destroy();
}

void
Shader::destroy()
{
    if(m_uiProgram)
        glDeleteProgram(m_uiProgram);

    m_uiProgram = 0;
    
    m_akUniforms.clear();
}

void
Shader::enable()
{
    if(m_uiProgram == 0)
        return;
        
    glUseProgram(m_uiProgram);
    checkStatus("Enabling shader");
    
    UniformMapIter pkIter;
    for(pkIter = m_akUniforms.begin(); pkIter != m_akUniforms.end(); pkIter++)
    {
        Uniform kUniform = pkIter->second;
        
        if( kUniform.location < 0 )
            continue;

#ifdef DEBUG             
        char acMessage[1024] = {0};
#endif        
        switch(kUniform.length)
        {
            case 1:
            {
                if( kUniform.integer )
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform1i[%3d][%s] = [%d] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.i[ 0]);
#endif  
                    glUniform1i( kUniform.location, kUniform.value.i[0]);
                }
                else
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform1f[%3d][%s] = [%f] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.f[ 0]);
#endif  
                    glUniform1f( kUniform.location, kUniform.value.f[0]);                
                }
                break;
            }
            case 2:
            {
                if( kUniform.integer )
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform2i[%3d][%s] = [%d %d] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.i[ 0],
                        kUniform.value.i[ 1]);
#endif  
                    glUniform2iv( kUniform.location, 2, kUniform.value.i);                
                }
                else
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform2f[%3d][%s] = [%f %f] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.f[ 0],
                        kUniform.value.f[ 1]);
#endif  
                    glUniform2fv( kUniform.location, 2, kUniform.value.f);                
                }
                break;
            }
            case 3:
            {
                if( kUniform.integer )
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform3i[%3d][%s] = [%d %d %d] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.i[ 0],
                        kUniform.value.i[ 1],
                        kUniform.value.i[ 2]);
#endif  

                    glUniform3iv( kUniform.location, 3, kUniform.value.i);                
                }
                else
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform3f[%3d][%s] = [%f %f %f] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.f[ 0],
                        kUniform.value.f[ 1],
                        kUniform.value.f[ 2]);
#endif  
                    glUniform3fv( kUniform.location, 3, kUniform.value.f);                
                }
                break;
            }
            case 4:
            {
                if( kUniform.integer )
                {
#ifdef DEBUG 
                     sprintf(acMessage,
                        "Shader Uniform4i[%3d][%s] = [%d %d %d %d] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.i[ 0],
                        kUniform.value.i[ 1],
                        kUniform.value.i[ 2],
                        kUniform.value.i[ 3]);
#endif  
                    glUniform4iv( kUniform.location, 4, kUniform.value.i);                
                }
                else
                {

#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform4f[%3d][%s] = [%f %f %f %f] \n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.f[ 0],
                        kUniform.value.f[ 1],
                        kUniform.value.f[ 2],
                        kUniform.value.f[ 3]);
#endif  
                    glUniform4fv( kUniform.location, 4, kUniform.value.f);                
                }
                break;
            }
            case 16:
            {
                if( kUniform.integer == false )
                {
#ifdef DEBUG 
                    sprintf(acMessage,
                        "Shader Uniform16f[%3d][%s] = [%f %f %f %f] [%f %f %f %f] [%f %f %f %f] [%f %f %f %f]\n",
                        kUniform.location, 
                        pkIter->first,
                        kUniform.value.f[ 0],
                        kUniform.value.f[ 1],
                        kUniform.value.f[ 2],
                        kUniform.value.f[ 3],
                        kUniform.value.f[ 4],
                        kUniform.value.f[ 5],
                        kUniform.value.f[ 6],
                        kUniform.value.f[ 7],
                        kUniform.value.f[ 8],
                        kUniform.value.f[ 9],
                        kUniform.value.f[10],
                        kUniform.value.f[11],
                        kUniform.value.f[12],
                        kUniform.value.f[13],
                        kUniform.value.f[14],
                        kUniform.value.f[15]);
#endif                        
                    glUniformMatrix4fv( kUniform.location, 1, false, kUniform.value.f);                
                }
                break;           
            };
        }
#ifdef DEBUG 
        char acStatusMsg[4096];
        sprintf(acStatusMsg, "Submitting %s", acMessage );
        checkStatus(acStatusMsg);
#endif
    }
    checkStatus("Submitting uniforms");
    
}

void 
Shader::disable()
{
    glUseProgram(0);
    checkStatus("Disabling program");
}

bool 
Shader::setUniform1f(const char* acName, float fV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }

    Uniform kUniform;
    kUniform.location = iLocation;
    kUniform.length = 1;
    kUniform.integer = false;
    kUniform.value.f[0] = fV;
    m_akUniforms[acName] = kUniform;
    return true;
}

bool 
Shader::setUniform2f(const char* acName, const float2 & rkV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }
    
    Uniform kUniform;
    kUniform.location = iLocation;
    kUniform.length = 2;
    kUniform.integer = false;
    kUniform.value.f[0] = rkV.x;
    kUniform.value.f[1] = rkV.y;
    m_akUniforms[acName] = kUniform;
    return true;
}


bool 
Shader::setUniform3f(const char* acName, const float3 & rkV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }
    
    Uniform kUniform;
    kUniform.location = iLocation;
    kUniform.length = 3;
    kUniform.integer = false;
    kUniform.value.f[0] = rkV.x;
    kUniform.value.f[1] = rkV.y;
    kUniform.value.f[2] = rkV.z;
    m_akUniforms[acName] = kUniform;
    return true;
}

bool 
Shader::setUniform4f(const char* acName, const float4 &rkV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }
        
    Uniform kUniform;
    kUniform.location = iLocation;    
    kUniform.length = 4;
    kUniform.integer = false;
    kUniform.value.f[0] = rkV.x;
    kUniform.value.f[1] = rkV.y;
    kUniform.value.f[2] = rkV.z;
    kUniform.value.f[3] = rkV.w;
    m_akUniforms[acName] = kUniform;
    return true;
}

bool 
Shader::setUniform16f(const char* acName, const float16 & rkV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }

    Uniform kUniform;
    kUniform.location = iLocation;
    kUniform.length = 16;
    kUniform.integer = false;
    memcpy(kUniform.value.f, rkV, 16 * sizeof(float));
    m_akUniforms[acName] = kUniform;
    return true;    
}

bool 
Shader::setUniform1i(const char* acName, int iV)
{
    int iLocation = glGetUniformLocation(m_uiProgram, acName);
    if(iLocation < 0)
    {
        printf("Shader Error: Invalid uniform '%s', location not found! %d\n", acName, iLocation);
        return false;
    }

    Uniform kUniform;
    kUniform.location = iLocation;
    kUniform.length = 1;
    kUniform.integer = true;
    kUniform.value.i[0] = iV;
    m_akUniforms[acName] = kUniform;
    return true;
}
    
bool
Shader::compile(
    const char* acVertexPgmSrc, 
    const char* acFragPgmSrc)
{
    const uint uiMaxInfoLogLength = 1000;
	char acInfoLog[uiMaxInfoLogLength];
	int iLogLength = 0;
	
    destroy();
    
    GLuint uiVertexShader = glCreateShader(GL_VERTEX_SHADER);
    GLuint uiFragmentShader = glCreateShader(GL_FRAGMENT_SHADER);

    glShaderSource(uiVertexShader, 1, &acVertexPgmSrc, 0);
    glShaderSource(uiFragmentShader, 1, &acFragPgmSrc, 0);
    
    glCompileShader(uiVertexShader);
    glGetShaderInfoLog(uiVertexShader, uiMaxInfoLogLength, (GLsizei*) &iLogLength, (GLchar*) acInfoLog);
    if(iLogLength && strlen(acInfoLog))
        printf("Shader: Build Log:\n%s\n", acInfoLog);
    
    glCompileShader(uiFragmentShader);
    glGetShaderInfoLog(uiFragmentShader, uiMaxInfoLogLength, (GLsizei*) &iLogLength, (GLchar*) acInfoLog);
    if(iLogLength && strlen(acInfoLog))
        printf("Shader: Build Log:\n%s\n", acInfoLog);

    GLuint uiProgram = glCreateProgram();

    glAttachShader(uiProgram, uiVertexShader);
    glAttachShader(uiProgram, uiFragmentShader);

    glLinkProgram(uiProgram);

    glGetProgramInfoLog(uiProgram, uiMaxInfoLogLength, (GLsizei*) &iLogLength, (GLchar*) acInfoLog);
    if(iLogLength)
        printf("%s\n", acInfoLog);

    GLint iSuccess = 0;
    glGetProgramiv(uiProgram, GL_LINK_STATUS, &iSuccess);
    if (iSuccess == 0) 
	{
        glGetProgramInfoLog(uiProgram, uiMaxInfoLogLength, 0, acInfoLog);
        printf("Shader: Failed to link program:\n%s\n", acInfoLog);
        glDeleteProgram(uiProgram);
        uiProgram = 0;
		return false;
	}

    m_uiProgram = uiProgram;
    return true;
}

bool
Shader::loadAndCompile(
    const char* acVertexFilename,
    const char* acFragmentFilename)
{
    char *acResource = 0;
    uint uiLength = 0;
    
    char *acVertexPgmSrc = 0;
    size_t uiVertexPgmLength = 0;
    
    char *acFragmentPgmSrc = 0;
    size_t uiFragmentPgmLength = 0;
    
    FindResourcePath(acVertexFilename, &acResource, &uiLength);
    LoadTextFromFile(acResource, &acVertexPgmSrc, &uiVertexPgmLength);
    if(acResource)
        free(acResource);

    FindResourcePath(acFragmentFilename, &acResource, &uiLength);
    LoadTextFromFile(acResource, &acFragmentPgmSrc, &uiFragmentPgmLength);

    if(acResource)
        free(acResource);

    bool bSuccess = compile(acVertexPgmSrc, acFragmentPgmSrc);

    if(acVertexPgmSrc)
        free(acVertexPgmSrc);
    
    if(acFragmentPgmSrc)
        free(acFragmentPgmSrc);
        
    return bSuccess;
}


void
Shader::checkStatus(const char *acMessage)
{
    GLenum eError = glGetError();
    if(eError == GL_FALSE)
        return;

    if(acMessage)
        printf("Shader[%d]: OpenGL Error: %s\n", m_uiProgram, acMessage);
        
    switch(eError)
    {
    case(GL_INVALID_ENUM):
        printf("Shader[%d]: OpenGL Error: Invalid Enumerate!\n", m_uiProgram);
        break;
    case(GL_INVALID_VALUE):
        printf("Shader[%d]: OpenGL Error: Invalid Value!\n", m_uiProgram);
        break;
    case(GL_INVALID_OPERATION):
        printf("Shader[%d]: OpenGL Error: Invalid Operation!\n", m_uiProgram);
        break;
    case(GL_STACK_OVERFLOW):
        printf("Shader[%d]: OpenGL Error: Stack Overflow!\n", m_uiProgram);
        break;
    case(GL_STACK_UNDERFLOW):
        printf("Shader[%d]: OpenGL Error: Stack Underflow!\n", m_uiProgram);
        break;
    case(GL_OUT_OF_MEMORY):
        printf("Shader[%d]: OpenGL Error: Out of Memory!\n", m_uiProgram);
        break;
    case(GL_INVALID_FRAMEBUFFER_OPERATION_EXT):
        printf("Shader[%d]: OpenGL Error: Invalid framebuffer operation!\n", m_uiProgram);
        break;
    default:
        printf("Shader[%d]: Unknown OpenGL Error '%d'\n", m_uiProgram, (int)eError);
        break;
    }    
}

GLuint 
Shader::getVertexAttribLocation(const char *name) 
{
	return glGetAttribLocation(m_uiProgram, name);
}
