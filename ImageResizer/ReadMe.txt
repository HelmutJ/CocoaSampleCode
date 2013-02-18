Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

ImageResizer					An application that explains how to use Image Resizer 
						composition from the composition repository to resize an image.

Sample Requirements				The project was created using the Xcode running under 
						Mac OS X 10.6.x or later. The supplied Quartz Composer compositions 
						were created using the Quartz Composer editor running under 
						Mac OS X 10.6.x or later.

About the sample				In the sample, the user can drag an image into the preview 
						window on the right. This preview window is an QCView object. 
						It handles the events such as draggingEntered, DraggingExit, 
						and so on. Once an image is in the QCView, the original image is shown, 
						and the parameters for resizing the image are shown in a 								QCCompositionParameterView window. When the input parameters are 
						changed, a QCRenderer is called to produce the resized image and 
						the image will be updated in the QCView window. The user can also 
						drag the resized image from the preview window to other location 
						to make a copy of the image.

Using the Sample				Open the project using the Xcode editor which can be found in 
						/Developer/Applications. Build the project and run. Drag an image 
						into the preview window, edit the resize parameters and drag the 
						image to other location to make a copy.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

