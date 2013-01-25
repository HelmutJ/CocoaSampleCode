SPLITVIEWS
==========

"SplitViews" is a Cocoa sample application that demonstrates how to use the NSSplitView class.  An NSSplitView object stacks several subviews within one view so that the user can change their relative sizes.

This sample shows how to use the following, (refer to the "Splits" menu for access to all the different kinds of split views) -

1) Horizontal and vertical split views

2) Collapsible split views - users can draw a split view divider in one direction enough to collapse a split view area down to zero size, then able to expand it again.  This is done by using NSSplitViewDelegate:

	- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview;

If a subview is collapsible, the NSSplitView will collapse it when the user has dragged the divider more than halfway between the position that would make the subview its minimum size and the position that would make it zero size. The subview will become uncollapsed if the user drags the divider back past that point.

In this example, it also uses "constrainMinCoordinate" and "constrainMaxCoordinate" delegate methods to constrain the split view sizes to an arbitrary vertical value.

3) Custom dividers - Split views allow for custom dividers allowing you to alter it's size and appearance.  You can do this by subclassing NSSplitView and overriding:

	- (void)drawDividerInRect:(NSRect)rect;

4) Metal-Style split views - After applying "Textured" style to your window, split views can adopt the metal-style appearance along with its window.

5) Real-World Example - In addition this sample shows a real-world example of using split views in a way to easily organize your window's content.  In this case, this sample mimicks a mail style organizer window.

All split view sizes in this sample are persistent across application launches.
This is done by entering a string value for each split view from either Interface Builder, or programmatically through:

    - (void)setAutosaveName:(NSString *)autosaveName;


Creating Split Views in Xcode
============================

>>> Interface Builder: show how to setup a split view <<<


Sample Requirements
===================
The supplied Xcode project was created using Xcode v4.2 with Mac OS X 10.7, running under Mac OS X 10.5.x or later.

	
Changes from Previous Versions
==============================
1.0 - First version


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.


Copyright (C) 2011 Apple Inc. All rights reserved.