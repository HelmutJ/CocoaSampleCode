/*
    File: MorseSynthesizerBuffer.m
Abstract: Synthesizer code specific to the legacy, buffer based API
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

#import "MorseSynthesizerBuffer.h"
#import "MorseSynthesizerPriv.h"
#import "AudioOutput.h"

@implementation MorseSynthesizer (BufferBasedCalls)

- (long)getSpeechInfo:(unsigned long) selector result:(void *)speechInfo
{
	switch (selector) {
	case soInputMode:
		*(unsigned long *)speechInfo = 'TEXT';
		break;
	case soCharacterMode:
		*(unsigned long *)speechInfo = 'NORM';
		break;
	case soNumberMode:
		*(unsigned long *)speechInfo = 'NORM';
		break;
	case soRate:
		*(Fixed *)speechInfo = speechRate * 65536.0f;
		break;
	case soPitchBase:
		*(Fixed *)speechInfo = pitchBase * 65536.0f;
		break;
	case soPitchMod:
		*(Fixed *)speechInfo = 0;
		break;
	case soVolume:
		*(Fixed *)speechInfo = volume * 65536.0f;
		break;
	case soStatus:
		((SpeechStatusInfo *)speechInfo)->outputBusy = 
			synthState != kSynthStopped && synthState != kSynthPaused;
		((SpeechStatusInfo *)speechInfo)->outputPaused = 
			synthState == kSynthPaused;
		((SpeechStatusInfo *)speechInfo)->inputBytesLeft = 0;
		((SpeechStatusInfo *)speechInfo)->phonemeCode	= 0;
		break;
	case 'aunt': // soAudioUnit
		/* 
		 * If we're used from within an audio unit, we can safely assume that 
		 * one of the three following property calls is issued before anything
		 * else could happen that would cause a sound channel to be created.
		 */
		[self createSoundChannel:YES];
		*(AudioUnit *)speechInfo = [audioOutput getSourceUnit];
		break;
	case 'augr': // soAudioGraph
		//
		// Set up a sound channel suitable for the audio unit
		//
		[self createSoundChannel:YES];
		*(AUGraph *)speechInfo = [audioOutput getSourceGraph];
		break;
	case 'offl': // soOfflineMode
		//
		// Set up a sound channel suitable for the audio unit
		//
		[self createSoundChannel:YES];
		*(int *)speechInfo	= [audioOutput offlineProcessing];
		break;
	default:
		return siUnknownInfoType;
	}
	return noErr;
}

- (long)setSpeechInfo:(unsigned long)selector info:(void*)speechInfo
{
	switch (selector) {
	case soRate:
		speechRate = *(Fixed *)speechInfo / 65536.0f;
		break;
	case soPitchBase:
		pitchBase = *(Fixed *)speechInfo / 65536.0f;
		break;
	case soVolume:
		volume = *(Fixed *)speechInfo / 65536.0f;
		break;
	case soOutputToFileWithCFURL:
		//
		// Always dispose of previous sound arrangements
		//
		[self disposeSoundChannel];
		if (speechInfo) {
			//
			// Client is specifying a file to save the output to. We default to the format traditionally written
			// by Macintalk. Set fAudioFileRef, the AudioOutput itself will be created lazily.
			//
			static const AudioStreamBasicDescription sDefaultAudioFormat = {
				22050.0, kAudioFormatLinearPCM, 
				kAudioFormatFlagIsPacked | kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger,
				2, 1, 2, 1, 16, 0
			};								   
			OSErr theErr = ExtAudioFileCreateWithURL((CFURLRef)speechInfo, kAudioFileAIFFType,
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
		break;
	case soOutputToExtAudioFile:
		//
		// Always dispose of previous sound arrangements
		//
		[self disposeSoundChannel];
		//
		// Set audioFileRef, the AudioOutput itself will be created lazily.
		//
		audioFileRef = (ExtAudioFileRef)speechInfo;
		break;
	case soOutputToAudioDevice: {
		AudioDeviceID newAudioDevice = *(AudioDeviceID *)speechInfo;
		//
		// Dispose of previous sound arrangements unless they remain unchanged.
		//
		if (audioFileRef || audioDevice != newAudioDevice) {
			[self disposeSoundChannel];
			//
			// Set fAudioDevice, the AudioOutput itself will be created lazily.
			//
			audioDevice = newAudioDevice;
		}}
		break;
	case 'offl': // soOfflineMode
		[self createSoundChannel:YES];
		[audioOutput setOfflineProcessing:*(int *)speechInfo];
		break;
	case soRefCon:
		clientRefCon = *(long *)speechInfo;
		break;
	case soSpeechDoneCallBack:
		speechDoneCallback = (SpeechDoneUPP)speechInfo;
		break;
	case soSyncCallBack:
		syncCallback = (SpeechSyncUPP)speechInfo;
		break;
	case soWordCallBack:
		wordCallback = (SpeechWordUPP)speechInfo;
		break;
	case soTextDoneCallBack:
		textDoneCallback = (SpeechTextDoneUPP)speechInfo;
		break;
	case soErrorCallBack:
	case soPhonemeCallBack:
		// Ignore for now
		break;
	default:
		return siUnknownInfoType;
	}
	
	return noErr;
}

- (long)useDictionary:(void *)dictionary length:(CFIndex)length
{
    /* Not yet implemented */
    return noErr;
}

@end

