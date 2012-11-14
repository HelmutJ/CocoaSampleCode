/*
 <codex> 
 <abstract>AUOutputElement.h</abstract>
 <\codex>
*/
#include "AUOutputElement.h"
#include "AUBase.h"

AUOutputElement::AUOutputElement(AUBase *audioUnit) : 
	AUIOElement(audioUnit)
{
	AllocateBuffer();
}

OSStatus	AUOutputElement::SetStreamFormat(const CAStreamBasicDescription &desc)
{
	OSStatus result = AUIOElement::SetStreamFormat(desc);	// inherited
	if (result == AUBase::noErr)
		AllocateBuffer();
	return result;
}
