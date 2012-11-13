
/*
     File: SampleCIScrollableView.m
 Abstract: The SampleCIScrollableView builds on the SimpleCIView from other Core Image sample codes. It is modified to support scrolling by setting up the OpenGL coordinate system accordingly.
  Version: 1.3
 
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

#import "SampleCIScrollableView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@interface SampleCIScrollableView (internalCalls)

- (BOOL)displaysWhenScreenProfileChanges;
- (void)viewWillMoveToWindow:(NSWindow*)newWindow;
- (void)displayProfileChanged:(NSNotification*)notification;

@end


@implementation SampleCIScrollableView

+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    static NSOpenGLPixelFormat *pf;
	
    if (pf == nil)
    {
		/* Making sure the context's pixel format doesn't have a recovery
		 * renderer is important - otherwise CoreImage may not be able to
		 * create deeper context's that share textures with this one. */
		
		static const NSOpenGLPixelFormatAttribute attr[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFAColorSize, 32,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
			NSOpenGLPFAAllowOfflineRenderers,  /* allow use of offline renderers               */
#endif
			0
		};
		
		pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];
    }
	
    return pf;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_image release];
    [_contextOptions release];
    [_context release];

    [super dealloc];
}

- (void)setContextOptions:(NSDictionary *)dict
{
    [_contextOptions release];
    _contextOptions = [dict retain];
	
    [_context release];
    _context = nil;
}

- (CIImage *)image
{
    return [[_image retain] autorelease];
}

- (void)setImage:(CIImage *)image dirtyRect:(CGRect)r
{
    if (_image != image)
    {
        [_image release];
        _image = [image retain];

        if (CGRectIsInfinite (r))
            [self setNeedsDisplay:YES];
        else
            [self setNeedsDisplayInRect:*(NSRect *)&r];
    }
}

- (void)setImage:(CIImage *)image
{
    [self setImage:image dirtyRect:CGRectInfinite];
}

- (void)prepareOpenGL
{
    GLint parm = 1;

    /* Enable beam-synced updates. */

    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];

    /* Make sure that everything we don't need is disabled. Some of these
     * are enabled by default and can slow down rendering. */

    glDisable (GL_ALPHA_TEST);
    glDisable (GL_DEPTH_TEST);
    glDisable (GL_SCISSOR_TEST);
    glDisable (GL_BLEND);
    glDisable (GL_DITHER);
    glDisable (GL_CULL_FACE);
    glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask (GL_FALSE);
    glStencilMask (0);
    glClearColor (0.0f, 0.0f, 0.0f, 0.0f);
    glHint (GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
    _needsReshape = YES;
}


- (void)reshape		// scrolled, moved or resized
{
    _needsReshape = YES;	// reset the viewport etc. on the next draw
}

- (void)updateMatrices
{
    NSRect	visibleRect = [self visibleRect];
    NSRect	mappedVisibleRect = NSIntegralRect([self convertRect: visibleRect toView: [self enclosingScrollView]]);
    
    [[self openGLContext] update];

    /* Install an orthographic projection matrix (no perspective)
     * with the origin in the bottom left and one unit equal to one
     * device pixel. */

    glViewport (0, 0,mappedVisibleRect.size.width, mappedVisibleRect.size.height);

    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    glOrtho(visibleRect.origin.x,
		visibleRect.origin.x + visibleRect.size.width,
		visibleRect.origin.y,
		visibleRect.origin.y + visibleRect.size.height,
		-1, 1);

    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
    _needsReshape = NO;
}

- (BOOL)displaysWhenScreenProfileChanges
{
    return YES;
}

- (void)viewWillMoveToWindow:(NSWindow*)newWindow
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidChangeScreenProfileNotification object:nil];
    [center addObserver:self selector:@selector(displayProfileChanged:) name:NSWindowDidChangeScreenProfileNotification object:newWindow];
    [center addObserver:self selector:@selector(displayProfileChanged:) name:NSWindowDidMoveNotification object:newWindow];
    
    // When using OpenGL, we should disable the window's "one-shot" feature
    [newWindow setOneShot:NO];
}

- (void)displayProfileChanged:(NSNotification*)notification
{
	CGDirectDisplayID oldDid = _did;
	_did = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] pointerValue];
	if(_did == oldDid)
		return;
	
	_cglContext = [[self openGLContext] CGLContextObj];
	
    if(_pf == nil)
	{
		_pf = [self pixelFormat];
		if (_pf == nil)
			_pf = [[self class] defaultPixelFormat];
		
	}
    CGLLockContext(_cglContext);
    {
		
        // Create a new CIContext using the new output color space		
        [_context release];
		
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
		// For 10.6 onwards we use the new API but do not pass in a colorspace as. 
		// Since the cgl context will be rendered to the display, it is valid to rely on CI to get the colorspace from the context.
		_context = [[CIContext contextWithCGLContext:_cglContext pixelFormat:[_pf CGLPixelFormatObj] colorSpace:nil options:_contextOptions] retain];    
#else		
		CMProfileRef displayProfile = NULL;
		CGColorSpaceRef displayColorSpace = NULL;
		// Ask ColorSync for our current display's profile
		CMGetProfileByAVID((CMDisplayIDType)_did, &displayProfile);
		displayColorSpace = CGColorSpaceCreateWithPlatformColorSpace(displayProfile);
		CMCloseProfile(displayProfile);
		
		if(_contextOptions)
		{
			[(NSMutableDictionary*)_contextOptions setObject:(id)displayColorSpace forKey:kCIContextOutputColorSpace];
		} else {
			//_contextOptions = [[NSDictionary dictionaryWithObject:(id)displayColorSpace forKey:kCIContextOutputColorSpace] retain];
		}
		_context = [[CIContext contextWithCGLContext:_cglContext pixelFormat:[_pf CGLPixelFormatObj] options:_contextOptions] retain];
		CGColorSpaceRelease(displayColorSpace);
#endif
	}
    CGLUnlockContext(_cglContext);
    
}

- (void)drawRect:(NSRect)r
{
    CGRect ir;
    CGImageRef cgImage;

    [[self openGLContext] makeCurrentContext];

    if ([NSGraphicsContext currentContextDrawingToScreen])
    {
        if (_needsReshape)
        {
            [self updateMatrices];
            r = [self visibleRect];
            glClear (GL_COLOR_BUFFER_BIT);
        }
        ir = CGRectIntegral (*(CGRect *)&r);


        if ([self respondsToSelector:@selector (drawRect:inCIContext:)])
        {
            [self drawRect:*(NSRect *)&ir inCIContext:[self ciContext]];
        }
        else if (_image != nil)
        {
            [_context drawImage:_image atPoint:ir.origin fromRect:ir];
        }

        /* Flush the OpenGL command stream. If the view is double
         * buffered this should be replaced by [[self openGLContext]
         * flushBuffer]. */

        glFlush ();
    }
    else
    {
        /* Printing the view contents. Render using CG, not OpenGL. */
        ir = CGRectIntegral (*(CGRect *)&r);

        if ([self respondsToSelector:@selector (drawRect:inCIContext:)])
        {
            [self drawRect:*(NSRect *)&ir inCIContext:[self ciContext]];
        }
        else if (_image != nil)
        {
            cgImage = [[self ciContext] createCGImage:_image fromRect:ir format:kCIFormatRGBA16 colorSpace:nil];

            if (cgImage != NULL)
            {
                CGContextDrawImage ([[NSGraphicsContext currentContext]
				     graphicsPort], ir, cgImage);
                CGImageRelease (cgImage);
            }
        }
    }
}

- (CIContext*)ciContext
{
    /* Allocate a CoreImage rendering context using the view's OpenGL
     * context as its destination if none already exists. 
     * Make sure this is done before somebody queries the ciContext. */

    if (_context == nil)
		[self displayProfileChanged:nil];
    return _context;
}

@end
