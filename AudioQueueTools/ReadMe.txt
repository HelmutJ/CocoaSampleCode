### AudioQueueTools ###

===========================================================================
DESCRIPTION:

The AudioQueueTools project contains three targets for playing, recording, and rendering audio data via the AudioQueue API. aqplay takes an input file and plays it back using an output queue, aqrecord will record a file in a specified data format using an input queue, and aqrender will render an input file to a specified output file using the AudioQueue's offline render functionality. The examples provide a template for simple audio data manipulation using the AudioQueue API new to Leopard.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
PACKAGING LIST:

aqplay.cpp
- Source for file playback using the AudioQueue

aqrecord.cpp
- Source for input recording using the AudioQueue

aqrender.cpp
- Source for offline rendering using the AudioQueue
===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
