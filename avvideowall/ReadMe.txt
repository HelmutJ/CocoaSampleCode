### avvideowall ###

===========================================================================
DESCRIPTION:

avvideowall is a command line application that creates a wall of video out 
of the video capture devices on your Mac.

avvideowall demonstrates the flexibility of AV Foundation capture on Lion. 
It is a command line application that creates a wall of 
AVCaptureVideoPreviewLayers, 4 per capture device in a mirrored square, and 
sends them flying around the screen.  The sample demonstrates how to create 
a complex AVCaptureSession consisting of multiple AVCaptureVideoDeviceInputs 
and multiple AVCaptureVideoPreviewLayers, and how to connect the correct 
inputs to the desired layers.

This sample does not use Automatic Reference Counting. To build, disable ARC
in the Xcode project's Build Settings.

Usage: press space to spin/reset the video preview layers; press q/Q to quit

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.0 or later, Mac OS X v10.7 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.7 or later

===========================================================================
PACKAGING LIST:

AVVideoWall.h
AVVideoWall.m
The AVVideoWall class, builds a video wall of live capture devices

AVVideoWall+TerminalIO.h
AVVideoWall+TerminalIO.m
An AVVideoWall category, responsible for setting up terminal I/O for the 
command line application

main.m
Application main entry point

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- First public release.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.
