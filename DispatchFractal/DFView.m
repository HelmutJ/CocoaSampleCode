//
// File:       DFView.m
//
// Abstract:   This example shows how to combine parallel computation on the CPU
//             via GCD with results processing and display on the GPU via OpenCL
//             and OpenGL. It computes escape-time fractals in parallel on the
//             global concurrent GCD queue and uses another GCD queue to upload
//             results to the GPU for processing via two OpenCL kernels. Calls to
//             OpenCL and OpenGL for display are serialized with a third GCD queue.
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
//  Copyright 2009 Apple Inc. All rights reserved.
//

#import "DFView.h"
#import "DFAppDelegate.h"

#import <string.h>
#import <mach/mach_time.h>
#import <libkern/OSAtomic.h>
#import <OpenGL/CGLMacro.h>

@interface DFView(Private)
- (void)prepareOpenCL:(CGLContextObj)context;
- (void)updateColors;
- (void)processQuadtree:(unsigned int)bufferIndex;
- (void)redraw;
- (void)startRefresh;
- (void)stopRefresh;
- (void)resetFps;
- (void)updateFps;
@end

#define DFErrCondAssert(c, d) \
	if (!c || err) { \
	    NSLog(@"Assertion failure: Failed to %@: %d.", d, err); \
	    [[NSAlert alertWithMessageText: \
	    @"Your graphics hardware is not yet supported by OpenCL.\n" \
	    "Please check back later!" defaultButton:nil \
	    alternateButton:nil otherButton:nil \
	    informativeTextWithFormat:@"Failed to %@: %d.", d, err] \
	    runModal]; exit(1); }
#define DFErrAssert(d) DFErrCondAssert(1, d)

#define GRADIENT_POINTS 1024 /* 16kB lookup table */

#define flushFrame(cgl_ctx) \
	CGLFlushDrawable(cgl_ctx); if (texture) {OSAtomicAdd64(1, &frames);}

static CVReturn renderCallback(CVDisplayLinkRef displayLink,
	const CVTimeStamp *now, const CVTimeStamp *outputTime,
	CVOptionFlags flagsIn, CVOptionFlags *flagsOut,
	void *displayLinkContext) {
    DFView *view = (DFView*)displayLinkContext;
    [view redraw];
    return kCVReturnSuccess;
}

@implementation DFView

@synthesize enabled, haveSelection, needsFlush, quadtreeDone, processing,
	cycling, refreshing, vSync, useDLink, useGLMPEngine,
	quadtreeBufferIndex, colorRoot, cycleSpeed, cycleBase,
	col0, col1, col2, col3, col4, observedKeys;

enum {IDX_enabledisplay = 0, IDX_cyclecolors, IDX_colorroot,
	IDX_cyclespeed, IDX_vsync, IDX_displaylink, IDX_openglmp,
	IDX_col0, IDX_col1, IDX_col2, IDX_col3, IDX_col4};

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect
	    pixelFormat:[[self class] defaultPixelFormat]];
    if (self) {
	self.observedKeys = [NSArray arrayWithObjects:
		@"enabledisplay", @"cyclecolors", @"colorroot",
		@"cyclespeed", @"vsync", @"displaylink", @"openglmp",
		@"col0", @"col1", @"col2", @"col3", @"col4", nil];
	openglqueue = dispatch_queue_create("com.dispatchfractal.opengl", NULL);
	dispatch_set_target_queue(openglqueue,
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
	openclqueue = dispatch_queue_create("com.dispatchfractal.opencl", NULL);
	dispatch_set_target_queue(openclqueue,
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

	mach_timebase_info_data_t tb;
	mach_timebase_info(&tb);
	tb_freq = ((long double) tb.denom * NSEC_PER_SEC) / tb.numer;
	bzero(quadtreeOutputBuffer, 2 * sizeof(cl_mem));
	self.enabled = YES;

	[[NSNotificationCenter defaultCenter] addObserver:self
	       selector:@selector(windowChangedScreen:)
	       name:NSWindowDidMoveNotification object:[self window]];
    }
    return self;
}

- (void)dealloc {
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj]; // CGLMacro.h
    if (quadtreeCommandQueue) {
	dispatch_sync(openclqueue,^{
	    clFinish(quadtreeCommandQueue);
	    clReleaseCommandQueue(quadtreeCommandQueue);
	    dispatch_suspend(openclqueue);
	});
	dispatch_release(openclqueue);
    }
    dispatch_sync(openglqueue, ^{
	CGLSetCurrentContext(cgl_ctx);
	if (renderCommandQueue) clFinish(renderCommandQueue);
	if (renderImage) clReleaseMemObject(renderImage);
	if (colorizeOutputBuffer) clReleaseMemObject(colorizeOutputBuffer);
	for (int i = 0; i < 2; i++) {
	    if (quadtreeOutputBuffer[i])
		clReleaseMemObject(quadtreeOutputBuffer[i]);
	}
	if (quadtreeInputBuffer) clReleaseMemObject(quadtreeInputBuffer);
	if (gradientBuffer) clReleaseMemObject(gradientBuffer);
	if (colorizeKernel) clReleaseKernel(colorizeKernel);
	if (quadtreeKernel) clReleaseKernel(quadtreeKernel);
	if (computeProgram) clReleaseProgram(computeProgram);
	if (renderCommandQueue) clReleaseCommandQueue(renderCommandQueue);
	if (computeContext) clReleaseContext(computeContext);
	if (texture) glDeleteTextures(1, &texture);
	if (indexBuffer) glDeleteBuffers(1, &indexBuffer);
	if (vertexBuffer) glDeleteBuffers(1, &vertexBuffer);
	if (selectionDisplayList) glDeleteLists(selectionDisplayList, 1);
	dispatch_suspend(openglqueue);
    });
    dispatch_release(openglqueue);
    if (displayLink) CVDisplayLinkRelease(displayLink);
    if (fpstimer) {
	dispatch_source_cancel(fpstimer);
	dispatch_release(fpstimer);
    }
    if (gradientComponents) free(gradientComponents);
    [col0 release]; [col1 release]; [col2 release]; [col3 release];
    [col4 release]; [computeDevice release]; [observedKeys release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    NSWindow *w = [self window];
    if (w) {
	[w setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];
	[w setAllowsConcurrentViewDrawing:YES];
	[w useOptimizedDrawing:YES];
	[w makeKeyAndOrderFront:self];
    }
}

- (void)windowChangedScreen:(NSNotification*)inNotification
{
    if (displayLink) {
	CGDirectDisplayID currentDisplayID =
		CVDisplayLinkGetCurrentCGDisplay(displayLink);
	NSWindow *window = [inNotification object];
	CGDirectDisplayID displayID = (CGDirectDisplayID)[[[[window screen]
		deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
	if  (displayID != currentDisplayID) {
	    CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID);
	}
    }
}

- (BOOL)isOpaque {
    return YES;
}

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
    cl_int err = 0;
    const NSOpenGLPixelFormatAttribute attributes[] = {
	NSOpenGLPFAAccelerated,
	NSOpenGLPFANoRecovery,
	NSOpenGLPFAWindow,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAAllowOfflineRenderers,
	NSOpenGLPFAAlphaSize, 0,
	NSOpenGLPFADepthSize, 0,
	NSOpenGLPFAStencilSize, 0,
	NSOpenGLPFAAccumSize, 0,
	0
    };
    NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc]
	    initWithAttributes:attributes] autorelease];
    DFErrCondAssert(pixelFormat, @"create OpenGL pixel format");
    return pixelFormat;
}

- (void)prepareOpenGL {
    NSSize size = [self bounds].size;
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj]; // CGLMacro.h
    glDisable(GL_DITHER);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
    glDepthMask(GL_FALSE);
    glStencilMask(0);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glShadeModel(GL_FLAT);
    glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
    glHint(GL_CLIP_VOLUME_CLIPPING_HINT_EXT, GL_FASTEST);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glClearColor(0.655f, 0.655f, 0.655f, 1.0f);
    glViewport(0, 0, size.width, size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    selectionDisplayList = glGenLists(1);

    GLfloat vertices[4][2] = {
	{-1.0f, -1.0f}, {-1.0f,  1.0f}, { 1.0f,  1.0f}, { 1.0f, -1.0f}};
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glVertexPointer(2, GL_FLOAT, 2 * sizeof(GLfloat), NULL);
    glTexCoordPointer(2, GL_FLOAT, 2 * sizeof(GLfloat),
	    (char*)NULL + 8 * sizeof(GLfloat));
    glBufferData(GL_ARRAY_BUFFER, 16 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);

    GLushort indices[4] = {0, 1, 2, 3};
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices,
	    GL_STATIC_DRAW);

    [self prepareOpenCL:cgl_ctx];

    NSOpenGLPixelFormat	*pixelFormat = [self pixelFormat];
    CGOpenGLDisplayMask	totalDisplayMask = 0;
    for (GLint virtualScreen = 0; virtualScreen <
	    [pixelFormat numberOfVirtualScreens]; virtualScreen++) {
	GLint displayMask;
	[pixelFormat getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask
		forVirtualScreen:virtualScreen];
	totalDisplayMask |= displayMask;
    }
    CVDisplayLinkCreateWithOpenGLDisplayMask(totalDisplayMask, &displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, renderCallback, self);
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cgl_ctx,
	    [pixelFormat CGLPixelFormatObj]);

    fpstimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
	    dispatch_get_main_queue());
    dispatch_source_set_timer(fpstimer, dispatch_time(
	    DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), .5 * NSEC_PER_SEC,
	    .1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(fpstimer, ^{
	[self updateFps];
    });
}

- (void)prepareOpenCL:(CGLContextObj)context {
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
    cl_int err = 0;
    cl_context_properties properties[] = {
        CL_CONTEXT_PROPERTY_USE_CGL_SHAREGROUP_APPLE,
	(cl_context_properties)CGLGetShareGroup(context),
	0
    };
    computeContext = clCreateContext(properties, 0, 0, 0, 0, &err);
    DFErrCondAssert(computeContext, @"create OpenCL compute context");

    cl_device_id computeDeviceID ;
    err = clGetGLContextInfoAPPLE(computeContext, cgl_ctx,
	    CL_CGL_DEVICE_FOR_CURRENT_VIRTUAL_SCREEN_APPLE,
	    sizeof(computeDeviceID), &computeDeviceID, NULL);
    DFErrCondAssert(computeDeviceID, @"locate OpenCL compute device");

    cl_char vendorName[1024] = {}, deviceName[1024] = {};
    err = clGetDeviceInfo(computeDeviceID, CL_DEVICE_VENDOR,
	    sizeof(vendorName), vendorName, NULL);
    err|= clGetDeviceInfo(computeDeviceID, CL_DEVICE_NAME,
	    sizeof(deviceName), deviceName, NULL);
    DFErrAssert(@"retrieve OpenCL device info");
    computeDevice = [[NSString alloc] initWithFormat:@"%s %s", vendorName,
	    deviceName];

    renderCommandQueue = clCreateCommandQueue(computeContext, computeDeviceID,
	    0, &err);
    DFErrCondAssert(renderCommandQueue, @"create OpenCL command queue");

    quadtreeCommandQueue = clCreateCommandQueue(computeContext, computeDeviceID,
	    0, &err);
    DFErrCondAssert(quadtreeCommandQueue, @"create OpenCL command queue");

    NSData *source = [NSData dataWithContentsOfURL:[[NSBundle mainBundle]
	    URLForResource:@"DispatchFractal" withExtension:@"cl"]];
    DFErrCondAssert(source, @"load OpenCL kernel source");

    const char *bytes = [source bytes];
    const size_t lengths[] = {[source length], 0};
    computeProgram = clCreateProgramWithSource(computeContext, 1, &bytes,
	    lengths, &err);
    DFErrCondAssert(computeProgram, @"create OpenCL program");

    NSString *opts = [NSString stringWithFormat:@"-DGRADIENT_POINTS=%d",
	    GRADIENT_POINTS];
    err = clBuildProgram(computeProgram, 0, NULL, [opts UTF8String], NULL,
	    NULL);
    if (err) {
        size_t len;
        char log[2048];
        clGetProgramBuildInfo(computeProgram, computeDeviceID,
		CL_PROGRAM_BUILD_LOG, sizeof(log), log, &len);
        NSLog(@"OpenCL program build failure: %d\n%s", err, log);
    }
    DFErrAssert(@"build OpenCL program");
    clUnloadCompiler();

    quadtreeKernel = clCreateKernel(computeProgram, "quadtree", &err);
    DFErrCondAssert(quadtreeKernel, @"create OpenCL quadtree kernel");

    err = clGetKernelWorkGroupInfo(quadtreeKernel, computeDeviceID,
	    CL_KERNEL_WORK_GROUP_SIZE, sizeof(maxQuadtreeKernelWorkGroupSize),
	    &maxQuadtreeKernelWorkGroupSize, NULL);
    DFErrAssert(@"retrieve OpenCL quadtree kernel work group info");

    colorizeKernel = clCreateKernel(computeProgram, "colorize", &err);
    DFErrCondAssert(colorizeKernel, @"create OpenCL colorize kernel");

    err = clGetKernelWorkGroupInfo(colorizeKernel, computeDeviceID,
	    CL_KERNEL_WORK_GROUP_SIZE, sizeof(maxColorizeKernelWorkGroupSize),
	    &maxColorizeKernelWorkGroupSize, NULL);
    DFErrAssert(@"retrieve OpenCL colorize kernel work group info");

    gradientLength = 4 * sizeof(float) * (GRADIENT_POINTS + 1);
    gradientComponents = malloc(gradientLength);
    gradientBuffer = clCreateBuffer(computeContext, CL_MEM_READ_ONLY,
	    gradientLength, NULL, &err);
    DFErrCondAssert(gradientBuffer, @"create OpenCL gradient buffer");
}

- (void)updateColors {
    NSColor *col = self.col4;
    NSGradient *gradient = [[NSGradient alloc] initWithColors:[NSArray
	    arrayWithObjects:self.col0, self.col1, self.col2, self.col3,
	    self.col0, nil]];
    float *g = gradientComponents;
    CGFloat c[4];
    unsigned int i = 0;
    do {
	[[col colorUsingColorSpaceName:NSDeviceRGBColorSpace] getComponents:c];
	*g++ = c[2]; *g++ = c[1]; *g++ = c[0]; *g++ = c[3];
	col = [gradient interpolatedColorAtLocation:
		(CGFloat)i/(GRADIENT_POINTS-1)];
    } while (i++ < GRADIENT_POINTS);
    [gradient release];
    dispatch_async(openglqueue, ^{
	cl_int err = clEnqueueWriteBuffer(renderCommandQueue, gradientBuffer,
		CL_FALSE, 0, gradientLength, gradientComponents, 0, NULL, NULL);
	DFErrAssert(@"write to OpenCL gradient buffer");
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:((DFAppDelegate*)[NSApp delegate]).dataController] &&
	    [keyPath hasPrefix:@"selection."]) {
	id d = [object selection];
	NSString *k = [keyPath substringFromIndex:10];
	switch ([self.observedKeys indexOfObject:k]) {
	case IDX_enabledisplay: {
	    const BOOL b = [[d valueForKey:k] boolValue];
	    if (b != self.refreshing && texture) {
		long double base = (mach_absolute_time() / tb_freq) *
			self.cycleSpeed;
		if (b) {
		    if (self.processing || self.cycling) {
			self.cycleBase -= base;
			[self startRefresh];
		    }
		} else {
		    self.cycleBase += base;
		    [self stopRefresh];
		}
	    }
	    break;
	}
	case IDX_cyclecolors: {
	    const BOOL b = [[d valueForKey:k] boolValue];
	    if (b != self.cycling) {
		self.cycling = b;
		if (texture) {
		    long double base = (mach_absolute_time() / tb_freq) *
			    self.cycleSpeed;
		    if (b) {
			self.cycleBase -= base;
			[self startRefresh];
		    } else {
			self.cycleBase += base;
			if (!self.processing) [self stopRefresh];
		    }
		}
	    }
	    break;
	}
	case IDX_colorroot: {
	    unsigned int r = [[d valueForKey:k] unsignedIntValue];
	    if (r != self.colorRoot) {
		self.colorRoot = r;
		if (!self.refreshing) {
		    [self setNeedsDisplay:YES];
		}
	    }
	    break;
	}
	case IDX_cyclespeed: {
	    double oldSpeed = self.cycleSpeed;
	    double newSpeed = [[d valueForKey:k] doubleValue];
	    if (newSpeed != oldSpeed) {
		self.cycleSpeed = newSpeed;
		self.cycleBase += (mach_absolute_time() / tb_freq) *
			(oldSpeed - newSpeed);
	    }
	    break;
	}
	case IDX_vsync: {
	    const BOOL b = [[d valueForKey:k] boolValue];
	    if (b != self.vSync) {
		self.vSync = b;
		CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
		dispatch_async(openglqueue,^{
		    const GLint swapInterval = b ? 1 : 0;
		    CGLSetCurrentContext(cgl_ctx);
		    CGLSetParameter(cgl_ctx, kCGLCPSwapInterval, &swapInterval);
		});
	    }
	    break;
	}
	case IDX_displaylink: {
	    const BOOL b = [[d valueForKey:k] boolValue];
	    if (b != self.useDLink) {
		if (self.refreshing) {
		    if (b) {
			CVDisplayLinkStart(displayLink);
		    } else {
			CVDisplayLinkStop(displayLink);
			[self redraw];
		    }
		    [self setNeedsDisplay:YES];
		}
		self.useDLink = b;
	    }
	    break;
	}
	case IDX_openglmp: {
	    const BOOL b = [[d valueForKey:k] boolValue];
	    if (b != self.useGLMPEngine) {
		self.useGLMPEngine = b;
		CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
		dispatch_async(openglqueue,^{
		    CGLSetCurrentContext(cgl_ctx);
		    if (b) {
			CGLEnable(cgl_ctx, kCGLCEMPEngine);
		    } else {
			CGLDisable(cgl_ctx, kCGLCEMPEngine);
		    }
		});
	    }
	    break;
	}
	case IDX_col0:
	    self.col0 = [d valueForKey:k];
	    goto updateColors;
	case IDX_col1:
	    self.col1 = [d valueForKey:k];
	    goto updateColors;
	case IDX_col2:
	    self.col2 = [d valueForKey:k];
	    goto updateColors;
	case IDX_col3:
	    self.col3 = [d valueForKey:k];
	    goto updateColors;
	case IDX_col4:
	    self.col4 = [d valueForKey:k];
	    goto updateColors;
	updateColors:
	    if (texture) {
		[self updateColors];
		if (!self.refreshing) {
		    [self setNeedsDisplay:YES];
		}
	    }
	    break;
	case NSNotFound:
	default:
	    break;
	}
    }
}

- (void)startQuadtreeProcessing:(float *)quadtree size:(unsigned long)size {
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj]; // CGLMacro.h
    if (!texture) [self updateColors];
    dispatch_async(openglqueue,^{
	CGLSetCurrentContext(cgl_ctx);
	if (size != imageSize) {
	    if (texture) glDeleteTextures(1, &texture);
	    glGenTextures(1, &texture);
	    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);
	    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER,
		    GL_LINEAR);
	    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER,
		    GL_NEAREST);
	    void *buf = calloc(size * size, 4 * sizeof(unsigned char));
	    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGB8, size, size, 0,
		    GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, buf);
	    free(buf);

	    GLfloat texCoords[4][2] = {
		{ 0.0f,  size}, { 0.0f,  0.0f}, { size,  0.0f}, { size,  size}};
	    glBufferSubData(GL_ARRAY_BUFFER, 8 * sizeof(GLfloat),
		    sizeof(texCoords), texCoords);

	    double f;
	    size_t s;
	    s = floor(sqrt(maxQuadtreeKernelWorkGroupSize));
	    do f = (double)size / s; while(f - floor(f) != 0.0 && --s);
	    quadtreeKernelWorkGroupSize = s;
	    s = floor(sqrt(maxColorizeKernelWorkGroupSize));
	    do f = (double)size / s; while(f - floor(f) != 0.0 && --s);
	    colorizeKernelWorkGroupSize = s;

	    imageSize = size;
	    dataLength = size * size * sizeof(float);
	    quadtreeLength = 2 * dataLength;

	    cl_int err;
	    if (quadtreeInputBuffer) clReleaseMemObject(quadtreeInputBuffer);
	    quadtreeInputBuffer = clCreateBuffer(computeContext,
		    CL_MEM_READ_ONLY, quadtreeLength, NULL, &err);
	    DFErrCondAssert(quadtreeInputBuffer,
		    @"create OpenCL quadtree input buffer");

	    for (int i = 0; i < 2; i++) {
		if (quadtreeOutputBuffer[i])
		    clReleaseMemObject(quadtreeOutputBuffer[i]);
		quadtreeOutputBuffer[i] = clCreateBuffer(computeContext,
			CL_MEM_READ_WRITE, dataLength, NULL, &err);
		DFErrCondAssert(quadtreeOutputBuffer[i],
			@"create OpenCL quadtree output buffer");
	    }

	    if (colorizeOutputBuffer) clReleaseMemObject(colorizeOutputBuffer);
	    colorizeOutputBuffer = clCreateBuffer(computeContext,
		    CL_MEM_WRITE_ONLY, size * size * 4 * sizeof(unsigned char),
		    NULL, &err);
	    DFErrCondAssert(colorizeOutputBuffer,
		    @"create OpenCL colorize output buffer");

	    if (renderImage) clReleaseMemObject(renderImage);
	    renderImage = clCreateFromGLTexture2D(computeContext,
		    CL_MEM_WRITE_ONLY, GL_TEXTURE_RECTANGLE_EXT, 0, texture,
		    &err);
	    DFErrCondAssert(renderImage, @"create OpenCL texture reference");

	}
	dispatch_sync(openclqueue,^{
	    quadtreeData = quadtree;
	    [self processQuadtree:self.quadtreeBufferIndex ? 0 : 1];
	});
	colorizeInputBuffer = quadtreeOutputBuffer[self.quadtreeBufferIndex];
	[self resetFps];
    });
    id d = [((DFAppDelegate*)[NSApp delegate]).dataController selection];
    [d setValue:computeDevice forKey:@"opencldevice"];
    self.processing = YES;
    [self startRefresh];
}

- (void)stopQuadtreeProcessing {
    dispatch_sync(openglqueue,^{
	dispatch_sync(openclqueue,^{
	    [self processQuadtree:self.quadtreeBufferIndex ? 0 : 1];
	    quadtreeData = NULL;
	});
    });
    [self setNeedsDisplay:YES];
    [self displayIfNeededIgnoringOpacity];
    self.processing = NO;
    if (!self.cycling) {
	[self stopRefresh];
    }
}

- (void)processQuadtree:(unsigned int)bufferIndex {
    if (quadtreeData) {
	cl_int err = 0;
	cl_event event;
	err = clEnqueueWriteBuffer(quadtreeCommandQueue, quadtreeInputBuffer,
		CL_FALSE, 0, quadtreeLength, quadtreeData, 0, NULL, NULL);
	DFErrAssert(@"write to OpenCL quadtree input buffer");
	const void *values[] = {&quadtreeInputBuffer,
		&quadtreeOutputBuffer[bufferIndex]};
	const size_t sizes[] = {sizeof(cl_mem), sizeof(cl_mem)};
	for (unsigned int i = 0; i < sizeof(values)/sizeof(void*); i++) {
	    err |= clSetKernelArg(quadtreeKernel, i, sizes[i], values[i]);
	}
	DFErrAssert(@"set OpenCL quadtree kernel arguments");
	const size_t global[2] = {imageSize, imageSize};
	const size_t local[2] = {quadtreeKernelWorkGroupSize,
		quadtreeKernelWorkGroupSize};
	err = clEnqueueNDRangeKernel(quadtreeCommandQueue, quadtreeKernel, 2,
		NULL, global, local, 0, NULL, &event);
	DFErrAssert(@"enqueue OpenCL quadtree kernel");

	err = clWaitForEvents(1, &event);
	DFErrAssert(@"wait for OpenCL event");
	clReleaseEvent(event);

	self.quadtreeDone = YES;
	self.quadtreeBufferIndex = bufferIndex;
    }
}

- (void)startRefresh {
    if (self.refreshing) return;
    self.refreshing = YES;
    dispatch_resume(fpstimer);
    [self resetFps];
    if (self.useDLink) {
	CVDisplayLinkStart(displayLink);
	[self setNeedsDisplay:YES];
    } else {
	[self redraw];
    }
}

- (void)stopRefresh {
    if (!self.refreshing) return;
    if (self.useDLink) {
	CVDisplayLinkStop(displayLink);
	[self redraw];
    }
    dispatch_suspend(fpstimer);
    [self resetFps];
    [self updateFps];
    self.refreshing = NO;
}

- (void)redraw {
    if (!self.useDLink) {
	[self drawRect:NSZeroRect];
    } else if (self.needsFlush) {
	self.needsFlush = NO;
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	dispatch_async(openglqueue,^{
	    CGLSetCurrentContext(cgl_ctx);
	    flushFrame(cgl_ctx);
	    [self drawRect:NSZeroRect];
	});
    }
}

- (void)resetFps {
    fpsStartTime = mach_absolute_time();
    frames = 0;
}

- (void)updateFps {
    const uint64_t now = mach_absolute_time();
    const double fps = (frames * tb_freq) / (now - fpsStartTime);
    id d = [((DFAppDelegate*)[NSApp delegate]).dataController selection];
    [d setValue:[NSNumber numberWithDouble:fps] forKey:@"fps"];
    fpsStartTime = now;
    frames = 0;
}

- (void)drawRect:(NSRect)dirtyRect {
    const long double freq = tb_freq;
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj]; // CGLMacro.h
    dispatch_async(openglqueue,^{
	CGLSetCurrentContext(cgl_ctx);
	if (self.needsFlush) {
	    self.needsFlush = NO;
	    flushFrame(cgl_ctx);
	}
	cl_int err = 0;
	if (renderImage) {
	    const long double p = (self.cycling && self.refreshing) ?
		    ((mach_absolute_time() / freq) * self.cycleSpeed +
		    self.cycleBase) : self.cycleBase;
	    const float currentPhase = p - floorl(p);
	    const unsigned int root = self.colorRoot;
	    const void *values[] = {&colorizeInputBuffer, &colorizeOutputBuffer,
		     &gradientBuffer, &currentPhase, &root};
	    const size_t sizes[] = {sizeof(cl_mem), sizeof(cl_mem),
		    sizeof(cl_mem), sizeof(float), sizeof(unsigned int)};
	    for (unsigned int i = 0; i < sizeof(values)/sizeof(void*); i++) {
		err |= clSetKernelArg(colorizeKernel, i, sizes[i], values[i]);
	    }
	    DFErrAssert(@"set OpenCL colorize kernel arguments");

	    const size_t global[2] = {imageSize, imageSize};
	    const size_t local[2] = {colorizeKernelWorkGroupSize,
		    colorizeKernelWorkGroupSize};
	    err = clEnqueueNDRangeKernel(renderCommandQueue, colorizeKernel,
		    2, NULL, global, local, 0, NULL, NULL);
	    DFErrAssert(@"enqueue OpenCL colorize kernel");

	    err = clEnqueueAcquireGLObjects(renderCommandQueue, 1, &renderImage,
		    0, NULL, NULL);
	    DFErrAssert(@"acquire OpenCL GL object");

	    const size_t origin[3] = {0, 0, 0};
	    const size_t region[3] = {imageSize, imageSize, 1};
	    err = clEnqueueCopyBufferToImage(renderCommandQueue,
		    colorizeOutputBuffer, renderImage, 0, origin, region, 0,
		    NULL, NULL);
	    DFErrAssert(@"copy OpenCL buffer to image");
	    err = clEnqueueReleaseGLObjects(renderCommandQueue, 1, &renderImage,
		     0, NULL, NULL);
	    DFErrAssert(@"release OpenCL GL object");

	    if (self.quadtreeDone) {
		self.quadtreeDone = NO;
		const unsigned int bufferIndex = self.quadtreeBufferIndex;
		colorizeInputBuffer = quadtreeOutputBuffer[bufferIndex];
		dispatch_async(openclqueue,^{
		    [self processQuadtree:bufferIndex ? 0 : 1];
		});
	    }
	}
	if (texture) {
	    glDrawRangeElements(GL_QUADS, 0, 3, 4, GL_UNSIGNED_SHORT, NULL);
	    if (self.enabled && self.haveSelection) {
		glCallList(selectionDisplayList);
	    }
	} else {
	    glClear(GL_COLOR_BUFFER_BIT);
	}
	if (self.refreshing) {
	    if (self.useDLink) {
		self.needsFlush = YES;
	    } else {
		flushFrame(cgl_ctx);
		[self redraw];
	    }
	} else {
	    CGLFlushDrawable(cgl_ctx);
	}
    });
}

- (CGImageRef)createImage {
    if (!texture) return NULL;
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CIContext *ciCtx = [CIContext contextWithCGLContext:cgl_ctx
	    pixelFormat:[[self pixelFormat] CGLPixelFormatObj]
	    colorSpace:cs options:nil];
    const CGRect r = {.origin = {0, 0}, .size = {imageSize, imageSize}};
    CIImage *ciImage = [CIImage imageWithTexture:texture
	    size:r.size flipped:YES colorSpace:cs];
    CGImageRef image, *imgPtr = &image;
    dispatch_sync(openglqueue,^{
	CGLSetCurrentContext(cgl_ctx);
	*imgPtr = [ciCtx createCGImage:ciImage fromRect:r];
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER,
		GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER,
		GL_NEAREST);
    });
    CFRelease(cs);
    return image;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.enabled) {
	self.haveSelection = NO;
	selectionOrigin = [self convertPoint:[theEvent locationInWindow]
		fromView:nil];
    } else {
	[super mouseDown:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (self.enabled) {
	NSPoint p = [self convertPoint:[theEvent locationInWindow]
		fromView:nil];
	NSRect r;
	r.origin = selectionOrigin;
	r.size.width  = p.x - r.origin.x;
	r.size.height = p.y - r.origin.y;
	CGFloat s = fmax(fabs(r.size.width), fabs(r.size.height));
	r.size.width  = copysign(s, r.size.width);
	r.size.height = copysign(s, r.size.height);
	if(r.size.width < 0) {
	    r.size.width *= -1;
	    r.origin.x -= r.size.width;
	}
	if (r.size.height < 0 ) {
	    r.size.height *= -1;
	    r.origin.y -= r.size.height;
	}
	selection = r;
	NSSize size = [self bounds].size;
	const CGAffineTransform t = {.a = 2.0/size.width, .b = 0.0,
		.c = 0.0, .d = 2.0/size.height, .tx = -1.0, .ty = -1.0};
	const CGRect nr = CGRectApplyAffineTransform(NSRectToCGRect(r), t);
	const GLfloat x1 = nr.origin.x, x2 = x1 + nr.size.width;
	const GLfloat y1 = nr.origin.y, y2 = y1 + nr.size.height;
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	dispatch_async(openglqueue,^{
	    CGLSetCurrentContext(cgl_ctx);
	    const GLfloat vertices[4][3] = {
		    {x1, y1, -1.0}, {x2, y1, -1.0},
		    {x2, y2, -1.0}, {x1, y2, -1.0}};
	    glNewList(selectionDisplayList, GL_COMPILE);
	    glDisable(GL_TEXTURE_RECTANGLE_EXT);
	    glEnable(GL_BLEND);
	    glBegin(GL_QUADS);
	    glColor4f(0.5f, 0.5f, 0.5f, 0.5f);
	    glVertex2fv(vertices[0]); glVertex2fv(vertices[1]);
	    glVertex2fv(vertices[2]); glVertex2fv(vertices[3]);
	    glEnd();
	    glPolygonMode(GL_FRONT, GL_LINE);
	    glBegin(GL_QUADS);
	    glColor4f(1.0f, 1.0f, 1.0f, 0.8f);
	    glVertex2fv(vertices[0]); glVertex2fv(vertices[1]);
	    glVertex2fv(vertices[2]); glVertex2fv(vertices[3]);
	    glEnd();
	    glPolygonMode(GL_FRONT, GL_FILL);
	    glDisable(GL_BLEND);
	    glEnable(GL_TEXTURE_RECTANGLE_EXT);
	    glEndList();
	    self.haveSelection = YES;
	});
	[self setNeedsDisplay:YES];
    } else {
	[super mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.enabled) {
	DFAppDelegate *d = (DFAppDelegate*)[NSApp delegate];
	NSPoint p = [self convertPoint:[theEvent locationInWindow]
		fromView:nil];
	[self mouseDragged:theEvent];
	if (selection.size.width < 5 || selection.size.height < 5) {
	    NSUInteger modifierFlags = [theEvent modifierFlags];
	    if (modifierFlags & NSAlternateKeyMask) {
		[d centerAtPoint:p];
	    } else if (modifierFlags & NSControlKeyMask) {
		[d zoomOutAtPoint:p];
	    } else {
		[d zoomInAtPoint:p];
	    }
	} else {
	    [d zoomToRect:selection];
	}
	dispatch_async(openglqueue,^{
	    self.haveSelection = NO;
	});
	selectionOrigin = NSZeroPoint;
    } else {
	[super mouseUp:theEvent];
    }
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    if (self.enabled) {
	DFAppDelegate *d = (DFAppDelegate*)[NSApp delegate];
	NSPoint p = [self convertPoint:[theEvent locationInWindow]
		fromView:nil];
	[d zoomOutAtPoint:p];
    } else {
	[super rightMouseUp:theEvent];
    }
}

@end
