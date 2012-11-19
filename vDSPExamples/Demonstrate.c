/*
	    File: Demonstrate.c
	Abstract: vDSP AltiVec examples.
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
	

	File: Demonstrate.c
	
	Description:
		Main routine and some subroutines for the vDSP AltiVec examples.
	
	Copyright:
		Copyright (C) 2007 Apple Inc.  All rights reserved.
*/


#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/param.h>
#include <sys/sysctl.h>

#include <Accelerate/Accelerate.h>

#include "Demonstrate.h"


/*	Here we define some minor subroutines.  If this were a larger
	application, these would likely be defined in a separate file, rather
	than in Demonstrate.c.
*/


#if defined __ppc__ || defined __ppc64__

	/*	Some PowerPC processors have AltiVec (including those in G4 and
		G5 systems) and some do not (including those in G3 systems).
		If you want to write code that uses AltiVec features to run
		quickly on G4 or G5 systems but still works (more slowly) on G3
		systems, you may need to test for the presence of AltiVec
		features at run time.

		To start, we will define a Boolean value that we will set to
		indicate whether AltiVec is available or not.
	*/
	static _Bool HasVector;

	/*	This routine initializes the HasVector object above by asking
		the operating system whether AltiVec features are present.
	*/
	static void InitializeHasVector(void)
	{
		unsigned int HasAltiVec;
		size_t SizeOfHasAltiVec = sizeof HasAltiVec;

		// Ask sysctlbyname for the value of "hw.optional.altivec".
		if (0 != sysctlbyname("hw.optional.altivec",
			&HasAltiVec, &SizeOfHasAltiVec, NULL, 0))
		{
			/*	sysctlbyname failed.  That should not happen on
				a PowerPC, although of course an Intel system
				will report there is no value for
				"hw.optional.altivec".
			*/
			fprintf(stderr,
"Error, sysctlbyname(\"hw.optional.altivec\") failed with\n"
"errno %d:  %s.\n",
				errno, strerror(errno));
			exit(EXIT_FAILURE);
		}

		HasVector = HasAltiVec;

		/*	Now code can tell whether AltiVec is available by
			checking the value of HasVector.
		*/
	}

#else	// defined __ppc__ || defined __ppc64__

	// If we are not on a PowerPC, define InitializeHasVector to do nothing.
	#define InitializeHasVector()

	/*	Since this is not being compiled for a PowerPC, we will assume
		it is being compiled for an Intel system that has vector
		features, since all Apple systems have SSE2 at least.  (If you
		are writing code for other systems, you may need additional
		tests here.)
	*/
	#define HasVector	1

#endif	// defined __ppc__ || defined __ppc64__


/*	This next section defines some things to change the floating-point
	math environment.  Both AltiVec and Intel (IA-32 and EM64T) processors
	execute floating-point operations more quickly when they can treat
	subnormal numbers as zero, so we want to enable that mode.

	In summary:

		PowerPC and Intel processors can be set to handle subnormal
		floating-point numbers (essentially those with tiny exponents,
		very near zero) as specified by the IEEE 754 floating-point
		standard or to convert such numbers to zero when they are used
		or produced in floating-point arithmetic instructions.  Let us
		call the former mode "conformant" and the latter mode "fast".

		On some PowerPC processors, in conformant mode, all vector
		floating-point arithmetic instructions take an extra CPU cycle.

		On some Intel processors, in conformant mode, vector
		floating-point arithmetic instructions that encounter a
		subnormal number generate a trap that may take around a
		thousand CPU cycles to handle.

	On Intel processors, code compiled with Apple GCC uses vector
	instructions for all floating-point arithmetic.  Thus, all
	floating-point arithmetic is affected if a subnormal is encountered and
	is affected by the selection of conformant mode or fast mode.

	Because the penalty on PowerPC processors affects all applications
	with vector floating-point instructions, you will want to set fast mode
	unless your application requires proper handling of subnormal numbers.

	Because the penalty on Intel processors only affects applications when
	subnormal numbers are encountered, your application might not suffer
	any penalty, and you could leave the processor in conformant mode (the
	default).  However, if subnormal numbers are encountered, the
	performance penalty can be huge.  It can also be intermittent, causing
	erratic operation that is fast sometimes and slow sometimes.  To avoid
	this, you can set fast mode.

	The following section defines:

		MathEnvironment

			An object type that can record the floating-point
			environment.

		FastMathEnvironment

			An environment in which fast mode is set.

		MathEnvironment SetMathEnvironment(MathEnvironment New)

			A function that sets a new environment and returns the
			old one.

			Note that SetMathEnvironment sets the entire
			environment, not just the mode for which subnormal
			numbers are handled.  Notably, the AltiVec saturation
			bit is changed and the Intel rounding and exception
			bits are changed.

	You can use the symbols above to set the environment without
	additional information about the details.  For those who wish to know
	the details of the modes:

		On PowerPC, the subnormal handling is controlled by the
		non-Java mode bit.  Non-Java mode is the fast mode, and Java
		mode is the conformant mode.  It is unfortunate the mode is
		named in the negative, as a non-Java mode rather than a Java
		mode, but it is that way in the AltiVec specification.

		On Intel, the subnormal handling is controlled by two bits in
		the MXSCR, the FZ (flush-to-zero, subnormal outputs are
		replaced by zero) and DAZ (denormals-are-zeros, subnormal
		inputs are replaced by zero).
*/
#if defined __ppc__ || defined __ppc64__

	typedef vUInt32 MathEnvironment;

	// Define an environment with the non-Java bit set.
	#define FastMathEnvironment	((vUInt32) (1<<16))

	/*	Two implementations of SetMathEnvironment follow.  The first is
		for when the AltiVec language extensions are available.  The
		second is a stub routine for when the extensions are
		unavailable.  (When the extensions are unavailable, it is
		still possible to use GCC assembly language features to access
		the necessary processor register.  However, such code is of
		course not generally portable to other compilers.)

		_AltiVecPIMLanguageExtensionsAreEnabled is a symbol newly in
		Accelerate/Accelerate.h as of Mac OS 10.5.  The intent is for
		it to be defined if and only if the C language extensions
		defined in the AltiVec Programming Interface Manual are
		available in the current compilation.  This is a tricky
		proposition because there is not universal agreement between
		compilers about how to indicate that.  The test used in
		Accelerate to determine that should work on several compilers.
	*/
	#if defined _AltiVecPIMLanguageExtensionsAreEnabled
		MathEnvironment SetMathEnvironment(MathEnvironment New)
		{
			if (HasVector)
			{
				// Get current value of VSCR.
				MathEnvironment Old = vec_mfvscr();

				// Set new value of VSCR.
				vec_mtvscr(New);

				return Old;
			}
			else
				/*	On a machine without AltiVec, you
					cannot set non-Java mode.
				*/
				return (vUInt32) (0);
		}
	#else	// defined _AltiVecPIMLanguageExtensionsAreEnabled
		MathEnvironment SetMathEnvironment(MathEnvironment New)
		{
			return (vUInt32) (0);
		}
	#endif	// defined _AltiVecPIMLanguageExtensionsAreEnabled

#elif defined __i386__ || defined __x86_64__

	#include <fenv.h>
	#if !defined __GNUC__
		/*	This statement should be used when the compiler
			supports it.
		*/
		#pragma STDC FENV_ACCESS ON
	#endif

	typedef fenv_t MathEnvironment;

	// Define FastMathEnvironment to use one provided by Apple via fenv.h.
	#define	FastMathEnvironment	(*FE_DFL_DISABLE_SSE_DENORMS_ENV)

	MathEnvironment SetMathEnvironment(MathEnvironment New)
	{
		MathEnvironment Old;
	
		// Get the old environment.
		if (0 != fegetenv(&Old))
		{
			fprintf(stderr, "Error, fegetenv returned non-zero.\n");
			exit(EXIT_FAILURE);
		}
	
		// Set the new environment.
		if (0 != fesetenv(&New))
		{
			fprintf(stderr, "Error, fesetenv returned non-zero.\n");
			exit(EXIT_FAILURE);
		}

		return Old;
	}

#else

	/*	On an unknown architecture, we have no control over the
		environment.
	*/
	typedef _Bool MathEnvironment;
	static const MathEnvironment FastMathEnvironment = 0;
	MathEnvironment SetMathEnvironment(MathEnvironment New)
	{
		return 0;
	}

#endif


// Define static data for Clock routine.
static mach_timebase_info_data_t MachClockInfo;
ClockData ClockLatency;	// Average latency of clock routine, in clock ticks.


// Return mach clock's time.
ClockData Clock(void)
{
	return mach_absolute_time();
}


/*	Subtract two clock measurements and convert difference to seconds,
	excluding measurement time.
*/
double ClockToSeconds(ClockData t1, ClockData t0)
{
	return (t1 - t0 - ClockLatency) * 1e-9
		* MachClockInfo.numer / MachClockInfo.denom;
}


// Initialize static data for Clock routine.
static void InitializeClock()
{
	static const int Iterations = 1000000;

	int i;

	/*	Get ratio of mach_absolute_time ticks to nanoseconds.  (One
		tick is numer/denom nanoseconds.)
	*/
	mach_timebase_info(&MachClockInfo);

	// Measure latency of Clock routine.
	ClockData t0 = Clock(), t1;
	for (i = 0; i < Iterations; ++i)
		t1 = Clock();

	// Record average latency (rounded down).
	ClockLatency = (t1 - t0) / Iterations;
}


int main(void)
{
	/*	Initialize various things.  These are typically done only once,
		at the start of a program.
	*/
	InitializeClock();
	InitializeHasVector();

	// Set the floating-point math environment for fast execution.
	MathEnvironment OldMathEnvironment
		= SetMathEnvironment(FastMathEnvironment);

	DemonstrateConvolution();
	DemonstrateDFT();
	DemonstrateFFT();
	DemonstrateFFT2D();

	/*	Restore the original math environment.  This is not necessary
		at the end of a program, but this is how you might do it in an
		application that wanted to change the environment various
		times.
	*/
	SetMathEnvironment(OldMathEnvironment);

	return 0;
}
