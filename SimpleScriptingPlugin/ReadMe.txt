File: readme.txt

Abstract: ReadMe.txt for SimpleScriptingPlugin sample code project

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved. 



Introduction

This sample is a follow-on to the SimpleScriptingObjects sample, and it uses many of the techniques from the SimpleScriptingVerbs sample.  After completing the steps defined in the SimpleScriptingObjects sample to set up and create a scriptable application, you can continue with the steps in this sample to add both scripting plugin capabilities to the application and an example scripting plugin.  

The techniques presented here illustrate a number of interesting things you can do with a scripting plugin.  These include:

(a) adding new scripting classes

(b) extending existing scripting classes

(c) adding new scripting commands

Briefly said, once an application is scriptable, allowing for scripting plugins is easy work.  The modifications to the host application are minimal and very generic.  No special code needs to be added to the existing scripting classes to allow for plugins.  And, creating a scripting plugin is no more difficult than adding some additional scripting to the application.  The scripting plugin itself is a simple Cocoa Loadable Bundle that contains one or more .sdef files describing its scripting functionality.  



IMPORTANT - directions for building the two targets

The Xcode project for this sample includes two targets - one for the plugin named ScriptingPlugin and another for host application named SimpleScriptingPlugin.  You can tell Xcode which target to build by either setting the active target in the Project menu, or by control-clicking (right clicking) on the target in the project's window and selecting the build command in the pop-up menu.



IMPORTANT - information for testing

Between tests that involve any change in the scripting definitions for the application - including the addition or removal of a scripting plugin, the Script Editor must be re-launched before it will notice changes in the scripting dictionary.

The following two AppleScript files have been provided for testing:

(a) SimpleScriptingObjectsTest.applescript contains an AppleScript that uses the classes defined in the host application.  It is the same as the test script provided with the original SimpleScriptingObjects sample.

(a) TestAppleScript.applescript contains an AppleScript that uses both the classes in the host application and the features provided by the plugin.




PART ONE
Setting up the host application


Step 1:  Indicate that the application is capable of providing a dynamically generated dictionary.

Add the OSAScriptingDefinition key to the Info.plist file with the string value 'dynamic'.  This tells AppleScript that the dictionary is not stored in a .sdef file in the resource fork and clients can retrieve a copy of a dynamically generated one by way of an Apple event. 

	<key>OSAScriptingDefinition</key>
	<string>dynamic</string>



Step 2:  Add the Apple event handler for providing the dynamically generated dictionary.

Inside of your application delegate's -applicationWillFinishLaunching: method install an Apple event handler for providing your application's scripting dictionary.  In this sample, the following call is used for doing that:

		/* set event handler */
	[[NSAppleEventManager sharedAppleEventManager]
	 setEventHandler:self andSelector:@selector(handleGetSDEFEvent:withReplyEvent:)
	 forEventClass:'ascr' andEventID:'gsdf'];		



Step 3:  Load your plugins.

This step must be preformed before the Apple event handler returns the dynamically generated dictionary.  In this sample, all of the plugins are loaded inside of the application delegate's -applicationWillFinishLaunching: method.

Important points:

(a) Details concerned with how plugins are searched for and located are isolated in the files ApplicationPlugInsFolders.h and ApplicationPlugInsFolders.m.  In that file the following folders are searched:

    applicationBundleDirectory/Contents/PlugIns
    ~/Library/Application Support/applicationSupportDirectory/PlugIns
    /Library/Application Support/applicationSupportDirectory/PlugIns
		 
as suggested in http://developer.apple.com/documentation/Cocoa/Conceptual/LoadingCode/Concepts/Plugins.html. 

IMPORTANT - To simplify testing with this sample, the directory containing the application is also searched for plugins.  Since both the host application and the plugin targets build into the same directory, this arrangement simplifies testing.


(b) In this sample, plugin bundles are identified with the ".simplePlugIn" suffix.



Step 4:  Creating and returning the dynamically generated dictionary.

This is by far the most complex part of this sample and most of the work is done by the NSXMLDocument class inside of the application delegate's -handleGetSDEFEvent:withReplyEvent: method.  This involves combining the application's .sdef file(s) and the plugin's .sdef file(s) into a single NSXMLDocument and returning the result as UTF-8 encoded XML text.  Comments in that method detail the steps involved using those classes.

Important points:

(a) This event handler won't be called until some external client attempts to use, or ask about, your application's scripting capabilities.  This may not be immediately after your application starts.

(b) All plugins containing classes referenced in the dictionary returned by the Apple event handler must have been loaded before the handler returns.

(c) .sdef files are loaded from the Application's resources folder and then from each of the plugin bundle's resources folders.  Both the application and the plugins may have more than one .sdef file in their resources.





PART TWO
Creating a scripting plugin


Step 1:  Setting up the plugin target

In this sample, the plugin was added to the project as a new Cocoa Loadable Bundle target.  In the Packaging section of the build settings, the Wrapper Extension was set to 'simplePlugIn' so the plugin will be found by the host application when it is in one of the application's special plugin directories.

NOTE:  In this sample both the plugin and the host program are part of the same Xcode project.  In other cases, it may be more convenient to organize these into separate Xcode projects.



Step 2:  Add a scripting dictionary to the plugin's resources

In this sample the scripting definitions for the plugin are provided in three scripting suites contained in two separate .sdef files.  These were organized in this way both for clarity and to show that it is not necessary to put all of the definitions together into a single suite or file.

- ScriptingPlugin.sdef contains two scripting suites.  One for class extensions and another for new scripting features provided by the plugin.

- PluginVerbs.sdef contains definitions for some scripting verbs that were copied over from the SimpleScriptingVerbs sample.

When the plugin is loaded, the host application will combine the definitions from both of these files into the dynamically generated dictionary.


Important points:

(a) The plugin's dictionary does not include the standard scripting definitions.  This has already been done in the application, so the definitions in the plugin's dictionary are only concerned with the functionality provided by the plugin.  

(b) Plugins can extend existing classes, add commands, and add objects to the scripting functionality provided by an application.  Plugins add commands and objects using the same techniques detailed in the SimpleScriptingVerbs and SimpleScriptingObjects samples, but extending classes is done using the class-extension element.  

In this sample the class-extension element is used to extend the functionality of the application class and several other classes.  For example,  here is the class-extension element used to extend the functionality of the application class: 


		<class-extension extends="application" description="plugin add-ons to the application class.">

			<cocoa class="NSApplication"/>

			<element type="mattress">
				<cocoa key="mattresses"/>
			</element>

			<property name="valuable" code="TrVa" type="boolean" access="r"
			        description="True if the value to weight ratio of all of the items in the app is better than two to one.  Note: Items hidden in mattresses are not counted."/>
			
			<responds-to name="randomize weight">
                <cocoa method="setRandomWeight:"/>
            </responds-to>
			
            <responds-to name="randomize value">
                <cocoa method="setRandomValue:"/>
            </responds-to>

		</class-extension>


This class extension illustrates how to add a new element type (mattress), property (valuable), and some commands (randomize weight and randomize value) to a class.  The methods implementing the extension are provided in a category of NSApplication in the file PluginAppCategory.h.



Step 3:  Brief roadmap of the plugin in this sample

The host application in this sample provides a number of scripting features and the plugin extends those features in the following ways:


(a) Extending existing classes.
In this sample, class-extension elements are used to extend the host application's application, trinket, treasure, bucket, and strong box classes by adding properties, verbs, and elements to them.  Files implementing the functionality for these extensions include:

	PluginAppCategory.h/m
	TrinketCategory.h/m
	TreasureCategory.h/m
	StrongBoxCategory.h/m
	BucketCategory.h/m

The scripting dictionary items for the class extensions have been organized into a separate suite called "Simple Scripting Plugin Extensions" in the file ScriptingPlugin.sdef.


(b) Adding a new scripting class.
The mattress class is provided by the plugin.  It is a container class that can contain objects defined in the main application's dictionary.  This class is implemented in the files:

	Mattress.h/m 

This class is accessed as an element of the application class.  So, the methods implementing the element accessors are provided in a category of NSApplication in the files:

	PluginAppCategory.h/m

The scripting dictionary items for the new scripting features provided by the plugin have been organized into a separate suite called "Simple Scripting Plugin New Features" in the file ScriptingPlugin.sdef.


(c) Adding some new verbs.
Three of the sample commands provided in the SimpleScriptingVerbs sample have been copied into the plugin directly from the SimpleScriptingVerbs sample without any changes to illustrate that a plugin can provide verbs.  These commands are implemented in the following files:

	SimpleCommand.h/m
	DirectParameterCommand.h/m
	CommandWithArgs.h/m

The scripting dictionary items for the verbs provided by the plugin have been included in a separate suite called "Simple Scripting Plugin Verbs" in the file PluginVerbs.sdef.



Step 4:  Where to next?

Careful planning before you start adding in scripting features will be well worth your while.  So, please consider reading the following documentation.

- The items listed in the section "Making Your Application Scriptable" on this page are essential reading.  Everyone new to scripting should read through these documents and familiarize themselves with the topics discussed.
http://developer.apple.com/referencelibrary/GettingStarted/GS_AppleScript/index.html

- "Designing for Scriptability in Cocoa Scripting Guide provides a high-level checklist of design issues and tactics:
http://developer.apple.com/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/index.html

- This Scripting Interface Guidelines document provides more detailed information you should consider when adding scriptability to your application: 
http://developer.apple.com/technotes/tn2002/tn2106.html

- The AppleScript terminology and Apple Event Codes document provides a listing of four character codes that area already defined for use with specific terms.  As you are adding terminology to your application you should always check there to see if a four character code has already been defined for a term you would like to use AND to make sure a four character code you would like to use is not already being used by some other terminology. 
http://developer.apple.com/releasenotes/AppleScript/ASTerminology_AppleEventCodes/TermsAndCodes.html

- NSScriptCommand class is the one you use for implementing verbs (aka commands) 
http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSScriptCommand_Class/Reference/Reference.html

- The "Support for Class Extension Elements in .sdef-Declared Scriptability" section of:
http://developer.apple.com/iphone/library/releasenotes/Cocoa/Foundation.html



Step 5:  And after that?

This sample is part of a suite of samples structured as an incremental tutorial with concepts illustrated in one sample leading to the next in the order they are listed below.

SimpleScripting
	http://developer.apple.com/samplecode/SimpleScripting/
	
SimpleScriptingProperties
	http://developer.apple.com/samplecode/SimpleScriptingProperties/
	
SimpleScriptingObjects
	http://developer.apple.com/samplecode/SimpleScriptingObjects/
	
SimpleScriptingVerbs
	http://developer.apple.com/samplecode/SimpleScriptingVerbs/

SimpleScriptingPlugin (you are here)
	http://developer.apple.com/samplecode/SimpleScriptingPlugin/




