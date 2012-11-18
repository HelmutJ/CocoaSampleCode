AUTimePitchTest

===========================================================================
DESCRIPTION:

AUTimePitchTest demonstrates how to build an Audio Unit Graph connecting an AUConverter to a MultiChannel Mixer to the AUTimePitch audio unit then to the Default Output unit.

The AUTimePitch unit can be used to speed up or slow down audio data without changing pitch to facilitate for example, the playing back of an audio book faster or slower than real-time. The same concepts and Core Audio specific APIs demonstrated in this sample may be applied to and used with iOS applications with only minor modification for available audio unit types.

One mixer input bus is created with input volume control an overall mixer output volume control and a bus enabled / disable switch. A client format sets a sample rate of 22kHz and an AUConverter is used at the top of the graph to convert this to the graph sample rate of 11kHz. The sample file has a native sample rate of 44.1kHz. This extracurricular use of different rates are arbitrary choices for demo purposes to show how conversion may happen in different places.

File @ 44.1kHz - > ExtAudioFile - > Client Format @ 22kHz - > AUConverter graph @ 11kHz -> Output

A lot of information about what's going on in the sample is dumped out to the console and can be used to understand how everything is being configured. Methods such as CAShow and the Print() method of the CAStreamBasicDescription helper class are invaluable if you're confused about how stream formats and the AUGraph are being configured.

===========================================================================
RELATED INFORMATION:

Core Audio Overview
Audio Unit Processing Graph Services Reference
Output Audio Unit Services Reference
System Audio Unit Access Guide
Audio Component Services Reference
Audio File Services Reference

AudioToolbox/AUGraph.h
AudioToolbox/ExtendedAudioFile.h

===========================================================================
SPECIAL CONSIDERATIONS:

This sample has been configured with 10.7 as the OS X Deployment Target. The following is only a concern if you plan to use the multichannel mixer on Mac OS X 10.6.x.

Mac OS X 10.6.x:
There is a known issue with the bus enable/disable property kMultiChannelMixerParam_Enable. Setting this property for a bus with the multichannel mixer does not currently work, the bus is always enabled regardless. Therefore the enable/disable UI checkbox does not currently appear to do anything however the code setting the parameter is correct. This issue was fixed on OS X 10.7.

Enabling/disabling mixer busses works as expected with other mixer audio units such as the Matrix Mixer.

iOS:
The kMultiChannelMixerParam_Enable parameter works correctly on iOS.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.8 SDK

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.7 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0, Tested with Mac OS X 10.7

===========================================================================
Copyright (C) 2010-2012 Apple Inc. All rights reserved.