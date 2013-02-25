Introduction:

This sample code demonstrates how to load, compile, and link GLSL fragment and vertex shaders from within a simple Cocoa application.  

The Fragment and vertex shaders have c like syntax and reside in the files with ".vs" and ".fs" extensions respectively, inside the main application bundle.  They're loaded, compiled, linked and bound to a program object using OpenGL APIs and instantiated through the Shader class. The shader class here does not validate the program object.

This project further contains a simple class for displaying strings in an OpenGL view using GLUT's built-in bitmap fonts.

This application further demonstrates a simple timer based OpenGL animation from within a Cocoa application.  

It is also worth noting that the Tranguloid Trefoil geometry here is a parametric surface, created using a display list.

Mouse support:

¥ For zooming the object, hold the right-mouse down and move mouse up or down.
¥ For updating the pitch, hold the left-mouse key down and change the angle. 

Revision History:

¥ Refactored the sample code to better demonstrate the interaction of OpenGL APIs with an OpenGL view.
¥ Moved the GLSL program object instantiation into its own basic class.
¥ Moved the GLSL hardware check code into its a separate file.
¥ Consistent use of  float math library functions for pattern and palette generation.
¥ Animation continues during window resizing.
¥ Consistent use of doubles and their OpenGL equivalents during geometry generation. 
¥ Updated the Xcode project to use the new format.
¥ Updated the NIB to use the new format.
¥ Added a simple GLUT string class.