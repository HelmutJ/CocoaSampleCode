/*
    File: MorseSynthesizer.m
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

#import "MorseSynthesizerPriv.h"
#import "MorseTokenBuffer.h"
#import "MorseAudio.h"
#import "AudioOutput.h"

#include <ApplicationServices/ApplicationServices.h>

@implementation MorseSynthesizer

+ (long)willUnloadBundle
{
	return 0; /* We retain no resources that would block unloading us */
}

- (id)init
{
	speechRate	= 20.0f;
	pitchBase	= 440.0f;
	volume		= 1.0f;
	openDelim	= (CFStringRef)[@"[[" retain];
	closeDelim	= (CFStringRef)[@"]]" retain];

	queue		= dispatch_queue_create("MorseSynthesizer", 0);
	tokens		= [[MorseTokenBuffer alloc] init];
    
    return self;
}

- (void)close
{
	[self disposeSoundChannel];
	if (generateSamples)
		dispatch_source_cancel(generateSamples);
	dispatch_release(queue);
	[self release];
}

- (long)useVoice:(VoiceSpec *)voice withBundle:(CFBundleRef)inVoiceSpecBundle
{
	/*
	 * Set up voice specific information. Normally, we would use a considerable amount of voice 
	 * specific data. In our example, we change the default pitch and rate based on the gender
	 * of the voice.
	 */
	VoiceDescription desc;
	if (!GetVoiceDescription(voice, &desc, sizeof(desc)))
		switch (desc.gender) {
		case kMale:
			speechRate	= 20.0f;
			pitchBase	= 300.0f;
			break;
		case kFemale:
			speechRate	= 25.0f;
			pitchBase	= 440.0f;
			break;
		case kNeuter:
			speechRate	= 30.0f;
			pitchBase	= 360.0f;
			break;
		}
	return noErr;
}

- (BOOL)isActive
{
	__block BOOL result;
	
	dispatch_sync(queue, ^{
			result = !(synthState == kSynthStopped || synthState == kSynthPaused);
		});
	
	return result;
}

- (void)startSampleGeneration
{
	if ([tokens peekNextToken] != kMorseNone) {
		synthState          = kSynthRunning;
		audioOn             = NO;
		unitsLeftInToken	= 0;
		if (generateSamples)
			dispatch_release(generateSamples);
		generateSamples= dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
		dispatch_source_set_event_handler(generateSamples, ^{ [self generateMorseAudio]; });
		dispatch_resume(generateSamples);
		dispatch_source_set_timer(generateSamples, DISPATCH_TIME_NOW, (audioFileRef ? 1ull : 10ull)*1000*1000, 5ull*1000*1000);
	}
}

- (void)encodeText:(CFStringRef)text
{
	[tokens clear];
	if (wordCallback)
		[tokens wantWordCallbacks:@selector(wordCallback:)];

	/* 
	 * Morse code is case insensitive, and so are our embedded commands.
	 * Most synthesizers require considerably more subtlety than this.
	 */
	CFMutableStringRef s = CFStringCreateMutableCopy(NULL, 0, text);
	CFStringFold(s, kCFCompareCaseInsensitive, NULL);
	text = s;

	float	curRate	= speechRate;
	float	curPitch= pitchBase;
	float	curVol	= volume;

	CFRange remainingText = CFRangeMake(0, CFStringGetLength(text));
	while (openDelim) {
		CFRange delim;
		if (!CFStringFindWithOptions(text, openDelim, remainingText, 0, &delim))
			break;

		/* Encode text before opening delimiter */
		CFRange prefix = CFRangeMake(remainingText.location, 
									 delim.location-remainingText.location);
		[tokens encodeText:text range:prefix]; 
		[tokens encodeWordBreak];

		/* Process embedded commands */
		CFStringRef newOpenDelim	= (CFStringRef)CFRetain(openDelim);
		CFStringRef newCloseDelim   = (CFStringRef)CFRetain(closeDelim);
		CFIndex		embedded		= delim.location+delim.length;
		CFIndex     endEmbedded     = remainingText.location+remainingText.length;

		delim.length = remainingText.length-(embedded-remainingText.location);
		if (CFStringFindWithOptions(text, closeDelim, delim, 0, &delim)) {
			endEmbedded 			= delim.location;
			remainingText.length 	= (remainingText.location+remainingText.length)-(endEmbedded+delim.length);
			remainingText.location	= endEmbedded+delim.length;
		} else {
			remainingText.length	= 0;
			remainingText.location	= endEmbedded;
		}

		/* We should be reporting errors if we encounter any, but we don't */
#define FETCH_NEXT_CHAR if (embedded < endEmbedded) ch = CFStringGetCharacterAtIndex(text, embedded++); else ch = ' '
#define SKIP_SPACES     while (isspace(ch) && embedded<endEmbedded) FETCH_NEXT_CHAR
#define ERROR			goto skipToNextCommand

		while (embedded < endEmbedded) {
			UniChar ch;
			FETCH_NEXT_CHAR;
			SKIP_SPACES;
			char 	selector[5] = {0,0,0,0,0};
			int  	selIx       = 0;
			SEL		paramSel;
			float * curParam;
			char	relative;
			char    argument[32];
			int		argIx;
			float 	value;
			while (selIx < 4 && isalpha(ch)) {
				selector[selIx++] = ch;
				FETCH_NEXT_CHAR;
			}
			/* 
			 * We only handle a small subset of the embedded commands we're 
			 * supposed to handle. You probably get the idea, though.
			 */
			if (!strcmp(selector, "cmnt")) {
				break; /* Comment, skip rest of embedded command */
			} else if (!strcmp(selector, "dlim")) {
				/* 	
				 * Change embedded command delimiters. The change takes place 
				 * AFTER the current block of embedded commands.
				 */
				UniChar odelim[2] = {0,0};
				UniChar cdelim[2] = {0,0};
				SKIP_SPACES;
				if (!isspace(ch) && ch != ';') {
					odelim[0] = ch;
					FETCH_NEXT_CHAR;
					if (!isspace(ch) && ch != ';') {
						odelim[1] = ch;
						FETCH_NEXT_CHAR;
					}
					SKIP_SPACES;
				}
				if (!isspace(ch) && ch != ';') {
					cdelim[0] = ch;
					FETCH_NEXT_CHAR;
					if (!isspace(ch) && ch != ';') {
						cdelim[1] = ch;
						FETCH_NEXT_CHAR;
					}
				}
				newOpenDelim = !odelim[0] ? NULL
					: CFStringCreateWithCharacters(NULL, odelim, 1+(odelim[1] != 0));
				newCloseDelim = !cdelim[0] ? NULL
					: CFStringCreateWithCharacters(NULL, cdelim, 1+(cdelim[1] != 0));
			} else if (!strcmp(selector, "rate")) {
				paramSel= @selector(updateSpeechRate:);
				curParam= &curRate;
			handleNumericArgument:
				SKIP_SPACES;
				if (ch == '+' || ch == '-') {
					relative = ch;
					FETCH_NEXT_CHAR;
				} else
					relative = 0;
				SKIP_SPACES;
				for (argIx = 0; isdigit(ch) || ch == '.'; ++argIx) {
					argument[argIx] = ch;
					FETCH_NEXT_CHAR;
				}
				argument[argIx] = 0;
				if (!argIx)
					ERROR;
				value = atof(argument);
				/* TODO: Parameters need range check! */
				switch (relative) {
				case '+':
					*curParam += value;
					break;
				case '-':
					*curParam -= value;
					break;
				default:
					*curParam = value;
					break;
				}
				[tokens encodeFloatCallback:paramSel value:*curParam];
			} else if (!strcmp(selector, "pbas")) {
				paramSel= @selector(updatePitchBase:);
				curParam= &curPitch;
				goto handleNumericArgument;
			} else if (!strcmp(selector, "volm")) {
				paramSel= @selector(updateVolume:);
				curParam= &curVol;
				goto handleNumericArgument;
			} else if (!strcmp(selector, "sync")) {
				/* Sync accepts a wide range of formats */
				uint32_t arg = 0;
				SKIP_SPACES;
				if (ch == '0') {
					FETCH_NEXT_CHAR;
					if (ch == 'x') {
					hexArg:
						FETCH_NEXT_CHAR;
						while (isxdigit(ch)) {
							arg	= arg*16 + ch - (isdigit(ch) ? '0' : 'a');
							FETCH_NEXT_CHAR;
						}
					} else {
						/* Initial 0 can be ignored */
					decimalArg:
						while (isdigit(ch)) {
							arg = arg*10 + ch-'0';
							FETCH_NEXT_CHAR;
						}
					}
				} else if (ch == '$') {
					goto hexArg;
				} else if (isdigit(ch)) {
					goto decimalArg;
				} else if (ch == '\'' || ch == '"') {
					UniChar quote = ch;
					FETCH_NEXT_CHAR;
					while (ch != quote && !(arg & 0xFF000000)) {
						arg	= (arg << 8) | (ch & 0xFF);
						FETCH_NEXT_CHAR;
					}
				} else {
					arg = ch << 24;
					FETCH_NEXT_CHAR;
					arg |= (ch & 0xFF) << 16;
					FETCH_NEXT_CHAR;
					arg |= (ch & 0xFF) << 8;
					FETCH_NEXT_CHAR;
					arg |= (ch & 0xFF);
					FETCH_NEXT_CHAR;
				}
				[tokens encodeSyncCallback:@selector(syncCallback:) value:arg];
			} else {   /* Unknown selector */
				ERROR;
			}
		skipToNextCommand:
			while (embedded < endEmbedded && isspace(ch))
				FETCH_NEXT_CHAR;
			if (embedded == endEmbedded)
				break;
			else if (ch != ';') {
				FETCH_NEXT_CHAR;
				ERROR;
			}
		}

		if (openDelim)
			CFRelease(openDelim);
		openDelim	= newOpenDelim;
		if (closeDelim)
			CFRelease(closeDelim);
		closeDelim  = newCloseDelim;
	}
	if (remainingText.length)
		[tokens encodeText:text range:remainingText];
	CFRelease(s);
}

- (long)startSpeaking:(CFStringRef)text
	  noEndingProsody:(BOOL)noEndingProsody noInterrupt:(BOOL)noInterrupt 
			preflight:(BOOL)preflight
{
	/*
	 * Test for currently active speech
	 */
	if ([self isActive])
		if (noInterrupt) {
			return synthNotReady;
		} else {
			[self stopSpeakingAt:kImmediate];
			while ([self isActive])
				usleep(5000);	// Test again in 5ms
		}
			
	synthState	= kSynthStopped;
	pauseToken	= kMorseNone;
	
	if (!text || !CFStringGetLength(text))
		return noErr;
	
	textBeingSpoken = CFRetain(text);
	[self encodeText:text];
	[self createSoundChannel:NO];
	if (preflight)
		synthState = kSynthPaused;
	else
		[self startSampleGeneration];
	
	return noErr;
}

- (long)stopSpeakingAt:(unsigned long)whereToStop
{
	dispatch_sync(queue, ^{
		switch (synthState) {
		case kSynthStopping:
		case kSynthStopped:
			break; 
		case kSynthPaused:
			[tokens clear];
			synthState	= kSynthStopped;
			break;
		case kSynthPausing:
			synthState = kSynthStopping;
			break;
		case kSynthRunning:
			switch (whereToStop) {
			case kEndOfWord:
				[tokens trimTokens:kMorseWordGap];
				break;
			case kEndOfSentence:
				[tokens trimTokens:kMorseSentenceGap];
				break;
			default:
				if (audioOutput) {
					synthState = kSynthStopping;
					[audioOutput stopAudio];
					[tokens clear];
					unitsLeftInToken = 0;
				} else {
					synthState = kSynthStopped;
				}
			} 
			break;
		}
	});
	
	return noErr;
}

- (long)pauseSpeakingAt:(unsigned long)whereToStop
{
	dispatch_sync(queue, ^{
		switch (synthState) {
		case kSynthPausing:
		case kSynthPaused:
		case kSynthStopping:
		case kSynthStopped:
			break; 
		case kSynthRunning:
			switch (whereToStop) {
			case kEndOfWord:
				pauseToken = kMorseWordGap;
				break;
			case kEndOfSentence:
				if (!pauseToken)
					pauseToken = kMorseSentenceGap;
				break;
			default:
				pauseToken = kMorseNone;
				synthState = kSynthPausing;
				[audioOutput stopAudio];
			}
			break;
		}
	});
	
	return noErr;
}

- (long)continueSpeaking
{
	switch (synthState) {
	case kSynthPausing:
	case kSynthPaused:
		[tokens skipGaps];
		[self startSampleGeneration];
		break;
	default:
		break;
	} 

	return noErr;
}

- (long)copyPhonemes:(CFStringRef)text result:(CFStringRef *)phonemes
{
	MorseTokenBuffer * t = [[MorseTokenBuffer alloc] init];
	[t encodeText:text];
	*phonemes = [t morseCharacters];

	return noErr;
}

- (CFStringEncoding)stringEncodingForBuffer
{
	return stringEncodingForBuffer;
}

- (void)updateSpeechRate:(NSValue *)update
{
	speechRate = ((MorseCallback *)[update pointerValue])->arg.f;
}

- (void)updatePitchBase:(NSValue *)update
{
	pitchBase = ((MorseCallback *)[update pointerValue])->arg.f;
}

- (void)updateVolume:(NSValue *)update
{
	volume = ((MorseCallback *)[update pointerValue])->arg.f;
}

- (void)wordCallback:(NSValue *)arg
{
	if (wordCallback) {
		CFRange r = ((MorseCallback *)[arg pointerValue])->arg.r;
#if SYNTHESIZER_USES_BUFFER_API
		wordCallback((SpeechChannel)self, clientRefCon, r.location, r.length);
#else
		wordCallback((SpeechChannel)self, clientRefCon, textBeingSpoken, r);
#endif
	}
}

- (void)syncCallback:(NSValue *)arg
{
	if (syncCallback)
		syncCallback((SpeechChannel)self, clientRefCon, ((MorseCallback *)[arg pointerValue])->arg.u);
}

@end

@implementation MorseSynthesizer (SoundChannelManagement)

- (void)createSoundChannel:(BOOL)forAudioUnit
{
	dispatch_sync(queue, ^{
			if (!audioOutput)
				if (audioFileRef == (ExtAudioFileRef)-1)
					audioOutput = [AudioOutput createIgnoreAudio];
				else if (audioFileRef)
					audioOutput = [AudioOutput createFileAudio:audioFileRef];
				else
					audioOutput = [AudioOutput createLiveAudio:forAudioUnit withDevice:audioDevice];
		});
}

- (void)disposeSoundChannel
{
	dispatch_sync(queue, ^{
			[audioOutput close];
	
			audioOutput	  	= 0;
			audioDevice	= kAudioDeviceUnknown;
	
			if (audioFileRef) {
				if (audioFileOwned)
					ExtAudioFileDispose(audioFileRef);
				audioFileRef 	= 0;
				audioFileOwned 	= NO;
			}
		});
}

@end
