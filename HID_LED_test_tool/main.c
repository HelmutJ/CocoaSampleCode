//
//	File:		main.c
//
//	Contains:	main source code to HID LED test tool
//
//	Copyright:	Copyright (c) 2007 Apple Inc., All Rights Reserved
//
//	Disclaimer: IMPORTANT:	This Apple software is supplied to you by
//				Apple Inc. ("Apple") in consideration of your agreement to the
//				following terms, and your use, installation, modification or
//				redistribution of this Apple software constitutes acceptance of these
//				terms.	If you do not agree with these terms, please do not use,
//				install, modify or redistribute this Apple software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non-exclusive
//				license, under Apple's copyrights in this original Apple software (the
//				"Apple Software"), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and/or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following
//				text and disclaimers in all such redistributions of the Apple Software.
//				Neither the name, trademarks, service marks or logos of Apple Inc.
//				may be used to endorse or promote products derived from the Apple
//				Software without specific prior written permission from Apple.	Except
//				as expressly stated in this notice, no other rights or licenses, express
//				or implied, are granted by Apple herein, including but not limited to
//				any patent rights that may be infringed by your derivative works or by
//				other works in which the Apple Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//				MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//				THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//				FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//				OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//				OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//				MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//				AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//				STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//				POSSIBILITY OF SUCH DAMAGE.
//
// ****************************************************
#pragma mark -
#pragma mark * complation directives *
// ----------------------------------------------------

#ifndef FALSE
#define FALSE 0
#define TRUE !FALSE
#endif

// ****************************************************
#pragma mark -
#pragma mark * includes & imports *
// ----------------------------------------------------

#include <CoreFoundation/CoreFoundation.h>
#include <Carbon/Carbon.h>
#include <IOKit/hid/IOHIDLib.h>

// ****************************************************
#pragma mark -
#pragma mark * typedef's, struct's, enums, defines, etc. *
// ----------------------------------------------------
// function to create a matching dictionary for usage page & usage
static CFMutableDictionaryRef hu_CreateMatchingDictionaryUsagePageUsage( Boolean isDeviceNotElement,
																		UInt32 inUsagePage,
																		UInt32 inUsage )
{
	// create a dictionary to add usage page / usages to
	CFMutableDictionaryRef result = CFDictionaryCreateMutable( kCFAllocatorDefault,
															  0,
															  &kCFTypeDictionaryKeyCallBacks,
															  &kCFTypeDictionaryValueCallBacks );
	
	if ( result ) {
		if ( inUsagePage ) {
			// Add key for device type to refine the matching dictionary.
			CFNumberRef pageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsagePage );
			
			if ( pageCFNumberRef ) {
				if ( isDeviceNotElement ) {
					CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsagePageKey ), pageCFNumberRef );
				} else {
					CFDictionarySetValue( result, CFSTR( kIOHIDElementUsagePageKey ), pageCFNumberRef );
				}
				CFRelease( pageCFNumberRef );
				
				// note: the usage is only valid if the usage page is also defined
				if ( inUsage ) {
					CFNumberRef usageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsage );
					
					if ( usageCFNumberRef ) {
						if ( isDeviceNotElement ) {
							CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsageKey ), usageCFNumberRef );
						} else {
							CFDictionarySetValue( result, CFSTR( kIOHIDElementUsageKey ), usageCFNumberRef );
						}
						CFRelease( usageCFNumberRef );
					} else {
						fprintf( stderr, "%s: CFNumberCreate( usage ) failed.", __PRETTY_FUNCTION__ );
					}
				}
			} else {
				fprintf( stderr, "%s: CFNumberCreate( usage page ) failed.", __PRETTY_FUNCTION__ );
			}
		}
	} else {
		fprintf( stderr, "%s: CFDictionaryCreateMutable failed.", __PRETTY_FUNCTION__ );
	}
	return result;
}	// hu_CreateMatchingDictionaryUsagePageUsage

int main( int argc, const char * argv[] )
{
#pragma unused ( argc, argv )
	
	// create a IO HID Manager reference
	IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
	require( tIOHIDManagerRef, Oops );
	
	// Create a device matching dictionary
	CFDictionaryRef matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( TRUE,
																				  kHIDPage_GenericDesktop,
																				  kHIDUsage_GD_Keyboard );
	require( matchingCFDictRef, Oops );
	
	// set the HID device matching dictionary
	IOHIDManagerSetDeviceMatching( tIOHIDManagerRef, matchingCFDictRef );
	
	if ( matchingCFDictRef ) {
		CFRelease( matchingCFDictRef );
	}
	
	// Now open the IO HID Manager reference
	IOReturn tIOReturn = IOHIDManagerOpen( tIOHIDManagerRef, kIOHIDOptionsTypeNone );
	require_noerr( tIOReturn, Oops );
	
	// and copy out its devices
	CFSetRef deviceCFSetRef = IOHIDManagerCopyDevices( tIOHIDManagerRef );
	require( deviceCFSetRef, Oops );
	
	// how many devices in the set?
	CFIndex deviceIndex, deviceCount = CFSetGetCount( deviceCFSetRef );
	
	// allocate a block of memory to extact the device ref's from the set into
	IOHIDDeviceRef * tIOHIDDeviceRefs = malloc( sizeof( IOHIDDeviceRef ) * deviceCount );
	require( tIOHIDDeviceRefs, Oops );
	
	// now extract the device ref's from the set
	CFSetGetValues( deviceCFSetRef, (const void **) tIOHIDDeviceRefs );
	
	// before we get into the device loop we'll setup our element matching dictionary
	matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( FALSE, kHIDPage_LEDs, 0 );
	require( matchingCFDictRef, Oops );
	
	int pass;	// do 256 passes
	for ( pass = 0; pass < 256; pass++ ) {
		Boolean delayFlag = FALSE;	// if we find an LED element we'll set this to TRUE
		
		printf( "pass = %d.\n", pass );
		for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ ) {
			
			// if this isn't a keyboard device...
			if ( !IOHIDDeviceConformsTo( tIOHIDDeviceRefs[deviceIndex], kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard ) ) {
				continue;	// ...skip it
			}
			
			printf( "	 device = %p.\n", tIOHIDDeviceRefs[deviceIndex] );
			
			// copy all the elements
			CFArrayRef elementCFArrayRef = IOHIDDeviceCopyMatchingElements( tIOHIDDeviceRefs[deviceIndex],
																		   matchingCFDictRef,
																		   kIOHIDOptionsTypeNone );
			require( elementCFArrayRef, next_device );
			
			// for each device on the system these values are divided by the value ranges of all LED elements found
			// for example, if the first four LED element have a range of 0-1 then the four least significant bits of 
			// this value will be sent to these first four LED elements, etc.
			int device_value = pass;
			
			// iterate over all the elements
			CFIndex elementIndex, elementCount = CFArrayGetCount( elementCFArrayRef );
			for ( elementIndex = 0; elementIndex < elementCount; elementIndex++ ) {
				IOHIDElementRef tIOHIDElementRef = ( IOHIDElementRef ) CFArrayGetValueAtIndex( elementCFArrayRef, elementIndex );
				require( tIOHIDElementRef, next_element );
				
				uint32_t usagePage = IOHIDElementGetUsagePage( tIOHIDElementRef );
				
				// if this isn't an LED element...
				if ( kHIDPage_LEDs != usagePage ) {
					continue;	// ...skip it
				}
				
				uint32_t usage = IOHIDElementGetUsage( tIOHIDElementRef );
				IOHIDElementType tIOHIDElementType = IOHIDElementGetType( tIOHIDElementRef );
				
				printf( "		 element = %p (page: %d, usage: %d, type: %d ).\n",
					   tIOHIDElementRef, usagePage, usage, tIOHIDElementType );
				
				// get the logical mix/max for this LED element
				CFIndex minCFIndex = IOHIDElementGetLogicalMin( tIOHIDElementRef );
				CFIndex maxCFIndex = IOHIDElementGetLogicalMax( tIOHIDElementRef );
				
				// calculate the range
				CFIndex modCFIndex = maxCFIndex - minCFIndex + 1;
				
				// compute the value for this LED element
				CFIndex tCFIndex = minCFIndex + ( device_value % modCFIndex );
				device_value /= modCFIndex;
				
				printf( "			 value = 0x%08lX.\n", tCFIndex );
				
				uint64_t timestamp = 0; // create the IO HID Value to be sent to this LED element
				IOHIDValueRef tIOHIDValueRef = IOHIDValueCreateWithIntegerValue( kCFAllocatorDefault, tIOHIDElementRef, timestamp, tCFIndex );
				if ( tIOHIDValueRef ) {
					// now set it on the device
					tIOReturn = IOHIDDeviceSetValue( tIOHIDDeviceRefs[deviceIndex], tIOHIDElementRef, tIOHIDValueRef );
					CFRelease( tIOHIDValueRef );
					require_noerr( tIOReturn, next_element );
					delayFlag = TRUE;	// set this TRUE so we'll delay before changing our LED values again
				}
			next_element:	;
				continue;
			}
		next_device: ;
			CFRelease( elementCFArrayRef );
			continue;
		}
		
		// if we found an LED we'll delay before continuing
		if ( delayFlag ) {
			usleep( 500000 ); // sleep one half second
		}
	}						  // next pass
	
	if ( tIOHIDManagerRef ) {
		CFRelease( tIOHIDManagerRef );
	}
	
	if ( matchingCFDictRef ) {
		CFRelease( matchingCFDictRef );
	}
Oops:	;
	return 0;
} /* main */
