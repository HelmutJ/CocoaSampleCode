### TableViewPlayground ###

===========================================================================
DESCRIPTION:

This example demonstrates the View Based TableView. The demo focuses on three areas: 1. Basic TableView, 2. Complex TableView, 3. Complex OutlineView. The same model is shared between the Complex TableView and OutlineView classes.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.8 or later
XCode 4.1 or later.

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.8 or later

===========================================================================
PACKAGING LIST:

ATDesktopEntity.h/.m: 
 The basic sample model for the application. 

ATApplicationController.h/.m:
 Main controller for the application.

ATBasicTableViewWindowController.h/m:
 Basic controller implementation for a basic View Based TableView.

ATColorTableController.h/.m:
 Controller for the color table popup used in the ATComplextTableViewController example

ATColorView.h/.m:
 Simple view that adds an animatable background color.

ATComplexOutlineController.h/.m:
 Complex Outline View example controller.

ATComplexTableViewController.h/.m:
 Complex Table View example controller. 

ATObjectTableRowView.h/.m:
 Extends NSTableRowView by adding an objectValue for the row.

ATSampleWindowRowView.h/.m:
 Extends NSTableRowView by adding custom background drawing.

ATTableCellView.h:
 Extends NSTableCellView primarily for adding outlets to be hooked up in IB.

English.proj:
 Localized NIBs.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

Version 2.0
- General project updates.

Version 3.0
- Updates for Mountain Lion.

===========================================================================
Copyright (C) 2010-2012 Apple Inc. All rights reserved.
