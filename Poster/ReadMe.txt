Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

Poster						Shows how to tile the rendering of a QCRenderer's composition 
						by modifying appropriately the OpenGL projection matrix. Here
						"poster" means an image that could be larger than the GPU can
						supports. In this case, the GPU generates the image part by
						part. It generates one part of the image at each time and 
						copies the result to the corresponding part of the image. 

Sample Requirements				The project was created using the Xcode running under Mac OS X 
						10.6.x or later. 

About the sample				This sample uses a QCRenderer to render a Quartz Composer 
						composition in the view window. The user needs to select a 
						composition by clicking on the "Select Composition" button. 
						When the "Export Poster…" button is clicked, the sample sets up 
						the OpenGL context, creates a pixel buffer as the rendering 
						target and renders the composition. The contents in the pixel 
						buffer is then copied to the file tile by tile.

Using the Sample				Open the project using the Xcode editor which can be found in 
						/Developer/Applications. Build the project and run.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

