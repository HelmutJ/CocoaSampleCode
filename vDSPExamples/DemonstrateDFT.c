/*
	    File: DemonstrateDFT.c
	Abstract: Demonstration of vDSP DFT routines.
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
	

	This is a sample module to illustrate the use of vDSP's DFT functions.
	This module also times the functions.

	Copyright (C) 2007, 2010 Apple Inc.  All rights reserved.
*/


#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <Accelerate/Accelerate.h>

#include "Demonstrate.h"


#define Iterations	10000	// Number of iterations used in the timing loop.

#define	N		960	// Number of elements.


static const float_t TwoPi = 0x3.243f6a8885a308d313198a2e03707344ap1;


/*	Compare two complex vectors and report the relative error between them.
	(The vectors must have unit strides; other strides are not supported.)
*/
static void CompareComplexVectors(
	DSPSplitComplex Expected, DSPSplitComplex Observed, vDSP_Length Length)
{
	double_t Error = 0, Magnitude = 0;

	int i;
	for (i = 0; i < Length; ++i)
	{
		double_t re, im;

		// Accumulate square of magnitude of elements.
		re = Expected.realp[i];
		im = Expected.imagp[i];
		Magnitude += re*re + im*im;

		// Accumulate square of error.
		re = Expected.realp[i] - Observed.realp[i];
		im = Expected.imagp[i] - Observed.imagp[i];
		Error += re*re + im*im;
	}

	printf("\tRelative error in observed result is %g.\n",
		sqrt(Error / Magnitude));
}


/*	Demonstrate the real-to-complex one-dimensional out-of-place DFT.

	Applications may need to rearrange data before calling the
	real-to-complex DFT.  This is because the vDSP DFT routines currently
	use a separated-data complex format, in which real components and
	imaginary components are stored in different arrays.  For the
	real-to-complex DFT, real data passed using the same arrangements used
	for complex data.  (This is largely due to the nature of the algorithm
	used in performing in the real-to-complex DFT.) The mapping puts
	even-indexed elements of the real data in real components of the
	complex data and odd-indexed elements of the real data in imaginary
	components of the complex data.

	(It is possible to improve this situation by implementing
	interleaved-data complex format.  If you would benefit from such
	routines, please enter an enhancement request at
	http://developer.apple.com/bugreporter.)

	If an application's real data is stored sequentially in an array (as is
	common) and the design cannot be altered to provide data in the
	even-odd split configuration, then the data can be moved using the
	routine vDSP_ctoz.

	The output of the real-to-complex DFT contains only the first N/2
	complex elements, with one exception.  This is because the second N/2
	elements are complex conjugates of the first N/2 elements, so they are
	redundant.

	The exception is that the imaginary parts of elements 0 and N/2 are
	zero, so only the real parts are provided.  The real part of element
	N/2 is stored in the space that would be used for the imaginary part of
	element 0.

	See the vDSP Library manual for illustration and additional
	information.
*/
static void DemonstratevDSP_DFT_zrop(vDSP_DFT_Setup Setup)
{
	/*	Define a stride for the array be passed to the DFT.  In many
		applications, the strides are one and is passed to vDSP
		routines as constants.
	*/
	const vDSP_Stride Stride = 1;

	// Define a variable for a loop iterator.
	vDSP_Length i;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tOne-dimensional real DFT of %lu elements.\n",
		(unsigned long) N);

	// Allocate memory for the arrays.
	float *Signal = malloc(N * Stride * sizeof Signal);
	float *BufferMemory = malloc(N * sizeof *BufferMemory);
	float *ObservedMemory = malloc(N * sizeof *ObservedMemory);

	if (ObservedMemory == NULL || BufferMemory == NULL || Signal == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	// Assign half of BufferMemory to reals and half to imaginaries.
	DSPSplitComplex Buffer = { BufferMemory, BufferMemory + N/2 };

	// Assign half of ObservedMemory to reals and half to imaginaries.
	DSPSplitComplex Observed = { ObservedMemory, ObservedMemory + N/2 };

	/*	Generate an input signal.  In a real application, data would of
		course be provided from an image file, sensors, or other source.
	*/
	const float Frequency0 = 48, Frequency1 = 243, Frequency2 = 300;
	const float Phase0 = 1.f/3, Phase1 = .82f, Phase2 = .5f;
	for (i = 0; i < N; ++i)
		Signal[i*Stride] =
			  cos((i * Frequency0 / N + Phase0) * TwoPi)
			+ cos((i * Frequency1 / N + Phase1) * TwoPi)
			+ cos((i * Frequency2 / N + Phase2) * TwoPi);

	/*	Reinterpret the real signal as an interleaved-data complex
		vector and use vDSP_ctoz to move the data to a separated-data
		complex vector.  This puts the even-indexed elements of Signal
		in Observed.realp and the odd-indexed elements in
		Observed.imagp.

		Note that we pass vDSP_ctoz two times Signal's normal stride,
		because ctoz skips through a complex vector from real to real,
		skipping imaginary elements.  Considering this as a stride of
		two real-sized elements rather than one complex element is a
		legacy use.

		In the destination array, a stride of one is used regardless of
		the source stride.  Since the destination is a buffer allocated
		just for this purpose, there is no point in replicating the
		source stride. and the DFT routines work best with unit
		strides.  (In fact, the routine we use here, vDSP_DFT_Execute,
		uses only a unit stride and has no parameter for anything
		else.)
	*/
	vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Buffer, 1, N/2);

	// Perform a real-to-complex DFT.
	vDSP_DFT_Execute(Setup,
		Buffer.realp, Buffer.imagp,
		Observed.realp, Observed.imagp);

	/*	Prepare expected results based on analytical transformation of
		the input signal.
	*/
	float *ExpectedMemory = malloc(N * sizeof *ExpectedMemory);
	if (ExpectedMemory == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	// Assign half of ExpectedMemory to reals and half to imaginaries.
	DSPSplitComplex Expected = { ExpectedMemory, ExpectedMemory + N/2 };

	for (i = 0; i < N/2; ++i)
		Expected.realp[i] = Expected.imagp[i] = 0;

	// Add the frequencies in the signal to the expected results.
	Expected.realp[(int) Frequency0] = N * cos(Phase0 * TwoPi);
	Expected.imagp[(int) Frequency0] = N * sin(Phase0 * TwoPi);

	Expected.realp[(int) Frequency1] = N * cos(Phase1 * TwoPi);
	Expected.imagp[(int) Frequency1] = N * sin(Phase1 * TwoPi);

	Expected.realp[(int) Frequency2] = N * cos(Phase2 * TwoPi);
	Expected.imagp[(int) Frequency2] = N * sin(Phase2 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Observed, N/2);

	// Release memory.
	free(ExpectedMemory);

	/*	The above shows how to use the vDSP_DFT_Execute routine.  Now we
		will see how fast it is.
	*/

	// Time vDSP_DFT_Execute by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_DFT_Execute(Setup,
			Buffer.realp, Buffer.imagp,
			Observed.realp, Observed.imagp);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tReal-to-complex DFT on %lu elements takes %g microseconds.\n",
		(unsigned long) N, Time * 1e6);

	/*	Time vDSP_DFT_Execute with the vDSP_ctoz and vDSP_ztoc
		transformations.
	*/

	/*	Zero the signal before timing because repeated DFTs on non-zero
		data can cause abnormalities such as infinities, NaNs, and
		subnormal numbers.
	*/
	for (i = 0; i < N; ++i)
		Signal[i*Stride] = 0;

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
	{
		vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Observed, 1, N/2);
		vDSP_DFT_Execute(Setup,
			Buffer.realp, Buffer.imagp,
			Observed.realp, Observed.imagp);
		vDSP_ztoc(&Observed, 1, (DSPComplex *) Signal, 2*Stride, N/2);
	}

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf(
"\tReal-to-complex DFT with vDSP_ctoz and vDSP_ztoc takes %g microseconds.\n",
		Time * 1e6);

	// Release resources.
	free(ObservedMemory);
	free(BufferMemory);
	free(Signal);
}


/*	Demonstrate the complex one-dimensional out-of-place DFT.
*/
static void DemonstratevDSP_DFT_zop(vDSP_DFT_Setup Setup)
{
	// Define a variable for a loop iterator.
	vDSP_Length i;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tOne-dimensional complex DFT of %ld elements.\n",
		(unsigned long) N);

	// Allocate memory for the arrays.
	DSPSplitComplex Signal, Observed;
	Signal.realp = malloc(N * sizeof Signal.realp);
	Signal.imagp = malloc(N * sizeof Signal.imagp);
	Observed.realp = malloc(N * sizeof Observed.realp);
	Observed.imagp = malloc(N * sizeof Observed.imagp);

	if (Signal.realp == NULL || Signal.imagp == NULL
		|| Observed.realp == NULL || Observed.imagp == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	/*	Generate an input signal.  In a real application, data would of
		course be provided from an image file, sensors, or other source.
	*/
	const float Frequency0 = 300, Frequency1 = 450, Frequency2 = 775;
	const float Phase0 = .3, Phase1 = .45f, Phase2 = .775f;
	for (i = 0; i < N; ++i)
	{
		Signal.realp[i] =
			  cos((i * Frequency0 / N + Phase0) * TwoPi)
			+ cos((i * Frequency1 / N + Phase1) * TwoPi)
			+ cos((i * Frequency2 / N + Phase2) * TwoPi);
		Signal.imagp[i] =
			  sin((i * Frequency0 / N + Phase0) * TwoPi)
			+ sin((i * Frequency1 / N + Phase1) * TwoPi)
			+ sin((i * Frequency2 / N + Phase2) * TwoPi);
	}

	// Perform a DFT.
	vDSP_DFT_Execute(Setup,
		Signal.realp, Signal.imagp,
		Observed.realp, Observed.imagp);

	/*	Prepare expected results based on analytical transformation of
		the input signal.
	*/
	DSPSplitComplex Expected;
	Expected.realp = malloc(N * sizeof Expected.realp);
	Expected.imagp = malloc(N * sizeof Expected.imagp);

	if (Expected.realp == NULL || Expected.imagp == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	for (i = 0; i < N/2; ++i)
		Expected.realp[i] = Expected.imagp[i] = 0;

	// Add the frequencies in the signal to the expected results.
	Expected.realp[(int) Frequency0] = N * cos(Phase0 * TwoPi);
	Expected.imagp[(int) Frequency0] = N * sin(Phase0 * TwoPi);

	Expected.realp[(int) Frequency1] = N * cos(Phase1 * TwoPi);
	Expected.imagp[(int) Frequency1] = N * sin(Phase1 * TwoPi);

	Expected.realp[(int) Frequency2] = N * cos(Phase2 * TwoPi);
	Expected.imagp[(int) Frequency2] = N * sin(Phase2 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Observed, N);

	// Release memory.
	free(Expected.realp);
	free(Expected.imagp);

	/*	The above shows how to use the vDSP_DFT_Execute routine.  Now we
		will see how fast it is.
	*/

	// Time vDSP_DFT_Execute by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_DFT_Execute(Setup,
			Signal.realp, Signal.imagp,
			Observed.realp, Observed.imagp);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tvComplex DFT on %lu elements takes %g microseconds.\n",
		(unsigned long) N, Time * 1e6);

	// Release resources.
	free(Signal.realp);
	free(Signal.imagp);
	free(Observed.realp);
	free(Observed.imagp);
}


// Demonstrate vDSP DFT functions.
void DemonstrateDFT(void)
{
	printf("Begin %s.\n", __func__);

	// Initialize data for the DFT routines.

	vDSP_DFT_Setup zop_Setup
		= vDSP_DFT_zop_CreateSetup(0, N, vDSP_DFT_FORWARD);
	if (zop_Setup == NULL)
	{
		fprintf(stderr, "Error, vDSP_zop_CreateSetup failed.\n");
		exit (EXIT_FAILURE);
	}

	vDSP_DFT_Setup zrop_Setup
		= vDSP_DFT_zrop_CreateSetup(zop_Setup, N, vDSP_DFT_FORWARD);
	if (zrop_Setup == NULL)
	{
		fprintf(stderr, "Error, vDSP_zop_CreateSetup failed.\n");
		exit (EXIT_FAILURE);
	}

	DemonstratevDSP_DFT_zrop(zrop_Setup);
	DemonstratevDSP_DFT_zop(zop_Setup);

	vDSP_DFT_DestroySetup(zop_Setup);
	vDSP_DFT_DestroySetup(zrop_Setup);

	printf("\nEnd %s.\n\n\n", __func__);
}
