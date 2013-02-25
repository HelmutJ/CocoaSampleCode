//
// File:       AppleSamplePCIUserClient.h
//
// Abstract:   User client interface between userland and sample kernel PCI driver
//
// Version:    2.0
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
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//

#include <IOKit/IOUserClient.h>
#include "AppleSamplePCI.h"

#if	MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#define SamplePCIUserClientClassName com_YourCompany_driver_SamplePCIUserClient_10_4
#else
#define SamplePCIUserClientClassName com_YourCompany_driver_SamplePCIUserClient
#endif

// Forward declarations
class IOBufferMemoryDescriptor;

class SamplePCIUserClientClassName : public IOUserClient
{
	/*
	 * Declare the metaclass information that is used for runtime
	 * typechecking of IOKit objects. Note that the class name is different when supporting PowerPC on 10.4.
	 */
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	OSDeclareDefaultStructors( com_YourCompany_driver_SamplePCIUserClient_10_4 );
#else
	OSDeclareDefaultStructors( com_YourCompany_driver_SamplePCIUserClient );
#endif
	
private:
	SamplePCIClassName*			fDriver;
	IOBufferMemoryDescriptor*	fClientSharedMemory;
	SampleSharedMemory*			fClientShared;
	task_t						fTask;
	int32_t						fOpenCount;
	bool						fCrossEndian;
	
public:
	/* IOService overrides */
	virtual bool start(IOService* provider);
	virtual void stop(IOService* provider);
	
	/* IOUserClient overrides */
	virtual bool initWithTask(task_t owningTask, void* securityID,
							  UInt32 type,  OSDictionary* properties);
	
	virtual IOReturn clientClose(void);
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	/* Old user client API - only supports access from 32-bit user processes. */
	virtual IOExternalMethod* getTargetAndMethodForIndex(IOService** targetP, UInt32 index);
#else	
	/* New user client API for supporting access from both 32-bit and 64-bit user processes. */
	virtual IOReturn externalMethod(uint32_t selector, IOExternalMethodArguments* arguments,
									IOExternalMethodDispatch* dispatch, OSObject* target, void* reference);
#endif
	
	virtual IOReturn clientMemoryForType(UInt32 type,
										 IOOptionBits* options,
										 IOMemoryDescriptor** memory);
	
	/* External methods */
	virtual IOReturn method1(UInt32* dataIn, UInt32* dataOut,
							 IOByteCount inputCount, IOByteCount* outputCount);
	
	virtual IOReturn method2(SampleStructForMethod2* structIn, 
							 SampleResultsForMethod2* structOut,
							 IOByteCount inputSize, IOByteCount* outputSize);
	
};

