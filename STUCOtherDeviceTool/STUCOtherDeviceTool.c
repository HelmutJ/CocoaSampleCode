/*
 
 File: STUCOtherDeviceTool.c
 
 Abstract: Command line tool which sends SCSI commands to supported devices other than MMC authoring devices
	using SCSITask User Client.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2001-2009 Apple Inc. All Rights Reserved.
 
*/ 

//-----------------------------------------------------------------------------
//	Includes
//-----------------------------------------------------------------------------

#include <string.h>
#include <unistd.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/scsi/SCSITaskLib.h>
#include <IOKit/scsi/SCSICommandOperationCodes.h>
#include <IOKit/scsi/SCSICmds_INQUIRY_Definitions.h>
#include <CoreFoundation/CoreFoundation.h>


//-----------------------------------------------------------------------------
//	Macros
//-----------------------------------------------------------------------------

#define DEBUG	0

#define DEBUG_ASSERT_COMPONENT_NAME_STRING "STUCOtherDeviceTool"

#if DEBUG
#define DEBUG_ASSERT_MESSAGE(componentNameString,	\
							 assertionString,		\
							 exceptionLabelString,	\
							 errorString,			\
							 fileName,				\
							 lineNumber,			\
							 errorCode)				\
DebugAssert(componentNameString,					\
					   assertionString,				\
					   exceptionLabelString,		\
					   errorString,					\
					   fileName,					\
					   lineNumber,					\
					   errorCode)					\

static void
DebugAssert ( const char *	componentNameString,
			  const char *	assertionString,
			  const char *	exceptionLabelString,
			  const char *	errorString,
			  const char *	fileName,
			  long			lineNumber,
			  int			errorCode )
{
	
	if ( ( assertionString != NULL ) && ( *assertionString != '\0' ) )
		printf ( "Assertion failed: %s: %s\n", componentNameString, assertionString );
	else
		printf ( "Check failed: %s:\n", componentNameString );
	if ( exceptionLabelString != NULL )
		printf ( "	 %s\n", exceptionLabelString );
	if ( errorString != NULL )
		printf ( "	 %s\n", errorString );
	if ( fileName != NULL )
		printf ( "	 file: %s\n", fileName );
	if ( lineNumber != 0 )
		printf ( "	 line: %ld\n", lineNumber );
	if ( errorCode != 0 )
		printf ( "	 error: %d\n", errorCode );
	
}

#endif	/* DEBUG */

#include <AssertMacros.h>


// These are mutually exclusive. Only define one of them to be 1.
#define FILTER_SEQUENTIAL_ACCESS_DEVICES_ONLY			1	/* SCSI Peripheral Device Type 01 devices */
#define FILTER_PRINTER_DEVICES_ONLY						0	/* SCSI Peripheral Device Type 02 devices */
#define FILTER_PROCESSOR_DEVICES_ONLY					0	/* SCSI Peripheral Device Type 03 devices */
#define FILTER_SCANNERS_ONLY							0	/* SCSI Peripheral Device Type 06 devices */
#define FILTER_MEDIUM_CHANGERS_ONLY						0	/* SCSI Peripheral Device Type 08 devices */

#if ( FILTER_SEQUENTIAL_ACCESS_DEVICES_ONLY || \
	  FILTER_PRINTER_DEVICES_ONLY || \
	  FILTER_PROCESSOR_DEVICES_ONLY || \
	  FILTER_SCANNERS_ONLY || \
	  FILTER_MEDIUM_CHANGERS_ONLY )
#define FILTER	1
#endif


#define FILTER_APPLE_PRODUCT_ID_ONLY					0	/* Filter to devices which have "Apple" as the Vendor Identification*/


//-----------------------------------------------------------------------------
//	Constants
//-----------------------------------------------------------------------------

#define kAppleVendorString								"Apple"


//-----------------------------------------------------------------------------
//	Globals
//-----------------------------------------------------------------------------

static IONotificationPortRef	gNotifyPort;
static io_iterator_t			gAppearedIter;
static io_iterator_t			gDisappearedIter;


//-----------------------------------------------------------------------------
//	Prototypes
//-----------------------------------------------------------------------------

static void
PrintSenseString ( SCSI_Sense_Data * sense, Boolean addRawValues );

static void
TestDevice ( io_service_t service );

static void
TestUnitReady ( SCSITaskDeviceInterface ** interface );

static void
Inquiry ( SCSITaskDeviceInterface ** interface );

static void
DeviceAppeared ( void * refCon, io_iterator_t iterator );

static void
DeviceDisappeared ( void * refCon, io_iterator_t iterator );

static void
StripWhiteSpace ( char * buffer, SInt32 length );

static void
SignalHandler ( int sigraised );


//-----------------------------------------------------------------------------
//		main - Our main entry point
//-----------------------------------------------------------------------------

int
main ( int argc, const char * argv[] )
{
	
	CFMutableDictionaryRef 	matchingDict	= NULL;
	CFMutableDictionaryRef 	subDict			= NULL;
	CFRunLoopSourceRef		runLoopSource	= NULL;
	IOReturn				error			= kIOReturnSuccess;
	sig_t					oldHandler		= 0;
	
#if FILTER
	
	CFNumberRef				peripheralDeviceTypeRef = 0;
	UInt8					peripheralDeviceType	= 0;
	
#endif /* FILTER */
	
	// Set up a signal handler so we can clean up when we're interrupted from the command line
	// Otherwise we stay in our run loop forever.
	oldHandler = signal ( SIGINT, SignalHandler );
	require ( ( oldHandler != SIG_ERR ), ErrorExit );
	
	// Create the dictionaries
	matchingDict = CFDictionaryCreateMutable ( kCFAllocatorDefault,
											   0,
											   &kCFTypeDictionaryKeyCallBacks,
											   &kCFTypeDictionaryValueCallBacks );
	require ( ( matchingDict != NULL ), ErrorExit ); 
	
	subDict = CFDictionaryCreateMutable ( kCFAllocatorDefault,
										  0,
										  &kCFTypeDictionaryKeyCallBacks,
										  &kCFTypeDictionaryValueCallBacks );
	require ( ( subDict != NULL ), ReleaseMatchingDictionary ); 
	
	//
	//	Note: We are setting up a matching dictionary which looks like the following:
	//
	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//		</dict>
	// </dict>
	//
	
	// Create a dictionary with the "SCSITaskDeviceCategory" key = "SCSITaskUserClientDevice"
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSITaskDeviceCategory ),
							CFSTR ( kIOPropertySCSITaskUserClientDevice ) );
	
	// The following gives you an idea of how to filter based on properties in the IORegistry.
	// If you want to filter based on a SCSI Peripheral Device Type, here are a few examples.
	// You can match on any of the properties listed at the node you are interested in (typically
	// that node is the IOSCSIPeripheralDeviceNub for drivers with no in-kernel logical unit
	// driver). You can match on kIOPropertySCSIVendorIdentification to find only some vendors, or
	// you can match on a specific product using kIOPropertySCSIProductIdentification, etc.
	
	#if FILTER_SEQUENTIAL_ACCESS_DEVICES_ONLY

	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//			<key>Peripheral Device Type<key>
	//			<integer>1</integer>
	//		</dict>
	// </dict>
	
	peripheralDeviceType = kINQUIRY_PERIPHERAL_TYPE_SequentialAccessSSCDevice;
	peripheralDeviceTypeRef = CFNumberCreate ( 	kCFAllocatorDefault,
												kCFNumberCharType,
												&peripheralDeviceType );
	
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSIPeripheralDeviceType ),
							peripheralDeviceTypeRef );
	
	CFRelease ( peripheralDeviceTypeRef );
	
	#endif /* FILTER_SEQUENTIAL_ACCESS_DEVICES_ONLY */
	
	#if FILTER_PRINTER_DEVICES_ONLY

	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//			<key>Peripheral Device Type<key>
	//			<integer>9</integer>
	//		</dict>
	// </dict>
	
	peripheralDeviceType = kINQUIRY_PERIPHERAL_TYPE_PrinterSSCDevice;
	peripheralDeviceTypeRef = CFNumberCreate ( 	kCFAllocatorDefault,
												kCFNumberCharType,
												&peripheralDeviceType );
	
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSIPeripheralDeviceType ),
							peripheralDeviceTypeRef );
	
	CFRelease ( peripheralDeviceTypeRef );
	
	#endif /* FILTER_PRINTER_DEVICES_ONLY */

	#if FILTER_PROCESSOR_DEVICES_ONLY

	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//			<key>Peripheral Device Type<key>
	//			<integer>3</integer>
	//		</dict>
	// </dict>
	
	peripheralDeviceType = kINQUIRY_PERIPHERAL_TYPE_ProcessorSPCDevice;
	peripheralDeviceTypeRef = CFNumberCreate ( 	kCFAllocatorDefault,
												kCFNumberCharType,
												&peripheralDeviceType );
	
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSIPeripheralDeviceType ),
							peripheralDeviceTypeRef );
	
	CFRelease ( peripheralDeviceTypeRef );
	
	#endif /* FILTER_PROCESSOR_DEVICES_ONLY */

	#if FILTER_SCANNERS_ONLY

	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//			<key>Peripheral Device Type<key>
	//			<integer>6</integer>
	//		</dict>
	// </dict>
	
	peripheralDeviceType = kINQUIRY_PERIPHERAL_TYPE_ScannerSCSI2Device;
	peripheralDeviceTypeRef = CFNumberCreate ( 	kCFAllocatorDefault,
												kCFNumberCharType,
												&peripheralDeviceType );
	
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSIPeripheralDeviceType ),
							peripheralDeviceTypeRef );
	
	CFRelease ( peripheralDeviceTypeRef );
	
	#endif /* FILTER_SCANNERS_ONLY */

	#if FILTER_MEDIUM_CHANGERS_ONLY

	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskUserClientDevice</string>
	//			<key>Peripheral Device Type<key>
	//			<integer>8</integer>
	//		</dict>
	// </dict>
	
	peripheralDeviceType = kINQUIRY_PERIPHERAL_TYPE_MediumChangerSMCDevice;
	peripheralDeviceTypeRef = CFNumberCreate ( 	kCFAllocatorDefault,
												kCFNumberCharType,
												&peripheralDeviceType );
	
	CFDictionarySetValue ( 	subDict,
							CFSTR ( kIOPropertySCSIPeripheralDeviceType ),
							peripheralDeviceTypeRef );
	
	CFRelease ( peripheralDeviceTypeRef );
	
	#endif /* FILTER_MEDIUM_CHANGERS_ONLY */
	
	// Add the dictionary to the main dictionary with the key "IOPropertyMatch" to
	// narrow the search to the above dictionary.
	CFDictionarySetValue ( 	matchingDict,
							CFSTR ( kIOPropertyMatchKey ),
							subDict );
	
	// Create the port on which we will receive notifications. We'll wrap it in a runLoopSource
	// which we then feed into the runLoop for async event notifications.
	gNotifyPort = IONotificationPortCreate ( kIOMasterPortDefault );
	require ( ( gNotifyPort != NULL ), ReleaseSubDictionary );
	
	// Get a runLoopSource for our mach port.
	runLoopSource = IONotificationPortGetRunLoopSource ( gNotifyPort );
	require ( ( runLoopSource != NULL ), DestroyNotificationPort );
	
	// Add the runloop source to the current runloop. You must enter the runloop by calling
	// CFRunLoopRun() before any notifications can be delivered.
	CFRunLoopAddSource ( CFRunLoopGetCurrent ( ), runLoopSource, kCFRunLoopDefaultMode );
	
	// Retain a reference since we arm both the appearance and disappearance notifications
	// and the call to IOServiceAddMatchingNotification() consumes a reference each time.
	matchingDict = ( CFMutableDictionaryRef ) CFRetain ( matchingDict );
	
	// Now set up two notifications, one to be called when an authoring device is
	// first matched by I/O Kit, and the other to be called when the device is
	// terminated.
	error = IOServiceAddMatchingNotification ( gNotifyPort,
											   kIOFirstMatchNotification,
											   matchingDict,
											   DeviceAppeared,
											   NULL,
											   &gAppearedIter );
	require ( ( error == kIOReturnSuccess ), DestroyNotificationPort );
	
	// Iterate once to get already-present devices and arm the notification
	DeviceAppeared ( NULL, gAppearedIter );
	
	error = IOServiceAddMatchingNotification ( gNotifyPort,
											   kIOTerminatedNotification,
											   matchingDict,
											   DeviceDisappeared,
											   NULL,
											   &gDisappearedIter );
	require ( ( error == kIOReturnSuccess ), ReleaseAppearedIterator );
	
	// Iterate once to arm the notification
	DeviceDisappeared ( NULL, gDisappearedIter );
	
	// Release the dictionary
	CFRelease ( subDict );
	subDict = NULL;
	
	// Start the run loop. Now we'll receive notifications.
	CFRunLoopRun ( );
	
	// We should never get here, but this is required.
	return 0;
	
	
ReleaseAppearedIterator:
	
	
	require_quiet ( ( gAppearedIter != IO_OBJECT_NULL ), DestroyNotificationPort );
	IOObjectRelease ( gAppearedIter );
	gAppearedIter = IO_OBJECT_NULL;
	
	
DestroyNotificationPort:
	
	
	require_quiet ( ( gNotifyPort != NULL ), ReleaseSubDictionary );
	IONotificationPortDestroy ( gNotifyPort );
	gNotifyPort = NULL;
	
	
ReleaseSubDictionary:
	
	
	require_quiet ( ( subDict != NULL ), ReleaseMatchingDictionary );
	CFRelease ( subDict );
	subDict = NULL;
	
	
ReleaseMatchingDictionary:
	
	
	require_quiet ( ( matchingDict != NULL ), ErrorExit );
	CFRelease ( matchingDict );
	matchingDict = NULL;
	
	
ErrorExit:
	
	
	return -1;
	
}


//-----------------------------------------------------------------------------
//		TestDevice -  Creates a plugin for the device and begins test process
//-----------------------------------------------------------------------------

static void
TestDevice ( io_service_t service )
{
	
	SInt32							score			= 0;
	HRESULT							herr			= S_OK;
	IOReturn						err				= kIOReturnSuccess;
	IOCFPlugInInterface **			plugInInterface = NULL;
	SCSITaskDeviceInterface **		interface		= NULL;
	
	// Create the IOCFPlugIn interface so we can query it.
	err = IOCreatePlugInInterfaceForService ( 	service,
												kIOSCSITaskDeviceUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&plugInInterface,
												&score );
	
	require ( ( err == kIOReturnSuccess ), ErrorExit );
	
	// Query the interface for the SCSITaskDeviceInterface.
	herr = ( *plugInInterface )->QueryInterface ( plugInInterface,
										CFUUIDGetUUIDBytes ( kIOSCSITaskDeviceInterfaceID ),
										( LPVOID * ) &interface );
	
	require ( ( herr == S_OK ), DestroyPlugin );
	require ( ( interface != NULL ), DestroyPlugin );
	
	// Obtain exclusive access
	err = ( *interface )->ObtainExclusiveAccess ( interface );
	require ( ( err == kIOReturnSuccess ), ReleaseDeviceInterface );
	
	// We have exclusive access now. Send a TEST_UNIT_READY command.
	TestUnitReady ( interface );
	
	// Send an INQUIRY command.
	Inquiry ( interface );
	
	// Make sure we release exclusive access now that we are done with the device.
	( *interface )->ReleaseExclusiveAccess ( interface );
	
	
ReleaseDeviceInterface:
	
	
	require_quiet ( ( interface != NULL ), DestroyPlugin );
	( *interface )->Release ( interface );
	interface = NULL;
	
	
DestroyPlugin:
	
	
	require_quiet ( ( plugInInterface != NULL ), ErrorExit );
	IODestroyPlugInInterface ( plugInInterface );
	plugInInterface = NULL;
	
	
ErrorExit:
	
	
	return;
	
}


//-----------------------------------------------------------------------------
//		Inquiry - Sends an INQUIRY command to the device
//-----------------------------------------------------------------------------

static void
Inquiry ( SCSITaskDeviceInterface ** interface )
{
	
	SCSIServiceResponse				serviceResponse	= kSCSIServiceResponse_Request_In_Process;
	SCSITaskStatus					taskStatus		= kSCSITaskStatus_GOOD;
	SCSICmd_INQUIRY_StandardData	inqBuffer		= { 0 };
	SCSI_Sense_Data					senseData		= { 0 };
	SCSICommandDescriptorBlock		cdb				= { 0 };
	SCSITaskInterface **			task			= NULL;
	IOReturn						err	 			= 0;
	UInt64							transferCount 	= 0;
	SCSITaskSGElement				sgElement;
	
	printf ( "Inquiry: " );
	
	// Create a task now that we have exclusive access
	task = ( *interface )->CreateSCSITask ( interface );
	require ( ( task != NULL ), ErrorExit );
	
	// Set up the sgElement. The address is just the buffer's address. The length is our request size.
#if __LP64__
	sgElement.address = ( mach_vm_address_t ) &inqBuffer;
#else
	sgElement.address = ( IOVirtualAddress ) &inqBuffer;
#endif
	sgElement.length  = sizeof ( SCSICmd_INQUIRY_StandardData );
	
	// We're going to execute an INQUIRY to the device as a
	// test of exclusive commands.
	cdb[0] = kSCSICmd_INQUIRY;
	cdb[4] = sizeof ( SCSICmd_INQUIRY_StandardData );
	
	// Set the actual cdb in the task
	err = ( *task )->SetCommandDescriptorBlock ( task, cdb, kSCSICDBSize_6Byte );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Set the scatter-gather entry in the task
	err = ( *task )->SetScatterGatherEntries ( task,
											   &sgElement,
											   1,
											   sizeof ( SCSICmd_INQUIRY_StandardData ),
											   kSCSIDataTransfer_FromTargetToInitiator );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Set the timeout in the task
	err = ( *task )->SetTimeoutDuration ( task, 10000 );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Send it!
	err = ( *task )->ExecuteTaskSync ( task, &senseData, &taskStatus, &transferCount );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Get the SCSI service response
	err = ( *task )->GetSCSIServiceResponse ( task, &serviceResponse );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	printf ( "serviceResponse = %d, taskStatus = %d, transferCount = %qd\n", serviceResponse, taskStatus, transferCount );
	
	require ( ( serviceResponse == kSCSIServiceResponse_TASK_COMPLETE ), ReleaseTask );
	
	if ( taskStatus == kSCSITaskStatus_GOOD )
	{
		
		char	tmp[kINQUIRY_PRODUCT_IDENTIFICATION_Length + 1];
		
		printf ( "Good Status\n" );
		printf ( "Inquiry Data\n" );
		
		printf ( "Peripheral Device Type = %d\n",
				 inqBuffer.PERIPHERAL_DEVICE_TYPE & kINQUIRY_PERIPHERAL_TYPE_Mask );
		printf ( "Removable Media Bit = %d\n",
				 inqBuffer.RMB & kINQUIRY_PERIPHERAL_RMB_MediumRemovable ? 1 : 0 );
		
		bcopy ( inqBuffer.VENDOR_IDENTIFICATION, tmp, kINQUIRY_VENDOR_IDENTIFICATION_Length );
		tmp[kINQUIRY_VENDOR_IDENTIFICATION_Length] = 0;
		StripWhiteSpace ( tmp, kINQUIRY_VENDOR_IDENTIFICATION_Length );
		printf ( "Vendor Identification = %s\n", tmp );
		
		bcopy ( inqBuffer.PRODUCT_IDENTIFICATION, tmp, kINQUIRY_PRODUCT_IDENTIFICATION_Length );
		tmp[kINQUIRY_PRODUCT_IDENTIFICATION_Length] = 0;
		StripWhiteSpace ( tmp, kINQUIRY_PRODUCT_IDENTIFICATION_Length );
		printf ( "Product Identification = %s\n", tmp );
		
		bcopy ( inqBuffer.PRODUCT_REVISION_LEVEL, tmp, kINQUIRY_PRODUCT_REVISION_LEVEL_Length );
		tmp[kINQUIRY_PRODUCT_REVISION_LEVEL_Length] = 0;
		StripWhiteSpace ( tmp, kINQUIRY_PRODUCT_REVISION_LEVEL_Length );
		printf ( "Product Revision Level = %s\n", tmp );
		
		printf ( "\n" );
		
	}
	
	else if ( taskStatus == kSCSITaskStatus_CHECK_CONDITION )
	{
		PrintSenseString ( &senseData, false );
	}
	
	
ReleaseTask:
	
	
	require_quiet ( ( task != NULL ), ErrorExit );
	( *task )->Release ( task );
	task = NULL;
	
	
ErrorExit:
	
	
	return;
	
}


//-----------------------------------------------------------------------------
//		TestUnitReady -  Sense a TEST_UNIT_READY command to the device
//-----------------------------------------------------------------------------

static void
TestUnitReady ( SCSITaskDeviceInterface ** interface )
{
	
	SCSIServiceResponse				serviceResponse	= kSCSIServiceResponse_Request_In_Process;
	SCSITaskStatus					taskStatus		= kSCSITaskStatus_GOOD;
	SCSI_Sense_Data					senseData		= { 0 };
	SCSICommandDescriptorBlock		cdb				= { 0 };
	SCSITaskInterface **			task			= NULL;
	IOReturn						err	 			= 0;
	UInt64							transferCount	= 0;
	
	printf ( "TestUnitReady: " );
	
	// Create a task now that we have exclusive access
	task = ( *interface )->CreateSCSITask ( interface );
	require ( ( task != NULL ), ErrorExit );
	
	// TEST_UNIT_READY is all zeros in the CDB, so we don't actually
	// have to set any values.
	
	// cdb[0] = kSCSICmd_TEST_UNIT_READY;
	
	// Set the actual cdb in the task
	err = ( *task )->SetCommandDescriptorBlock ( task, cdb, kSCSICDBSize_6Byte );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Set the timeout in the task
	err = ( *task )->SetTimeoutDuration ( task, 5000 );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Send it!
	err = ( *task )->ExecuteTaskSync ( task, &senseData, &taskStatus, &transferCount );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	// Get the SCSI service response
	err = ( *task )->GetSCSIServiceResponse ( task, &serviceResponse );
	require ( ( err == kIOReturnSuccess ), ReleaseTask );
	
	printf ( "serviceResponse = %d, taskStatus = %d\n", serviceResponse, taskStatus );
	
	require ( ( serviceResponse == kSCSIServiceResponse_TASK_COMPLETE ), ReleaseTask );
	
	// Task status is not GOOD, print any sense string if they apply.
	if ( taskStatus == kSCSITaskStatus_GOOD )
	{
		printf ( "Good Status, device is ready\n" );
	}
	
	else if ( taskStatus == kSCSITaskStatus_CHECK_CONDITION )
	{
		PrintSenseString ( &senseData, false );	
	}
	
	
ReleaseTask:
	
	
	require_quiet ( ( task != NULL ), ErrorExit );
	( *task )->Release ( task );
	task = NULL;
	
	
ErrorExit:
	
	
	return;
	
}


//-----------------------------------------------------------------------------
//		PrintSenseString -  Prints out meaningful string corresponding to sense
//							data SENSE_KEY, ASC, and ASCQ
//-----------------------------------------------------------------------------

static void
PrintSenseString ( SCSI_Sense_Data * sense, Boolean addRawValues )
{
	
	char	str[256];
	UInt8	key, ASC, ASCQ;
	
	key 	= sense->SENSE_KEY & 0x0F;
	ASC 	= sense->ADDITIONAL_SENSE_CODE;
	ASCQ 	= sense->ADDITIONAL_SENSE_CODE_QUALIFIER;
	
	if ( addRawValues )
	{
	
		snprintf ( str, sizeof ( str ), "Key: 0x%02x, ASC: 0x%02x, ASCQ: 0x%02x\n", key, ASC, ASCQ );
	
	}
	
	else
	{
		str[0] = '\0';
	}
	
	strlcat ( str, "Sense data indicates: ", sizeof ( str ) );
	
	switch ( key )
	{
	
		case 0x0: 	strlcat ( str, "No Sense", sizeof ( str ) ); break;
		case 0x1: 	strlcat ( str, "Recovered Error", sizeof ( str ) ); break;
		case 0x2: 	strlcat ( str, "Not Ready", sizeof ( str ) ); break;
		case 0x3: 	strlcat ( str, "Medium Error", sizeof ( str ) ); break;
		case 0x4: 	strlcat ( str, "Hardware Error", sizeof ( str ) ); break;
		case 0x5: 	strlcat ( str, "Illegal Request", sizeof ( str ) ); break;
		case 0x6: 	strlcat ( str, "Unit Attention", sizeof ( str ) ); break;
		case 0x7: 	strlcat ( str, "Data Protect", sizeof ( str ) ); break;
		case 0x8: 	strlcat ( str, "Blank Check", sizeof ( str ) ); break;
		case 0x9: 	strlcat ( str, "Vendor-Specific", sizeof ( str ) ); break;
		case 0xA: 	strlcat ( str, "Copy Aborted", sizeof ( str ) ); break;
		case 0xB: 	strlcat ( str, "Aborted Command", sizeof ( str ) ); break;
		case 0xC: 	strlcat ( str, "Equal (now obsolete)", sizeof ( str ) ); break;
		case 0xD: 	strlcat ( str, "Volume Overflow", sizeof ( str ) ); break;
		case 0xE: 	strlcat ( str, "Miscompare", sizeof ( str ) ); break;
		default: 	strlcat ( str, "Unknown Sense Code", sizeof ( str ) ); break;
	
	}
	
	strlcat ( str, ", ", sizeof ( str ) );
	
	switch ( ( ( UInt16 ) ASC << 8 ) | ASCQ )
	{
		
		case 0x0000: strlcat ( str, "No additional sense information", sizeof ( str ) ); break;
		case 0x0001: strlcat ( str, "Filemark detected", sizeof ( str ) ); break;
		case 0x0002: strlcat ( str, "End of partition/medium detected", sizeof ( str ) ); break;
		case 0x0003: strlcat ( str, "Setmark detected", sizeof ( str ) ); break;
		case 0x0004: strlcat ( str, "Beginning of partition/medium detected", sizeof ( str ) ); break;
		case 0x0005: strlcat ( str, "End of data detected", sizeof ( str ) ); break;
		case 0x0006: strlcat ( str, "I/O process termination", sizeof ( str ) ); break;
		case 0x0011: strlcat ( str, "Play operation in progress", sizeof ( str ) ); break;
		case 0x0012: strlcat ( str, "Play operation paused", sizeof ( str ) ); break;
		case 0x0013: strlcat ( str, "Play operation successfully completed", sizeof ( str ) ); break;
		case 0x0014: strlcat ( str, "Play operation stopped due to error", sizeof ( str ) ); break;
		case 0x0015: strlcat ( str, "No current audio status to return", sizeof ( str ) ); break;
		case 0x0016: strlcat ( str, "Operation in progress", sizeof ( str ) ); break;
		case 0x0017: strlcat ( str, "Cleaning requested", sizeof ( str ) ); break;
		case 0x0100: strlcat ( str, "Mechanical positioning or changer error", sizeof ( str ) ); break;
		case 0x0200: strlcat ( str, "No seek complete", sizeof ( str ) ); break;
		case 0x0300: strlcat ( str, "Peripheral device write fault", sizeof ( str ) ); break;
		case 0x0301: strlcat ( str, "No write current", sizeof ( str ) ); break;
		case 0x0302: strlcat ( str, "Excessive write errors", sizeof ( str ) ); break;
		case 0x0400: strlcat ( str, "Logical unit not ready, cause not reportable", sizeof ( str ) ); break;
		case 0x0401: strlcat ( str, "Logical unit not ready, in process of becoming ready", sizeof ( str ) ); break;
		case 0x0402: strlcat ( str, "Logical unit not ready, initializing command required", sizeof ( str ) ); break;
		case 0x0403: strlcat ( str, "Logical unit not ready, manual intervention required", sizeof ( str ) ); break;
		case 0x0404: strlcat ( str, "Logical unit not ready, format in progress", sizeof ( str ) ); break;
		case 0x0407: strlcat ( str, "Logical unit not ready, operation in progress", sizeof ( str ) ); break;
		case 0x0408: strlcat ( str, "Logical unit not ready, long write in progress", sizeof ( str ) ); break;
		case 0x0409: strlcat ( str, "Logical unit not ready, self-test in progress", sizeof ( str ) ); break;
		case 0x0500: strlcat ( str, "Logical unit does not respond to selection", sizeof ( str ) ); break;
		case 0x0501: strlcat ( str, "Media load - Eject failed", sizeof ( str ) ); break;
		case 0x0600: strlcat ( str, "No reference position found", sizeof ( str ) ); break;
		case 0x0700: strlcat ( str, "Multiple peripheral devices selected", sizeof ( str ) ); break;
		case 0x0800: strlcat ( str, "Logical unit communication failure", sizeof ( str ) ); break;
		case 0x0801: strlcat ( str, "Logical unit communication time-out", sizeof ( str ) ); break;
		case 0x0802: strlcat ( str, "Logical unit communication parity error", sizeof ( str ) ); break;
		case 0x0803: strlcat ( str, "Logical unit communication CRC error (Ultra-DMA/32)", sizeof ( str ) ); break;
		case 0x0804: strlcat ( str, "Unreachable copy target", sizeof ( str ) ); break;
		case 0x0900: strlcat ( str, "Track following error", sizeof ( str ) ); break;
		case 0x0901: strlcat ( str, "Tracking servo failure", sizeof ( str ) ); break;
		case 0x0902: strlcat ( str, "Focus servo failure", sizeof ( str ) ); break;
		case 0x0903: strlcat ( str, "Spindle servo failure", sizeof ( str ) ); break;
		case 0x0904: strlcat ( str, "Head select fault", sizeof ( str ) ); break;
		case 0x0A00: strlcat ( str, "Error log overflow", sizeof ( str ) ); break;
		case 0x0B00: strlcat ( str, "Warning", sizeof ( str ) ); break;
		case 0x0B01: strlcat ( str, "Warning, specified temperature exceeded", sizeof ( str ) ); break;
		case 0x0B02: strlcat ( str, "Warning, enclosure degraded", sizeof ( str ) ); break;
		case 0x0C00: strlcat ( str, "Write error", sizeof ( str ) ); break;
		case 0x0C01: strlcat ( str, "Write error, recovered with auto reallocation", sizeof ( str ) ); break;
		case 0x0C02: strlcat ( str, "Write error, auto reallocation failed", sizeof ( str ) ); break;
		case 0x0C03: strlcat ( str, "Write error, recommend reassignment", sizeof ( str ) ); break;
		case 0x0C04: strlcat ( str, "Compression check miscompare error", sizeof ( str ) ); break;
		case 0x0C05: strlcat ( str, "Data expansion occurred during compression", sizeof ( str ) ); break;
		case 0x0C06: strlcat ( str, "Block not compressible", sizeof ( str ) ); break;
		case 0x0C07: strlcat ( str, "Write error, recovery needed", sizeof ( str ) ); break;
		case 0x0C08: strlcat ( str, "Write error, recovery failed", sizeof ( str ) ); break;
		case 0x0C09: strlcat ( str, "Write error, loss of streaming", sizeof ( str ) ); break;
		case 0x0C0A: strlcat ( str, "Write error, padding blocks added", sizeof ( str ) ); break;
		case 0x1000: strlcat ( str, "ID, CRC or ECC error", sizeof ( str ) ); break;
		case 0x1100: strlcat ( str, "Unrecovered read error", sizeof ( str ) ); break;
		case 0x1101: strlcat ( str, "Read retries exhausted", sizeof ( str ) ); break;
		case 0x1102: strlcat ( str, "Error too long to correct", sizeof ( str ) ); break;
		case 0x1103: strlcat ( str, "Multiple read errors", sizeof ( str ) ); break;
		case 0x1104: strlcat ( str, "Unrecovered read error - auto reallocate failed", sizeof ( str ) ); break;
		case 0x1105: strlcat ( str, "L-EC uncorrectable error", sizeof ( str ) ); break;
		case 0x1106: strlcat ( str, "CIRC unrecovered error", sizeof ( str ) ); break;
		case 0x1107: strlcat ( str, "Re-synchronization error", sizeof ( str ) ); break;
		case 0x1108: strlcat ( str, "Incomplete block read", sizeof ( str ) ); break;
		case 0x1109: strlcat ( str, "No gap found", sizeof ( str ) ); break;
		case 0x110A: strlcat ( str, "Miscorrected error", sizeof ( str ) ); break;
		case 0x110B: strlcat ( str, "Unrecovered read error - recommend reassignment", sizeof ( str ) ); break;
		case 0x110C: strlcat ( str, "Unrecovered read error - recommend rewrite the data", sizeof ( str ) ); break;
		case 0x110D: strlcat ( str, "De-compression CRC error", sizeof ( str ) ); break;
		case 0x110E: strlcat ( str, "Cannot decompress using declared algorithm", sizeof ( str ) ); break;
		case 0x110F: strlcat ( str, "Error reading UPC/EAN number", sizeof ( str ) ); break;
		case 0x1110: strlcat ( str, "Error reading ISRC number", sizeof ( str ) ); break;
		case 0x1111: strlcat ( str, "Read error, loss of streaming", sizeof ( str ) ); break;
		case 0x1200: strlcat ( str, "Address mark not found for ID field", sizeof ( str ) ); break;
		case 0x1300: strlcat ( str, "Address mark not found for data field", sizeof ( str ) ); break;
		case 0x1400: strlcat ( str, "Recorded entity not found", sizeof ( str ) ); break;
		case 0x1401: strlcat ( str, "Record not found", sizeof ( str ) ); break;
		case 0x1402: strlcat ( str, "Filemark or setmark not found", sizeof ( str ) ); break;
		case 0x1403: strlcat ( str, "End of data not found", sizeof ( str ) ); break;
		case 0x1404: strlcat ( str, "Block sequence error", sizeof ( str ) ); break;
		case 0x1405: strlcat ( str, "Record not found - recommend reassignment", sizeof ( str ) ); break;
		case 0x1406: strlcat ( str, "Record not found - data auto-reallocated", sizeof ( str ) ); break;
		case 0x1500: strlcat ( str, "Random positioning error", sizeof ( str ) ); break;
		case 0x1501: strlcat ( str, "Mechanical positioning or changer error", sizeof ( str ) ); break;
		case 0x1502: strlcat ( str, "Positioning error detected by read of medium", sizeof ( str ) ); break;
		case 0x1600: strlcat ( str, "Data synchronization mark error", sizeof ( str ) ); break;
		case 0x1601: strlcat ( str, "Data sync error - data rewritten", sizeof ( str ) ); break;
		case 0x1602: strlcat ( str, "Data sync error - recommend rewrite", sizeof ( str ) ); break;
		case 0x1603: strlcat ( str, "Data sync error - data auto-reallocated", sizeof ( str ) ); break;
		case 0x1604: strlcat ( str, "Data sync error - recommend reassignment", sizeof ( str ) ); break;
		case 0x1700: strlcat ( str, "Recovered data with no error correction applied", sizeof ( str ) ); break;
		case 0x1701: strlcat ( str, "Recovered data with retries", sizeof ( str ) ); break;
		case 0x1702: strlcat ( str, "Recovered data with positive head offset", sizeof ( str ) ); break;
		case 0x1703: strlcat ( str, "Recovered data with negative head offset", sizeof ( str ) ); break;
		case 0x1704: strlcat ( str, "Recovered data with retries and/or CIRC applied", sizeof ( str ) ); break;
		case 0x1705: strlcat ( str, "Recovered data using previous sector ID", sizeof ( str ) ); break;
		case 0x1706: strlcat ( str, "Recovered data without ECC, data auto-reallocated", sizeof ( str ) ); break;
		case 0x1707: strlcat ( str, "Recovered data without ECC, recommend reassignment", sizeof ( str ) ); break;
		case 0x1708: strlcat ( str, "Recovered data without ECC, recommend rewrite", sizeof ( str ) ); break;
		case 0x1709: strlcat ( str, "Recivered data without ECC, data rewritten", sizeof ( str ) ); break;
		case 0x1800: strlcat ( str, "Recovered data with error correction applied", sizeof ( str ) ); break;
		case 0x1801: strlcat ( str, "Recovered data with error correction & retries applied", sizeof ( str ) ); break;
		case 0x1802: strlcat ( str, "Recovered data, the data was auto-reallocated", sizeof ( str ) ); break;
		case 0x1803: strlcat ( str, "Recovered data with CIRC", sizeof ( str ) ); break;
		case 0x1804: strlcat ( str, "Recovered data with L-EC", sizeof ( str ) ); break;
		case 0x1805: strlcat ( str, "Recovered data, recommend reassignment", sizeof ( str ) ); break;
		case 0x1806: strlcat ( str, "Recovered data, recommend rewrite", sizeof ( str ) ); break;
		case 0x1807: strlcat ( str, "Recovered data with ECC, data rewritten", sizeof ( str ) ); break;
		case 0x1808: strlcat ( str, "Recovered data with linking", sizeof ( str ) ); break;
		case 0x1900: strlcat ( str, "Defect list error", sizeof ( str ) ); break;
		case 0x1901: strlcat ( str, "Defect list not available", sizeof ( str ) ); break;
		case 0x1902: strlcat ( str, "Defect list error in primary list", sizeof ( str ) ); break;
		case 0x1903: strlcat ( str, "Defect list error in grown list", sizeof ( str ) ); break;
		case 0x1A00: strlcat ( str, "Parameter list length error", sizeof ( str ) ); break;
		case 0x1B00: strlcat ( str, "Synchronous data transfer error", sizeof ( str ) ); break;
		case 0x1C00: strlcat ( str, "Defect list not found", sizeof ( str ) ); break;
		case 0x1C01: strlcat ( str, "Primary defect list not found", sizeof ( str ) ); break;
		case 0x1C02: strlcat ( str, "Grown defect list not found", sizeof ( str ) ); break;
		case 0x1D00: strlcat ( str, "Miscompare during verify operation", sizeof ( str ) ); break;
		case 0x1E00: strlcat ( str, "Recovered ID with ECC correction", sizeof ( str ) ); break;
		case 0x1F00: strlcat ( str, "Partial defect list transfer", sizeof ( str ) ); break;
		case 0x2000: strlcat ( str, "Invalid command operation code", sizeof ( str ) ); break;
		case 0x2100: strlcat ( str, "Logical block address out of range", sizeof ( str ) ); break;
		case 0x2101: strlcat ( str, "Invalid element address", sizeof ( str ) ); break;
		case 0x2102: strlcat ( str, "Invalid address for write", sizeof ( str ) ); break;
		case 0x2200: strlcat ( str, "Illegal function", sizeof ( str ) ); break;
		case 0x2400: strlcat ( str, "Invalid field in CDB", sizeof ( str ) ); break;
		case 0x2401: strlcat ( str, "CDB decryption error", sizeof ( str ) ); break;
		case 0x2500: strlcat ( str, "Logical unit not supported", sizeof ( str ) ); break;
		case 0x2600: strlcat ( str, "Invalid field in parameter list", sizeof ( str ) ); break;
		case 0x2601: strlcat ( str, "Parameter not supported", sizeof ( str ) ); break;
		case 0x2602: strlcat ( str, "Parameter value invalid", sizeof ( str ) ); break;
		case 0x2603: strlcat ( str, "Threshold parameters not supported", sizeof ( str ) ); break;
		case 0x2604: strlcat ( str, "Invalid release of active persistent reservation", sizeof ( str ) ); break;
		case 0x2605: strlcat ( str, "Data decryption error", sizeof ( str ) ); break;
		case 0x2606: strlcat ( str, "Too many target descriptors", sizeof ( str ) ); break;
		case 0x2607: strlcat ( str, "Unsupported target descriptor type code", sizeof ( str ) ); break;
		case 0x2608: strlcat ( str, "Too many segment descriptors", sizeof ( str ) ); break;
		case 0x2609: strlcat ( str, "Unsupported segment descriptor type code", sizeof ( str ) ); break;
		case 0x260A: strlcat ( str, "Unexpected inexact segment", sizeof ( str ) ); break;
		case 0x260B: strlcat ( str, "Inline data length exceeded", sizeof ( str ) ); break;
		case 0x260C: strlcat ( str, "Invalid operation for copy source or destination", sizeof ( str ) ); break;
		case 0x260D: strlcat ( str, "Copy segment granularity violation", sizeof ( str ) ); break;
		case 0x2700: strlcat ( str, "Write protected", sizeof ( str ) ); break;
		case 0x2701: strlcat ( str, "Hardware write protected", sizeof ( str ) ); break;
		case 0x2702: strlcat ( str, "Logical unit software write protected", sizeof ( str ) ); break;
		case 0x2703: strlcat ( str, "Associated write protect", sizeof ( str ) ); break;
		case 0x2704: strlcat ( str, "Persistent write protect", sizeof ( str ) ); break;
		case 0x2705: strlcat ( str, "Permanent write protect", sizeof ( str ) ); break;
		case 0x2800: strlcat ( str, "Not ready to ready transition, medium may have changed", sizeof ( str ) ); break;
		case 0x2801: strlcat ( str, "Import or export element accessed", sizeof ( str ) ); break;
		case 0x2900: strlcat ( str, "Power on, reset or bus device reset occurred", sizeof ( str ) ); break;
		case 0x2901: strlcat ( str, "Power on occured", sizeof ( str ) ); break;
		case 0x2902: strlcat ( str, "SCSI bus reset occurred", sizeof ( str ) ); break;
		case 0x2903: strlcat ( str, "Bus device reset function occurred", sizeof ( str ) ); break;
		case 0x2904: strlcat ( str, "Device internal reset", sizeof ( str ) ); break;
		case 0x2905: strlcat ( str, "Transceiver mode changed to single-ended", sizeof ( str ) ); break;
		case 0x2906: strlcat ( str, "Transceiver mode changed to LVD", sizeof ( str ) ); break;
		case 0x2A00: strlcat ( str, "Parameters changed", sizeof ( str ) ); break;
		case 0x2A01: strlcat ( str, "Mode parameters changed", sizeof ( str ) ); break;
		case 0x2A02: strlcat ( str, "Log parameters changed", sizeof ( str ) ); break;
		case 0x2A03: strlcat ( str, "Reservations preempted", sizeof ( str ) ); break;
		case 0x2A04: strlcat ( str, "Reservations released", sizeof ( str ) ); break;
		case 0x2A05: strlcat ( str, "Registrations preempted", sizeof ( str ) ); break;
		case 0x2B00: strlcat ( str, "Copy cannot execute since host cannot disconnect", sizeof ( str ) ); break;
		case 0x2C00: strlcat ( str, "Command sequence error", sizeof ( str ) ); break;
		case 0x2C01: strlcat ( str, "Too many windows specified", sizeof ( str ) ); break;
		case 0x2C02: strlcat ( str, "Invalid combination of windows specified", sizeof ( str ) ); break;
		case 0x2C03: strlcat ( str, "Current program area is not empty", sizeof ( str ) ); break;
		case 0x2C04: strlcat ( str, "Current program area is empty", sizeof ( str ) ); break;
		case 0x2C05: strlcat ( str, "Persistent prevent conflict", sizeof ( str ) ); break;
		case 0x2D00: strlcat ( str, "Overwrite error on update in place", sizeof ( str ) ); break;
		case 0x2E00: strlcat ( str, "Insufficient time for operation", sizeof ( str ) ); break;
		case 0x2F00: strlcat ( str, "Commands cleared by anther initiator", sizeof ( str ) ); break;
		case 0x3000: strlcat ( str, "Incompatible medium installed", sizeof ( str ) ); break;
		case 0x3001: strlcat ( str, "Cannot read medium, unknown format", sizeof ( str ) ); break;
		case 0x3002: strlcat ( str, "Cannot read medium, incompatible format", sizeof ( str ) ); break;
		case 0x3003: strlcat ( str, "Cleaning cartridge installed", sizeof ( str ) ); break;
		case 0x3004: strlcat ( str, "Cannot write medium, unknown format", sizeof ( str ) ); break;
		case 0x3005: strlcat ( str, "Cannot write medium, incompatible format", sizeof ( str ) ); break;
		case 0x3006: strlcat ( str, "Cannot format medium, incompatible medium", sizeof ( str ) ); break;
		case 0x3007: strlcat ( str, "Cleaning failure", sizeof ( str ) ); break;
		case 0x3008: strlcat ( str, "Cannot write, application code mismatch", sizeof ( str ) ); break;
		case 0x3009: strlcat ( str, "Current session not fixated for append", sizeof ( str ) ); break;
		case 0x3100: strlcat ( str, "Medium format corrupted", sizeof ( str ) ); break;
		case 0x3101: strlcat ( str, "Format command failed", sizeof ( str ) ); break;
		case 0x3102: strlcat ( str, "Zoned formatting failed due to spare linking", sizeof ( str ) ); break;
		case 0x3200: strlcat ( str, "No defect spare location available", sizeof ( str ) ); break;
		case 0x3201: strlcat ( str, "Defect list update failure", sizeof ( str ) ); break;
		case 0x3300: strlcat ( str, "Tape length error", sizeof ( str ) ); break;
		case 0x3400: strlcat ( str, "Enclosure failure", sizeof ( str ) ); break;
		case 0x3500: strlcat ( str, "Enclosure services failure", sizeof ( str ) ); break;
		case 0x3501: strlcat ( str, "Unsupported enclosure function", sizeof ( str ) ); break;
		case 0x3502: strlcat ( str, "Enclosure services unavailable", sizeof ( str ) ); break;
		case 0x3503: strlcat ( str, "Enclosure services transfer failure", sizeof ( str ) ); break;
		case 0x3504: strlcat ( str, "Enclosure services transfer refused", sizeof ( str ) ); break;
		case 0x3600: strlcat ( str, "Ribbon, ink, or toner failure", sizeof ( str ) ); break;
		case 0x3700: strlcat ( str, "Rounded parameter", sizeof ( str ) ); break;
		case 0x3800: strlcat ( str, "Event status notification", sizeof ( str ) ); break;
		case 0x3802: strlcat ( str, "ESN - Power management class event", sizeof ( str ) ); break;
		case 0x3804: strlcat ( str, "ESN - Media class event", sizeof ( str ) ); break;
		case 0x3806: strlcat ( str, "ESN - Device busy class event", sizeof ( str ) ); break;
		case 0x3900: strlcat ( str, "Saving parameters not supported", sizeof ( str ) ); break;
		case 0x3A00: strlcat ( str, "Medium not present", sizeof ( str ) ); break;
		case 0x3A01: strlcat ( str, "Medium not present, tray closed", sizeof ( str ) ); break;
		case 0x3A02: strlcat ( str, "Medium not present, tray open", sizeof ( str ) ); break;
		case 0x3A03: strlcat ( str, "Medium not present, loadable", sizeof ( str ) ); break;
		case 0x3A04: strlcat ( str, "Medium not present, medium auxiliary memory accessible", sizeof ( str ) ); break;
		case 0x3B00: strlcat ( str, "Sequential positioning error", sizeof ( str ) ); break;
		case 0x3B01: strlcat ( str, "Tape position error at beginning of medium", sizeof ( str ) ); break;
		case 0x3B02: strlcat ( str, "Tape position error at end of medium", sizeof ( str ) ); break;
		case 0x3B03: strlcat ( str, "Tape or electronic vertical forms unit not ready", sizeof ( str ) ); break;
		case 0x3B04: strlcat ( str, "Slew failure", sizeof ( str ) ); break;
		case 0x3B05: strlcat ( str, "Paper jam", sizeof ( str ) ); break;
		case 0x3B06: strlcat ( str, "Failed to sense top-of-form", sizeof ( str ) ); break;
		case 0x3B07: strlcat ( str, "Failed to sense bottom-of-form", sizeof ( str ) ); break;
		case 0x3B08: strlcat ( str, "Reposition error", sizeof ( str ) ); break;
		case 0x3B09: strlcat ( str, "Read past end of medium", sizeof ( str ) ); break;
		case 0x3B0A: strlcat ( str, "Read past beginning of medium", sizeof ( str ) ); break;
		case 0x3B0B: strlcat ( str, "Position past end of medium", sizeof ( str ) ); break;
		case 0x3B0C: strlcat ( str, "Position past beginning of medium", sizeof ( str ) ); break;
		case 0x3B0D: strlcat ( str, "Medium destination element full", sizeof ( str ) ); break;
		case 0x3B0E: strlcat ( str, "Medium source element empty", sizeof ( str ) ); break;
		case 0x3B0F: strlcat ( str, "End of medium reached", sizeof ( str ) ); break;
		case 0x3B11: strlcat ( str, "Medium magazine not accessible", sizeof ( str ) ); break;
		case 0x3B12: strlcat ( str, "Medium magazine removed", sizeof ( str ) ); break;
		case 0x3B13: strlcat ( str, "Medium magazine inserted", sizeof ( str ) ); break;
		case 0x3B14: strlcat ( str, "Medium magazine locked", sizeof ( str ) ); break;
		case 0x3B15: strlcat ( str, "Medium magazine unlocked", sizeof ( str ) ); break;
		case 0x3B16: strlcat ( str, "Mechanical positioning or changer error", sizeof ( str ) ); break;
		case 0x3D00: strlcat ( str, "Invalid bits in identify message", sizeof ( str ) ); break;
		case 0x3E00: strlcat ( str, "Logical unit has not self-configured yet", sizeof ( str ) ); break;
		case 0x3E01: strlcat ( str, "Logical unit failure", sizeof ( str ) ); break;
		case 0x3E02: strlcat ( str, "Timeout on logical unit", sizeof ( str ) ); break;
		case 0x3E03: strlcat ( str, "Logical unit failed self-test", sizeof ( str ) ); break;
		case 0x3E04: strlcat ( str, "Logical unit unable to update self-test log", sizeof ( str ) ); break;
		case 0x3F00: strlcat ( str, "Target operating conditions have changed", sizeof ( str ) ); break;
		case 0x3F01: strlcat ( str, "Microcode has been changed", sizeof ( str ) ); break;
		case 0x3F02: strlcat ( str, "Changed operating definition", sizeof ( str ) ); break;
		case 0x3F03: strlcat ( str, "Inquiry data has changed", sizeof ( str ) ); break;
		case 0x3F04: strlcat ( str, "Component device attached", sizeof ( str ) ); break;
		case 0x3F05: strlcat ( str, "Device identifier changed", sizeof ( str ) ); break;
		case 0x3F06: strlcat ( str, "Redundancy group created or modified", sizeof ( str ) ); break;
		case 0x3F07: strlcat ( str, "Redundancy group deleted", sizeof ( str ) ); break;
		case 0x3F08: strlcat ( str, "Spare created or modified", sizeof ( str ) ); break;
		case 0x3F09: strlcat ( str, "Spare deleted", sizeof ( str ) ); break;
		case 0x3F0A: strlcat ( str, "Volume set created or modified", sizeof ( str ) ); break;
		case 0x3F0B: strlcat ( str, "Volume set deleted", sizeof ( str ) ); break;
		case 0x3F0C: strlcat ( str, "Volume set deassigned", sizeof ( str ) ); break;
		case 0x3F0D: strlcat ( str, "Volume set reassigned", sizeof ( str ) ); break;
		case 0x3F0E: strlcat ( str, "Reported LUNs data has changed", sizeof ( str ) ); break;
		case 0x3F10: strlcat ( str, "Medium loadable", sizeof ( str ) ); break;
		case 0x3F11: strlcat ( str, "Medium auxiliary memory accessible", sizeof ( str ) ); break;
		case 0x4000: strlcat ( str, "RAM failure", sizeof ( str ) ); break;
		case 0x4100: strlcat ( str, "Data path failure", sizeof ( str ) ); break;
		case 0x4200: strlcat ( str, "Power-on or self-test failure", sizeof ( str ) ); break;
		case 0x4300: strlcat ( str, "Message error", sizeof ( str ) ); break;
		case 0x4400: strlcat ( str, "Internal target failure", sizeof ( str ) ); break;
		case 0x4500: strlcat ( str, "Select or reselect failure", sizeof ( str ) ); break;
		case 0x4600: strlcat ( str, "Unseccessful soft reset", sizeof ( str ) ); break;
		case 0x4700: strlcat ( str, "SCSI Parity error", sizeof ( str ) ); break;
		case 0x4701: strlcat ( str, "Data phase CRC error detected", sizeof ( str ) ); break;
		case 0x4702: strlcat ( str, "SCSI parity error detected during ST data phase", sizeof ( str ) ); break;
		case 0x4703: strlcat ( str, "Information unit CRC error detected", sizeof ( str ) ); break;
		case 0x4704: strlcat ( str, "Async information protection error detected", sizeof ( str ) ); break;
		case 0x4800: strlcat ( str, "Initiator detected error message received", sizeof ( str ) ); break;
		case 0x4900: strlcat ( str, "Invalid message error", sizeof ( str ) ); break;
		case 0x4A00: strlcat ( str, "Command phase error", sizeof ( str ) ); break;
		case 0x4B00: strlcat ( str, "Data phase error", sizeof ( str ) ); break;
		case 0x4C00: strlcat ( str, "Logical unit failed self-configuration", sizeof ( str ) ); break;
		case 0x4E00: strlcat ( str, "Overlapped commands attempted", sizeof ( str ) ); break;
		case 0x5000: strlcat ( str, "Write append error", sizeof ( str ) ); break;
		case 0x5001: strlcat ( str, "Write append position error", sizeof ( str ) ); break;
		case 0x5002: strlcat ( str, "Position error related to timing", sizeof ( str ) ); break;
		case 0x5100: strlcat ( str, "Erase failure", sizeof ( str ) ); break;
		case 0x5300: strlcat ( str, "Media load or eject failed", sizeof ( str ) ); break;
		case 0x5301: strlcat ( str, "Unload tape failure", sizeof ( str ) ); break;
		case 0x5302: strlcat ( str, "Medium removal prevented", sizeof ( str ) ); break;
		case 0x5400: strlcat ( str, "SCSI to host system interface failure", sizeof ( str ) ); break;
		case 0x5500: strlcat ( str, "System Resource failure", sizeof ( str ) ); break;
		case 0x5501: strlcat ( str, "System Buffer full", sizeof ( str ) ); break;
		case 0x5502: strlcat ( str, "Insufficient reservation resources", sizeof ( str ) ); break;
		case 0x5503: strlcat ( str, "Insufficient resources", sizeof ( str ) ); break;
		case 0x5504: strlcat ( str, "Insufficient registration resources", sizeof ( str ) ); break;
		case 0x5700: strlcat ( str, "Unable to recover table of contents", sizeof ( str ) ); break;
		case 0x5800: strlcat ( str, "Generation does not exist", sizeof ( str ) ); break;
		case 0x5900: strlcat ( str, "Updated block read", sizeof ( str ) ); break;
		case 0x5A00: strlcat ( str, "Operator request or state change input (UNSPECIFIED)", sizeof ( str ) ); break;
		case 0x5A01: strlcat ( str, "Operator medium removal request", sizeof ( str ) ); break;
		case 0x5A02: strlcat ( str, "Operator selected write protect", sizeof ( str ) ); break;
		case 0x5A03: strlcat ( str, "Operator selected write permit", sizeof ( str ) ); break;
		case 0x5B00: strlcat ( str, "Log exception", sizeof ( str ) ); break;
		case 0x5B01: strlcat ( str, "Threshold condition met", sizeof ( str ) ); break;
		case 0x5B02: strlcat ( str, "Log counter at maximum", sizeof ( str ) ); break;
		case 0x5B03: strlcat ( str, "Log list codes exhausted", sizeof ( str ) ); break;
		case 0x5C00: strlcat ( str, "RPL status change", sizeof ( str ) ); break;
		case 0x5C01: strlcat ( str, "Spindles synchronized", sizeof ( str ) ); break;
		case 0x5C02: strlcat ( str, "Spindle not synchronized", sizeof ( str ) ); break;
		case 0x5D00: strlcat ( str, "Failure prediction threshold exceeded, predicted logical unit failure", sizeof ( str ) ); break;
		case 0x5D01: strlcat ( str, "Failure prediction threshold exceeded, predicted media failure", sizeof ( str ) ); break;
		case 0x5D10: strlcat ( str, "Hardware impending failure - general hard drive failure", sizeof ( str ) ); break;
		case 0x5D11: strlcat ( str, "Hardware impending failure - drive error rate too high", sizeof ( str ) ); break;
		case 0x5D12: strlcat ( str, "Hardware impending failure - data error rate too high", sizeof ( str ) ); break;
		case 0x5D13: strlcat ( str, "Hardware impending failure - seek error rate too high", sizeof ( str ) ); break;
		case 0x5D14: strlcat ( str, "Hardware impending failure - too many block reassigns", sizeof ( str ) ); break;
		case 0x5D15: strlcat ( str, "Hardware impending failure - access times too high", sizeof ( str ) ); break;
		case 0x5D16: strlcat ( str, "Hardware impending failure - start unit times too high", sizeof ( str ) ); break;
		case 0x5D17: strlcat ( str, "Hardware impending failure - channel parametrics", sizeof ( str ) ); break;
		case 0x5D18: strlcat ( str, "Hardware impending failure - controller detected", sizeof ( str ) ); break;
		case 0x5D19: strlcat ( str, "Hardware impending failure - throughput performance", sizeof ( str ) ); break;
		case 0x5D1A: strlcat ( str, "Hardware impending failure - seek time performance", sizeof ( str ) ); break;
		case 0x5D1B: strlcat ( str, "Hardware impending failure - spin-up retry count", sizeof ( str ) ); break;
		case 0x5D1C: strlcat ( str, "Hardware impending failure - drive calibration retry count", sizeof ( str ) ); break;
		case 0x5D20: strlcat ( str, "Controller impending failure - general hard drive failure", sizeof ( str ) ); break;
		case 0x5D21: strlcat ( str, "Controller impending failure - drive error rate too high", sizeof ( str ) ); break;
		case 0x5D22: strlcat ( str, "Controller impending failure - data error rate too high", sizeof ( str ) ); break;
		case 0x5D23: strlcat ( str, "Controller impending failure - seek error rate too high", sizeof ( str ) ); break;
		case 0x5D24: strlcat ( str, "Controller impending failure - too many block reassigns", sizeof ( str ) ); break;
		case 0x5D25: strlcat ( str, "Controller impending failure - access times too high", sizeof ( str ) ); break;
		case 0x5D26: strlcat ( str, "Controller impending failure - start unit times too high", sizeof ( str ) ); break;
		case 0x5D27: strlcat ( str, "Controller impending failure - channel parametrics", sizeof ( str ) ); break;
		case 0x5D28: strlcat ( str, "Controller impending failure - controller detected", sizeof ( str ) ); break;
		case 0x5D29: strlcat ( str, "Controller impending failure - throughput performance", sizeof ( str ) ); break;
		case 0x5D2A: strlcat ( str, "Controller impending failure - seek time performance", sizeof ( str ) ); break;
		case 0x5D2B: strlcat ( str, "Controller impending failure - spin-up retry count", sizeof ( str ) ); break;
		case 0x5D2C: strlcat ( str, "Controller impending failure - drive calibration retry count", sizeof ( str ) ); break;
		case 0x5DFF: strlcat ( str, "Failure prediction threshold exceeded (FALSE)", sizeof ( str ) ); break;
		case 0x5E00: strlcat ( str, "Low power condition on", sizeof ( str ) ); break;
		case 0x5E01: strlcat ( str, "Idle condition activated by timer", sizeof ( str ) ); break;
		case 0x5E02: strlcat ( str, "Standby condition activated by timer", sizeof ( str ) ); break;
		case 0x5E03: strlcat ( str, "Idle condition activated by command", sizeof ( str ) ); break;
		case 0x5E04: strlcat ( str, "Standby condition activated by command", sizeof ( str ) ); break;
		case 0x5E41: strlcat ( str, "Power state change to active", sizeof ( str ) ); break;
		case 0x5E42: strlcat ( str, "Power state change to idle", sizeof ( str ) ); break;
		case 0x5E43: strlcat ( str, "Power state change to standby", sizeof ( str ) ); break;
		case 0x5E45: strlcat ( str, "Power state change to sleep", sizeof ( str ) ); break;
		case 0x5E47: strlcat ( str, "Power state change to device control", sizeof ( str ) ); break;
		case 0x6000: strlcat ( str, "Lamp failure", sizeof ( str ) ); break;
		case 0x6100: strlcat ( str, "Video acquisition error", sizeof ( str ) ); break;
		case 0x6101: strlcat ( str, "Unable to acquire video", sizeof ( str ) ); break;
		case 0x6102: strlcat ( str, "Out of focus", sizeof ( str ) ); break;
		case 0x6200: strlcat ( str, "Scan head positioning error", sizeof ( str ) ); break;
		case 0x6300: strlcat ( str, "End of user area encountered on this track", sizeof ( str ) ); break;
		case 0x6301: strlcat ( str, "Packet does not fit in available space", sizeof ( str ) ); break;
		case 0x6400: strlcat ( str, "Illegal mode for this track or incompatible medium", sizeof ( str ) ); break;
		case 0x6401: strlcat ( str, "Invalid packet size", sizeof ( str ) ); break;
		case 0x6500: strlcat ( str, "Voltage fault", sizeof ( str ) ); break;
		case 0x6600: strlcat ( str, "Automatic document feeder cover up", sizeof ( str ) ); break;
		case 0x6601: strlcat ( str, "Automatic document feeder lift up", sizeof ( str ) ); break;
		case 0x6602: strlcat ( str, "Document jam in automatic document feeder", sizeof ( str ) ); break;
		case 0x6603: strlcat ( str, "Document misfeed in automatic document feeder", sizeof ( str ) ); break;
		case 0x6700: strlcat ( str, "Configuration failure", sizeof ( str ) ); break;
		case 0x6701: strlcat ( str, "Configuration of incapable logical unit", sizeof ( str ) ); break;
		case 0x6702: strlcat ( str, "Add logical unit failed", sizeof ( str ) ); break;
		case 0x6703: strlcat ( str, "Modification of logical unit failed", sizeof ( str ) ); break;
		case 0x6704: strlcat ( str, "Exchange of logical unit failed", sizeof ( str ) ); break;
		case 0x6705: strlcat ( str, "Remove of logical unit failed", sizeof ( str ) ); break;
		case 0x6706: strlcat ( str, "Attachment of logical unit failed", sizeof ( str ) ); break;
		case 0x6707: strlcat ( str, "Creation of logical unit failed", sizeof ( str ) ); break;
		case 0x6800: strlcat ( str, "Logical unit not configured", sizeof ( str ) ); break;
		case 0x6900: strlcat ( str, "Data loss on logical unit", sizeof ( str ) ); break;
		case 0x6901: strlcat ( str, "Multiple logical unit failures", sizeof ( str ) ); break;
		case 0x6902: strlcat ( str, "A parity/data mismatch", sizeof ( str ) ); break;
		case 0x6A00: strlcat ( str, "Informational, refer to log", sizeof ( str ) ); break;
		case 0x6B00: strlcat ( str, "State change has occurred", sizeof ( str ) ); break;
		case 0x6B01: strlcat ( str, "Redundancy level got better", sizeof ( str ) ); break;
		case 0x6B02: strlcat ( str, "Redundancy level got worse", sizeof ( str ) ); break;
		case 0x6C00: strlcat ( str, "Rebuild failure occurred", sizeof ( str ) ); break;
		case 0x6D00: strlcat ( str, "Recalculate failure occurred", sizeof ( str ) ); break;
		case 0x6E00: strlcat ( str, "Command to logical unit failed", sizeof ( str ) ); break;
		case 0x6F00: strlcat ( str, "Copy protection key exchange failure, authentication failure", sizeof ( str ) ); break;
		case 0x6F01: strlcat ( str, "Copy protection key exchange failure, key not present", sizeof ( str ) ); break;
		case 0x6F02: strlcat ( str, "Copy protection key exchange failure, key not established", sizeof ( str ) ); break;
		case 0x6F03: strlcat ( str, "Read of scrambled sector without authentication", sizeof ( str ) ); break;
		case 0x6F04: strlcat ( str, "Media region code is mismatched to logical unit region", sizeof ( str ) ); break;
		case 0x6F05: strlcat ( str, "Drive region must be permanent/Region reset count error", sizeof ( str ) ); break;
		case 0x7100: strlcat ( str, "Decompression exception long algorithm id", sizeof ( str ) ); break;
		case 0x7200: strlcat ( str, "Session fixation error", sizeof ( str ) ); break;
		case 0x7201: strlcat ( str, "Session fixation error writing lead-in", sizeof ( str ) ); break;
		case 0x7202: strlcat ( str, "Session fixation error writing lead-out", sizeof ( str ) ); break;
		case 0x7203: strlcat ( str, "Session fixation error, incomplete track in session", sizeof ( str ) ); break;
		case 0x7204: strlcat ( str, "Empty or partially written reserved track", sizeof ( str ) ); break;
		case 0x7205: strlcat ( str, "No more RZone reservations are allowed", sizeof ( str ) ); break;
		case 0x7300: strlcat ( str, "CD control error", sizeof ( str ) ); break;
		case 0x7301: strlcat ( str, "Power calibration area almost full", sizeof ( str ) ); break;
		case 0x7302: strlcat ( str, "Power calibration area is full", sizeof ( str ) ); break;
		case 0x7303: strlcat ( str, "Power calibration area error", sizeof ( str ) ); break;
		case 0x7304: strlcat ( str, "Program memory area update failure", sizeof ( str ) ); break;
		case 0x7305: strlcat ( str, "Program memory area is full", sizeof ( str ) ); break;
		case 0x7306: strlcat ( str, "Program memory area is (almost) full", sizeof ( str ) ); break;
		case 0xB900: strlcat ( str, "Play operation aborted", sizeof ( str ) ); break;
		case 0xBF00: strlcat ( str, "Loss of streaming", sizeof ( str ) ); break;
		default:
			if ( ASC == 0x40 ) { snprintf ( str, sizeof ( str ), "Diagnostic failure on component $%02x", ASCQ ); break; }
			if ( ASC == 0x4D ) { snprintf ( str, sizeof ( str ), "Tagged overlapped commands, queue tag = $%02x", ASCQ ); break; }
			break;
	}
	
	printf ( "%s\n", str );
	
}


//-----------------------------------------------------------------------------
//		DeviceAppeared -  Callback for when a new device appears
//-----------------------------------------------------------------------------

static void
DeviceAppeared ( void * refCon, io_iterator_t iterator )
{
	
	io_service_t	obj = IO_OBJECT_NULL;
	
	obj = IOIteratorNext ( iterator );
	
	while ( obj != IO_OBJECT_NULL )
	{
		
		IOReturn				error   = kIOReturnSuccess;
		CFMutableDictionaryRef	theDict = NULL;
		
		printf ( "Device appeared.\n" );
		
		// Get the CF Properties for the io_service_t
		error = IORegistryEntryCreateCFProperties ( obj,
													&theDict,
													kCFAllocatorDefault,
													0 );
		
		if ( error == kIOReturnSuccess )
		{
			
			CFStringRef		theVendorStringRef = NULL;
			
			// The following gives you an idea of how to filter out items when you have been notified a device you might
			// have an interest in has appeared. You can filter based on any properties in the IORegistry. As an example,
			// the following filters based on kIOPropertySCSIVendorIdentification with a field of "Apple". This is helpful
			// if you want to filter based on device type and several different vendors which your app supports. Just be sure
			// to release the io_service_t using IOObjectRelease if you choose to not support it, that way there won't be
			// a leak in the kernel.
			
			theVendorStringRef = ( CFStringRef ) CFDictionaryGetValue ( theDict, CFSTR ( kIOPropertySCSIVendorIdentification ) );
			
			#if FILTER_APPLE_PRODUCT_ID_ONLY
			
			if ( theVendorStringRef != NULL )
			{
				
				if ( CFStringCompare ( theVendorStringRef, CFSTR ( kAppleVendorString ), 0 ) == kCFCompareEqualTo )
				{
					
					// This is an Apple product because the strings match.
					TestDevice ( obj );
					
				}
				
			}
			
			#else
			
			TestDevice ( obj );
			
			#endif /* FILTER_APPLE_PRODUCT_ID_ONLY */
			
			CFRelease ( theDict );
			
		}
		
		( void ) IOObjectRelease ( obj );
		obj = IOIteratorNext ( iterator );
		
	}
	
}


//-----------------------------------------------------------------------------
//		DeviceDisappeared -  Callback for when a device disappears
//-----------------------------------------------------------------------------

static void
DeviceDisappeared ( void * refCon, io_iterator_t iterator )
{
	
	io_service_t	obj = IO_OBJECT_NULL;
	
	obj = IOIteratorNext ( iterator );
	while ( obj != IO_OBJECT_NULL )
	{
		
		printf ( "Device disappeared.\n" );
		( void ) IOObjectRelease ( obj );
		obj = IOIteratorNext ( iterator );
		
	}
	
}


//-----------------------------------------------------------------------------
//		StripWhiteSpace -  Strips whitespace characters from the end of a string
//-----------------------------------------------------------------------------

static void
StripWhiteSpace ( char * buffer, SInt32 length )
{
	
	SInt32		index = 0;
	
	for ( index = ( length - 1 ); index >= 0; index-- )
	{
		
		if ( buffer[index] != ' ' )
			break;
		
		buffer[index] = 0;
		
	}
	
}


//-----------------------------------------------------------------------------
//		SignalHandler -  Callback for signal handling
//-----------------------------------------------------------------------------

static void
SignalHandler ( int sigraised )
{
	
	printf ( "\nInterrupted\n" );
	
	// Clean up here
	if ( gNotifyPort != NULL )
	{
		
		IONotificationPortDestroy ( gNotifyPort );
		gNotifyPort = NULL;
		
	}
	
	if ( gAppearedIter != IO_OBJECT_NULL )
	{
		
		IOObjectRelease ( gAppearedIter );
		gAppearedIter = IO_OBJECT_NULL;
		
	}
	
	if ( gDisappearedIter != IO_OBJECT_NULL )
	{
		
		IOObjectRelease ( gDisappearedIter );
		gDisappearedIter = IO_OBJECT_NULL;
		
	}
	
	_exit ( 0 );
	
}
