/*
     File: SA_PlugIn.cpp
 Abstract: SA_PlugIn.h
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
	SA_PlugIn.cpp
==================================================================================================*/

//==================================================================================================
//	Includes
//==================================================================================================

//	Self Include
#include "SA_PlugIn.h"

//	Local Includes
#include "SA_Device.h"
#include "SA_IOKit.h"
#include "SimpleAudioDriverTypes.h"

//	PublicUtility Includes
#include "CADebugMacros.h"
#include "CAException.h"

//	System Includes
#include <IOKit/IOMessage.h>

//==================================================================================================
//	SA_PlugIn
//==================================================================================================

SA_PlugIn&	SA_PlugIn::GetInstance()
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	return *sInstance;
}

SA_PlugIn::SA_PlugIn()
:
	SA_Object(kAudioObjectPlugInObject, kAudioPlugInClassID, kAudioObjectClassID, 0),
	mDeviceInfoList(),
	mIOKitNotificationPort(NULL),
	mMatchingNotification(IO_OBJECT_NULL),
	mDispatchQueue("SA_PlugIn"),
	mMutex("SA_PlugIn")
{
}

SA_PlugIn::~SA_PlugIn()
{
}

void	SA_PlugIn::Activate()
{
	_StartDeviceListNotifications();
	SA_Object::Activate();
}

void	SA_PlugIn::Deactivate()
{
	CAMutex::Locker theLocker(mMutex);
	SA_Object::Deactivate();
	_StopDeviceListNotifications();
	_RemoveAllDevices();
}

void	SA_PlugIn::StaticInitializer()
{
	try
	{
		sInstance = new SA_PlugIn;
		SA_ObjectMap::MapObject(kAudioObjectPlugInObject, sInstance);
		sInstance->Activate();
	}
	catch(...)
	{
		DebugMsg("SA_PlugIn::StaticInitializer: failed to create the plug-in");
		delete sInstance;
		sInstance = NULL;
	}
}

bool	SA_PlugIn::HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const
{
	bool theAnswer = false;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyManufacturer:
		case kAudioPlugInPropertyDeviceList:
		case kAudioPlugInPropertyTranslateUIDToDevice:
		case kAudioPlugInPropertyResourceBundle:
			theAnswer = (inAddress.mScope == kAudioObjectPropertyScopeGlobal) && (inAddress.mElement == kAudioObjectPropertyElementMaster);
			break;
		
		default:
			theAnswer = SA_Object::HasProperty(inObjectID, inClientPID, inAddress);
	};
	return theAnswer;
}

bool	SA_PlugIn::IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const
{
	bool theAnswer = false;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyManufacturer:
		case kAudioPlugInPropertyDeviceList:
		case kAudioPlugInPropertyTranslateUIDToDevice:
		case kAudioPlugInPropertyResourceBundle:
			theAnswer = false;
			break;
		
		default:
			theAnswer = SA_Object::IsPropertySettable(inObjectID, inClientPID, inAddress);
	};
	return theAnswer;
}

UInt32	SA_PlugIn::GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const
{
	UInt32 theAnswer = 0;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyManufacturer:
			theAnswer = sizeof(CFStringRef);
			break;
			
		case kAudioObjectPropertyOwnedObjects:
		case kAudioPlugInPropertyDeviceList:
			{
				CAMutex::Locker theLocker(mMutex);
				theAnswer = static_cast<UInt32>(mDeviceInfoList.size() * sizeof(AudioObjectID));
			}
			break;
			
		case kAudioPlugInPropertyTranslateUIDToDevice:
			theAnswer = sizeof(AudioObjectID);
			break;
			
		case kAudioPlugInPropertyResourceBundle:
			theAnswer = sizeof(CFStringRef);
			break;
		
		default:
			theAnswer = SA_Object::GetPropertyDataSize(inObjectID, inClientPID, inAddress, inQualifierDataSize, inQualifierData);
	};
	return theAnswer;
}

void	SA_PlugIn::GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const
{
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyManufacturer:
			//	This is the human readable name of the maker of the plug-in.
			ThrowIf(inDataSize < sizeof(CFStringRef), CAException(kAudioHardwareBadPropertySizeError), "SA_PlugIn::GetPropertyData: not enough space for the return value of kAudioObjectPropertyManufacturer");
			*reinterpret_cast<CFStringRef*>(outData) = CFSTR("Apple Inc.");
			outDataSize = sizeof(CFStringRef);
			break;
			
		case kAudioObjectPropertyOwnedObjects:
		case kAudioPlugInPropertyDeviceList:
			//	The plug-in object only owns devices, so the the owned object list and the device
			//	list are actually the same thing. We need to be holding the mutex to access the
			//	device info list.
			{
				CAMutex::Locker theLocker(mMutex);
				
				//	Calculate the number of items that have been requested. Note that this
				//	number is allowed to be smaller than the actual size of the list. In such
				//	case, only that number of items will be returned
				UInt32 theNumberItemsToFetch = static_cast<UInt32>(std::min(inDataSize / sizeof(AudioObjectID), mDeviceInfoList.size()));
				
				//	go through the device list and copy out the devices' object IDs
				AudioObjectID* theReturnedDeviceList = reinterpret_cast<AudioObjectID*>(outData);
				for(UInt32 theDeviceIndex = 0; theDeviceIndex < theNumberItemsToFetch; ++theDeviceIndex)
				{
					theReturnedDeviceList[theDeviceIndex] = mDeviceInfoList[theDeviceIndex].mDeviceObjectID;
				}
				
				//	say how much we returned
				outDataSize = theNumberItemsToFetch * sizeof(AudioObjectID);
			}
			break;
			
		case kAudioPlugInPropertyTranslateUIDToDevice:
			//	This property translates the UID passed in the qualifier as a CFString into the
			//	AudioObjectID for the device the UID refers to or kAudioObjectUnknown if no device
			//	has the UID.
			ThrowIf(inQualifierDataSize < sizeof(CFStringRef), CAException(kAudioHardwareBadPropertySizeError), "SA_PlugIn::GetPropertyData: the qualifier size is too small for kAudioPlugInPropertyTranslateUIDToDevice");
			ThrowIf(inDataSize < sizeof(AudioObjectID), CAException(kAudioHardwareBadPropertySizeError), "SA_PlugIn::GetPropertyData: not enough space for the return value of kAudioPlugInPropertyTranslateUIDToDevice");
			outDataSize = sizeof(AudioObjectID);
			break;
			
		case kAudioPlugInPropertyResourceBundle:
			//	The resource bundle is a path relative to the path of the plug-in's bundle.
			//	To specify that the plug-in bundle itself should be used, we just return the
			//	empty string.
			ThrowIf(inDataSize < sizeof(AudioObjectID), CAException(kAudioHardwareBadPropertySizeError), "SA_GetPlugInPropertyData: not enough space for the return value of kAudioPlugInPropertyResourceBundle");
			*reinterpret_cast<CFStringRef*>(outData) = CFSTR("");
			outDataSize = sizeof(CFStringRef);
			break;
		
		default:
			SA_Object::GetPropertyData(inObjectID, inClientPID, inAddress, inQualifierDataSize, inQualifierData, inDataSize, outDataSize, outData);
			break;
	};
}

void	SA_PlugIn::SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData)
{
	switch(inAddress.mSelector)
	{
		default:
			SA_Object::SetPropertyData(inObjectID, inClientPID, inAddress, inQualifierDataSize, inQualifierData, inDataSize, inData);
			break;
	};
}

void	SA_PlugIn::_StartDeviceListNotifications()
{
	if((mIOKitNotificationPort == NULL) && (mMatchingNotification == IO_OBJECT_NULL))
	{
		try
		{
			//	get the IOKit master port
			mach_port_t theMasterPort = MACH_PORT_NULL;
			kern_return_t theKernelError = IOMasterPort(bootstrap_port, &theMasterPort);
			ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_PlugIn::_StartDeviceListNotifications: IOMasterPort failed");
			
			//  create an IOKit notification port
			mIOKitNotificationPort = IONotificationPortCreate(theMasterPort);
			ThrowIfNULL(mIOKitNotificationPort, CAException(kAudioHardwareUnspecifiedError), "SA_PlugIn::_StartDeviceListNotifications: IONotificationPortCreate failed");

			//	tell the port to use our command gate's dispatch queue
			IONotificationPortSetDispatchQueue(mIOKitNotificationPort, mDispatchQueue.GetDispatchQueue());

			//  create a matching dictionary for 
			CFDictionaryRef theMatchingDictionary = IOServiceMatching(kSimpleAudioDriverClassName);
			ThrowIfNULL(theMatchingDictionary, CAException(kAudioHardwareUnspecifiedError), "SA_PlugIn::_StartDeviceListNotifications: IOServiceMatching failed");
			
			//	sign up for notification for when new IOAudioEngines show up (this consumes a ref on theMatchingDictionary)
			theKernelError = IOServiceAddMatchingNotification(mIOKitNotificationPort, kIOFirstPublishNotification, theMatchingDictionary, IOServiceMatchingHandler, GetObjectIDAsPtr(), &mMatchingNotification);
			ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_PlugIn::_StartDeviceListNotifications: IOServiceAddMatchingNotification failed");
			
			//	create the devices indicated by the returned io_iterator_t
			IOServiceMatchingHandler(GetObjectIDAsPtr(), mMatchingNotification);
		}
		catch(...)
		{
			//	release the IOKit notification object
			if(mMatchingNotification != IO_OBJECT_NULL)
			{
				IOObjectRelease(mMatchingNotification);
				mMatchingNotification = IO_OBJECT_NULL;
			}
			
			//	release the IOKit notification port
			if(mIOKitNotificationPort != NULL)
			{
				IONotificationPortDestroy(mIOKitNotificationPort);
				mIOKitNotificationPort = NULL;
			}
			
			//	rethrow the exception
			throw;
		}
	}
}

void	SA_PlugIn::_StopDeviceListNotifications()
{
	//	release the IOKit notification object
	if(mMatchingNotification != IO_OBJECT_NULL)
	{
		IOObjectRelease(mMatchingNotification);
		mMatchingNotification = IO_OBJECT_NULL;
	}
	
	//	release the IOKit notification port
	if(mIOKitNotificationPort)
	{
		IONotificationPortDestroy(mIOKitNotificationPort);
		mIOKitNotificationPort = NULL;
	}
}

void	SA_PlugIn::AddDevice(SA_Device* inDevice)
{
	CAMutex::Locker theLocker(mMutex);
	_AddDevice(inDevice);
}

void	SA_PlugIn::RemoveDevice(SA_Device* inDevice)
{
	CAMutex::Locker theLocker(mMutex);
	_RemoveDevice(inDevice);
}

SA_Device*	SA_PlugIn::CopyDeviceByIOObject(io_object_t inIOObject)
{
	CAMutex::Locker theLocker(mMutex);
	return _CopyDeviceByIOObject(inIOObject);
}

void	SA_PlugIn::_AddDevice(SA_Device* inDevice)
{
	if(inDevice != NULL)
	{
		//  Initialize an DeviceInfo to describe the new device
		DeviceInfo theDeviceInfo(inDevice->GetObjectID());
		
		//  Set up the interest notification
		kern_return_t theKernelError = IOServiceAddInterestNotification(mIOKitNotificationPort, inDevice->GetIOKitObject(), kIOGeneralInterest, IOServiceInterestHandler, GetObjectIDAsPtr(), &theDeviceInfo.mInterestNotification);
		ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_PlugIn::_AddDevice: Cannot add an interest callback.");

		//	tell the port to use our command gate's dispatch queue
		IONotificationPortSetDispatchQueue(mIOKitNotificationPort, mDispatchQueue.GetDispatchQueue());
		
		//  put the device info in the list
		mDeviceInfoList.push_back(theDeviceInfo);
	}
}

void	SA_PlugIn::_RemoveDevice(SA_Device* inDevice)
{
	//  find it in the device list and grab an iterator for it
	if(inDevice != NULL)
	{
		bool wasFound = false;
		DeviceInfoList::iterator theDeviceIterator = mDeviceInfoList.begin();
		while(!wasFound && (theDeviceIterator != mDeviceInfoList.end()))
		{
			if(inDevice->GetObjectID() == theDeviceIterator->mDeviceObjectID)
			{
				wasFound = true;
				
				//  clean up the interest notification
				IOObjectRelease(theDeviceIterator->mInterestNotification);
				theDeviceIterator->mInterestNotification = IO_OBJECT_NULL;
				
				//  remove the device from the list
				theDeviceIterator->mDeviceObjectID = 0;
				mDeviceInfoList.erase(theDeviceIterator);
			}
			else
			{
				++theDeviceIterator;
			}
		}
	}
}

void	SA_PlugIn::_RemoveAllDevices()
{
	//	spin through the device list
	for(DeviceInfoList::iterator theDeviceIterator = mDeviceInfoList.begin(); theDeviceIterator != mDeviceInfoList.end(); ++theDeviceIterator)
	{
		//	clean up the interest notification
		IOObjectRelease(theDeviceIterator->mInterestNotification);
		theDeviceIterator->mInterestNotification = IO_OBJECT_NULL;
		
		//	remove the object from the list
		AudioObjectID theDeadDeviceObjectID = theDeviceIterator->mDeviceObjectID;
		theDeviceIterator->mDeviceObjectID = 0;
		
		//	asynchronously get rid of the device since we are holding the plug-in's state lock
		CADispatchQueue::GetGlobalSerialQueue().Dispatch(false,	^{
																	CATry;
																	//	resolve the device ID to an object
																	SA_ObjectReleaser<SA_Device> theDeadDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(theDeadDeviceObjectID));
																	if(theDeadDevice.IsValid())
																	{
																		//	deactivate the device
																		theDeadDevice->Deactivate();
																		
																		//	and release it
																		SA_ObjectMap::ReleaseObject(theDeadDevice);
																	}
																	CACatch;
																});
	}
}

SA_Device*	SA_PlugIn::_CopyDeviceByIOObject(io_object_t inIOObject)
{
	//	Because of the vagaries of IOKit notifications, it is quite often the case that the actual
	//	value of the io_object_t to look up will not actually match any of the io_object_t's that
	//	we've seen before. So to do the matching here, we look up an IORegistry property that is
	//	different for each device, like the device UID property, and see if that matches anything
	//	we know about.

	SA_Device* theAnswer = NULL;
	CACFString theDeviceUIDToFind(SA_Device::HW_CopyDeviceUID(inIOObject));
	if(theDeviceUIDToFind.IsValid())
	{
		DeviceInfoList::iterator theDeviceIterator = mDeviceInfoList.begin();
		while((theAnswer == NULL) && (theDeviceIterator != mDeviceInfoList.end()))
		{
			SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(theDeviceIterator->mDeviceObjectID));
			if(theDevice.IsValid())
			{
				CACFString theDeviceUID(theDevice->CopyDeviceUID());
				if(theDeviceUIDToFind == theDeviceUID)
				{
					theAnswer = theDevice;
					SA_ObjectMap::RetainObject(theAnswer);
				}
			}
			++theDeviceIterator;
		}
	}
	return theAnswer;
}

void	SA_PlugIn::IOServiceMatchingHandler(void* inContext, io_iterator_t inIterator)
{
	bool deviceWasAdded = false;
	SA_ObjectReleaser<SA_PlugIn> thePlugIn(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_PlugIn>(static_cast<AudioObjectID>(reinterpret_cast<uintptr_t>(inContext))));
	ThrowIf(!thePlugIn.IsValid(), CAException(kAudioHardwareIllegalOperationError), "SA_PlugIn::IOServiceMatchingHandler: no plug-in object");
	
	SA_IOKitIterator theIterator(inIterator, false);
	SA_IOKitObject theService(theIterator.Next());
	while(theService.IsValid())
	{
		if(theService.ConformsTo(kSimpleAudioDriverClassName))
		{
			//	Note that we catch all exceptions here so that we can finish processing the items in the notification
			SA_Device* theNewDevice = NULL;
			try
			{
				//	make the new device object
				AudioObjectID theNewDeviceObjectID = SA_ObjectMap::GetNextObjectID();
				theNewDevice = new SA_Device(theNewDeviceObjectID, theService.CopyObject());
				
				//	add it to the object map
				SA_ObjectMap::MapObject(theNewDeviceObjectID, theNewDevice);
				
				//	add it to the device list
				thePlugIn->AddDevice(theNewDevice);
				
				//	activate the device
				theNewDevice->Activate();
				
				deviceWasAdded = true;
			}
			catch(...)
			{
				thePlugIn->RemoveDevice(theNewDevice);
				SA_ObjectMap::ReleaseObject(theNewDevice);
			}
		}

		theService = theIterator.Next();
	}
	
	if(deviceWasAdded)
	{
		//	this will change the owned object list and the device list
		AudioObjectPropertyAddress theChangedProperties[] {	{ kAudioObjectPropertyOwnedObjects, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster },
															{ kAudioPlugInPropertyDeviceList, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster } };
		Host_PropertiesChanged(thePlugIn->GetObjectID(), 2, theChangedProperties);
	}
}

void	SA_PlugIn::IOServiceInterestHandler(void* inContext, io_service_t inService, natural_t inMessageType, void*)
{
	if((inService != IO_OBJECT_NULL) && (inService != MACH_PORT_DEAD) && (inMessageType == kIOMessageServiceIsTerminated))
	{
		CATry;
		
		//	get the plug-in object
		SA_ObjectReleaser<SA_PlugIn> thePlugIn(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_PlugIn>(static_cast<AudioObjectID>(reinterpret_cast<uintptr_t>(inContext))));
		ThrowIf(!thePlugIn.IsValid(), CAException(kAudioHardwareIllegalOperationError), "SA_PlugIn::IOServiceInterestHandler: no plug-in object");
		
		//	get the dead device
		SA_ObjectReleaser<SA_Device> theDeadDevice(thePlugIn->CopyDeviceByIOObject(inService));
		if(theDeadDevice.IsValid())
		{
			//	remove it from our list
			thePlugIn->RemoveDevice(theDeadDevice);
			
			//	deactivate the device
			theDeadDevice->Deactivate();
			
			//	release it
			SA_ObjectMap::ReleaseObject(theDeadDevice);
			
			//	this will change the owned object list and the device list
			AudioObjectPropertyAddress theChangedProperties[] {	{ kAudioObjectPropertyOwnedObjects, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster },
																{ kAudioPlugInPropertyDeviceList, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster } };
			Host_PropertiesChanged(thePlugIn->GetObjectID(), 2, theChangedProperties);
		}
	
		CACatch;
	}
}

pthread_once_t				SA_PlugIn::sStaticInitializer = PTHREAD_ONCE_INIT;
SA_PlugIn*					SA_PlugIn::sInstance = NULL;
AudioServerPlugInHostRef	SA_PlugIn::sHost = NULL;

#pragma mark COM Prototypes

//	Entry points for the COM methods
extern "C" void*	SA_Create(CFAllocatorRef inAllocator, CFUUIDRef inRequestedTypeUUID);
static HRESULT		SA_QueryInterface(void* inDriver, REFIID inUUID, LPVOID* outInterface);
static ULONG		SA_AddRef(void* inDriver);
static ULONG		SA_Release(void* inDriver);
static OSStatus		SA_Initialize(AudioServerPlugInDriverRef inDriver, AudioServerPlugInHostRef inHost);
static OSStatus		SA_CreateDevice(AudioServerPlugInDriverRef inDriver, CFDictionaryRef inDescription, const AudioServerPlugInClientInfo* inClientInfo, AudioObjectID* outDeviceObjectID);
static OSStatus		SA_DestroyDevice(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID);
static OSStatus		SA_AddDeviceClient(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, const AudioServerPlugInClientInfo* inClientInfo);
static OSStatus		SA_RemoveDeviceClient(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, const AudioServerPlugInClientInfo* inClientInfo);
static OSStatus		SA_PerformDeviceConfigurationChange(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo);
static OSStatus		SA_AbortDeviceConfigurationChange(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo);
static Boolean		SA_HasProperty(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress);
static OSStatus		SA_IsPropertySettable(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, Boolean* outIsSettable);
static OSStatus		SA_GetPropertyDataSize(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32* outDataSize);
static OSStatus		SA_GetPropertyData(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32* outDataSize, void* outData);
static OSStatus		SA_SetPropertyData(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);
static OSStatus		SA_StartIO(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID);
static OSStatus		SA_StopIO(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID);
static OSStatus		SA_GetZeroTimeStamp(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, Float64* outSampleTime, UInt64* outHostTime, UInt64* outSeed);
static OSStatus		SA_WillDoIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, Boolean* outWillDo, Boolean* outWillDoInPlace);
static OSStatus		SA_BeginIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo);
static OSStatus		SA_DoIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, AudioObjectID inStreamObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo, void* ioMainBuffer, void* ioSecondaryBuffer);
static OSStatus		SA_EndIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo);

#pragma mark The COM Interface

static AudioServerPlugInDriverInterface	gAudioServerPlugInDriverInterface =
{
	NULL,
	SA_QueryInterface,
	SA_AddRef,
	SA_Release,
	SA_Initialize,
	SA_CreateDevice,
	SA_DestroyDevice,
	SA_AddDeviceClient,
	SA_RemoveDeviceClient,
	SA_PerformDeviceConfigurationChange,
	SA_AbortDeviceConfigurationChange,
	SA_HasProperty,
	SA_IsPropertySettable,
	SA_GetPropertyDataSize,
	SA_GetPropertyData,
	SA_SetPropertyData,
	SA_StartIO,
	SA_StopIO,
	SA_GetZeroTimeStamp,
	SA_WillDoIOOperation,
	SA_BeginIOOperation,
	SA_DoIOOperation,
	SA_EndIOOperation
};
static AudioServerPlugInDriverInterface*	gAudioServerPlugInDriverInterfacePtr	= &gAudioServerPlugInDriverInterface;
static AudioServerPlugInDriverRef			gAudioServerPlugInDriverRef				= &gAudioServerPlugInDriverInterfacePtr;
static UInt32								gAudioServerPlugInDriverRefCount		= 1;

#pragma mark Factory

extern "C"
void*	SA_Create(CFAllocatorRef inAllocator, CFUUIDRef inRequestedTypeUUID)
{
	//	This is the CFPlugIn factory function. Its job is to create the implementation for the given
	//	type provided that the type is supported. Because this driver is simple and all its
	//	initialization is handled via static iniitalization when the bundle is loaded, all that
	//	needs to be done is to return the AudioServerPlugInDriverRef that points to the driver's
	//	interface. A more complicated driver would create any base line objects it needs to satisfy
	//	the IUnknown methods that are used to discover that actual interface to talk to the driver.
	//	The majority of the driver's initilization should be handled in the Initialize() method of
	//	the driver's AudioServerPlugInDriverInterface.
	
	#pragma unused(inAllocator)
    void* theAnswer = NULL;
    if(CFEqual(inRequestedTypeUUID, kAudioServerPlugInTypeUUID))
    {
		theAnswer = gAudioServerPlugInDriverRef;
		SA_PlugIn::GetInstance();
    }
    return theAnswer;
}

#pragma mark Inheritence

static HRESULT	SA_QueryInterface(void* inDriver, REFIID inUUID, LPVOID* outInterface)
{
	//	This function is called by the HAL to get the interface to talk to the plug-in through.
	//	AudioServerPlugIns are required to support the IUnknown interface and the
	//	AudioServerPlugInDriverInterface. As it happens, all interfaces must also provide the
	//	IUnknown interface, so we can always just return the single interface we made with
	//	gAudioServerPlugInDriverInterfacePtr regardless of which one is asked for.

	//	declare the local variables
	HRESULT theAnswer = 0;
	
	try
	{
		//	validate the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_QueryInterface: bad driver reference");
		ThrowIfNULL(outInterface, CAException(kAudioHardwareIllegalOperationError), "SA_QueryInterface: no place to store the returned interface");

		//	make a CFUUIDRef from inUUID
		CACFUUID theRequestedUUID(CFUUIDCreateFromUUIDBytes(NULL, inUUID));
		ThrowIf(!theRequestedUUID.IsValid(), CAException(kAudioHardwareIllegalOperationError), "SA_QueryInterface: failed to create the CFUUIDRef");

		//	AudioServerPlugIns only support two interfaces, IUnknown (which has to be supported by all
		//	CFPlugIns and AudioServerPlugInDriverInterface (which is the actual interface the HAL will
		//	use).
		ThrowIf(!CFEqual(theRequestedUUID.GetCFObject(), IUnknownUUID) && !CFEqual(theRequestedUUID.GetCFObject(), kAudioServerPlugInDriverInterfaceUUID), CAException(E_NOINTERFACE), "SA_QueryInterface: requested interface is unsupported");
		ThrowIf(gAudioServerPlugInDriverRefCount == UINT32_MAX, CAException(E_NOINTERFACE), "SA_QueryInterface: the ref count is maxxed out");
		
		//	do the work
		++gAudioServerPlugInDriverRefCount;
		*outInterface = gAudioServerPlugInDriverRef;
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
		
	return theAnswer;
}

static ULONG	SA_AddRef(void* inDriver)
{
	//	This call returns the resulting reference count after the increment.
	
	//	declare the local variables
	ULONG theAnswer = 0;
	
	//	check the arguments
	FailIf(inDriver != gAudioServerPlugInDriverRef, Done, "SA_AddRef: bad driver reference");
	FailIf(gAudioServerPlugInDriverRefCount == UINT32_MAX, Done, "SA_AddRef: out of references");

	//	increment the refcount
	++gAudioServerPlugInDriverRefCount;
	theAnswer = gAudioServerPlugInDriverRefCount;

Done:
	return theAnswer;
}

static ULONG	SA_Release(void* inDriver)
{
	//	This call returns the resulting reference count after the decrement.

	//	declare the local variables
	ULONG theAnswer = 0;
	
	//	check the arguments
	FailIf(inDriver != gAudioServerPlugInDriverRef, Done, "SA_Release: bad driver reference");
	FailIf(gAudioServerPlugInDriverRefCount == UINT32_MAX, Done, "SA_Release: out of references");

	//	decrement the refcount
	//	Note that we don't do anything special if the refcount goes to zero as the HAL
	//	will never fully release a plug-in it opens. We keep managing the refcount so that
	//	the API semantics are correct though.
	--gAudioServerPlugInDriverRefCount;
	theAnswer = gAudioServerPlugInDriverRefCount;

Done:
	return theAnswer;
}

#pragma mark Basic Operations

static OSStatus	SA_Initialize(AudioServerPlugInDriverRef inDriver, AudioServerPlugInHostRef inHost)
{
	//	The job of this method is, as the name implies, to get the driver initialized. One specific
	//	thing that needs to be done is to store the AudioServerPlugInHostRef so that it can be used
	//	later. Note that when this call returns, the HAL will scan the various lists the driver
	//	maintains (such as the device list) to get the inital set of objects the driver is
	//	publishing. So, there is no need to notifiy the HAL about any objects created as part of the
	//	execution of this method.

	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_Initialize: bad driver reference");
		
		//	store the AudioServerPlugInHostRef
		SA_PlugIn::GetInstance().SetHost(inHost);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}

	return theAnswer;
}

static OSStatus	SA_CreateDevice(AudioServerPlugInDriverRef inDriver, CFDictionaryRef inDescription, const AudioServerPlugInClientInfo* inClientInfo, AudioObjectID* outDeviceObjectID)
{
	//	This method is used to tell a driver that implements the Transport Manager semantics to
	//	create an AudioEndpointDevice from a set of AudioEndpoints. Since this driver is not a
	//	Transport Manager, we just return kAudioHardwareUnsupportedOperationError.
	
	#pragma unused(inDriver, inDescription, inClientInfo, outDeviceObjectID)
	
	return kAudioHardwareUnsupportedOperationError;
}

static OSStatus	SA_DestroyDevice(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID)
{
	//	This method is used to tell a driver that implements the Transport Manager semantics to
	//	destroy an AudioEndpointDevice. Since this driver is not a Transport Manager, we just check
	//	the arguments and return kAudioHardwareUnsupportedOperationError.
	
	#pragma unused(inDriver, inDeviceObjectID)
	
	return kAudioHardwareUnsupportedOperationError;
}

static OSStatus	SA_AddDeviceClient(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, const AudioServerPlugInClientInfo* inClientInfo)
{
	//	This method is used to inform the driver about a new client that is using the given device.
	//	This allows the device to act differently depending on who the client is. This driver does
	//	not need to track the clients using the device, so we just return successfully.
	
	#pragma unused(inDriver, inDeviceObjectID, inClientInfo)
	
	return 0;
}

static OSStatus	SA_RemoveDeviceClient(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, const AudioServerPlugInClientInfo* inClientInfo)
{
	//	This method is used to inform the driver about a client that is no longer using the given
	//	device. This driver does not track clients, so we just return successfully.
	
	#pragma unused(inDriver, inDeviceObjectID, inClientInfo)
	
	return 0;
}

static OSStatus	SA_PerformDeviceConfigurationChange(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo)
{
	//	This method is called to tell the device that it can perform the configuation change that it
	//	had requested via a call to the host method, RequestDeviceConfigurationChange(). The
	//	arguments, inChangeAction and inChangeInfo are the same as what was passed to
	//	RequestDeviceConfigurationChange().
	//
	//	The HAL guarantees that IO will be stopped while this method is in progress. The HAL will
	//	also handle figuring out exactly what changed for the non-control related properties. This
	//	means that the only notifications that would need to be sent here would be for either
	//	custom properties the HAL doesn't know about or for controls.
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_PerformDeviceConfigurationChange: bad driver reference");
		
		//	get the device object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_PerformDeviceConfigurationChange: unknown device");
		
		//	tell it to do the work
		theDevice->PerformConfigChange(inChangeAction, inChangeInfo);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_AbortDeviceConfigurationChange(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo)
{
	//	This method is called to tell the driver that a request for a config change has been denied.
	//	This provides the driver an opportunity to clean up any state associated with the request.

	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_PerformDeviceConfigurationChange: bad driver reference");
		
		//	get the device object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_PerformDeviceConfigurationChange: unknown device");
		
		//	tell it to do the work
		theDevice->AbortConfigChange(inChangeAction, inChangeInfo);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

#pragma mark Property Operations

static Boolean	SA_HasProperty(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress)
{
	//	This method returns whether or not the given object has the given property.
	
	//	declare the local variables
	Boolean theAnswer = false;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_HasProperty: bad driver reference");
		ThrowIfNULL(inAddress, CAException(kAudioHardwareIllegalOperationError), "SA_HasProperty: no address");
		
		//	get the object
		SA_ObjectReleaser<SA_Object> theObject(SA_ObjectMap::CopyObjectByObjectID(inObjectID));
		ThrowIf(!theObject.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_HasProperty: unknown object");
		
		//	tell it to do the work
		theAnswer = theObject->HasProperty(inObjectID, inClientProcessID, *inAddress);
	}
	catch(const CAException& inException)
	{
		theAnswer = false;
	}
	catch(...)
	{
		theAnswer = false;
	}

	return theAnswer;
}

static OSStatus	SA_IsPropertySettable(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, Boolean* outIsSettable)
{
	//	This method returns whether or not the given property on the object can have its value
	//	changed.
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_IsPropertySettable: bad driver reference");
		ThrowIfNULL(inAddress, CAException(kAudioHardwareIllegalOperationError), "SA_IsPropertySettable: no address");
		ThrowIfNULL(outIsSettable, CAException(kAudioHardwareIllegalOperationError), "SA_IsPropertySettable: no place to put the return value");
		
		//	get the object
		SA_ObjectReleaser<SA_Object> theObject(SA_ObjectMap::CopyObjectByObjectID(inObjectID));
		ThrowIf(!theObject.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_IsPropertySettable: unknown object");
		
		//	tell it to do the work
		if(theObject->HasProperty(inObjectID, inClientProcessID, *inAddress))
		{
			*outIsSettable = theObject->IsPropertySettable(inObjectID, inClientProcessID, *inAddress);
		}
		else
		{
			theAnswer = kAudioHardwareUnknownPropertyError;
		}
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_GetPropertyDataSize(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32* outDataSize)
{
	//	This method returns the byte size of the property's data.
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_GetPropertyDataSize: bad driver reference");
		ThrowIfNULL(inAddress, CAException(kAudioHardwareIllegalOperationError), "SA_GetPropertyDataSize: no address");
		ThrowIfNULL(outDataSize, CAException(kAudioHardwareIllegalOperationError), "SA_GetPropertyDataSize: no place to put the return value");
		
		//	get the object
		SA_ObjectReleaser<SA_Object> theObject(SA_ObjectMap::CopyObjectByObjectID(inObjectID));
		ThrowIf(!theObject.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_GetPropertyDataSize: unknown object");
		
		//	tell it to do the work
		if(theObject->HasProperty(inObjectID, inClientProcessID, *inAddress))
		{
			*outDataSize = theObject->GetPropertyDataSize(inObjectID, inClientProcessID, *inAddress, inQualifierDataSize, inQualifierData);
		}
		else
		{
			theAnswer = kAudioHardwareUnknownPropertyError;
		}
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}

	return theAnswer;
}

static OSStatus	SA_GetPropertyData(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32* outDataSize, void* outData)
{
	//	This method fetches the data for a given property
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_GetPropertyData: bad driver reference");
		ThrowIfNULL(inAddress, CAException(kAudioHardwareIllegalOperationError), "SA_GetPropertyData: no address");
		ThrowIfNULL(outDataSize, CAException(kAudioHardwareIllegalOperationError), "SA_GetPropertyData: no place to put the return value size");
		ThrowIfNULL(outData, CAException(kAudioHardwareIllegalOperationError), "SA_GetPropertyData: no place to put the return value");
		
		//	get the object
		SA_ObjectReleaser<SA_Object> theObject(SA_ObjectMap::CopyObjectByObjectID(inObjectID));
		ThrowIf(!theObject.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_GetPropertyData: unknown object");
		
		//	tell it to do the work
		if(theObject->HasProperty(inObjectID, inClientProcessID, *inAddress))
		{
			theObject->GetPropertyData(inObjectID, inClientProcessID, *inAddress, inQualifierDataSize, inQualifierData, inDataSize, *outDataSize, outData);
		}
		else
		{
			theAnswer = kAudioHardwareUnknownPropertyError;
		}
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}

	return theAnswer;
}

static OSStatus	SA_SetPropertyData(AudioServerPlugInDriverRef inDriver, AudioObjectID inObjectID, pid_t inClientProcessID, const AudioObjectPropertyAddress* inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData)
{
	//	This method changes the value of the given property

	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_SetPropertyData: bad driver reference");
		ThrowIfNULL(inAddress, CAException(kAudioHardwareIllegalOperationError), "SA_SetPropertyData: no address");
		
		//	get the object
		SA_ObjectReleaser<SA_Object> theObject(SA_ObjectMap::CopyObjectByObjectID(inObjectID));
		ThrowIf(!theObject.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_SetPropertyData: unknown object");
		
		//	tell it to do the work
		if(theObject->HasProperty(inObjectID, inClientProcessID, *inAddress))
		{
			if(theObject->IsPropertySettable(inObjectID, inClientProcessID, *inAddress))
			{
				theObject->SetPropertyData(inObjectID, inClientProcessID, *inAddress, inQualifierDataSize, inQualifierData, inDataSize, inData);
			}
			else
			{
				theAnswer = kAudioHardwareUnsupportedOperationError;
			}
		}
		else
		{
			theAnswer = kAudioHardwareUnknownPropertyError;
		}
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

#pragma mark IO Operations

static OSStatus	SA_StartIO(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID)
{
	//	This call tells the device that IO is starting for the given client. When this routine
	//	returns, the device's clock is running and it is ready to have data read/written. It is
	//	important to note that multiple clients can have IO running on the device at the same time.
	//	So, work only needs to be done when the first client starts. All subsequent starts simply
	//	increment the counter.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_StartIO: bad driver reference");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_StartIO: unknown device");
		
		//	tell it to do the work
		theDevice->StartIO();
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_StopIO(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID)
{
	//	This call tells the device that the client has stopped IO. The driver can stop the hardware
	//	once all clients have stopped.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_StopIO: bad driver reference");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_StopIO: unknown device");
		
		//	tell it to do the work
		theDevice->StopIO();
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_GetZeroTimeStamp(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, Float64* outSampleTime, UInt64* outHostTime, UInt64* outSeed)
{
	//	This method returns the current zero time stamp for the device. The HAL models the timing of
	//	a device as a series of time stamps that relate the sample time to a host time. The zero
	//	time stamps are spaced such that the sample times are the value of
	//	kAudioDevicePropertyZeroTimeStampPeriod apart. This is often modeled using a ring buffer
	//	where the zero time stamp is updated when wrapping around the ring buffer.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_GetZeroTimeStamp: bad driver reference");
		ThrowIfNULL(outSampleTime, CAException(kAudioHardwareIllegalOperationError), "SA_GetZeroTimeStamp: no place to put the sample time");
		ThrowIfNULL(outHostTime, CAException(kAudioHardwareIllegalOperationError), "SA_GetZeroTimeStamp: no place to put the host time");
		ThrowIfNULL(outSeed, CAException(kAudioHardwareIllegalOperationError), "SA_GetZeroTimeStamp: no place to put the seed");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_GetZeroTimeStamp: unknown device");
		
		//	tell it to do the work
		theDevice->GetZeroTimeStamp(*outSampleTime, *outHostTime, *outSeed);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_WillDoIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, Boolean* outWillDo, Boolean* outWillDoInPlace)
{
	//	This method returns whether or not the device will do a given IO operation.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_WillDoIOOperation: bad driver reference");
		ThrowIfNULL(outWillDo, CAException(kAudioHardwareIllegalOperationError), "SA_WillDoIOOperation: no place to put the will-do return value");
		ThrowIfNULL(outWillDoInPlace, CAException(kAudioHardwareIllegalOperationError), "SA_WillDoIOOperation: no place to put the in-place return value");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_WillDoIOOperation: unknown device");
		
		//	tell it to do the work
		bool willDo = false;
		bool willDoInPlace = false;
		theDevice->WillDoIOOperation(inOperationID, willDo, willDoInPlace);
		
		//	set the return values
		*outWillDo = willDo;
		*outWillDoInPlace = willDoInPlace;
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}

	return theAnswer;
}

static OSStatus	SA_BeginIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo)
{
	//	This is called at the beginning of an IO operation.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_BeginIOOperation: bad driver reference");
		ThrowIfNULL(inIOCycleInfo, CAException(kAudioHardwareIllegalOperationError), "SA_BeginIOOperation: no cycle info");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_BeginIOOperation: unknown device");
		
		//	tell it to do the work
		theDevice->BeginIOOperation(inOperationID, inIOBufferFrameSize, *inIOCycleInfo);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}

static OSStatus	SA_DoIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, AudioObjectID inStreamObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo, void* ioMainBuffer, void* ioSecondaryBuffer)
{
	//	This is called to actuall perform a given operation. For this device, all we need to do is
	//	clear the buffer for the ReadInput operation.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_EndIOOperation: bad driver reference");
		ThrowIfNULL(inIOCycleInfo, CAException(kAudioHardwareIllegalOperationError), "SA_EndIOOperation: no cycle info");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_EndIOOperation: unknown device");
		
		//	tell it to do the work
		theDevice->DoIOOperation(inStreamObjectID, inOperationID, inIOBufferFrameSize, *inIOCycleInfo, ioMainBuffer, ioSecondaryBuffer);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}

	return theAnswer;
}

static OSStatus	SA_EndIOOperation(AudioServerPlugInDriverRef inDriver, AudioObjectID inDeviceObjectID, UInt32 inClientID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo* inIOCycleInfo)
{
	//	This is called at the end of an IO operation.
	
	#pragma unused(inClientID)
	
	//	declare the local variables
	OSStatus theAnswer = 0;
	
	try
	{
		//	check the arguments
		ThrowIf(inDriver != gAudioServerPlugInDriverRef, CAException(kAudioHardwareBadObjectError), "SA_EndIOOperation: bad driver reference");
		ThrowIfNULL(inIOCycleInfo, CAException(kAudioHardwareIllegalOperationError), "SA_EndIOOperation: no cycle info");
		
		//	get the object
		SA_ObjectReleaser<SA_Device> theDevice(SA_ObjectMap::CopyObjectOfClassByObjectID<SA_Device>(inDeviceObjectID));
		ThrowIf(!theDevice.IsValid(), CAException(kAudioHardwareBadObjectError), "SA_EndIOOperation: unknown device");
		
		//	tell it to do the work
		theDevice->EndIOOperation(inOperationID, inIOBufferFrameSize, *inIOCycleInfo);
	}
	catch(const CAException& inException)
	{
		theAnswer = inException.GetError();
	}
	catch(...)
	{
		theAnswer = kAudioHardwareUnspecifiedError;
	}
	
	return theAnswer;
}
