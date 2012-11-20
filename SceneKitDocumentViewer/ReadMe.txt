### Scene Kit Document Viewer ###

===========================================================================
DESCRIPTION:

Demonstrates how to use Scene Kit to load and play a 3D scene with animations. It also shows how to pick objects and highlight their materials.

===========================================================================
PACKAGING LIST:

ASCAppDelegate.h/m
This is the main controller for the application and handles the setup of the view and the loading of an initial scene. An instance of this class resides in MainMenu.xib and uses an IBOutlet reference for the view (which has been wired up through Interface Builder).

ASCView.h/m
A subclass of SCNView on which the user can drop .dae files. It handles mouse events to pick 3D objects and highlight their materials.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
