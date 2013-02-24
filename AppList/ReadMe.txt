AppList

"AppList" is a Cocoa sample application that demonstrates how to use the NSRunningApplication class provided by NSWorkspace.  NSRunningApplication can be used for inspecting and manipulating running applications on the system.  An array of these objects are by NSWorkspace using:

	NSArray* appList = [[NSWorkspace sharedWorkspace] runningApplications];

Only user applications can be tracked; this does not provide information about every process on the system.

Since NSRunningApplication has properties that vary, they can be observed with KVO.  So we use Cocoa bindings to display these properties to the user.  The properties are returned atomically so NSRunningApplication is thread safe.


Sample Requirements
The supplied Xcode project was created using Xcode v3.2 running under Mac OS X 10.6 or later. The project will create a Universal Binary.


Using the Sample
Simply build and run the sample using Xcode.  Select any application from the list to reveal its attributes on the right side of the window.  You can also hide, unhide and quit any selected app.

	
Changes from Previous Versions
n/a


Packaging List
AppController.m
AppController.h
NSApp's main controller object that controls the hide, unhide and quit buttons.  It also contains a custom value transformer for mapping NSBundleExecutableArchitecture values to readable strings.

MainMenu.xib
Contains the menu bar and main window this app along with all the necessary Cocoa bindings to display application attributes. 


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.


Developer Technical Support
The Apple Developer Connection Developer Technical Support (DTS) team is made up of highly qualified engineers with development expertise in key Apple technologies. Whether you need direct one-on-one support troubleshooting issues, hands-on assistance to accelerate a project, or helpful guidance to the right documentation and sample code, Apple engineers are ready to help you.  Refer to the Apple Developer Technical Support page.

Copyright (C) 2008-2009 Apple Inc. All rights reserved.