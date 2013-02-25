/*
	File:			SimpleUserClient.cpp
	
	Description:	This file shows how to implement a simple I/O Kit user client that is Rosetta-aware.

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


#include <IOKit/IOLib.h>
#include <IOKit/IOKitKeys.h>
#include <libkern/OSByteOrder.h>
#include "SimpleUserClient.h"


#define super IOUserClient

// Even though we are defining the convenience macro super for the superclass, you must use the actual class name
// in the OS*MetaClass macros. Note that the class name is different when supporting Mac OS X 10.4.

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
OSDefineMetaClassAndStructors(com_apple_dts_driver_SimpleUserClient_10_4, IOUserClient)
#else
OSDefineMetaClassAndStructors(com_apple_dts_driver_SimpleUserClient, IOUserClient)
#endif

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
// Sentinel values for the method dispatch table
enum {
    kMethodObjectThis = 0,
    kMethodObjectProvider
};


// User client method dispatch table.
//
// The user client mechanism is designed to allow calls from a user process to be dispatched to
// any IOService-based object in the kernel. Almost always this mechanism is used to dispatch calls to
// either member functions of the user client itself or of the user client's provider. The provider is
//  the driver which the user client is connecting to the user process.
//
// While this sample shows one case of dispatching calls directly to the driver (ScalarIScalarO),
// it is recommended that calls be dispatched to the user client. This allows the user client to perform
// error checking on the parameters before passing them to the driver. It also allows the user client to
// do any endian-swapping of parameters in the cross-endian case. (See ScalarIStructI below for further
// discussion of this subject.)
//
// The dispatch table makes use of the sentinel values kMethodObjectThis and kMethodObjectProvider to
// represent at compile time the values of the this pointer and fProvider respectively at run time.  
const IOExternalMethod SimpleUserClientClassName::sMethods[kNumberOfMethods] = {
	{   // kMyUserClientOpen
		(IOService *) kMethodObjectThis,									// Target object is this user client.
		(IOMethod) &SimpleUserClientClassName::openUserClient,				// Method pointer.
		kIOUCScalarIScalarO,												// Scalar Input, Scalar Output.
		0,																	// No scalar input values.
		0																	// No scalar output values.
	},
	{   // kMyUserClientClose
		(IOService *) kMethodObjectThis,									// Target object is this user client.
		(IOMethod) &SimpleUserClientClassName::closeUserClient,				// Method pointer.
		kIOUCScalarIScalarO,												// Scalar Input, Scalar Output.
		0,																	// No scalar input values.
		0																	// No scalar output values.
	},
	{   // kMyScalarIStructIMethod
		(IOService *) kMethodObjectThis,									// Target object is this user client.
		(IOMethod) &SimpleUserClientClassName::ScalarIStructI,				// Method pointer.
		kIOUCScalarIStructI,												// Scalar Input, Struct Input.
		1,																	// One scalar input value.
		sizeof(MySampleStruct)												// The size of the input struct.
	},
	{   // kMyScalarIStructOMethod
		(IOService *) kMethodObjectThis,									// Target object is this user client.
		(IOMethod) &SimpleUserClientClassName::ScalarIStructO,				// Method pointer.
		kIOUCScalarIStructO,												// Scalar Input, Struct Output.
		2,																	// Two scalar input values.
		sizeof(MySampleStruct)												// The size of the output struct.
	},
	{   // kMyScalarIScalarOMethod
		(IOService *) kMethodObjectProvider,								// Target object is this user client's provider
																			// (the driver).
		(IOMethod) &SimpleDriverClassName::ScalarIScalarO,					// Method pointer.
		kIOUCScalarIScalarO,												// Scalar Input, Scalar Output.
		2,																	// Two scalar input values.
		1																	// One scalar output value.
	},
	{   // kMyStructIStructOMethod
		(IOService *) kMethodObjectThis,									// Target object is this user client.
		(IOMethod) &SimpleUserClientClassName::StructIStructO,				// Method pointer.
		kIOUCStructIStructO,												// Struct Input, Struct Output.
		sizeof(MySampleStruct),												// The size of the input struct.
		sizeof(MySampleStruct)												// The size of the output struct.
	}
};
    
// Look up the external methods - supply a description of the parameters 
// available to be called.
//
// This is the legacy approach which only supports 32-bit user processes.
IOExternalMethod* SimpleUserClientClassName::getTargetAndMethodForIndex(IOService** target, UInt32 index)
{
	IOLog("%s[%p]::%s(%p, %ld)\n", getName(), this, __FUNCTION__, target, index);
    
    // Make sure that the index of the function we're calling actually exists in the function table.
    if (index < (UInt32) kNumberOfMethods) {
		if (sMethods[index].object == (IOService *) kMethodObjectThis) {
			*target = this;	   
        }
		else {
			*target = fProvider;	   
		}
		return (IOExternalMethod *) &sMethods[index];
    }
	else {
		*target = NULL;
		return NULL;
	}
}
#else
// This is the technique which supports both 32-bit and 64-bit user processes starting with Mac OS X 10.5.
//
// User client method dispatch table.
//
// The user client mechanism is designed to allow calls from a user process to be dispatched to
// any IOService-based object in the kernel. Almost always this mechanism is used to dispatch calls to
// either member functions of the user client itself or of the user client's provider. The provider is
// the driver which the user client is connecting to the user process.
//
// It is recommended that calls be dispatched to the user client and not directly to the provider driver.
// This allows the user client to perform error checking on the parameters before passing them to the driver.
// It also allows the user client to do any endian-swapping of parameters in the cross-endian case.
// (See ScalarIStructI below for further discussion of this subject.)

const IOExternalMethodDispatch SimpleUserClientClassName::sMethods[kNumberOfMethods] = {
	{   // kMyUserClientOpen
		(IOExternalMethodAction) &SimpleUserClientClassName::sOpenUserClient,	// Method pointer.
		0,																		// No scalar input values.
		0,																		// No struct input value.
		0,																		// No scalar output values.
		0																		// No struct output value.
	},
	{   // kMyUserClientClose
		(IOExternalMethodAction) &SimpleUserClientClassName::sCloseUserClient,	// Method pointer.
		0,																		// No scalar input values.
		0,																		// No struct input value.
		0,																		// No scalar output values.
		0																		// No struct output value.
	},
	{   // kMyScalarIStructIMethod
		(IOExternalMethodAction) &SimpleUserClientClassName::sScalarIStructI,	// Method pointer.
		1,																		// One scalar input value.
		sizeof(MySampleStruct),													// The size of the input struct.
		0,																		// No scalar output values.
		0																		// No struct output value.
	},
	{   // kMyScalarIStructOMethod
		(IOExternalMethodAction) &SimpleUserClientClassName::sScalarIStructO,	// Method pointer.
		2,																		// Two scalar input values.
		0,																		// No struct input value.
		0,																		// No scalar output values.
		sizeof(MySampleStruct)													// The size of the output struct.
	},
	{   // kMyScalarIScalarOMethod
		(IOExternalMethodAction) &SimpleUserClientClassName::sScalarIScalarO,	// Method pointer.
		2,																		// Two scalar input values.
		0,																		// No struct input value.
		1,																		// One scalar output value.
		0																		// No struct output value.
	},
	{   // kMyStructIStructOMethod
		(IOExternalMethodAction) &SimpleUserClientClassName::sStructIStructO,	// Method pointer.
		0,																		// No scalar input values.
		sizeof(MySampleStruct),													// The size of the input struct.
		0,																		// No scalar output values.
		sizeof(MySampleStruct)													// The size of the output struct.
	}
};

IOReturn SimpleUserClientClassName::externalMethod(uint32_t selector, IOExternalMethodArguments* arguments,
												   IOExternalMethodDispatch* dispatch, OSObject* target, void* reference)

{
	IOLog("%s[%p]::%s(%d, %p, %p, %p, %p)\n", getName(), this, __FUNCTION__,
		  selector, arguments, dispatch, target, reference);
        
    if (selector < (uint32_t) kNumberOfMethods) {
        dispatch = (IOExternalMethodDispatch *) &sMethods[selector];
        
        if (!target) {
            if (selector == kMyScalarIScalarOMethod) {
				target = fProvider;
			}
			else {
				target = this;
			}
		}
    }
        
	return super::externalMethod(selector, arguments, dispatch, target, reference);
}
#endif


// There are two forms of IOUserClient::initWithTask, the second of which accepts an additional OSDictionary* parameter.
// If your user client needs to modify its behavior when it's being used by a process running using Rosetta,
// you need to implement the form of initWithTask with this additional parameter.
//
// initWithTask is called as a result of the user process calling IOServiceOpen.
bool SimpleUserClientClassName::initWithTask(task_t owningTask, void* securityToken, UInt32 type, OSDictionary* properties)
{
    bool	success;
    
	success = super::initWithTask(owningTask, securityToken, type, properties);	    
	
	// This IOLog must follow super::initWithTask because getName relies on the superclass initialization.
	IOLog("%s[%p]::%s(%p, %p, %ld, %p)\n", getName(), this, __FUNCTION__, owningTask, securityToken, type, properties);

	if (success) {
		// This code will do the right thing on both PowerPC- and Intel-based systems because the cross-endian
		// property will never be set on PowerPC-based Macs. 
		fCrossEndian = false;
	
		if (properties != NULL && properties->getObject(kIOUserClientCrossEndianKey)) {
			// A connection to this user client is being opened by a user process running using Rosetta.
			
			// Indicate that this user client can handle being called from cross-endian user processes by 
			// setting its IOUserClientCrossEndianCompatible property in the I/O Registry.
			if (setProperty(kIOUserClientCrossEndianCompatibleKey, kOSBooleanTrue)) {
				fCrossEndian = true;
				IOLog("%s[%p]::%s(): fCrossEndian = true\n", getName(), this, __FUNCTION__);
			}
		}
	}
	
    fTask = owningTask;
    fProvider = NULL;
        
    return success;
}


// start is called after initWithTask as a result of the user process calling IOServiceOpen.
bool SimpleUserClientClassName::start(IOService* provider)
{
    bool	success;
	
	IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
    
    // Verify that this user client is being started with a provider that it knows
	// how to communicate with.
	fProvider = OSDynamicCast(SimpleDriverClassName, provider);
    success = (fProvider != NULL);
    
    if (success) {
		// It's important not to call super::start if some previous condition
		// (like an invalid provider) would cause this function to return false. 
		// I/O Kit won't call stop on an object if its start function returned false.
		success = super::start(provider);
	}
	
    return success;
}


// We override stop only to log that it has been called to make it easier to follow the user client's lifecycle.
void SimpleUserClientClassName::stop(IOService* provider)
{
	IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
    
    super::stop(provider);
}


// clientClose is called as a result of the user process calling IOServiceClose.
IOReturn SimpleUserClientClassName::clientClose(void)
{
	IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
    
    // Defensive coding in case the user process called IOServiceClose
	// without calling closeUserClient first.
    (void) closeUserClient();
    
	// Inform the user process that this user client is no longer available. This will also cause the
	// user client instance to be destroyed.
	//
	// terminate would return false if the user process still had this user client open.
	// This should never happen in our case because this code path is only reached if the user process
	// explicitly requests closing the connection to the user client.
	bool success = terminate();
	if (!success) {
		IOLog("%s[%p]::%s(): terminate() failed.\n", getName(), this, __FUNCTION__);
	}

    // DON'T call super::clientClose, which just returns kIOReturnUnsupported.
    
    return kIOReturnSuccess;
}


// clientDied is called if the client user process terminates unexpectedly (crashes).
// We override clientDied only to log that it has been called to make it easier to follow the user client's lifecycle.
// Production user clients need to override clientDied only if they need to take some alternate action if the user process
// crashes instead of exiting normally.
IOReturn SimpleUserClientClassName::clientDied(void)
{
    IOReturn result = kIOReturnSuccess;

	IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);

    // The default implementation of clientDied just calls clientClose.
    result = super::clientDied();

    return result;
}


// willTerminate is called at the beginning of the termination process. It is a notification
// that a provider has been terminated, sent before recursing up the stack, in root-to-leaf order.
//
// This is where any pending I/O should be terminated. At this point the user client has been marked
// inactive and any further requests from the user process should be returned with an error.
bool SimpleUserClientClassName::willTerminate(IOService* provider, IOOptionBits options)
{
	IOLog("%s[%p]::%s(%p, %ld)\n", getName(), this, __FUNCTION__, provider, options);
	
	return super::willTerminate(provider, options);
}


// didTerminate is called at the end of the termination process. It is a notification
// that a provider has been terminated, sent after recursing up the stack, in leaf-to-root order.
bool SimpleUserClientClassName::didTerminate(IOService* provider, IOOptionBits options, bool* defer)
{
	IOLog("%s[%p]::%s(%p, %ld, %p)\n", getName(), this, __FUNCTION__, provider, options, defer);
	
	// If all pending I/O has been terminated, close our provider. If I/O is still outstanding, set defer to true
	// and the user client will not have stop called on it.
	closeUserClient();
	*defer = false;
	
	return super::didTerminate(provider, options, defer);
}


// We override terminate only to log that it has been called to make it easier to follow the user client's lifecycle.
// Production user clients will rarely need to override terminate. Termination processing should be done in
// willTerminate or didTerminate instead.
bool SimpleUserClientClassName::terminate(IOOptionBits options)
{
    bool	success;
    
	IOLog("%s[%p]::%s(%ld)\n", getName(), this, __FUNCTION__, options);

    success = super::terminate(options);
    
    return success;
}


// We override finalize only to log that it has been called to make it easier to follow the user client's lifecycle.
// Production user clients will rarely need to override finalize.
bool SimpleUserClientClassName::finalize(IOOptionBits options)
{
    bool	success;
    
	IOLog("%s[%p]::%s(%ld)\n", getName(), this, __FUNCTION__, options);
    
    success = super::finalize(options);
    
    return success;
}


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sOpenUserClient(SimpleUserClientClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->openUserClient();
}
#endif

IOReturn SimpleUserClientClassName::openUserClient(void)
{
    IOReturn	result = kIOReturnSuccess;
	
	IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
    
    if (fProvider == NULL || isInactive()) {
		// Return an error if we don't have a provider. This could happen if the user process
		// called openUserClient without calling IOServiceOpen first. Or, the user client could be
		// in the process of being terminated and is thus inactive.
        result = kIOReturnNotAttached;
	}
    else if (!fProvider->open(this)) {
		// The most common reason this open call will fail is because the provider is already open
		// and it doesn't support being opened by more than one client at a time.
		result = kIOReturnExclusiveAccess;
	}
        
    return result;
}


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sCloseUserClient(SimpleUserClientClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->closeUserClient();
}
#endif


IOReturn SimpleUserClientClassName::closeUserClient(void)
{
    IOReturn	result = kIOReturnSuccess;
	
	IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
            
    if (fProvider == NULL) {
		// Return an error if we don't have a provider. This could happen if the user process
		// called closeUserClient without calling IOServiceOpen first. 
		result = kIOReturnNotAttached;
		IOLog("%s[%p]::%s(): returning kIOReturnNotAttached.\n", getName(), this, __FUNCTION__);
	}
	else if (fProvider->isOpen(this)) {
		// Make sure we're the one who opened our provider before we tell it to close.
		fProvider->close(this);
	}
	else {
		result = kIOReturnNotOpen;
		IOLog("%s[%p]::%s(): returning kIOReturnNotOpen.\n", getName(), this, __FUNCTION__);
	}
	
    return result;
}


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sScalarIStructI(SimpleUserClientClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->ScalarIStructI((uint32_t) arguments->scalarInput[0],
								  (MySampleStruct*) arguments->structureInput,
								  (uint32_t) arguments->structureInputSize);
}
#endif


IOReturn SimpleUserClientClassName::ScalarIStructI(uint32_t inNumber, MySampleStruct* inStruct, uint32_t inStructSize)
{
	IOReturn	result;

	IOLog("%s[%p]::%s(inNumber = %d, field1 = %lld, field2 = %lld, inStructSize = %d)\n", getName(), this, __FUNCTION__,
		  inNumber, inStruct->field1, inStruct->field2, inStructSize);
    
	// Endian-swap structure parameters in the user client before passing them to the driver.
	//
	// This may require adding new functions to your user client and modifying the dispatch table in
	// getTargetAndMethodForIndex to point to these new functions.
	//
	// This approach is greatly preferable because it avoids the complexity of a driver which can be opened by multiple clients,
	// each of which may or may not be cross-endian. It also avoids having to change the driver to make it cross-endian-aware.
	//
	// Note that fCrossEndian will always be false if running on a PowerPC-based Mac.
	
	if (fProvider == NULL || isInactive()) {
		// Return an error if we don't have a provider. This could happen if the user process
		// called ScalarIStructI without calling IOServiceOpen first. Or, the user client could be
		// in the process of being terminated and is thus inactive.
		result = kIOReturnNotAttached;
	}
	else if (!fProvider->isOpen(this)) {
		// Return an error if we do not have the driver open. This could happen if the user process
		// did not call openUserClient before calling this function.
		result = kIOReturnNotOpen;
	}
	else {
		if (fCrossEndian) {
			// Structures aren't automatically swapped by the user client mechanism as it has no knowledge of how the fields
			// structure are laid out.
			
			// Swap the fields of the structure passed by the client user process before passing it to the driver.
			// Use the unconditional swap macros here as we know only at runtime if we're being called from a
			// cross-endian user process running using Rosetta.
			
			inStruct->field1 = OSSwapInt64(inStruct->field1);
			inStruct->field2 = OSSwapInt64(inStruct->field2);
			
			IOLog("%s[%p]::%s(after swap: inNumber = %d, field1 = %lld, field2 = %lld, inStructSize = %d)\n", getName(), this, __FUNCTION__,
				  inNumber, inStruct->field1, inStruct->field2, inStructSize);
		}
		
		result = fProvider->ScalarIStructI(inNumber, inStruct, inStructSize);
	}
	
	return result;
}


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sScalarIStructO(SimpleUserClientClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->ScalarIStructO((uint32_t) arguments->scalarInput[0],
								  (uint32_t) arguments->scalarInput[1],
								  (MySampleStruct*) arguments->structureOutput,
								  (uint32_t*) &arguments->structureOutputSize);
}
#endif


IOReturn SimpleUserClientClassName::ScalarIStructO(uint32_t inNumber1, uint32_t inNumber2,
												   MySampleStruct* outStruct, uint32_t* outStructSize)
{
	IOReturn	result;

	IOLog("%s[%p]::%s(inNumber1 = %d, inNumber2 = %d)\n", getName(), this, __FUNCTION__, inNumber1, inNumber2);

	if (fProvider == NULL || isInactive()) {
		// Return an error if we don't have a provider. This could happen if the user process
		// called ScalarIStructO without calling IOServiceOpen first. Or the user client could be
		// in the process of being terminated and is thus inactive.
		result = kIOReturnNotAttached;
	}
	else if (!fProvider->isOpen(this)) {
		// Return an error if we do not have the driver open. This could happen if the user process
		// did not call openUserClient before calling this function.
		result = kIOReturnNotOpen;
	}
	else {
		result = fProvider->ScalarIStructO(inNumber1, inNumber2, outStruct, outStructSize);

		// Note that fCrossEndian will always be false if running on a PowerPC-based Mac.
		if (fCrossEndian) {
			// Swap the fields of the structure returned by the driver before returning it to the client user process.
			// Use the unconditional swap macros here as we know only at runtime if we're being called from a
			// cross-endian user process running using Rosetta.

			outStruct->field1 = OSSwapInt64(outStruct->field1);
			outStruct->field2 = OSSwapInt64(outStruct->field2);

			IOLog("%s[%p]::%s(output after swap: field1 = %lld, field2 = %lld, outStructSize = %d)\n", getName(), this, __FUNCTION__,
				  outStruct->field1, outStruct->field2, *outStructSize);
		}
	}

	return result;
}


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sScalarIScalarO(SimpleDriverClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->ScalarIScalarO((uint32_t) arguments->scalarInput[0],
								  (uint32_t) arguments->scalarInput[1],
								  (uint32_t*) &arguments->scalarOutput[0]);
}
#endif


#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
IOReturn SimpleUserClientClassName::sStructIStructO(SimpleUserClientClassName* target, void* reference, IOExternalMethodArguments* arguments)
{
    return target->StructIStructO((MySampleStruct*) arguments->structureInput,
								  (MySampleStruct*) arguments->structureOutput,
								  (uint32_t) arguments->structureInputSize,
								  (uint32_t*) &arguments->structureOutputSize);
}
#endif


IOReturn SimpleUserClientClassName::StructIStructO(MySampleStruct* inStruct, MySampleStruct* outStruct,
												   uint32_t inStructSize, uint32_t* outStructSize)
{
	IOReturn	result;

	IOLog("%s[%p]::%s(field1 = %lld, field2 = %lld, inStructSize = %d)\n", getName(), this, __FUNCTION__,
			inStruct->field1, inStruct->field2, inStructSize);

	if (fProvider == NULL || isInactive()) {
		// Return an error if we don't have a provider. This could happen if the user process
		// called StructIStructO without calling IOServiceOpen first. Or, the user client could be
		// in the process of being terminated and is thus inactive.
		result = kIOReturnNotAttached;
	}
	else if (!fProvider->isOpen(this)) {
		// Return an error if we do not have the driver open. This could happen if the user process
		// did not call openUserClient before calling this function.
		result = kIOReturnNotOpen;
	}
	else {
		// Note that fCrossEndian will always be false if running on a PowerPC-based Mac.
		if (fCrossEndian) {
			// Swap the fields of the structure returned by the driver before returning it to the client user process.
			// Use the unconditional swap macros here as we know only at runtime if we're being called from a
			// cross-endian user process running using Rosetta.

			inStruct->field1 = OSSwapInt64(inStruct->field1);
			inStruct->field2 = OSSwapInt64(inStruct->field2);
			
			IOLog("%s[%p]::%s(input after swap: field1 = %lld, field2 = %lld, inStructSize = %d)\n", getName(), this, __FUNCTION__,
				inStruct->field1, inStruct->field2, inStructSize);
		}
		
		result = fProvider->StructIStructO(inStruct, outStruct, inStructSize, outStructSize);

		if (fCrossEndian) {
			// Swap the results returned by the driver before returning them to the client user process.
			outStruct->field1 = OSSwapInt64(outStruct->field1);
			outStruct->field2 = OSSwapInt64(outStruct->field2);

			IOLog("%s[%p]::%s(output after swap: field1 = %lld, field2 = %lld, outStructSize = %d)\n", getName(), this, __FUNCTION__,
				  outStruct->field1, outStruct->field2, *outStructSize);
		}
	}
    
    return result;
}
