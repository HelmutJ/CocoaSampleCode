NSOperationSample

"NSOperationSample" is a Cocoa sample application that demonstrates how to use the NSOperation and NSOperationQueue classes. 

The NSOperation class manages the execution of a single encapsulated task.  Operations are typically scheduled by adding them to an operation queue object (an instance of NSOperationQueue class), although you can execute them directly by explicitly invoking their "start" method.  Operations remain in the queue until they are cancelled or finish executing.

===========================================================================
Sample Requirements
The supplied Xcode project was created using Xcode v4.3 or later running under Mac OS X 10.6.x or later.  It also uses ARC (Objective-C Automatic Reference Counting). 

===========================================================================
About the Sample
"NSOperationSample" illustrates how to use NSOperation and NSOperationQueue classes by searching the file system for certain image files.  One NSOperation is created for recursively searching a given directory, other NSOperation instances are then created for each file found and used to examine the file.  It uses NSOperationQueue to manage these operations so users can stop the search.

===========================================================================
Using the Sample
Simply build and run the sample using Xcode.  Choose a directory to start the search of image files.  The sample will recursively search that directory for all image files.  You can stop the search by clicking "Stop".

===========================================================================
Changes from Previous Versions:

1.0 - First version.
1.1 - Fixed memory leak, some code reformatting.
1.3 - Upgraded to Xcode 4.3 and Mac OS X 10.7, replaced one deprecated API use, adopted NSURL APIs.


Copyright (C) 2006-2012 Apple Inc. All rights reserved.