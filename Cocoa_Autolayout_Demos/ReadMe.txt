Cocoa_Autolayout_Demos
======================

These demo sample apps illustrate the Cocoa Autolayout API, new in Mac OS X 10.7.  

"FindPanelLayout" demonstrates how code in the controller layer uses the API.  It lays out a window that is fairly complex with classic Cocoa layout (if the strings are dynamic, as they are across localizations), and straightforward with constraints.  This example illustrates use of the visual format language, content hugging priority, RTL and localization support, automatic window minimum size, visualization for debugging, and the concept of ambiguity as something that can go wrong.  This is a good first sample to look at. 

"SplitView" demonstrates the API from the perspective of a view.  It implements a split view with one extra feature: when a divider is dragged, it pushes other dividers out of the way if necessary, and they snap back.  The class is 245 lines long compared with NSSplitView's 2502. This is of course not a fair comparison because NSSplitView does more, but it's clear that it's a lot simpler, particularly in the dragging code.  This example illustrates fancy use of priority, overriding updateConstraints, dragging, and constraints that cross the view hierarchy.

"DraggingAndWindowResize" is a bit of a priority lab.  It shows a view with its own drag resize box inside of a window, like Safari has for multiline editable text views in a web page.  If the window needs to get bigger to accommodate your dragging, it does.  This demonstrates mainly NSLayoutPriorityDragThatCanResizeWindow.

"Cocoa Layout (Beta).tracetemplate" is the Instruments template discussed in the Autolayout release notes section on debugging. Use it for debugging.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.
