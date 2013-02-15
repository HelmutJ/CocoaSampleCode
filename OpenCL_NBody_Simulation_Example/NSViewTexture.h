//
// File:       NSViewTexture.h
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

#ifndef __NSVIEWTEXTURE_H__
#define __NSVIEWTEXTURE_H__

#if defined(__cplusplus)
extern "C"
{
#endif

#if defined(__gl_h_)
    typedef GLenum GLenum_type;
    typedef GLint  GLint_type;
#else
    typedef unsigned int GLenum_type;
    typedef int GLint_type;
#endif

#if defined(__OBJC__) && defined(APPKIT_EXTERN)
    typedef id id_type;
#else
    typedef void *id_type;
#endif

    /* calls glTexImage2D(
                 target,
                 0,
                 GL_RGBA,
                 [view bounds].size.width,
                 [view bounds].size.height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 --contents of view--);
    */
    extern void TexImageNSView(
            GLenum_type target,
            id_type     view);

    /* calls glTexSubImage2D(
                 target,
                 0,
                 xoffset,
                 yoffset,
                 [view bounds].size.width,
                 [view bounds].size.height,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 --contents of view--);
    */
    extern void TexSubImageNSView(
            GLenum_type target,
            id_type     view,
            GLint_type  xoffset,
            GLint_type  yoffset);

    /* alignment should be -1, 0 or 1 for left/center/right respectively,
       or anything else for natural alignment */
       
    /* initial_text and font_name should be UTF-8 encoded, and may be NULL */
    extern id_type ConvenienceCreateNSTextView(
            unsigned    width,
            unsigned    height,
            const char *font_name,
            float       font_size,
            int         alignment,
            const char *initial_text);

    /* calls [view release] */
    extern void ConvenienceReleaseNSTextView(
            id_type view);

    /* calls [view setString:[NSString stringWithUTF8String:text]] */
    extern void ConvenienceSetNSTextViewText(
            id_type     view,
            const char *text);

    extern int GetMainDisplayWidth(void);

#if defined(__cplusplus)
}
#endif

#endif
