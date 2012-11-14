/*
 <codex> 
 <abstract>CAHostTimeBase.h</abstract>
 <\codex>
*/
//=============================================================================
//	Includes
//=============================================================================

#include "CAHostTimeBase.h"

Float64	CAHostTimeBase::sFrequency = 0;
Float64	CAHostTimeBase::sInverseFrequency = 0;
UInt32	CAHostTimeBase::sMinDelta = 0;
UInt32	CAHostTimeBase::sToNanosNumerator = 0;
UInt32	CAHostTimeBase::sToNanosDenominator = 0;
UInt32	CAHostTimeBase::sFromNanosNumerator = 0;
UInt32	CAHostTimeBase::sFromNanosDenominator = 0;
bool	CAHostTimeBase::sUseMicroseconds = false;
bool	CAHostTimeBase::sIsInited = false;
#if Track_Host_TimeBase
UInt64	CAHostTimeBase::sLastTime = 0;
#endif

//=============================================================================
//	CAHostTimeBase
//
//	This class provides platform independent access to the host's time base.
//=============================================================================

void	CAHostTimeBase::Initialize()
{
	//	get the info about Absolute time
	#if TARGET_OS_MAC
		struct mach_timebase_info	theTimeBaseInfo;
		mach_timebase_info(&theTimeBaseInfo);
		sMinDelta = 1;
		sToNanosNumerator = theTimeBaseInfo.numer;
		sToNanosDenominator = theTimeBaseInfo.denom;
		sFromNanosNumerator = sToNanosDenominator;
		sFromNanosDenominator = sToNanosNumerator;

		//	the frequency of that clock is: (sToNanosDenominator / sToNanosNumerator) * 10^9
		sFrequency = static_cast<Float64>(sToNanosDenominator) / static_cast<Float64>(sToNanosNumerator);
		sFrequency *= 1000000000.0;
	#elif TARGET_OS_WIN32
		LARGE_INTEGER theFrequency;
		QueryPerformanceFrequency(&theFrequency);
		sMinDelta = 1;
		sToNanosNumerator = 1000000000ULL;
		sToNanosDenominator = *((UInt64*)&theFrequency);
		sFromNanosNumerator = sToNanosDenominator;
		sFromNanosDenominator = sToNanosNumerator;
		sFrequency = static_cast<Float64>(*((UInt64*)&theFrequency));
	#endif
	sInverseFrequency = 1.0 / sFrequency;
	
	#if	Log_Host_Time_Base_Parameters
		DebugMessage(  "Host Time Base Parameters");
		DebugMessageN1(" Minimum Delta:          %lu", sMinDelta);
		DebugMessageN1(" Frequency:              %f", sFrequency);
		DebugMessageN1(" To Nanos Numerator:     %lu", sToNanosNumerator);
		DebugMessageN1(" To Nanos Denominator:   %lu", sToNanosDenominator);
		DebugMessageN1(" From Nanos Numerator:   %lu", sFromNanosNumerator);
		DebugMessageN1(" From Nanos Denominator: %lu", sFromNanosDenominator);
	#endif

	sIsInited = true;
}
