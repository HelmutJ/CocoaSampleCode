
Basic Drawing and Event Handling
================================

This sample contains "Squiggles", a Cocoa window-based Application that shows custom drawing and event-handling in a custom subclass of NSView.

--------------------------------

Using the Sample
Build and run the sample using Xcode. Click and drag the mouse in the main view to create one or more "squiggles". 
Use the text field and stepper to apply a rotational tranform repeatedly when drawing.

--------------------------------

Packaging List

ASCSquiggleView.{h,m}
	The primary view in this sample. This is typical of Cocoa progams that need to do custom drawing and event handling. This class overrides the designated initializer -initWithFrame: to initialize its attributes; -drawRect: to support custom drawing; and two NSResponder methods -mouseDown: and -mouseDragged: to handle mouse down and mouse drag events.
	
ASCSquiggle.{h,m}
	This is the lowest level model object in this application. A squiggle has a path, thickness, and color.

ASCSquiggleWindowController.{h,m}
	An instance of ASCSquiggleWindowController functions as the controller object for the application. It responds to messages from a text field, stepper, and button to update the content of the ASCSquiggleView.

MainMenu.xib
	A "nib" file with the main menu, window, and window controller. It will be loaded when the application is first launched, and its "File's Owner" is the instance of NSApplication. The window is configured to be visible on launch. The text field is configured with a number formatter to constrain the value to 1-25.

--------------------------------

Copyright (C) 2012 Apple Inc. All rights reserved.