/*
	File:			SimpleUserClientInterface.c
	
	Description:	Implements an abstraction layer between client applications and the user client.

	Copyright:		Copyright © 2007-2008 Apple Inc. All rights reserved.
	
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
			
            1.1			05/22/2007			Split out user client interface functions from main test tool.

*/


#include <AvailabilityMacros.h>
#include <IOKit/IOKitLib.h>
#include "SimpleUserClientInterface.h"

kern_return_t MyOpenUserClient(io_connect_t connect)
{
    // This calls the openUserClient method in SimpleUserClient inside the kernel. Though not mandatory, it's good
    // practice to use open and close semantics in your driver to prevent multiple user space applications from
    // using your driver at the same time.
    
	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallScalarMethod != NULL) {
		// ...and use it if it is.
#endif
		kernResult = IOConnectCallScalarMethod(connect, kMyUserClientOpen, NULL, 0, NULL, NULL);
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult = IOConnectMethodScalarIScalarO(connect, kMyUserClientOpen, 0, 0);
	}    
#endif
    
	return kernResult;
}


kern_return_t MyCloseUserClient(io_connect_t connect)
{
    // This calls the closeUserClient method in SimpleUserClient inside the kernel, which in turn closes
	// the driver.
    
	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallScalarMethod != NULL) {
		// ...and use it if it is.
#endif
		kernResult = IOConnectCallScalarMethod(connect, kMyUserClientClose, NULL, 0, NULL, NULL);
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult = IOConnectMethodScalarIScalarO(connect, kMyUserClientClose, 0, 0);
	}    
#endif

    return kernResult;
}


kern_return_t MyScalarIStructureI(io_connect_t connect, const uint32_t scalarI, 
								  const size_t structISize, const MySampleStruct* structI)
{
    // This calls the function ScalarIStructI in SimpleUserClient inside the kernel.
	    
	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallMethod != NULL) {
		// ...and use it if it is.
#endif
		uint64_t scalarI_64 = scalarI;

		kernResult = IOConnectCallMethod(connect,						// an io_connect_t returned from IOServiceOpen().
										 kMyScalarIStructIMethod,		// selector of the function to be called via the user client.
										 &scalarI_64,					// array of scalar (64-bit) input values.
										 1,								// the number of scalar input values.
										 structI,						// a pointer to the struct input parameter.
										 structISize,					// the size of the input structure parameter.
										 NULL,							// array of scalar (64-bit) output values.
										 NULL,							// pointer to the number of scalar output values.
										 NULL,							// pointer to the struct output parameter.
										 NULL							// pointer to the size of the output structure parameter.
										 );
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult =
			IOConnectMethodScalarIStructureI(connect,					// an io_connect_t returned from IOServiceOpen().
											 kMyScalarIStructIMethod,	// Index to the function to be called via the user client.
											 1,							// the number of scalar (32-bit) input values.
											 structISize,				// the size of the input structure parameter.
											 scalarI,					// a scalar input parameter.
											 structI					// pointer to the struct input parameter.
											 );
	}
#endif
    
    return kernResult;
}


kern_return_t MyScalarIStructureO(io_connect_t connect, const uint32_t scalarI_1, const uint32_t scalarI_2,
								  size_t* structOSize, MySampleStruct* structO)
{
    // This calls the function ScalarIStructureO in SimpleUserClient inside the kernel.

	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallMethod != NULL) {
		// ...and use it if it is.
#endif
		uint64_t	scalarI_64[2];
		
		scalarI_64[0] = scalarI_1;
		scalarI_64[1] = scalarI_2;
		
		kernResult = IOConnectCallMethod(connect,						// an io_connect_t returned from IOServiceOpen().
										 kMyScalarIStructOMethod,		// selector of the function to be called via the user client.
										 scalarI_64,					// array of scalar (64-bit) input values.
										 2,								// the number of scalar input values.
										 NULL,							// a pointer to the struct input parameter.
										 0,								// the size of the input structure parameter.
										 NULL,							// array of scalar (64-bit) output values.
										 NULL,							// pointer to the number of scalar output values.
										 structO,						// pointer to the struct output parameter.
										 structOSize					// pointer to the size of the output structure parameter.
										 );
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult =
			IOConnectMethodScalarIStructureO(connect,					// an io_connect_t returned from IOServiceOpen().
											 kMyScalarIStructOMethod,	// an index to the function to be called via the user client.
											 2,							// the number of scalar input values.
											 structOSize,				// the size of the struct output parameter.
											 scalarI_1,					// a scalar input parameter.
											 scalarI_2,					// another scalar input parameter.
											 structO					// a pointer to a struct output parameter.
											 );
	}
#endif
        
    return kernResult;
}


kern_return_t MyScalarIScalarO(io_connect_t connect, const uint32_t scalarI_1, const uint32_t scalarI_2, uint32_t* scalarO)
{
    // This calls the function ScalarIScalarO in SimpleUserClient inside the kernel.
    
	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallScalarMethod != NULL) {
		// ...and use it if it is.
#endif
		uint64_t	scalarI_64[2];
		uint64_t	scalarO_64;
		uint32_t	outputCount = 1; 
		
		scalarI_64[0] = scalarI_1;
		scalarI_64[1] = scalarI_2;
		
		kernResult = IOConnectCallScalarMethod(connect,					// an io_connect_t returned from IOServiceOpen().
											   kMyScalarIScalarOMethod,	// selector of the function to be called via the user client.
											   scalarI_64,				// array of scalar (64-bit) input values.
											   2,						// the number of scalar input values.
											   &scalarO_64,				// array of scalar (64-bit) output values.
											   &outputCount				// pointer to the number of scalar output values.
											   );
											   
		*scalarO = (uint32_t) scalarO_64;
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult =
			IOConnectMethodScalarIScalarO(connect,						// an io_connect_t returned from IOServiceOpen().
										  kMyScalarIScalarOMethod,		// an index to the function to be called via the user client.
										  2,							// the number of scalar input values.
										  1,							// the number of scalar output values.
										  scalarI_1,					// a scalar input parameter.
										  scalarI_2,					// another scalar input parameter.
										  scalarO						// a scalar output parameter.
										  );
	}
#endif

    return kernResult;
}


kern_return_t MyStructureIStructureO(io_connect_t connect, const size_t structISize, const MySampleStruct* structI,
									 size_t* structOSize, MySampleStruct* structO)
{
    // This calls the function StructureIStructureO in SimpleUserClient inside the kernel.
    
	kern_return_t	kernResult;
	
#if !defined(__LP64__)
	// Check if Mac OS X 10.5 API is available...
	if (IOConnectCallStructMethod != NULL) {
		// ...and use it if it is.
#endif
		kernResult = IOConnectCallStructMethod(connect,						// an io_connect_t returned from IOServiceOpen().
											   kMyStructIStructOMethod,		// selector of the function to be called via the user client.
											   structI,						// pointer to the input struct parameter.
											   structISize,					// the size of the input structure parameter.
											   structO,						// pointer to the output struct parameter.
											   structOSize					// pointer to the size of the output structure parameter.
											   );
#if !defined(__LP64__)
	}
	else {
		// Otherwise fall back to older API.
		kernResult =
			IOConnectMethodStructureIStructureO(connect,					// an io_connect_t returned from IOServiceOpen().
												kMyStructIStructOMethod,	// an index to the function to be called via the user client.
												structISize,				// the size of the input struct paramter.
												structOSize,				// a pointer to the size of the output struct paramter.
												(MySampleStruct*) structI,	// a pointer to the input struct parameter.
												structO						// a pointer to the output struct parameter.
												);
	}
#endif

    return kernResult;
}
