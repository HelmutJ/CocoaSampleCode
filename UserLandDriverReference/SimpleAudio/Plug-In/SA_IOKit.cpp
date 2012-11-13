/*
     File: SA_IOKit.cpp
 Abstract: SA_IOKit.h
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
	SA_IOKit.cpp
==================================================================================================*/

//==================================================================================================
//	Includes
//==================================================================================================

//	Self Include
#include "SA_IOKit.h"

//	PublicUtility Includes
#include "CACFArray.h"
#include "CACFDictionary.h"
#include "CACFNumber.h"
#include "CACFString.h"
#include "CADebugMacros.h"
#include "CAException.h"

//	Local Includes
#include <CoreAudio/AudioHardwareBase.h>

//==================================================================================================
//	SA_IOKitObject
//==================================================================================================

SA_IOKitObject::SA_IOKitObject()
:
	mObject(IO_OBJECT_NULL),
	mConnection(IO_OBJECT_NULL),
	mProperties(static_cast<CFMutableDictionaryRef>(NULL), true),
	mAlwaysLoadPropertiesFromRegistry(true),
	mIsAlive(true)
{
}

SA_IOKitObject::SA_IOKitObject(io_object_t inObject)
:
	mObject(inObject),
	mConnection(IO_OBJECT_NULL),
	mProperties(static_cast<CFMutableDictionaryRef>(NULL), true),
	mAlwaysLoadPropertiesFromRegistry(true),
	mIsAlive(true)
{
	//	Note that we don't retain anything here as this constructor will consume a reference. In
	//	other words, this constructor essentially takes ownership of the object.
}

SA_IOKitObject::SA_IOKitObject(CFDictionaryRef inProperties)
:
	mObject(IO_OBJECT_NULL),
	mConnection(IO_OBJECT_NULL),
	mProperties(inProperties, true),
	mAlwaysLoadPropertiesFromRegistry(true),
	mIsAlive(false)
{
}

SA_IOKitObject::SA_IOKitObject(const SA_IOKitObject& inObject)
:
	mObject(inObject.mObject),
	mConnection(IO_OBJECT_NULL),
	mProperties(inObject.mProperties),
	mAlwaysLoadPropertiesFromRegistry(inObject.mAlwaysLoadPropertiesFromRegistry),
	mIsAlive(inObject.mIsAlive)
{
	Retain();
}

SA_IOKitObject&	SA_IOKitObject::operator=(io_object_t inObject)
{
	CloseConnection();
	Release();
	mObject = inObject;
	mIsAlive = true;
	//	Note that we don't retain anything here as this assignment operator will consume a reference
	//	just like the constructor with a similar signature. In other words, this assignment operator
	//	essentially takes ownership of the object.
	return *this;
}

SA_IOKitObject&	SA_IOKitObject::operator=(const SA_IOKitObject& inObject)
{
	CloseConnection();
	Release();
	mObject = inObject.mObject;
	mAlwaysLoadPropertiesFromRegistry = inObject.mAlwaysLoadPropertiesFromRegistry;
	mIsAlive = inObject.mIsAlive;
	mProperties = inObject.mProperties;
	if(mProperties.IsValid())
	{
		CFRelease(mProperties.GetCFDictionary());
	}
	Retain();
	return *this;
}

SA_IOKitObject::~SA_IOKitObject()
{		
	CloseConnection();
	Release();
}

io_object_t	SA_IOKitObject::GetObject() const
{
	return mObject;
}

io_object_t	SA_IOKitObject::CopyObject()
{
	Retain();
	return mObject;
}

bool	SA_IOKitObject::IsValid() const
{
	return mObject != IO_OBJECT_NULL;
}

bool	SA_IOKitObject::IsEqualTo(io_object_t inObject) const
{
	return IOObjectIsEqualTo(mObject, inObject);
}

bool	SA_IOKitObject::ConformsTo(const io_name_t inClassName)
{
	return IOObjectConformsTo(mObject, inClassName);
}

bool	SA_IOKitObject::IsServiceAlive() const
{
	return mIsAlive;
}

void	SA_IOKitObject::ServiceWasTerminated()
{
	mIsAlive = false;
}

bool	SA_IOKitObject::TestForLiveness(io_object_t inObject)
{
	bool theAnswer = false;
	if(inObject != IO_OBJECT_NULL)
	{
		CFMutableDictionaryRef theProperties = NULL;
		kern_return_t theError = IORegistryEntryCreateCFProperties(inObject, &theProperties, NULL, 0);
		if(theProperties != NULL)
		{
			CFRelease(theProperties);
		}
		theAnswer = theError == 0;
	}
	return theAnswer;
}

CFDictionaryRef	SA_IOKitObject::CopyProperties() const
{
	CacheProperties();
	return mProperties.CopyCFDictionary();
}

bool	SA_IOKitObject::HasProperty(CFStringRef inKey) const
{
	CacheProperties();
	return mProperties.HasKey(inKey);
}

bool	SA_IOKitObject::CopyProperty_bool(CFStringRef inKey, bool& outValue) const
{
	CacheProperties();
	return mProperties.GetBool(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_SInt32(CFStringRef inKey, SInt32& outValue) const
{
	CacheProperties();
	return mProperties.GetSInt32(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_UInt32(CFStringRef inKey, UInt32& outValue) const
{
	CacheProperties();
	return mProperties.GetUInt32(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_UInt64(CFStringRef inKey, UInt64& outValue) const
{
	CacheProperties();
	return mProperties.GetUInt64(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_Fixed32(CFStringRef inKey, Float32& outValue) const
{
	CacheProperties();
	return mProperties.GetFixed32(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_Fixed64(CFStringRef inKey, Float64& outValue) const
{
	CacheProperties();
	return mProperties.GetFixed64(inKey, outValue);
}

bool	SA_IOKitObject::CopyProperty_CFString(CFStringRef inKey, CFStringRef& outValue) const
{
	CacheProperties();
	bool theAnswer = mProperties.GetString(inKey, outValue);
	if(outValue != NULL)
	{
		CFRetain(outValue);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFArray(CFStringRef inKey, CFArrayRef& outValue) const
{
	CacheProperties();
	bool theAnswer = mProperties.GetArray(inKey, outValue);
	if(outValue != NULL)
	{
		CFRetain(outValue);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFDictionary(CFStringRef inKey, CFDictionaryRef& outValue) const
{
	CacheProperties();
	bool theAnswer = mProperties.GetDictionary(inKey, outValue);
	if(outValue != NULL)
	{
		CFRetain(outValue);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFType(CFStringRef inKey, CFTypeRef& outValue) const
{
	CacheProperties();
	bool theAnswer = mProperties.GetCFType(inKey, outValue);
	if(outValue != NULL)
	{
		CFRetain(outValue);
	}
	return theAnswer;
}

void	SA_IOKitObject::CopyProperty_CACFString(CFStringRef inKey, CACFString& outValue) const
{
	CacheProperties();
	mProperties.GetCACFString(inKey, outValue);
}

void	SA_IOKitObject::CopyProperty_CACFArray(CFStringRef inKey, CACFArray& outValue) const
{
	CacheProperties();
	mProperties.GetCACFArray(inKey, outValue);
}

void	SA_IOKitObject::CopyProperty_CACFDictionary(CFStringRef inKey, CACFDictionary& outValue) const
{
	CacheProperties();
	mProperties.GetCACFDictionary(inKey, outValue);
}

void	SA_IOKitObject::CopyProperty_CACFType(CFStringRef inKey, CACFType& outValue) const
{
	CacheProperties();
	CFTypeRef theValue = NULL;
	if(mProperties.GetCFType(inKey, theValue))
	{
		outValue = theValue;
	}
}

void	SA_IOKitObject::SetProperty(CFStringRef inKey, CFTypeRef inValue)
{
	kern_return_t theError = IORegistryEntrySetCFProperty(mObject, inKey, inValue);
	ThrowIfKernelError(theError, CAException(theError), "SA_IOKitObject::SetProperty: got an error from the IORegistry");
}

void	SA_IOKitObject::SetProperty_bool(CFStringRef inKey, bool inValue)
{
	CACFNumber theValue(inValue ? UInt32(1) : UInt32(0));
	SetProperty(inKey, theValue.GetCFNumber());
}

void	SA_IOKitObject::SetProperty_SInt32(CFStringRef inKey, SInt32 inValue)
{
	CACFNumber theValue(inValue);
	SetProperty(inKey, theValue.GetCFNumber());
}

void	SA_IOKitObject::SetProperty_UInt32(CFStringRef inKey, UInt32 inValue)
{
	CACFNumber theValue(inValue);
	SetProperty(inKey, theValue.GetCFNumber());
}

void	SA_IOKitObject::PropertiesChanged()
{
	mProperties = static_cast<CFMutableDictionaryRef>(NULL);
}

void	SA_IOKitObject::CacheProperties() const
{
	if((mObject != IO_OBJECT_NULL) && (!mProperties.IsValid() || mAlwaysLoadPropertiesFromRegistry))
	{
		CFMutableDictionaryRef theProperties = NULL;
		kern_return_t theError = IORegistryEntryCreateCFProperties(mObject, &theProperties, NULL, 0);
		AssertNoKernelError(theError, "SA_IOKitObject::CacheProperties: failed to get the properties from the IO Registry");
		const_cast<SA_IOKitObject*>(this)->mProperties = theProperties;
		if(theProperties != NULL)
		{
			CFRelease(theProperties);
		}
	}
}

bool	SA_IOKitObject::CopyProperty_bool(io_object_t inObject, CFStringRef inKey, bool& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFBooleanGetTypeID()))
	{
		outValue = CFBooleanGetValue(static_cast<CFBooleanRef>(theProperty));
		theAnswer = true;
	}
	else if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFNumberGetTypeID()))
	{
		CACFNumber theNumber(static_cast<CFNumberRef>(theProperty), false);
		outValue = theNumber.GetUInt32() != 0;
		theAnswer = true;
	}
	if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_SInt32(io_object_t inObject, CFStringRef inKey, SInt32& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFNumberGetTypeID()))
	{
		CACFNumber theNumber(static_cast<CFNumberRef>(theProperty), false);
		outValue = theNumber.GetSInt32();
		theAnswer = true;
	}
	if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_UInt32(io_object_t inObject, CFStringRef inKey, UInt32& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFNumberGetTypeID()))
	{
		CACFNumber theNumber(static_cast<CFNumberRef>(theProperty), false);
		outValue = theNumber.GetUInt32();
		theAnswer = true;
	}
	if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFString(io_object_t inObject, CFStringRef inKey, CFStringRef& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFStringGetTypeID()))
	{
		outValue = static_cast<CFStringRef>(theProperty);
		theAnswer = true;
	}
	else if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFArray(io_object_t inObject, CFStringRef inKey, CFArrayRef& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFArrayGetTypeID()))
	{
		outValue = static_cast<CFArrayRef>(theProperty);
		theAnswer = true;
	}
	else if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

bool	SA_IOKitObject::CopyProperty_CFDictionary(io_object_t inObject, CFStringRef inKey, CFDictionaryRef& outValue)
{
	bool theAnswer = false;
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFDictionaryGetTypeID()))
	{
		outValue = static_cast<CFDictionaryRef>(theProperty);
		theAnswer = true;
	}
	else if(theProperty != NULL)
	{
		CFRelease(theProperty);
	}
	return theAnswer;
}

void	SA_IOKitObject::CopyProperty_CACFString(io_object_t inObject, CFStringRef inKey, CACFString& outValue)
{
	CFTypeRef theProperty = IORegistryEntryCreateCFProperty(inObject, inKey, NULL, 0);
	if((theProperty != NULL) && (CFGetTypeID(theProperty) == CFStringGetTypeID()))
	{
		outValue = static_cast<CFStringRef>(theProperty);
		CFRelease(theProperty);
	}
	else
	{
		if(theProperty != NULL)
		{
			CFRelease(theProperty);
		}
		outValue = static_cast<CFStringRef>(NULL);
	}
}

io_object_t	SA_IOKitObject::CopyMatchingObjectWithPropertyValue(CFDictionaryRef inMatchingDictionary, CFStringRef inKey, CFTypeRef inValue)
{
	io_object_t theAnswer = IO_OBJECT_NULL;
	
	if((inMatchingDictionary != NULL) && (inKey != NULL) && (inValue != NULL))
	{
		//	get the IOKit master port
		mach_port_t theMasterPort;
		kern_return_t theKernelError = IOMasterPort(bootstrap_port, &theMasterPort);
		ThrowIfKernelError(theKernelError, CAException(theKernelError), "HALS_IOA1PlugIn::_Activate: IOMasterPort failed");
		
		//	make an iterator that goes through the services that match (this consumes a reference on inMatchingDictionary)
		CFRetain(inMatchingDictionary);
		SA_IOKitObject theIOService;
		io_iterator_t theIOIterator = IO_OBJECT_NULL;
		theKernelError = IOServiceGetMatchingServices(theMasterPort, inMatchingDictionary, &theIOIterator);
		if((theKernelError == 0) && (theIOIterator != IO_OBJECT_NULL))
		{
			SA_IOKitIterator theIterator(theIOIterator);
			//	find the service with the same property value
			SA_IOKitObject theCurrentIOService(theIterator.Next());
			while(!theIOService.IsValid() && theCurrentIOService.IsValid())
			{
				CACFType theCurrentValue;
				theCurrentIOService.CopyProperty_CACFType(inKey, theCurrentValue);
				if(theCurrentValue.IsValid() && CFEqual(theCurrentValue.GetCFObject(), inValue))
				{
					theIOService = theCurrentIOService.CopyObject();
				}
				
				theCurrentIOService = theIterator.Next();
			}
		}
		theAnswer = theIOService.CopyObject();
	}
	
	return theAnswer;
}
	
io_object_t	SA_IOKitObject::CopyChildWithIntegerPropertyValues(io_object_t inParent, CFStringRef inKey1, UInt32 inValue1, CFStringRef inKey2, UInt32 inValue2)
{
	io_object_t theAnswer = IO_OBJECT_NULL;
	
	if((inParent != IO_OBJECT_NULL) && (inKey1 != NULL) && (inKey2 != NULL))
	{
		//	make an iterator that goes through the services that match
		SA_IOKitObject theIOService;
		SA_IOKitIterator theIterator(inParent, kIOServicePlane);
		if(theIterator.IsValid())
		{
			//	find the IOService with the same property values
			SA_IOKitObject theCurrentIOService(theIterator.Next());
			while(!theIOService.IsValid() && theCurrentIOService.IsValid())
			{
				UInt32 theValue1 = 0;
				bool hasValue1 = theCurrentIOService.CopyProperty_UInt32(inKey1, theValue1);
				UInt32 theValue2 = 0;
				bool hasValue2 = theCurrentIOService.CopyProperty_UInt32(inKey2, theValue2);

				if(hasValue1 && hasValue2 && (inValue1 == theValue1) && (inValue2 == theValue2))
				{
					theIOService = theCurrentIOService.CopyObject();
				}
				
				theCurrentIOService = theIterator.Next();
			}
		}
		
		theAnswer = theIOService.CopyObject();
	}
	
	return theAnswer;
}
	
io_object_t	SA_IOKitObject::CopyParentByClassName(io_object_t inObject, const char* inClassName, const io_name_t inPlane)
{
	io_object_t theAnswer = IO_OBJECT_NULL;
	SA_IOKitIterator theIterator(inObject, inPlane, true);
	if(theIterator.IsValid())
	{	
		bool wasFound = false;
		SA_IOKitObject theParent(theIterator.Next());
		while(!wasFound && theParent.IsValid())
		{
			if(theParent.ConformsTo(inClassName))
			{
				//	found it, so save it and get out
				theAnswer = theParent.CopyObject();
				wasFound = true;
			}
			else
			{
				theParent = theIterator.Next();
			}
		}
	}
	return theAnswer;
}

bool	SA_IOKitObject::IsConnectionOpen() const
{
	return mConnection != IO_OBJECT_NULL;
}

void	SA_IOKitObject::OpenConnection(UInt32 inUserClientType)
{
	if((mObject != IO_OBJECT_NULL) && (mConnection == IO_OBJECT_NULL))
	{
		kern_return_t theKernelError = IOServiceOpen(mObject, mach_task_self(), inUserClientType, &mConnection);
		ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_IOKitObject::OpenConnection: failed to open a connection");
	}
}

void	SA_IOKitObject::CloseConnection()
{
	if(mConnection != IO_OBJECT_NULL)
	{
		IOServiceClose(mConnection);
		mConnection = IO_OBJECT_NULL;
	}
}

void	SA_IOKitObject::SetConnectionNotificationPort(UInt32 inType, mach_port_t inPort, void* inUserData)
{
	if(mConnection != IO_OBJECT_NULL)
	{
		kern_return_t theKernelError = IOConnectSetNotificationPort(mConnection, inType, inPort, reinterpret_cast<uintptr_t>(inUserData));
		if(inPort != MACH_PORT_NULL)
		{
			ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_IOKitObject::SetConnectionNotificationPort: Cannot set the connection's's notification port.");
		}
	}
}

void*	SA_IOKitObject::MapMemory(UInt32 inType, IOOptionBits inOptions, UInt32& outSize)
{
	void* theAnswer = NULL;
	if((mConnection != IO_OBJECT_NULL) && mIsAlive)
	{
		mach_vm_address_t	theAddress;
		mach_vm_size_t		theSize;
		kern_return_t theKernelError = IOConnectMapMemory64(mConnection, inType, mach_task_self(), &theAddress, &theSize, inOptions);
		ThrowIfKernelError(theKernelError, CAException(theKernelError), "SA_IOKitObject::MapMemory: failed to map in the memory");
		theAnswer = reinterpret_cast<void*>(theAddress);
		ThrowIfNULL(theAnswer, CAException(kAudioHardwareIllegalOperationError), "SA_IOKitObject::MapMemory: mapped in a NULL pointer");
		outSize = static_cast<UInt32>(theSize);
	}
	return theAnswer;
}

void	SA_IOKitObject::ReleaseMemory(void* inMemory, UInt32 inType)
{
	if((mConnection != IO_OBJECT_NULL) && (inMemory != NULL))
	{
		IOConnectUnmapMemory64(mConnection, inType, mach_task_self(), reinterpret_cast<mach_vm_address_t>(inMemory));
//		AssertNoKernelError(theKernelError, "SA_IOKitObject::ReleaseMemory: failed to release the memory");
	}
}

kern_return_t	SA_IOKitObject::CallMethod(UInt32 inSelector, const UInt64* inInputItems, UInt32 inNumberInputItems, const void* inRawInput, size_t inRawInputSize, UInt64* outOutputItems, UInt32* outNumberOutputItems, void* outRawOutput, size_t* outRawOutputSize)
{
	kern_return_t theKernelError;
	if((mConnection != IO_OBJECT_NULL) && mIsAlive)
	{
		theKernelError = IOConnectCallMethod(mConnection, inSelector, inInputItems, inNumberInputItems, inRawInput, inRawInputSize, outOutputItems, reinterpret_cast<uint32_t*>(outNumberOutputItems), outRawOutput, outRawOutputSize);
	}
	else
	{
		theKernelError = kAudioHardwareNotRunningError;
	}
	return theKernelError;
}

kern_return_t	SA_IOKitObject::CallTrap(UInt32 inSelector)
{
	kern_return_t theKernelError;
	if((mConnection != IO_OBJECT_NULL) && mIsAlive)
	{
		theKernelError = IOConnectTrap0(mConnection, inSelector);
	}
	else
	{
		theKernelError = kAudioHardwareNotRunningError;
	}
	return theKernelError;
}

void	SA_IOKitObject::Retain()
{
	if(mObject != IO_OBJECT_NULL)
	{
		IOObjectRetain(mObject);
	}
}

void	SA_IOKitObject::Release()
{
	if(mObject != IO_OBJECT_NULL)
	{
		IOObjectRelease(mObject);
		mObject = IO_OBJECT_NULL;
	}
	mProperties = static_cast<CFMutableDictionaryRef>(NULL);
}

//==================================================================================================
//	SA_IOKitIterator
//==================================================================================================

SA_IOKitIterator::SA_IOKitIterator()
:
	mIterator(IO_OBJECT_NULL),
	mWillRelease(true)
{
}

SA_IOKitIterator::SA_IOKitIterator(io_iterator_t inIterator, bool inWillRelease)
:
	mIterator(inIterator),
	mWillRelease(inWillRelease)
{
}

SA_IOKitIterator::SA_IOKitIterator(const SA_IOKitIterator& inIterator)
:
	mIterator(inIterator.mIterator),
	mWillRelease(inIterator.mWillRelease)
{
	Retain();
}

SA_IOKitIterator::SA_IOKitIterator(io_object_t inParent, const io_name_t inPlane)
:
	mIterator(IO_OBJECT_NULL),
	mWillRelease(true)
{
	if(IORegistryEntryGetChildIterator(inParent, inPlane, &mIterator) != 0)
	{
		mIterator = IO_OBJECT_NULL;
	}
}

SA_IOKitIterator::SA_IOKitIterator(io_object_t inChild, const io_name_t inPlane, bool)
:
	mIterator(IO_OBJECT_NULL),
	mWillRelease(true)
{
	if(IORegistryEntryGetParentIterator(inChild, inPlane, &mIterator) != 0)
	{
		mIterator = IO_OBJECT_NULL;
	}
}

SA_IOKitIterator::SA_IOKitIterator(CFMutableDictionaryRef inMatchingDictionary)
:
	mIterator(IO_OBJECT_NULL),
	mWillRelease(true)
{
	//	note that IOServiceGetMatchingServices will consume one reference on inMatchingDictionary
	if(IOServiceGetMatchingServices(kIOMasterPortDefault, inMatchingDictionary, &mIterator) != 0)
	{
		mIterator = IO_OBJECT_NULL;
	}
}

SA_IOKitIterator&	SA_IOKitIterator::operator=(io_iterator_t inIterator)
{
	Release();
	mIterator = inIterator;
	Retain();
	return *this;
}

SA_IOKitIterator&	SA_IOKitIterator::operator=(const SA_IOKitIterator& inIterator)
{
	Release();
	mIterator = inIterator.mIterator;
	Retain();
	return *this;
}

SA_IOKitIterator::~SA_IOKitIterator()
{
	Release();
}

io_iterator_t	SA_IOKitIterator::GetIterator() const
{
	return mIterator;
}

bool	SA_IOKitIterator::IsValid() const
{
	return mIterator != IO_OBJECT_NULL;
}

io_object_t	SA_IOKitIterator::Next()
{
	return IOIteratorNext(mIterator);
}

void	SA_IOKitIterator::SetWillRelease(bool inWillRelease)
{
	mWillRelease = inWillRelease;
}

void	SA_IOKitIterator::Retain()
{
	if(mIterator != IO_OBJECT_NULL)
	{
		IOObjectRetain(mIterator);
	}
}

void	SA_IOKitIterator::Release()
{
	if(mWillRelease && (mIterator != IO_OBJECT_NULL))
	{
		IOObjectRelease(mIterator);
		mIterator = IO_OBJECT_NULL;
	}
}
