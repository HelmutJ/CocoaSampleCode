
/*
     File: SampleCIView.m
 Abstract: Simple OpenGL based CoreImage view.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "SampleCIView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@interface SampleCIView ()

@property (nonatomic, strong) CIContext *context;
@property (nonatomic, strong) NSDictionary *contextOptions;

- (BOOL)displaysWhenScreenProfileChanges;
- (void)viewWillMoveToWindow:(NSWindow*)newWindow;
- (void)displayProfileChanged:(NSNotification*)notification;

@end


@implementation SampleCIView
{
    NSRect				_lastBounds;
	CGLContextObj		_cglContext;
	NSOpenGLPixelFormat *pixelFormat;
	CGDirectDisplayID	_directDisplayID;
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    static NSOpenGLPixelFormat *pf;
	
    if (pf == nil)
    {
		/* 
         Making sure the context's pixel format doesn't have a recovery renderer is important - otherwise CoreImage may not be able to create deeper context's that share textures with this one.
         */
		static const NSOpenGLPixelFormatAttribute attr[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFAAllowOfflineRenderers,  /* Allow use of offline renderers */
			0
		};
		
		pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];
    }
	
    return pf;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setContextOptions:(NSDictionary *)dict
{
    _contextOptions = dict;
    self.context = nil;
}


- (void)setImage:(CIImage *)image
{
    [self setImage:image dirtyRect:CGRectInfinite];
}


- (void)setImage:(CIImage *)image dirtyRect:(CGRect)rect
{
    if (_image != image)
    {
		_image = image;
		
		if (CGRectIsInfinite(rect)) {
			[self setNeedsDisplay:YES];
        }
		else {
			[self setNeedsDisplayInRect:NSRectFromCGRect(rect)];
        }
    }
}


- (void)prepareOpenGL
{
    GLint parm = 1;
	
    /* Enable beam-synced updates. */
	
    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];
	
    /* Make sure that everything we don't need is disabled. Some of these
     * are enabled by default and can slow down rendering. */
	
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_DITHER);
    glDisable(GL_CULL_FACE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_FALSE);
    glStencilMask(0);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
}


- (void)viewBoundsDidChange:(NSRect)bounds
{
    /* For subclasses. */
}


- (void)updateMatrices
{
    NSRect bounds = [self bounds];
	
    if (!NSEqualRects(bounds, _lastBounds)) {
        
		[[self openGLContext] update];
		
		/* Install an orthographic projection matrix (no perspective)
		 * with the origin in the bottom left and one unit equal to one
		 * device pixel. */
		
		glViewport(0, 0, bounds.size.width, bounds.size.height);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0, bounds.size.width, 0, bounds.size.height, -1, 1);
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		
		_lastBounds = bounds;
		
		[self viewBoundsDidChange:bounds];
    }
}


- (BOOL)displaysWhenScreenProfileChanges
{
    return YES;
}


- (void)viewWillMoveToWindow:(NSWindow*)newWindow
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidChangeScreenProfileNotification object:nil];
    [center addObserver:self selector:@selector(displayProfileChanged:) name:NSWindowDidChangeScreenProfileNotification object:newWindow];
    [center addObserver:self selector:@selector(displayProfileChanged:) name:NSWindowDidMoveNotification object:newWindow];
    
    // When using OpenGL, we should disable the window's "one-shot" feature
    [newWindow setOneShot:NO];
}


- (void)displayProfileChanged:(NSNotification*)notification
{
	CGDirectDisplayID oldDid = _directDisplayID;
	_directDisplayID = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] pointerValue];
    
	if (_directDisplayID == oldDid) {
		return;
	}
    
	_cglContext = [[self openGLContext] CGLContextObj];
	
    if (pixelFormat == nil)
	{
		pixelFormat = [self pixelFormat];
		if (pixelFormat == nil) {
			pixelFormat = [[self class] defaultPixelFormat];
        }
	}
    
    CGLLockContext(_cglContext);
    {
        // Create a new CIContext using the new output color space		
        // Since the cgl context will be rendered to the display, it is valid to rely on CI to get the colorspace from the context.
		self.context = [CIContext contextWithCGLContext:_cglContext pixelFormat:[pixelFormat CGLPixelFormatObj] colorSpace:nil options:_contextOptions];
	}
    CGLUnlockContext(_cglContext);
}


- (void)drawRect:(NSRect)rect
{
    [[self openGLContext] makeCurrentContext];
	
    /* Allocate a CoreImage rendering context using the view's OpenGL
     * context as its destination if none already exists. */
	
    if (self.context == nil) {
		[self displayProfileChanged:nil];
	}
    
    CGRect integralRect = CGRectIntegral(NSRectToCGRect(rect));
	
    if ([NSGraphicsContext currentContextDrawingToScreen])
    {
		[self updateMatrices];
		
		/*
         Clear the specified subrect of the OpenGL surface then render the image into the view. Use the GL scissor test to clip to the subrect. Ask CoreImage to generate an extra pixel in case it has to interpolate (allow for hardware inaccuracies).
         */
        CGRect rr = CGRectIntersection(CGRectInset (integralRect, -1.0f, -1.0f), NSRectToCGRect(_lastBounds));
		
		glScissor(integralRect.origin.x, integralRect.origin.y, integralRect.size.width, integralRect.size.height);
		glEnable(GL_SCISSOR_TEST);
		
		glClear(GL_COLOR_BUFFER_BIT);
        
		if ([self respondsToSelector:@selector(drawRect:inCIContext:)]) {
            // For Subclasses to provide their own drawing method.
			[(id <SampleCIViewDraw>)self drawRect:NSRectFromCGRect(rr) inCIContext:self.context];
		}
		else {
            
            if (self.image != nil) {
                [self.context drawImage:self.image inRect:rr fromRect:rr];
            }
		}
		
		glDisable(GL_SCISSOR_TEST);
		
		/*
         Flush the OpenGL command stream. If the view is double buffered this should be replaced by [[self openGLContext] flushBuffer].
         */
		glFlush();
    }
    else
    {
		/* Printing the view contents. Render using CG, not OpenGL. */
		
		if ([self respondsToSelector:@selector (drawRect:inCIContext:)]) {
			[(id <SampleCIViewDraw>)self drawRect:NSRectFromCGRect(integralRect) inCIContext:self.context];
		}
		else {
            
            if (self.image != nil) {
                
                CGImageRef cgImage = [self.context createCGImage:self.image fromRect:integralRect format:kCIFormatRGBA16 colorSpace:nil];
                
                if (cgImage != NULL) {
                    CGContextDrawImage([[NSGraphicsContext currentContext] graphicsPort], integralRect, cgImage);
                    CGImageRelease(cgImage);
                }
            }
        }
    }
}

@end
