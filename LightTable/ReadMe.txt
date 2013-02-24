### LightTable ###

===========================================================================
DESCRIPTION:

The "Hello World" of multi-touch applications, LightTable. This sample project demonstrates how to use mouse, gesture, and multi-touch events to provide an enhanced user experience.

Drop images on the Light table and resize them using two fingers and a multi-touch capable trackpad. Also use thee horizontal swipe gesture to slide in and out the selection property controls. Double-click the slide to adjust the image size and placement within the slide.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.6 or later, Multi-touch capable trackpad

===========================================================================
PACKAGING LIST:

LTWindowController.h/.m
  The controller for the document window. This class sets up the bindings between the LTView and the CoreData data that we couldn't do in IB. Also, this class handles the swipe event to bring in and dismiss the tools view.

LTView.h/.m
  This is a custom view that manages drawing and layout of the slides. It allows the user to adjust slides via the mouse or individual touches on the trackpad. All tracking is done with the help of a collection of InputTrackers.

InputTacker.h/m
  This is the base class for InputTrackers. Input Trackers are a technique to factor the various input tracking needs of a view without using tracking loops or complicated internal variables. See InputTracker.h for more information.

ClickTracker.h/.m
  An InputTracker that looks for single and double clicks.

DragTracker.h/.m
  An InputTracker that tracks the dragging of the mouse.

DualTouchTracker.h/.m
  An InputTracker that tracks two touches as they move on the trackpad.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
