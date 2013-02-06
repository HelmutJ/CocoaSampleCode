TrackBall
=========

DESCRIPTION:

"TrackBall" is a Cocoa sample application that demonstrates how to create your own custom Cocoa control.
This is structured as a demo for use in the session "Building a Custom Control for your Cocoa Applicaton (125)" for WWDC 2007.

It is designed to show you what you need to do to develop a fully featured Cocoa control based on the NSControl class.
It involves implementing behaviors such as drawing, mouse and scroll wheel tracking, text editing, as well as accessibility.

Listed below is a portion of the class methods TrackBall overrides to achieve its custom behavior:

To construct the proper cell for NSControl:
+ (Class)cellClass;

To control how key strokes are managed.  This allows for arrow keys for rotation. If the option key is depressed, we rotate about the Z axis.
Tab changes the focused portion. and enter/return begin editing a text field:
- (void)keyDown:(NSEvent*)event;

To determine whether we support click-through:
- (BOOL)acceptsFirstMouse:(NSEvent*)event;

To prevent the trackBallView, or any of the subviews from gaining focus:
- (NSView *)nextKeyView;

To support animating of the three coordinates:
+ (id)defaultAnimationForKey:(NSString*)key;

To support a custom appearance:
- (void)drawRect:(NSRect)rect;

To support mouse and scroll wheel behaviors:
- (void)scrollWheel:(NSEvent*)event;
- (void)mouseDragged:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;

To support text editing via NSTextDelegate:
- (void)textDidEndEditing:(NSNotification*)notification;
- (BOOL)textShouldEndEditing:(NSText*)textObject;

To control the NSCell's appearance:
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle;

USING THE SAMPLE:

Simply build and run the sample using Xcode.  Use the track ball control to move around the panoramic image.
To view external panoramic images, use the Image -> Open menu item and choose external spherical panoramic images.


=======================================================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 or later

=======================================================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later


=======================================================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Project update for Xcode 4.
- Application quits when the window is closed.
- Updated code related to validating cell input.
- Updated code for opening files.
Version 1.0
- First release.


=======================================================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.