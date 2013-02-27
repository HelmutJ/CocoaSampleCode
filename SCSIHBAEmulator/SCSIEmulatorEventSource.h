/*

File:SCSIEmulatorEventSource.h

Abstract: Header for an IOEventSource subclass used to respond to SCSI tasks
		on the IOSCSIParallelInterfaceController workloop

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

#ifndef _SCSIEMULATOREVENTSOURCE_H
#define _SCSIEMULATOREVENTSOURCE_H

#include <kern/queue.h>
#include <IOKit/IOEventSource.h>
#include <IOKit/scsi/spi/IOSCSIParallelInterfaceController.h>

class com_apple_dts_SCSIEmulatorAdapter;

typedef struct {
	queue_chain_t				fQueueChain;

	SCSIParallelTaskIdentifier	fTask;
	SCSITaskStatus				fTaskStatus;
	SCSIServiceResponse			fServiceResponse;
} SCSIEmulatorRequestBlock;

class com_apple_dts_SCSIEmulatorEventSource : public IOEventSource {

OSDeclareDefaultStructors(com_apple_dts_SCSIEmulatorEventSource)

public:
	typedef void (*Action) (com_apple_dts_SCSIEmulatorAdapter *owner, SCSIEmulatorRequestBlock srb);

    virtual bool							init(com_apple_dts_SCSIEmulatorAdapter *ourAdapter, com_apple_dts_SCSIEmulatorEventSource::Action action = 0);
    virtual void							free(void);
	
	virtual bool							addItemToQueue(SCSIEmulatorRequestBlock* elem);

protected:
	/*! @function checkForWork
		@abstract Pure Virtual member function used by IOWorkLoop for work scheduling.
		@discussion This function will be called to request a subclass to check it's internal state for any work to do and then to call out the owner/action.
		@result Return true if this function needs to be called again before all its outstanding events have been processed.
	*/
    virtual bool checkForWork();
	
private:
	queue_head_t mResponderQueue;

};

#endif
