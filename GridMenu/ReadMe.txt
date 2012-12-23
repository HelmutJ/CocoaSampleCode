GridMenu
========

"GridMenu" is a Cocoa sample application that demonstrates how to implement "grid-like" menus from an NSPopupButton using NSMatrix, NSCollectionView and NSTrackingArea as the contents. This is done by embedding a custom NSView inside a NSMenuItem; the two custom views being NSMatrix and NSCollectionView and the tracking area view which hosts multiple NSTrackingAreas.

===========================================================================
In using NSCollectionView it uses the new implementation introduced in 10.6.  Starting with 10.6 NSCollectionViewItem is a subclass of NSViewController.  This sample shows how to use the new implementation at the same time be compatible with 10.5.x.

===========================================================================
Sample Requirements

The supplied Xcode project was created using Xcode v4.3 or later, running with Mac OS X 10.5.x or later.

===========================================================================
Changes from Previous Versions

1.1 - Upgraded to Xcode 4.3 and Mac OS X 10.7, fixed some compiler warnings.
1.0 - First version

===========================================================================
Copyright (C) 2010-2012 Apple Inc. All rights reserved.