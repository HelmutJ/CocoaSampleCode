MorseSynthesizer

===========================================================================
DESCRIPTION

This Cocoa sample code project shows how to write a speech synthesizer plug-in for the speech synthesis manager. It is designed to demonstrate as much functionality, especially audio functionality, as possible, while abstracting from the complexity of full blown speech synthesis. Therefore, the plug-in translates text into Morse code, rather than into human speech as a typical speech synthesizer plug-in would provide.  

Tasks covered by this project include:
    • Implementing the Speech Synthesis Engine API.
    • Parsing and implementing (a subset of our supported) embedded commands.
    • Generating audio for use in live audio, in the Speech Synthesis audio unit, and for saving to audio files.

To test this project, perform the following steps:

    1. Build all the targets. The Morse target builds the plug-in speech synthesizer. The Samuel target builds a voice for the synthesizer.

    2. Install the built synthesizer in /Library/Speech/Synthesizers

    3. Install the built voice(s) in /Library/Speech/Voices

    4. In Terminal, enter the following command:
        say -v Samuel "SOS I'm trapped in a computer"

Voice Considerations
--------------------
Voices are bundles installed in either /Library/Speech/Voices/YOUR_VOICE_NAME.SpeechVoice or in ~/Library/Speech/Voices/YOUR_VOICE_NAME.SpeechVoice

Speech Synthesizer Considerations
---------------------------------
Speech Synthesizers are bundles installed in /Library/Speech/Synthesizers/YOUR_SYNTHESIZER_NAME.SpeechSynthesizer

===========================================================================
BUILD REQUIREMENTS
Mac OS X v10.7, Xcode 4.1

===========================================================================
RUNTIME REQUIREMENTS
Dependent on how the plug-ins are built, as described in Special Considerations.

===========================================================================
SPECIAL CONSIDERATIONS

    By default, the synthesizer supports our modern API (10.5 or later), which is based on Core Foundation opaque types. To instead make the synthesizer support our legacy API, which was based on raw text buffers, define the preprocessor variable SYNTHESIZER_USES_BUFFER_API, and link with MorseSynthesizerBuffer.m instead of MorseSynthesizerCF.m.

    Our modern voice format (10.5 or later) stores all attributes in the voice bundle's Info.plist file. By running BuildVoiceDescription with the --binary command line option, you may alternatively choose to build a binary VoiceDescription file, as is used in the older voice format.

===========================================================================
PACKAGING LIST

• SynthesizerAPI.m
    Implements the Engine API calls, delegating them to an instance of the MorseSynthesizer class.

• MorseSynthesizer.h
• MorseSynthesizer.m
    Implements the bulk of the synthesizer code.

• MorseSynthesizerCF.h
• MorseSynthesizerCF.m
    Implements the code that is only relevant to the modern API.

• MorseSynthesizerBuffer.h
• MorseSynthesizerBuffer.m
    Implements the code that is only relevant to the legacy API.

• MorseTokenBuffer.h
• MorseTokenBuffer.m
• MorseAudio.h
• MorseAudio.m
    These two classes are mostly concerned with handling the Morse related business logic, as opposed to general purpose speech synthesis code.

• AudioOutput.h
• AudioOutput.m
    Sends the generated audio to the various audio output destinations.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS
Version 1.0 - first version

===========================================================================
RELATED INFORMATION

• Speech Synthesis Programming Guide
• Speech Synthesis Manager Reference
• NSSpeechSynthesizer Class Reference
• CocoaSpeechSynthesisExample
• Manual page of say(1)


===========================================================================
Copyright (c) 2011 Apple Inc. All rights reserved.
