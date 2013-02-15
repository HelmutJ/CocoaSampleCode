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

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

#import "NSViewTexture.h"

void TexSubImageNSView(
    GLenum target,
    id     view,
    GLint  xoffset,
    GLint  yoffset)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSSize size = [view bounds].size;
    
    unsigned width = size.width;
    unsigned height = size.height;
    
    unsigned char *buffer;

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes:NULL
                                      pixelsWide:width
                                      pixelsHigh:height
                                   bitsPerSample:8
                                 samplesPerPixel:4
                                        hasAlpha:YES
                                        isPlanar:NO
                                  colorSpaceName:NSDeviceRGBColorSpace
                                     bytesPerRow:width * 4
                                    bitsPerPixel:32];
        
    [view cacheDisplayInRect:[view bounds] toBitmapImageRep:bitmap];
    
    buffer = [bitmap bitmapData];
  
    glTexSubImage2D(
        target,
        0,
        xoffset,
        yoffset,
        width,
        height,
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        buffer);
        
    [bitmap release];
    [pool release];
}

void TexImageNSView(
    GLenum target,
    id     view)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSSize size = [view bounds].size;

    glTexImage2D(
        target,
        0,
        GL_LUMINANCE_ALPHA,
        size.width,
        size.height,
        0,
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        NULL);

    TexSubImageNSView(target, view, 0, 0);
    
    [pool release];
}

id ConvenienceCreateNSTextView(
    unsigned    width,
    unsigned    height,
    const char *font_name,
    float       font_size,
    int         alignment,
    const char *initial_text)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// hardcoded white font with black drop shadow
    NSRect rect = NSMakeRect(0.0f, 0.0f, (float)width, (float)height);
    NSTextView *view = [[NSTextView alloc] initWithFrame:rect];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset: NSMakeSize(0, -3)];
	[shadow setShadowBlurRadius: 3];    
	[shadow setShadowColor:[NSColor blackColor]];    
    [view setBackgroundColor:[NSColor clearColor]];
    [view setTypingAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
        	[NSColor whiteColor], NSForegroundColorAttributeName,
            shadow, NSShadowAttributeName,
            nil]];
    [view setFont:
        [NSFont fontWithName:[NSString stringWithUTF8String:font_name]
                        size:font_size]];
    switch (alignment)
    {
    case -1:
        [view setAlignment:NSLeftTextAlignment];
        break;
    case 0:
        [view setAlignment:NSCenterTextAlignment];
        break;
    case 1:
        [view setAlignment:NSRightTextAlignment];
        break;
    default:
        [view setAlignment:NSNaturalTextAlignment];
        break;
    }
                        
    if (initial_text != NULL)
    {
        [view setString:[NSString stringWithUTF8String:initial_text]];
    }
    
    [pool release];
    
    return view;
}

int GetMainDisplayWidth(void)
{
    int width;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    width = (int)[[NSScreen mainScreen] frame].size.width;
    [pool release];
    return width;
}

void ConvenienceReleaseNSTextView(
    id view)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [view release];
    [pool release];
}

void ConvenienceSetNSTextViewText(
    id          view,
    const char *text)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [view setString:[NSString stringWithUTF8String:text]];
    [pool release];
}
