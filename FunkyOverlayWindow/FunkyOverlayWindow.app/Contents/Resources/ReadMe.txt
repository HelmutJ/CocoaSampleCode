FunkyOverlayWindow
==================

ABOUT:

This Cocoa sample shows how to do several different things with windows and Cocoa widgets, by providing a floating "overlay" window interface with a "selection box" that traverses the window.  This sample demonstrates:

how to create transparent windows
how to draw transparent NSButtons with non-transparent cell content
how to ensure that mouse clicks on a window go through the window to the content underneath
how to create and use mouse tracking areas
how to have an overlay window that fades in/out based on mouse tracking
how to use the Carbon HotKey API in a Cocoa application
how to do drag-and-drop to an NSMatrix, targeting a particular cell in the matrix
how to attach windows to each other so that if one moves, the other does too (although the parent window can't be moved in this example)

The techniques demonstrated in this sample might be useful for a developer working on a utility of one sort or another.  When you mouse over the overlay window, it fades in and the blue selection box (itself another child window) starts tracking over the window.  Pressing cmd-return will change the direction that the selection box tracks.  Moving your mouse off the window will cause the selection box to stop tracking, and the overlay window to fade back out again.  You can also drag image files into buttons in the window and the buttons will use those images.

There are three main transparency techniques demonstrated in this sample:

1) You can call -setAlphaValue: on the window to set the transparency of the whole window.  This sets the transparency of the window's contents as well, which may or may not be what you want.

2) You can leave the alpha of the window as it is, and instead (or in addition) fill the window with a transparent view (having already called -setOpaque:NO on the window) and then just render what you want into that window.

3) The first two techniques have been demonstrated for a while in the RoundTransparentWindow sample.  But a third technique is demonstrated here: how to make an NSButton transparent, with the image being drawn on it not transparent.  This is done by first rendering the button's cell into an NSImage, then compositing the image to the controlView with transparency, and then drawing the contents of the button's cell frame again with no transparency.

===========================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later.

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Rewrote mouse tracking to use NSTrackingArea.
- Rewrote animation to use Core Animation.
- Project updated for Xcode 4.
Version 1.0
- Initial Version

===========================================================================
Copyright (C) 2003-2011 Apple Inc. All rights reserved.