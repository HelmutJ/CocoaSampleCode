SimpleScripting
===============

ABOUT:

This sample illustrates the initial steps required to make an application scriptable.  Other samples in the SimpleScripting* series build on top of this sample to show how to add additional scripting functionality.


Step 1:  Setting up

Create a new .sdef file that includes the standard scripting suite and add it to your Xcode project.  Usually, this file will have the same name as your application.  Going along with that convention, the .sdef file in this sample has been named "SimpleScripting.sdef".  In the contents of that file, enter an empty dictionary that includes the standard AppleScript suite as follows:


<dictionary xmlns:xi="http://www.w3.org/2003/XInclude">

    <xi:include href="file:///System/Library/ScriptingDefinitions/CocoaStandard.sdef" xpointer="xpointer(/dictionary/suite)"/>

        <!-- add your own suite definitions here -->

</dictionary>


The important parts of this definition are as follows:

1. The 'xi' namespace declaration in the opening dictionary element declares that enclosed elements using the 'xi' namespace will follow conventions defined by the XInclude standard.  This will allow us to include the standard definitions.

2. The 'xi:include' element includes the Standard Suite in the .sdef.

NOTE: Prior to Mac OS X 10.5 developers would copy the standard suite from the ScriptingDefinitions sample (http://developer.apple.com/samplecode/ScriptingDefinitions/index.html) directly into their .sdef file.  For backwards compatibility with Mac OS X 10.4, you may continue to use that technique, but moving forward the XInclude technique described above is recommended.




Step 2: Advertise your scriptability

Add these two entries to your application's Info.plist file:

    <key>NSAppleScriptEnabled</key>
    <string>YES</string>
    
    <key>OSAScriptingDefinition</key>
    <string>Simple.sdef</string>

The first marks your application as one that supports scripting, the second lets the system know where to look for your application's scripting definition file.  You should use the file name you used in step 1.

http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_evolution/SAppsEvolution.html




Step 3: Start editing your Scripting Definition (.sdef) file

In Xcode, select your .sdef file and select "File > Open As... > Plain Text File", and edit the file to include definitions for your own application.


IMPORTANT:  You can use the Script Editor application to view your application's dictionary in a dictionary viewer and to write test scripts. Whenever you make changes to your .sdef file you will have to quit and run Script Editor again for it to see the changes, because it  caches dictionaries while it is running.




Step 4: Add a starting suite

Add a new suite to your .sdef file at the end of the dictionary just before the closing </dictionary> tag:


	<suite name="Simple Scripting Suite" code="SScr"
		<!-- put your application specific scripting suite information here -->
		 
	</suite>

It is inside of this suite definition where you will put your application specific scripting information.  You can add additional suites if you like and use them to group related scripting functionality together, but for most purposes one should be sufficient.




Step 5: Add an application class to your new script suite.

Here is our new suite with the application class added in:

	<suite name="Simple Scripting Suite" code="SScr"
		description="SimpleScripting application specific scripting facilities.">
		
		<!-- put your application specific scripting suite information here -->
		
		<class name="application" code="capp" 
					description="Our simple application class." inherits="application">
					
			<cocoa class="NSApplication"/>
			
			<property name="ready" code="Srdy" type="boolean" access="r"
			        description="we're always ready"/>
				
		</class>

	</suite>

Note, the application class we have added inherits from the application class defined in the Standard Suite in Skeleton.sdef.  Also, to get started we have added a single property to our specialized application class named 'ready'.  Note that I have defined this property as 'read only' by specifying an access attribute of "r".

The application class is the root container class for an AppleScriptable application.  All of the root functionality provided by your application will be contained in this class and the other classes and objects that it contains.

Important points to note of here:
  - the suite has a unique four-character code associated with it 'SScr'. 
  - the 'ready' property has a unique code associated with it.  When picking that code, I first consulted the AppleScript Terminology and Apple Event Codes table here:
  http://developer.apple.com/releasenotes/AppleScript/ASTerminology_AppleEventCodes/TermsAndCodes.html
  
  to see if 'ready' was already associated with a four letter code.  If it was I would have used that code, but I didn't find the word 'ready' listed there so I made up a four-character code for it.  And, of course, I double checked it against the codes in the Apple Event Codes table to make sure I wasn't swiping a code that was already in being used for another term).




Step 6: Add a category to the NSApplication class.

Add the files SimpleApplication.h and SimpleApplication.m to your project and add a definition for a category of NSApplication to them that implements the 'ready' property accessor.


in SimpleApplication.h:

	#import <Cocoa/Cocoa.h>
	
	@interface NSApplication (SimpleApplication)
	
	- (NSNumber*) ready;
	
	@end


and in SimpleApplication.m:


	#import "SimpleApplication.h"
	
	@implementation NSApplication (SimpleApplication)
	
	- (NSNumber*) ready {
		return [NSNumber numberWithBool:YES];
	}
	
	@end
	
Since we specified the 'ready' property as read only, we only need to provide an accessor for reading its value.  There's no point in implementing a setter method function as it's a read only property.




Step 7:  The big test

Build and run your application.  Then, run the following script in the Script Editor:

tell application "SimpleScripting"
	properties
end tell

It should report the following result showing the 'ready' property:

{name:"SimpleScripting", frontmost:false, version:"0", class:application, ready:true}

If you've gotten this far, then congratulations you have made your first scriptable application.




Step 8:  One last thing...

As you begin to add scripting to your application you will more than likely want to debug it and see what's going on.  But, in doing that you will be confronted with the fact that the way scripting operates, using a debugger isn't always the most convenient way to figure out what's going on.  While processing a script your application is likely to receive many callbacks (hundreds in many cases) and what you need to do is track those callbacks to discover what is going on.  So, what do you do?  Well, we recommend that you add logging statements to the methods implementing your scripting callbacks.  In this step we'll add a new file to the project called scriptLog.h containing the following definitions:


	#define	scriptLoggingMasterSwitch	( 1 )
	
	#if scriptLoggingMasterSwitch
	#define SLOG(format,...) NSLog( @"SLOG: File=%s line=%d proc=%s " format, strrchr("/" __FILE__,'/')+1, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__ )
	#else
	#define SLOG(format,...)
	#endif

And then we'll modify SimpleApplication.m so it contains:

	#import "SimpleApplication.h"
	#import "scriptLog.h"
	
	@implementation NSApplication (SimpleApplication)
	
	- (NSNumber*) ready {
	    SLOG(@"Here we are!");
		return [NSNumber numberWithBool:YES];
	}
	
	@end

Now, if we add in those changes, build and run the result, and run the same test script from before,  we'll find the following entry in our application's run log:


2007-02-21 17:36:56.913 SimpleScripting[4905] SLOG: File=SimpleApplication.m line=15 proc=-[NSApplication(SimpleApplication) ready] Here we are!

It shows the file name, line number, method name and the string we provided.  Later as we add additional scripting functionality we'll find these log messages valuable for tracking what's going on with our scripting.



Step 9:  Where to next?

Well, now that you have the very basics in hand, you're all ready to start adding scriptability to your application.  But, careful planning before you start adding in scripting features will be well worth your while.  So, please consider reading the following documentation.

- The items listed in the section "Implementing a Scriptable Application" on this page are essential reading.  Everyone new to scripting should read through these documents and familiarize themselves with the topics discussed.
http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_implement/SAppsImplement.html

- "Designing for Scriptability in Cocoa Scripting Guide provides a high-level checklist of design issues and tactics:
http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_design_apps/SAppsDesignApp.htmlE

- This Scripting Interface Guidelines document provides more detailed information you should consider when adding scriptability to your application: 
http://developer.apple.com/technotes/tn2002/tn2106.html

- The AppleScript terminology and Apple Event Codes document provides a listing of four character codes that area already defined for use with specific terms.  As you are adding terminology to your application you should always check there to see if a four character code has already been defined for a term you would like to use AND to make sure a four character code you would like to use is not already being used by some other terminology. 
http://developer.apple.com/releasenotes/AppleScript/ASTerminology_AppleEventCodes/TermsAndCodes.html

- NSScriptCommand class is the one you use for implementing verbs (aka commands) 
http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSScriptCommand_Class/Reference/Reference.html



Step 10:  And after that?

This sample is part of a suite of samples is structured as an incremental tutorial with concepts illustrated in one sample leading to the next in the order they are listed below.

SimpleScripting (you are here)
	http://developer.apple.com/samplecode/SimpleScripting/
	
SimpleScriptingProperties
	http://developer.apple.com/samplecode/SimpleScriptingProperties/
	
SimpleScriptingObjects
	http://developer.apple.com/samplecode/SimpleScriptingObjects/
	
SimpleScriptingVerbs
	http://developer.apple.com/samplecode/SimpleScriptingVerbs/


===========================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later.

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Project updated for Xcode 4.
Version 1.0
- Initial Version

===========================================================================
Copyright (C) 2008-2011 Apple Inc. All rights reserved.