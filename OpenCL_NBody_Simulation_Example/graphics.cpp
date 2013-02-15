//
// File:       graphics.cpp
//
// Abstract:   This example performs an NBody simulation which calculates a gravity field 
//             and corresponding velocity and acceleration contributions accumulated 
//             by each body in the system from every other body.  This example
//             also shows how to mitigate computation between all available devices
//             including CPU and GPU devices, as well as a hybrid combination of both,
//             using separate threads for each simulator.
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

////////////////////////////////////////////////////////////////////////////////

#include <ApplicationServices/ApplicationServices.h>

#include "graphics.h"
#include "NSViewTexture.h"
#include "data.h"

GLuint CreateTextureWithLabel(
    std::string const &text, 
    float size, 
    bool italic, 
    unsigned width, 
    unsigned height)
{
    return CreateTextureWithLabelUseFont( text, size, italic ? "Arial Bold Italic" : "Arial Bold", width, height, 0 );
}

// alignment: -1 (left), 0 (center), 1 (right) otherwise (natural)
GLuint CreateTextureWithLabelUseFont(
    std::string const &text, 
    float size, 
    const char *font, 
    unsigned width, 
    unsigned height, 
    int alignment)
{
    id_type view = ConvenienceCreateNSTextView(
                       width, height,
                       font, size,
                       alignment,
                       text.c_str());

    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    TexImageNSView(GL_TEXTURE_2D, view);

    ConvenienceReleaseNSTextView(view);

    return texture;
}

GLuint 
LoadTexture(
    std::string const &path, 
    GLenum target, 
    bool mipmap)
{
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(
                       kCFAllocatorDefault,
                       (UInt8 const *)path.c_str(),
                       path.length(),
                       false);
    CGImageSourceRef source = CGImageSourceCreateWithURL(url, NULL);
    CFRelease(url);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    void *data = calloc(width * height, 4);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(
                                     kCGColorSpaceGenericRGB);
    CGContextRef context = CGBitmapContextCreate(
                               data,
                               width,
                               height,
                               8,
                               4 * width,
                               colorSpace,
                               kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CFRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CFRelease(image);

    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(target, texture);
    if (mipmap)
    {
        glTexParameteri(target, GL_GENERATE_MIPMAP, GL_TRUE);
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    }
    else
    {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }
    glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(
        target,
        0,
        GL_RGBA8,
        width,
        height,
        0,
        GL_BGRA,
        GL_UNSIGNED_INT_8_8_8_8_REV,
        data);

    CFRelease(context);
    free(data);

    return texture;
}

static GLuint 
CreateShader(
    GLenum target, 
    char const *fileName)
{
    GLuint shader = glCreateShader(target);

    char *source;
    size_t source_length;
    LoadFileIntoString(fileName, &source, &source_length);

    glShaderSource(shader, 1, (const GLchar **)&source, NULL);
    glCompileShader(shader);

    // FIXME actually check for successful compile
    char log[1024] = {0};
    GLint length = 0;
    glGetShaderInfoLog(shader, 1024, &length, log);
    if(length)
        printf("Shader Log:\n%s\n", log);

    return shader;
}

GLuint LoadShader(
    char const *vsFileName,
    char const *gsFileName,
    char const *fsFileName,
    GLenum      inType,
    GLenum      outType,
    GLsizei     verticesOut)
{
    GLuint vertexShader = 0, geometryShader = 0, fragmentShader = 0;

    if (vsFileName)
    {
        vertexShader = CreateShader(GL_VERTEX_SHADER, vsFileName);
    }

    if (gsFileName)
    {
        geometryShader = CreateShader(GL_GEOMETRY_SHADER_EXT, gsFileName);
    }

    if (fsFileName)
    {
        fragmentShader = CreateShader(GL_FRAGMENT_SHADER, fsFileName);
    }

    GLuint program = glCreateProgram();
    if (vertexShader)   glAttachShader(program, vertexShader);
    if (geometryShader) glAttachShader(program, geometryShader);
    if (fragmentShader) glAttachShader(program, fragmentShader);

    if (geometryShader)
    {
        glProgramParameteriEXT(program, GL_GEOMETRY_INPUT_TYPE_EXT, inType);
        glProgramParameteriEXT(program, GL_GEOMETRY_OUTPUT_TYPE_EXT, outType);
        glProgramParameteriEXT(program, GL_GEOMETRY_VERTICES_OUT_EXT, verticesOut);
    }

    glLinkProgram(program);

    glDeleteShader(vertexShader);
    glDeleteShader(geometryShader);
    glDeleteShader(fragmentShader);

    // FIXME actually check for successful link
    char shaderLog[1000];
    GLint len;
    glGetProgramInfoLog(program, 1000, &len, shaderLog);
    printf("%s\n", shaderLog);

    return program;
}

inline float HermiteBasis(float pA, float pB, float vA, float vB, float u)
{
    float u2 = (u * u), u3 = u2 * u;
    float B0 = 2 * u3 - 3 * u2 + 1;
    float B1 = -2 * u3 + 3 * u2;
    float B2 = u3 - 2 * u2 + u;
    float B3 = u3 - u;
    return( B0*pA + B1*pB + B2*vA + B3*vB );
}

unsigned char* CreateGaussianMap(int N)
{
    float *M = new float[2*N*N];
    unsigned char *B = new unsigned char[N*N];
    float X, Y, Y2, Dist;
    float Incr = 2.0f / N;
    int i = 0;
    int j = 0;
    Y = -1.0f;

    for (int y = 0; y < N; y++, Y += Incr)
    {
        Y2 = Y * Y;
        X = -1.0f;
        for (int x = 0; x < N; x++, X += Incr, i += 2, j++)
        {
            Dist = (float)sqrtf(X * X + Y2);
            if (Dist > 1) Dist = 1;
            M[i+1] = M[i] = HermiteBasis(1.0f, 0, 0, 0, Dist);
            B[j] = (unsigned char)(M[i] * 255);
        }
    }
    delete [] M;
    return(B);
}

GLuint CreateButtonLabel(
    std::string const &text, 
    unsigned int font_size)
{
    return CreateTextureWithLabel(text, font_size, false, BUTTON_WIDTH, BUTTON_HEIGHT);
}


void DrawButton(Button const *button, GLuint texture, GLuint background, bool selected)
{
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, background);
    glColor3f(1, 1, 1);
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glMatrixMode(GL_TEXTURE);
    glPushMatrix();
    {
        glLoadIdentity();
        glScalef(button->w(), button->h(), 1);
        glMatrixMode(GL_MODELVIEW);
    
        if (selected)
        {
            glColor3f(0.5f, 0.5f, 0.5f);
        }
        else
        {
            glColor3f(0.3f, 0.3f, 0.3f);
        }
    
        DrawQuad(button->x(), button->y(), button->w(), button->h());
    }
    glMatrixMode(GL_TEXTURE);
    glPopMatrix();

    glMatrixMode(GL_MODELVIEW);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    glBindTexture(GL_TEXTURE_2D, texture);

    if (selected)
    {
        glColor3f(0.4f, 0.7f, 1.0f);
    }
    else
    {
        glColor3f(0.85f, 0.2f, 0.2f);
    }

    glTranslatef(0, -10, 0);
    DrawButton(button);
    glTranslatef(0, 10, 0);
    glColor3f(1, 1, 1);
    glBindTexture(GL_TEXTURE_2D, 0);
}

void DrawMeter(
    float x,
    float y,
    SmoothMeter &meter)
{
    glPushMatrix();
    glTranslatef(x, y, 0.0);
    glColor3f(1, 1, 1);
    meter.draw();
    glPopMatrix();
}
void DrawQuad(
    float x, float y, 
    float w, float h)
{
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(x, y);
    glTexCoord2f(1.0, 0.0);
    glVertex2f(x + w, y);
    glTexCoord2f(1.0, 1.0);
    glVertex2f(x + w, y + h);
    glTexCoord2f(0.0, 1.0);
    glVertex2f(x, y + h);
    glEnd();
}

void DrawQuadInverted(
    float x, float y, 
    float w, float h)
{
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 1.0);
    glVertex2f(x, y);
    glTexCoord2f(1.0, 1.0);
    glVertex2f(x + w, y);
    glTexCoord2f(1.0, 0.0);
    glVertex2f(x + w, y + h);
    glTexCoord2f(0.0, 0.0);
    glVertex2f(x, y + h);
    glEnd();
}


