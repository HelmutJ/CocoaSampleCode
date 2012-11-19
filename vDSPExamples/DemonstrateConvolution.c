/*
	    File: DemonstrateConvolution.c
	Abstract: Demonstration of vDSP convolution routine.
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
	
	Copyright (C) 2012 Apple Inc. All Rights Reserved.
	

	This is a sample module to illustrate the use of vDSP_conv for
	convolution and correlation.  This module also times the vDSP_conv.

	Copyright (C) 2007 Apple Inc.  All rights reserved.
*/

#include <stdio.h>
#include <stdlib.h>

#include <Accelerate/Accelerate.h>

#include "Demonstrate.h"


#define Iterations 1000	// How many iterations to use in the timer loop.


// Demonstrate vDSP_conv.
void DemonstrateConvolution(void)
{
	/*	Define strides for the arrays being passed to the convolution.
		In many applications, the strides are one and are passed to the
		vDSP routine as constants.  We give them names here just so
		that the routine call is more illustrative, showing the
		arguments by name.
	*/
	const vDSP_Stride
		SignalStride = 1,
		FilterStride = 1,
		ResultStride = 1;

	/*	Lengths tend to differ more than strides, although it is might
		not be unusual to have constants in a particular application.
		(For example, your filter length might be a constant because
		the code is written specially for a very specific filter.  The
		result length is more likely to be a named constant at least,
		representing a frame size.)

		The signal length is padded a bit.  This length is not actually
		passed to the vDSP_conv routine; it is the number of elements
		that the signal array must contain.  The SignalLength defined
		below is used to allocate space, and it is the filter length
		rounded up to a multiple of four elements and added to the
		result length.  The extra elements give the vDSP_conv routine
		leeway to perform vector-load instructions, which load multiple
		elements even if they are not all used.  If the caller did not
		guarantee that memory beyond the values used in the signal
		array were accessible, a memory access violation might result.
	*/
	vDSP_Length
		FilterLength = 256,
		ResultLength = 2048,
		SignalLength = (FilterLength+3 & -4u) + ResultLength;

	// Define pointers to the arrays we will use.
	float *Signal, *Filter, *Result;

	// Define a variable for a loop iterator.
	vDSP_Length i;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	float Time, Gigaflops;

	printf("Begin %s.\n\n", __func__);

	// Allocate memory for the arrays.
	Signal = malloc(SignalLength * SignalStride * sizeof *Signal);
	Filter = malloc(FilterLength * FilterStride * sizeof *Filter);
	Result = malloc(ResultLength * ResultStride * sizeof *Result);

	if (Signal == NULL || Filter == NULL || Result == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	/*	Initialize the input signal.  In a real application, data would
		of course be provided from an image file, sensors, or other
		source.
	*/
	for (i = 0; i < SignalLength; i++)
		Signal[i*SignalStride] = 1.0;

	/*	Initialize the filter.  A real application would have different
		filter coefficients.
	*/
	for (i = 0; i < FilterLength; i++)
		Filter[i*FilterStride] = 1.0;

	// Perform a correlation.
	vDSP_conv(Signal, SignalStride, Filter, FilterStride,
		Result, ResultStride, ResultLength, FilterLength);

	/*	Perform a convolution by using the filter backward.  To do
		this, we pass -1 for the filter stride and pass vDSP_conv a
		pointer to the first element of the backward filter, which is
		the last element of the forward filter.
	*/
	vDSP_conv(Signal, SignalStride, Filter + FilterLength - 1, -1,
		Result, ResultStride, ResultLength, FilterLength);

	/*	The above calls show how to use the vDSP_conv routine.  Now we
		will see how fast it is.
	*/

	t0 = Clock();

	for (i = 0; i < Iterations; i++)
		vDSP_conv(Signal, SignalStride, Filter, FilterStride,
			Result, ResultStride, ResultLength, FilterLength);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	/*	For each result element, a convolution takes a multiply for
		each filter element and an addition for each element after the
		first.  So there are ResultLength * (2 * FilterLength - 1)
		floating-point operations in this convolution.  We divide that
		by the number of seconds it takes to do the convolution to get
		floating-point operations per second and then scale by 1e-9 to
		get gigaflops.
	*/
	Gigaflops = ResultLength * (2 * FilterLength - 1) / Time * 1e-9;

	printf("\tA %lu * %lu convolution takes %g microseconds,\n"
		"\twhich is a performance of %g gigaflops.\n\n",
		(unsigned long) ResultLength, (unsigned long) FilterLength,
		Time * 1e6, Gigaflops);

	// Free allocated memory.
	free(Signal);
	free(Filter);
	free(Result);

	printf("End %s.\n\n\n", __func__);
}
