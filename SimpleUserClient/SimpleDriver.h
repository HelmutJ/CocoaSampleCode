/*
	File:			SimpleDriver.h
	
	Description:	This file shows how to implement a basic I/O Kit driver kernel extension (KEXT).

	Copyright:		Copyright © 2001-2008 Apple Inc. All rights reserved.
	
	Disclaimer:		IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
					("Apple") in consideration of your agreement to the following terms, and your
					use, installation, modification or redistribution of this Apple software
					constitutes acceptance of these terms.  If you do not agree with these terms,
					please do not use, install, modify or redistribute this Apple software.
					
					In consideration of your agreement to abide by the following terms, and subject
					to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
					copyrights in this original Apple software (the "Apple Software"), to use,
					reproduce, modify and redistribute the Apple Software, with or without
					modifications, in source and/or binary forms; provided that if you redistribute
					the Apple Software in its entirety and without modifications, you must retain
					this notice and the following text and disclaimers in all such redistributions of
					the Apple Software.  Neither the name, trademarks, service marks or logos of
					Apple Computer, Inc. may be used to endorse or promote products derived from the
					Apple Software without specific prior written permission from Apple.  Except as
					expressly stated in this notice, no other rights or licenses, express or implied,
					are granted by Apple herein, including but not limited to any patent rights that
					may be infringed by your derivative works or by other works in which the Apple
					Software may be incorporated.
					
					The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
					WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
					WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
					PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
					COMBINATION WITH YOUR PRODUCTS.
					
					IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
					CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
					GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
					ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
					OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
					(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
					ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):
	
            2.0			08/13/2008			Add Leopard user client API for supporting 64-bit user processes.
											Now requires Xcode 3.0 or later to build.
			
            1.1			05/22/2007			User client performs endian swapping when called from a user process 
											running using Rosetta. Updated to produce a universal binary.
											Now requires Xcode 2.2.1 or later to build.
			
			1.0d3	 	01/14/2003			New sample.

*/

// Set up a minimal set of availability macros.
//
// These macros are useful for conditionally compiling code targeting specific versions
// of Mac OS X. But the standard availability macros aren't available to kernel code
// prior to Mac OS X 10.5. Code targeting 10.5 and later should use AvailabilityMacros.h
// instead of this file. Code targeting 10.6 and later should use Availability.h

#ifndef MAC_OS_X_VERSION_MIN_REQUIRED

#ifndef MAC_OS_X_VERSION_10_4
#define MAC_OS_X_VERSION_10_4 1040
#endif

#ifdef __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
#define MAC_OS_X_VERSION_MIN_REQUIRED __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
#else
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_4
#endif

#endif

#include <IOKit/IOService.h>
#include "UserKernelShared.h"

struct MySampleStruct;

class SimpleDriverClassName : public IOService
{
	// Declare the metaclass information that is used for runtime type checking of I/O Kit objects.
	// Note that the class name is different when targeting Mac OS X 10.4 because support for that
	// version has to be built as a separate kext. This is because the KPIs for 64-bit user processes
	// to access user clients only exist on Mac OS X 10.5 and later.
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	OSDeclareDefaultStructors(com_apple_dts_driver_SimpleDriver_10_4)
#else
	OSDeclareDefaultStructors(com_apple_dts_driver_SimpleDriver)
#endif
	
public:
	// IOService methods
	virtual bool init(OSDictionary* dictionary = 0);
	virtual void free(void);
	
	virtual IOService* probe(IOService* provider, SInt32* score);
	
	virtual bool start(IOService* provider);
	virtual void stop(IOService* provider);
	
	virtual bool willTerminate(IOService* provider, IOOptionBits options);
	virtual bool didTerminate(IOService* provider, IOOptionBits options, bool* defer);
	
    virtual bool terminate(IOOptionBits options = 0);
    virtual bool finalize(IOOptionBits options);

	// SimpleDriver methods
	virtual IOReturn ScalarIStructI(uint32_t inNumber, MySampleStruct* inStruct, uint32_t inStructSize);
	virtual IOReturn ScalarIStructO(uint32_t inNumber1, uint32_t inNumber2, MySampleStruct* outStruct, uint32_t* outStructSize);
	virtual IOReturn ScalarIScalarO(uint32_t inNumber1, uint32_t inNumber2, uint32_t* outNumber);
	virtual IOReturn StructIStructO(MySampleStruct* inStruct, MySampleStruct* outStruct, uint32_t inStructSize, uint32_t* outStructSize);
};