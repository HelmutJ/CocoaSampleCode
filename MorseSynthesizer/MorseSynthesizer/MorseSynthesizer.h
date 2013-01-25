/*
    File: MorseSynthesizer.h
Abstract: The main speech synthesizer code, handling speaking and embedded commands
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

#include <dispatch/dispatch.h>
#include <ApplicationServices/ApplicationServices.h>
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>

@class AudioOutput;
@class MorseTokenBuffer;

//
// Main synthesizer class
//
@interface MorseSynthesizer : NSObject {
	//
	// String encoding for buffer calls
	//
	CFStringEncoding	stringEncodingForBuffer;
	//
	// Audio generation state (fairly idiosyncratic to this example)
	//
	MorseTokenBuffer *	tokens;
	int					pauseToken;
	size_t				unitsLeftInToken;
	BOOL				audioOn;
	//
	// Synthesizer state (applicable to most synthesizers)
	//
	int					synthState;
	float				speechRate;
	float				pitchBase;
	float				volume;
	CFStringRef			openDelim;
	CFStringRef			closeDelim;
	SRefCon				clientRefCon;
	CFStringRef			textBeingSpoken;
	
	//
	// Audio output state (applicable to most synthesizers)
	//
	AudioOutput *		audioOutput;
	ExtAudioFileRef		audioFileRef;	    // Audio file to save to
	bool				audioFileOwned;		// Did we open it?
	AudioDeviceID		audioDevice;		// Audio device to play to	
	//
	// Callbacks
	//
	SpeechTextDoneProcPtr	textDoneCallback;	// Callback to call when we no longer need the input text
	SpeechDoneProcPtr		speechDoneCallback;	// Callback to call when we're done
	SpeechSyncProcPtr		syncCallback;		// Callback to call for sync embedded command
#if SYNTHESIZER_USES_BUFFER_API
	SpeechWordProcPtr		wordCallback;		// Callback to call for each word 
#else
	SpeechWordCFProcPtr		wordCallback;		// Callback to call for each word 
#endif
	//
	// We work through a dispatch queue. It's the modern thing to do
	//
	dispatch_queue_t	queue;
	dispatch_source_t	generateSamples;
}

- (id)init;
- (void)close;	
- (long)useVoice:(VoiceSpec *)voice withBundle:(CFBundleRef)inVoiceSpecBundle;
- (long)startSpeaking:(CFStringRef)text 
	  noEndingProsody:(BOOL)noEndingProsody noInterrupt:(BOOL)noInterrupt 
			preflight:(BOOL)preflight;
- (long)copyPhonemes:(CFStringRef)text result:(CFStringRef *)phonemes;
- (long)stopSpeakingAt:(unsigned long)whereToStop;
- (long)pauseSpeakingAt:(unsigned long)whereToStop;
- (long)continueSpeaking;
- (CFStringEncoding)stringEncodingForBuffer;

+ (long)willUnloadBundle;

@end
