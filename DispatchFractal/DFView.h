//
// File:       DFView.h
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenCL/opencl.h>
#import <dispatch/dispatch.h>

@interface DFView : NSOpenGLView {
@private
    dispatch_queue_t openglqueue, openclqueue;
    dispatch_source_t fpstimer;
    CVDisplayLinkRef displayLink;
    GLuint texture, vertexBuffer, indexBuffer, selectionDisplayList;
    cl_context computeContext;
    cl_program computeProgram;
    cl_command_queue quadtreeCommandQueue, renderCommandQueue;
    cl_kernel quadtreeKernel, colorizeKernel;
    cl_mem quadtreeInputBuffer, quadtreeOutputBuffer[2];
    cl_mem colorizeInputBuffer, colorizeOutputBuffer;
    cl_mem renderImage, gradientBuffer;
    size_t quadtreeLength, dataLength, gradientLength, imageSize;
    size_t maxQuadtreeKernelWorkGroupSize, quadtreeKernelWorkGroupSize;
    size_t maxColorizeKernelWorkGroupSize, colorizeKernelWorkGroupSize;
    float *quadtreeData, *gradientComponents;
    unsigned int quadtreeBufferIndex, colorRoot;
    BOOL enabled, haveSelection, needsFlush, quadtreeDone, processing;
    BOOL cycling, refreshing, vSync, useDLink, useGLMPEngine;
    double cycleSpeed;
    long double cycleBase, tb_freq;
    volatile int64_t frames;
    uint64_t fpsStartTime;
    NSColor *col0, *col1, *col2, *col3, *col4;
    NSPoint selectionOrigin;
    NSRect selection;
    NSString *computeDevice;
    NSArray *observedKeys;
}

@property BOOL enabled, haveSelection, needsFlush, quadtreeDone, processing;
@property BOOL cycling, refreshing, vSync, useDLink, useGLMPEngine;
@property unsigned int quadtreeBufferIndex, colorRoot;
@property double cycleSpeed;
@property long double cycleBase;
@property(copy) NSColor *col0, *col1, *col2, *col3, *col4;
@property(retain) NSArray *observedKeys;

- (void)startQuadtreeProcessing:(float *)quadtree size:(unsigned long)size;
- (void)stopQuadtreeProcessing;
- (CGImageRef)createImage;
@end
