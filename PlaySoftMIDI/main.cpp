/*	Copyright © 2007 Apple Inc. All Rights Reserved.
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
			Apple Inc. ("Apple") in consideration of your agreement to the
			following terms, and your use, installation, modification or
			redistribution of this Apple software constitutes acceptance of these
			terms.  If you do not agree with these terms, please do not use,
			install, modify or redistribute this Apple software.
			
			In consideration of your agreement to abide by the following terms, and
			subject to these terms, Apple grants you a personal, non-exclusive
			license, under Apple's copyrights in this original Apple software (the
			"Apple Software"), to use, reproduce, modify and redistribute the Apple
			Software, with or without modifications, in source and/or binary forms;
			provided that if you redistribute the Apple Software in its entirety and
			without modifications, you must retain this notice and the following
			text and disclaimers in all such redistributions of the Apple Software. 
			Neither the name, trademarks, service marks or logos of Apple Inc. 
			may be used to endorse or promote products derived from the Apple
			Software without specific prior written permission from Apple.  Except
			as expressly stated in this notice, no other rights or licenses, express
			or implied, are granted by Apple herein, including but not limited to
			any patent rights that may be infringed by your derivative works or by
			other works in which the Apple Software may be incorporated.
			
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
*/
// This is a simple test case of making an simple graph with a DLSSynth, Limiter and Ouput unit

// we're going to use a graph because its easier for it to just handle the setup and connections, etc...

#include <CoreServices/CoreServices.h> //for file stuff
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h> //for AUGraph
#include <unistd.h> // used for usleep...

// This call creates the Graph and the Synth unit...
OSStatus	CreateAUGraph (AUGraph &outGraph, AudioUnit &outSynth)
{
	OSStatus result;
	//create the nodes of the graph
	AUNode synthNode, limiterNode, outNode;
	
	AudioComponentDescription cd;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;

	require_noerr (result = NewAUGraph (&outGraph), home);

	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_DLSSynth;

	require_noerr (result = AUGraphAddNode (outGraph, &cd, &synthNode), home);

	cd.componentType = kAudioUnitType_Effect;
	cd.componentSubType = kAudioUnitSubType_PeakLimiter;  

	require_noerr (result = AUGraphAddNode (outGraph, &cd, &limiterNode), home);

	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_DefaultOutput;  
	require_noerr (result = AUGraphAddNode (outGraph, &cd, &outNode), home);
	
	require_noerr (result = AUGraphOpen (outGraph), home);
	
	require_noerr (result = AUGraphConnectNodeInput (outGraph, synthNode, 0, limiterNode, 0), home);
	require_noerr (result = AUGraphConnectNodeInput (outGraph, limiterNode, 0, outNode, 0), home);
	
	// ok we're good to go - get the Synth Unit...
	require_noerr (result = AUGraphNodeInfo(outGraph, synthNode, 0, &outSynth), home);

home:
	return result;
}


// some MIDI constants:
enum {
	kMidiMessage_ControlChange 		= 0xB,
	kMidiMessage_ProgramChange 		= 0xC,
	kMidiMessage_BankMSBControl 	= 0,
	kMidiMessage_BankLSBControl		= 32,
	kMidiMessage_NoteOn 			= 0x9
};

int main (int argc, const char * argv[]) {
	AUGraph graph = 0;
	AudioUnit synthUnit;
	OSStatus result;
	char* bankPath = 0;
	
	UInt8 midiChannelInUse = 0; //we're using midi channel 1...
	
		// this is the only option to main that we have...
		// just the full path of the sample bank...
		
		// On OS X there are known places were sample banks can be stored
		// Library/Audio/Sounds/Banks - so you could scan this directory and give the user options
		// about which sample bank to use...
	if (argc > 1)
		bankPath = const_cast<char*>(argv[1]);
	
	require_noerr (result = CreateAUGraph (graph, synthUnit), home);
	
// if the user supplies a sound bank, we'll set that before we initialize and start playing
	if (bankPath) 
	{
		FSRef fsRef;
		require_noerr (result = FSPathMakeRef ((const UInt8*)bankPath, &fsRef, 0), home);
		
		printf ("Setting Sound Bank:%s\n", bankPath);
		
		require_noerr (result = AudioUnitSetProperty (synthUnit,
											kMusicDeviceProperty_SoundBankFSRef,
											kAudioUnitScope_Global, 0,
											&fsRef, sizeof(fsRef)), home);
    
	}
	
	// ok we're set up to go - initialize and start the graph
	require_noerr (result = AUGraphInitialize (graph), home);

		//set our bank
	require_noerr (result = MusicDeviceMIDIEvent(synthUnit, 
								kMidiMessage_ControlChange << 4 | midiChannelInUse, 
								kMidiMessage_BankMSBControl, 0,
								0/*sample offset*/), home);

	require_noerr (result = MusicDeviceMIDIEvent(synthUnit, 
								kMidiMessage_ProgramChange << 4 | midiChannelInUse, 
								0/*prog change num*/, 0,
								0/*sample offset*/), home);

	CAShow (graph); // prints out the graph so we can see what it looks like...
	
	require_noerr (result = AUGraphStart (graph), home);

	// we're going to play an octave of MIDI notes: one a second
	for (int i = 0; i < 13; i++) {
		UInt32 noteNum = i + 60;
		UInt32 onVelocity = 127;
		UInt32 noteOnCommand = 	kMidiMessage_NoteOn << 4 | midiChannelInUse;
			
			printf ("Playing Note: Status: 0x%lX, Note: %ld, Vel: %ld\n", noteOnCommand, noteNum, onVelocity);
		
		require_noerr (result = MusicDeviceMIDIEvent(synthUnit, noteOnCommand, noteNum, onVelocity, 0), home);
		
			// sleep for a second
		usleep (1 * 1000 * 1000);

		require_noerr (result = MusicDeviceMIDIEvent(synthUnit, noteOnCommand, noteNum, 0, 0), home);
	}
	
	// ok we're done now

home:
	if (graph) {
		AUGraphStop (graph); // stop playback - AUGraphDispose will do that for us but just showing you what to do
		DisposeAUGraph (graph);
	}
	return result;
}


