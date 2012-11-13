/*
     File: SimpleAudioDriverTypes.h
 Abstract: SimpleAudioDriverTypes.h
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
	SimpleAudioDriverTypes.h
==================================================================================================*/
#if !defined(__SimpleAudioDriverTypes_h__)
#define __SimpleAudioDriverTypes_h__

//==================================================================================================
//	Constants
//==================================================================================================

//	the class name for the part of the driver for which a matching notificaiton will be created
#define kSimpleAudioDriverClassName	"com_apple_audio_SimpleAudioDriver"

//	IORegistry keys that have the basic info about the driver
#define kSimpleAudioDriver_RegistryKey_SampleRate			"sample rate"
#define kSimpleAudioDriver_RegistryKey_RingBufferFrameSize	"buffer frame size"
#define kSimpleAudioDriver_RegistryKey_DeviceUID			"device UID"

//	memory types
enum
{
	kSimpleAudioDriver_Buffer_Status,
	kSimpleAudioDriver_Buffer_Input,
	kSimpleAudioDriver_Buffer_Output
};

//	user client method selectors
enum
{
	kSimpleAudioDriver_Method_Open,				//	No arguments
	kSimpleAudioDriver_Method_Close,			//	No arguments
	kSimpleAudioDriver_Method_StartHardware,	//	No arguments
	kSimpleAudioDriver_Method_StopHardware,		//	No arguments
	kSimpleAudioDriver_Method_SetSampleRate,	//	One input: the new sample rate as a 64 bit integer
	kSimpleAudioDriver_Method_GetControlValue,	//	One input: the control ID, One output: the control value
	kSimpleAudioDriver_Method_SetControlValue,	//	Two inputs, the control ID and the new value
	kSimpleAudioDriver_Method_NumberOfMethods
};

//	control IDs
enum
{
	kSimpleAudioDriver_Control_MasterInputVolume,
	kSimpleAudioDriver_Control_MasterOutputVolume
};

//	volume control ranges
#define kSimpleAudioDriver_Control_MinRawVolumeValue	0
#define kSimpleAudioDriver_Control_MaxRawVolumeValue	96
#define kSimpleAudioDriver_Control_MinDBVolumeValue		-96.0f
#define kSimpleAudioDriver_Control_MaxDbVolumeValue		0.0f

//	the struct in the status buffer
struct SimpleAudioDriverStatus
{
	volatile UInt64	mSampleTime;
	volatile UInt64	mHostTime;
};
typedef struct SimpleAudioDriverStatus	SimpleAudioDriverStatus;

#endif	//	__SimpleAudioDriverTypes_h__
