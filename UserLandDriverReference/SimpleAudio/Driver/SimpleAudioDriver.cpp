/*
     File: SimpleAudioDriver.cpp
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
	SimpleAudioDriver.cpp
==================================================================================================*/

//==================================================================================================
//	Includes
//==================================================================================================

//	Self Include
#include "SimpleAudioDriver.h"

//	System Includes
#include <IOKit/IOBufferMemoryDescriptor.h>
#include <IOKit/IOCommandGate.h>
#include <IOKit/IOTimerEventSource.h>

//==================================================================================================
//	SimpleAudioDriver
//==================================================================================================

OSDefineMetaClassAndStructors(com_apple_audio_SimpleAudioDriver, IOService)

bool	SimpleAudioDriver::start(IOService* inProvider)
{
	//	start the superclass
    bool theAnswer = IOService::start(inProvider);
    if(theAnswer)
	{
		//	create the work loop
		mWorkLoop = IOWorkLoop::workLoop();
		FailIfNULL(mWorkLoop, theAnswer = kIOReturnNoResources, Failure, "SimpleAudioDriver::start: couldn't allocate the work loop");
		
		//	create the command gate
		mCommandGate = IOCommandGate::commandGate(this);
		FailIfNULL(mWorkLoop, theAnswer = kIOReturnNoResources, Failure, "SimpleAudioDriver::start: couldn't allocate the command gate");
		
		//	attach it to the work loop
		mWorkLoop->addEventSource(mCommandGate);
		
		//	initialize the stuff tracked by the IORegistry
		mSampleRate = 44100;
		setProperty(kSimpleAudioDriver_RegistryKey_SampleRate, mSampleRate, sizeof(mSampleRate) * 8);
		
		mIOBufferFrameSize = 16384;
		setProperty(kSimpleAudioDriver_RegistryKey_RingBufferFrameSize, mIOBufferFrameSize, sizeof(mIOBufferFrameSize) * 8);
		
		char theDeviceUID[128];
		snprintf(theDeviceUID, 128, "SimpleAudioDevice-%d", static_cast<int>(random() % 100000));
		setProperty(kSimpleAudioDriver_RegistryKey_DeviceUID, theDeviceUID);

		//	allocate the IO buffers
		IOReturn theError = allocateBuffers();
		FailIfError(theError, theAnswer = false, Failure, "SimpleAudioDriver::start: allocating the buffers failed");
		
		//	initialize the timer that stands in for a real interrupt
		theError = initTimer();
		FailIfError(theError, freeBuffers(); theAnswer = false, Failure, "SimpleAudioDriver::start: initializing the timer failed");
		
		//	initialize the controls
		theError = initControls();
		FailIfError(theError, theAnswer = false, Failure, "SimpleAudioDriver::start: initializing the controls failed");
		
		//	publish ourselves
		registerService();
	}

    return theAnswer;

Failure:
	if(mCommandGate != NULL)
	{
		if(mWorkLoop != NULL)
		{
			mWorkLoop->removeEventSource(mCommandGate);
			mCommandGate->release();
			mCommandGate = NULL;
		}
	}
	
	if(mWorkLoop != NULL)
	{
		mWorkLoop->release();
		mWorkLoop = NULL;
	}
	
	freeBuffers();
	destroyTimer();
	
	return theAnswer;
}

void	SimpleAudioDriver::stop(IOService* inProvider)
{
	//	tear things down
	freeBuffers();
	destroyTimer();
	if(mCommandGate != NULL)
	{
		if(mWorkLoop != NULL)
		{
			mWorkLoop->removeEventSource(mCommandGate);
			mCommandGate->release();
			mCommandGate = NULL;
		}
	}
	if(mWorkLoop != NULL)
	{
		mWorkLoop->release();
		mWorkLoop = NULL;
	}
    IOService::stop(inProvider);
}

IOBufferMemoryDescriptor*	SimpleAudioDriver::getBuffer(int inBufferType)
{
	//	we gate the external methods onto the work loop for thread safety
	IOBufferMemoryDescriptor* theAnswer = NULL;
	if(mCommandGate != NULL)
	{
		mCommandGate->runAction(_getBuffer, &inBufferType, &theAnswer);
	}
	return theAnswer;
}

IOReturn SimpleAudioDriver::startHardware()
{
	//	we gate the external methods onto the work loop for thread safety
	IOReturn theAnswer = kIOReturnSuccess;
	if(mCommandGate != NULL)
	{
		theAnswer = mCommandGate->runAction(_startHardware);
	}
	else
	{
		theAnswer = kIOReturnNoResources;
	}
	return theAnswer;
}

void SimpleAudioDriver::stopHardware()
{
	//	we gate the external methods onto the work loop for thread safety
	if(mCommandGate != NULL)
	{
		mCommandGate->runAction(_stopHardware);
	}
}

IOReturn SimpleAudioDriver::setSampleRate(UInt64 inNewSampleRate)
{
	//	we gate the external methods onto the work loop for thread safety
	IOReturn theAnswer = kIOReturnSuccess;
	if(mCommandGate != NULL)
	{
		theAnswer = mCommandGate->runAction(_setSampleRate, &inNewSampleRate);
	}
	else
	{
		theAnswer = kIOReturnNoResources;
	}
	return theAnswer;
}

IOReturn SimpleAudioDriver::_getBuffer(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	#pragma unused(inArg2, inArg3)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriver* theDriver = NULL;
	const int* theBufferType = NULL;
	IOBufferMemoryDescriptor** theBuffer = NULL;
	
	//	cast the arguments back to what they need to be
	theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	FailIfNULL(theDriver, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: this is not a SimpleAudioDriver");
	
	theBufferType = reinterpret_cast<const int*>(inArg0);
	FailIfNULL(theBufferType, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no buffer type");

	theBuffer = reinterpret_cast<IOBufferMemoryDescriptor**>(inArg1);
	FailIfNULL(theBuffer, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no buffer");
	
	switch(*theBufferType)
	{
		case kSimpleAudioDriver_Buffer_Status:
			*theBuffer = theDriver->mStatusBuffer;
			break;
			
		case kSimpleAudioDriver_Buffer_Input:
			*theBuffer = theDriver->mInputBuffer;
			break;
			
		case kSimpleAudioDriver_Buffer_Output:
			*theBuffer = theDriver->mOutputBuffer;
			break;
	};

Done:
	return theAnswer;
}
	
IOReturn SimpleAudioDriver::_startHardware(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	//	This driver uses a work loop timer to simulate an interrupt to driver the timing
	
	#pragma unused(inArg0, inArg1, inArg2, inArg3)
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	cast the arguments back to what they need to be
	SimpleAudioDriver* theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	FailIfNULL(theDriver, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: this is not a SimpleAudioDriver");
	
	if(!theDriver->mIsRunning)
	{
		if((theDriver->mInputBuffer != NULL) && (theDriver->mOutputBuffer != NULL))
		{
			//	clear the buffers
			bzero(theDriver->mInputBuffer->getBytesNoCopy(), theDriver->mInputBuffer->getCapacity());
			bzero(theDriver->mOutputBuffer->getBytesNoCopy(), theDriver->mOutputBuffer->getCapacity());
			
			//	start the timer
			theAnswer = theDriver->startTimer();
			FailIfError(theAnswer, , Done, "SimpleAudioDriver::_startHardware: starting the timer failed");
			
			//	update the is running state
			theDriver->mIsRunning = true;
		}
		else
		{
			theAnswer = kIOReturnNoResources;
		}
	}

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriver::_stopHardware(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	//	cast the arguments back to what they need to be
	#pragma unused(inArg0, inArg1, inArg2, inArg3)
	SimpleAudioDriver* theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	if((theDriver != NULL) && theDriver->mIsRunning)
	{
		//	all we need to do is stop the timer
		theDriver->stopTimer();
		theDriver->mIsRunning = false;
	}
	return kIOReturnSuccess;
}

IOReturn	SimpleAudioDriver::_setSampleRate(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	#pragma unused(inArg1, inArg2, inArg3)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriver* theDriver = NULL;
	const UInt64* theNewSampleRate = NULL;
	
	//	cast the arguments back to what they need to be
	theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	FailIfNULL(theDriver, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_setSampleRate: this is not a SimpleAudioDriver");
	
	theNewSampleRate = reinterpret_cast<const UInt64*>(inArg0);
	FailIfNULL(theNewSampleRate, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_setSampleRate: no new sample rate");
	
	//	make sure that IO is stopped
	FailIf(theDriver->mIsRunning, theAnswer = kIOReturnNotPermitted, Done, "SimpleAudioDriver::_setSampleRate: can't change the sample rate while IO is running");

	//	make sure the sample rate is something we support
	if((*theNewSampleRate == 44100) || (*theNewSampleRate == 48000))
	{
		theDriver->mSampleRate = *theNewSampleRate;
		theDriver->setProperty(kSimpleAudioDriver_RegistryKey_SampleRate, theDriver->mSampleRate, sizeof(theDriver->mSampleRate) * 8);
		theDriver->updateTimer();
	}
	else
	{
		theAnswer = kIOReturnUnsupported;
	}

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriver::getVolume(int inVolumeID, UInt32& outVolume)
{
	//	we gate the external methods onto the work loop for thread safety
	IOReturn theAnswer = 0;
	if(mCommandGate != NULL)
	{
		theAnswer = mCommandGate->runAction(_getVolume, &inVolumeID, &outVolume);
	}
	return theAnswer;
}

IOReturn SimpleAudioDriver::setVolume(int inVolumeID, UInt32 inNewVolume)
{
	//	we gate the external methods onto the work loop for thread safety
	IOReturn theAnswer = kIOReturnSuccess;
	if(mCommandGate != NULL)
	{
		theAnswer = mCommandGate->runAction(_setVolume, &inVolumeID, &inNewVolume);
	}
	else
	{
		theAnswer = kIOReturnNoResources;
	}
	return theAnswer;
}

IOReturn	SimpleAudioDriver::_getVolume(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	#pragma unused(inArg2, inArg3)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriver* theDriver = NULL;
	const int* theControlID = NULL;
	UInt32* theControlValue = NULL;
	
	//	cast the arguments back to what they need to be
	theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	FailIfNULL(theDriver, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: this is not a SimpleAudioDriver");
	
	theControlID = reinterpret_cast<const int*>(inArg0);
	FailIfNULL(theControlID, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no control ID");

	theControlValue = reinterpret_cast<UInt32*>(inArg1);
	FailIfNULL(theControlValue, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no control value");
	
	switch(*theControlID)
	{
		case kSimpleAudioDriver_Control_MasterInputVolume:
			*theControlValue = theDriver->mMasterInputVolume;
			break;
			
		case kSimpleAudioDriver_Control_MasterOutputVolume:
			*theControlValue = theDriver->mMasterOutputVolume;
			break;
	};

Done:
	return theAnswer;
}

IOReturn	SimpleAudioDriver::_setVolume(OSObject* inTarget, void* inArg0, void* inArg1, void* inArg2, void* inArg3)
{
	#pragma unused(inArg2, inArg3)
	IOReturn theAnswer = kIOReturnSuccess;
	SimpleAudioDriver* theDriver = NULL;
	const int* theControlID = NULL;
	const UInt32* theNewControlValue = NULL;
	
	//	cast the arguments back to what they need to be
	theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	FailIfNULL(theDriver, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: this is not a SimpleAudioDriver");
	
	theControlID = reinterpret_cast<const int*>(inArg0);
	FailIfNULL(theControlID, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no control ID");

	theNewControlValue = reinterpret_cast<UInt32*>(inArg1);
	FailIfNULL(theNewControlValue, theAnswer = kIOReturnBadArgument, Done, "SimpleAudioDriver::_startHardware: no control value");
	
	switch(*theControlID)
	{
		case kSimpleAudioDriver_Control_MasterInputVolume:
			theDriver->mMasterInputVolume = *theNewControlValue;
			if(theDriver->mMasterInputVolume > kSimpleAudioDriver_Control_MaxRawVolumeValue)
			{
				theDriver->mMasterInputVolume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
			}
			break;
			
		case kSimpleAudioDriver_Control_MasterOutputVolume:
			theDriver->mMasterOutputVolume = *theNewControlValue;
			if(theDriver->mMasterOutputVolume > kSimpleAudioDriver_Control_MaxRawVolumeValue)
			{
				theDriver->mMasterOutputVolume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
			}
			break;
	};

Done:
	return theAnswer;
}

IOReturn SimpleAudioDriver::allocateBuffers()
{
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	The status buffer holds the zero time stamp when IO is running
	mStatusBuffer = IOBufferMemoryDescriptor::withOptions(kIOMemoryKernelUserShared, sizeof(SimpleAudioDriverStatus));
	FailIfNULL(mStatusBuffer, theAnswer = kIOReturnNoMemory, Failure, "SimpleAudioDriver::allocateBuffers: failed to allocate the status buffer");
	bzero(mStatusBuffer->getBytesNoCopy(), mStatusBuffer->getCapacity());

	//	These are the ring buffers for transmitting the audio data
	
	//	Note that for this driver the samples are always 16 bit stereo	
	mInputBuffer = IOBufferMemoryDescriptor::withOptions(kIOMemoryKernelUserShared, mIOBufferFrameSize * 2 * 2);
	FailIfNULL(mInputBuffer, theAnswer = kIOReturnNoMemory, Failure, "SimpleAudioDriver::allocateBuffers: failed to allocate the input buffer");
	bzero(mInputBuffer->getBytesNoCopy(), mInputBuffer->getCapacity());

	mOutputBuffer = IOBufferMemoryDescriptor::withOptions(kIOMemoryKernelUserShared, mIOBufferFrameSize * 2 * 2);
	FailIfNULL(mOutputBuffer, theAnswer = kIOReturnNoMemory, Failure, "SimpleAudioDriver::allocateBuffers: failed to allocate the output buffer");
	bzero(mOutputBuffer->getBytesNoCopy(), mOutputBuffer->getCapacity());
	
	return kIOReturnSuccess;

Failure:
	if(mStatusBuffer != NULL)
	{
		mStatusBuffer->release();
		mStatusBuffer = NULL;
	}
	
	if(mInputBuffer != NULL)
	{
		mInputBuffer->release();
		mInputBuffer = NULL;
	}
	
	if(mOutputBuffer != NULL)
	{
		mOutputBuffer->release();
		mOutputBuffer = NULL;
	}
	
	return theAnswer;
}

void	SimpleAudioDriver::freeBuffers()
{
	if(mStatusBuffer != NULL)
	{
		mStatusBuffer->release();
		mStatusBuffer = NULL;
	}
	
	if(mInputBuffer != NULL)
	{
		mInputBuffer->release();
		mInputBuffer = NULL;
	}
	
	if(mOutputBuffer != NULL)
	{
		mOutputBuffer->release();
		mOutputBuffer = NULL;
	}
}

IOReturn SimpleAudioDriver::initTimer()
{
	IOReturn theAnswer = kIOReturnSuccess;
	
	//	create the timer event source that will be our fake interrupt
	mTimerEventSource = IOTimerEventSource::timerEventSource(this, timerFired);
	FailIfNULL(mTimerEventSource, theAnswer = kIOReturnNoResources, Failure, "SimpleAudioDriver::initTimer: couldn't allocate the timer event source");
	
	//	add the timer to the work loop
	mWorkLoop->addEventSource(mTimerEventSource);

	//	calculate how many ticks are in each buffer
	updateTimer();
	
	return kIOReturnSuccess;

Failure:
	if(mTimerEventSource != NULL)
	{
		if(mWorkLoop != NULL)
		{
			mWorkLoop->removeEventSource(mTimerEventSource);
		}
		mTimerEventSource->release();
		mTimerEventSource = NULL;
	}

	if(mWorkLoop != NULL)
	{
		mWorkLoop->release();
		mWorkLoop = NULL;
	}
	
	return theAnswer;
}

void	SimpleAudioDriver::destroyTimer()
{
	if(mTimerEventSource != NULL)
	{
		if(mWorkLoop != NULL)
		{
			mWorkLoop->removeEventSource(mTimerEventSource);
		}
		mTimerEventSource->release();
		mTimerEventSource = NULL;
	}

	if(mWorkLoop != NULL)
	{
		mWorkLoop->release();
		mWorkLoop = NULL;
	}
}

IOReturn SimpleAudioDriver::startTimer()
{
	IOReturn theAnswer = kIOReturnSuccess;
	
	if((mStatusBuffer != NULL) && (mTimerEventSource != NULL))
	{
		//	clear the status buffer
		SimpleAudioDriverStatus* theStatus = (SimpleAudioDriverStatus*)mStatusBuffer->getBytesNoCopy();
		theStatus->mSampleTime = 0;
		theStatus->mHostTime = 0;
		
		//	calculate how many ticks are in each buffer
		struct mach_timebase_info theTimeBaseInfo;
		clock_timebase_info(&theTimeBaseInfo);
		mHostTicksPerBuffer = (mIOBufferFrameSize * 1000000000ULL) / mSampleRate;
		mHostTicksPerBuffer = (mHostTicksPerBuffer * theTimeBaseInfo.denom) / theTimeBaseInfo.numer;
			
		//	start the timer, the first time stamp will be taken when it goes off
		union { UInt64 mUInt64; AbsoluteTime mAbsoluteTime; } theNextWakeTime;
		theNextWakeTime.mUInt64 = mHostTicksPerBuffer;
		mTimerEventSource->setTimeout(theNextWakeTime.mAbsoluteTime);
	}
	else
	{
		theAnswer = kIOReturnNoResources;
	}
	
	return theAnswer;
}

void	SimpleAudioDriver::stopTimer()
{
	if(mTimerEventSource != NULL)
	{
		mTimerEventSource->cancelTimeout();
	}
}

void	SimpleAudioDriver::updateTimer()
{
	struct mach_timebase_info theTimeBaseInfo;
	clock_timebase_info(&theTimeBaseInfo);
	mHostTicksPerBuffer = (mIOBufferFrameSize * 1000000000ULL) / mSampleRate;
	mHostTicksPerBuffer = (mHostTicksPerBuffer * theTimeBaseInfo.denom) / theTimeBaseInfo.numer;
}

void	SimpleAudioDriver::timerFired(OSObject* inTarget, IOTimerEventSource* inSender)
{
	//	validate the engine
	SimpleAudioDriver* theDriver = OSDynamicCast(SimpleAudioDriver, inTarget);
	if((theDriver != NULL) && (theDriver->mStatusBuffer != NULL))
	{
		//	get the status buffer
		SimpleAudioDriverStatus* theStatus = (SimpleAudioDriverStatus*)theDriver->mStatusBuffer->getBytesNoCopy();
		
		//	get the current time
		UInt64 theCurrentTime = 0;
		clock_get_uptime((AbsoluteTime*)&theCurrentTime);
		
		//	increment the time stamps
		if(theStatus->mHostTime != 0)
		{
			theStatus->mSampleTime += theDriver->mIOBufferFrameSize;
			theStatus->mHostTime += theDriver->mHostTicksPerBuffer;
		}
		else
		{
			//	but not if it's the first one
			theStatus->mSampleTime = 0;
			theStatus->mHostTime = theCurrentTime;
		}
		
		//	set the timer to go off in one buffer
		union { UInt64 mUInt64; AbsoluteTime mAbsoluteTime; } theNextWakeTime;
		theNextWakeTime.mUInt64 = theStatus->mHostTime + theDriver->mHostTicksPerBuffer;
		inSender->wakeAtTime(theNextWakeTime.mAbsoluteTime);
	}
}

IOReturn	SimpleAudioDriver::initControls()
{
	mMasterInputVolume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
	mMasterOutputVolume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
	return kIOReturnSuccess;
}
