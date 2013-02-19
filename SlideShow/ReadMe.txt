Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

SlideShow					A slide show application based on the QCRenderer API 
						that uses a custom composition or a composition from 
						the Composition Repository to render the transitions.

Sample Requirements				The project was created using the Xcode running under 
						Mac OS X 10.6.x or later. The supplied Quartz Composer 
						compositions were created using the Quartz Composer 
						editor running under Mac OS X 10.6.x or later.

About the sample				This sample asks the user to choose a directory that 
						contains images. All the images that conform to the 
						NSImage types will be slide shown in full screen. The 
						sample selects a transition composition randomly each 
						time the application is run. The transition between 
						one image and the next is implemented with a 
						QCRenderer containing the transition composition. Any 
						files that are not images or the image files do not 
						conform to the NSImage types will be ignored.

Using the Sample				Open the project using the Xcode editor which can be 
						found in /Developer/Applications. Build the project 
						and run.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

