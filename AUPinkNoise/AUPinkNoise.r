/*
 <codex>
 <abstract>AUPinkNoise.r</abstract>
 <\codex>
*/
#include <AudioUnit/AudioUnit.r>

#include "AUPinkNoiseVersion.h"

// Note that resource IDs must be spaced 2 apart for the 'STR ' name and description
#define kAudioUnitResID_AUPinkNoise				1000

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ AUPinkNoise~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define RES_ID			kAudioUnitResID_AUPinkNoise
#define COMP_TYPE		kAudioUnitType_Generator
#define COMP_SUBTYPE	'pink'
#define COMP_MANUF		kAudioUnitManufacturer_Apple	

#define VERSION			0x00010000
#define NAME			"Apple: AUPinkNoise"
#define DESCRIPTION		"Audio Unit Pink Noise Generator"
#define ENTRY_POINT		"AUPinkNoiseEntry"

#include "AUResources.r"