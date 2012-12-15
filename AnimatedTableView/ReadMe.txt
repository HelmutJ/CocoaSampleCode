### AnimatedTableView ###

===========================================================================
DESCRIPTION:

This example demonstrates some advanced concepts and features in NSTableView and NSBrowser. The application loads images from a specific directory and displays them in a custom NSTableView subclass on the left side. The Table View displays a list of cells that display an desktop background image along with a fill color that can be edited with a custom pop-up color editor. While images are loading, an animated progress indicator is added to the Table View. A basic NSImageView displays the selected image on the right side of the window, which can then be set as the desktop wallpaper via a button click. Double clicking on the large Image View will bring up a customized NSBrowser that allows modifying the image through a series of CoreImage filters.

The sample code uses a common two-letter prefix (AT) to avoid conflicting with any standard Apple frameworks.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.3, Mac OS X v10.7.x or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.6.x or later

===========================================================================
PACKAGING LIST:

ATDesktopEntity.h/.m: 
 The basic sample model for the application. The ATDesktopEntity is an abstract base class that provides title and fileURL properties. The ATDesktopFolderEntity is a concrete subclass that loads an array of children from the fileURL set on it. The children can be other ATDesktopFolderEntities, or ATDesktopImageEntities. The ATDesktopImageEntity subclass stores an image, thumbnailImage and fillColor that can be set as the desktop wallpaper. The ATDesktopImageEntity provides the thumbnailImage and image properties asynchronously to avoid blocking the main thread. Key Value Observing (KVO) is used by the main controller (ATContentController) to discover when the properties are available or have changed. 

ATImageTextCell.h/.m:
 A custom NSTextFieldCell subclass that demonstrates using sub-cells to draw the individual cell parts. An NSImageCell draws the image on the left of the cell, while a custom ATColorCell draws a color swatch and title on the lower right.

ATColorCell.h/.m:
 A simple NSTextFieldCell subclass that draws a color swatch to the left of the text title.

ATDynamicTableView.h/.m:
 An NSTableView subclass shows how to properly extend the delegate and add support for batch loading of contents as they are needed on screen. It also adds delegate support for providing a subview that can be used to show animations inside of the Table View (such as a progress indicator).

ATFilterBrowserController.h/.m:
 An NSWindowController subclass that has an associated nib (ATFilterBrowser.xib) containing a window with an NSBrowser on it. This class is the controller for the window, nib and Browser. The application's main controller (ATContentController) uses this class as a means to provide sourceImage and get back a generated filteredImage.

ATFilterItem.h/.m:
  The ATFilterBrowserController displays ATFilterItems inside of the NSBrowser that it displays. The ATFilterItems provide a wrapper around a CoreImage filter that takes a source image and provides a resulting image with the filter applied to it.

ATFilterBrowser.xib:
 The basic nib file used by the ATFilterBrowserController to show the window and Browser inside of it.

ATFilterBrowserColumnHeader.xib:
 The ATFilterBrowserController provides the ATFilterBrowserColumnHeader.xib to the NSBrowser when a column header is needed. It uses a basic NSViewController to load the nib. Inside the nib, the 'view' outlet for the owner (the NSViewController) is setup to be the desired column header NSView.

ATFilterBrowserColumnHeader.xib:
 The ATFilterBrowserController provides the ATFilterBrowserPreview.xib to the NSBrowser when a column preview is needed. It uses a basic NSViewController to load the nib. Inside the nib, the 'view' outlet for the owner (the NSViewController) is setup to be the desired preview NSView.

ATBorderView.h/.m:
 A simple NSView subclass that draws a border around the view, with an arrow pointing to the top center of the view. This view is used by the pop-up window.

ATColorView.h/.m:
 A simple NSView subclass that adds a backgroundColor property. The property only works if the view is layer-backed (setWantsLayer:YES)

ATDblActionImageView.h/.m:
 A simple NSImageView subclass that sends the action out when the view is double clicked. Normally an action for an NSImageView is only sent when the view's contents changes.

ATPopupWindow.h/.m:
 A custom NSWindow that mainly implements a "popup" animation using CoreAnimation.

ATContentController.h/.m:
 The main application controller. Uses the model to display the images from "/Library/Desktop Pictures", and controls the User Interface.

ATColorTableController.h/.m:
 A basic controller that implements the NSTableView datasource/delegate methods for the color popup table. This class is used by the ATImageTextCell to edit its color property in a new window.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.1 - Upgraded to Xcode 4.3 and Mac OS X 10.7, fixed some leaks.
1.0 - First version.

===========================================================================
Copyright (C) 2009-2012 Apple Inc. All rights reserved.
