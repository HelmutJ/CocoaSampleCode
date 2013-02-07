Basic Cocoa Animations
======================

DESCRIPTION:

"BasicCocoaAnimations" demonstrates the use of the animator proxy to easily animate views and windows.  The frame of the main window and the opacity of the inspector window animates.  Switching between toolbar items changes the view in the window with a basic transition animation.  The first two toolbar panels demonstrate animating one or multiple views.

Using the NSAnimationContext to change the duration of an animation is also demonstrated.

This is structured as a demo for use in the session "Building Animated Cocoa User Interfaces (210)" for WWDC 2007.


Main Window
===========
The MainWindowController.m file demonstrates three things:

1. The moveView: action method shows calling the animator to change a single view's frame origin.

2. The moveAllViews: action method shows changing a number of view's attributes at once.

3. Finally, as you select different items in the toolbar, the window resizes and the new view content fades in.  The pieces that make this happen are in two places:

In -awakeFromNib:, -setWantsLayer: makes the window content view layer-backed.  This is required for the transition animation.

In -switchView: the same methods are called as usual to change a window's frame and to replace subviews with one difference, we add the call to the animator in both cases to cause the effect.

Also notice the use of the NSAnimationContext to change the duration of the animation if the user has the Shift key held when they click.  This gives the 'slow-motion' effect often seen in demos.


Inspector Window
================
You can show the inspector window using View > Inspector

The inspector window implements the sometimes seen effect where an inspector that hasn't been used in a while slowly loses opacity, but returns to full opacity quickly when the mouse is over the window.

The InspectorController.m file contains the implementation of this.  The mechanism uses the NSTrackingArea mechanism introduced in Mac OS X 10.5 Leopard to receive mouse entered and mouse exited events.

The timer used is not to drive the animation, but just to give a reasonable delay before the window starts fading.  Note that fading in and out is simply a matter of calling the animator and setting the alpha value of the window.  Note also the use of the NSAnimationContext to cause a long, slow fade of the window.

=======================================================================================================
BUILD REQUIREMENTS

Xcode 3.2 and Mac OS X 10.6 Snow Leopard or later.

=======================================================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

=======================================================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Updated project for Xcode 4.
Version 1.0
- First release.

=======================================================================================================
Copyright (C) 2007-2011 Apple Inc. All rights reserved.