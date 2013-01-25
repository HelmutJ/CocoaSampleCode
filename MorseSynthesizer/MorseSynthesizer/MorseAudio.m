/*
    File: MorseAudio.m
Abstract: Generate audio corresponding to morse code. 

Most of this code is specific to morse encoding and is of little interest 
for speech synthesis in general.
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

#import "MorseSynthesizerPriv.h"
#import "MorseAudio.h"
#import "MorseTokenBuffer.h"
#import "AudioOutput.h"

@implementation MorseSynthesizer (MorseAudioGeneration)

- (void)generateMorseAudio
{
	/*
	 * At typical morse rates (20wpm) and frequencies (440Hz), pitch periods are much shorter 
	 * than the unit length, so we simply round to the nearest half PP and start and end with a 
	 * zero crossing.
	 */
	const size_t		kNumZeros	= 32;
	static const float	sZeros[kNumZeros] = {0.0f};
	
	const float			kUnitInMS	= 1200.0f / speechRate;	/* Per definition http://en.wikipedia.org/wiki/Morse_code */
	const float			kUnitInSamp	= 22.050f * kUnitInMS;
	const float			kHalfPeriod = 11025.0f / pitchBase;
	const size_t		kPeriod		= 22050 / pitchBase;
	
	if (!unitsLeftInToken) {
		// 
		// Load next symbol
		//
		if ([tokens peekNextToken] == kMorseNone || synthState == kSynthPausing) {
			if ([audioOutput audioDone]) {
				dispatch_source_cancel(generateSamples);
				switch (synthState) {
				case kSynthPausing:
				case kSynthPaused:		
					synthState = kSynthPaused;
					break;
				default:
					synthState 		= kSynthStopped;
					CFRelease(textBeingSpoken);
					textBeingSpoken	= NULL;
					if (textDoneCallback) {
						/* The text done callback used to allow clients to pass in more text,
						   but that feature is deprecated. We pass a NULL pointer so clients 
						   will hopefully get the hint.
						*/
						const void * 	nextBuf		= NULL;
						unsigned long 	byteLen		= 0;
						SInt32	   		controlFlags= 0;
						textDoneCallback((SpeechChannel)self, clientRefCon, &nextBuf, &byteLen, &controlFlags);
					}
					if (speechDoneCallback)
						speechDoneCallback((SpeechChannel)self, clientRefCon);
					break;
				}
			}
			return;
		}
		if ([tokens peekNextToken] == pauseToken) {
			switch (synthState) {
			case kSynthStopping:
			case kSynthStopped:		
				break;
			default:
				synthState = kSynthPausing;
				break;
			}
			pauseToken = kMorseNone;
			return;
		}
		MorseToken curToken = [tokens fetchNextToken];
		switch (curToken) {
		case kMorseDit:
			audioOn		= YES;
			unitsLeftInToken	= lroundf(kUnitInSamp / kHalfPeriod);
			break;
		case kMorseDah:
			audioOn		= YES;
			unitsLeftInToken	= lroundf(3.0f * kUnitInSamp / kHalfPeriod);
			break;
		case kMorseMarkGap:
			audioOn		= NO;
			unitsLeftInToken	= lroundf(kUnitInSamp / kNumZeros);
			break;
		case kMorseCharGap:
			audioOn		= NO;
			unitsLeftInToken	= lroundf(3.0f * kUnitInSamp / kNumZeros);
			break;
		case kMorseWordGap:
		case kMorseSentenceGap:
		default:
			audioOn		= NO;
			unitsLeftInToken	= lroundf(7.0f * kUnitInSamp / kNumZeros);
			break;
		case kMorseCallback:
			[tokens executeCallback:self];
			break;
		}
		if (unitsLeftInToken < 1)
			unitsLeftInToken	= 1;
	}
	
	const size_t kEnoughForToday = 4096;
	for (size_t totalSamples = 0; 
		 totalSamples < kEnoughForToday && unitsLeftInToken  
			 && [audioOutput sampleCapacity] >= (audioOn ? kPeriod : kNumZeros); 
		 --unitsLeftInToken
	) {
		if (audioOn) {
			float			samples[1024];
			const size_t	numSamples	= unitsLeftInToken == 1 ? kPeriod / 2 : kPeriod;
			const float		kScale		= 2.0f*M_PI/kPeriod;
			for (size_t i = 0; i<numSamples; ++i)
				samples[i] = sinf(i*kScale)*volume*0.8f;
			[audioOutput queueSamples:samples count:numSamples];
			totalSamples += numSamples;
			if (unitsLeftInToken > 1)
				--unitsLeftInToken;
		} else {
			[audioOutput queueSamples:sZeros count:kNumZeros];
			totalSamples += kNumZeros;
		}
	}
}

@end
