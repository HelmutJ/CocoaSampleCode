/*

File:SCSIEmulatorAdapterNub.h

Abstract: Header for the IOKit nub used to match our SCSI HBA emulator
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

// IOSCSIParallelInterfaceController, for whatever reasons, demands that we have a primary interrupt
// in our provider chain.  This is a simple class to provide that support but in software instead


#ifndef _SCSIEMULATORADAPTER_NUB_H
#define _SCSIEMULATORADAPTER_NUB_H

#include <IOKit/IOService.h>
#include <IOKit/scsi/SCSITask.h>

class com_apple_dts_SCSIEmulator;
class com_apple_dts_SCSIEmulatorAdapter;

class com_apple_dts_SCSIEmulatorAdapterNub : public IOService {

OSDeclareDefaultStructors(com_apple_dts_SCSIEmulatorAdapterNub)

public:
    virtual bool				init(com_apple_dts_SCSIEmulator *adapter = 0, OSDictionary *dict = 0);
	virtual void				free(void);

    virtual bool				start(IOService *provider);
    virtual void				stop(IOService *provider);

    virtual IOReturn			message(UInt32 type, IOService * provider,
										void * argument = 0);

    virtual bool				willTerminate(IOService *provider, IOOptionBits options);
    virtual bool				didTerminate(IOService *provider, IOOptionBits options, bool *defer);

#if 1 // Work-around for bug in IOSCSIParallelFamily.  Radar:4914537
	virtual IOReturn			getInterruptType(int source, int *interruptType);
    virtual IOReturn			registerInterrupt(int source, OSObject *target,
										IOInterruptAction handler,
										void *refCon = 0);
    virtual IOReturn			unregisterInterrupt(int source);
#endif

	com_apple_dts_SCSIEmulator *getEmulator(com_apple_dts_SCSIEmulatorAdapter *adapter, SCSITargetIdentifier targetID);

private:
	com_apple_dts_SCSIEmulator *mEmulator;
};

#endif