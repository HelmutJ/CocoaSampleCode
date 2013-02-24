//
// File:       DispatchFractalCLI.c
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

#include <CoreFoundation/CoreFoundation.h>
#include <stdlib.h>
#include <stdio.h>
#include <getopt.h>
#include "DispatchFractal.h"

static const struct option longopts[] = {
    { "fractal",	required_argument, NULL, 'f' },
    { "x",		required_argument, NULL, 'x' },
    { "y",		required_argument, NULL, 'y' },
    { "w",		required_argument, NULL, 'w' },
    { "maxiterations",	required_argument, NULL, 'm' },
    { "concurrent",	required_argument, NULL, 'c' },
    { "subdivisions",	required_argument, NULL, 's' },
    { "stride",		required_argument, NULL, 'r' },
    { "stats",		required_argument, NULL, 't' },
    { "displaystats",	required_argument, NULL, 'd' },
    { "help",		required_argument, NULL, 'h' },
    {},
};

int main (int argc, const char * argv[]) {
    fractal_params_t params = {
	.centerX	    = fractalInitialParams[0].centerX,
	.centerY	    = fractalInitialParams[0].centerY,
	.width		    = fractalInitialParams[0].width,
	.maxiterations	    = fractalInitialParams[0].maxiterations,
	.subdivisions	    = 11,
	.stride		    = 4,
	.computeqconcurrent = true,
	.enabledisplay	    = false,
	.collectstats	    = true,
	.displaystats	    = true,
    };
    int ch, status = 0;
    char *e;
    double d;
    unsigned long u;
    long l;
    unsigned int f = 0;
    while ((ch = getopt_long_only(argc, (char **)argv,
	    "f:x:y:w:m:c:s:r:t:d:h?", longopts, NULL)) != -1) {
	switch (ch) {
	case 'f':
	    f = strtod(optarg, &e); if (*e || f < 1 || f > 5) goto badarg;
	    f--;
	    params.centerX = fractalInitialParams[f].centerX;
	    params.centerY = fractalInitialParams[f].centerY;
	    params.width = fractalInitialParams[f].width;
	    params.maxiterations = fractalInitialParams[f].maxiterations;
	    break;
	case 'x':
	    d = strtod(optarg, &e); if (*e) goto badarg;
	    params.centerX = d;
	    break;
	case 'y':
	    d = strtod(optarg, &e); if (*e) goto badarg;
	    params.centerY = d;
	    break;
	case 'w':
	    d = strtod(optarg, &e); if (*e || !d) goto badarg;
	    params.width = d;
	    break;
	case 'm':
	    u = strtoul(optarg, &e, 10); if (*e || !u) goto badarg;
	    params.maxiterations = u;
	    break;
	case 'c':
	    l = strtol(optarg, &e, 10); if (*e || l < -3 ) goto badarg;
	    params.computeqconcurrent = l;
	    break;
	case 's':
	    u = strtoul(optarg, &e, 10); if (*e) goto badarg;
	    params.subdivisions = u;
	    break;
	case 'r':
	    u = strtoul(optarg, &e, 10); if (*e || !u) goto badarg;
	    params.stride = u;
	    break;
	case 't':
	    u = strtoul(optarg, &e, 10); if (*e || u > 1) goto badarg;
	    params.collectstats = u;
	    break;
	case 'd':
	    u = strtoul(optarg, &e, 10); if (*e || u > 1) goto badarg;
	    params.displaystats = u;
	    break;
	case 0:
	    break;
	case ':':
	badarg:
	    fprintf(stderr, "%s: %s argument `%s'\n", argv[0],
		    ch==':' ? "Missing" : "Invalid", optind > 1 &&
		    optind <= argc ? argv[optind-1] : "");
	case '?':
	    status = 1;
	case 'h':
	default:
	    fprintf(stderr, "Usage:\t%s [options]\n\n", argv[0]);
	    fprintf(stderr, "\t-fractal 1|2|3|4|5\n"
		    "\t-x value -y value -w value -maxiterations value\n"
		    "\t-concurrent 0|1 -subdivisions value -stride value\n"
		    "\t-collectstats 0|1 -displaystats 0|1\n\n");
	    exit(status);
	    break;
	}
    }
    if (argc > optind) { optind++; goto badarg; }
    fractal_t fractal = fractalNew();
    fractalStart(fractal, ^{
	return params;
    }, fractalCompute[f], ^(fractal_out_t * const quadtree, const natural size) {
    }, ^(const nanoseconds elapsed) {
#if !FRACTAL_STATISTICS
	fprintf(stderr, "%5.2f s  Done!\n", (double)elapsed/NSEC_PER_SEC);
#endif
	fractalFree(fractal);
	CFRunLoopStop(CFRunLoopGetMain());
    }, ^(const counter computedone, const counter computequeued,
	    const counter computemax, const counter flops,
	    const nanoseconds elapsed) {
	fprintf(stderr, "%5.2f s; compute: %3lld%% done, %8lld blocks done, "
		"%8lld blocks queued; %5.2f GFLOPs\n",
		(double)elapsed/NSEC_PER_SEC, 100*computedone/computemax,
		computedone, computequeued, (double)flops/elapsed);
    });
    CFRunLoopRun();
    return 0;
}
