/*
	    File: DemonstrateFFT2D.c
	Abstract: Demonstration of vDSP two-dimemsional FFT routines.
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
	

	This is a sample module to illustrate the use of vDSP's two-dimensional
	FFT functions.  This module also times the functions.

	Copyright (C) 2007 Apple Inc.  All rights reserved.
*/


#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <Accelerate/Accelerate.h>

#include "Demonstrate.h"


#define Iterations	10000	// Number of iterations used in the timing loop.

#define Log2R	5u		// Base-two logarithm of number of rows.
#define Log2C	6u		// Base-two logarithm of number of columns.
#define	R	(1u<<Log2R)	// Number of rows.
#define	C	(1u<<Log2C)	// Number of columns.
#define	N	(R*C)		// Total number of elements.


static const float_t TwoPi = 0x3.243f6a8885a308d313198a2e03707344ap1;


// Return the maximum of two numbers.
#define	max(a, b)	((a) < (b) ? (b) : (a))


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


/*	Demonstrate the real-to-complex two-dimensional in-place FFT,
	vDSP_fft2d_zrip.

	The in-place FFT writes results into the same array that contains the
	input data.

	Applications may need to rearrange data before calling the
	real-to-complex FFT.  This is because the vDSP FFT routines currently
	use a separated-data complex format, in which real components and
	imaginary components are stored in different arrays.  For the
	real-to-complex FFT, real data passed using the same arrangements used
	for complex data.  (This is largely due to the nature of the algorithm
	used in performing in the real-to-complex FFT.)

	With a one-dimensional array, the mapping puts even-indexed elements of
	the real data in real components of the complex data and odd-indexed
	elements of the real data in imaginary components of the complex-data.
	With two-dimensional arrays stored in row-major order (which C uses and
	FORTRAN does not), the even-indexed elements within each row are mapped
	to the real components, and the odd-indexed elements are mapped to
	imaginary components.  Thus, an element in row 13 and column 24 would
	be mapped to an element in row 13 and column 12 of the array containing
	real components.  An element in row 13 and column 25 would be mapped to
	an element in row 13 and column 12 of the array containing imaginary
	components.

	(It is possible to improve this situation by implementing
	interleaved-data complex format.  If you would benefit from such
	routines, please enter an enhancement request at
	http://developer.apple.com/bugreporter.)

	If an application's real data is stored sequentially in an array (as is
	common) and the design cannot be altered to provide data in the
	even-odd split configuration, then the data can be moved using the
	routine vDSP_ctoz.

	As noted in the one-dimensional FFT code and the vDSP Library manual,
	the output of the real-to-complex FFT with N real inputs contains only
	about N/2 complex numbers (actually N/2-1 complex numbers and two real
	numbers).  The two-dimensional real-to-complex FFT has similar
	symmetries, and some of its mathematical outputs are packed to fit into
	memory with the same dimensions as the input.  This packing results in
	some awkward arrangements in the first column (index 0) of the output.
	It is described in the vDSP Library manual and not further addressed
	here.
*/
static void DemonstratevDSP_fft2d_zrip(FFTSetup Setup)
{
	/*	Define a stride for the array be passed to the FFT.  In many
		applications, the stride is one and is passed to the vDSP
		routine as a constant.
	*/
	const vDSP_Stride Stride = 1;

	// Define variables for loop iterators.
	vDSP_Length i, r, c;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tTwo-dimensional real FFT of %lu*%lu elements.\n",
		(unsigned long) R, (unsigned long) C);

	// Allocate memory for the arrays.
	float *Signal = malloc(N * Stride * sizeof Signal);
	float *ObservedMemory = malloc(N * sizeof *ObservedMemory);

	if (ObservedMemory == NULL || Signal == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	// Assign half of ObservedMemory to reals and half to imaginaries.
	DSPSplitComplex Observed = { ObservedMemory, ObservedMemory + N/2 };

	/*	Generate an input signal.  In a real application, data would of
		course be provided from an image file, sensors, or other
		source.

		We inject two cosine waves, each with a frequency in the row
		dimension, a frequency in the column dimension, and a phase.
	*/
	const float
		Frequency0R =  9,   Frequency1R =  6,
		Frequency0C = 13,   Frequency1C = 11,
		Phase0      =  0,   Phase1      =   .25;
	for (r = 0; r < R; ++r)
		for (c = 0; c < C; ++c)
			Signal[(r*C + c) * Stride] =
  cos((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ cos((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);

	/*	Reinterpret the real signal as an interleaved-data complex
		vector and use vDSP_ctoz to move the data to a separated-data
		complex vector.

		Note that we pass vDSP_ctoz two times Signal's normal stride,
		because ctoz skips through a complex vector from real to real,
		skipping imaginary elements.  Considering this as a stride of
		two real-sized elements rather than one complex element is a
		legacy use.

		Also, we assume here the rows of Signal are contiguous, that
		there is no additional stride between rows.  When this is the
		case, we can use a single call to vDSP_ctoz to copy the whole
		array.  If it were not the case, we would need to use a
		separate vDSP_ctoz call for each row.

		In the destination array, a stride of one is used regardless of
		the source stride.  Since the destination is a buffer allocated
		just for this purpose, there is no point in replicating the
		source stride.
	*/
	vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Observed, 1, N/2);

		/*	Here and elsewhere we treat Signal and Observed as a
			one-dimensional array, even though they contain a
			two-dimensional signal.  That is fine because they are
			laid out in memory as consecutive elements, so they are
			one-dimensional arrays for purposes of copying data,
			which do not care about the interpretation of the
			data.  When we want to act on the two-dimensional
			signal, we do the necessary subscript arithmetic to
			convert indices in the two-dimensional signal to an
			index in the one-dimensional array.

			It is also possible to cast the one-dimensional array
			(or a pointer to it) to a two-dimensional array (or a
			pointer to it).  The resulting behavior is not defined
			by the C standard.  Many compilers produce code that
			behaves in the obvious way, but it is possible to get
			undesirable behavior, particularly when optimization is
			involved.
		*/

	// Perform a real-to-complex FFT.
	vDSP_fft2d_zrip(Setup, &Observed, 1, 0, Log2C, Log2R, FFT_FORWARD);

		/*	Observe that zero is passed as the row stride.
			Normally the row stride is number of elements from the
			start of one row to the start of the next.  Zero is a
			special value that means to use the number of columns.
			This is the normal case when an array is not embedded
			in a larger array.  If, for example, you were taking
			the DFT of a 16*16 array embedded inside a 1024*1024
			array, you would pass 1024 as the row stride, because
			the rows of the 16*16 array begin 1024 elements apart
			in memory.
		*/

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

	for (r = 0; r < R; ++r)
		for (c = 0; c < C/2; ++c)
			Expected.realp[r*C/2 + c]
				= Expected.imagp[r*C/2 + c] = 0;

	// Add the frequencies in the signal to the expected results.
	r = Frequency0R;
	c = Frequency0C;
	Expected.realp[r*C/2 + c] = N * cos(Phase0 * TwoPi);
	Expected.imagp[r*C/2 + c] = N * sin(Phase0 * TwoPi);

	r = Frequency1R;
	c = Frequency1C;
	Expected.realp[r*C/2 + c] = N * cos(Phase1 * TwoPi);
	Expected.imagp[r*C/2 + c] = N * sin(Phase1 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Observed, N/2);

	// Release memory.
	free(ExpectedMemory);

	/*	The above shows how to use the vDSP_fft2d_zrip routine.  Now we
		will see how fast it is.
	*/

	/*	Zero the signal before timing because repeated FFTs on non-zero
		data can cause abnormalities such as infinities, NaNs, and
		subnormal numbers.
	*/
	for (r = 0; r < R; ++r)
		for (c = 0; c < C; ++c)
			Signal[r*C + c] = 0;
	vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Observed, 1, N/2);

	// Time vDSP_fft2d_zrip by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_fft2d_zrip(Setup, &Observed, 1, 0, Log2C, Log2R,
			FFT_FORWARD);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tvDSP_fft2d_zrip on %lu*%lu elements takes %g microseconds.\n",
		(unsigned long) R, (unsigned long) C, Time * 1e6);

	/*	Time vDSP_fft2d_zrip with the vDSP_ctoz and vDSP_ztoc
		transformations.
	*/

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
	{
		vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Observed, 1, N/2);
		vDSP_fft2d_zrip(Setup, &Observed, 1, 0, Log2C, Log2R,
			FFT_FORWARD);
		vDSP_ztoc(&Observed, 1, (DSPComplex *) Signal, 2*Stride, N/2);
	}

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf(
		"\tvDSP_fft2d_zrip with vDSP_ctoz and vDSP_ztoc takes "
		"%g microseconds.\n",
		Time * 1e6);

	// Release resources.
	free(ObservedMemory);
	free(Signal);
}


/*	Demonstrate the real-to-complex two-dimensional out-of-place FFT,
	vDSP_fft2d_zrop.

	The out-of-place FFT writes results into a different array than the
	input.  If you are using vDSP_ctoz to reformat the input, you do not
	need vDSP_fft2d_zrop because you move the data from an input array to
	an output array when you call vDSP_ctoz.  vDSP_fft2d_zrop may be useful
	when incoming data arrives in the format used by vDSP_fft2d_zrop, and
	you want to simultaneously perform an FFT and store the results in
	another array.
*/
static void DemonstratevDSP_fft2d_zrop(FFTSetup Setup)
{
	/*	Define a stride for the array be passed to the FFT.  In many
		applications, the stride is one and is passed to the vDSP
		routine as a constant.
	*/
	const vDSP_Stride Stride = 1;

	// Define variables for loop iterators.
	vDSP_Length i, r, c;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tTwo-dimensional real FFT of %lu*%lu elements.\n",
		(unsigned long) R, (unsigned long) C);

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
		course be provided from an image file, sensors, or other
		source.

		We inject two cosine waves, each with a frequency in the row
		dimension, a frequency in the column dimension, and a phase.
	*/
	const float
		Frequency0R = 25  , Frequency1R =  8,
		Frequency0C = 17  , Frequency1C = 14,
		Phase0      =  .71, Phase1      =   .46;
	for (r = 0; r < R; ++r)
		for (c = 0; c < C; ++c)
			Signal[(r*C + c) * Stride] =
  cos((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ cos((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);

	/*	Reinterpret the real signal as an interleaved-data complex
		vector and use vDSP_ctoz to move the data to a separated-data
		complex vector.

		Note that we pass vDSP_ctoz two times Signal's normal stride,
		because ctoz skips through a complex vector from real to real,
		skipping imaginary elements.  Considering this as a stride of
		two real-sized elements rather than one complex element is a
		legacy use.

		Also, we assume here the rows of Signal are contiguous, that
		there is no additional stride between rows.  When this is the
		case, we can use a single call to vDSP_ctoz to copy the whole
		array.  If it were not the case, we would need to use a
		separate vDSP_ctoz call for each row.

		In the destination array, a stride of one is used regardless of
		the source stride.  Since the destination is a buffer allocated
		just for this purpose, there is no point in replicating the
		source stride.
	*/
	vDSP_ctoz((DSPComplex *) Signal, 2*Stride, &Buffer, 1, N/2);

		/*	Here and elsewhere we treat Signal and Observed as a
			one-dimensional array, even though they contain a
			two-dimensional signal.  That is fine because they are
			laid out in memory as consecutive elements, so they are
			one-dimensional arrays for purposes of copying data,
			which do not care about the interpretation of the
			data.  When we want to act on the two-dimensional
			signal, we do the necessary subscript arithmetic to
			convert indices in the two-dimensional signal to an
			index in the one-dimensional array.

			It is also possible to cast the one-dimensional array
			(or a pointer to it) to a two-dimensional array (or a
			pointer to it).  The resulting behavior is not defined
			by the C standard.  Many compilers produce code that
			behaves in the obvious way, but it is possible to get
			undesirable behavior, particularly when optimization is
			involved.
		*/

	// Perform a real-to-complex FFT.
	vDSP_fft2d_zrop(Setup, &Buffer, 1, 0, &Observed, 1, 0,
		Log2C, Log2R, FFT_FORWARD);

		/*	Observe that zero is passed as the row stride.
			Normally the row
			stride is number of elements from the start of one row
			to the start of the next.  Zero is a special value that
			means to use the number of columns.  This is the normal
			case when an array is not embedded in a larger array.
			If, for example, you were taking the DFT of a 16*16
			array embedded inside a 1024*1024 array, you would pass
			1024 as the row stride, because the rows of the 16*16
			array begin 1024 elements apart in memory.
		*/

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

	for (r = 0; r < R; ++r)
		for (c = 0; c < C/2; ++c)
			Expected.realp[r*C/2 + c]
				= Expected.imagp[r*C/2 + c] = 0;

	// Add the frequencies in the signal to the expected results.
	r = Frequency0R;
	c = Frequency0C;
	Expected.realp[r*C/2 + c] = N * cos(Phase0 * TwoPi);
	Expected.imagp[r*C/2 + c] = N * sin(Phase0 * TwoPi);

	r = Frequency1R;
	c = Frequency1C;
	Expected.realp[r*C/2 + c] = N * cos(Phase1 * TwoPi);
	Expected.imagp[r*C/2 + c] = N * sin(Phase1 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Observed, N/2);

	// Release memory.
	free(ExpectedMemory);

	/*	The above shows how to use the vDSP_fft2d_zrop routine.  Now we
		will see how fast it is.
	*/

	// Time vDSP_fft2d_zrop by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_fft2d_zrop(Setup, &Buffer, 1, 0, &Observed, 1, 0,
			Log2C, Log2R, FFT_FORWARD);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tvDSP_fft2d_zrop on %lu*%lu elements takes %g microseconds.\n",
		(unsigned long) R, (unsigned long) C, Time * 1e6);

	/*	Unlike the vDSP_fft2d_zrip example, we do not time
		vDSP_fft2d_zrop in conjunction with vDSP_ctoz and vDSP_ztoc.
		If your data arrangement requires you to use vDSP_ctoz, then
		you are already making a copy of the input data.  So you would
		just do the FFT in-place in that copy; you would call
		vDSP_fft2d_zrip and not vDSP_fft2d_zrop.
	*/

	// Release resources.
	free(ObservedMemory);
	free(BufferMemory);
	free(Signal);
}


/*	Demonstrate the complex two-dimensional in-place FFT, vDSP_fft2d_zip.

	The in-place FFT writes results into the same array that contains the
	input data.  This may be faster than an out-of-place routine because it
	uses less memory (so there is less data to load from memory and a
	greater chance of keeping data in cache).
*/
static void DemonstratevDSP_fft2d_zip(FFTSetup Setup)
{
	/*	Define a stride for the array be passed to the FFT.  In many
		applications, the stride is one and is passed to the vDSP
		routine as a constant.
	*/
	const vDSP_Stride SignalStride = 1;

	// Define variables for loop iterators.
	vDSP_Length i, r, c;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tTwo-dimensional complex FFT of %lu*%lu elements.\n",
		(unsigned long) R, (unsigned long) C);

	// Allocate memory for the arrays.
	DSPSplitComplex Signal;
	Signal.realp = malloc(N * SignalStride * sizeof Signal.realp);
	Signal.imagp = malloc(N * SignalStride * sizeof Signal.imagp);

	if (Signal.realp == NULL || Signal.imagp == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	/*	Generate an input signal.  In a real application, data would of
		course be provided from an image file, sensors, or other
		source.

		We inject two cosine waves, each with a frequency in the row
		dimension, a frequency in the column dimension, and a phase.
	*/
	const float
		Frequency0R = 18  , Frequency1R =  3,
		Frequency0C = 22  , Frequency1C = 17,
		Phase0      =  .14, Phase1      =   .67;
	for (r = 0; r < R; ++r)
		for (c = 0; c < C; ++c)
		{
			Signal.realp[(r*C + c) * SignalStride] =
  cos((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ cos((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);
			Signal.imagp[(r*C + c) * SignalStride] =
  sin((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ sin((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);
		}

	// Perform an FFT.
	vDSP_fft2d_zip(Setup, &Signal, SignalStride, 0, Log2C, Log2R,
		FFT_FORWARD);

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

	for (i = 0; i < N; ++i)
		Expected.realp[i] = Expected.imagp[i] = 0;

	// Add the frequencies in the signal to the expected results.
	r = Frequency0R;
	c = Frequency0C;
	Expected.realp[r*C + c] = N * cos(Phase0 * TwoPi);
	Expected.imagp[r*C + c] = N * sin(Phase0 * TwoPi);

	r = Frequency1R;
	c = Frequency1C;
	Expected.realp[r*C + c] = N * cos(Phase1 * TwoPi);
	Expected.imagp[r*C + c] = N * sin(Phase1 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Signal, N);

	// Release memory.
	free(Expected.realp);
	free(Expected.imagp);

	/*	The above shows how to use the vDSP_fft2d_zip routine.  Now we
		will see how fast it is.
	*/

	/*	Zero the signal before timing because repeated FFTs on non-zero
		data can cause abnormalities such as infinities, NaNs, and
		subnormal numbers.
	*/
	for (i = 0; i < N; ++i)
		Signal.realp[i] = Signal.imagp[i] = 0;

	// Time vDSP_fft2d_zip by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_fft2d_zip(Setup, &Signal, SignalStride, 0,
			Log2C, Log2R, FFT_FORWARD);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tvDSP_fft2d_zip on %lu*%lu elements takes %g microseconds.\n",
		(unsigned long) R, (unsigned long) C, Time * 1e6);

	// Release resources.
	free(Signal.realp);
	free(Signal.imagp);
}


/*	Demonstrate the complex two-dimensional out-of-place FFT,
	vDSP_fft2d_zop.

	The out-of-place FFT writes results into a different array than the
	input.
*/
static void DemonstratevDSP_fft2d_zop(FFTSetup Setup)
{
	/*	Define strides for the arrays be passed to the FFT.  In many
		applications, the strides are one and are passed to the vDSP
		routine as constants.
	*/
	const vDSP_Stride SignalStride = 1, ObservedStride = 1;

	// Define variables for loop iterators.
	vDSP_Length i, r, c;

	// Define some variables used to time the routine.
	ClockData t0, t1;
	double Time;

	printf("\n\tTwo-dimensional complex FFT of %lu*%lu elements.\n",
		(unsigned long) R, (unsigned long) C);

	// Allocate memory for the arrays.
	DSPSplitComplex Signal, Observed;
	Signal.realp = malloc(N * SignalStride * sizeof Signal.realp);
	Signal.imagp = malloc(N * SignalStride * sizeof Signal.imagp);
	Observed.realp = malloc(N * ObservedStride * sizeof Observed.realp);
	Observed.imagp = malloc(N * ObservedStride * sizeof Observed.imagp);

	if (Signal.realp == NULL || Signal.imagp == NULL
		|| Observed.realp == NULL || Observed.imagp == NULL)
	{
		fprintf(stderr, "Error, failed to allocate memory.\n");
		exit(EXIT_FAILURE);
	}

	/*	Generate an input signal.  In a real application, data would of
		course be provided from an image file, sensors, or other
		source.

		We inject two cosine waves, each with a frequency in the row
		dimension, a frequency in the column dimension, and a phase.
	 */
	const float
		Frequency0R = 25  , Frequency1R =  6,
		Frequency0C = 15  , Frequency1C = 18,
		Phase0      =  .45, Phase1      =   .37;
	for (r = 0; r < R; ++r)
		for (c = 0; c < C; ++c)
		{
			Signal.realp[(r*C + c) * SignalStride] =
  cos((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ cos((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);
			Signal.imagp[(r*C + c) * SignalStride] =
  sin((r*Frequency0R/R + c*Frequency0C/C + Phase0) * TwoPi)
+ sin((r*Frequency1R/R + c*Frequency1C/C + Phase1) * TwoPi);
		}

	// Perform an FFT.
	vDSP_fft2d_zop(Setup, &Signal, SignalStride, 0,
		&Observed, ObservedStride, 0, Log2C, Log2R, FFT_FORWARD);

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

	for (i = 0; i < N; ++i)
		Expected.realp[i] = Expected.imagp[i] = 0;

	// Add the frequencies in the signal to the expected results.
	r = Frequency0R;
	c = Frequency0C;
	Expected.realp[r*C + c] = N * cos(Phase0 * TwoPi);
	Expected.imagp[r*C + c] = N * sin(Phase0 * TwoPi);

	r = Frequency1R;
	c = Frequency1C;
	Expected.realp[r*C + c] = N * cos(Phase1 * TwoPi);
	Expected.imagp[r*C + c] = N * sin(Phase1 * TwoPi);

	// Compare the observed results to the expected results.
	CompareComplexVectors(Expected, Observed, N);

	// Release memory.
	free(Expected.realp);
	free(Expected.imagp);

	/*	The above shows how to use the vDSP_fft2d_zop routine.  Now we
		will see how fast it is.
	*/

	// Time vDSP_fft2d_zop by itself.

	t0 = Clock();

	for (i = 0; i < Iterations; ++i)
		vDSP_fft2d_zop(Setup, &Signal, SignalStride, 0,
			&Observed, ObservedStride, 0, Log2C, Log2R,
			FFT_FORWARD);

	t1 = Clock();

	// Average the time over all the loop iterations.
	Time = ClockToSeconds(t1, t0) / Iterations;

	printf("\tvDSP_fft2d_zop on %lu*%lu elements takes %g microseconds.\n",
		(unsigned long) R, (unsigned long) C, Time * 1e6);

	// Release resources.
	free(Signal.realp);
	free(Signal.imagp);
	free(Observed.realp);
	free(Observed.imagp);
}


// Demonstrate vDSP FFT functions.
void DemonstrateFFT2D(void)
{
	printf("Begin %s.\n", __func__);

	/*	Initialize data for the FFT routines.  Note that the longest
		length we will use, in either dimension, is passed to the
		setup.
	*/
	FFTSetup Setup = vDSP_create_fftsetup(max(Log2R, Log2C), FFT_RADIX2);
	if (Setup == NULL)
	{
		fprintf(stderr, "Error, vDSP_create_fftsetup failed.\n");
		exit (EXIT_FAILURE);
	}

	DemonstratevDSP_fft2d_zrip(Setup);
	DemonstratevDSP_fft2d_zrop(Setup);
	DemonstratevDSP_fft2d_zip(Setup);
	DemonstratevDSP_fft2d_zop(Setup);

	vDSP_destroy_fftsetup(Setup);

	printf("\nEnd %s.\n\n\n", __func__);
}
