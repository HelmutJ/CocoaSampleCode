### CustomMenus ###

===========================================================================
DESCRIPTION:

This application demonstrates several implementations of custom menus, including a popup menu with a custom view, and a custom "suggestions" popup window that behaves like a popup menu and properly handles user interactions accordingly.

This application was written as part of the WWDC 2010 "Key Event Handling In Cocoa Applications" session (#145).
Video of this session is available here: https://developer.apple.com/videos/

===========================================================================
BUILD REQUIREMENTS:

OS X 10.8 or later, Xcode 4.4 or later

===========================================================================
RUNTIME REQUIREMENTS:

OS X 10.6.x or later

===========================================================================
PACKAGING LIST:

SuggestionsWindowController.{h,m}
The controller for the suggestions popup window. This class handles creating, displaying, and event tracking of the suggestion popup window.

RoundedCornersView.{h,m}
A view that draws a rounded rect with the window background. It is used to draw the background for the suggestions window and expose the suggestions to accessibility.

SuggestionsWindow.{h,m}
A custom window that acts as a popup menu of sorts.  Since this isn't semantically a window, we ignore it for accessibility purposes. However, we need to inform accessibility of the logical relationship between this window and it parent UI element in the parent window.

HighlightingView.{h,m}
A simple view that draws menu-like highlighting and exposes its containing views as a suggestion for accessibility.

TextFieldCell.{h,m}
A custom text field cell to perform two tasks. Draw with white text on a dark background, and expose any associated suggestion window as our accessibility child.

ImagePickerMenuItemView.{h,m}
A custom view that is used as an NSMenuItem. This view contains up to 4 images and the logic to track the selection of one of those images.

CustomMenusAppDelegate.{h,m}
This class is responsible for two major activities. It sets up the images in the popup menu (via a custom view) and responds to the menu actions. Also, it supplies the suggestions for the search text field and responds to suggestion selection changes and text field editing.

NSImageThumbnailExtensions.{h,m}
A category on NSImage to create a thumbnail sized NSImage from an image URL.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.4 - Upgraded for the OS X 10.8 SDK, removed one build warning, App Sandboxing turned on.
1.3 - Project updated for Xcode 4.
1.2 - First version.

===========================================================================
Copyright (C) 2011-2012 Apple Inc. All rights reserved.
