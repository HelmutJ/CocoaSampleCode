//
// File:		AppleSamplePCIAvailability.h
//
// Abstract:	Subset of AvailabilityMacros.h for pre-10.5 kernel builds.
//
//				The availability macros are useful for conditionally compiling code targeting
//				specific versions of Mac OS X. But these macros aren't available to kernel code
//				prior to Mac OS X 10.5. Code targeting 10.5 and later should use AvailabilityMacros.h
//				instead of this file. Code targeting 10.6 and later should use Availability.h
//				instead of this file.
//
// Version:		1.0
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//


/*
 * Set up standard Mac OS X versions
 */
#define MAC_OS_X_VERSION_10_0 1000
#define MAC_OS_X_VERSION_10_1 1010
#define MAC_OS_X_VERSION_10_2 1020
#define MAC_OS_X_VERSION_10_3 1030
#define MAC_OS_X_VERSION_10_4 1040
#define MAC_OS_X_VERSION_10_5 1050
#define MAC_OS_X_VERSION_10_6 1060


/* 
 * If min OS not specified, assume 10.1 for ppc and 10.4 for all others
 * Note: gcc driver may set _ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED_ based on MACOSX_DEPLOYMENT_TARGET environment variable
 */
#ifndef MAC_OS_X_VERSION_MIN_REQUIRED
#ifdef __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
#if (__i386__ || __x86_64__) && (__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < MAC_OS_X_VERSION_10_4)
#warning Building for Intel with Mac OS X Deployment Target < 10.4 is invalid.
#elif __ppc64__ && (__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < MAC_OS_X_VERSION_10_4)
#warning Building for ppc64 with Mac OS X Deployment Target < 10.4 is invalid.
#endif
#define MAC_OS_X_VERSION_MIN_REQUIRED __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
#else
#if __ppc64__ || __i386__ || __x86_64__
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_4
#else
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_1
#endif
#endif
#endif

/*
 * Error on bad values
 */
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_0
#error MAC_OS_X_VERSION_MIN_REQUIRED must be >= MAC_OS_X_VERSION_10_0
#endif
