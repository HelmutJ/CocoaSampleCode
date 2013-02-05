### TargetGallery ###

===========================================================================
DESCRIPTION:

Simple project that demonstrates how mouse events are routed though a Cocoa Application. It also modifies the event routing by overriding -hitTest:.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.0, Mac OS X 10.6 Snow Leopard or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6 Snow Leopard or later

===========================================================================
PACKAGING LIST:

TargetView.h/m
  This class demonstrates responding to a mouse down event via implementing the -mouseDown: responder method.

TargetGallery.h/m
  This class handles drawing and animating the individual targets. It also demonstrates how to change the initial point in the responder chain for pointer events by overriding -hitTest:.

TargetGalleryController.h/m
  The main controller for this application. This class demonstrates how events may flow up the responder chain to the NSWindowController by implementing mouse tracking to drag targets when in editing mode.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Added NSImage alpha hit testing to the targets.
- Project updated for Xcode 4.
Version 1.0
- First version.

===========================================================================
Copyright (C) 2009-2011 Apple Inc. All rights reserved.
