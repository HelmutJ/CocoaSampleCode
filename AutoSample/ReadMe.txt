AutoSample
==========


ABOUT:

This file discusses using the AMWorkflowView and AMWorkflowController classes to display and execute Automator Workflows, and describes the parts of the project necessary to support the use of these classes.


The following four items are necessary for any project using the Automator framework:




1. Add the Automator framework to your project.

Select your project in the project navigator and choose the "AutoSample" target.  Under the "Build Phases" tab, expand the group titles "Link Binary With Libraries" and click the + button.  Then, add the "Automator.framework" to the project.  




2. Add a minimum system version Info.plist key.

Since the Automator.framework is necessary for this application to run and that framework is not present on previous system versions, you should add the following key/value pair to the Info.plist file for the application.  If someone tries to run this application on a system earlier than Mac OS X version 10.5, then they will receive a notice from launch services letting them know that the application is meant to be run on a later version of Mac OS X.

	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>

You can edit the Info.plist file by either clicking on its icon in the resources section of the project navigator.




3. Add in the Automator framework header.

In the files where you will be using the Automator classes, add the import statement '#import <Automator/Automator.h>' near the top of the file.  This will include all of the definitions for using the Automator framework.

Here is the import statement for the Automator framework headers:

	#import <Automator/Automator.h>





The remainder of this read me file discusses items specific to this sample.




Overview

This sample displays a single window containing a list of workflows and a read only AMWorkflowView.  The workflows listed are the ones found in the Application's resources in the folder:

	/AutoSample.app/Contents/Resources/workflows/

When the application starts up it scans the workflows folder and loads each Automator workflow found there as an instance of AMWorkflow.  It then stores these AMWorkflow instances in an array along with the file names.  That array is used as the backing store for the NSTableView in the window.  

When a click is received on the name of a workflow in the NSTableView, the workflow is displayed in the AMWorkflowView on the right hand side of the window.

When a double-click is received on the name of a workflow in the NSTableView (or, when the "run" button is pressed), the selected workflow is displayed in the AMWorkflowView on the right hand side of the window and it is run.




Initialization Details

All of the setup for this sample is performed in the -awakeFromNib method.  The important features to note there are as follows:


(a) The AMWorkflowView is being used for display purposes only.  As such, we mark the view as read only by turning off it's editing features with the following method call:

   [workflowView setEditable: NO];


(b) We don't actually manage the AMWorkflowView ourselves.  Rather, we use an AMWorkflowController to take care of that.  In this sample, we have added an AMWorkflowController to our .nib file and we have set the AMWorkflowView displayed in the main window as it's workFlowView.  

With this arrangement, our Controller object does not have to worry about the details of operating the AMWorkflowView's user interface, as the AMWorkflowController will take care of that. 

So methods in the Controller object can receive information about the status of the view we have set our Controller object as the AMWorkflowController's delegate.  With our controller object set as the AMWorkflowController delegate, the AMWorkflowController will call back to our Controller object to provide status information about the AMWorkflow it is displaying in the AMWorkflowView.

To run and display specific AMWorkflows, we will want to call methods on the AMWorkflowController.  So we can do that from methods implemented in the Controller object,  we have added an instance variable to the Controller object where we store a reference to the AMWorkflowController object.

All of these relationships have been set up by control-dragging between objects in the Interface Builder interface.  You can use the connections inspector in Interface Builder to examine these connections.


(c) We allocate and initialize all of the AMWorkflow instances for the workflows found in our Resources folder and we store them in a NSArray.  It's worth noting that we populate the NSArray with NSDictionary records that include the AMWorkflow instance, the file name, and the path.


(d) we have set up an array controller to manage the contents of the NSTableView.  To do that, we have bound the content array of the array controller to the workflows value stored in our Controller object.  In the column of the table we have bound the value to the arrangedObjects controller key on the Array Controller.  Back in our controller object, we have stored a reference to the Array Controller in the tableContent outlet so we can access its arrangedObjects value (to allow us to access the values displayed in the table no matter how the user has sorted the list by clicking on the table header). 



AMWorkflowController delegate methods

We implement two AMWorkflowController delegate methods in this sample.  Namely, workflowControllerWillRun: and workflowControllerDidRun:.  The first method is called just before a workflow being managed by the AMWorkflowController is run and the second is called just after it finishes running.  

We use these methods to display the progress bar and to set the internal runningWorkflow flag.  We use bindings based on the runningWorkflow flag to display the progress bar, enable the stop button while a workflow is running, and disable the run button while a workflow is running.  Also, we use the runningWorkflow flag to prevent certain user actions, such as switching the AMWorkflowController to another workflow, while a workflow is still running.




Running a workflow

We have set the run method on the AMWorkflowController as the target action for the run button.  Bindings based on the runningWorkflow flag control the availability of this button (by controlling its enabled state) for starting a new workflow.

We have set the stop method on the AMWorkflowController as the target action for the stop button.  Bindings based on the runningWorkflow flag control the availability of this button (by controlling its enabled state) for stopping a new workflow.




Where to next?

Documentation for Automator AMWorkflowController and AMWorkflow can be found in the developer documentation.  To find the AMWorkflowController and AMWorkflow documentation, select 'Documentation' from the Help Menu in Xcode, and type AMWorkflow or AMWorkflowController into the search field near the top of the window.


===========================================================================
BUILD REQUIREMENTS

Xcode 4.2, Mac OS X 10.7 Lion.

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
Copyright (C) 2007-2011 Apple Inc. All rights reserved.