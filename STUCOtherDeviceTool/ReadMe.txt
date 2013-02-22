### STUCOtherDeviceTool ###

===========================================================================
DESCRIPTION:

Finds attached devices that have the following SCSI Peripheral Device Types:
	01h	Sequential access devices
	02h	Printer devices
	03h	Processor devices
	06h	Scanners
	08h	Medium changers

Sends SCSI commands to these devices using the SCSITask User Client (STUC) API.

See Technical Q&A QA1179 "Sending SCSI or ATA commands to storage devices" <http://developer.apple.com/qa/qa2001/qa1179.html> for more information
about devices that are supported by STUC.

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.1 or later, Mac OS X Leopard v10.5 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X Leopard v10.5 or later

===========================================================================
PACKAGING LIST:

STUCOtherDeviceTool.c
Test tool source.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
