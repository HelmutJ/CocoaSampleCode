Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

Offline						A command-line tool that uses the QCRenderer API to render a Quartz 
						composition offscreen on the video card using an OpenGL pBuffer, 
						download the pixels data, then save the frames to disk as separate 
						compressed TIFF files.

Sample Requirements				The project was created using the Xcode running under Mac OS X 10.6.x 
						or later. 

About the sample				This sample shows how to execute a Quartz Composer composition 
						offline with QCRenderer. This command line program needs two 
						parameters. The first one is the location of the Quartz Composer 
						composition that is to be executed. The second parameter is the 
						location where the generated images are to be saved. To execute a 
						Quartz Composer composition offline, the user needs to initialize a 
						QCRenderer with the composition, and then call the renderAtTime 
						function of the QCRenderer to execute the composition. This program 
						executes the composition 10 times and saves the images into the 
						location indicated by the second parameter.

Using the Sample				Open the project using the Xcode editor which can be found in /
						Developer/Applications. Build the project. Run the program with two 
						parameters, the location of the composition and the location to save 
						the images.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

