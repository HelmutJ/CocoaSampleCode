/*
     File: SA_Object.cpp
 Abstract: SA_Object.h
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
	SA_ObjectMap.cpp
==================================================================================================*/

//==================================================================================================
//	Includes
//==================================================================================================

//	Self Include
#include "SA_Object.h"

//	PublicUtility Includes
#include "CADebugMacros.h"
#include "CADispatchQueue.h"
#include "CAException.h"

//==================================================================================================
#pragma mark -
#pragma mark SA_Object
//==================================================================================================

#pragma mark Construction/Destruction

SA_Object::SA_Object(AudioObjectID inObjectID, AudioClassID inClassID, AudioClassID inBaseClassID, AudioObjectID inOwnerObjectID)
:
	mObjectID(inObjectID),
	mClassID(inClassID),
	mBaseClassID(inBaseClassID),
	mOwnerObjectID(inOwnerObjectID),
	mIsActive(false)
{
}

void	SA_Object::Activate()
{
	mIsActive = true;
}

void	SA_Object::Deactivate()
{
	mIsActive = false;
}

SA_Object::~SA_Object()
{
}

#pragma mark Property Operations

bool	SA_Object::HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const
{
	#pragma unused(inObjectID, inClientPID)
	
	bool theAnswer = false;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyBaseClass:
		case kAudioObjectPropertyClass:
		case kAudioObjectPropertyOwner:
		case kAudioObjectPropertyOwnedObjects:
			theAnswer = (inAddress.mScope == kAudioObjectPropertyScopeGlobal) && (inAddress.mElement == kAudioObjectPropertyElementMaster);
			break;
	};
	return theAnswer;
}

bool	SA_Object::IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const
{
	#pragma unused(inObjectID, inClientPID)
	
	bool theAnswer = false;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyBaseClass:
		case kAudioObjectPropertyClass:
		case kAudioObjectPropertyOwner:
		case kAudioObjectPropertyOwnedObjects:
			theAnswer = false;
			break;
		
		default:
			Throw(CAException(kAudioHardwareUnknownPropertyError));
			break;
	};
	return theAnswer;
}

UInt32	SA_Object::GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const
{
	#pragma unused(inObjectID, inClientPID, inQualifierDataSize, inQualifierData)
	
	UInt32 theAnswer = 0;
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyBaseClass:
		case kAudioObjectPropertyClass:
			theAnswer = sizeof(AudioClassID);
			break;
			
		case kAudioObjectPropertyOwner:
			theAnswer = sizeof(AudioObjectID);
			break;
			
		case kAudioObjectPropertyOwnedObjects:
			theAnswer = 0;
			break;
		
		default:
			Throw(CAException(kAudioHardwareUnknownPropertyError));
			break;
	};
	return theAnswer;
}

void	SA_Object::GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const
{
	#pragma unused(inObjectID, inClientPID, inQualifierDataSize, inQualifierData)
	
	switch(inAddress.mSelector)
	{
		case kAudioObjectPropertyBaseClass:
			//	This is the AudioClassID of the base class of this object. This is an invariant.
			ThrowIf(inDataSize < sizeof(AudioClassID), CAException(kAudioHardwareBadPropertySizeError), "SA_Object::GetPropertyData: not enough space for the return value of kAudioObjectPropertyBaseClass");
			*reinterpret_cast<AudioClassID*>(outData) = mBaseClassID;
			outDataSize = sizeof(AudioClassID);
			break;
			
		case kAudioObjectPropertyClass:
			//	This is the AudioClassID of the class of this object. This is an invariant.
			ThrowIf(inDataSize < sizeof(AudioClassID), CAException(kAudioHardwareBadPropertySizeError), "SA_Object::GetPropertyData: not enough space for the return value of kAudioObjectPropertyClass");
			*reinterpret_cast<AudioClassID*>(outData) = mClassID;
			outDataSize = sizeof(AudioClassID);
			break;
			
		case kAudioObjectPropertyOwner:
			//	The AudioObjectID of the object that owns this object. This is an invariant.
			ThrowIf(inDataSize < sizeof(AudioObjectID), CAException(kAudioHardwareBadPropertySizeError), "SA_Object::GetPropertyData: not enough space for the return value of kAudioObjectPropertyOwner");
			*reinterpret_cast<AudioClassID*>(outData) = mOwnerObjectID;
			outDataSize = sizeof(AudioObjectID);
			break;
			
		case kAudioObjectPropertyOwnedObjects:
			//	This is an array of AudioObjectIDs for the objects owned by this object. By default,
			//	objects don't own any other objects. This is an invariant by default, but an object
			//	that can contain other objects will likely need to do some synchronization to access
			//	this property.
			outDataSize = 0;
			break;
		
		default:
			Throw(CAException(kAudioHardwareUnknownPropertyError));
			break;
	};
}

void	SA_Object::SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData)
{
	#pragma unused(inObjectID, inClientPID, inQualifierDataSize, inQualifierData, inDataSize, inData)
	
	switch(inAddress.mSelector)
	{
		default:
			Throw(CAException(kAudioHardwareUnknownPropertyError));
			break;
	};
}

//==================================================================================================
#pragma mark -
#pragma mark SA_ObjectMap
//==================================================================================================

#pragma mark Construction/Destruction

SA_ObjectMap::SA_ObjectMap()
:
	mMutex("SA_ObjectMap Mutex"),
	mNextObjectID(32),
	mObjectInfoList()
{
	mObjectInfoList.reserve(256);
}

SA_ObjectMap::~SA_ObjectMap()
{
}

void	SA_ObjectMap::StaticInitializer()
{
	sInstance = new SA_ObjectMap;
	AssertNotNULL(sInstance, "SA_ObjectMap::StaticInitializer: failed to create the object map");
}

#pragma mark External Methods

AudioObjectID	SA_ObjectMap::GetNextObjectID()
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	CAMutex::Locker theLocker(sInstance->mMutex);
	AudioObjectID theAnswer = sInstance->_GetNextObjectID();
	return theAnswer;
}

bool	SA_ObjectMap::MapObject(AudioObjectID inObjectID, SA_Object* inObject)
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	bool theAnswer = false;
	if((inObjectID != 0) && (inObject != NULL))
	{
		CAMutex::Locker theLocker(sInstance->mMutex);
		theAnswer = sInstance->_MapObject(inObjectID, inObject);
	}
	return theAnswer;
}

void	SA_ObjectMap::UnmapObject(AudioObjectID inObjectID, SA_Object* inObject)
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	if((inObjectID != 0) && (inObject != NULL))
	{
		CAMutex::Locker theLocker(sInstance->mMutex);
		sInstance->_UnmapObject(inObjectID, inObject);
	}
}

SA_Object*	SA_ObjectMap::CopyObjectByObjectID(AudioObjectID inObjectID)
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	SA_Object* theAnswer = NULL;
	if(inObjectID != 0)
	{
		CAMutex::Locker theLocker(sInstance->mMutex);
		theAnswer = sInstance->_CopyObjectByObjectID(inObjectID);
	}
	return theAnswer;
}

UInt64	SA_ObjectMap::RetainObject(SA_Object* inObject)
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	UInt64 theAnswer = 0;
	if(inObject != NULL)
	{
		CAMutex::Locker theLocker(sInstance->mMutex);
		theAnswer = sInstance->_RetainObject(inObject);
	}
	return theAnswer;
}

UInt64	SA_ObjectMap::ReleaseObject(SA_Object* inObject)
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	UInt64 theAnswer = 0;
	if(inObject != NULL)
	{
		CAMutex::Locker theLocker(sInstance->mMutex);
		theAnswer = sInstance->_ReleaseObject(inObject);
	}
	return theAnswer;
}

void	SA_ObjectMap::Dump()
{
	pthread_once(&sStaticInitializer, StaticInitializer);
	CAMutex::Locker theLocker(sInstance->mMutex);
	sInstance->_Dump();
}

void	SA_ObjectMap::DestroyObject(SA_Object* inObject)
{
	//	The method is called when an object has been fully released and removed from the map. There
	//	is no need to synchronize against the object map's mutex. All it needs to do is dispose of
	//	the object in whatever manner is most suitable.
	delete inObject;
}

#pragma mark Internal Methods

AudioObjectID	SA_ObjectMap::_GetNextObjectID()
{
	return mNextObjectID++;
}

bool	SA_ObjectMap::_MapObject(AudioObjectID inObjectID, SA_Object* inObject)
{
	bool theAnswer = false;
	
	//	we don't do mappings for IDs of 0 or NULL object pointers
	if((inObjectID != 0) && (inObject != NULL))
	{
		//	look to see if the ID is already attached to an object
		ObjectInfoList::iterator theByIDIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObjectID);
		if(theByIDIterator == mObjectInfoList.end())
		{
			//	it is not, so we're going to do a mapping
			theAnswer = true;
			
			//	look to see if the object is already in the list
			ObjectInfoList::iterator theByPtrIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObject);
			if(theByPtrIterator != mObjectInfoList.end())
			{
				//	it is, so just add the new ID to it's ID list
				theByPtrIterator->mObjectIDList.push_back(inObjectID);
			}
			else
			{
				//	this is the first time this object has been mapped, so add a new entry to the list
				mObjectInfoList.push_back(ObjectInfo(inObjectID, inObject));
			}
		}
		else
		{
			//	the given ID is already attached to an object, this is a programming error
			DebugMsg("HALB_ObjectMap::_MapObject: %d cannot be mapped to object %p because it is already mapped to %p", (int)inObjectID, inObject, theByIDIterator->mObject);
		}
	}
	
	return theAnswer;
}

void	SA_ObjectMap::_UnmapObject(AudioObjectID inObjectID, SA_Object* inObject)
{
	//	we don't do mappings for IDs of 0 or NULL object pointers
	if((inObjectID != 0) && (inObject != NULL))
	{
		//	find the object this ID is attached to
		ObjectInfoList::iterator theIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObjectID);
		if(theIterator != mObjectInfoList.end())
		{
			//	make sure that it is the object we expect to be unmapping
			if(theIterator->mObject == inObject)
			{
				//	find the ID in the ID list
				ObjectIDList::iterator theIDIterator = std::find(theIterator->mObjectIDList.begin(), theIterator->mObjectIDList.end(), inObjectID);
				if(theIDIterator != theIterator->mObjectIDList.end())
				{
					//	get rid of it
					theIterator->mObjectIDList.erase(theIDIterator);
					
					//	get rid of the object if there are no more IDs
					if(theIterator->mObjectIDList.empty())
					{
						//	get rid of the info in the list
						mObjectInfoList.erase(theIterator);
						
						//	and destroy the object
						CADispatchQueue::GetGlobalSerialQueue().Dispatch(false, ^{ DestroyObject(inObject); });
					}
				}
			}
		}
	}
}

SA_Object*	SA_ObjectMap::_CopyObjectByObjectID(AudioObjectID inObjectID)
{
	SA_Object* theAnswer = NULL;
	
	//	find the object this ID is attached to
	ObjectInfoList::iterator theIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObjectID);
	if(theIterator != mObjectInfoList.end())
	{
		//	don't overflow the reference count
		if(theIterator->mReferenceCount < UINT64_MAX)
		{
			//	increment the reference count
			theIterator->mReferenceCount += 1;
			
			//	return the object pointer
			theAnswer = theIterator->mObject;
		}
		else
		{
			DebugMsg("SA_ObjectMap::_CopyObjectByObjectID: not copying because the reference count is at maximum");
		}
	}
	
	return theAnswer;
}

UInt64	SA_ObjectMap::_RetainObject(SA_Object* inObject)
{
	UInt64 theAnswer = 0;

	//	find the info for this object
	ObjectInfoList::iterator theIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObject);
	if(theIterator != mObjectInfoList.end())
	{
		//	don't overflow the reference count
		if(theIterator->mReferenceCount < UINT64_MAX)
		{
			//	increment the reference count
			theIterator->mReferenceCount += 1;
		}
		else
		{
			DebugMsg("SA_ObjectMap::_RetainObject: not retaining because the reference count is at maximum");
		}
		
		theAnswer = theIterator->mReferenceCount;
	}
	
	return theAnswer;
}

UInt64	SA_ObjectMap::_ReleaseObject(SA_Object* inObject)
{
	UInt64 theAnswer = 0;

	//	find the info for this object
	ObjectInfoList::iterator theIterator = std::find(mObjectInfoList.begin(), mObjectInfoList.end(), inObject);
	if(theIterator != mObjectInfoList.end())
	{
		//	don't underflow the reference count
		if(theIterator->mReferenceCount > 0)
		{
			//	decrement the reference count
			theIterator->mReferenceCount -= 1;
			
			//	destroy the object if the count reaches 0
			if(theIterator->mReferenceCount == 0)
			{
				//	get rid of the info in the list
				mObjectInfoList.erase(theIterator);
				
				//	and destroy the object
				CADispatchQueue::GetGlobalSerialQueue().Dispatch(false, ^{ DestroyObject(inObject); });
			}
		}
		else
		{
			DebugMsg("SA_ObjectMap::_ReleaseObject: not releasing because the reference count is already at 0");
		}
		
		theAnswer = theIterator->mReferenceCount;
	}
	
	return theAnswer;
}

void	SA_ObjectMap::_Dump()
{

	//	iterate through the objects in the map and dump their id, class, and ref count
	DebugMsg("HALB_ObjectMap::_Dump:");
	AudioClassID	theBaseClassID;
	char			theBaseClassIDString[5];
	AudioClassID	theClassID;
	char			theClassIDString[5];
	UInt64			theReferenceCount;
	
	if(!mObjectInfoList.empty())
	{
		for(ObjectInfoList::iterator theIterator = mObjectInfoList.begin(); theIterator != mObjectInfoList.end(); ++theIterator)
		{
			theBaseClassID = theIterator->mObject->GetBaseClassID();
			theClassID = theIterator->mObject->GetClassID();
			theReferenceCount = theIterator->mReferenceCount;
			CACopy4CCToCString(theBaseClassIDString, theBaseClassID);
			CACopy4CCToCString(theClassIDString, theClassID);
			
			if(theIterator->mObjectIDList.size() == 1)
			{
				DebugMsg("  Object: %p | Class: '%s' | Base Class: '%s' | Ref: %4qd | ID: %d", theIterator->mObject, theClassIDString, theBaseClassIDString, theReferenceCount, (int)theIterator->mObjectIDList.front());
			}
			else
			{
				DebugMsg("  Object: %p | Class: '%s' | Base Class: '%s' | Ref: %4qd | Number IDs: %d", theIterator->mObject, theClassIDString, theBaseClassIDString, theReferenceCount, (int)theIterator->mObjectIDList.size());
			
				for(size_t theIndex = 0; theIndex < theIterator->mObjectIDList.size(); ++theIndex)
				{
					DebugMsg("    ID %3d: %d", (int)theIndex, (int)theIterator->mObjectIDList.at(theIndex));
				}
			}
		}
	}
	else
	{
		DebugMsg("  No Objects");
	}
}

pthread_once_t	SA_ObjectMap::sStaticInitializer = PTHREAD_ONCE_INIT;
SA_ObjectMap*	SA_ObjectMap::sInstance = NULL;
