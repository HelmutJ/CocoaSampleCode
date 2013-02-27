/*

File:SCSIEmulatorAdapter.cpp

Abstract: Implementation of the core a virtual SCSI HBA based off of
		IOSCSIParallelInterfaceController

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
#include <IOKit/IOTypes.h>
#include <IOKit/IOMessage.h>
#include <IOKit/scsi/SCSICommandOperationCodes.h>
#include <IOKit/storage/IOStorageProtocolCharacteristics.h>
#include <IOKit/scsi/spi/IOSCSIParallelInterfaceController.h>

#include "SCSIEmulator.h"
#include "SCSIEmulatorAdapter.h"
#include "SCSIEmulatorAdapterNub.h"
#include "SCSIEmulatorIOKitDriver.h"
#include "SCSIEmulatorEventSource.h"

#ifndef MAX_TARGET_ID
#define kMaxTargetID 256
#else
#define kMaxTargetID MAX_TARGET_ID
#endif

#ifndef MAX_LUNS
#define kMaxLUNs 64
#else
#define kMaxLUNs MAX_LUNS
#endif

#ifndef MAX_TASKS
#define kMaxTasks 32 // Arbitrary number.  This sample code will work with anything >= 1
#else
#define kMaxTasks MAX_TASKS
#endif

#ifndef SENSE_BUFFER_LEN
#define kSenseBufferLen 128
#else
#define kSenseBufferLen SENSE_BUFFER_LEN
#endif

#define INITIATOR_IDENTIFIER 0x87654321


// Define superclass
#define super IOSCSIParallelInterfaceController

// REQUIRED! This macro defines the class's constructors, destructors,
// and several other methods I/O Kit requires. Do NOT use super as the
// second parameter. You must use the literal name of the superclass.
OSDefineMetaClassAndStructors(com_apple_dts_SCSIEmulatorAdapter, IOSCSIParallelInterfaceController)

// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorAdapter::willTerminate(IOService *provider, IOOptionBits options)
{
    return super::willTerminate(provider, options);
}


// Only present to provide a debug checkpoint
bool com_apple_dts_SCSIEmulatorAdapter::didTerminate(IOService *provider, IOOptionBits options, bool *defer)
{
    return super::didTerminate(provider, options, defer);
}

// Only present to provide a debug checkpoint
bool
com_apple_dts_SCSIEmulatorAdapter::terminate( IOOptionBits options)
{
	bool res = super::terminate(options);
	return res;
}


IOReturn
com_apple_dts_SCSIEmulatorAdapter::message(UInt32 type, IOService *provider, void *argument)
{
	
	IOReturn ret;

#if 1 // Work-around for bug in IOSCSIParallelFamily.  Radar:4914658
	switch (type) {
		case kIOMessageServiceIsRequestingClose:
		{
			// As the provider is opened by IOSCSIParallelInterfaceController itself, it should
			// be responsible for closing it, not us.  Currently, this is not the case
			ret = super::message(type, provider, argument);

			if (getProvider()->isOpen(this))
				getProvider()->close(this);
				
			return (getProvider()->isOpen(this) == false) ? ret : kIOReturnError;

			break;
		}

		default:
		{
			break;
		}
	}
#endif

	ret = super::message(type, provider, argument);
	
	return ret;
}

SCSILogicalUnitNumber
com_apple_dts_SCSIEmulatorAdapter::ReportHBAHighestLogicalUnitNumber ( void )
{
	// Report the highest LUN number devices on this HBA are allowed to have.
	// 0 is a valid response for HBAs that only allow a single LUN per device

	SCSILogicalUnitNumber maxLUN = kMaxLUNs - 1; // Report LUNs for our sample
	return maxLUN;
}

bool
com_apple_dts_SCSIEmulatorAdapter::DoesHBASupportSCSIParallelFeature ( SCSIParallelFeature theFeature )
{
	bool ret = false; // return false for any unimplemented or unknown features

	switch (theFeature) {
		case kSCSIParallelFeature_WideDataTransfer:
			ret = true;
			break;
		case kSCSIParallelFeature_SynchronousDataTransfer:
			ret = true;
			break;
		case kSCSIParallelFeature_QuickArbitrationAndSelection:
			ret = true;
			break;
		case kSCSIParallelFeature_DoubleTransitionDataTransfers:
			ret = true;
			break;
		case kSCSIParallelFeature_InformationUnitTransfers:
			ret = true;
			break;
	}

	return ret;
}

bool
com_apple_dts_SCSIEmulatorAdapter::InitializeTargetForID ( SCSITargetIdentifier targetID )
{	
	bool retVal = false;

	com_apple_dts_SCSIEmulatorAdapterNub *nub = OSDynamicCast(com_apple_dts_SCSIEmulatorAdapterNub, getProvider());
	
	if (nub) {
		com_apple_dts_SCSIEmulator *emulator = nub->getEmulator(this, targetID);

		if (emulator) {
			if (mTargetsArray)
				mTargetsArray->setObject(targetID, emulator);

			retVal = true;
		}
	}

	return retVal;
}


SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::AbortTaskRequest ( 	
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL,
							SCSITaggedTaskIdentifier	theQ )
{
	// Returning general failure for AbortTaskRequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}

SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::AbortTaskSetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL )
{
	// Returning general failure for AbortTaskSetRequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}
	
SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::ClearACARequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL )
{
	// Returning general failure for ClearACARequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}
	
SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::ClearTaskSetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL )
{
	// Returning general failure for ClearTaskSetRequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}
	
SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::LogicalUnitResetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL )
{
	// Returning general failure for LogicalUnitResetRequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}
	
SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::TargetResetRequest (
							SCSITargetIdentifier		theT )
{
	// Returning general failure for TargetResetRequest as this isn't yet supported by our HBA

	return kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
}

SCSIInitiatorIdentifier
com_apple_dts_SCSIEmulatorAdapter::ReportInitiatorIdentifier ( void )
{
	// What device ID does our HBA occupy on the bus?

	SCSIInitiatorIdentifier ourIdentity = INITIATOR_IDENTIFIER;
	return ourIdentity;
}

SCSIDeviceIdentifier
com_apple_dts_SCSIEmulatorAdapter::ReportHighestSupportedDeviceID ( void )
{
	// This HBA can handle how many attached devices?  The actual number can be lower

	SCSIDeviceIdentifier highestValidDevice = kMaxTargetID;
	return highestValidDevice;
}

UInt32
com_apple_dts_SCSIEmulatorAdapter::ReportMaximumTaskCount ( void )
{
	// How many concurrent tasks does our HBA support?
	// Given that this is the parallel tasking SCSI family, you'd
	// expect this to be greater than 1, but single task HBAs are
	// supported as well

	UInt32 maxTasks = kMaxTasks;
	return maxTasks;
}

UInt32
com_apple_dts_SCSIEmulatorAdapter::ReportHBASpecificTaskDataSize ( void )
{
	// How much space do we need allocated internally for each task?

	UInt32 taskDataSize = sizeof(SCSIEmulatorRequestBlock);
	return taskDataSize;
}

UInt32
com_apple_dts_SCSIEmulatorAdapter::ReportHBASpecificDeviceDataSize ( void )
{
	// How much space do we need allocated internally for each attached device?

	UInt32 hbaDataSize = sizeof(com_apple_dts_SCSIEmulator *);
	return hbaDataSize;
}

bool
com_apple_dts_SCSIEmulatorAdapter::DoesHBAPerformDeviceManagement ( void )
{
	// Report that we *DO NOT* manage our own devices
	// We will have the system query each possible target during startup
	// and do not expect or handle changes to this list while running

	// If you know that the bus is static and won't change, you can report false here and let the
	// OS handle discovering any attached devices.  If this is a SCSI bus where devices can be
	// dynamically added/removed, then you will need to return true and have a mechanism for
	// detecting, adding and removing devices as needed.

#if 0
	// If you were to do device management yourself, you would have to do something like:
	SCSIDeviceIdentifier index = 0
	CreateTargetForID(index++);
	
	// Use DestroyTargetForID() to remove targets as they disappear
#endif

	// This HBA does not support a mechanism for device attach/detach 
	// notification, go ahead and create target devices.
	return false;
}

bool
com_apple_dts_SCSIEmulatorAdapter::InitializeController ( void )
{
	com_apple_dts_SCSIEmulatorAdapterNub *nub = NULL;
	IOReturn ret = kIOReturnSuccess;

	nub	= OSDynamicCast(com_apple_dts_SCSIEmulatorAdapterNub, getProvider());
	if (!nub) {
		IOLog("InitializeController: failed to cast provider\n");
		goto failed;
	}

	mTargetsArray = OSArray::withCapacity(kMaxTargetID);
	
	mResponderEventSource = OSTypeAlloc(com_apple_dts_SCSIEmulatorEventSource);
	if (!mResponderEventSource) {
		IOLog("InitializeController: failed to alloc mResponderEventSource\n");
		goto failed;
	}

	if (!mResponderEventSource->init(this,  &com_apple_dts_SCSIEmulatorAdapter::TaskComplete)) {
		IOLog("InitializeController: failed to init mResponderEventSource\n");
		mResponderEventSource->release();
		goto failed;
	}

	ret = GetWorkLoop()->addEventSource(mResponderEventSource);
	if (ret != kIOReturnSuccess) {
		IOLog("InitializeController: failed to add event source.  ret = 0x%X\n", ret);
		mResponderEventSource->release();
		goto failed;
	}

	goto success;
	
failed:
	return false;
	
success:
	// The controller is now initialized and ready for operation
	return true;
}

void
com_apple_dts_SCSIEmulatorAdapter::TerminateController ( void )
{
	if (GetWorkLoop()->removeEventSource(mResponderEventSource) != kIOReturnSuccess) {
		IOLog("TerminateController: failed to de-register eventsource?\n");
	}

	if (mResponderEventSource)
		mResponderEventSource->release();

	if (mTargetsArray)
		mTargetsArray->release();
}

bool
com_apple_dts_SCSIEmulatorAdapter::StartController ( void )
{
	// Start providing HBA services.  Re-init anything needed and go

	return true;
}

void
com_apple_dts_SCSIEmulatorAdapter::StopController ( void )
{
	// We've been requested to stop providing HBA services.  Clean up and shut down
}

void
com_apple_dts_SCSIEmulatorAdapter::HandleInterruptRequest ( void )
{
	// OK, odds are, your driver will want to do something here to get info from the HBA.
	// Usually, this will be pulling task completion info, etc. and then calling TaskCompleted().
	//
	// this->TaskCompleted(task, transportSucceeded, scsiStatus, transferredDataLength, senseData, senseDataLength);
	//

	// Since this example operates without using a real primary interrupt, this will never get called
	IOLog("HandleInterruptRequest: captured interrupt?");
}

SCSIServiceResponse
com_apple_dts_SCSIEmulatorAdapter::ProcessParallelTask ( SCSIParallelTaskIdentifier parallelRequest )
{
	// Not all of these may be required.  Unused ones are commented out to avoid compiler warnings
	SCSITargetIdentifier		targetID				= GetTargetIdentifier(parallelRequest);
//	SCSITaskIdentifier			task					= GetSCSITaskIdentifier(parallelRequest);
//	SCSITaggedTaskIdentifier	taggedTask				= GetTaggedTaskIdentifier(parallelRequest);
	SCSILogicalUnitNumber		lun						= GetLogicalUnitNumber(parallelRequest);
//	SCSITaskAttribute			taskAttribute			= GetTaskAttribute(parallelRequest);
	
	UInt8						transferDir				= GetDataTransferDirection(parallelRequest);
	UInt64						transferSize			= GetRequestedDataTransferCount(parallelRequest);
	IOMemoryDescriptor *		transferMemDesc			= GetDataBuffer(parallelRequest);
//	UInt64						transferMemDescOffset   = GetDataBufferOffset(parallelRequest);

	// Get the CDB
	UInt8						cdbLength				= GetCommandDescriptorBlockSize(parallelRequest);
	SCSICommandDescriptorBlock  cdbData;
	
	SCSITaskStatus 				scsiStatus 				= kSCSITaskStatus_GOOD;
	UInt64 						dataLen 				= 0;

	UInt8						senseBuffer[kSenseBufferLen];
	UInt64						senseBufferLen 			= sizeof(senseBuffer);

	com_apple_dts_SCSIEmulator *emulator = (com_apple_dts_SCSIEmulator *)mTargetsArray->getObject(targetID);

	// Fail if we don't have a SCSI emulator backing this target
	if (!emulator) {
		IOLog("ProcessParallelTask: ABORT - !emulator for targetID = %ud\n", targetID);
		goto failure_exit;
	}

	// Fail if we're supposed to transfer data and don't have a data buffer
	if (!transferMemDesc && (transferDir != kSCSIDataTransfer_NoDataTransfer)) {
		IOLog("ProcessParallelTask: ABORT - !transferMemDesc && (transferDir != kSCSIDataTransfer_NoDataTransfer) - %p and %d\n", transferMemDesc, transferDir);
		goto failure_exit;
	}

	// Fail if we don't have a large enough CDB buffer set aside
	if (cdbLength > sizeof(cdbData)) {
		IOLog("ProcessParallelTask: ABORT - cdbLength > sizeof(cdbData) - %d vs. %d\n", cdbLength, sizeof(cdbData));
		goto failure_exit;
	}

	if (!GetCommandDescriptorBlock(parallelRequest, &cdbData)) {
		IOLog("ProcessParallelTask: ABORT - !GetCommandDescriptorBlock(parallelRequest, &cdbData)\n");
		goto failure_exit;
	}

	if (transferMemDesc && (transferDir != kSCSIDataTransfer_NoDataTransfer)) {
#if 0
		// This block isn't necessary as memory descriptors passed in are always autoprepared for us.
		// Remember: Any memory descriptors allocated and used internally should be prepared before sending
		// or receiving data to/from real hardware
		IOReturn res = transferMemDesc->prepare();
		if (res != kIOReturnSuccess) {
			goto failure_exit;
		}
#endif

		// We are guaranteed that the memory descriptor will always be sized large enough by
		// by SAM/STUC to hold the transfer size requested
		dataLen = transferSize;
	}

	// This is where the "real" work should get done by your hardware.  The individual parameters
	// are being sent instead of just the task reference as the task is opaque by design and
	// the getter/setter methods are protected and available within this class, but not within
	// the emulator itself.
	emulator->sendCommand(cdbData, cdbLength, transferMemDesc, &dataLen, lun, &scsiStatus, senseBuffer, &senseBufferLen);

	// Real hardware should be doing the task processing internally and providing responses
	// via an interrupt mechanism.  IOSCSIParallelInterfaceController expects this and you
	// should always do your task completions from the workloop thread.
	CompleteTaskOnWorkloopThread(parallelRequest, true, scsiStatus, dataLen, senseBuffer, senseBufferLen);
	return kSCSIServiceResponse_Request_In_Process;

failure_exit:
	CompleteTaskOnWorkloopThread(parallelRequest, false, scsiStatus, dataLen, senseBuffer, senseBufferLen);
	return kSCSIServiceResponse_Request_In_Process;
}

void
com_apple_dts_SCSIEmulatorAdapter::CompleteTaskOnWorkloopThread (
	SCSIParallelTaskIdentifier		parallelRequest,
	bool							transportSuccessful,
	SCSITaskStatus					scsiStatus,
	UInt64							actuallyTransferred,
	UInt8*							senseBuffer,
	int								senseLength)
{
//	SCSITargetIdentifier		target					= GetTargetIdentifier(parallelRequest);
	UInt8						transferDir				= GetDataTransferDirection(parallelRequest);
	UInt64						transferSizeMax			= GetRequestedDataTransferCount(parallelRequest);
//	IOMemoryDescriptor *		transferMemDesc			= GetDataBuffer(parallelRequest);
	SCSIEmulatorRequestBlock *	srb						= ( SCSIEmulatorRequestBlock * ) GetHBADataPointer ( parallelRequest );
	
	if (transportSuccessful && (scsiStatus != kSCSITaskStatus_TASK_SET_FULL)) {
		// set the realized transfer counts
		switch (transferDir) {
			case kSCSIDataTransfer_FromTargetToInitiator:
			{
				if (actuallyTransferred > transferSizeMax) {
					actuallyTransferred = transferSizeMax;
				}
				if (!SetRealizedDataTransferCount(parallelRequest, actuallyTransferred)) {
					IOLog("CompleteTaskOnWorkloopThread: SetRealizedDataTransferCount (%d bytes) returned FAIL\n", actuallyTransferred);
				}
				break;
			}
			case kSCSIDataTransfer_FromInitiatorToTarget:
			{
				if (actuallyTransferred > transferSizeMax) {
					actuallyTransferred = transferSizeMax;
				}
				if (!SetRealizedDataTransferCount(parallelRequest, actuallyTransferred)) {
					IOLog("CompleteTaskOnWorkloopThread: SetRealizedDataTransferCount (%d bytes) returned FAIL\n", actuallyTransferred);
				}
				break;
			}
			case kSCSIDataTransfer_NoDataTransfer:
			default:
			{
				break;
			}
		}
	}

	// Now, add the completion to the queue to be checked by the workloop thread.  The completion needs
	// to be done on the workloop to allow the stack to unwind itself or you risk running into a panic.
	// The addItemToQueue method in the event source signals the workloop to check the queue after the task
	// is added.
	if (!transportSuccessful) {
		IOLog("CompleteTaskOnWorkloopThread: Failed transport - task = %p, transferDir = %d, transferSize = %lld, scsiStatus = 0x%X\n", parallelRequest, transferDir, transferSizeMax, scsiStatus);
		
		queue_init(&srb->fQueueChain);
		srb->fTask = parallelRequest;
		srb->fTaskStatus = scsiStatus;
		srb->fServiceResponse = kSCSIServiceResponse_SERVICE_DELIVERY_OR_TARGET_FAILURE;
		
		mResponderEventSource->addItemToQueue(srb);
		
	} else {
		// handle sense data in common fashion and complete the task
		if (senseLength > 0) {
			if (!SetAutoSenseData(parallelRequest, (SCSI_Sense_Data*) senseBuffer, senseLength)) {
				IOLog("CompleteTaskOnWorkloopThread: Could not set sense data in parallel task\n");
			}
		}
		
		queue_init(&srb->fQueueChain);
		srb->fTask = parallelRequest;
		srb->fTaskStatus = scsiStatus;
		srb->fServiceResponse = kSCSIServiceResponse_TASK_COMPLETE;
		
		mResponderEventSource->addItemToQueue(srb);
	}
	
}

void
com_apple_dts_SCSIEmulatorAdapter::TaskComplete (com_apple_dts_SCSIEmulatorAdapter *owner, SCSIEmulatorRequestBlock response)
{
	owner->CompleteParallelTask(response.fTask, response.fTaskStatus, response.fServiceResponse);
}

