ButtonMadness
=============

"ButtonMadness" is a Cocoa application that demonstrates how to use the various type of buttons.  It demonstrates two approaches: 1) creating buttons using Interface Builder, 2) creating the same buttons using code.  Apple recommends that you of course design your application with Interface Builder whenever possible.  However, there may be an occasion when you need to do control creation using code in situations where you don't exactly know the make up of your UI until the application or user loads something.  This sample shows both approaches as it gives you an idea of the "magic" that goes on behind the scenes in Interface Builder to create the standard UI elements.  So this sample gives you the knowledge in programmatically creating these buttons, affect their behavior, and setting their target/action connections.


General Approach
Create a "CustomView" placeholder in the nib file - this will determine the placement and size of the control.
- Note that you may choose to not use a placeholder view and determine its location coordinates and size on your own.
- For convenience, this sample simply leverages the CustomView for easy control placement.

At nib loading time (awakeFromNib, or windowControllerDidLoadNib if Document-based) - - Create an instance of the desired class, and set its frame to match the placeholder. - Set up the attributes of the control. - Add the newly created control as a subView of the parent view (in our case NSBox). - Remove the placeholder CustomView.


Sample Requirements
The supplied Xcode project was created using Xcode v3.2 running under Mac OS X 10.6.x or later.


About the Sample
"ButtonMadness" shows off the following:

1. NSPopUpButton - Pull down and popup style menus.

2. NSButton - Icon buttons: normal or momentary type buttons.  It also includes a special custom button "DropDownButton" for menus.

3. NSMatrix - A matrix of Radio cells.

4. NSColorWell

5. NSSegmentedControl - Introduces a special Objective-C category to un-select all segments.

6. NSLevelIndicator - Includes the ability to change them to the four known indicator styles.

To examine the action results of these controls, refer to the Console Log or Run Log.


Using the Sample
Simply build and run the sample using Xcode.  Play with the various buttons to see how they operate.  Look over the nib file to see how they are setup, then look at the code to see how they are programmatically created.

	
Changes from Previous Versions
1.0 - First release
1.1 - Upgraded to support 10.6, now builds 3-way Universal (ppc, i386, x86_64), some more optimized code.
1.2 - Removed all compiler warnings, upgraded for Xcode 4.3/Lion.

Copyright (C) 2007-2012, Apple Inc.