SimpleScriptingVerbs
====================

FORWARD:

This sample is a follow-on to the SimpleScripting sample. It shows how to add verbs to the terminology provided by a scriptable application. (A verb is a command or action that can be invoked in a script.)


INSTRUCTIONS:

Step 1:  Setting up

Create a new .sdef file that includes the standard scripting suite and add it to your Xcode project.  Usually, this file will have the same name as your application.  Going along with that convention, the .sdef file in this sample has been named "SimpleScriptingVerbs.sdef".  In the contents of that file, enter an empty dictionary that includes the standard AppleScript suite as follows:


<dictionary xmlns:xi="http://www.w3.org/2003/XInclude">

    <xi:include href="file:///System/Library/ScriptingDefinitions/CocoaStandard.sdef" xpointer="xpointer(/dictionary/suite)"/>

        <!-- add your own suite definitions here -->

</dictionary>


The important parts of this definition are as follows:

1. The 'xi' namespace declaration in the opening dictionary element declares that enclosed elements using the 'xi' namespace will follow conventions defined by the XInclude standard.  This will allow us to include the standard definitions.

2. The 'xi:include' element includes the Standard Suite in the .sdef.

NOTE: Prior to Mac OS X 10.5 developers would copy the standard suite from the ScriptingDefinitions sample (http://developer.apple.com/samplecode/ScriptingDefinitions/index.html) directly into their .sdef file.  For backwards compatibility with Mac OS X 10.4, you may continue to use that technique, but moving forward the XInclude technique described above is recommended.




Step 2: Add a starting suite

Add a new suite to your .sdef file at the end of the dictionary just before the closing </dictionary> tag:


	<suite name="Simple Scripting Verbs" code="SVrb" description="Terminology for the SimpleScriptingVerbs Sample.">
	
		<!-- We'll put our verb definitions here -->
		 
	</suite>

It is inside of this suite definition where you will put your application specific scripting information.  You can add additional suites if you like and use them to group related scripting functionality, but for most purposes one suite should be sufficient.

Important points to note here:
  - the suite has a unique four-character code associated with it 'SVrb' that uniquely identifies our suite.  We will used that four letter code when putting together eight character code identifiers for our scripting commands (verbs).




Step 3: Add some verbs to the script suite.

These are the verbs we have added to this example:



(a) the 'do simple command' verb.

		<command name="do simple command" code="SVrbSimp" description="run a simple command with no parameters">
			<cocoa class="SimpleCommand"/>
			<result type="integer" description="returns the number seven"/>
		</command>

This is a simple verb with no parameters.  It returns an integer number.  Verbs don't get much simpler than this.

Important points to note here:

  - Note the code value has eight characters in it.  This is actually two four character codes combined together.  The first four characters will be the 'event class' in the in the Apple event sent to your application for this command.  And the last four letters will be the 'event code' in the Apple event sent for the command.
    
  - the Cocoa class that implements the command is identified by the "<cocoa class="SimpleCommand"/>" element in the xml.  Here we identify the 'SimpleCommand' class that is implemented in the files SimpleCommand.h and SimpleCommand.m.  When Cocoa receives this command it will instantiate an instance of the class SimpleCommand and then it will call the -performDefaultImplementation method on that instance.  You put your code for performing the command in the performDefaultImplementation method of that class.



(b) the 'do direct parameter command' verb.

		<command name="do direct parameter command" code="SVrbDpCm" description="run a simple command with a direct parameter">
			<cocoa class="DirectParameterCommand"/>
			<direct-parameter description="a text parameter passed to the command">
				<type type="text"/>
			</direct-parameter>
			<result type="text" description="the direct parameter enclosed in quotes"/>
		</command>

This is a simple verb that receives a single string parameter and returns a string value (a copy of the parameter enclosed in quotes).  

Important points to note here:

  - Note the code value has eight characters in it.  This is actually two four character codes combined together.  The first four characters will be the 'event class' in the in the Apple event sent to your application for this command.  And the last four letters will be the 'event code' in the Apple event sent for the command.  Here we have used the Suite's four letter code as the event class and then we have used a unique four letter code as the event code.
    
  - the Cocoa class that implements the command is identified by the "<cocoa class="DirectParameterCommand"/>" element in the xml.  Here we identify the 'DirectParameterCommand' class that is implemented in the files DirectParameterCommand.h and DirectParameterCommand.m.  When Cocoa receives this command it will instantiate an instance of the class DirectParameterCommand and then it will call the -performDefaultImplementation method on that instance.  You put your code for performing the command in the performDefaultImplementation method of that class.

  - inside of your performDefaultImplementation method you can access the direct parameter by calling the [self directParameter].    
  
  

(c) the 'do command with args' verb.

		<command name="do command with args" code="SVrbAgCm" description="run a command with a bunch of arguments">
			<cocoa class="CommandWithArgs"/>
			
			<direct-parameter description="a text parameter passed to the command">
				<type type="text"/>
			</direct-parameter>
			
			<parameter name="blinking" code="savo" type="boolean" optional="yes" 
				description="a boolean parameter.">
				<cocoa key="SaveOptions"/>
			</parameter>
			
			<parameter name="preferred hand" code="LRnd" type="preferredhands" optional="yes" 
				description="a parameter using our enumeration.">
				<cocoa key="TheHand"/>
			</parameter>
			
			<parameter name="prose" code="Pros" type="text" optional="yes" 
				description="a text parameter.">
				<cocoa key="ProseText"/>
			</parameter>
			
			<parameter name="ivalue" code="iVal" type="integer" optional="yes" 
				description="an integer parameter.">
				<cocoa key="IntegerValue"/>
			</parameter>
			
			<parameter name="rvalue" code="rVal" type="real" optional="yes" 
				description="an real number parameter.">
				<cocoa key="RealValue"/>
			</parameter>
			
			<result type="text" description="the direct parameter enclosed in quotes"/>
		</command>

This is a verb that receives a number of arguments and returns a string value (either a copy of the prose parameter enclosed in quotes or, if the prose parameter is not provided, a copy of the direct parameter enclosed in quotes).  

Important points to note here:

  - Note the code value has eight characters in it.  This is actually two four character codes combined together.  The first four characters will be the 'event class' in the in the Apple event sent to your application for this command.  And the last four letters will be the 'event code' in the Apple event sent for the command.  Here we have used the Suit's four letter code as the event class and then we have used a unique four letter code as the event code.
    
  - the Cocoa class that implements the command is identified by the "<cocoa class="CommandWithArgs"/>" element in the xml.  Here we identify the 'CommandWithArgs' class that is implemented in the files CommandWithArgs.h and CommandWithArgs.m.  When Cocoa receives this command it will instantiate an instance of the class CommandWithArgs and then it will call the -performDefaultImplementation method on that instance.  You put your code for performing the command in the performDefaultImplementation method of that class.

  - each parameter has a cocoa key associated with it.  For example, the 'rvalue' command has a cocoa key of 'RealValue' associated with it.  Inside of your performDefaultImplementation method you can retrieve all of the arguments by calling [self evaluatedArguments].   The evaluatedArguments method will return a NSDictionary with each of the arguments associated with their respective Cocoa key.  For example, inside of the performDefaultImplementation method, you could call [[self evaluatedArguments] objectForKey:@"RealValue"] to retrieve the value of the 'rvalue' parameter.  Of course, if a parameter has been marked as optional and the user has not provided that parameter, then there will be no entry in the NSDictionary for its cocoa key.

  - the 'preferred hand' parameter illustrates how you can use an AppleScript enumeration as a parameter.  For more information about using enumerations, see the SimpleScriptingProperties example.
  
  - even though we have provided a number of parameter definitions, verbs will always receive a direct parameter.  Inside of your performDefaultImplementation method you can access this value by calling [self directParameter].
 



Step 4:  Where to next?

Well, now that you have the very basics in hand, you're ready to start adding scriptability to your application.  But, careful planning before you start adding in scripting features will be well worth your while.  So, please consider reading the following documentation.

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




Step 5:  And after that?

This sample is part of a suite of samples is structured as an incremental tutorial with concepts illustrated in one sample leading to the next in the order they are listed below.  If you have not visited any of the preceding samples, then please refer to those for additional information.

SimpleScripting
	http://developer.apple.com/samplecode/SimpleScripting/
	
SimpleScriptingProperties
	http://developer.apple.com/samplecode/SimpleScriptingProperties/
	
SimpleScriptingObjects
	http://developer.apple.com/samplecode/SimpleScriptingObjects/
	
SimpleScriptingVerbs (you are here)
	http://developer.apple.com/samplecode/SimpleScriptingVerbs/




===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6 Snow Leopard or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Project updated for Xcode 4.
Version 1.1
- Changed the .sdef so that it uses XInclude to import the Standard Suite from another file instead of providing a definition of the Standard Suite in the .sdef file.
Version 1.0
- First version.

===========================================================================
Copyright (C) 2008-2011 Apple Inc. All rights reserved.