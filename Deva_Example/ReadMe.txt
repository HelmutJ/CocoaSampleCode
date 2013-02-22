### Deva Example ###

===========================================================================
DESCRIPTION:

The Deva sample was originally designed to identify and communicate with the 
DevaSys <http://www.devasys.com> "USB I2C/IO,ÊInterface Board", and to interact
with the programmable IO bits which appear on the IO connector. Much of the sample
functionality is specific to the DevaSys devices. However, portions of the sample
demonstrate many techniques implemented in all USB application level drivers
such as
1. Discovering the USB device (or interface).
2. Accessing the USB device (or interface) via a plugin interface.
3. Setting the default configuration for a USB Device.
4. Identifying the endpoints and obtaining the pipe properties.
5. Making USB control requests

The Deva sample builds a command line interface tool for use in a Terminal
window. The tool can be used with all USB devices as well as with 
the interfaces on USB Composite devices. The tool will detect the presence
of a matching USB device, by vendor ID and product ID, or a specific USB
interface with the additional configuration and interface number parameter.

The tool will try to open the USB device, configure the device, then access 
the interface and, identify the pipes. 
===========================================================================
BUILD REQUIREMENTS:

Xcode 3.1 or later, Mac OS X Leopard v10.5 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X Leopard v10.5 or later

===========================================================================
PACKAGING LIST:

Main.c
Main code to discover the USB device (or interface), open the USB device, 
and begin to work with the device.

deva.{c,h}
Functions specific for accessing the IO ports on the DevaSys device.

printInterpretedError.{c.h}
Code to print an interpreted version of an IOReturn error.

something.{c.h}
Entry point for device specific code.
===========================================================================
USING THE SAMPLE Deva tool

Determine whether you want to have the Deva work at the USB device level or 
begin at the USB interface level. In the main.c file, set MATCH_INTERFACE to 
0 to have the tool search for a matching USB device, or set the value to a
non-zero value to have the tool match by interface.

For a match by USB device, use the tool by passing the vendorID and productID
as parameters to the command line interface. 
user$ ./Deva <VID> <PID>

For a match by USB interface, use the tool in the same way as for a USB 
device, by passing in the vendorID and productID as parameters to the 
command line interface. For the USB interface case, the code is set to 
look for interface 0, configuration 1. To have the tool find a different
interface and configuration, set usbConfig, and usbIntNum, in the main
function as desired.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
