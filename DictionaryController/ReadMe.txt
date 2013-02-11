DictionaryController
====================

"DictionaryController" is a Cocoa application that demonstrates various ways to use the NSDictionaryController class. A dictionary controller transforms the contents of a dictionary into an array of key-value pairs that can be bound to user interface items such as columns of a table view.  With the dictionary controller, you can specify which key-value pairs to be included or excluded for display as well as associate a localized displayable key to each pair.

===========================================================================
SAMPLE REQUIREMENTS

The supplied Xcode project was created using Xcode v3.2 with Mac OS X 10.6, running under Mac OS X 10.5.x or later.


===========================================================================
ABOUT THE SAMPLE

As a primary illustration, this sample shows how to display individual NSDictionary objects loaded from the file called people.dict.

Each person dictionary looks like the following:

<dict>
	<key>lastName</key>
	<string>Public</string>
	<key>firstName</key>
	<string>John Q.</string>
	<key>street</key>
	<string>679 North Michigan Ave.</string>
	<key>city</key>
	<string>Chicago</string>
	<key>state</key>
	<string>IL</string>
	<key>zip</key>
	<string>60611</string>
	<key>id</key>
	<string>459</string>
</dict>

An instance of NSDictionaryController is used to display this information in a table.  Its content is bound to the current selection in the table view on the left side of  the main window.  Notice the last key/value pair named "id".  This is of little concern to the user so the dictionary controller marks this as an "Excluded Key".  Also the "lastName" and "firstName" keys will have a corresponding localized key loaded from Localizable.strings file.  This feature allows keys from the dictionary to have displayable values seen by the user.

===========================================================================
USING THE SAMPLE

Build and run the sample using Xcode.
1) In the main window, select any person in the table on the left to reveal their corresponding NSDictionary objects displayed in the table on the right which is bound to a dictionary controller.  Details of the selection in the right hand table are shown in three text fields under the table. Notice the bindings for the three text fields: all are bound to the dictionary controller's selection, with the following model key paths:
	The first is bound with Model Key Path = "value"
	The second is bound with Model Key Path = "key"
	The third is bound with Model Key Path = "localizedKey"
We achieve this since the objects managed by our dictionary controller are key-value pair objects that comply with the NSDictionaryControllerKeyValuePair informal protocol.
	
2) In the File or Folder window, drop any file or folder from the Finder to the window's drop location to reveal its corresponding dictionary displayed in the table below it.

===========================================================================
PACKAGING LIST

AppDelegate.m
AppDelegate.h
	NSApp's main delegate, manages MyWindowController and helps open the sample's ReadMe from the Help menu.
	This class is responsible for creating and opening both windows (MyWindowController, DropWindowController) for this sample.

MyWindowController.h
MyWindowController.m
	The NSWindowController object for the sample's main window.
MainWindow.nib
	The nib for the MyWindowController.

DropWindowController.h
DropWindowController.m
	The NSWindowController object for the sample's "File or Folder" window.
DropWindow.nib
	The nib for the DropWindowController.

DropView.h
DropView.m
	A custom NSView used to receive file or folder drops from the Desktop.  This view resides in the DropWindow nib.

people.dict
	A dictionary file containing the list of people to be displayed in this sample.

Localizable.string
	Contains the localized key strings to be applied to the NSDictionaryController.


Upgraded to support 10.6, now builds 3-way Universal (ppc, i386, x86_64)

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Upgraded to support 10.6, now builds 3-way Universal (ppc, i386, x86_64), removed one deprecated API.

Version 1.0
- New Release


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.

Copyright © 2007-2011 Apple Inc. All rights reserved.