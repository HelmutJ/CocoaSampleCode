Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Plugin

SpotlightSearch					A Quartz Composer plug-in that searches for files of a 
						given type matching a Spotlight query. The file type is 
						expressed as Uniform Type Identifier e.g. 
						"public.image".

Sample Requirements				The plugin was created using the Xcode editor running 
						under Mac OS X 10.6.x or later. 

About the sample				An advanced Quartz Composer plug-in that performs a 
						Spotlight search on a background thread for files 
						matching a query and an optional UTI type.

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

						This plug-in requires the file types to be searched and 
						the search query in the input ports. The output port 
						"Searching" returns TRUE if the search is still going 
						on, and returns FALSE when the search is done. A 
						structure of the matched images is returned in the 
						output port "Results".

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport

