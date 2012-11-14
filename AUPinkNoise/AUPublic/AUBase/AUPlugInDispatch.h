/*
 <codex> 
 <abstract>Part of CoreAudio Utility Classes</abstract>
 <\codex>
*/
#ifndef __AUPlugInBase_h__
#define __AUPlugInBase_h__

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <AudioUnit/AudioComponent.h>
	#if !CA_BASIC_AU_FEATURES
		#include <AudioUnit/MusicDevice.h>
	#endif
#else
	#include "AudioComponent.h"
	#include "MusicDevice.h"
#endif

#include "ComponentBase.h"

struct AUBaseLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUBaseFactory : public APFactory<AUBaseLookup, Implementor>
{
};

struct AUOutputLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUOutputBaseFactory : public APFactory<AUOutputLookup, Implementor>
{
};

struct AUComplexOutputLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUOutputComplexBaseFactory : public APFactory<AUComplexOutputLookup, Implementor>
{
};

struct AUBaseProcessLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUBaseProcessFactory : public APFactory<AUBaseProcessLookup, Implementor>
{
};

struct AUBaseProcessMultipleLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUBaseProcessMultipleFactory : public APFactory<AUBaseProcessMultipleLookup, Implementor>
{
};

#if !CA_BASIC_AU_FEATURES
struct AUMIDILookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUMIDIEffectFactory : public APFactory<AUMIDILookup, Implementor>
{
};

struct AUMIDIProcessLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUMIDIProcessFactory : public APFactory<AUMIDIProcessLookup, Implementor>
{
};

struct AUMusicLookup {
	static AudioComponentMethod Lookup (SInt16 selector);
};
template <class Implementor>
class AUMusicDeviceFactory : public APFactory<AUMusicLookup, Implementor>
{
};
#endif // CA_BASIC_AU_FEATURES

#endif // __AUPlugInBase_h__
