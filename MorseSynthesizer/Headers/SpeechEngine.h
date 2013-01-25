/*
    File: SpeechEngine.h
Abstract: Definition of the SPI between the Speech Synthesis API and a speech engine that
			implements the actual synthesis technology.  Each voice is matched to its appropriate
			speech engine via a type code stored in the voice.

			This documentation requires an understanding of the Speech Synthesis Manager
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

/*
 * VOICES
 *
 * Voices are bundles installed in DOMAIN/Library/Speech/Voices/YOUR_VOICE_NAME.SpeechVoice, where DOMAIN is one of three
 * domains: system, local, or user.
 *
 * If the voice is designed to run on Mac OS X 10.4 and earlier it must contain a VoiceDescription file at the location YOUR_VOICE_NAME.SpeechVoice/Contents/Resources/VoiceDescription.
 * The VoiceDescription file contains the voice's attributes in binary form using the struct VoiceDescription, as defined in SpeechSynthesis.h.
 * The voice's Info.plist file should also include additional voice attributes that VoiceOver uses (VoiceSupportedCharacters & VoiceIndividuallySpokenCharacters).
 *
 * If the voice will only support Mac OS X 10.5 and later, then a VoiceDescription file is not necesary and all voice attributes can be defined in the voice's Info.plist file.
 * 
 * NOTE: Voice bundle names cannot contain spaces.  However, the name of the voice that is specified in the
 * VoiceDescription file and displayed to the user can contain spaces.
 *
 *
 */

#define kSpeechVoiceSynthesizerNumericID		CFSTR("VoiceSynthesizerNumericID")
#define kSpeechVoiceNumericID					CFSTR("VoiceNumericID")


/*
 * SYNTHESIZERS
 *
 * Speech Synthesizers are bundles installed in /System/Library/Speech/Synthesizers/YOUR_SYNTHESIZER_NAME.SpeechSynthesizer
 *
 * Define _SUPPORT_SPEECH_SYNTHESIS_IN_MAC_OS_X_VERSION_10_0_THROUGH_10_4__ as true if your synthesizer is intended to run on Mac OS X 10.4 and earlier.
 *
 *
 *
 */


#define kSpeechEngineTypeArrayKey CFSTR("SpeechEngineTypeArray")

#if _SUPPORT_SPEECH_SYNTHESIS_IN_MAC_OS_X_VERSION_10_0_THROUGH_10_4__
/* Engine Description (in YOUR_SYNTHESIZER_NAME.SpeechSynthesizer/Contents/Resources/SpeechEngineDescription) */
typedef struct SpeechEngineDesc
{
	long		fFileFormat;	// Currently 2
	OSType		fEngineType[3]; // Voice types handled, padded with \0\0\0\0 if necessary
} SpeechEngineDesc;

/* Engine (in YOUR_SYNTHESIZER_NAME.SpeechSynthesizer/Contents/MacOS/YOUR_SYNTHESIZER_NAME) */
#endif

/* Token to identify your private per-channel data */
typedef long SpeechChannelIdentifier;


/* API: These functions must be defined and exported with these names and extern "C" linkage. All of them
   return an OSStatus result.
*/


#ifdef __cplusplus
extern "C" {
#endif

/* Open channel - called from NewSpeechChannel, passes back in *ssr a unique SpeechChannelIdentifier value of your choosing. */
long	SEOpenSpeechChannel	( SpeechChannelIdentifier* ssr );

/* Set the voice to be used for the channel. Voice type guaranteed to be compatible with above spec */
long 	SEUseVoice 			( SpeechChannelIdentifier ssr, VoiceSpec* voice, CFBundleRef inVoiceSpecBundle );

/* Close channel */
long	SECloseSpeechChannel( SpeechChannelIdentifier ssr ); 

/* Analogous to corresponding speech synthesis API calls, except for details noted below */

/* Must also be able to parse and handle the embedded commands defined in Inside Macintosh: Speech */
long 	SESpeakCFString			( SpeechChannelIdentifier ssr, CFStringRef text, CFDictionaryRef options);
long 	SECopySpeechProperty	( SpeechChannelIdentifier ssr, CFStringRef property, CFTypeRef * object );
long 	SESetSpeechProperty		( SpeechChannelIdentifier ssr, CFStringRef property, CFTypeRef object);
long 	SEUseSpeechDictionary 	( SpeechChannelIdentifier ssr, CFDictionaryRef speechDictionary );
long 	SECopyPhonemesFromText 	( SpeechChannelIdentifier ssr, CFStringRef text, CFStringRef * phonemes);
long 	SEStopSpeechAt			( SpeechChannelIdentifier ssr, unsigned long whereToPause); 
long 	SEPauseSpeechAt			( SpeechChannelIdentifier ssr, unsigned long whereToPause );
long 	SEContinueSpeech		( SpeechChannelIdentifier ssr );
	
#if _SUPPORT_SPEECH_SYNTHESIS_IN_MAC_OS_X_VERSION_10_0_THROUGH_10_4__

/* Must also be able to parse and handle the embedded commands defined in Inside Macintosh: Speech */
long 	SESpeakBuffer		( SpeechChannelIdentifier ssr, Ptr textBuf, long byteLen, long controlFlags ); 
long 	SETextToPhonemes 	( SpeechChannelIdentifier ssr, char* textBuf, long textBytes, void** phonemeBuf, long* phonBytes);
long 	SEUseDictionary 	( SpeechChannelIdentifier ssr, void* dictionary, long dictLength );

/* The soPhonemeSymbols call is passed as soPhonemeSymbolsPtr ('phsp'); speechInfo passes a pointer to a (void *)
   The engine has to allocate a sufficiently sized area with malloc(), fill it in, and store it into 
   *(void **)speechInfo. The API will dispose the memory. The call is rarely used and can probably be left 
   unimplemented. 

   Must be able to handle all selectors defined in Inside Macintosh: Speech.
*/
long 	SEGetSpeechInfo		( SpeechChannelIdentifier ssr, unsigned long selector, void* speechInfo );

/* soCurrentVoice will be handled by the API (and SEUseVoice, if necessary 

   Must be able to handle all selectors defined in Inside Macintosh: Speech, including those for the various callbacks,
   with the exception of soCurrentA5 and soSoundOutput.
*/
long 	SESetSpeechInfo		( SpeechChannelIdentifier ssr, unsigned long selector, void* speechInfo );

/* Same as SEGetSpeechInfo(ssr, soStatus, status). Will probably get dropped in next release of MacOS X */
long 	SESpeechStatus 		( SpeechChannelIdentifier ssr, SpeechStatusInfo * status );

#endif

/*  The SEWillUnloadBundle function is required to be implemented by synthesizers that can be loaded and unloaded on-the-fly 
	from a location outside the standard directories in which synthesizers are found automatically. This function is called 
	prior to the synthesizer's bundle being unloaded, usually as a result of the client calling SpeechSynthesisUnregisterModuleURL. 
	
	When called, the synthesizer should remove any run loops and threads created by the bundle so that its code can be removed 
	from memory and the executable file closed. If the synthesizer was successful in preparing for unloading, then return 0 (zero);
	otherwise, return -1.
*/
long 	SEWillUnloadBundle	(void);

/* Internal selectors used by the Speech Synthesis Audio Unit */
#define kSpeechAudioUnit	CFSTR("aunt")
#define kSpeechAudioGraph	CFSTR("augr")
#define kSpeechOfflineMode	CFSTR("offl")

#if _SUPPORT_SPEECH_SYNTHESIS_IN_MAC_OS_X_VERSION_10_0_THROUGH_10_4__
#define soAudioUnit		'aunt'
#define soAudioGraph	'augr'
#define soOffline		'offl'
#endif
	
#ifdef __cplusplus
}
#endif

