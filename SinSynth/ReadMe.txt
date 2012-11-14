### SinSynth ###

===========================================================================
DESCRIPTION:

This is a test implementation of a sin wave synth using AUInstrumentBase classes
	
It illustrates a basic usage of these classes
	
It artificially limits the number of notes at one time to 12, so the note-stealing algorithm is used - you should know how this works!
	
Most of the work you need to do is defining a Note class (see TestNote). AUInstrument manages the creation and destruction of notes, the various stages of a note's lifetime.

Alot of printfs have been left in (but are if'def out)

These can be useful as you figure out how this all fits together. This is true in the AUInstrumentBase classes as well; simply define DEBUG_PRINT to 1 and this turns all this on
	
The project also defines CA_AUTO_MIDI_MAP (OTHER_C_FLAGS). This adds all the code that is needed to map MIDI messages to specific parameter changes. This can be seen in AU Lab's MIDI Editor window CA_AUTO_MIDI_MAP is implemented in AUMIDIBase.cpp/.h

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
