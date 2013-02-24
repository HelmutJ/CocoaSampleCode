//
// File:       DispatchFractal.c
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

#include "DispatchFractal.h"
#include <stdlib.h>
#include <strings.h>
#include <dispatch/dispatch.h>
#include <Block.h>
#include <libkern/OSAtomic.h>
#include <assert.h>

#pragma mark Data

typedef struct {
    real minradius;
    natural maxiterations, stride, quadtreewidth;
    fractal_out_t *quadtree;
    bool enabledisplay, collectstats;
    fractal_compute_t compute;
    dispatch_group_t group;
    dispatch_queue_t computequeue;
    volatile counter generation, stopping;
#if FRACTAL_TIMING || FRACTAL_STATISTICS
    nanoseconds startTime;
    dispatch_source_t statstimer;
#endif
#if FRACTAL_STATISTICS
    volatile counter computequeued, computedone;
    volatile counter flops;
#endif
} fractal_data_t;

#define newGeneration(data) \
	OSAtomicAdd64Barrier(1, &((data)->generation))
#define generationValid(data, generation) \
	((data)->generation == (generation))
#define stopBlocks(data) \
	OSAtomicAdd64Barrier(1, &((data)->stopping))
#define quadtreeLoc(data, x, y, o) ((data)->quadtree + \
	(((data)->quadtreewidth - (o)) + (x) + (y) * (data)->quadtreewidth))

#pragma mark Timing

#if FRACTAL_TIMING || FRACTAL_STATISTICS
#include <mach/mach_time.h>
static mach_timebase_info_data_t tb = {};
#define timingSetup(data) \
	if (!tb.numer) { mach_timebase_info(&tb); }; \
	data->startTime = mach_absolute_time()
#define timingStart(data) \
	data->startTime = mach_absolute_time()
#define elapsedNs(data) \
	((mach_absolute_time() - data->startTime) * tb.numer / tb.denom)
#else /* FRACTAL_TIMING */
#define timingSetup(data)
#define timingStart(data)
#define elapsedNs(data) 0
#endif /* FRACTAL_TIMING */

#pragma mark Statistics

#if FRACTAL_STATISTICS

#define computeBlockQueued(data) \
	if (data->collectstats) { OSAtomicAdd64( 1, &(data->computequeued)); }
#define computeBlockDequeued(data) \
	if (data->collectstats) { OSAtomicAdd64(-1, &(data->computequeued)); }
#define computeBlockDone(data, g) \
	if (data->collectstats && generationValid(data, g)) { \
	OSAtomicAdd64( 1, &(data->computedone)); }
#define opsStatsSetup() natural n = 0
#define ops (data->collectstats ? &n : NULL)
#define opsStatsUpdate(data) \
	if (data->collectstats) { OSAtomicAdd64(n, &(data->flops)); }
#define updateStatsDisplay(data, computemax, stats_b) \
	stats_b(data->computedone, data->computequeued, computemax, \
	data->flops, elapsedNs(data))
#else /* FRACTAL_STATISTICS */
#define computeBlockQueued(data)
#define computeBlockDequeued(data)
#define computeBlockDone(data, g)
#define opsStatsSetup()
#define ops NULL
#define opsStatsUpdate(data)
#endif /* FRACTAL_STATISTICS */

#pragma mark Computation Blocks

#define enqueueCompute(data, cX, cY, r, px, py, po, i, g) \
	computeBlockQueued(data); \
	dispatch_group_async(data->group, data->computequeue, ^{ \
	    if (generationValid(data, g) && !data->stopping) { \
		compute(data, cX, cY, r, px, py, po, i, g); \
		computeBlockDone(data, g); \
	    } computeBlockDequeued(data); \
	})

#if FRACTAL_STATISTICS
static natural totalBlocks(const natural subdiv, const natural stride)
	__attribute__((const));
natural totalBlocks(const natural subdiv, const natural stride) {
    natural b = 1;
    if (subdiv > 0 && subdiv >= stride) {
    	b += 4;
	if (subdiv > 1 && subdiv > stride) {
	    const natural k = (subdiv % stride ? subdiv % stride : stride) + 1;
	    /*
	     * Sum(i=k, i<=subdiv, i+=stride, 4^i) := 
	     * (4^k) * ((4^stride)^((subdiv-k)/stride+1)-1) / ((4^stride)-1))
	     */
	    #define e(x) (1ul << (2ul * (x)))
	    b += e(k) * (e(stride * (((subdiv - k) / stride) + 1ul)) - 1ul) /
		    (e(stride) - 1ul);
	    #undef e
    	}
    }
    return b;
}
#endif /* FRACTAL_STATISTICS */

static void compute(fractal_data_t * const data, const real centerX,
	const real centerY, const real radius,
	const natural px, const natural py, const natural po,
	natural iteration, const counter generation)
{
    opsStatsSetup();
    real val = data->compute(centerX, centerY, data->maxiterations, ops);
    if (!generationValid(data, generation) || data->stopping) return;
    opsStatsUpdate(data);
    if (data->enabledisplay) {
	*quadtreeLoc(data, px, py, po) = val;
    }
    if (radius > data->minradius) {
	const real r = radius / 2;
	const real x1 = centerX - r, x2 = centerX + r;
	const real y1 = centerY + r, y2 = centerY - r;
	const natural o = po << 1ul;
	const natural px1 = px << 1ul, px2 = px1 + 1;
	const natural py1 = py << 1ul, py2 = py1 + 1;  
	if (iteration++ < data->stride) {
	    compute(data, x1, y1, r, px1, py1, o, iteration, generation);
	    compute(data, x2, y1, r, px2, py1, o, iteration, generation);
	    compute(data, x1, y2, r, px1, py2, o, iteration, generation);
	    compute(data, x2, y2, r, px2, py2, o, iteration, generation);
	} else {
	    iteration -= data->stride;
	    enqueueCompute(data, x1, y1, r, px1, py1, o, iteration, generation);
	    enqueueCompute(data, x2, y1, r, px2, py1, o, iteration, generation);
	    enqueueCompute(data, x1, y2, r, px1, py2, o, iteration, generation);
	    enqueueCompute(data, x2, y2, r, px2, py2, o, iteration, generation);
	}
    }
}

#pragma mark Fractal API

fractal_t fractalNew(void) {
    return calloc(1, sizeof(fractal_data_t));
}

void fractalFree(fractal_t fractal) {
    fractal_data_t * const data = fractal;
    if (data->group) {
	if (!data->stopping) { 
	    fractalStop(fractal);
	}
	dispatch_group_wait(data->group, DISPATCH_TIME_FOREVER);
    }
    free((void*) fractal);
}

void fractalStart(fractal_t fractal,
	fractal_params_t (^params_b)(void), fractal_compute_t compute_b,
	void (^start_b)(fractal_out_t * const, const natural),
	void (^stop_b)(const nanoseconds),
	void (^stats_b)(const counter, const counter, const counter,
	const counter, const nanoseconds))
{
    fractal_data_t * const data = fractal;
    if (data->stopping) return;
    const counter generation = newGeneration(data);
    timingSetup(data);
    const fractal_params_t params = params_b();
    const natural pixels = 1ul << params.subdivisions;
    const real radius = params.width / 2;
    data->minradius = radius / pixels;
    data->maxiterations = params.maxiterations;
    data->stride = params.stride;
    data->enabledisplay = params.enabledisplay;
    if (data->enabledisplay) {
	if (!data->quadtree) {
	    data->quadtreewidth = 2 * pixels;
	    data->quadtree = calloc(2 * pixels * pixels, sizeof(fractal_out_t));
	} else {
	    assert(data->quadtreewidth == 2 * pixels);
	    bzero(data->quadtree, 2 * pixels * pixels * sizeof(fractal_out_t));
	}
	*quadtreeLoc(data, 0, 0, 2) = 0.0001;
    }
    data->collectstats = params.collectstats;
    if (data->compute) { Block_release(data->compute); }
    data->compute = Block_copy(compute_b);
    if (!data->computequeue) {
	dispatch_queue_t globalqueue = dispatch_get_global_queue(
		DISPATCH_QUEUE_PRIORITY_LOW, 0);
	assert(globalqueue);
	if (params.computeqconcurrent) {
	    data->computequeue = globalqueue;
	} else {
	    data->computequeue = dispatch_queue_create(
		    "com.dispatchfractal.compute", NULL);
	    dispatch_set_target_queue(data->computequeue, globalqueue);
	    assert(data->computequeue);
	}
	data->group = dispatch_group_create();
    }
#if FRACTAL_STATISTICS
    const counter computemax = totalBlocks(params.subdivisions, params.stride);
    data->computedone = 0; data->flops = 0;
    if (params.collectstats && params.displaystats) {
	updateStatsDisplay(data, computemax, stats_b);
	if (data->statstimer) {
	    dispatch_suspend(data->statstimer);	
	} else {
	    data->statstimer = dispatch_source_create(
		    DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
		    dispatch_get_main_queue());
	}
	dispatch_source_set_timer(data->statstimer, dispatch_time(
		DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), .5 * NSEC_PER_SEC,
		.1 * NSEC_PER_SEC);
	dispatch_source_set_event_handler(data->statstimer, ^{
	    updateStatsDisplay(data, computemax, stats_b);
	});
	dispatch_resume(data->statstimer);
    }
#endif
    start_b(data->quadtree, pixels);
    timingStart(data);
    enqueueCompute(data, params.centerX, params.centerY, radius, 0, 0, 2,
	    params.subdivisions >= params.stride ? params.stride +
	    (params.subdivisions % params.stride ? params.stride - 
	    params.subdivisions % params.stride : 0) : 1, generation);
    dispatch_group_notify(data->group, dispatch_get_main_queue(), ^{
	if (generationValid(data, generation)) {
	    dispatch_release(data->computequeue); data->computequeue = NULL;
	    dispatch_release(data->group); data->group = NULL;
	    Block_release(data->compute); data->compute = NULL;
#if FRACTAL_STATISTICS
	    if (data->statstimer) {
		dispatch_source_cancel(data->statstimer);
		dispatch_release(data->statstimer);
		data->statstimer = NULL;
	    }
	    updateStatsDisplay(data, computemax, stats_b);
#endif
	    data->stopping = 0;
	    stop_b(elapsedNs(data));
	    if (data->quadtree) {
		free(data->quadtree);
		data->quadtree = NULL;
	    }
	}
    });
}

void fractalStop(fractal_t fractal) {
    stopBlocks((fractal_data_t *)fractal);
}
