PhotoSearch
===========

AppKit Sample application for the WWDC 2007 session:
"Beyond Buttons and Sliders - Advanced Controls in Cocoa"

===========================================================================
Sample Requirements

The supplied Xcode project builds with Xcode 4.4 Mac OS X 10.8 and runs on 10.8 or later.

This sample is also designed to be App Sandboxed, and with Sandboxing, it means this app should also be code signed.

===========================================================================
About the Sample

This sample application uses Spotlight to perform a search for images on your computer. The search location or search scope can also be customized by the user.  The results are displayed in a custom cell, ImagePreviewCell. A custom NSOutlineView subclass is used to automatically add tracking areas to perform automatic rollover highlighting effects inside the cells. A custom DateCell class is implemented that demonstrates how to properly truncate dates based on the cell size. The NSPredicateEditor (introduced in Leopard) is used to create a search rule. The NSPathControl (introduced in Leopard) is used to display a selected path. This demo also has a special menu under the main application named "What's This?" that demonstrates setting custom views to an NSMenuItem.

PhotoSearch is App Sandboxed which offers strong defense against damage from malicious code.  In doing so, it allows you to retain access to file-system resources by employing a security mechanism, known as security-scoped bookmarks, that preserves user intent between app launches.  Hence, the search location or scope becomes a security-scoped bookmark.


* CellTrackingRect.h: Defines an abstract NSCell category for implementing tracking areas.
* DateCell.h/.m: A custom cell that can automatically truncate the date shown based on the available size.
* ImagePreviewCell.h/.m: A custom cell that demonstrates custom drawing, hit testing, custom tracking and custom editing.
* MainWindowController.h/.m: The main controller that glues the user interface to the data model.
* SearchItem.h/.m: The data model representation for a search result.
* SearchQuery.h/.m: The data model representation for a search query, which contains an array of SearchItem children.
* TrackableOutlineView.h/.m: A custom NSOutlineView subclass that automatically adds tracking areas for a cell that implements the category defined in CellTrackingRect.h
* CaseInsensitivePredicateTemplate.h/.m: A custom predicate template used by the NSPredicateEditor to have a case insensitive Spotlight search.
* MenuController.h/.m: Hooks up custom views to menu items.
* GameView.h/.m: A custom game view used in the menu.


===========================================================================
Changes from Previous Versions

1.0 - first version
1.1 - Updated the row height of the NSPredicateEditor
1.2 - Removed pre-Leopard workarounds for highlighting cells. Also replaced deprecated -selectRows:byExtendingSelection: and -columnsInRect: with their modern NSIndexSet replacements.
1.6 - Upgraded to Xcode 4.5 and Mac OS X 10.8, app is now sandboxed, and uses a security-scoped bookmark of the search location, fixed some leaks, eliminated some compiler warnings. 

===========================================================================
Copyright (C) 2007-2012 Apple Inc. All rights reserved.