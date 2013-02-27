/*

File:SCSIEmulatorAdapter.h

Abstract: Header for the core of a virtual SCSI HBA based off of
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

// Code to implement a basic Parallel tasking SCSI HBA.  In this case, a SCSI-based RAM disk.
// While this works via IOSCSIParallelInterfaceController, it won't ever see multiple outstanding
// transactions as all calls from the OS into this driver are command gated and the driver itself
// will return data immediately.

#ifndef _SCSIEMULATORADAPTER_H
#define _SCSIEMULATORADAPTER_H

#include <IOKit/scsi/spi/IOSCSIParallelInterfaceController.h>
#include <IOKit/scsi/SCSITask.h>

#include "SCSIEmulatorEventSource.h"

class com_apple_dts_SCSIEmulator;

class com_apple_dts_SCSIEmulatorAdapter : public IOSCSIParallelInterfaceController {

OSDeclareDefaultStructors(com_apple_dts_SCSIEmulatorAdapter)
friend class com_apple_dts_SCSIEmulatorEventSource;

public:
    virtual bool		willTerminate(IOService *provider, IOOptionBits options);
    virtual bool		didTerminate(IOService *provider, IOOptionBits options, bool *defer);

	/*! @function terminate
		@abstract Make an IOService inactive and begin its destruction.
		@discussion Registering an IOService informs possible clients of its existance and instantiates drivers that may be used with it; terminate involves the opposite process of informing clients that an IOService is no longer able to be used and will be destroyed. By default, if any client has the service open, terminate fails. If the kIOServiceRequired flag is passed however, terminate will be sucessful though further progress in the destruction of the IOService will not proceed until the last client has closed it. The service will be made inactive immediately upon successful termination, and all its clients will be notified via their message method with a message of type kIOMessageServiceIsTerminated. Both these actions take place on the callers thread. After the IOService is made inactive, further matching or attach calls will fail on it. Each client has its stop method called upon their close of an inactive IOService, or on its termination if they do not have it open. After stop, detach is called in each client. When all clients have been detached, the finalize method is called in the inactive service. The terminate process is inherently asynchronous since it will be deferred until all clients have chosen to close.
		@param options In most cases no options are needed. kIOServiceSynchronous may be passed to cause terminate to not return until the service is finalized.
	*/

    virtual bool terminate( IOOptionBits options = 0 );

	/*!
		@function message
		@abstract Receive a generic message delivered from an attached provider.
		@discussion A provider may deliver messages via the message method to its clients informing them of state changes, for example kIOMessageServiceIsTerminated or kIOMessageServiceIsSuspended. Certain messages are defined by IOKit in IOMessage.h while others may family dependent. This method is implemented in the client to receive messages.
		@param type A type defined in IOMessage.h or defined by the provider family.
		@param provider The provider from which the message originates.
		@param argument An argument defined by the provider family, not used by IOService.
		@result An IOReturn code defined by the message type.
	*/

    virtual IOReturn message( UInt32 type, IOService * provider,
                              void * argument = 0 );

	/*!
		@function ReportHBAHighestLogicalUnitNumber
		@abstract Gets the Highest Logical Unit Number
		@discussion	This method is used to query the HBA child class to 
		determine what the highest Logical Unit Number that the controller can 
		address.
		@result returns a valid 64-bit logical unit number.
	*/
	
	virtual SCSILogicalUnitNumber	ReportHBAHighestLogicalUnitNumber ( void );
	
	/*!
		@function DoesHBASupportSCSIParallelFeature
		@abstract Queries the HBA child class to determine if it supports a 
		specific SPI feature.
		@discussion	Queries the HBA child class to determine if it supports the 
		specified feature as defined by the SCSI Parallel Interconnect 
		specifications.
		@result Returns true if requested feature is supported.
	*/
	
	virtual bool	DoesHBASupportSCSIParallelFeature ( 
							SCSIParallelFeature 		theFeature );
	
	/*!
		@function InitializeTargetForID
		@abstract Called to initialized a target device.
		@discussion	This method will be called to initialize a target device in 
		a single-threaded manner.  The HBA can use this method to probe the 
		target or do anything else necessary before the device object is 
		registered with IOKit for matching.
		@result Returns true if the target was successfully initialized.
	*/
	
	virtual bool	InitializeTargetForID (  
							SCSITargetIdentifier 		targetID );

	// The SCSI Task Management Functions as defined in the SCSI Architecture
	// Model - 2 (SAM-2) specification.  These are used by the client to request
	// the specified function.  The controller can complete these immmediately 
	// by returning the appropriate SCSIServiceResponse, or these can be completed
	// asyncronously by the controller returning a SCSIServiceResponse of
	// kSCSIServiceResponse_Request_In_Process and then calling the appropriate
	// function complete member routine listed in the child class API section.
	
	virtual SCSIServiceResponse	AbortTaskRequest ( 	
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL,
							SCSITaggedTaskIdentifier	theQ );

	virtual	SCSIServiceResponse AbortTaskSetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL );
	
	virtual	SCSIServiceResponse ClearACARequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL );
	
	virtual	SCSIServiceResponse ClearTaskSetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL );
	
	virtual	SCSIServiceResponse LogicalUnitResetRequest (
							SCSITargetIdentifier 		theT,
							SCSILogicalUnitNumber		theL );
	
	virtual	SCSIServiceResponse TargetResetRequest (
							SCSITargetIdentifier 		theT );

	void CompleteTaskOnWorkloopThread ( 
							SCSIParallelTaskIdentifier		parallelRequest,
							bool							transportSuccessful,
							SCSITaskStatus					scsiStatus,
							UInt64							actuallyTransferred,
							UInt8*							senseBuffer,
							int								senseLength );

protected:
	/*!
		@function ReportInitiatorIdentifier
		@abstract Get the SCSI Device Identifer for the HBA.
		@discussion This method will be called to determine the SCSI Device 
		Identifer that the Initiator has assigned for this HBA.
		@result returns SCSIInitiatorIdentifier.
	*/
	
	virtual SCSIInitiatorIdentifier	ReportInitiatorIdentifier ( void );
	
	/*!
		@function ReportHighestSupportedDeviceID
		@abstract Get the highest supported SCSI Device Identifer.
		@discussion This method will be called to determine the value of the 
		highest SCSI Device Identifer supported by the HBA. This value will be 
		used to determine the last ID to process.
		@result returns highest SCSIDeviceIdentifier
	*/
	
	virtual SCSIDeviceIdentifier	ReportHighestSupportedDeviceID ( void );
	
	/*!
		@function ReportMaximumTaskCount
		@abstract Report Maximum Task Count
		@discussion This method will be called to retrieve the maximum number of
		outstanding tasks the HBA can process. This number must be greater than
		zero or the controller driver will fail to match and load.
		@result returns maximum (non-zero) task count.
	*/
	
	virtual UInt32		ReportMaximumTaskCount ( void );
	
  	/*!
		@function ReportHBASpecificTaskDataSize
		@abstract Determine memory needed for HBA Task specific use.
		@discussion This method is used to retrieve the amount of memory that 
		will be allocated in the SCSI Parallel Task for HBA specific use.
		@result returns memory required in bytes
	*/
	
	virtual UInt32		ReportHBASpecificTaskDataSize ( void );
	
  	/*!
		@function ReportHBASpecificDeviceDataSize
		@abstract  Determine memory needed for HBA Device specific use.
		@discussion This method is used to retrieve the amount of memory that 
		will be allocated in the SCSI Parallel Device for HBA specific use.
		@result  returns memory required in bytes
	*/
	
	virtual UInt32		ReportHBASpecificDeviceDataSize ( void );
	
  	/*!
		@function DoesHBAPerformDeviceManagement
		@abstract  Determine if HBA will manage devices.
		@discussion This method is used to determine if the HBA will manage 
		target device creation and destruction.  
		@result return true means objects for target devices will only be 	
		created when the child class calls the CreateTargetForID method.
	*/
	
	virtual bool		DoesHBAPerformDeviceManagement ( void );

	
  	/*!
		@function InitializeController
		@abstract  Called to initialize the controller
		@discussion It is guaranteed that the InitializeController will only be 
		called once per instantiation.  The InitializeController methods allows 
		the subclass driver to do all the necessary initialization required by 
		the hardware before it is able to accept requests to execute. All 
		necessary allocation of resources should be made during this method 
		call. This is the first method that will be called in the subclass.
		@result return true means that initialization was successful.
	*/
	
	virtual bool	InitializeController ( void );
	
  	/*!
		@function TerminateController
		@abstract  Called to terminate the controller
		@discussion It is guaranteed that the TerminateController will only be 
		called once and only after the InitializeController method and only if 
		true was returned in response to the InitializeController method.
		The TerminateController method allows the subclass to release all 
		resources that were acquired for operation of the hardware and shutdown 
		all hardware services.
		This is the last method of the subclass that will be called before the 		
		class is destroyed.
	*/
	
	virtual void	TerminateController ( void );
	
	/*!
		@function StartController
		@abstract Called to start the controller
		@discussion The StartController will always be called before any 
		requests are sent to the driver for execution. This method is called 
		after an initialize to start the services provided by the specific HBA 
		driver or called after a StopController call to restart those services. 
		After this call completes, all services provided by the HBA driver are 
		available to the client.
		@result return true means that start was successful.
	*/
	
	virtual bool	StartController ( void );
	
	/*!
		@function StopController
		@abstract Called to stop the controller
		@discussion The StopController method will be called any time that the 
		system wants the card to stop accepting requests. ( See StartController 
		discussion )
	*/
	
	virtual void	StopController ( void );

	/*!
		@function HandleInterruptRequest
		@abstract Handle Interrupt Request
		@discussion The HandleInterruptRequest is used to notifiy an HBA 
		specific subclass that an interrupt request needs to be serviced. It is 
		called on the workloop (it holds the gate) at secondary interrupt level.
	*/
	
	virtual void	HandleInterruptRequest ( void );

	/*!
		@function ProcessParallelTask
		@abstract Called by client to process a parallel task.
		@discussion This method is called to process a parallel task (i.e. put
		the command on the bus). The HBA specific sublcass must implement this 
		method.
		@param parallelRequest A valid SCSIParallelTaskIdentifier.
		@result serviceResponse (see <IOKit/scsi/SCSITask.h>)
	*/
	
	virtual SCSIServiceResponse ProcessParallelTask (
							SCSIParallelTaskIdentifier parallelRequest );

private:
	static void TaskComplete ( com_apple_dts_SCSIEmulatorAdapter *owner, SCSIEmulatorRequestBlock response );

	OSArray *mTargetsArray;
	
	com_apple_dts_SCSIEmulatorEventSource *mResponderEventSource;
};

#endif
