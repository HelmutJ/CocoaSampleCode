Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

LiveEdit					A simple RTF text editor that shows how to implement 
						live edit using a background Quartz composition with 
						Core Animation and the Composition Repository.

Sample Requirements				The project was created using the Xcode running under 
						Mac OS X 10.6.x or later. 

About the sample				In the sample, the user can live edit the content in 
						the document window. A Quartz Composer QCCompositionPickerPanel 
						is used to provide the compositions that can generate 
						the animation backgrounds for the document. The document 
						window is registered to receive the notification whenever 
						a certain composition in the picker panel is selected. 
						Once a composition is selected, a core animation layer 
						is set up using this composition in the document to 
						generate the animation background.

Using the Sample				Open the project using the Xcode editor which can be 
						found in /Developer/Applications. Build the project and run. 
						Edit the text in the document window. Click in the 
						composition picker to change the background.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

