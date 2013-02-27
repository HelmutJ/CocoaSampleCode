/*

File:SCSIEmulatorIOKitDriver.cpp

Abstract: Implementation of an IOKit wrapper used to match and load
		instances of the SCSI HBA emulator

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

#include <IOKit/IOMessage.h>
#include <IOKit/IOLib.h>
#include <IOKit/pci/IOPCIDevice.h>
#include <IOKit/IOBufferMemoryDescriptor.h>

#include "SCSIEmulatorIOKitDriver.h"
#include "SCSIEmulator.h"
#include "SCSIEmulatorAdapterNub.h"

// Define superclass
#define super IOService

// REQUIRED! This macro defines the class's constructors, destructors,
// and several other methods I/O Kit requires. Do NOT use super as the
// second parameter. You must use the literal name of the superclass.
OSDefineMetaClassAndStructors(com_apple_dts_SCSIEmulatorIOKitDriver, IOService)


// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorIOKitDriver::init(OSDictionary *dict)
{
	bool res = super::init(dict);
	return res;
}


// Only present to provide a debug checkpoint
void com_apple_dts_SCSIEmulatorIOKitDriver::free(void)
{
	super::free();
}


// Only present to provide a debug checkpoint
IOService *com_apple_dts_SCSIEmulatorIOKitDriver::probe(IOService *provider, SInt32 *score)
{
	IOService *res = super::probe(provider, score);
	return res;
}


bool com_apple_dts_SCSIEmulatorIOKitDriver::start(IOService *provider)
{
	bool res = super::start(provider);

	if (res) {
		// OK... we could add a userClient to this to allow for configuration, but
		// this will suffice for now.  By default, this creates a single 20MB RAM disk
		mDisk = OSTypeAlloc(com_apple_dts_SCSIEmulator);
		if (mDisk) {
			if (mDisk->init()) {
				createNewAdapter(mDisk);
			} else {
				mDisk->release();
				mDisk = NULL;
			}
		}
	}

	return res;
}


// Only present to provide a debug checkpoint
void com_apple_dts_SCSIEmulatorIOKitDriver::stop(IOService *provider)
{		
	if (mDisk) {
		mDisk->release();
		mDisk = NULL;
	}

	super::stop(provider);
}


// Only present to provide a debug checkpoint
IOReturn
com_apple_dts_SCSIEmulatorIOKitDriver::message( UInt32 type, IOService *provider, void *argument )
{
	IOReturn ret;

	ret = super::message(type, provider, argument);
	return ret;
}


// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorIOKitDriver::willTerminate(IOService *provider, IOOptionBits options)
{
    return super::willTerminate(provider, options);
}


// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorIOKitDriver::didTerminate(IOService *provider, IOOptionBits options, bool *defer)
{
    return super::didTerminate(provider, options, defer);
}


com_apple_dts_SCSIEmulatorAdapterNub *
com_apple_dts_SCSIEmulatorIOKitDriver::createNewAdapter(com_apple_dts_SCSIEmulator *adapter)
{
	com_apple_dts_SCSIEmulatorAdapterNub *newService = OSTypeAlloc(com_apple_dts_SCSIEmulatorAdapterNub);
	bool startedOK = false;
	if (newService) {
		do {
			if (!newService->init(adapter)) {
				IOLog("createNewAdapter: Failed to init adapter nub\n");
				break;
			}
				
			if (!newService->attach(this)) {
				IOLog("createNewAdapter: Failed to attach adapter nub\n");
				break;
			}
				
			this->checkResources();
			newService->checkResources();

			if (!newService->start(this)) {
				IOLog("createNewAdapter: Failed start call to adapter nub\n");
				newService->detach(this);
			} else {
				startedOK = true;
			}
		} while (false);

		newService->release();
	}
	
	if (!startedOK) {
		newService = NULL;
	}
	
	return newService;
}
