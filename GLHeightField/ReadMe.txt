Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Plugin

GLHeightField					A Quartz Composer plug-in that renders a 3D height field 
						from an image.

Sample Requirements				The plugin was created using the Xcode editor running 
						under Mac OS X 10.6.x or later. 

About the sample				An advanced Quartz Composer plug-in that implements a 
						custom consumer patch that renders a 3D height field from 
						an image using OpenGL frame buffer objects (FBO) and 
						vertex buffer objects (VBO).

Using the Sample				Open the project using the Xcode editor which can be found 
						in /Developer/Applications. From the main menu, 
						choose "Project", set "Active Configuration" to "Release", 
						and "Active Target" to "Build & Copy".  These settings are
						also available from the top left corner of the 'Overview' 
						pull-down window. Build the project. Once the build has 
						completed successfully, the plug-in can be used as a 
						regular QC patch in the Quartz Composer editor (also 
						installed under /Developer/Applications), by selecting it 
						from the Library - Plugin panel.

						Connects an image to the plug-in input port "Image", the 
						3D field will be rendered in the Viewer. The user can 
						change the rendering by setting the input parameters 
						"Wireframe Mode" and "Color".

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport
