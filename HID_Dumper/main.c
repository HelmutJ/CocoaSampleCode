/*
     File: main.c
 Abstract: main source code to HID Dumper
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

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

//#include <IOKit/hid/IOHIDLib.h>
#include "HID_Utilities_External.h"

// ****************************************************
#pragma mark -
#pragma mark * typedef's, struct's, enums, defines, etc. *

// ----------------------------------------------------

int main ( int argc, const char * argv[] )
{
#pragma unused ( argc, argv )
	
	Boolean dumpElements = false;
	
	if ( argc >= 2) {
		char elements_param[] = "-elements";
		if (0 == strncmp(argv[1], elements_param, strlen(elements_param))) {
			dumpElements = true;
		} else {
			printf("usage: %s [-elements]\n", argv[0]);
			return -1;
		}
	}
	
	IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
	require( tIOHIDManagerRef, Oops );
	
	IOHIDManagerSetDeviceMatching( tIOHIDManagerRef, NULL );
	
	IOReturn tIOReturn = IOHIDManagerOpen( tIOHIDManagerRef, kIOHIDOptionsTypeNone );
	require_noerr( tIOReturn, Oops );
	
	CFSetRef deviceCFSetRef = IOHIDManagerCopyDevices( tIOHIDManagerRef );
	require( deviceCFSetRef, Oops );
	
	CFIndex deviceIndex, deviceCount = CFSetGetCount( deviceCFSetRef );
	
	IOHIDDeviceRef * tIOHIDDeviceRefs = malloc( sizeof( IOHIDDeviceRef ) * deviceCount );
	require( tIOHIDDeviceRefs, Oops );
	
	CFSetGetValues( deviceCFSetRef, ( const void ** )tIOHIDDeviceRefs );
	
	for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ ) {
		// open it
		tIOReturn = IOHIDDeviceOpen( tIOHIDDeviceRefs[deviceIndex], kIOHIDOptionsTypeNone );
		require_noerr( tIOReturn, next_device );
		
		HIDDumpDeviceInfo( tIOHIDDeviceRefs[deviceIndex] );
		
		if (dumpElements) {
			// and copy all the elements
			CFArrayRef elementCFArrayRef = IOHIDDeviceCopyMatchingElements( tIOHIDDeviceRefs[deviceIndex],
																		   NULL /* matchingCFDictRef */,
																		   kIOHIDOptionsTypeNone );
			require( elementCFArrayRef, next_device );
			
			// iterate over all the elements
			CFIndex elementIndex, elementCount = CFArrayGetCount( elementCFArrayRef );
			for ( elementIndex = 0; elementIndex < elementCount; elementIndex++ ) {
				IOHIDElementRef tIOHIDElementRef = ( IOHIDElementRef )CFArrayGetValueAtIndex( elementCFArrayRef, elementIndex );
				require( tIOHIDElementRef, next_element );
				
				HIDDumpElementInfo( tIOHIDElementRef );
			next_element:   ;
				continue;
			}
			CFRelease( elementCFArrayRef );
		}
	next_device: ;
		( void )IOHIDDeviceClose( tIOHIDDeviceRefs[deviceIndex], kIOHIDOptionsTypeNone );
		continue;
	}
	
	if ( tIOHIDManagerRef ) {
		CFRelease( tIOHIDManagerRef );
	}
Oops:   ;
	return 0;
}
