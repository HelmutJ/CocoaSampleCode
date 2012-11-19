/*
	    File: Demonstrate.h
	Abstract: Common declarations for vDSP examples.
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
	

	File: Demonstrate.h
	
	Description:
		Common declarations for the vDSP examples.

	Copyright:
		Copyright (C) 2007 Apple Inc.  All rights reserved.
*/
#ifndef __MAIN__
#define __MAIN__


#ifdef __cplusplus
	extern "C" {
		/*	This tells a C++ compiler that the following routines
			are defined in C and so must be called using C linkage,
			not C++ linkage.  We do not need this in this code
			since all of our routines are in C, but it illustrates
			good practice for header files that may be included
			from C or C++ programs.
		*/
#endif


// These are routines that illustrate calls to a few vDSP routines.
void DemonstrateConvolution(void);
void DemonstrateDFT(void);
void DemonstrateFFT(void);
void DemonstrateFFT2D(void);


/*	The Clock routine reports the current time, but the format it uses
	should not be manipulated by the user.  The routine ClockToSeconds
	takes two times reported by Clock and returns their difference in
	seconds.  (It also subtracts the average latency of the Clock routine
	from the difference.)
*/
#include <mach/mach_time.h>	// Declare mach_absolute_time.
typedef uint64_t ClockData;	// Define type for clock data.
ClockData Clock(void);		// Declare clock routine.
double ClockToSeconds(ClockData t1, ClockData t0);
				// Return number of seconds between two times.


#ifdef __cplusplus
	}
#endif


#endif
