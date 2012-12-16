SourceView
==========

"SourceView" is a Cocoa sample application that demonstrates how to use NSOutlineView driven by NSTreeController and various other Cocoa classes to produce a Finder-like source view.

Among the features demonstrated are -

- Source outline view using NSOutlineView using a custom outline cell ImageAndTextCell,
- Loading dictionary data from disk using [NSDictionary dictionaryWithContentsOfFile…] to populate the outline view,
- Outline view uses selection highlight style: NSTableViewSelectionHighlightStyleSourceList, which gives is a gradient-style selection.
- Icon view of directories using NSCollectionView,
- Viewing URLs using WebView,
- Outline view drag and drop support for URLs and file system-based objects (from Safari, Finder, etc),
- Factoring or organizing its various NSViews into a separate nib using NSViewController,
- Factoring or organizing its various Windows into a separate nib using NSWindowController,
- Obtaining file system icons using NSWorkspace,
- NSplitView sub-pane size management during divider resize,
- Using template images in our buttons such as NSImageNameAddTemplate and NSImageNameRemoveTemplate,
- NSWindow edge alteration using [NSWindow setContentBorderThickness]


===========================================================================
BUILD REQUIREMENTS:

The supplied Xcode project was created using Xcode v4.3 or later running under Mac OS X 10.7.x or later.

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6.x or later

===========================================================================
USING THE SAMPLE:

Simply build and run the sample using Xcode, launch SourceView and examine the contents in the outline view.
The first section "Devices" is automatically added with the help of: [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]. The second section "Places" is also automatically added by the window controller.

The sections following are determined by the external Outline.dict file, read in as a NSDictionary and populated into the NSOutlineView.  You can experiment on your own with adding and removing items in this file.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First Release
1.1 - Upgraded to support 10.6, now builds 3-way Universal (ppc, i386, x86_64), fixed a bug when removing a folder failed to update the detail view.
1.2 - Upgraded for Xcode 4.3/Lion, removed all compiler warnings, plugged up some memory leaks, leveraging improvements to Obj-C runtime.
1.3 - Fixed bug in setting the webView's URL.

===========================================================================
Copyright © 2007-2012 Apple Inc. All rights reserved.