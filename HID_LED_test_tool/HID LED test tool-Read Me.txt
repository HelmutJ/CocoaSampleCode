HID LED test tool
Human Interface Device LED test tool

Version 1.0 1 Apr 2008 Initial release.  
----

This application is a command line tool which demonstrates the HID Manager APIs introduced in Leopard (10.5). 

----

Requirements: Mac OS X 10.5, Xcode 3.0

Packing List
------------
The sample contains the following items:

    HID LED test tool-Read Me.txt   - this file
    HID LED test tool.xcodeproj     - Xcode project file
    configs                         - Xcode configuration files
    main.c                          - main source file
    build                           - contains a prebuilt binary.


Building the Sample
-------------------
The sample was built using Xcode 3.0 on Mac OS X 10.5.  You should be able to just open the project and choose Build from the Build menu.  This will build "HID LED test tool" in the "build/debug" or "build/release" directory.

Using the Sample
----------------
Launch "HID LED test tool" 

How the code works
------------
The "main" routine creates a IOHID Manager reference to which we set a matching dictionary for keyboards. We then open it and copy out a set of its devices (which should all be keyboards). We then extract all the device references from this set into a block of memory. We then (pre-)create an element matching dictionary for LEDs before entering our main loops.

Our outer loop executes 256 passes; the inner loop iterates over all of the device references that we extracted from the set of devices that we'd copied from our HID Manager reference. After double checking to be sure that the device is a keyboard we copy all the matching elements into a CFArray and then iterate over all the elements in that array. For each element in the array of elements we double check it's usage page to be sure that it's an LED and then get its min/max logical range. This range is used as a modulus to compute the LED's desired value (based on the current pass). This elementvalue is then sent to the device and all loops continue. If an LED element was sent a value then we delay half a second between passes.

Caveats
-------

This demonstration application and the set of utilities is constantly evolving to both address any bugs and provide better support for developer requested features. Any suggestions and/or bugs can be directed to the Apple bug reporter at: <http://developer.apple.com/bugreporter/index.html>

We hope this helps people get up and running with the HID Manager APIs introduced in 10.5 in a quick and painless manner.

Credits and Version History
---------------------------

Version 1.0 1 Apr 2008 Initial release.  

Share and Enjoy.
Apple Developer Technical Support
