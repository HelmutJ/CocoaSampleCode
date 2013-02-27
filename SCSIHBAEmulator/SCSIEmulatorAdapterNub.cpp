/*

File:SCSIEmulatorAdapterNub.cpp

Abstract: Implementation of the IOKit nub used to match our SCSI HBA emulator
		against and to provide the necessary patch to support a virtual HBA

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#include <IOKit/IOLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IODeviceTreeSupport.h>

#include "SCSIEmulatorAdapterNub.h"

// Define my superclass
#define super IOService

// REQUIRED! This macro defines the class's constructors, destructors,
// and several other methods I/O Kit requires. Do NOT use super as the
// second parameter. You must use the literal name of the superclass.
OSDefineMetaClassAndStructors(com_apple_dts_SCSIEmulatorAdapterNub, IOService)


bool
com_apple_dts_SCSIEmulatorAdapterNub::init(com_apple_dts_SCSIEmulator *adapter, OSDictionary *dict)
{
	bool res = super::init(dict);

	mEmulator = adapter;

	return res;
}

// Only present to provide a debug checkpoint
void
com_apple_dts_SCSIEmulatorAdapterNub::free(void)
{
	super::free();
}

bool
com_apple_dts_SCSIEmulatorAdapterNub::start( IOService *provider )
{
	bool res = super::start(provider);
			
	if (res) {
		registerService(kIOServiceSynchronous);
	}

	return res;
}

// Only present to provide a debug checkpoint
void
com_apple_dts_SCSIEmulatorAdapterNub::stop( IOService *provider )
{
	super::stop(provider);
}

// Only present to provide a debug checkpoint
IOReturn
com_apple_dts_SCSIEmulatorAdapterNub::message(UInt32 type, IOService *provider, void *argument)
{
	IOReturn ret = super::message(type, provider, argument);
	return ret;
}

// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorAdapterNub::willTerminate(IOService *provider, IOOptionBits options)
{
    return super::willTerminate(provider, options);
}


// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorAdapterNub::didTerminate(IOService *provider, IOOptionBits options, bool *defer)
{
    return super::didTerminate(provider, options, defer);
}

#if 1 // Work-around for bug in IOSCSIParallelFamily.  Radar:4914537
IOReturn
com_apple_dts_SCSIEmulatorAdapterNub::getInterruptType(int source, int *interruptType)
{
	*interruptType = kIOInterruptTypeEdge;

	return kIOReturnSuccess;
}

IOReturn
com_apple_dts_SCSIEmulatorAdapterNub::registerInterrupt(int source, OSObject *target,
				      IOInterruptAction handler,
				      void *refCon)
{
	return kIOReturnSuccess;
}

IOReturn
com_apple_dts_SCSIEmulatorAdapterNub::unregisterInterrupt(int source)
{
	return kIOReturnSuccess;
}
#endif

com_apple_dts_SCSIEmulator *
com_apple_dts_SCSIEmulatorAdapterNub::getEmulator(com_apple_dts_SCSIEmulatorAdapter *adapter, SCSITargetIdentifier targetID)
{
	// Although this example only creates one target and one adapter, you could modify it to create multiple adapters
	// with multiple targets

	if (targetID == 0) {
		return mEmulator;
	} else {
		return NULL;
	}
}
