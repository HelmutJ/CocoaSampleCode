/*
 <codex> 
 <abstract>CADebugger.h</abstract>
 <\codex>
*/
//=============================================================================
//	Includes
//=============================================================================

#include "CADebugger.h"

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <CoreAudio/CoreAudioTypes.h>
#else
	#include <CoreAudioTypes.h>
#endif

//	on X, use the Unix routine, otherwise use Debugger()
#if TARGET_API_MAC_OSX
	#include <signal.h>
#endif

//=============================================================================
//	CADebugger
//=============================================================================

void	CADebuggerStop()
{
	#if	CoreAudio_Debug
		#if	TARGET_API_MAC_OSX
			raise(SIGINT);
		#else
			__debugbreak();
		#endif
	#endif
}
