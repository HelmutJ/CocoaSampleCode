### AVSimpleEditorOSX ###

===========================================================================
DESCRIPTION:

A simple AV Foundation document based movie editing application.
This sample is ARC-enabled.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.0 or later, Mac OS X v10.7 or later, ARC enabled. 

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.7 or later

===========================================================================
PACKAGING LIST:

AVSEDocument.m/h:
 The document class. This contains the document level logic including playback.
AVSECommand.m/h:
 The abstract super class of all editing tools.
AVSETrimCommand/AVSERotateCommand/AVSECropCommand/AVSEAddMusicCommand/AVSEAddWatermarkCommand.m/h:
 The concrete subclasses of AVSECommand which implement different tools. 
AVSPDocument.xib:
 The document NIB. This contains the application UI.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
