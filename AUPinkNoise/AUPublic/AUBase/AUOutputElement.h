/*
 <codex> 
 <abstract>Part of CoreAudio Utility Classes</abstract>
 <\codex>
*/
#ifndef __AUOutput_h__
#define __AUOutput_h__

#include "AUScopeElement.h"
#include "AUBuffer.h"

	/*! @class AUOutputElement */
class AUOutputElement : public AUIOElement {
public:
	/*! @ctor AUOutputElement */
						AUOutputElement(AUBase *audioUnit);

	// AUElement override
	/*! @method SetStreamFormat */
	virtual OSStatus	SetStreamFormat(const CAStreamBasicDescription &desc);
	/*! @method NeedsBufferSpace */
	virtual bool		NeedsBufferSpace() const { return true; }
};

#endif // __AUOutput_h__
