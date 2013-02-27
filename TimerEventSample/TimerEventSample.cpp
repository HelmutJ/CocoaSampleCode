/*
	File:		TimerEventSample.cpp
	
	Description:
				A simple sample KEXT that shows how use a timer event source.
				
	Author:		JAS

	Copyright: 	© Copyright 2001 Apple Computer, Inc. All rights reserved.
	
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):
	03/28/01	JAS	Created

*/
#include <IOKit/IOLib.h>
#include "TimerEventSample.h"

 
// REQUIRED! This macro defines the class's constructors, destructors,
// and several other methods I/O Kit requires.  Do NOT use super as the
// second parameter.  You must use the literal name of the superclass.
OSDefineMetaClassAndStructors( TimerEventSample, IOService )

// Define my superclass
#define super IOService


bool TimerEventSample::start(IOService *provider)
{
    bool 				result;
	
	IOLog("Starting\n");
	
	result = super::start(provider);
	
	while( result )
	{
		// get our workloop
		myWorkLoop = getWorkLoop();
	
		// get a timer and set our timeout handler to be called when it fires
		myTimer = IOTimerEventSource::timerEventSource( this, (IOTimerEventSource::Action)&TimerEventSample::timeoutHandler );
		
		// make sure we got a timer
		if( !myTimer )
		{
			IOLog( "%s: Failed to create timer event source\n", getName() );
			result = false;
			break;
		}
		
		
		// add the timer to the workloop
		if( myWorkLoop->addEventSource(myTimer) != kIOReturnSuccess )
		{
			IOLog( "%s: Failed to add timer event source to workloop\n", getName() );
			result = false;
			break;
		}

		// now set the timeout
		// this example uses 5 seconds
		myTimer->setTimeoutMS( 5000 );

		// zero counter
		counter = 0;	// this is used to count the number of times that timeoutHandler is called
		
		break;	// make sure to exit while(result)!!!
	}
	
    return( result );
}

void TimerEventSample::stop(IOService *provider)
{
    IOLog("Stopping\n");
	
	// if we got a timer in ::start, clean up
	if( myTimer )
	{
		myTimer->cancelTimeout();					// stop the timer
		myWorkLoop->removeEventSource( myTimer );	// remove the timer from the workloop
		myTimer->release();							// release the timer
		myTimer = NULL;								//
	}
	
    super::stop(provider);
}


// this function is called when the timer fires
void TimerEventSample::timeoutHandler(OSObject *owner, IOTimerEventSource *sender)
{
	TimerEventSample*	myTimerSample;
	
	// make sure that the owner of the timer is us
	myTimerSample = OSDynamicCast( TimerEventSample, owner );
	if( myTimerSample )	// it's us
	{		
		// increment the counter
		myTimerSample->counter++;

		// indicate we were called
		// print the counter as well
		IOLog( "%s: In timeoutHandler (%ld)\n", myTimerSample->getName(), myTimerSample->counter );
		
		// reset the timer for 5 seconds
		sender->setTimeoutMS( 5000 );
	}
} 


// standard IOKit methods
bool TimerEventSample::init(OSDictionary *dict)
{
    bool res = super::init(dict);
    IOLog("Initializing\n");
    return res;
}

void TimerEventSample::free(void)
{
    IOLog("Freeing\n");
    super::free();
}

IOService *TimerEventSample::probe(IOService *provider, SInt32  *score)
{
    IOService *res = super::probe(provider, score);
    IOLog("Probing\n");
    return res;
}

