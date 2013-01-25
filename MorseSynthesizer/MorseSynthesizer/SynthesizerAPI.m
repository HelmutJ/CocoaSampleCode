/*
    File: SynthesizerAPI.m
Abstract: Implement Speech Engine API calls.

While theoretically these calls can be implemented in a procedural language,
our approach is to represent a speech channel object as an instance of a 
synthesizer class, to which all the API calls delegate the actual work.
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

#include "MorseSynthesizer.h"
#include <ApplicationServices/ApplicationServices.h>

#if SYNTHESIZER_USES_BUFFER_API
#define _SUPPORT_SPEECH_SYNTHESIS_IN_MAC_OS_X_VERSION_10_0_THROUGH_10_4__ 1
#import "MorseSynthesizerBuffer.h"
#else
#import "MorseSynthesizerCF.h"
#endif

#include "SpeechEngine.h"

//
// This example uses the synthesizer plug-in API supported in Mac OS X 10.6 and later versions.
// It demonstrates all audio output methods defined in 10.6
//

/* Open channel - called from NewSpeechChannel, passes back in *ssr a unique SpeechChannelIdentifier value of your choosing. */
long	SEOpenSpeechChannel( SpeechChannelIdentifier* ssr )
{
	//
    // Pass back an identifier for this new channel.
	//
	SpeechChannelIdentifier newChannel = 
           (SpeechChannelIdentifier)[[MorseSynthesizer alloc] init];
    if (ssr) 
        *ssr = newChannel;

	// This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	synthOpenFailed		-241	Could not open another speech synthesizer channel 
	
    return newChannel ? noErr : synthOpenFailed;
}

/* Set the voice to be used for the channel. Voice type guaranteed to be compatible with above spec */
long 	SEUseVoice( SpeechChannelIdentifier ssr, VoiceSpec* voice, CFBundleRef inVoiceSpecBundle )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    //	voiceNotFound		-244	Voice resource not found 

	return [(MorseSynthesizer *)ssr useVoice:voice withBundle:inVoiceSpecBundle];
}

/* Close channel */
long	SECloseSpeechChannel( SpeechChannelIdentifier ssr )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    [(MorseSynthesizer *)ssr close];

    return noErr;
} 

/* Analogous to corresponding speech synthesis API calls, except for details noted below */

/********* Universal API calls ***************/

long 	SEStopSpeechAt( SpeechChannelIdentifier ssr, unsigned long whereToStop)
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
    return [(MorseSynthesizer *)ssr stopSpeakingAt:whereToStop];
} 

long 	SEPauseSpeechAt( SpeechChannelIdentifier ssr, unsigned long whereToPause )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
    return [(MorseSynthesizer *)ssr pauseSpeakingAt:whereToPause];
} 

long 	SEContinueSpeech( SpeechChannelIdentifier ssr )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
    return [(MorseSynthesizer *)ssr continueSpeaking];
} 

/*  Try to release all resources that would require this bundle to remain in memory.
*/
long 	SEWillUnloadBundle()
{
/*  The SEWillUnloadBundle function is required to be implemented by synthesizers that can be loaded and unloaded on-the-fly 
	from a location outside the standard directories in which synthesizers are found automatically. This function is called 
	prior to the synthesizer's bundle being unloaded, usually as a result of the client calling SpeechSynthesisUnregisterModuleURL. 
	
	When called, the synthesizer should remove any run loops and threads created by the bundle so that its code can be removed 
	from memory and the executable file closed. If the synthesizer was successful in preparing for unloading, then return 0 (zero);
	otherwise, return -1.
*/
	return [MorseSynthesizer willUnloadBundle];
}

/******************** CF based calls **********************/

#if !SYNTHESIZER_USES_BUFFER_API

/* Must also be able to parse and handle the embedded commands defined in Inside Macintosh: Speech */
long 	SESpeakCFString( SpeechChannelIdentifier ssr, CFStringRef text, CFDictionaryRef options )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    //	synthNotReady		-242	Speech synthesizer is still busy speaking 
	
	return [(MorseSynthesizer *)ssr 
			   startSpeaking:text 
			   noEndingProsody:[[(NSDictionary*)options objectForKey:(NSString *)kSpeechNoEndingProsody] boolValue]
			   noInterrupt:[[(NSDictionary*)options objectForKey:(NSString *)kSpeechNoSpeechInterrupt] boolValue]
			   preflight:[[(NSDictionary*)options objectForKey:(NSString *)kSpeechPreflightThenPause] boolValue]];
} 

long 	SECopyPhonemesFromText 	( SpeechChannelIdentifier ssr, CFStringRef text, CFStringRef * phonemes)
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 

    return [(MorseSynthesizer *)ssr copyPhonemes:text result:phonemes];
} 

long 	SEUseSpeechDictionary( SpeechChannelIdentifier ssr, CFDictionaryRef speechDictionary )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    //	bufTooSmall			-243	Output buffer is too small to hold result 
    //	badDictFormat		-246	Pronunciation dictionary format error 

    return [(MorseSynthesizer *)ssr useDictionary:speechDictionary];
} 

/* 
    Pass back the information for the designated speech channel and selector
*/
long 	SECopySpeechProperty( SpeechChannelIdentifier ssr, CFStringRef property, CFTypeRef * object )
{
    // This routine is required to support the following properties:
    // kSpeechStatusProperty
    // kSpeechErrorsProperty
    // kSpeechInputModeProperty
    // kSpeechCharacterModeProperty
    // kSpeechNumberModeProperty
    // kSpeechRateProperty  
    // kSpeechPitchBaseProperty
    // kSpeechPitchModProperty
    // kSpeechVolumeProperty
    // kSpeechSynthesizerInfoProperty
    // kSpeechRecentSyncProperty
    // kSpeechPhonemeSymbolsProperty
	//
    // NOTE: kSpeechCurrentVoiceProperty is automatically handled by the API
    //

    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	siUnknownInfoType	-231	Feature not implemented on synthesizer, Unknown type of information 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 

    return [(MorseSynthesizer *)ssr copyProperty:property result:object];
} 

/*
    Set the information for the designated speech channel and selector
*/
long 	SESetSpeechProperty( SpeechChannelIdentifier ssr, CFStringRef property, CFTypeRef object)
{
    // This routine is required to support the following properties:
    // kSpeechCharacterModeProperty
    // kSpeechNumberModeProperty
    // kSpeechRateProperty  
    // kSpeechPitchBaseProperty
    // kSpeechPitchModProperty
    // kSpeechVolumeProperty
    // kSpeechCommandDelimiterProperty
    // kSpeechResetProperty 
    // kSpeechRefConProperty
    // kSpeechTextDoneCallBack
    // kSpeechSpeechDoneCallBack
    // kSpeechSyncCallBack  
    // kSpeechPhonemeCallBack
    // kSpeechErrorCFCallBack
    // kSpeechWordCFCallBack
    // kSpeechOutputToFileURLProperty
	//
    // NOTE: Setting kSpeechCurrentVoiceProperty is automatically converted to a SEUseVoice call.
	//

    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	siUnknownInfoType	-231	Feature not implemented on synthesizer, Unknown type of information 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 

    return [(MorseSynthesizer *)ssr setProperty:property value:object];
} 

/*************************** Buffer based calls ***********************************/

#else /* SYNTHESIZER_USES_BUFFER_API */

long 	SESpeechStatus( SpeechChannelIdentifier ssr, SpeechStatusInfo * status )
{	
	return SEGetSpeechInfo(ssr, soStatus, status);
} 

/* Must also be able to parse and handle the embedded commands defined in Inside Macintosh: Speech */
long 	SESpeakBuffer( SpeechChannelIdentifier ssr, Ptr textBuf, long byteLen, long controlFlags )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    //	synthNotReady		-242	Speech synthesizer is still busy speaking 
	CFStringEncoding	encoding = [(MorseSynthesizer *)ssr stringEncodingForBuffer];
	CFStringRef			cfString = 
		CFStringCreateWithBytes(NULL, (UInt8 *)textBuf, byteLen, encoding, false);
	long 				result   =
		[(MorseSynthesizer *)ssr 
			startSpeaking:cfString 
			noEndingProsody:((controlFlags & kNoEndingProsody) != 0)
			noInterrupt:((controlFlags & kNoSpeechInterrupt) != 0)
			preflight:((controlFlags & kPreflightThenPause) != 0)];
	CFRelease(cfString);

	return result;
} 

long 	SETextToPhonemes( SpeechChannelIdentifier ssr, char* textBuf, long textBytes, void** phonemeBuf, long* phonBytes)
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
	CFStringRef			phon;
	CFStringEncoding	encoding = [(MorseSynthesizer *)ssr stringEncodingForBuffer];
	CFStringRef			cfString = 
		CFStringCreateWithBytes(NULL, (UInt8 *)textBuf, textBytes, encoding, false);
    long error = [(MorseSynthesizer *)ssr copyPhonemes:cfString result:&phon];
	CFRelease(cfString);
	if (error)
		return error;
	CFIndex   len = CFStringGetLength(phon);
	CFIndex   max = CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingMacRoman);
	UInt8 *   buf = (UInt8 *)malloc(max);
	CFStringGetBytes(phon, CFRangeMake(0, len), kCFStringEncodingMacRoman, ' ', false, buf, max, &len);
	*phonemeBuf	  = buf;
	*phonBytes    = len;
	
	return noErr;
} 

long 	SEUseDictionary( SpeechChannelIdentifier ssr, void* dictionary, long dictLength )
{
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
    //	bufTooSmall			-243	Output buffer is too small to hold result 
    //	badDictFormat		-246	Pronunciation dictionary format error 
	
    return [(MorseSynthesizer *)ssr useDictionary:dictionary length:dictLength];
} 

/* 
 Pass back the information for the designated speech channel and selector
 */
long 	SEGetSpeechInfo( SpeechChannelIdentifier ssr, unsigned long selector, void* speechInfo )
{
    // This routine is required to support the following selectors:
    //	soStatus                      = 'stat'
    //	soErrors                      = 'erro'
    //	soInputMode                   = 'inpt'
    //	soCharacterMode               = 'char'
    //	soNumberMode                  = 'nmbr'
    //	soRate                        = 'rate'
    //	soPitchBase                   = 'pbas'
    //	soPitchMod                    = 'pmod'
    //	soVolume                      = 'volm'
    //	soSynthType                   = 'vers'
    //	soRecentSync                  = 'sync'
    //	soPhonemeSymbols              = 'phsy'
	//
	// Optionally, you may support the following selector:
    //	soSynthExtension              = 'xtnd'
    //
    // NOTE: 	The selector soCurrentVoice is automatically handled by the API,
    // 			and selectors soCurrentA5, soSoundOutput are no longer necessary under Mac OS X.
    //
    //			The soPhonemeSymbols selector is passed as soPhonemeSymbolsPtr ('phsp'); speechInfo passes a pointer to a (void *)
    //			The engine has to allocate a sufficiently sized area with malloc(), fill it in, and store it into 
    //			*(void **)speechInfo. The API will dispose the memory. The call is rarely used and can probably be left unimplemented. 
	
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	siUnknownInfoType	-231	Feature not implemented on synthesizer, Unknown type of information 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
    return [(MorseSynthesizer *)ssr getSpeechInfo:selector result:speechInfo];
} 

/*
 Set the information for the designated speech channel and selector
 */
long 	SESetSpeechInfo( SpeechChannelIdentifier ssr, unsigned long selector, void* speechInfo )
{
    // This routine should support the following selectors:
    //	soInputMode                   = 'inpt'
    //	soCharacterMode               = 'char'
    //	soNumberMode                  = 'nmbr'
    //	soRate                        = 'rate'
    //	soPitchBase                   = 'pbas'
    //	soPitchMod                    = 'pmod'
    //	soVolume                      = 'volm'
    //	soCommandDelimiter            = 'dlim'
    //	soReset                       = 'rset'
    //	soRefCon                      = 'refc'
    //	soTextDoneCallBack            = 'tdcb'
    //	soSpeechDoneCallBack          = 'sdcb'
    //	soSyncCallBack                = 'sycb'
    //	soErrorCallBack               = 'ercb'
    //	soPhonemeCallBack             = 'phcb'
    //	soWordCallBack                = 'wdcb'
    //	soOutputToFileWithCFURL 	  = 'opaf' 		Pass a CFURLRef to write to this file, NULL to generate sound
	//
	//  Optionally, you may support the following extension:
    //	soSynthExtension              = 'xtnd'
    //
    // NOTE: 	The selector soCurrentVoice is automatically handled by the API,
    // 			and selectors soCurrentA5, soSoundOutput are no longer necessary under Mac OS X.
	
    // This routine normally returns one of the following values:
    //	noErr				0		No error 
    //	paramErr			-50		Invalid value passed in a parameter. Your application passed an invalid parameter for dialog options. 
    //	siUnknownInfoType	-231	Feature not implemented on synthesizer, Unknown type of information 
    //	noSynthFound		-240	Could not find the specified speech synthesizer 
	
    return [(MorseSynthesizer *)ssr setSpeechInfo:selector info:speechInfo];
} 

#endif

