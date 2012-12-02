MenuItemView
============

"MenuItemView" is a Cocoa sample application that demonstrates how to embed an NSView inside a menu item or NSMenuItem in Mac OS X.  This sample is intended to show how this is done with various user interface elements such as controls and the menu bar.

Each NSView is added to a particular menu item by calling -
	[NSMenuItem setview:theView];

===========================================================================
Sample Requirements
The supplied Xcode project was created using Xcode v4.3 or later running under Mac OS X 10.6.x or later.

===========================================================================
Using the Sample
Simply build and run the sample using Xcode.  In the menu bar, "Custom" will contain the menu with embedded NSViews.  This same menu can also be found in the main window's controls as well as in the image view's contextual menu.  It is designed to show how this menu can be applied to different areas of the user interface.

Keep in mind should you choose to share this menu in different areas (like in this sample), that you cannot share the same menu instance among the various places.  You need to makes copies of the menu and its embedded views where ever you apply them.

===========================================================================	
Changes from Previous Versions

1.0 - First release.
1.1 - Fixed label color drawing bug during mouse tracking.
1.2 - Upgraded to Xcode 4.3 and Mac OS X 10.7, removed deprecated API use, fixed some leaks.


Copyright (C) 2010-2012 Apple Inc. All rights reserved.