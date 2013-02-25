/*
	File:			UserKernelShared.h

	Description:	Definitions shared between SimpleUserClient (kernel) and SimpleUserClientTool (userland).

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
			
            1.1			05/22/2007			Perform endian swapping when called from a user process running
											under Rosetta. Updated to produce a universal binary. Now requires
											Xcode 2.2.1 or later to build.
			
			1.0d3	 	01/14/2003			New sample.

*/

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#define SimpleDriverClassName		com_apple_dts_driver_SimpleDriver_10_4
#else
#define SimpleDriverClassName		com_apple_dts_driver_SimpleDriver
#endif

#define kSimpleDriverClassName		"com_apple_dts_driver_SimpleDriver"
#define kSimpleDriverClassName_10_4	"com_apple_dts_driver_SimpleDriver_10_4"

// Data structure passed between the tool and the user client. This structure and its fields need to have
// the same size and alignment between the user client, 32-bit processes, and 64-bit processes.
// To avoid invisible compiler padding, align fields on 64-bit boundaries when possible
// and make the whole structure's size a multiple of 64 bits.

typedef struct MySampleStruct {
    uint64_t field1;	
    uint64_t field2;
} MySampleStruct;


// User client method dispatch selectors.
enum {
    kMyUserClientOpen,
    kMyUserClientClose,
    kMyScalarIStructIMethod,
    kMyScalarIStructOMethod,
    kMyScalarIScalarOMethod,
    kMyStructIStructOMethod,
    kNumberOfMethods // Must be last 
};
