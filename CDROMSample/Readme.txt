CDROMSample
Command-line tool demonstrating how to use IOKitLib to find CD-ROM media mounted on the system. It also shows how to open, read raw sectors from, and close the drive.

Version: 1.3 - 10/17/2002

Techniques shown are:
- Finding ejectable CD-ROM media
- Locating the BSD /dev/rdisk* node name corresponding to that media 
- Opening the /dev/rdisk* node
- Retrieving the media's preferred block size
- Reading a sector from the media 
- Closing the device 

Note that /dev/*disk* nodes for removable media are owned by the currently logged in user. Nodes for non-removable media are owned by root. 

Version: 1.4 - 8/17/2005

- Updated to produce a universal binary.
- Use kIOMasterPortDefault instead of older IOMasterPort function.

Version: 1.5 - 04/27/2011

- Now builds with Xcode 4.