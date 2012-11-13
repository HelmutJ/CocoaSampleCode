/*
     File: SimpleAudioDriverUserClient.cpp
 Abstract: SimpleAudioDriverUserClient.h
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
*/
/*==================================================================================================
	SimpleAudioDriverUserClient.cpp
==================================================================================================*/

//==================================================================================================
//	Includes
//==================================================================================================

//	Self Include
#include "SimpleAudioDriverUserClient.h"

//	System Includes
#include <IOKit/IOBufferMemoryDescriptor.h>

//==================================================================================================
//	SimpleAudioDriver
//==================================================================================================

OSDefineMetaClassAndStructors(com_apple_audio_SimpleAudioDriverUserClient, IOUserClient)

bool SimpleAudioDriverUserClient::initWithTask(task_t inOwningTask, void* inSecurityToken, UInt32 inType, OSDictionary* inProperties)
{
	mTask = inOwningTask;
	mProvider = NULL;
	return IOUserClient::initWithTask(inOwningTask, inSecurityToken, inType, inProperties);
}

bool SimpleAudioDriverUserClient::start(IOService* inProvider)
{
	mProvider = OSDynamicCast(SimpleAudioDriver, inProvider);
	return (mProvider != NULL) && IOUserClient::start(inProvider);
}

bool SimpleAudioDriverUserClient::didTerminate(IOService* inProvider, IOOptionBits inOptions, bool* outDefer)
{
	if((mProvider != NULL) && (inProvider == mProvider))
	{
		if(mProvider->isOpen(this))
		{
			mProvider->stopHardware();
			mProvider->close(this);
		}
	}
	*outDefer = false;
	
	return IOUserClient::didTerminate(inProvider, inOptions, outDefer);
}

IOReturn SimpleAudioDriverUserClient::clientClose()
{
	if(mProvider->isOpen(this))
	{
		mProvider->stopHardware();
		mProvider->close(this);
	}
	terminate();
	return kIOReturnSuccess;
}

IOReturn SimpleAudioDriverUserClient::externalMethod(uint32_t inSelector, IOExternalMethodArguments* inArguments, IOExternalMethodDispatch* inDispatch, OSObject* inTarget, void* inReference)
{
	if(inSelector < static_cast<uint32_t>(kSimpleAudioDriver_Method_NumberOfMethods))
	{
		inDispatch = const_cast<IOExternalMethodDispatch*>(&sMethodTable[inSelector]);
		if(inTarget == NULL)
		{
			inTarget = this;
		}
	}
	return IOUserClient::externalMethod(inSelector, inArguments, inDispatch, inTarget, inReference);
}

IOReturn SimpleAudioDriverUserClient::clientMemoryForType(UInt32 inType, IOOptionBits* outOptions, IOMemoryDescriptor** outMemory)
{
	IOReturn theAnswer = kIOReturnSuccess;
	FailIfNULL(mProvider, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::clientMemoryForType: no provider");
	switch(inType)
	{
		case kSimpleAudioDriver_Buffer_Status:
		case kSimpleAudioDriver_Buffer_Input:
		case kSimpleAudioDriver_Buffer_Output:
			*outOptions = 0;
			*outMemory = mProvider->getBuffer(inType);
			if(*outMemory != NULL)
			{
				(*outMemory)->retain();
			}
			break;
		
		default:
			DebugMsg("SimpleAudioDriverUserClient::clientMemoryForType: unknown memory type: %u", inType);
			theAnswer = kIOReturnBadArgument;
			break;
	};
	
Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_Open(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference, inArguments)
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	make sure the target pointer is really a user client
	SimpleAudioDriverUserClient* theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_Open: not a user client");
	
	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_Open: no provider");
	FailIf(theUserClient->isInactive(), theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_Open: is inactive");
	
	//	tell the driver to open the user client
	if(!theUserClient->mProvider->open(theUserClient))
	{
        theAnswer = kIOReturnExclusiveAccess;
	}

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_Close(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference, inArguments)
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	make sure the target pointer is really a user client
	SimpleAudioDriverUserClient* theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_Close: not a user client");

	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_Close: no provider");
	
	//	tell the driver to close the user client
	if(theUserClient->mProvider->isOpen(theUserClient))
	{
		theUserClient->mProvider->stopHardware();
		theUserClient->mProvider->close(theUserClient);
	}
	else
	{
		theAnswer = kIOReturnNotOpen;
	}

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_StartHardware(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference, inArguments)
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	make sure the target pointer is really a user client
	SimpleAudioDriverUserClient* theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_StartHardware: not a user client");
	
	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_StartHardware: no provider");
	
	//	tell the driver to start the hardware
	theAnswer = theUserClient->mProvider->startHardware();

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_StopHardware(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference, inArguments)
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	make sure the target pointer is really a user client
	SimpleAudioDriverUserClient* theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_StopHardware: not a user client");

	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_StopHardware: no provider");
	
	//	tell the driver to start the hardware
	theUserClient->mProvider->stopHardware();

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_SetSampleRate(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriverUserClient* theUserClient = NULL;
	UInt64 theNewSampleRate = 0;
	
	//	make sure the target pointer is really a user client
	theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_SetSampleRate: not a user client");

	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_SetSampleRate: no provider");
	
	//	pull the arguments apart
	theNewSampleRate = inArguments->scalarInput[0];
	
	//	tell the driver to change the sample rate
	theAnswer = theUserClient->mProvider->setSampleRate(theNewSampleRate);

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_GetControlValue(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriverUserClient* theUserClient = NULL;
	int theControlID = 0;
	UInt32 theControlValue = 0;
	UInt64* theReturnedControlValue = NULL;
	
	//	make sure the target pointer is really a user client
	theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_GetControlValue: not a user client");

	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_GetControlValue: no provider");
	
	//	pull the arguments apart
	theControlID = static_cast<int>(inArguments->scalarInput[0]);
	theReturnedControlValue = &inArguments->scalarOutput[0];
	
	//	get the control value from driver
	switch(theControlID)
	{
		case kSimpleAudioDriver_Control_MasterInputVolume:
		case kSimpleAudioDriver_Control_MasterOutputVolume:
			theUserClient->mProvider->getVolume(theControlID, theControlValue);
			*theReturnedControlValue = theControlValue;
			break;
		
		default:
			theAnswer = kIOReturnBadArgument;
			break;
	};

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriverUserClient::method_SetControlValue(OSObject* inTarget, void* inReference, IOExternalMethodArguments* inArguments)
{
	#pragma unused(inReference)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriverUserClient* theUserClient = NULL;
	int theControlID = 0;
	UInt16 theNewControlValue = 0;
	
	//	make sure the target pointer is really a user client
	theUserClient = OSDynamicCast(SimpleAudioDriverUserClient, inTarget);
	FailIfNULL(theUserClient, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriverUserClient::method_SetControlValue: not a user client");

	//	make sure the user client is in the proper state
	FailIf(theUserClient->mProvider == NULL, theAnswer = kIOReturnNotAttached, Done, "SimpleAudioDriverUserClient::method_GetControlValue: no provider");
	
	//	pull the arguments apart
	theControlID = static_cast<int>(inArguments->scalarInput[0]);
	theNewControlValue = static_cast<UInt16>(inArguments->scalarInput[1]);
	
	//	tell the driver to change the control value
	switch(theControlID)
	{
		case kSimpleAudioDriver_Control_MasterInputVolume:
		case kSimpleAudioDriver_Control_MasterOutputVolume:
			theAnswer = theUserClient->mProvider->setVolume(theControlID, theNewControlValue);
			break;
		
		default:
			theAnswer = kIOReturnBadArgument;
			break;
	};

Done:
	return theAnswer;
}

const IOExternalMethodDispatch SimpleAudioDriverUserClient::sMethodTable[kSimpleAudioDriver_Method_NumberOfMethods] =
{
	//	kSimpleAudioDriver_Method_Open
	{
		SimpleAudioDriverUserClient::method_Open,				//	Method pointer
		0,														//	No scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_Close
	{
		SimpleAudioDriverUserClient::method_Close,				//	Method pointer
		0,														//	No scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_StartHardware
	{
		SimpleAudioDriverUserClient::method_StartHardware,		//	Method pointer
		0,														//	No scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_StopHardware
	{
		SimpleAudioDriverUserClient::method_StopHardware,		//	Method pointer
		0,														//	No scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_SetSampleRate
	{
		SimpleAudioDriverUserClient::method_SetSampleRate,		//	Method pointer
		1,														//	1 scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_GetControlValue
	{
		SimpleAudioDriverUserClient::method_GetControlValue,	//	Method pointer
		1,														//	1 scalar input value
		0,														//	No struct input value
		1,														//	1 scalar output value
		0														//	No struct output value
	},
	//	kSimpleAudioDriver_Method_SetControlValue
	{
		SimpleAudioDriverUserClient::method_SetControlValue,	//	Method pointer
		2,														//	2 scalar input values
		0,														//	No struct input value
		0,														//	No scalar output values
		0														//	No struct output value
	}
};

