/*
 <codex> 
 <abstract>Part of CoreAudio Utility Classes</abstract>
 <\codex>
*/
#ifndef __AUBaseHelper_h__
#define __AUBaseHelper_h__

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <CoreFoundation/CoreFoundation.h>
	#include <AudioUnit/AUComponent.h>
#else
	#include <CoreFoundation.h>
	#include <AUComponent.h>
#endif

#include "AUBase.h"


UInt32 FindInvalidSamples(Float32 *inSource, UInt32 inFramesToProcess, bool &hasNonZero, bool zapInvalidSamples);


// helpers for dealing with the file-references dictionary in an AUPreset

extern "C" OSStatus	
GetFileRefPath (CFDictionaryRef parent, CFStringRef frKey, CFStringRef * fPath);

// if fileRefDict is NULL, this call creates one
// if not NULL, then the key value is added to it
extern "C" CFMutableDictionaryRef 
CreateFileRefDict (CFStringRef fKey, CFStringRef fPath, CFMutableDictionaryRef fileRefDict);

#if DEBUG
	void PrintAUParamEvent (AudioUnitParameterEvent& event, FILE* f);
#endif



#endif // __AUBaseHelper_h__