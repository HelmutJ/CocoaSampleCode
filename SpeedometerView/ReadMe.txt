SpeedometerView
===============

DESCRIPTION:

This sample illustrates how to make a custom NSView that does some drawing and responds to mouse clicks.  The SpeedometerView class is a subclass of NSView and it is defined in the files SpeedometerView.h and SpeedomenterView.m.  The files SpeedyCategories.h and SpeedyCategories.m define some helper categories that are used by the view.  

To use this custom NSView in a project of your own, follow these steps:

1.  Drag a custom view object from the interface builder library into the nib file.

2.  Select the custom view and assign the SpeedometerView class to it in the class field.


This sample uses bindings to manage most of its user interface.  As such, there is no code in the project for maintaining these items.  Here is a summary of the bindings that are in place:


1. The ticks slider's value has a binding to the custom view's ticks value.  The slider's attributes are set to continually update as the value is changed.  

2. The curve slider is bound the custom view's curvature value.  The slider's attributes are set to continually update as the value is changed.

3. The speed slider is bound to the custom view's speed value.  The slider's attributes are set to continually update as the value is changed. 

4. The little progress indicator is bound to the draggingIndicator value on the custom view.  The little indicator shows up while the speedometer pointer is being dragged.  

=======================================================================================================
BUILD REQUIREMENTS

Xcode 4.3, Mac OS X 10.7.x or later

=======================================================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6.x or later

=======================================================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.3
- Upgraded to Xcode 4.3 and Mac OS X 10.7, fixed some compiler warnings.
Version 1.2
- Updated classes to use properties.
- Project updated for Xcode 4.
Version 1.1
- Updated NSString to NSBezierPath conversion routine.
Version 1.0
- First release.

=======================================================================================================
Copyright (C) 2007-2012 Apple Inc. All rights reserved.