//     File: main.m
// Abstract: Main file supporting the startup of the Virtual Scanner.
//  Version: 1.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2012 Apple Inc. All Rights Reserved.
// 

#import <sys/stat.h>
#import <pthread.h>
#import "EntryPoints.h"

//----------------------------------------------------------------------------------------------------------------------

pthread_mutex_t       _gScannersMutex       = PTHREAD_MUTEX_INITIALIZER;
NSMutableDictionary*  _gScannersDictionary  = NULL;
BOOL                  _gIsVirtualScanner    = NO;
DASessionRef          _gDiskArbSession      = NULL;
extern int            gArgc;
extern char*          gArgv[10];

//----------------------------------------------------------------------------------------------------------------------

int main(int argc, char *argv[])
{
    int status          = 0;
    int option          = 0;
    char tempStr[256]   = {0};
    
    while( ( option = getopt( argc, argv, "d:") ) != -1 )
    {
        switch ( option )
        {
            case 'd':
                tempStr[0] = 0;
                strlcpy( tempStr, optarg, 31 );
                gArgc       = 2;
                gArgv[0]    = argv[0];
                gArgv[1]    = strdup( tempStr );
            break;
        }
    }
    
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenUSBDevice                   = _ICD_ScannerOpenUSBDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenFireWireDeviceWithIORegPath = _ICD_ScannerOpenFWDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenTCPIPDevice                 = _ICD_ScannerOpenTCPIPDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerCloseDevice                     = _ICD_ScannerCloseDevice;
    gICDScannerCallbackFunctions.f_ICD_ScannerPeriodicTask                    = _ICD_ScannerPeriodicTask;
    gICDScannerCallbackFunctions.f_ICD_ScannerGetObjectInfo                   = _ICD_ScannerGetObjectInfo;
    gICDScannerCallbackFunctions.f_ICD_ScannerCleanup                         = _ICD_ScannerCleanup;
    gICDScannerCallbackFunctions.f_ICD_ScannerGetPropertyData                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerSetPropertyData                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerReadFileData                    = _ICD_ScannerReadFileData;
    gICDScannerCallbackFunctions.f_ICD_ScannerWriteDataToFile                 = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerWriteFileData                   = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerSendMessage                     = _ICD_ScannerSendMessage;
    gICDScannerCallbackFunctions.f_ICD_ScannerAddPropertiesToCFDictionary     = _ICD_ScannerAddPropertiesToCFDictionary;
    
    gICDScannerCallbackFunctions.f_ICD_ScannerOpenSession                     = _ICD_ScannerOpenSession;
    gICDScannerCallbackFunctions.f_ICD_ScannerCloseSession                    = _ICD_ScannerCloseSession;
    gICDScannerCallbackFunctions.f_ICD_ScannerInitialize                      = NULL;   // Unused
    gICDScannerCallbackFunctions.f_ICD_ScannerGetParameters                   = _ICD_ScannerGetParameters;
    gICDScannerCallbackFunctions.f_ICD_ScannerSetParameters                   = _ICD_ScannerSetParameters;
    gICDScannerCallbackFunctions.f_ICD_ScannerStatus                          = _ICD_ScannerStatus;
    gICDScannerCallbackFunctions.f_ICD_ScannerStart                           = _ICD_ScannerStart;
    
    if ( _gScannersDictionary == NULL )
        _gScannersDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];

    CFBundleRef bundle    = CFBundleGetMainBundle();
    NSString*   bundleID  = (NSString*)CFBundleGetIdentifier( bundle );
    
    _gIsVirtualScanner = [bundleID isEqualToString:@"com.apple.VirtualScanner"];
    
    if ( _gIsVirtualScanner )
    {
        _gDiskArbSession = DASessionCreate( kCFAllocatorDefault );
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
        DASessionScheduleWithRunLoop( _gDiskArbSession, CFRunLoopGetMain(), kCFRunLoopDefaultMode );
#else
        DASessionSetDispatchQueue( _gDiskArbSession, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul ) );
#endif
    }
    
    status = ICD_ScannerMain(argc, (const char **)argv);
    
    if ( _gDiskArbSession )
    {
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
        DASessionUnscheduleFromRunLoop( _gDiskArbSession, CFRunLoopGetMain(), kCFRunLoopDefaultMode );
#else
        DASessionSetDispatchQueue( _gDiskArbSession, NULL );
#endif
        CFRelease( _gDiskArbSession );
        _gDiskArbSession = NULL;
    }
    
    pthread_mutex_lock( &_gScannersMutex );
    [_gScannersDictionary release];
    pthread_mutex_unlock( &_gScannersMutex );
    pthread_mutex_destroy( &_gScannersMutex );
    
    return status;
}

//----------------------------------------------------------------------------------------------------------------------
