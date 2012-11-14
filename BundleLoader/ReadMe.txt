BundleLoader
============

DESCRIPTION:

"BundleLoader" is a Cocoa sample application that demonstrates how to load multiple Cocoa bundles or NSBundles (also known as plug-ins) into the main NSApplication.  This sample is designed to give you an overall demonstration on how to design, implement, search, load and run multiple plugins into your application.  The use of bundles to factor the main application is useful in many ways.  It cuts down on the "bloat-ware" effect in that your application loads only the parts it needs.  This efficiently organizes your application so that portions of it can ship separately from the main.  This enables extendibility as well as facilitate the process of bug fixing and shipping updates in an organized fashion.


NSBUNDLE DISCUSSION:

The NSBundle class provides methods for loading executable code and resources from Cocoa bundles. It handles all the details of loading, including interacting with the Mach-O loader dyld and loading Objective-C symbols into the Objective-C runtime.  The bundles included in this sample represent a "family" of similar bundles in that they contain a unified API.  This API is used by the main application, giving it the ability to use them without knowing the particular details of the bundle.  One example for this model is a main application loading plugins that represent similar devices or devices that operate in a common way but differ in minor ways.

This sample does not cover loading non-Cocoa bundles from within the Cocoa application.  For this topic refer to the Introduction to Bundle Programming Guide.


USING THE SAMPLE:

Simply build and run the sample using Xcode.  The BundleLoader will display all known bundles in its table and you are free to open any one of them.


INSTALLING THE BUNDLES:

One of the biggest design decisions you will make is "Where to install my bundles"  There are many places in the system you can install them.
The most common place would be:
~/Library/Application Support/
(NSPathUtilities refers this location as NSApplicationSupportDirectory).  

For the purposes of this sample and convenience, we have chosen to install each bundle inside the application in its "PlugIns" folder.  This is done by using the "Copy Files Build Phase" in the BundleLoader's Xcode project.  It copies each bundle build result from their respective folders (each build result is found in "UninstalledProducts").  Hence each bundle project has a separate Xcode project and all are direct dependencies to the BundleLoader project.

However, if you choose NOT to install your bundles inside the hosting application, you can skip using the Copy Files Build Phase and set the "Installation Build Products Location" for each bundle Xcode project to -
$(HOME)/Library/Application Support/BundleLoader


DESIGN STRATEGY:

By using [NSBundle principalClass], and the MyBundle base class, the sample is able to load each bundle and communicate with them.
The bundles defined are subclasses of MyBundle and they are: Doodad, Gizmo, Thingamajig and Thingy.

As mentioned earlier our bundles represent a "family" of similar bundles in that they contain a unified API.

The following API is adopted by all bundles in this sample -

- (BOOL)open;	// opens its window
- (void)close;	// closes its window
- (BOOL)isOpen;	// returns YES if its window is currently open
- (BOOL)select;	// selects its window

Each bundle has their own implementation of these methods, giving the bundle writer more freedom on how it operates.  So the bundle writer may choose to use a NSWindowController to manage its UI, or perhaps a generic NSObject controller.

Bundle information can normally be obtained from: [NSBundle infoDictionary], or information from the bundle's Info.plist.  But to demonstrate other kinds of "meta data" related to our bundles, we go beyond this method and offer additional localized string information (i.e. name and description).

The following accessors methods describe the appearance of each bundle.  The strings should not be confused with those found in the bundle's Info.Plist, although they certainly can be one of the same if the writer desires.  We even included a convenience method for obtaining the bundle's icon.

- (NSString*)bundleTitle;		// may not the same as the actual bundle title on disk
- (NSString*)bundleDescription;	// may not the same as [NSObject description]
- (NSImage*)bundleIcon;


RUNTIME BUNDLE SEARCHING:

As mentioned above, we narrow the search to the PlugIns folder inside the application. This sample can be expanded to search other domains as well.  As such, the search operation is contained in a separate thread in case it takes more time (i.e. in places where there are lots of bundles or over the network).  During the search we are careful only to load bundles whose bundleID starts with "com.apple.AppKit.bundleexample.", and ends with ".bundle".  


=======================================================================================================
BUILD REQUIREMENTS

Xcode 4.4, Mac OS X 10.8 or later

=======================================================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6.x or later

=======================================================================================================
CHANGES FROM PREVIOUS VERSIONS

1.2 - Upgraded to Xcode 4.4 and Mac OS X 10.8, fixed some compiler warnings.
1.1 - Project update for Xcode 4.
1.0 - Initial Release.

=======================================================================================================
Copyright (C) 2007-2012 Apple Inc. All rights reserved.