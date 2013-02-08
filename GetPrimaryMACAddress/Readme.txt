GetPrimaryMACAddress
Command-line tool demonstrating how to retrieve the Ethernet MAC address of the built-in Ethernet interface from the I/O Registry on Mac OS X. This is useful if you need a means of uniquely identifying a Macintosh system.

Techniques shown include finding the primary (built-in) Ethernet interface, finding the parent Ethernet controller, and retrieving properties from the controller's I/O Registry entry.


Version: 1.1 - 04/30/2002	

- Fix bug in creating the matching dictionary that caused the kIOPrimaryInterface property to be ignored.
- Clean up comments and add additional comments about how IOServiceGetMatchingServices operates.

Version: 1.2 - 09/15/2005

- Updated to produce a universal binary.
- Use kIOMasterPortDefault instead of older IOMasterPort function.
- Print the MAC address to stdout in response to <rdar://problem/4021220>.

Version: 1.3 - 04/27/2011

- Now builds with Xcode 4.
