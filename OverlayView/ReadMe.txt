### OverlayView ###

===========================================================================
DESCRIPTION:

An overlay view is a straightforward subclass of NSView that can draw on top of sibling views by simply being the last subview of the parent. In 'OverlayView', we imitate a behavior of Interface Builder and Keynote to show "guidelines" between the edge of a view and the edges of the view which contains it. We also use tracking areas to receive mouse moved events and implement some mouse event handling methods to allow the user to move the views.

For this example, an instance of our custom subclass of NSView, OverlayView, is inserted into the view hierarchy as a sibling of an NSBox which contains more views. When the 'Edit' checkbox is selected, the OverlayView is unhidden and draws its contents on top of the other views. Move the mouse over a view to see the guidelines and selection box, or drag the views to rearrange them.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.5 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.5 or later

===========================================================================
PACKAGING LIST:

English.lproj/MainMenu.xib			Defines the user interface for the OverlayView example.
DimensionLineDrawing.m				Logic to do the drawing of the guidelines.
MainController.h					Interface declaration of the controller for the example.
MainController.m					Implementation of the controller for the example, where the overlay view is created and setup.
OverlayView.h						Interface declaration for the NSView subclass OverlayView.
OverlayView.m						Implementation of the OverlayView, which draws selection highlights and guidelines.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
