SBSystemPrefs
=============



ABOUT:

This file details the steps involved in putting together a project that uses Scripting Bridge to send Apple events to the System Preferences application.  The following are the steps used to create this sample.



1. Start with a new Cocoa application.

In this sample we're going to use the System Preferences application so we'll call the sample 'SBSystemPrefs'.  The techniques we are demonstrating in this sample can be used in any Cocoa Application.  We used a simple one window Cocoa application for this sample to keep it simple.   

This project comes with the Interface Builder .nib file and the Controller object to support that already set up.  It is assumed that the reader is familiar with those parts of Cocoa programming so the mechanics of putting those parts together are not discussed in this readme.




2. Add a Scripting Bridge build rule to the project.

The first thing to do is to set up Xcode to automatically generate the Scripting Bridge source for the application you would like to target.  The following steps describe how you can do that:

(a) In the project navigator, choose the project file and select the "SBSystemPrefs" target.   

(b) With the "SBSystemPrefs" target selected, switch to the "Build Rules" tab.

(c) In the build rules tab, click on the + button at the bottom to add a new rule.

(d) Set up the new rule as follows:

	Process 'Source files with names matching:'   *.app
   
	using: 'Custom Script'
   
	set the script field to:
   
	sdef "$INPUT_FILE_PATH" | sdp -fh -o "$DERIVED_FILES_DIR" --basename "$INPUT_FILE_BASE" --bundleid `defaults read "$INPUT_FILE_PATH/Contents/Info" CFBundleIdentifier`

	click on the "+" icon below the 'with output files:' field, and then set the field to contain:
	
	$(DERIVED_FILES_DIR)/$(INPUT_FILE_BASE).h

	NOTE: if you're typing this rule in by hand, note that it should all be one one line, and it must be typed exactly as shown above.  If you have difficulty entering the above command, then copy and paste the command from the readme into the rule.

(e) All done.  Xcode is now set up to automatically generate Scripting Bridge source for any applications you add to your project.

NOTE: this rule uses the sdef and sdp command line tools.  To learn more about these tools, use the following commands in the Terminal window:

   man sdp
   man sdef




3. Select a target application.

To do this, drag and drop the application you would like to target into the project files group inside of the "Groups & Files" list in the project window.  

You can drop the application among the source files you are using for your application.  Because of the build rule we added in step 2, Xcode will treat the System Preferences application as if it were one of the source files during the build.  

You should uncheck the 'Copy items into destination group's folder (if needed)' option so the application is not copied into your project directory.  In this sample we have selected 'Absolute Path' as the reference type so we can easily move the project around from machine to machine without invalidating the reference (so long as the System Preferences application is present in the System/Library/CoreServices folder,  Xcode will be able to find it).

In this case, we are adding the System Preferences to our project.  The System Preferences application is located in the /Applications folder.




4. Add the target application to the Compile Sources.

After you have added the target application to your project, you must also add it to the main target's Compile Sources.  You can do that by adding the application to the 'Compile Sources' build phase under the main target.




5. Add the Scripting Bridge framework to your project.

In the Build Phases of the main target, expand the group titled "Link With Libraries".  Click the + button and select the ScriptingBridge.framework and click the Add button.




6. Add a minimum system version Info.plist key.

Since the ScriptingBridge.framework is necessary for this application to run and that framework is not present on previous system versions, you should add the following key/value pair to the Info.plist file for the application.  If someone tries to run this application on a system earlier than Mac OS X 10.5, then they will receive a notice from launch services letting them know that the application is meant to be run on a later version of Mac OS X.

	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>



7. Build the project.

If you have followed the steps above, Xcode will generate the Scripting Bridge source for your project.  They will be put inside of your build folder in a place where the linker and compiler can find them.  

The build rule that we installed will create a .h file with the same name as the application.  For example, if you added System Preferences to our project, then the build rule will create System Preferences.h.  The files will be created inside of the build directory in the DerivedSources directory where the compiler can find them.

For the Debug build, the System Preferences.h file will be located in this sub folder of the build directory:
/build/Intermediates/SBSystemPrefs.build/Debug/SBSystemPrefs.build/DerivedSources/System Preferences.h

For the Release build, the System Preferences.h file will be located in this sub folder of the build directory:
/build/Intermediates/SBSystemPrefs.build/Release/SBSystemPrefs.build/DerivedSources/System Preferences.h

A convenient way for you to open and inspect these files is to use the 'Open Quickly' command in the file menu.  For most purposes, the .h file will contain most of the interesting information so to view that file you open the 'System Preferences.h' file.  

In some cases, depending on what frameworks are in your project, the 'Open Quickly' command may open the system's 'System Preferences.h' file that includes constants and definitions used by the file system and the System Preferences application.  If that happens for you, then you will need to navigate into the build folder to find the correct header file.




8. Add in the System Preferences's Scripting Bridge header.

In the file Controller.m, we have added the import statement '#import "System Preferences.h"' (note the space in the include file name).  This will include all of the Scripting Bridge definitions for accessing the System Preferences application with Scripting Bridge.

Here is the imports section in our Controller.m file:

	#import "Controller.h"
	#import "System Preferences.h"

In your own application, of course, you would import the System Preferences.h file in the file where you intend to call it from.  In this sample, we are using the Scripting Bridge interface inside of three methods in our Controller class so that is why we are importing it into Controller.m.




9. Code for displaying a specific preference pane

So far, the preceding steps have described how to set up a project to use Scripting Bridge to target the System Preferences application.   In this section, we'll talk about the code in the -displaySpecificPane: method of the Controller class.

Here is the method itself:


- (IBAction)displayUniversalAccess:(id)sender {
		
		/* allocate a System Preferences Scripting Bridge object */
	SystemPreferencesApplication *systemPreferences =
		[SBApplication
			applicationWithBundleIdentifier:@"com.apple.systempreferences"];
	
        /* set ourself as the delegate to receive any errors */
    systemPreferences.delegate = self;

		/* bring the System Preferences in front */
	[systemPreferences activate];

		/* display the Universal Access pane */
	systemPreferences.currentPane = (SystemPreferencesPane *)
		[[systemPreferences panes] objectWithID:@"com.apple.preference.universalaccess"];
}


In this method, we create the Scripting Bridge object, activate the System Preferences application, and set the current pane to the Universal Access pane using it's unique id value. 

Note that when selecting the Universal Access pane, the ID property is used rather than the name.  This is the preferred method for referencing a preference pane as it will work across different localizations when the user has chosen a different language.




10. code for allowing selection from a list

The following method is called in response to a click on the "Choose from List..." button:

- (IBAction)selectPaneForDisplay:(id)sender {
	
		/* allocate a System Preferences Scripting Bridge object */
	SystemPreferencesApplication *systemPreferences =
		[SBApplication
			applicationWithBundleIdentifier:@"com.apple.systempreferences"];

        /* set ourself as the delegate to receive any errors */
    systemPreferences.delegate = self;
	
        /* add all of the preference panes to the list */
    NSArray *listOfPreferencePanes = [systemPreferences panes];

        /* If an error ocurred, eventDidFail: already displayed the error so exit gracefully  */
    if(!listOfPreferencePanes)
        return;

        /* set the array.  The array controller takes care of the display */
    self.prefPanes = [NSMutableArray arrayWithArray:listOfPreferencePanes];

		/* display the window */
	[self.selectionWindow makeKeyAndOrderFront:self];
	
		/* interact until a selection is made or the user cancels. */
	NSInteger modalResult = [NSApp runModalForWindow:self.selectionWindow];
	
		/* hide the window */
	[self.selectionWindow orderOut:self];
	
		/* if a row was selected, display the selected pane */
	if ( NSNotFound != modalResult ) {
		
		/* retrieve the selected one. */
		SystemPreferencesPane *selectedPane =
		(SystemPreferencesPane *) [[prefPanesController arrangedObjects]
								   objectAtIndex: modalResult];
		
		/* bring the System Preferences app in front */
		[systemPreferences activate];
		
		/* ask the System Preferences to display the pane.  */
		systemPreferences.currentPane = selectedPane;
	}
	
		/* reset the array (releases the array of SystemPreferencesPanes
		managed by the array controller) */
	self.prefPanes = nil;
	
}



Important aspects of this call include:

(a) We store an array of SystemPreferencesPane objects in the prefPanes instance variable and Cocoa bindings set up in the .nib file take care of displaying the items in the table in the window.  It's worth noting that in the binding between the table column and the array controller, we have chosen to display the localizedName property of the SystemPreferencesPane object.  This will ensure proper names being displayed across different localizations.

(b) If a preference pane has been selected, then the selected SystemPreferencesPane Scripting Bridge object is retrieved from the array controller, the system preferences application is brought to the front, and then the current pane is set to the selected item.  Note that the array controller is linked to the prefPanes array that we populated earlier in the method.  By using arrangedObjects we are able to retrieve the item selected in the GUI without having to worry about the order they are being displayed in the list (which, more than likely, will not be the same as the order they appear in the prefPanes array).




11. Where to next?

Documentation for Scripting Bridge can be found in the Scripting Bridge Release Note at this address:

    http://developer.apple.com/releasenotes/ScriptingAutomation/RN-ScriptingBridge/index.html

There are man pages available for the Scripting Bridge command line tools.  To access those pages, enter the following commands into the Terminal window:

   man sdp
   man sdef

There are some other Scripting Bridge samples available including SBSendEmail, SBSetFinderComment, ScriptingBridgeiCal and ScriptingBridgeFinder showing how to use Scripting Bridge together with the Apps named in their titles.


===========================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later.

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Updated setup instructions in the ReadMe.
- Project updated for Xcode 4.
Version 1.0
- Initial Version

===========================================================================
Copyright (C) 2007-2011 Apple Inc. All rights reserved.