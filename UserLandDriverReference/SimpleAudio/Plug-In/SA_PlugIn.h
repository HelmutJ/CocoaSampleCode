/*
     File: SA_PlugIn.h
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
	SA_PlugIn.h
==================================================================================================*/
#if !defined(__SA_PlugIn_h__)
#define __SA_PlugIn_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	SuperClass Includes
#include "SA_Object.h"

//	PublicUtility Includes
#include "CADispatchQueue.h"

//	System Includes
#include <IOKit/IOKitLib.h>

//==================================================================================================
//	Types
//==================================================================================================

class	SA_Device;

//==================================================================================================
//	SA_PlugIn
//==================================================================================================

class SA_PlugIn
:
	public SA_Object
{

#pragma mark Construction/Destruction
public:
	static SA_PlugIn&				GetInstance();

protected:
									SA_PlugIn();
	virtual							~SA_PlugIn();

	virtual void					Activate();
	virtual void					Deactivate();
	
private:
	static void						StaticInitializer();

#pragma mark Property Operations
public:
	virtual bool					HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual bool					IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual UInt32					GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	virtual void					GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	virtual void					SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Device List Management
private:
	void							_StartDeviceListNotifications();
	void							_StopDeviceListNotifications();
	
	void							AddDevice(SA_Device* inDevice);
	void							RemoveDevice(SA_Device* inDevice);
	SA_Device*						CopyDeviceByIOObject(io_object_t inIOObject);
	
	void							_AddDevice(SA_Device* inDevice);
	void							_RemoveDevice(SA_Device* inDevice);
	void							_RemoveAllDevices();
	SA_Device*						_CopyDeviceByIOObject(io_object_t inIOObject);
	
	static void						IOServiceMatchingHandler(void* inContext, io_iterator_t inIterator);
	static void						IOServiceInterestHandler(void* inContext, io_service_t inService, natural_t inMessageType, void* inMessageArgument);

	struct							DeviceInfo
	{
		AudioObjectID				mDeviceObjectID;
		io_object_t					mInterestNotification;
		
									DeviceInfo() : mDeviceObjectID(0), mInterestNotification(IO_OBJECT_NULL) {}
									DeviceInfo(AudioObjectID inDeviceObjectID) : mDeviceObjectID(inDeviceObjectID), mInterestNotification(IO_OBJECT_NULL) {}
	};
	typedef std::vector<DeviceInfo>	DeviceInfoList;
	
	DeviceInfoList					mDeviceInfoList;
	IONotificationPortRef			mIOKitNotificationPort;
	io_iterator_t					mMatchingNotification;
	CADispatchQueue					mDispatchQueue;

#pragma mark Host Accesss
public:
	static void						SetHost(AudioServerPlugInHostRef inHost)	{ sHost = inHost; }
	
	static void						Host_PropertiesChanged(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[])	{ if(sHost != NULL) { sHost->PropertiesChanged(GetInstance().sHost, inObjectID, inNumberAddresses, inAddresses); } }
	static void						Host_RequestDeviceConfigurationChange(AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo)			{ if(sHost != NULL) { sHost->RequestDeviceConfigurationChange(GetInstance().sHost, inDeviceObjectID, inChangeAction, inChangeInfo); } }

#pragma mark Implementation
private:
	CAMutex							mMutex;
	
	static pthread_once_t			sStaticInitializer;
	static SA_PlugIn*				sInstance;
	static AudioServerPlugInHostRef	sHost;

};

#endif	//	__SA_PlugIn_h__
