/*
 <codex> 
 <abstract>Part of CoreAudio Utility Classes</abstract>
 <\codex>
*/
#ifndef __CAVectorUnitTypes_h__
#define __CAVectorUnitTypes_h__

enum {
	kVecUninitialized = -1,
	kVecNone = 0,
	kVecAltivec = 1,
	kVecSSE2 = 100,
	kVecSSE3 = 101,
	kVecNeon = 200
};

#endif
