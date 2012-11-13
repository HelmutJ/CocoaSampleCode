/*
     File: SA_IOKit.h
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
	SA_IOKit.h
==================================================================================================*/
#if !defined(__SA_IOKit_h__)
#define __SA_IOKit_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	PublicUtility Includes
#include "CACFDictionary.h"
#include "CACFObject.h"

//	System Includes
#include <IOKit/IOKitLib.h>

//==================================================================================================
//	_IOAudioNotificationMessage64
//	
//	This is a replacement for IOAudioNotificationMessage that will work for both 32 and 64 bit
//	clients. Note that this assumes a 64 bit kernel.
//==================================================================================================

#if TARGET_RT_64_BIT

typedef struct _IOAudioNotificationMessage64 {
    mach_msg_header_t	messageHeader;
    UInt32		type;
    UInt32		ref;
    void *		sender;
} _IOAudioNotificationMessage64;

#else

typedef struct _IOAudioNotificationMessage64 {
    mach_msg_header_t	messageHeader;
    UInt32		type;
    UInt32		ref;
	UInt32		reserved;
    void *		sender;
} _IOAudioNotificationMessage64;

#endif

//==================================================================================================
//	SA_IOKitObject
//==================================================================================================

class SA_IOKitObject
{

#pragma mark Construction/Destruction
public:
						SA_IOKitObject();
						SA_IOKitObject(io_object_t inObject);
						SA_IOKitObject(CFDictionaryRef inProperties);
						SA_IOKitObject(const SA_IOKitObject& inObject);
	SA_IOKitObject&		operator=(io_object_t inObject);
	SA_IOKitObject&		operator=(const SA_IOKitObject& inObject);
	virtual				~SA_IOKitObject();

#pragma mark Attributes
public:
	io_object_t			GetObject() const;
	io_object_t			CopyObject();
	bool				IsValid() const;
	bool				IsEqualTo(io_object_t inObject) const;
	bool				ConformsTo(const io_name_t inClassName);
	bool				IsServiceAlive() const;
	void				ServiceWasTerminated();
	bool				TestForLiveness() const															{ return TestForLiveness(mObject); }
	void				SetAlwaysLoadPropertiesFromRegistry(bool inAlwaysLoadPropertiesFromRegistry)	{ mAlwaysLoadPropertiesFromRegistry = inAlwaysLoadPropertiesFromRegistry; }
	
	static bool			TestForLiveness(io_object_t inObject);
	
#pragma mark Registry Operations
public:
	CFDictionaryRef		CopyProperties() const;
	bool				HasProperty(CFStringRef inKey) const;
	bool				CopyProperty_bool(CFStringRef inKey, bool& outValue) const;
	bool				CopyProperty_SInt32(CFStringRef inKey, SInt32& outValue) const;
	bool				CopyProperty_UInt32(CFStringRef inKey, UInt32& outValue) const;
	bool				CopyProperty_UInt64(CFStringRef inKey, UInt64& outValue) const;
	bool				CopyProperty_Fixed32(CFStringRef inKey, Float32& outValue) const;
	bool				CopyProperty_Fixed64(CFStringRef inKey, Float64& outValue) const;
	bool				CopyProperty_CFString(CFStringRef inKey, CFStringRef& outValue) const;
	bool				CopyProperty_CFArray(CFStringRef inKey, CFArrayRef& outValue) const;
	bool				CopyProperty_CFDictionary(CFStringRef inKey, CFDictionaryRef& outValue) const;
	bool				CopyProperty_CFType(CFStringRef inKey, CFTypeRef& outValue) const;
	
	void				CopyProperty_CACFString(CFStringRef inKey, CACFString& outValue) const;
	void				CopyProperty_CACFArray(CFStringRef inKey, CACFArray& outValue) const;
	void				CopyProperty_CACFDictionary(CFStringRef inKey, CACFDictionary& outValue) const;
	void				CopyProperty_CACFType(CFStringRef inKey, CACFType& outValue) const;
	
	void				SetProperty(CFStringRef inKey, CFTypeRef inValue);
	void				SetProperty_bool(CFStringRef inKey, bool inValue);
	void				SetProperty_SInt32(CFStringRef inKey, SInt32 inValue);
	void				SetProperty_UInt32(CFStringRef inKey, UInt32 inValue);
	virtual void		PropertiesChanged();
	virtual void		CacheProperties() const;

#pragma mark Static Registry Operations
public:
	static bool			CopyProperty_bool(io_object_t inObject, CFStringRef inKey, bool& outValue);
	static bool			CopyProperty_SInt32(io_object_t inObject, CFStringRef inKey, SInt32& outValue);
	static bool			CopyProperty_UInt32(io_object_t inObject, CFStringRef inKey, UInt32& outValue);
	static bool			CopyProperty_CFString(io_object_t inObject, CFStringRef inKey, CFStringRef& outValue);
	static bool			CopyProperty_CFArray(io_object_t inObject, CFStringRef inKey, CFArrayRef& outValue);
	static bool			CopyProperty_CFDictionary(io_object_t inObject, CFStringRef inKey, CFDictionaryRef& outValue);
	
	static void			CopyProperty_CACFString(io_object_t inObject, CFStringRef inKey, CACFString& outValue);
	
	static io_object_t	CopyMatchingObjectWithPropertyValue(CFDictionaryRef inMatchingDictionary, CFStringRef inKey, CFTypeRef inValue);
	static io_object_t	CopyChildWithIntegerPropertyValues(io_object_t inObject, CFStringRef inKey1, UInt32 inValue1, CFStringRef inKey2, UInt32 inValue2);
	static io_object_t	CopyParentByClassName(io_object_t inObject, const char* inClassName, const io_name_t inPlane);

#pragma mark Connection Operations
public:
	bool				IsConnectionOpen() const;
	void				OpenConnection(UInt32 inUserClientType = 0);
	void				CloseConnection();
	void				SetConnectionNotificationPort(UInt32 inType, mach_port_t inPort, void* inUserData);
	void*				MapMemory(UInt32 inType, IOOptionBits inOptions, UInt32& outSize);
	void				ReleaseMemory(void* inMemory, UInt32 inType);
	kern_return_t		CallMethod(UInt32 inSelector, const UInt64* inInputItems, UInt32 inNumberInputItems, const void* inRawInput, size_t inRawInputSize, UInt64* outOutputItems, UInt32* outNumberOutputItems, void* outRawOutput, size_t* outRawOutputSize);
	kern_return_t		CallTrap(UInt32 inSelector);
	
#pragma mark Implementation
public:
	virtual void		Retain();
	virtual void		Release();

protected:
	io_object_t			mObject;
	io_connect_t		mConnection;
	CACFDictionary		mProperties;
	bool				mAlwaysLoadPropertiesFromRegistry;
	bool				mIsAlive;

};

//==================================================================================================
//	SA_IOKitIterator
//==================================================================================================

class SA_IOKitIterator
{

#pragma mark Construction/Destruction
public:
						SA_IOKitIterator();
						SA_IOKitIterator(io_iterator_t inIterator, bool inWillRelease = true);
						SA_IOKitIterator(const SA_IOKitIterator& inIterator);
						SA_IOKitIterator(io_object_t inParent, const io_name_t inPlane);
						SA_IOKitIterator(io_object_t inChild, const io_name_t inPlane, bool);
						SA_IOKitIterator(CFMutableDictionaryRef inMatchingDictionary);
	SA_IOKitIterator&	operator=(io_iterator_t inIterator);
	SA_IOKitIterator&	operator=(const SA_IOKitIterator& inIterator);
						~SA_IOKitIterator();

#pragma mark Operations
public:
	io_iterator_t		GetIterator() const;
	bool				IsValid() const;
	io_object_t			Next();
	void				SetWillRelease(bool inWillRelease);
	
#pragma mark Implementation
private:
	void				Retain();
	void				Release();
	
	io_iterator_t		mIterator;
	bool				mWillRelease;

};

#endif	//	__SA_IOKit_h__
