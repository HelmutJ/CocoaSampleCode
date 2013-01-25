ViewController
==============

DESCRIPTION:

"ViewController" is a Cocoa sample application that demonstrates how to use the NSViewController class.  The NSViewController class serves roughly the same purpose of NSWindowController, in that it manages an associated NSView from a nib file.  It does the same sort of memory management of top-level objects that NSWindowController does.  The NSViewController is usually the File's Owner of the nib file.


ABOUT:

"ViewController" shows how you can swap in and out NSViews from separate nib files onto your window.

A popup button will present four different choices -
1) CustomImageView - loads the custom NSView found in "CustomImageView.nib" which h olds the NSImageView.
The File's Owner of this nib is CustomImageViewController, a subclass of NSViewController.

2) CustomTableView - loads the custom NSView found in "CustomTableView.nib" which holds the NSTableView.
The File's Owner of this nib is CustomTableViewController, a subclass of NSViewController.

3) CustomVideoView - load the custom NSView found in "CustomVideoView.nib" which holds a AVPlayerLayer.
The File's Owner of this nib is CustomVideoViewController, a subclass of NSViewController.

4) CustomCameraView - load the custom NSView found in "CustomCameraView.nib" which holds a QCView (Quartz Composer).
This does not use a subclass of NSViewController as QC gives easy access to the iSight camera without using any code.
The file "iSight.qtz" is used to hook up the iSight camera.

Two NSTextField values in the window are bound to:
1) The view controller's title which is obtained from [NSViewController title] method.
2) The View controller's representedObject - which in this case is the number of subviews found in the nib (i.e. the representedObject is an NSNumber).
So case number two illustrates how you can bind to the representedObject.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.1, Mac OS X 10.7 Lion

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.7 Lion

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Updated video playback to use AVFoundation.
- Project updated for Xcode 4.
Version 1.0
- First version.

===========================================================================
Copyright (C) 2007-2011 Apple Inc. All rights reserved.