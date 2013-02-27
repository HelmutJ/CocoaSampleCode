 /*

File:<windowSMARTs.m>

Abstract: <A demonstration of how to use S.M.A.R.T. monitoring>

Version: <1.0>

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#import "windowSMARTs.h"

#include <ctype.h>
#include <stdio.h>
#include <sys/param.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_init.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOReturn.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <CoreFoundation/CoreFoundation.h>

#define kATADefaultSectorSize                             512

@implementation windowSMARTs

#if defined(__BIG_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)
#elif defined(__LITTLE_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)				SwapASCIIString( ( UInt16 * ) x,y)
#else
#error Unknown endianness.
#endif

// This constant comes from the SMART specification.  Only 30 values are allowed in any of the structures.
#define kSMARTAttributeCount	30


typedef struct IOATASmartAttribute
{
    UInt8 			attributeId;
    UInt16			flag;  
    UInt8 			current;
    UInt8 			worst;
    UInt8 			rawvalue[6];
    UInt8 			reserv;
}  __attribute__ ((packed)) IOATASmartAttribute;

typedef struct IOATASmartVendorSpecificData
{
    UInt16 					revisonNumber;
    IOATASmartAttribute		vendorAttributes [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificData;

/* Vendor attribute of SMART Threshold */
typedef struct IOATASmartThresholdAttribute
{
    UInt8 			attributeId;
    UInt8 			ThresholdValue;
    UInt8 			Reserved[10];
} __attribute__ ((packed)) IOATASmartThresholdAttribute;

typedef struct IOATASmartVendorSpecificDataThresholds
{
    UInt16							revisonNumber;
    IOATASmartThresholdAttribute 	ThresholdEntries [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificDataThresholds;


void SwapASCIIString(UInt16 *buffer, UInt16 length)
{
	int	index;
	
	for ( index = 0; index < length / 2; index ++ ) {
		buffer[index] = OSSwapInt16 ( buffer[index] );
	}	
}


-(int) VerifyIdentifyData: (UInt16 *) buffer
{
	UInt8		checkSum		= -1;
	UInt32		index			= 0;
	UInt8 *		ptr				= ( UInt8 * ) buffer;
	
	require_string(((buffer[255] & 0x00FF) == kChecksumValidCookie), ErrorExit, "WARNING: Identify data checksum cookie not found");

	checkSum = 0;
		
	for (index = 0; index < 512; index++)
		checkSum += ptr[index];
	
ErrorExit:
	return checkSum;
}


- (BOOL) PrintIdentifyData: ( IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) smartResultsDict
{
	IOReturn	error				= kIOReturnSuccess;
	UInt8 *		buffer				= NULL;
	UInt32		length				= kATADefaultSectorSize;
	
	UInt16 *	words				= NULL;
	int			checksum			= 0;
	
	BOOL		isSMARTSupported	= NO;
	
	buffer = (UInt8 *) malloc(kATADefaultSectorSize);
	require_string((buffer != NULL), ErrorExit, "malloc(kATADefaultSectorSize) failed");
	
	bzero(buffer, kATADefaultSectorSize);
	
	error = (*smartInterface)->GetATAIdentifyData(	smartInterface,
													buffer,
													kATADefaultSectorSize,
													&length );
	
	require_string((error == kIOReturnSuccess), ErrorExit, "GetATAIdentifyData failed");

	checksum = [self VerifyIdentifyData:( UInt16 * ) buffer];
	require_string((checksum == 0), ErrorExit, "Identify data verified. Checksum is NOT correct");
	
	// Terminate the strings with 0's
	// This changes the identify data, so we MUST do this part last.
	buffer[94] = 0;
	buffer[40] = 0;
	
	// Model number runs from byte 54 to 93 inclusive - byte 94 is set to 
	// zero to terminate that string.
	SwapASCIIHostToBig (&buffer[54], 40);
	[smartResultsDict setObject:[NSString stringWithCString:(char *)&buffer[54] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsModelKeyString];
	
	// Now that we have made a deep copy of the model string, poke a 0 into byte 54 
	// in order to terminate the fw-vers string which runs from bytes 46 to 53 inclusive.
	buffer[54] = 0;
	
	SwapASCIIHostToBig (&buffer[46], 8);
	[smartResultsDict setObject:[NSString stringWithCString:(char *)&buffer[46] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsFirmwareKeyString];

	SwapASCIIHostToBig (&buffer[20], 20);
	[smartResultsDict setObject:[NSString stringWithCString:(char *)&buffer[20] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsSerialNumberKeyString];
	
	words = (UInt16 *) buffer;
	
	isSMARTSupported = words[kATAIdentifyCommandSetSupported] & kATASupportsSMARTMask;
		
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsSMARTMask] forKey:kWindowSMARTsSMARTSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsWriteCacheMask] forKey:kWindowSMARTsWriteCacheSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsPowerManagementMask] forKey:kWindowSMARTsPMSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsCompactFlashMask] forKey:kWindowSMARTsCFSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsAdvancedPowerManagementMask] forKey:kWindowSMARTsAPMSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupports48BitAddressingMask] forKey:kWindowSMARTs48BitAddressingSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsFlushCacheMask] forKey:kWindowSMARTsFlushCacheCommandSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsFlushCacheExtendedMask] forKey:kWindowSMARTsFlushCacheExtCommandSupportKeyString];
	[smartResultsDict setObject:[NSNumber numberWithInt:(words[kATAIdentifyQueueDepth] & 0x001F) + 1] forKey:kWindowSMARTsQueueDepthKeyString];
		
	if ((words[76] != 0) && (words[76] != 0xFFFF)) {
		[smartResultsDict setObject:[NSNumber numberWithBool:words[76] & (1 << 8)] forKey:kWindowSMARTsNCQSupportKeyString];
		[smartResultsDict setObject:[NSNumber numberWithBool:words[78] & (1 << 3)] forKey:kWindowSMARTsDeviceInitiatedPMKeyString];
		[smartResultsDict setObject:[NSNumber numberWithBool:words[76] & (1 << 9)] forKey:kWindowSMARTsHostInitiatedPMKeyString];
		[smartResultsDict setObject:[NSNumber numberWithFloat:( words[76] & (1 << 2) ) ? 3.0 : 1.5] forKey:kWindowSMARTsInterfaceSpeedKeyString];
	}
		
	if (((words[kATAIdentifyCommandSetSupported2] & (1 << 1)) == 0) && ((words[76] & (1 << 8)) == 0)) {
		require_string((words[kATAIdentifyQueueDepth] != 0), ErrorExit, "\n WARNING! Found inconsistency with queue depth!\n\n");
	}
	
ErrorExit:
	if (buffer)
		free(buffer);

	return isSMARTSupported;
}

-(void) PrintSMARTData:(IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) smartResultsDict
{
	
	IOReturn									error				= kIOReturnSuccess;
	Boolean										conditionExceeded	= false;
	ATASMARTData								smartData;
	IOATASmartVendorSpecificData				smartDataVendorSpecifics;
	ATASMARTDataThresholds						smartThresholds;
	IOATASmartVendorSpecificDataThresholds		smartThresholdVendorSpecifics;
	ATASMARTLogDirectory						smartLogDirectory;

	bzero(&smartData, sizeof(smartData));
	bzero(&smartDataVendorSpecifics, sizeof(smartDataVendorSpecifics));
	bzero(&smartThresholds, sizeof(smartThresholds));
	bzero(&smartThresholdVendorSpecifics, sizeof(smartThresholdVendorSpecifics));
	bzero(&smartLogDirectory, sizeof(smartLogDirectory));

	// Default the results for safety.
	[smartResultsDict setObject:[NSNumber numberWithBool:NO] forKey:kWindowSMARTsDeviceOkKeyString];


	// Start by enabling S.M.A.R.T. reporting for this disk.
	error = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableOperations failed");
	
	error = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableAutosave failed");


	// In most cases, this value will be all that you require.  As most of the
	// S.M.A.R.T reporting attributes are vendor-specific, the only part you can
	// always count on being implemented and accurate is the overall T.E.C
	// (Threshold Exceeded Condition) status report.
	error = (*smartInterface)->SMARTReturnStatus(smartInterface, &conditionExceeded);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTReturnStatus failed" );
	
	if (!conditionExceeded)
		[smartResultsDict setObject:[NSNumber numberWithBool:YES] forKey:kWindowSMARTsDeviceOkKeyString];


	// NOTE:
	// The rest of the diagnostics gathering involves using portions of the API that is considered
	// optional for a drive vendor to implement.  Most vendors now do, but be warned not to rely
	// on it.  In particular, the attribute codes are usually considered vendor specific and
	// proprietary, although some codes (ie. drive temperature) are almost always present.


	// Ask the device to start collecting S.M.A.R.T. data immediately.  We are not asking
	// for an extended test to be performed at this point
	error = (*smartInterface)->SMARTExecuteOffLineImmediate (smartInterface, false);
	if (error != kIOReturnSuccess)
		printf("SMARTExecuteOffLineImmediate failed: %s(%x)\n", mach_error_string(error), error);


	// Next, a demonstration of how to extract the raw S.M.A.R.T. data attributes.
	// A drive can report up to 30 of these, but all are optional.  Normal values
	// vary by vendor, although the property used for this demonstration always
	// reports in degrees celcius
	error = (*smartInterface)->SMARTReadData(smartInterface, &smartData);
	if (error != kIOReturnSuccess) {
		printf("SMARTReadData failed: %s(%x)\n", mach_error_string(error), error);
	} else {
		error = (*smartInterface)->SMARTValidateReadData(smartInterface, &smartData);
		if (error != kIOReturnSuccess) {
			printf("SMARTValidateReadData failed for attributes: %s(%x)\n", mach_error_string(error), error);
		} else {
			smartDataVendorSpecifics = *((IOATASmartVendorSpecificData *)&(smartData.vendorSpecific1));

			int currentAttributeIndex = 0;
			for (currentAttributeIndex = 0; currentAttributeIndex < kSMARTAttributeCount; currentAttributeIndex++) {
				IOATASmartAttribute currentAttribute = smartDataVendorSpecifics.vendorAttributes[currentAttributeIndex];
			
				// Grab and use the drive temperature if it's present.  Don't freak out if it isn't, as
				// this is an optional behaviour although most drives do support this.
				if (currentAttribute.attributeId == kWindowSMARTsDriveTempAttribute) {
					UInt8 temp = currentAttribute.rawvalue[0];
					[smartResultsDict setObject:[NSNumber numberWithUnsignedInt:temp] forKey:kWindowSMARTsDeviceTempKeyString];
					break;
				}
			}
		}
	}


	// Now, grab the corresponding threshold value(s) for the data attributes we have.  A
	// threshold of zero for temperature indicates that this is not used as part of the
	// T.E.C. calculations.
	error = (*smartInterface)->SMARTReadDataThresholds(smartInterface, &smartThresholds);
	if (error != kIOReturnSuccess) {
		printf("SMARTReadDataThresholds failed for threshold data: %s(%x)\n", mach_error_string(error), error);
	} else {
		// The validation scheme used by S.M.A.R.T. is a checksum byte added to the end to make
		// the entire block add to 0x00.  This validation works for both the attribute data and
		// the threshold data, although the prototype for SMARTValidateReadData takes a pointer
		// to a ATASMARTData structure.  As a result, we can safely call it here with a typecast.
		error = (*smartInterface)->SMARTValidateReadData(smartInterface, (ATASMARTData *)&smartThresholds);
		if (error != kIOReturnSuccess) {
			printf("SMARTValidateReadData failed for threshold data: %s(%x)\n", mach_error_string(error), error);
		} else {
			smartThresholdVendorSpecifics = *((IOATASmartVendorSpecificDataThresholds *)&(smartThresholds.vendorSpecific1));

			int currentAttributeIndex = 0;
			for (currentAttributeIndex = 0; currentAttributeIndex < kSMARTAttributeCount; currentAttributeIndex++) {
				IOATASmartThresholdAttribute currentAttribute = smartThresholdVendorSpecifics.ThresholdEntries[currentAttributeIndex];
			
				// Grab and use the drive temperature if it's present.  Don't freak out if it isn't, as
				// this is an optional behaviour although most drives do support this
				if (currentAttribute.attributeId == kWindowSMARTsDriveTempAttribute) {
					UInt8 temp = currentAttribute.ThresholdValue;
					[smartResultsDict setObject:[NSNumber numberWithUnsignedInt:temp] forKey:kWindowSMARTsDeviceTempThresholdKeyString];
				}
			}
		}
	}


ErrorExit:
	// Now that we're done, shut down the S.M.A.R.T.  If we don't, storage takes a big performance hit.
	// We should be able to ignore any error conditions here safely
	error = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, false);
	error = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, false);
}

- (io_service_t) GetDeviceObject: (io_service_t) object
{
	
	io_service_t			service 	= IO_OBJECT_NULL;
	io_service_t			temp		= IO_OBJECT_NULL;
	io_service_t			parent 		= IO_OBJECT_NULL;
	IOReturn				status		= kIOReturnSuccess;
	NSMutableDictionary		*property	= nil;
	
	property = (NSMutableDictionary *) IORegistryEntrySearchCFProperty (
					object,
					kIOServicePlane,
					CFSTR(kIOPropertySMARTCapableKey),
					kCFAllocatorDefault,
					kNilOptions );
	
	if (property) {
		IOObjectRetain(object);
		service = object;
		[property release];
		goto Exit;
	}
	
	status = IORegistryEntryGetParentEntry (object, kIOServicePlane, &parent);
	require_string((status == kIOReturnSuccess), Exit, "IORegistryGetParentEntry failed");
	
	while (true) {
		temp = parent;
		
		property = (NSMutableDictionary *) IORegistryEntrySearchCFProperty (
				temp,
				kIOServicePlane,
				CFSTR(kIOPropertySMARTCapableKey),
				kCFAllocatorDefault,
				kNilOptions );
		
		if (property) {
			service = temp;
			[property release];
			break;
		}
		
		status = IORegistryEntryGetParentEntry(temp, kIOServicePlane, &parent);
		IOObjectRelease(temp);
		
		if (status != kIOReturnSuccess)
			break;
	}
	
Exit:
	return service;
}

- (IOReturn) PerformSMARTUnitTest:(io_service_t) object
{
	io_service_t				service				= IO_OBJECT_NULL;			
	IOCFPlugInInterface **		cfPlugInInterface	= NULL;
	IOATASMARTInterface **		smartInterface		= NULL;
	SInt32						score				= 0;
	HRESULT						herr				= S_OK;
	IOReturn					err					= kIOReturnSuccess;
	NSMutableDictionary *		smartResultsDict	= [[NSMutableDictionary alloc] initWithCapacity:16];
	
	// Under 10.4.8 and higher, we can use the presence of the "SMART Capable" key to find the top-most entry
	// in the registry for each device and query that.
	service = [self GetDeviceObject: object];
	
#if 0
	// If you know you're going to be running only on 10.4.8 or higher, you could do this
	require_string((service != IO_OBJECT_NULL), ErrorExit, "unable to obtain service using [self GetDeviceObject]");
#else
	// As a fall-back, this will help you work on pre-10.4.8 systems as well.
	if (!service)
		service = object;
#endif
	
	err = IOCreatePlugInInterfaceForService (	service,
												kIOATASMARTUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&cfPlugInInterface,
												&score );
	
	require_string ( ( err == kIOReturnSuccess ), ErrorExit,
					 "IOCreatePlugInInterfaceForService failed" );
	
	herr = ( *cfPlugInInterface )->QueryInterface (
										cfPlugInInterface,
										CFUUIDGetUUIDBytes ( kIOATASMARTInterfaceID ),
										( LPVOID ) &smartInterface );
	
	require_string ( ( herr == S_OK ), DestroyPlugIn,
					 "QueryInterface failed" );
	
	// Grab any identifying data we can on this device and then, if it supports S.M.A.R.T.,
	// qurey the S.M.A.R.T. monitoring subsystem for status information
	if ([self PrintIdentifyData:smartInterface withResultsDict:smartResultsDict])
		[self PrintSMARTData:smartInterface withResultsDict:smartResultsDict];

	[foundDevices addObject:smartResultsDict];
	[smartResultsDict release];
	
	( *smartInterface )->Release ( smartInterface );
	smartInterface = NULL;

DestroyPlugIn:
	IODestroyPlugInInterface ( cfPlugInInterface );
	cfPlugInInterface = NULL;

ErrorExit:
	return err;
	
}

- (id) init
{
	self = [super init];
	if (self) {
		foundDevices = [[NSMutableArray alloc] initWithCapacity:64];
		
		if (!foundDevices) {
			[self dealloc];
			self = nil;
		}
	}
	
	return self;
}

-(void) awakeFromNib
{
	IOReturn				error 			= kIOReturnSuccess;
	NSMutableDictionary		*matchingDict	= [[NSMutableDictionary alloc] initWithCapacity:8];
	NSMutableDictionary 	*subDict		= [[NSMutableDictionary alloc] initWithCapacity:8];
	io_iterator_t			iter			= IO_OBJECT_NULL;
	io_object_t				obj				= IO_OBJECT_NULL;
	
	//
	//	Note: We are setting up a matching dictionary which looks like the following:
	//
	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SMART Capable</key>
	//			<true/>
	//		</dict>
	// </dict>
	//
	
	// Create a dictionary with the "SMART Capable" key = true
	[subDict setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithCString:kIOPropertySMARTCapableKey]];
	
	// Add the dictionary to the main dictionary with the key "IOPropertyMatch" to
	// narrow the search to the above dictionary.
	[matchingDict setObject:subDict forKey:[NSString stringWithCString:kIOPropertyMatchKey]];
	
	[subDict release];
	subDict = NULL;

	// Remember - this call eats one reference to the matching dictionary.  In this case, removing the need to release it later
	error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
	if (error != kIOReturnSuccess) {
		printf("Error finding SMART Capable disks: %s(%x)\n", mach_error_string(error), error);
	} else {
		while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {		
			error = [self PerformSMARTUnitTest:obj];
			IOObjectRelease(obj);
		}
	}

	// OK, now if that search was unable to locate any devices, then either we don't have any or
	// we're running on a system older than 10.4.8.  This method will work for older installs
	// NOTE: This will locate all ATA storage devices, including ones that do not support S.M.A.R.T.
	// You will need to check the indentification data for the ATA Supports SMART bit.  This is
	// Done above in PrintIdentifyData and the result stored in the dicitonary for this device as
	// "SMART Supported"
	if ([foundDevices count] == 0) {
		iter			= IO_OBJECT_NULL;
		matchingDict	= (NSMutableDictionary *)IOServiceMatching("IOATABlockStorageDevice");

		// Remember - this call eats one reference to the matching dictionary.  In this case, removing the need to release it later
		error = IOServiceGetMatchingServices (kIOMasterPortDefault, (CFDictionaryRef)matchingDict, &iter);
		if (error != kIOReturnSuccess) {
			printf("Error finding SMART Capable disks the old way: %s(%x)\n", mach_error_string(error), error);
		} else {
			while ((obj = IOIteratorNext(iter)) != IO_OBJECT_NULL) {		
				error = [self PerformSMARTUnitTest:obj];
				IOObjectRelease(obj);
			}
		}
	}
	
	IOObjectRelease(iter);
	iter = IO_OBJECT_NULL;
	
	[deviceArrayController setContent:foundDevices];
}

- (void) dealloc
{
	[foundDevices release];
	[super dealloc];
}

@end
