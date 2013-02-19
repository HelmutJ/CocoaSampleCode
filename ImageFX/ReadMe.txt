Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

ImageFX						An application that explains how to use Quartz Composer 
						QCView and QCCompositionPickerView to render image with 
						special effects provided by Quartz Composer Image Filters.

Sample Requirements				The project was created using the Xcode running under 
						Mac OS X 10.6.x or later.

About the sample				In the sample, the user can drag an image into the 
						rendering window on the right. This rendering window is 
						an QCView object. It handles the events such as 
						draggingEntered, DraggingExit, and so on. When an image 
						is dragged into the QCView, an image filter selected 
						from the QCCompositionPickerView on the top left is 
						applied to render the image with special effects. The 
						QCCompositionPickerView is initialized with image 
						filters. When the user selects a filter from the picker 
						view, a large preview image of that effect will be 
						shown in the QCView window. The user is allowed to 
						change the input parameters for the selected image 
						filter. The image in the QCView can also be dragged 
						outside of the application window to make a copy of the 
						image.

Using the Sample				Open the project using the Xcode editor which can be 
						found in /Developer/Applications. Build the project and 
						run. Drag an image to the preview window, select the 
						image filter from the picker panel and change the 
						filter parameters.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

