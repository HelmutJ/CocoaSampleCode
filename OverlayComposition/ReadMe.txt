Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Application

OverlayComposition				A background only application that renders a Quartz 
						Composition in a floating transparent window on top 
						of the desktop, and which only updates at a specified 
						interval.

Sample Requirements				The project was created using the Xcode running under 
						Mac OS X 10.6.x or later. The supplied Quartz Composer 
						compositions were created using the Quartz Composer 
						editor running under Mac OS X 10.6.x or later.

About the sample				This sample shows how to render a composition with 
						QCRenderer in a QCView. At the beginning, the sample 
						renders a default composition. Ctl-click on the 
						window, a pop menu will show, the user can change the 
						composition name, parameters of the composition or the 
						rendering dimensions. The rendering window is a QCView, 
						it receives the mouse events and passes them to the 
						application. The application handles the menu. When the 
						use selects an item from the menu, the application 
						responds accordingly.

Using the Sample				Open the project using the Xcode editor which can be 
						found in /Developer/Applications. Build the project and 
						run. Ctl-click on the window to pop up the menu. Change 
						the parameters to see different results.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

