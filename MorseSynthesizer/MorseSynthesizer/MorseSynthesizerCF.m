/*
    File: MorseSynthesizerCF.m
Abstract: Synthesizer code specific to the modern API based on CoreFoundation types
 Version: 1.0

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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#import "MorseSynthesizerCF.h"
#import "MorseSynthesizerPriv.h"
#import "AudioOutput.h"

static CFNumberRef	newFloat(float value)
{
	return CFNumberCreate(NULL, kCFNumberFloatType, &value);
}

static CFNumberRef	newInt(int value)
{
	return CFNumberCreate(NULL, kCFNumberIntType, &value);
}

static CFNumberRef	newPtr(void * value)
{
	return CFNumberCreate(NULL, kCFNumberLongType, &value);
}

@implementation MorseSynthesizer (CoreFoundationBasedCalls)

- (long)copyProperty:(CFStringRef)property result:(CFTypeRef *)object
{
	if (!CFStringCompare(property, kSpeechInputModeProperty, 0))
		*object = CFRetain(kSpeechModeText);
	else if (!CFStringCompare(property, kSpeechCharacterModeProperty, 0))
		*object = CFRetain(kSpeechModeNormal);
	else if (!CFStringCompare(property, kSpeechNumberModeProperty, 0))
		*object = CFRetain(kSpeechModeNormal);
	else if (!CFStringCompare(property, kSpeechRateProperty, 0))
		*object = newFloat(speechRate);
	else if (!CFStringCompare(property, kSpeechPitchBaseProperty, 0))
		*object = newFloat(pitchBase);
	else if (!CFStringCompare(property, kSpeechPitchModProperty, 0))
		*object = newFloat(0.0f);
	else if (!CFStringCompare(property, kSpeechVolumeProperty, 0))
		*object = newFloat(volume);
	else if (!CFStringCompare(property, kSpeechStatusProperty, 0)) {
		CFTypeRef statusKeys[4];
		CFTypeRef statusValues[4];
		
		statusKeys[0]	= kSpeechStatusOutputBusy;
		statusValues[0]	= newInt(synthState == kSynthStopped || synthState == kSynthPaused ? 0 : 1);
		statusKeys[1]	= kSpeechStatusOutputPaused;
		statusValues[1]	= newInt(synthState == kSynthPaused ? 1 : 0);
		statusKeys[2]	= kSpeechStatusNumberOfCharactersLeft;
		statusValues[2]	= newInt(0);
		statusKeys[3]	= kSpeechStatusPhonemeCode;
		statusValues[3]	= newInt(0);
		
		*object = CFDictionaryCreate(NULL, statusKeys, statusValues, 4, 
									 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(statusValues[0]);
		CFRelease(statusValues[1]);
		CFRelease(statusValues[2]);
		CFRelease(statusValues[3]);
	} else if (!CFStringCompare(property, CFSTR("aunt"), 0)) { /* soAudioUnit */
		/* 
		 * If we're used from within an audio unit, we can safely assume that 
		 * one of the three following property calls is issued before anything
		 * else could happen that would cause a sound channel to be created.
		 */
		[self createSoundChannel:YES];
		*object = newPtr([audioOutput getSourceUnit]);
	} else if (!CFStringCompare(property, CFSTR("augr"), 0)) { /* soAudioGraph */
		[self createSoundChannel:YES];
		*object = newPtr([audioOutput getSourceGraph]);
	} else if (!CFStringCompare(property, CFSTR("offl"), 0)) { /* soOfflineMode */
		[self createSoundChannel:YES];
		*object = newInt([audioOutput offlineProcessing]);
	} else 
		return siUnknownInfoType;
	
	return noErr;
}

- (long) setProperty:(CFStringRef)property value:(CFTypeRef)object
{
	if (!CFStringCompare(property, kSpeechRateProperty, 0))
		CFNumberGetValue((CFNumberRef)object, kCFNumberFloatType, &speechRate);
	else if (!CFStringCompare(property, kSpeechPitchBaseProperty, 0))
		CFNumberGetValue((CFNumberRef)object, kCFNumberFloatType, &pitchBase);
	else if (!CFStringCompare(property, kSpeechVolumeProperty, 0))
		CFNumberGetValue((CFNumberRef)object, kCFNumberFloatType, &volume);
	else if (!CFStringCompare(property, kSpeechRefConProperty, 0)) 
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &clientRefCon);
	else if (!CFStringCompare(property, kSpeechOutputToFileURLProperty, 0)) { 
		//
		// Always dispose of previous sound arrangements
		//
		[self disposeSoundChannel];
		if (object) {
			//
			// Client is specifying a file to save the output to. We default to the format traditionally written
			// by Macintalk. Set audioFileRef, the AudioOutput itself will be created lazily.
			//
			static const AudioStreamBasicDescription sDefaultAudioFormat = {
				22050.0, kAudioFormatLinearPCM, 
				kAudioFormatFlagIsPacked | kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger,
				2, 1, 2, 1, 16, 0
			};								   
			OSErr theErr = ExtAudioFileCreateWithURL((CFURLRef)object, kAudioFileAIFFType,
													 &sDefaultAudioFormat, NULL, kAudioFileFlags_EraseFile,
													 &audioFileRef);
			if (!theErr) { 
				audioFileOwned = true;
			} else {
				//
				// Set to non-NULL. We will discard the sound output, so we can handle stuff like writing to /dev/null
				//
				audioFileRef	= (ExtAudioFileRef)-1;
			}
		}
	} else if (!CFStringCompare(property, kSpeechOutputToExtAudioFileProperty, 0)) { 
		//
		// Always dispose of previous sound arrangements
		//
		[self disposeSoundChannel];
		//
		// Set fAudioFileRef, the AudioOutput itself will be created lazily.
		//
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &audioFileRef);	
	} else if (!CFStringCompare(property, kSpeechOutputToAudioDeviceProperty, 0)) { 
		AudioDeviceID newAudioDevice;
		CFNumberGetValue((CFNumberRef)object, kCFNumberSInt32Type, &newAudioDevice);
		//
		// Dispose of previous sound arrangements unless they remain unchanged.
		//
		if (audioFileRef || audioDevice != newAudioDevice) {
			[self disposeSoundChannel];
			//
			// Set fAudioDevice, the AudioOutput itself will be created lazily.
			//
			audioDevice = newAudioDevice;
		}
	} else if (!CFStringCompare(property, CFSTR("offl"), 0)) { // soOfflineMode
		SInt8 offline;
		CFNumberGetValue((CFNumberRef)object, kCFNumberSInt8Type, &offline);
		[self createSoundChannel:YES];
		[audioOutput setOfflineProcessing:offline];
	} else if (!CFStringCompare(property, kSpeechSpeechDoneCallBack, 0)) {
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &speechDoneCallback);
	} else if (!CFStringCompare(property, kSpeechSyncCallBack, 0)) {
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &syncCallback);
	} else if (!CFStringCompare(property, kSpeechWordCFCallBack, 0)) {
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &wordCallback);
	} else if (!CFStringCompare(property, kSpeechTextDoneCallBack, 0)) {
		CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &textDoneCallback);
	} else if (!CFStringCompare(property, kSpeechErrorCFCallBack, 0)
		    || !CFStringCompare(property, kSpeechPhonemeCallBack, 0)
	) {
		; // Ignore for now
	} else 
		return siUnknownInfoType;

	return noErr;
}

- (long)useDictionary:(CFDictionaryRef)dictionary
{
    /* Not yet implemented */
    return noErr;
}

@end

