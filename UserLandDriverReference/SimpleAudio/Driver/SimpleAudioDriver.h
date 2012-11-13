/*
     File: SimpleAudioDriver.h
 Abstract: SimpleAudioDriver.h
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
	SimpleAudioDriver.h
==================================================================================================*/
#if !defined(__SimpleAudioDriver_h__)
#define __SimpleAudioDriver_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	Super Class Includes
#include <IOKit/IOService.h>

//	Loal Includes
#include "SimpleAudioDriverTypes.h"

//	System Includes
#include <IOKit/IOLib.h>

//==================================================================================================
//	Types
//==================================================================================================

class IOBufferMemoryDescriptor;

//==================================================================================================
//	SimpleAudioDriver
//==================================================================================================

#define SimpleAudioDriver	com_apple_audio_SimpleAudioDriver

class SimpleAudioDriver
:
	public	IOService
{

//	Construction/Destruction
	OSDeclareDefaultStructors(com_apple_audio_SimpleAudioDriver)
	
public:
	virtual bool				start(IOService* inProvider);
	virtual void				stop(IOService* inProvider);

//	IO Management
public:
	IOBufferMemoryDescriptor*	getBuffer(int inBufferType);
	IOReturn					startHardware();
	void						stopHardware();
	IOReturn					setSampleRate(UInt64 inNewSampleRate);

private:
	static IOReturn				_getBuffer(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);
	static IOReturn				_startHardware(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);
	static IOReturn				_stopHardware(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);
	static IOReturn				_setSampleRate(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);

//	Controls
public:
	IOReturn					getVolume(int inVolumeID, UInt32& outVolume);
	IOReturn					setVolume(int inVolumeID, UInt32 inNewVolume);

private:
	static IOReturn				_getVolume(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);
	static IOReturn				_setVolume(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3);

//	Implementation
private:
	IOReturn					allocateBuffers();
	void						freeBuffers();
	
	IOReturn					initTimer();
	void						destroyTimer();
	IOReturn					startTimer();
	void						stopTimer();
	void						updateTimer();
	static void					timerFired(OSObject* inTarget, IOTimerEventSource* inSender);
	
	IOReturn					initControls();

	IOWorkLoop*					mWorkLoop;
	IOCommandGate*				mCommandGate;
	
	IOBufferMemoryDescriptor*	mStatusBuffer;
	IOBufferMemoryDescriptor*	mInputBuffer;
	IOBufferMemoryDescriptor*	mOutputBuffer;
	UInt64						mIOBufferFrameSize;
	
	IOTimerEventSource*			mTimerEventSource;
	bool						mIsRunning;
	UInt64						mSampleRate;
	UInt64						mHostTicksPerBuffer;
	
	UInt32						mMasterInputVolume;
	UInt32						mMasterOutputVolume;

};

//==================================================================================================
//	Macros for error handling
//==================================================================================================

#define	DebugMsg(inFormat, ...)	IOLog(inFormat "\n", ## __VA_ARGS__)

#define	FailIf(inCondition, inAction, inHandler, inMessage)									\
			{																				\
				bool __failed = (inCondition);												\
				if(__failed)																\
				{																			\
					DebugMsg(inMessage);													\
					{ inAction; }															\
					goto inHandler;															\
				}																			\
			}

#define	FailIfError(inError, inAction, inHandler, inMessage)								\
			{																				\
				IOReturn __Err = (inError);													\
				if(__Err != 0)																\
				{																			\
					DebugMsg(inMessage ", Error: %d (0x%X)", __Err, (unsigned int)__Err);	\
					{ inAction; }															\
					goto inHandler;															\
				}																			\
			}

#define	FailIfNULL(inPointer, inAction, inHandler, inMessage)								\
			if((inPointer) == NULL)															\
			{																				\
				DebugMsg(inMessage);														\
				{ inAction; }																\
				goto inHandler;																\
			}

#endif	//	__SimpleAudioDriver_h__
