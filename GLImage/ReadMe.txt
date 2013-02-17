Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Plugin

GLImage						A Quartz Composer plug-in that produces an image of a 
						given size containing a diagonal color gradient.

Sample Requirements				The plugin was created using the Xcode editor running 
						under Mac OS X 10.6.x or later. 

About the sample				A Quartz Composer plug-in that implements a custom 
						processor patch that produces an image of an 
						arbitrary size containing a color gradient and 
						rendered using OpenGL.

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

						The size for the output image is set in the plug-in 
						input parameters "Image Pixels Height" and "Image 
						Pixels Width".  By changing the input parameters 
						"Bottom Color" and "Top Color", the output image 
						gradient is changed.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport
