/*

File: MyOpenGLView.m

Abstract: NSOpenGLView Subclass that Renders a Rotating Globe

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc.,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright © 2007 Apple Inc., All Rights Reserved

*/

#import "MyOpenGLView.h"
#import "Scene.h"

@implementation MyOpenGLView

- initWithFrame:(NSRect)frameRect {
    NSOpenGLPixelFormatAttribute attrs[] = {

        // Specifying "NoRecovery" gives us a context that cannot fall back to the software renderer.  This makes the View-based context a compatible with the layer-backed context, enabling us to use the "shareContext" feature to share textures, display lists, and other OpenGL objects between the two.
        NSOpenGLPFANoRecovery, // Enable automatic use of OpenGL "share" contexts.

        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 16,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        0
    };
    GLint rendererID;

    // Create our pixel format.
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    // Just as a diagnostic, report the renderer ID that this pixel format binds to.  CGLRenderers.h contains a list of known renderers and their corresponding RendererID codes.
    [pixelFormat getValues:&rendererID forAttribute:NSOpenGLPFARendererID forVirtualScreen:0];
    NSLog(@"NSOpenGLView pixelFormat RendererID = %08x", (unsigned)rendererID);

    self = [super initWithFrame:frameRect pixelFormat:pixelFormat];
    if (self) {
        scene = [[Scene alloc] init];
    }
    [pixelFormat release];
    return self;
}

- (void)dealloc {
    [scene release];
    [super dealloc];
}

- (Scene *)scene {
    return scene;
}

- (float)cameraDistance {
    return [scene cameraDistance];
}

- (void)setCameraDistance:(float)newCameraDistance {
    [scene setCameraDistance:newCameraDistance];
    [self setNeedsDisplay:YES];
}

- (float)rollAngle {
    return [scene rollAngle];
}

- (void)setRollAngle:(float)newRollAngle {
    [scene setRollAngle:newRollAngle];
    [self setNeedsDisplay:YES];
}

- (float)sunAngle {
    return [scene sunAngle];
}

- (void)setSunAngle:(float)newSunAngle {
    [scene setSunAngle:newSunAngle];
    [self setNeedsDisplay:YES];
}

- (BOOL)wireframe {
    return [scene wireframe];
}

- (void)setWireframe:(BOOL)flag {
    [scene setWireframe:flag];
    [self setNeedsDisplay:YES];
}

// Performs OpenGL setup that we only need to do once for each new OpenGL context that's assigned to the view.  AppKit automatically invokes the -prepareOpenGL API method once with the new NSOpenGLContext current, each time the view gets a new NSOpenGLContext (as can happen when the view is switched into or out of layer-backed mode).
- (void)prepareOpenGL {
    [scene prepareOpenGL];
}

- (void)drawRect:(NSRect)aRect {
    // Clear the framebuffer.
    glClearColor( 0.0, 0.0, 0.0, 1.0 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    // Delegate to our scene object for the remainder of the frame rendering.
    [scene render];
    [[self openGLContext] flushBuffer];
}

- (void)reshape {
    // Delegate to our scene object to update for a change in the view size.
    NSRect pixelBounds = [self convertRectToBase:[self bounds]];
    [scene setViewportRect:NSMakeRect(0, 0, pixelBounds.size.width, pixelBounds.size.height)];
}

- (BOOL)acceptsFirstResponder {
    // We want this view to be able to receive key events.
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    // Delegate to our controller object for handling key events.
    [controller keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent {
    // Delegate to our controller object for handling mouse events.
    [controller mouseDown:theEvent];
}

@end
