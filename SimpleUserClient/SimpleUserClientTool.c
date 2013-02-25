/*
	File:			SimpleUserClientTool.c
	
	Description:	This file shows how to communicate with an I/O Kit user client.

	Copyright:		Copyright © 2001-2008 Apple Inc. All rights reserved.
	
	Disclaimer:		IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
					("Apple") in consideration of your agreement to the following terms, and your
					use, installation, modification or redistribution of this Apple software
					constitutes acceptance of these terms.  If you do not agree with these terms,
					please do not use, install, modify or redistribute this Apple software.
					
					In consideration of your agreement to abide by the following terms, and subject
					to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
					copyrights in this original Apple software (the "Apple Software"), to use,
					reproduce, modify and redistribute the Apple Software, with or without
					modifications, in source and/or binary forms; provided that if you redistribute
					the Apple Software in its entirety and without modifications, you must retain
					this notice and the following text and disclaimers in all such redistributions of
					the Apple Software.  Neither the name, trademarks, service marks or logos of
					Apple Computer, Inc. may be used to endorse or promote products derived from the
					Apple Software without specific prior written permission from Apple.  Except as
					expressly stated in this notice, no other rights or licenses, express or implied,
					are granted by Apple herein, including but not limited to any patent rights that
					may be infringed by your derivative works or by other works in which the Apple
					Software may be incorporated.
					
					The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
					WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
					WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
					PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
					COMBINATION WITH YOUR PRODUCTS.
					
					IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
					CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
					GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
					ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
					OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
					(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
					ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):

            2.0			08/13/2008			Add Leopard user client API for supporting 64-bit user processes.
											Now requires Xcode 3.0 or later to build.
			
            1.1			05/22/2007			User client performs endian swapping when called from a user process 
											running using Rosetta. Updated to produce a universal binary.
											Now requires Xcode 2.2.1 or later to build.
			
			1.0d3	 	01/14/2003			New sample.

*/


#include <IOKit/IOKitLib.h>
#include <ApplicationServices/ApplicationServices.h>
#include "SimpleUserClientInterface.h"

#define kMyPathToSystemLog			"/var/log/system.log"

kern_return_t MyUserClientOpenExample(io_service_t service, io_connect_t *connect)
{
    // This call will cause the user client to be instantiated. It returns an io_connect_t handle
	// that is used for all subsequent calls to the user client.
    kern_return_t kernResult = IOServiceOpen(service, mach_task_self(), 0, connect);
	
    if (kernResult != KERN_SUCCESS) {
        fprintf(stderr, "IOServiceOpen returned 0x%08x\n", kernResult);
    }
	else {
		// This is an example of calling our user client's openUserClient method.
		kernResult = MyOpenUserClient(*connect);
			
		if (kernResult == KERN_SUCCESS) {
			printf("MyOpenUserClient was successful.\n\n");
		}
		else {
			fprintf(stderr, "MyOpenUserClient returned 0x%08x.\n\n", kernResult);
		}
    }
		
	return kernResult;
}


void MyUserClientCloseExample(io_connect_t connect)
{
	kern_return_t kernResult = MyCloseUserClient(connect);
        
    if (kernResult == KERN_SUCCESS) {
        printf("MyCloseUserClient was successful.\n\n");
    }
	else {
		fprintf(stderr, "MyCloseUserClient returned 0x%08x.\n\n", kernResult);
	}
    
    kernResult = IOServiceClose(connect);
    
    if (kernResult == KERN_SUCCESS) {
        printf("IOServiceClose was successful.\n\n");
    }
    else {
	    fprintf(stderr, "IOServiceClose returned 0x%08x\n\n", kernResult);
    }
}


void MyScalarIStructureIExample(io_connect_t connect)
{
    MySampleStruct	sampleStruct = { 586, 8756 };		// These are just a couple of random numbers.
    uint32_t		sampleNumber = 15;					// Another random number.
    
    kern_return_t kernResult = 
		MyScalarIStructureI(connect, sampleNumber, sizeof(MySampleStruct), &sampleStruct);
	    
    if (kernResult == KERN_SUCCESS) {
        printf("MyScalarIStructureI was successful.\n\n");
    }
	else {
		fprintf(stderr, "MyScalarIStructureI returned 0x%08x.\n\n", kernResult);
	}
}


void MyScalarIStructureOExample(io_connect_t connect)
{
    MySampleStruct	sampleStruct;
    uint32_t		sampleNumber1 = 154;	// This number is random.
    uint32_t		sampleNumber2 = 863;	// This number is random.
    size_t			structSize = sizeof(MySampleStruct); 
    
	kern_return_t kernResult =
		MyScalarIStructureO(connect, sampleNumber1, sampleNumber2, &structSize, &sampleStruct);
        
    if (kernResult == KERN_SUCCESS) {
        printf("MyScalarIStructureO was successful.\n");
        printf("field1 = %lld, field2 = %lld, structSize = %lu\n\n", sampleStruct.field1, sampleStruct.field2, structSize);
    }
	else {
		fprintf(stderr, "MyScalarIStructureO returned 0x%08x.\n\n", kernResult);
	}
}


void MyScalarIScalarOExample(io_connect_t connect)
{
    uint32_t	sampleNumber1 = 10;		// Random number with no meaning.
    uint32_t	sampleNumber2 = 32768;	// Another random number.
    uint32_t	resultNumber;
    
	kern_return_t kernResult =
		MyScalarIScalarO(connect, sampleNumber1, sampleNumber2, &resultNumber);
	
    if (kernResult == KERN_SUCCESS) {
        printf("MyScalarIScalarO was successful.\n");
        printf("resultNumber = %d\n\n", resultNumber);
    }
	else {
		fprintf(stderr, "MyScalarIScalarO returned 0x%08x.\n\n", kernResult);
	}
}


void MyStructureIStructureOExample(io_connect_t connect)
{
    MySampleStruct	sampleStruct1 = { 586, 8756 };	// These are random numbers I picked.
    MySampleStruct	sampleStruct2;
    size_t			structSize1 = sizeof(MySampleStruct);
    size_t			structSize2 = sizeof(MySampleStruct);
    
	kern_return_t kernResult =
		MyStructureIStructureO(connect, structSize1, &sampleStruct1, &structSize2, &sampleStruct2);    
    
	if (kernResult == KERN_SUCCESS) {
        printf("MyStructureIStructureO was successful.\n");
        printf("field1 = %lld, field2 = %lld, structSize = %lu\n\n", sampleStruct2.field1, sampleStruct2.field2, structSize2);
    }
	else {
		fprintf(stderr, "MyStructureIStructureO returned 0x%08x.\n\n", kernResult);
	}
}


void MyLaunchConsoleApp()
{
    CFURLRef pathRef;

    pathRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR(kMyPathToSystemLog), kCFURLPOSIXPathStyle, false);
    
    if (pathRef) {
        LSOpenCFURLRef(pathRef, NULL);
        CFRelease(pathRef);
    }
}


void TestUserClient(io_service_t service)
{
    kern_return_t				kernResult;
    io_connect_t				connect;

	// Instantiate a connection to the user client.
	kernResult = MyUserClientOpenExample(service, &connect);
	
	if (connect != IO_OBJECT_NULL) {	
		// Pass a scalar (int) parameter and a struct parameter to the user client.
		MyScalarIStructureIExample(connect);

		// Pass two scalar parameters to the user client and get a struct parameter back.
		MyScalarIStructureOExample(connect);
		
		// Pass two scalar parameters to the user client and get a scalar parameter back.
		MyScalarIScalarOExample(connect);
		
		// Pass a struct parameter to the user client and get a struct parameter back.
		MyStructureIStructureOExample(connect);
		
		// Close the user client and tear down the connection.
		MyUserClientCloseExample(connect);
	}
}


int main(int argc, char* argv[])
{
    kern_return_t	kernResult; 
    io_service_t	service;
    io_iterator_t 	iterator;
	bool			driverFound = false;
    
    // This will launch the Console.app so you can see the IOLogs from the kext.
    MyLaunchConsoleApp();

    // Look up the objects we wish to open. This example uses simple class
    // matching (IOServiceMatching()) to find instances of the class defined by the kext.
	//
	// Because Mac OS X has no weak-linking support in the kernel, the only way to
	// support mutually-exclusive KPIs is to provide separate kexts. This in turn means that the
	// separate kexts must have their own unique CFBundleIdentifiers and I/O Kit class names.
	//
	// This sample shows how to do this in the SimpleUserClient and SimpleUserClient_10.4 Xcode targets.
	//
	// From the userland perspective, a process must look for any of the class names it is prepared to talk to.
	
    // This creates an io_iterator_t of all instances of our driver that exist in the I/O Registry.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kSimpleDriverClassName), &iterator);
    
    if (kernResult != KERN_SUCCESS) {
        fprintf(stderr, "IOServiceGetMatchingServices returned 0x%08x\n\n", kernResult);
        return -1;
    }
        
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
		driverFound = true;
		printf("Found a device of class "kSimpleDriverClassName".\n\n");
		TestUserClient(service);
	}
    
    // Release the io_iterator_t now that we're done with it.
    IOObjectRelease(iterator);
    
    // Repeat the test on any instances of the Mac OS X 10.4 version of the driver.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kSimpleDriverClassName_10_4), &iterator);
    
    if (kernResult != KERN_SUCCESS) {
        fprintf(stderr, "IOServiceGetMatchingServices returned 0x%08x\n\n", kernResult);
        return -1;
    }
	
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
		driverFound = true;
		printf("Found a device of class "kSimpleDriverClassName_10_4".\n\n");
		TestUserClient(service);
	}
    
    // Release the io_iterator_t now that we're done with it.
    IOObjectRelease(iterator);
    
	if (driverFound == false) {
		fprintf(stderr, "No matching drivers found.\n");
	}

	return EXIT_SUCCESS;
}