//
// File:       DFFractals.c
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

#if FRACTAL_STATISTICS
#define opsStatsSetup()	natural n = 0
#define opsStatsAdd(i)	if (o) { n += (i); }
#define opsStatsEnd()	if (o) { *o = n; }
#else
#define opsStatsSetup()
#define opsStatsAdd(i)
#define opsStatsEnd()
#endif

enum {mandelbrot = 0, julia, mandelsine, juliasine, burningship};

typedef struct {real x, y;} complex;

static inline complex mandelbrot_f(const complex z, const complex c)
	__attribute__((const, always_inline));
static inline complex mandelsine_f(const complex z, const complex c)
	__attribute__((const, always_inline));
static inline complex burningship_f(const complex z, const complex c)
	__attribute__((const, always_inline));
static inline real modsq(const complex z) __attribute__((const, always_inline));

complex mandelbrot_f(const complex z, const complex c) {
    // z := z^2 + c
    const complex w = {
	.x = z.x * z.x - z.y * z.y + c.x,
	.y = 2.0L * z.x * z.y + c.y,
    };
    return w;
}

complex mandelsine_f(const complex z, const complex c) {
    // z := (1+.39i)*sin(z) + c
    const real lx = 1.0L, ly = .39L;
    const real x = SIN(z.x) * COSH(z.y), y = COS(z.x) * SINH(z.y);
    const complex w = {
	.x = lx * x - ly * y + c.x,
	.y = ly * x + lx * y + c.y,
    };
    return w;
}

complex burningship_f(const complex z, const complex c) {
    // z := (|Re(z)|+|Im(z)|i)^2 + c
    const complex w = {
	.x = z.x * z.x - z.y * z.y + c.x,
	.y = 2.0L * FABS(z.x * z.y) + c.y,
    };
    return w;
}

real modsq(const complex z) { return z.x * z.x + z.y * z.y; }

const fractal_compute_t fractalCompute[] = {
    [mandelbrot] =^(const real x, const real y, const natural max, natural *o) {
	real v = -1.0L;
	natural i = 1;
	opsStatsSetup();
	if (max && (x || y)) {
	    const complex c = {.x = x, .y = y};
	    complex z = c;
	    while (i < max) {
		z = mandelbrot_f(z, c);
		i++;
		if (isgreater(modsq(z), 4.0L)) {
		    v = (i + 3) - LOG2(LOG2(modsq(mandelbrot_f(
			    mandelbrot_f(z, c), c))) * (0.5L/M_LOG2E));
		    opsStatsAdd(19);
		    break;
		}
	    }
	    opsStatsAdd(10 * (i - 1));
	}
	opsStatsEnd();
	return v;
    },
    [julia] = ^(const real x, const real y, const natural max, natural *o) {
	real v = -1.0L;
	natural i = 0;
	opsStatsSetup();
	if (max) {
	    const complex c = {.x = -0.743643135L, .y = 0.131825963};
	    complex z = {.x = x, .y = y};
	    while (i < max) {
		z = mandelbrot_f(z, c);
		i++;
		if (isgreater(modsq(z), 4.0L)) {
		    v = (i + 3) - LOG2(LOG2(modsq(mandelbrot_f(
			    mandelbrot_f(z, c), c))) * (0.5L/M_LOG2E));
		    opsStatsAdd(21);
		    break;
		}
	    }
	    opsStatsAdd(12 * i);
	}
	opsStatsEnd();
	return v;
    },
    [mandelsine] =^(const real x, const real y, const natural max, natural *o) {
	real v = -1.0L;
	natural i = 1;
	opsStatsSetup();
	if (max) {
	    const complex c = {.x = x, .y = y};
	    complex z = c;
	    while (i < max) {
		z = mandelsine_f(z, c);
		i++;
		if (isgreater(FABS(z.x), 128.0L)) {
		    v = i;
		    break;
		}
	    }
	    opsStatsAdd(173 * (i - 1));
	}
	opsStatsEnd();
	return v;
    },
    [juliasine] = ^(const real x, const real y, const natural max, natural *o) {
	real v = -1.0L;
	natural i = 0;
	opsStatsSetup();
	if (max) {
	    const complex c = {.x = 2.65724565287168, .y = -.115736335515976};
	    complex z = {.x = x, .y = y};
	    while (i < max) {
		z = mandelsine_f(z, c);
		i++;
		if (isgreater(FABS(z.x), 128.0L)) {
		    v = i;
		    break;
		}
	    }
	    opsStatsAdd(173 * i);
	}
	opsStatsEnd();
	return v;
    },
    [burningship] = ^(const real x, const real y, const natural max, natural *o)
    {
	real v = -1.0L;
	natural i = 1;
	opsStatsSetup();
	if (max) {
	    const complex c = {.x = x, .y = -y};
	    complex z = c;
	    while (i < max) {
		z = burningship_f(z, c);
		i++;
		if (isgreater(modsq(z), 4.0L)) {
		    v = (i + 3) - LOG2(LOG2(modsq(burningship_f(
			    burningship_f(z, c), c))) * (0.5L/M_LOG2E));
		    opsStatsAdd(20);
		    break;
		}
	    }
	    opsStatsAdd(11 * (i - 1));
	}
	opsStatsEnd();
	return v;
    },
};

const fractal_initial_params_t fractalInitialParams[] = {
    [mandelbrot] = {.centerX = -0.743643135, .centerY = 0.131825963,
	    .width = 0.000014628, .maxiterations = 10000, .colorroot = 6},
    [julia] = {.centerX = -.824049066860816, .centerY = -.0297315617238007,
	    .width = .5e-6, .maxiterations = 25000, .colorroot = 4},
    [mandelsine] = {.centerX = 2.65724565287168, .centerY = -.115736335515976,
	    .width = .25, .maxiterations = 5000, .colorroot = 8},
    [juliasine] = {.centerX = -2.20894406557083, .centerY = .759484541416168,
	    .width = .9, .maxiterations = 5000, .colorroot = 9},
    [burningship] = {.centerX = -1.73373398184776, .centerY = .0454643815755844,
	    .width = .14, .maxiterations = 25000, .colorroot = 10},
};

