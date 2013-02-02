/*
     File: TransitionSelectorView.m
 Abstract: TransitionSelectorView.h
  Version: 1.2
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "TransitionSelectorView.h"

@implementation TransitionSelectorView

@synthesize sourceImage;
@synthesize targetImage;

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
	    0
	};

	pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];
    }

    return pf;
}

- (void)dealloc
{
    [transitions release];
    [_context release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    NSTimer    *timer;
    NSURL      *url;
    NSRect	bounds = [self bounds];

    thumbnailWidth  = bounds.size.width;
    thumbnailHeight = bounds.size.height;
    thumbnailGap    = 20.0;

    // setup the source and destination image for the transition
    url   = [NSURL fileURLWithPath: [[NSBundle mainBundle]
        pathForResource: @"Rose" ofType: @"jpg"]];
    self.sourceImage = [CIImage imageWithContentsOfURL: url];

    url   = [NSURL fileURLWithPath: [[NSBundle mainBundle]
        pathForResource: @"Frog" ofType: @"jpg"]];
    self.targetImage = [CIImage imageWithContentsOfURL: url];
    
    // setup our transitions
    if(transitions == nil)
        [self setupTransitions];
	
    // set the size of the content view according to the number of transitions we will render
    bounds.size.width = (float)[transitions count] * thumbnailWidth + ((float)[transitions count] - 1.0) * thumbnailGap;    
    [self setFrame:bounds];
    [self setBounds:bounds];
	
    // setup the repeating timer to trigger the rendering - we will render at 30fps
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0/30.0  target: self
        selector: @selector(timerFired:)  userInfo: nil  repeats: YES];

    base = [NSDate timeIntervalSinceReferenceDate];
    [[NSRunLoop currentRunLoop] addTimer: timer  forMode: NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer: timer  forMode: NSEventTrackingRunLoopMode];
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

// return our static shading image
- (CIImage *)shadingImage
{
    if(!shadingImage)
    {
        NSURL  *url;

        url   = [NSURL fileURLWithPath: [[NSBundle mainBundle]
            pathForResource: @"Shading" ofType: @"tiff"]];
        shadingImage = [[CIImage alloc] initWithContentsOfURL: url];
    }

    return shadingImage;
}

// return our static empty image
- (CIImage *)blankImage
{
    if(!blankImage)
    {
        NSURL  *url;

        url   = [NSURL fileURLWithPath: [[NSBundle mainBundle]
            pathForResource: @"Blank" ofType: @"jpg"]];
        blankImage = [[CIImage alloc] initWithContentsOfURL: url];
    }

    return blankImage;
}

// return our static mask image
- (CIImage *)maskImage
{
    if(!maskImage)
    {
        NSURL  *url;

        url   = [NSURL fileURLWithPath: [[NSBundle mainBundle]
            pathForResource: @"Mask" ofType: @"jpg"]];
        maskImage = [[CIImage alloc] initWithContentsOfURL: url];
    }

    return maskImage;
}

// trigger the rendering
- (void)timerFired: (id)sender
{
    [self setNeedsDisplay: YES];
}


- (CIImage *)imageForTransition: (int)transitionNumber  atTime: (float)t
{
    CIFilter  *transition, *crop;

    transition    = [transitions objectAtIndex:transitionNumber];

    if(fmodf(t, 2.0) < 1.0f)	    // transition to and back
    {
        [transition setValue: sourceImage  forKey: @"inputImage"];
        [transition setValue: targetImage  forKey: @"inputTargetImage"];
    }

    else
    {
        [transition setValue: targetImage  forKey: @"inputImage"];
        [transition setValue: sourceImage  forKey: @"inputTargetImage"];
    }

    // set the time for the transition
    [transition setValue: [NSNumber numberWithFloat: 0.5*(1-cos(fmodf(t, 1.0f) * M_PI))]
        forKey: @"inputTime"];

    // crop the output image to be within the rect of the thumbnail. This is needed as some transitions have effects that can go beyond the borders of the source image
    crop = [CIFilter filterWithName: @"CICrop"
        keysAndValues: @"inputImage", [transition valueForKey: @"outputImage"],
            @"inputRectangle", [CIVector vectorWithX: 0  Y: 0
            Z: thumbnailWidth  W: thumbnailHeight], nil];

    return [crop valueForKey: @"outputImage"];
}

- (void)drawRect: (NSRect)rectangle
{
    [[self openGLContext] makeCurrentContext];

    CGPoint origin = CGPointZero;
    CGRect  thumbFrame, displayRect;
    float   t;
    int     i;

    if(_needsReshape)
    {
	// reset the views coordinate system when the view has been resized or scrolled
	NSRect  visibleRect = [self visibleRect];
	NSRect  mappedVisibleRect = NSIntegralRect([self convertRect: visibleRect toView: [self enclosingScrollView]]);
	
	glViewport (0, 0, mappedVisibleRect.size.width, mappedVisibleRect.size.height);

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
    if (_context == nil)
    {
	NSOpenGLPixelFormat *pf;

	pf = [self pixelFormat];
	if (pf == nil)
	    pf = [[self class] defaultPixelFormat];

        _context = [[CIContext contextWithCGLContext:CGLGetCurrentContext() pixelFormat:[pf CGLPixelFormatObj] colorSpace:NULL options: nil] retain];
    }
    
    // fill the view black
    glColor4f (0.0f, 0.0f, 0.0f, 0.0f);
    glBegin(GL_POLYGON);
        glVertex2f (rectangle.origin.x, rectangle.origin.y);
        glVertex2f (rectangle.origin.x + rectangle.size.width, rectangle.origin.y);
        glVertex2f (rectangle.origin.x + rectangle.size.width, rectangle.origin.y + rectangle.size.height);
        glVertex2f (rectangle.origin.x, rectangle.origin.y + rectangle.size.height);
    glEnd();
    
    thumbFrame = CGRectMake(0,0, thumbnailWidth,thumbnailHeight);
    t          = 0.4*([NSDate timeIntervalSinceReferenceDate] - base);

    // draw the transitions
    for(i = ([transitions count] -1) ; i >= 0 ; i--)
    {
	displayRect.origin = origin;
	displayRect.size = thumbFrame.size;
	displayRect = CGRectIntersection (displayRect, *(CGRect*)&rectangle);
        if((displayRect.size.width > 0) && (displayRect.size.height > 0))	// only draw the transitions that are in the visible area to increase performance
            [_context drawImage: [self imageForTransition: i atTime: t]  atPoint: origin  fromRect: thumbFrame];
        origin.x += thumbnailWidth + thumbnailGap;
    }
    
    glFlush();
}

@end
