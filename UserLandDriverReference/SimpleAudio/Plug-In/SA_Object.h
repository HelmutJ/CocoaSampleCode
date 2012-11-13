/*
     File: SA_Object.h
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
	SA_ObjectMap.h
==================================================================================================*/
#if !defined(__SA_ObjectMap_h__)
#define __SA_ObjectMap_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	PublicUtility Includes
#include "CAMutex.h"

//	System Includes
#include <CoreAudio/AudioServerPlugIn.h>

//	Standard Library Includes
#include <vector>

//==================================================================================================
//	Types
//==================================================================================================

//==================================================================================================
//	SA_Object
//
//	This is the base class for objects managed by SA_ObjectMap. It's only job is to ensure that
//	objects of this type have the proper external semantics for a reference counted object. This
//	means that the desctructor is protected so that these objects cannot be deleted directly. Also,
//	these objects many not make a copy of another object or be assigned from another object. Note
//	that the reference count of the object is tracked and owned by the SA_ObjectMap.
//
//	These objects provide RTTI information tied to the constants describing the HAL's API class
//	hierarchy as described in the headers. The class ID and base class IDs passed in to the
//	constructor must operate with the semantics described in AudioObjectBase.h where the base class
//	has to always be one of the standard classes. The class ID can be a custom value or a standard
//	value however. If it is a standard value, the base class should be the proper standard base
//	class. So for example, a standard volume control object will say that it's class is
//	kAudioVolumeControlClassID and that its base class is kAudioLevelControlClassID. In the case of
//	a custom boolean control, it would say that it's class is a custom value like 'MYBL' and that
//	its base class is kAudioBooleanControlClassID.
//
//	Subclasses of this class must implement Activate(). This method is called after an object has
//	been constructed and inserted into the object map. Until Activate() is called, a constructed
//	object may not do anything active such as sending/receiving notifications or creating other
//	objects. Active operations may be performed in the Activate() method proper however. Note that
//	Activate() is called prior to any references to the object being handed out. As such, it does
//	not need to worry about being thread safe while Activate() is in progress.
//
//	Subclasses of this class must also implement Deactivate(). This method is called when the object
//	is at the end of it's lifecycle. Once Deactivate() has been called, the object may no longer
//	perform active opertions, including Deactivating other objects. This is based on the notion that
//	all the objects have a definite point at which they are considered dead to the outside world.
//	For example, an AudioDevice object is dead if it's hardware is unplugged. The point of death is
//	the notification the owner of the device gets to signal that it has been unplugged. Note that it
//	is both normal and expected that a dead object might still have outstanding references. Thus, an
//	object has to put in some care to do the right thing when these zombie references are used. The
//	best thing to do is to just have those queries return appropriate errors.
//
//	Deactivate() itself needs to be thread safe with respect to other opertions taking place on the
//	object. This also means taking care to handle the Deactivation of owned objects. For example, an
//	AudioDevice object will almost always own one or more AudioStream objects. If the stream is in a
//	separate lock domain from it's owning device, then the device has to be very careful about how
//	it deactivates the stream such that it doesn't try to lock the stream's lock while holding the
//	device's lock which will inevitably lead to a deadlock situation. There are two reasonable
//	approaches to dealing with this kind of situation. The first is to just not get into it by
//	making the device share a lock domain with all it's owned objects like streams and controls. The
//	other approach is to use dispatch queues to make the work of Deactivating owned objects take
//	place outside of the device's lock domain. For example, if the device needs to deactivate a
//	stream, it can remove the stream from any tracking in the device object and then dispatch
//	asynchronously the Deactivate() call on the stream and the release of the reference the device
//	has on the stream.
//
//	Note that both Activate() and Deactiveate() are called by objects at large. Typically,
//	Activate() is called by the creator of the object, usually right after the object has been
//	allocated. Deactivate() will usually be called by the owner of the object upon recognizing that
//	the object is dead to the outside world. Going back to the example of an AudioDevice getting
//	unplugged, the Deactivate() method will be called by whomever receives the notification about
//	the hardware going away, which is often the owner of the object.
//
//	This class also defines methods to implement the portion of the
//	AudioServerPlugInDriverInterface that deals with properties. The five methods all have the same
//	basic arguments and semantics. The class also provides the implementation for
//	the minimum required properties for all AudioObjects. There is a detailed commentary about each
//	specific property in the GetPropertyData() method.
//
//	It is important that a thread retain and hold a reference while it is using an SA_Object and 
//	that the reference be released promptly when the thread is finished using the object. By
//	assuming this, an SA_Objects can minimize the amount of locking it needs to do. In particular,
//	purely static or invariant data can be handled without any locking at all.
//==================================================================================================

class SA_Object
{

#pragma mark Construction/Destruction
public:
						SA_Object(AudioObjectID inObjectID, AudioClassID inClassID, AudioClassID inBaseClassID, AudioObjectID inOwnerObjectID);
					
	virtual void		Activate();
	virtual void		Deactivate();

protected:
	virtual				~SA_Object();

private:
						SA_Object(const SA_Object&);
	SA_Object&			operator=(const SA_Object&);

#pragma mark Attributes
public:
	AudioObjectID		GetObjectID() const			{ return mObjectID; }
	void*				GetObjectIDAsPtr() const	{ uintptr_t thePtr = mObjectID; return reinterpret_cast<void*>(thePtr); }
	AudioClassID		GetClassID() const			{ return mClassID; }
	AudioClassID		GetBaseClassID() const		{ return mBaseClassID; }
	AudioObjectID		GetOwnerObjectID() const	{ return mOwnerObjectID; }
	bool				IsActive() const			{ return mIsActive; }

#pragma mark Property Operations
public:
	virtual bool		HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual bool		IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual UInt32		GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	virtual void		GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	virtual void		SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Implementation
protected:
	friend class		SA_ObjectMap;
	
	AudioObjectID		mObjectID;
	AudioClassID		mClassID;
	AudioClassID		mBaseClassID;
	AudioObjectID		mOwnerObjectID;
	bool				mIsActive;

};

//==================================================================================================
//	SA_ObjectMap
//
//	SA_ObjectMap is a singleton object that maintains the mapping between AudioObjectIDs and
//	SA_Objects. In the process, it also manages the reference counting mechanism as well. The same
//	object can be mapped to multiple IDs.
//
//	The creator of an SA_Object must register the object with this map prior to calling Activate()
//	on the new object. The typical sequence of events for creating an object go like this:
//		- Get an AudioObjectID for the new object (via GetNextObjectID())
//		- Create the new object
//		- Register the object with the map (via MapObject())
//		- Activate the new object
//==================================================================================================

class SA_ObjectMap
{

#pragma mark Construction/Destruction
private:
										SA_ObjectMap();
	virtual								~SA_ObjectMap();
	
	static void							StaticInitializer();
										SA_ObjectMap(const SA_ObjectMap&);
	SA_ObjectMap&						operator=(const SA_ObjectMap&);

#pragma mark External Methods
public:
	static AudioObjectID				GetNextObjectID();
	static bool							MapObject(AudioObjectID inObjectID, SA_Object* inObject);
	static void							UnmapObject(AudioObjectID inObjectID, SA_Object* inObject);
	static SA_Object*					CopyObjectByObjectID(AudioObjectID inObjectID);
	template <class T> static T*		CopyObjectOfClassByObjectID(AudioObjectID inObjectID)			{ return reinterpret_cast<T*>(CopyObjectByObjectID(inObjectID)); }
	static UInt64						RetainObject(SA_Object* inObject);
	static UInt64						ReleaseObject(SA_Object* inObject);
	static void							Dump();

private:
	void								DestroyObject(SA_Object* inObject);

#pragma mark Internal Methods
private:
	AudioObjectID						_GetNextObjectID();
	bool								_MapObject(AudioObjectID inObjectID, SA_Object* inObject);
	void								_UnmapObject(AudioObjectID inObjectID, SA_Object* inObject);
	SA_Object*							_CopyObjectByObjectID(AudioObjectID inObjectID);
	UInt64								_RetainObject(SA_Object* inObject);
	UInt64								_ReleaseObject(SA_Object* inObject);
	void								_Dump();	

#pragma mark Implemenatation
private:
	typedef std::vector<AudioObjectID>	ObjectIDList;
	struct ObjectInfo
	{
		SA_Object*						mObject;
		UInt64							mReferenceCount;
		ObjectIDList					mObjectIDList;

										ObjectInfo(AudioObjectID inObjectID, SA_Object* inObject)	: mObject(inObject), mReferenceCount(1), mObjectIDList(1, inObjectID) {}
		bool							operator==(AudioObjectID inObjectID) const					{ return std::find(mObjectIDList.begin(), mObjectIDList.end(), inObjectID) != mObjectIDList.end(); }
		bool							operator==(const SA_Object* inObject) const					{ return mObject == inObject; }
	};
	typedef std::vector<ObjectInfo>		ObjectInfoList;
	
	CAMutex								mMutex;
	AudioObjectID						mNextObjectID;
	ObjectInfoList						mObjectInfoList;
	
	static pthread_once_t				sStaticInitializer;
	static SA_ObjectMap*				sInstance;
	
};

//==================================================================================================
//	SA_ObjectReleaser
//==================================================================================================

template <typename T>
class SA_ObjectReleaser
{

#pragma mark Construction/Destruction
public:
	explicit			SA_ObjectReleaser(T* inObject)							: mObject(inObject)	{}
						SA_ObjectReleaser(const SA_ObjectReleaser& inObject)	: mObject(inObject.mObject) { SA_ObjectMap::RetainObject(mObject); }
						~SA_ObjectReleaser()									{ SA_ObjectMap::ReleaseObject(mObject); }
	SA_ObjectReleaser&	operator=(const SA_ObjectReleaser& inObject)			{ if(mObject != inObject.mObject) { SA_ObjectMap::ReleaseObject(mObject); } mObject = inObject.mObject; SA_ObjectMap::RetainObject(mObject); return *this; }
	

#pragma mark Operations
public:
					operator T*() const			{ return mObject; }
	T*				operator ->() const			{ return mObject; }
	bool			IsValid() const				{ return mObject != NULL; }
	T*				GetObject() const			{ return mObject; }

#pragma mark Implementation
private:
	T*				mObject;
	
};

#endif	//	__SA_ObjectMap_h__
