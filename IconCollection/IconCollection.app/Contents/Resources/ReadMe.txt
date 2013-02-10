IconCollection

"IconCollection" is a Cocoa sample application that demonstrates how to use NSCollectionView along with NSWorkspace and named images to determine its content.  

Since creating an NSCollectionView object yields multiple top-level nib objects, it is recommended that you build a separate nib file for each NSCollectionView.   Doing so will make nib object management easier in the long run.  This sample illustrates this point by leveraging the capabilities of NSViewController, an efficient way to factor and manage your nib files based on views.

Sample Requirements
===================
The supplied Xcode project was created using Xcode v3.2 running under Mac OS X 10.6.x.

Using the Sample
================
Simply build and run the sample using Xcode.  Use the window's toolbar items to manipulate the contents of the collection view.

1) Ascending/Descending sort order -
	Affects the collection view's sort order indirectly by setting the NSArrayController sort descriptors.
2) Alternate colors -
	Set on the collection view's background colors (alternate colors) by calling:
		- (void)setBackgroundColors:(NSArray *)colors;
	If alternate colors is turned off, the NSCollectionView's enclosing scroll view draws its background using NSGradient.
3) Searching - 
	Changes what the collection view displays based on the icon display name indirectly by setting the NSArrayController's filterPredicate.
4) Uses NSBox "Transparent" binding to affect the collection view's selection appearance.
5) Collection view selection -
	A text label binds to the array controller selection to detect selection changes.
	This is done by binding to MyWindowController,
		model key path = "viewController.arrayController.selection.name".
	It also overrides both "Multiple Values Placeholder" and "No Selection Placeholder" for this this value binding.

Packaging List
==============
AppDelegate.m
AppDelegate.h
NSApp's main delegate, instructed to quit when the last window closes, and helps open the sample's ReadMe from the Help menu.

MyWindowController.h
MyWindowController.m
The NSWindowController object for the sample's main window.

MyViewController.h
MyViewController.m
The view controller based on NSViewController which manages all aspects of the collection view.  It owns "Collection.xib" as the File's Owner.

IconViewPrototype.xib
The nib file containins the collection view's prototype and view; the File's Owner is the NSCollectionViewItem class.

MainMenu.xib
The nib file for the app's delegate, window controller and menus.

Collection.xib
The nib file containing all necessary objects for managing the NSCollectionView.  It contains the array controller; the File's Owner is the NSViewController class.

icons.plist
A property list consisting of an array if dictionary objects describing the collection items.  This file is read by MyViewController to populate its array controller.

Changes from Previous Versions
==============================
Version 1.2 - Now builds 3-way Universal (ppc, i386, x86_64), gradient background now draws properly within the "documentVisibleRect".
Version 1.1 - Upgraded to support changes in NSCollectionView for SnowLeopard:
		- Adopted the nib-based approach for the prototype view.
		- Made the collection view a dragging source.
Version 1.0 - First release.

Feedback and Bug Reports
========================
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.

Developer Technical Support
===========================
The Apple Developer Connection Developer Technical Support (DTS) team is made up of highly qualified engineers with development expertise in key Apple technologies. Whether you need direct one-on-one support troubleshooting issues, hands-on assistance to accelerate a project, or helpful guidance to the right documentation and sample code, Apple engineers are ready to help you.  Refer to the Apple Developer Technical Support page.

Copyright (C) 2007-2011 Apple Inc. All rights reserved.