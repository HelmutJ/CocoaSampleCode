Animated Slider
===============

ABOUT:

The code in this sample enables all NSSliders in an app to be animated using Core Animation.  The custom category provides an implementation for +defaultAnimationForKey: which returns a linear animation for the slider's "floatValue" property.  This enables the implicit animation of that property.

The rest of the code is a simple IBAction that sets up the animation context and adjusts the slider's value using the animation proxy.

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6 Snow Leopard or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Rewritten to use Core Animation.
- Project updated for Xcode 4.
Version 1.0
- First version.

===========================================================================
Copyright (C) 2001-2011 Apple Inc. All rights reserved.
