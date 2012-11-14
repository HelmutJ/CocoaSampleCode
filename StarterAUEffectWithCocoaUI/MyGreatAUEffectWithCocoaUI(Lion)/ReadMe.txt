### MyGreatAUEffectWithCocoaUI For Lion ###

===========================================================================
DESCRIPTION:

An audio unit (often abbreviated as AU in header files and elsewhere) is a Mac OS X plug-in that enhances digital audio applications such as Logic Pro and GarageBand. You can also use audio units to build audio features into your own application. Programmatically, an audio unit is packaged as a bundle and configured as a component.

This sample is a "Hello World" project demonstrating how to build a Core Audio Audio Unit Effect with a custom Cocoa View. 

The project builds a final AU component called MyGreatAUEffectWithCocoaUI.component with the following Type, SubType and Manufacturer.

aufx Pass Demo  -  SAMPLE: MyGreatAUEffectWithCocoaUI

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.2 or later
Mac OS X 10.7.x Lion
Mac OS X 10.7 SDK

This project will NOT build on Mac OS X 10.6 SnowLeopard -- see TN2276
for more information regarding the AudioComponents changes required to build
on Mac OS X Lion and how to maintain build compatibility with the 10.6 SDK
if that is a goal.

This project will only build on Mac OS X Lion using the Mac 10.7 SDK

http://developer.apple.com/library/mac/#technotes/tn2276/_index.html

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.7 or later.
 
===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 - Based on the Audio Unit Effect With Cocoa View Template from
	      Xcode 3.2.1

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.