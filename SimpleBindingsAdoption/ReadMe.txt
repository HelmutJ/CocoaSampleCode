Simple Bindings Adoption
------------------------

This simple example illustrates the adoption of Cocoa Bindings to manage synchronization of values between models and views.

The example is a simple document-based application.  Each document has a window with a text field, slider, and button.  The values of the text field and slider represent the volume in a Track object managed by the document.  The Mute button sets the volume to zero.

There are three versions of the application:

1. Using target-action to update the track's volume when the user presses Enter in the text field or moves the slider.  The user interface is updated programmatically.

2. Programmatically: creating an object controller; binding its content to the track object; and binding the values of the text field and slider to the track's volume.  The user interface is updated using bindings.

3. In Interface Builder: creating an object controller; binding its content to the track object; and binding the values of the text field and slider to the track's volume.  The user interface is updated using bindings.

