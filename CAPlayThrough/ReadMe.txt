### CAPlayThrough ###

===========================================================================
DESCRIPTION:

The CAPlayThrough example project provides a Cocoa based sample application for obtaining all possible input and output devices on the system, setting the default device for input and/or output, and playing through audio from the input device to the output. The application uses two instances of the AUHAL audio unit (one for input, one for output) and a varispeed unit. the varispeed does two things: 
(1) if there is a difference between the sample rates of the input and output device, the varispeed AU does a resample (this is a setting that is made and is constant through the lifetime of the I/O operation, presuming the devices involved don't change) 
(2) As the devices involved may NOT be synchronised, a further adjustment is made over time, by varying the rate of playback between the two devices. This rate adjustment is made by looking at the rate scalar in the time stamps of the two devices. The rate scalar describes the measured difference between the idealised sample rate of a given device (say 44.1KHz) and the measured sample rate of the device as it is running - which will also vary. This adjustment is made by tweaking the rate parameter of the varispeed.

The app also uses a ring buffer to store the captured audio data from input and access it as needed by the output unit.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.7 or later
Xcode 4.3 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
PACKAGING LIST:

CAPlayThroughController.h
CAPlayThroughController.mm
- Controller class for managing PlayThrough objects. Handles building the available devices menu, resetting the PlayThrough objects, and starting and stopping the audio feed.

CAPlayThrough.h
CAPlayThough.cpp
- The CAPlayThrough class. Handles capturing data from input, storing to the ring buffer, and retrieving it for use by the output unit. Also performs the setup for the ring buffer, two AUHAL units and varispeed unit.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- First version.
- Updated for Mac OS X 10.7 Lion & Xcode 4.3, now using newer AudioObjectXXX APIs.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
