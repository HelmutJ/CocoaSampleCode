BindingsJoystick
================

This sample contains a "joystick" view that shows how you can implement a bindings-enabled subclass of NSView.

In addition to supporting basic binding for a sigle value, it responds properly to multiple selection markers. It is discussed in greater detail in "Cocoa Bindings Programming Topics > How Do Bindings Work?" (http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaBindings/Concepts/HowDoBindingsWork.html).



User Interface
--------------
The user interface is contained in MainMenu.xib.
The main objects instantiated in the nib file are:
* A window that contains
  - A table view to display Position objects.
  - A Joystick view.
  - Text fields to display and edit angle and offset values of the currently-selected Position object.
* An instance of AppController to manage the view and a collection of Position objects.
* An array controller for the App Controller's Position objects.


Classes
-------
The classes used in the sample are as follows:

AppController:
A simple controller object that manages a collection of Position objects containing offset and angle values. It is also responsible for establishing the bindings from the joystick view to the array controller.

JoystickView:
The main focus of the sample: A view that displays the angle and offset of an object, and allows those values to be edited graphically. These features also support bindings.

Position:
A trivial model class to encapsulate an angle and an offset. 