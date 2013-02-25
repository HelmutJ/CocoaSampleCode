//
// File:		AppleSamplePCIShared.h
//
// Abstract:	Shared header that defines the data structures we can use to
//				communicate between our kext and our userland client>
//
// Version:		2.0
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//

// Have to be careful regarding the alignment of structures since
// this file is shared between 32 bit kernel code and 32 or 64 bit
// user level code. 
// See http://developer.apple.com/documentation/Darwin/Conceptual/64bitPorting/index.html

// Structures in this file are aligned naturally by ordering any 64 bit quantities first.
// #pragma pack could also be used to force alignment

enum {
    kSampleMethod1 = 0,
    kSampleMethod2 = 1,
    kSampleMethod3 = 2,
    kSampleNumMethods
};

// To avoid invisible compiler padding, align fields on 64-bit boundaries when possible
// and make the whole structure's size a multiple of 64 bits.
typedef struct SampleStructForMethod2 {
    uint64_t		data_pointer; // Use C99 types to ensure desired size without unexpected truncation of 64-bit quantities.
    uint64_t		data_length;
    uint32_t		parameter1;
    uint32_t		__pad;
} SampleStructForMethod2;

typedef struct SampleResultsForMethod2 {
    uint64_t		results1;
} SampleResultsForMethod2;

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#define SamplePCIClassName	com_YourCompany_driver_SamplePCI_10_4
#else
#define SamplePCIClassName	com_YourCompany_driver_SamplePCI
#endif

#define kSamplePCIClassName			"com_YourCompany_driver_SamplePCI"
#define kSamplePCIClassName_10_4	"com_YourCompany_driver_SamplePCI_10_4"

// types for IOServiceOpen()
enum {
    kSamplePCIConnectType = 23
};

// types for IOConnectMapMemory()
enum {
    kSamplePCIMemoryType1 = 100,
    kSamplePCIMemoryType2 = 101,
};

// memory structure to be shared between the kernel and userland.
typedef struct SampleSharedMemory {
    uint32_t	field1;
    uint32_t	field2;
    uint32_t	field3;
    char		string[100];
} SampleSharedMemory;

#define kMyDisplayBrightnessKey	"brightness"
#define kMyDisplayParametersKey	"DisplayParameters"
#define kMyDisplayValueKey		"value"
#define kMyPropertyKey			"MyProperty"