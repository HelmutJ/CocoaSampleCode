//     File: EntryPoints.m
// Abstract: n/a
//  Version: 1.2
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
#import "VirtualScanner.h"

extern DASessionRef         _gDiskArbSession;
extern pthread_mutex_t      _gScannersMutex;
extern NSMutableDictionary* _gScannersDictionary;
extern BOOL                 _gIsVirtualScanner;

extern int                  gArgc;
extern char*                gArgv[10];

UInt32  LocationIDOfMatchingUSBDevice( void );

#pragma mark -

//------------------------------------------------------------------------------------- GetLocationIDOfMatchingUSBDevice
// Utility function to find a relevant USB device connected to the Mac

UInt32
LocationIDOfMatchingUSBDevice()
{
    UInt32        locationID  = 0;
    io_iterator_t iterator    = 0;
    
    if ( IOServiceGetMatchingServices( kIOMasterPortDefault, IOServiceMatching( kIOUSBDeviceClassName ), &iterator ) == kIOReturnSuccess )
    {
        BOOL          found     = NO;
        io_service_t  interface = 0;
        
        while ( ( interface = IOIteratorNext( iterator ) ) && !found )
        {
            NSMutableDictionary*  objProps  = NULL;
            
            if ( IORegistryEntryCreateCFProperties( interface, (CFMutableDictionaryRef*)&objProps, kCFAllocatorDefault, 0 ) == kIOReturnSuccess )
            {
                // Check to see if this is your device
                /*
				unsigned short  idVendor  = [[objProps objectForKey:@"idVendor"] unsignedShortValue];
				unsigned short  idProduct = [[objProps objectForKey:@"idProduct"] unsignedShortValue];
                
                if ( ( idVendor == yourDeviceVendorID ) && ( idProduct == yourDeviceProductID ) )
                {
                    locationID  = [[objProps objectForKey:@"locationID"] unsignedIntValue];
                    found       = YES;
                }
                */
            }
            
            [objProps release];
            IOObjectRelease( interface );
        }

        IOObjectRelease( iterator );
    }
    
    return locationID;
}


//----------------------------------------------------------------------------------------------- _ICD_ScannerOpenDevice
/* 
   This function is usually called when a USB device is attached to the Macintosh.
   This function is also called when the device module is executed via Xcode. In the latter case,
   the value of locationID passed to this function is set to 0.
*/
 
ICAError
_ICD_ScannerOpenUSBDevice(
    UInt32              locationID, 
    ScannerObjectInfo*  newDeviceObjectInfo
)
{
    Log("--> _ICD_ScannerOpenUSBDevice\n");
    
    ICAError  err = paramErr;
    
    if ( locationID == 0 )
    {
        // Special Case - we were launched by XCode and hence locationID is 0.
        
        if ( _gIsVirtualScanner )
        {
            UInt32 fakeLocation = 0;
            
            if ( gArgc == 2 )
            {
                int l = strlen( gArgv[1] );
                
                if ( l <= 4 )
                {
                    char* temp  = (char*)&fakeLocation;
                    int   c     = 0;
                    
                    for ( c = 0; c < l; ++c )
                        temp[c] = gArgv[1][c];
                }
            }
            else
                fakeLocation = 0xDEADBEEF;

            err = ICDConnectUSBDevice( fakeLocation );
        }
        else
        {
            UInt32  newLocationID = LocationIDOfMatchingUSBDevice();
            
            if ( newLocationID )
                err = ICDConnectUSBDevice( newLocationID );
        }
    }
    else 
    {
        NSNumber* locIDNum  = [NSNumber numberWithUnsignedInt:locationID];
        BOOL      newDevice = YES;
        
        pthread_mutex_lock( &_gScannersMutex );
        newDevice = ( [_gScannersDictionary objectForKey:locIDNum] == NULL );
        pthread_mutex_unlock( &_gScannersMutex );
        
        if ( newDevice )
        {
            VirtualScanner* vScanner  = NULL;
            
            if ( _gIsVirtualScanner )
            {
                if( locationID == 0xDEADBEEF )
                {
                    vScanner = [[VirtualScanner alloc] init];
                }
                else 
                {
                    // Construct the full BSD name for the mounted virtual scanner disk image and use it to create
                    // an instance of VirtualScanner.
                    
                    char      name[5] = {0};
                    NSString* bsdName = NULL;
                    
                    memcpy( name, &locationID, sizeof(locationID) );
                    bsdName = [NSString stringWithFormat:@"disk%s",name];
                    
                    Log( "    Opening Device %s\n", [bsdName fileSystemRepresentation] );

                    vScanner = [[VirtualScanner alloc] initWithDiskBSDName:bsdName andDASession:_gDiskArbSession];
                }
            }
            else
            {
                vScanner = [[VirtualScanner alloc] initWithLocationID:locationID];
                
                // add code here to setup the USB device
            }

            if ( vScanner )
            {
                newDeviceObjectInfo->privateData                  = (Ptr)vScanner;
                newDeviceObjectInfo->flags                        = 0;
                newDeviceObjectInfo->thumbnailSize                = 1;   // All scanner clients are based on ImageCaptureCore framework, which dynamically determines size of thumbnails. So, we do not need to know the exact size of the thumbnail. Set this to 1 if we have a thumbnail.
                newDeviceObjectInfo->dataSize                     = 0;
                newDeviceObjectInfo->icaObjectInfo.objectType     = kICADevice;
                newDeviceObjectInfo->icaObjectInfo.objectSubtype  = kICADeviceScanner;
                
                strlcpy( (char*)newDeviceObjectInfo->name, [vScanner.name UTF8String], sizeof(newDeviceObjectInfo->name) );
                
                NSDateFormatter*  df  = [[NSDateFormatter alloc] initWithDateFormat:@"%Y:%m:%d %H:%M:%S" allowNaturalLanguage:YES];
                NSDate*           d   = [NSDate date];
                NSString*         ds  = [df stringFromDate:d];

                if ( ds )
                    strlcpy( (char*)(newDeviceObjectInfo->creationDate), [ds UTF8String], sizeof(newDeviceObjectInfo->creationDate) );
                else
                    strlcpy( (char*)(newDeviceObjectInfo->creationDate), "0000:00:00 00:00:00", sizeof(newDeviceObjectInfo->creationDate) );
     
                [df release];
                
                // Cache device object info in our device object
                vScanner.deviceObjectInfo = newDeviceObjectInfo;

                pthread_mutex_lock( &_gScannersMutex );
                [_gScannersDictionary setObject:vScanner forKey:locIDNum];
                pthread_mutex_unlock( &_gScannersMutex );
                err = noErr;
            }
        }
    }
    
    Log("<-- _ICD_ScannerOpenUSBDevice\n");
    return err;
}

//--------------------------------------------------------------------------------------------- _ICD_ScannerOpenFWDevice
/*
  This function is called when a FireWire device is attached to the Macintosh.
  The value of guid is the FireWire GUID of the device and the value of ioRegPath can be used to obtain 
  the IOKit object corresponding to the IOService that triggered the launch of this device module.
*/

ICAError
_ICD_ScannerOpenFWDevice(
    UInt64              guid,
    io_string_t         ioRegPath,
    ScannerObjectInfo*  newDeviceObjectInfo
)
{
    Log("--> _ICD_ScannerOpenFWDevice\n");

    ICAError  err       = paramErr;
    NSNumber* guidNum  = [NSNumber numberWithUnsignedLongLong:guid];
    BOOL      newDevice = YES;
    
    pthread_mutex_lock( &_gScannersMutex );
    newDevice = ( [_gScannersDictionary objectForKey:guidNum] == NULL );
    pthread_mutex_unlock( &_gScannersMutex );
    
    if ( newDevice )
    {
        VirtualScanner* vScanner  = [[VirtualScanner alloc] initWithGUID:guid andIORegPath:ioRegPath];
        
        if ( vScanner )
        {
            newDeviceObjectInfo->privateData                 = (Ptr)vScanner;
            newDeviceObjectInfo->flags                       = 0;
            newDeviceObjectInfo->thumbnailSize               = 1;   // All scanner clients are based on ImageCaptureCore framework, which dynamically determines size of thumbnails. So, we do not need to know the exact size of the thumbnail. Set this to 1 if we have a thumbnail.
            newDeviceObjectInfo->dataSize                    = 0;
            newDeviceObjectInfo->icaObjectInfo.objectType    = kICADevice;
            newDeviceObjectInfo->icaObjectInfo.objectSubtype = kICADeviceScanner;
            
            strlcpy( (char*)newDeviceObjectInfo->name, [vScanner.name UTF8String], sizeof(newDeviceObjectInfo->name) );
            
            NSDateFormatter*  df  = [[NSDateFormatter alloc] initWithDateFormat:@"%Y:%m:%d %H:%M:%S" allowNaturalLanguage:YES];
            NSDate*           d   = [NSDate date];
            NSString*         ds  = [df stringFromDate:d];

            if ( ds )
                strlcpy( (char*)(newDeviceObjectInfo->creationDate), [ds UTF8String], sizeof(newDeviceObjectInfo->creationDate) );
            else
                strlcpy( (char*)(newDeviceObjectInfo->creationDate), "0000:00:00 00:00:00", sizeof(newDeviceObjectInfo->creationDate) );
 
            [df release];
            
            // Cache device object info in our device object
            vScanner.deviceObjectInfo = newDeviceObjectInfo;

            pthread_mutex_lock( &_gScannersMutex );
            [_gScannersDictionary setObject:vScanner forKey:guidNum];
            pthread_mutex_unlock( &_gScannersMutex );
            err= noErr;
        }
    }

    Log("<-- _ICD_ScannerOpenFWDevice\n");
    return err;
}

//------------------------------------------------------------------------------------------ _ICD_ScannerOpenTCPIPDevice
/*
  This function is called when a Bonjour service supported by this device module is selected by the user.
  The parameter dictionary 'params' contains information needed to conntect to the network device using 
  TCP/IP protocol. Here is a sample of the 'params' dictionary:

    {
        ICABonjourDeviceLocationKey = "In the magic ether";
        ICABonjourServiceNameKey = "Virtual Scanner Bonjour";
        ICABonjourServiceTypeKey = "_scanner._tcp.";
        ICABonjourTXTRecordKey =     {
            mdl = <56697274 75616c20 5363616e 6e6572>;
            mfg = <4170706c 65>;
            note = <496e2074 6865206d 61676963 20657468 6572>;
            scannerAvailable = <31>;
            txtvers = <31>;
            ty = <4170706c 65205669 72747561 6c205363 616e6e65 72>;
        };
        ICADeviceBrowserDeviceRefKey = 1;
        UUIDString = "1D279211-1D27-9211-1D27-92111D279211";
        deviceModulePath = "/System/Library/Image Capture/Devices/VirtualScanner.app";
        deviceModuleVersion = 16809984;
        deviceType = scanner;
        hostGUID = "C933C548-A19F-4084-BF09-528438D6D581";
        hostName = "Baskarans-MBP-UniMP";
        ipAddress = "192.168.2.9";
        "ipAddress_v6" = "fe80::3615:9eff:fe8a:9f9c";
        ipGUID = "";
        ipPort = 9500;
        "ipPort_v6" = 9500;
        name = "Apple Virtual Scanner";
        persistentIDString = "1D279211-1D27-9211-1D27-92111D279211";
        transportType = "TCP/IP";
    }
*/
 
ICAError
_ICD_ScannerOpenTCPIPDevice(
    CFDictionaryRef     params, 
    ScannerObjectInfo*  newDeviceObjectInfo
)
{
    Log("--> _ICD_ScannerOpenTCPIPDevice\n");
    ICAError  err       = paramErr;
    BOOL      newDevice = YES;
    
    pthread_mutex_lock( &_gScannersMutex );
    newDevice = ( [_gScannersDictionary objectForKey:[(NSDictionary*)params objectForKey:(id)kICABonjourServiceNameKey]] == NULL );
    pthread_mutex_unlock( &_gScannersMutex );
    
    if ( newDevice )
    {
        VirtualScanner* vScanner  = NULL;
        
        if ( _gIsVirtualScanner )
        {
            vScanner = [[VirtualScanner alloc] init];
        }
        else
        {
            vScanner = [[VirtualScanner alloc] initWithParameters:(NSDictionary*)params];
        }

        if( vScanner )
        {
            newDeviceObjectInfo->privateData                 = (Ptr)vScanner;
            newDeviceObjectInfo->flags                       = 0;
            newDeviceObjectInfo->thumbnailSize               = 1;   // All scanner clients are based on ImageCaptureCore framework, which dynamically determines size of thumbnails. So, we do not need to know the exact size of the thumbnail. Set this to 1 if we have a thumbnail.
            newDeviceObjectInfo->dataSize                    = 0;
            newDeviceObjectInfo->icaObjectInfo.objectType    = kICADevice;
            newDeviceObjectInfo->icaObjectInfo.objectSubtype = kICADeviceScanner;

            strlcpy( (char*)newDeviceObjectInfo->name, [vScanner.name UTF8String], sizeof(newDeviceObjectInfo->name) );
            
            NSDateFormatter*  df  = [[NSDateFormatter alloc] initWithDateFormat:@"%Y:%m:%d %H:%M:%S" allowNaturalLanguage:YES];
            NSDate*           d   = [NSDate date];
            NSString*         ds  = [df stringFromDate:d];

            if ( ds )
                strlcpy( (char*)(newDeviceObjectInfo->creationDate), [ds UTF8String], sizeof(newDeviceObjectInfo->creationDate) );
            else
                strlcpy( (char*)(newDeviceObjectInfo->creationDate), "0000:00:00 00:00:00", sizeof(newDeviceObjectInfo->creationDate) );
 
            [df release];
            
            // Cache device object info in our device object
            vScanner.deviceObjectInfo = newDeviceObjectInfo;

            pthread_mutex_lock( &_gScannersMutex );
            [_gScannersDictionary setObject:vScanner forKey:(id)kICABonjourServiceNameKey];
            pthread_mutex_unlock( &_gScannersMutex );
            err = noErr;
        }
    }
    
    Log("<-- _ICD_ScannerOpenTCPIPDevice\n");
    return err;
}

//---------------------------------------------------------------------------------------------- _ICD_ScannerCloseDevice

ICAError
_ICD_ScannerCloseDevice(
    ScannerObjectInfo*  deviceObjectInfo
)
{
    Log("--> _ICD_ScannerCloseDevice\n");
    ICAError        err       = noErr;
    VirtualScanner* vScanner  = NULL;
    
    require_action( deviceObjectInfo, bail, err = paramErr );
    vScanner = (VirtualScanner*)deviceObjectInfo->privateData;
    require_action( vScanner, bail, err = paramErr );
        
    // Add code here to perform any clean up operations 
    
    [vScanner release];

    pthread_mutex_lock( &_gScannersMutex );
    
    if ( _gIsVirtualScanner )
    {
        NSString* bsdName     = vScanner.bsdName;
        UInt32    locationID  = 0;
        
        if ( bsdName )
        {
            NSString*   temp        = [bsdName substringFromIndex:4];
            char        tempCStr[5] = {};
            
            [temp getCString:tempCStr maxLength:5 encoding:NSUTF8StringEncoding];
            strlcpy( (char*)&locationID, tempCStr, 4 );
        }
        else
          locationID = 0xDEADBEEF;
        
        [_gScannersDictionary removeObjectForKey:[NSNumber numberWithUnsignedInt:locationID]];
    }
    else
    {
        if ( vScanner.usbLocationID != 0 )
        {
            [_gScannersDictionary removeObjectForKey:[NSNumber numberWithUnsignedInt:vScanner.usbLocationID]];
        }
        else if ( vScanner.firewireGuid != 0 )
        {
            [_gScannersDictionary removeObjectForKey:[NSNumber numberWithUnsignedLongLong:vScanner.firewireGuid]];
        }
        else if ( vScanner.networkParams != NULL )
        {
            [_gScannersDictionary removeObjectForKey:[vScanner.networkParams objectForKey:(id)kICABonjourServiceNameKey]];
        }
    }

    pthread_mutex_unlock( &_gScannersMutex );
    
bail:
    Log("<-- _ICD_ScannerCloseDevice\n");
    return err;
}

//-------------------------------------------------------------------------------------------------- _ICD_ScannerCleanup
/*
  This function is called once for each object created by the device module. The objects include the scanner objects
  and any file objects created as children of the scanner objects. The file objects are created when scans are requested
  by a remote client.
*/

ICAError
_ICD_ScannerCleanup(
    ScannerObjectInfo*  objectInfo
)
{
    Log("--> _ICD_ScannerCleanup\n");
    Log("<-- _ICD_ScannerCleanup\n");
    return noErr;
}

//--------------------------------------------------------------------------------------------- _ICD_ScannerPeriodicTask
/*
  This function is called periodically to allow the device module to perform any periodic activity. Any code that polls
  the device for its status should go here.
*/

ICAError
_ICD_ScannerPeriodicTask(
    ScannerObjectInfo * deviceObjectInfo
)
{
    //Log("--> _ICD_ScannerPeriodicTask\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)deviceObjectInfo->privateData;
    require_action(scanner, bail, err = paramErr);
    
    // Acquire the scanner button status
    [scanner acquireButtonPress];
bail:
    //Log("<-- _ICD_ScannerPeriodicTask\n");
    return err;
}

//-------------------------------------------------------------------------------------------- _ICD_ScannerGetObjectInfo
/*
 This function is called when file objects are created as children of a scanner object. These files are created
 when when scans are requested by a remote client.
 */
 
ICAError
_ICD_ScannerGetObjectInfo(
    const ScannerObjectInfo*  parentObjectInfo,
    UInt32                    index,
    ScannerObjectInfo*        newObjectInfo
)
{
    Log("--> _ICD_ScannerGetObjectInfo\n");
    
    ICAError        err                 = noErr;
    VirtualScanner* scanner             = NULL;
    ICAObjectInfo   parentICAObjectInfo;
    
    // Files are presented as children of the device object using a flat hierarchy. Therefore, the parentObjectInfo
    // should belong to the device object. The following code checks for this.
    require_action(parentObjectInfo, bail, err = paramErr);
    parentICAObjectInfo = parentObjectInfo->icaObjectInfo;
    require_action(parentICAObjectInfo.objectType == kICADevice, bail, err = paramErr);
    scanner = (VirtualScanner*)parentObjectInfo->privateData;
    require_action(scanner, bail, err = paramErr);
    
    if ( index >= scanner.numberOfScannedImages )
        return kICAIndexOutOfRangeErr;
    
    switch ( parentICAObjectInfo.objectType )
    {
        case kICADevice:
            err = [scanner updateObjectInfo:newObjectInfo forScannedImageAtIndex:index];
            break;
            
        default:
            err = paramErr;
            break;
    }
    
bail:
    
    Log("<-- _ICD_ScannerGetObjectInfo\n");
    return err;
}

//--------------------------------------------------------------------------------------------- _ICD_ScannerReadFileData
/*
  This function is called to retrieve the image data of scanned image cached for remote client.
*/

ICAError
_ICD_ScannerReadFileData(
    const ScannerObjectInfo*  objectInfo,
    UInt32                    dataType,
    Ptr                       buffer,
    UInt32                    offset,
    UInt32*                   length
)
{
    Log("--> _ICD_ScannerReadFileData\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(objectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)objectInfo->privateData;
    require_action(scanner, bail, err = paramErr);
    [scanner readFileDataWithObjectInfo:objectInfo intoBuffer:(char*)buffer withOffset:offset andLength:length];

bail:    
    Log("<-- _ICD_ScannerReadFileData\n");
    return 0;
}

//---------------------------------------------------------------------------------------------- _ICD_ScannerSendMessage
/*
  SendMessage is a powerful mechanism for supporting a lot of system and device specific features.
  Here we demonstrate a few common messages:
    - a message to delete a cached image object
    - a message to retrieve the last button pressed
    - a message to inform the current selection rectangle position on the overview scan
 */
 
ICAError
_ICD_ScannerSendMessage(
    const ScannerObjectInfo*        objectInfo,
    ICD_ScannerObjectSendMessagePB* pb,
    ICDCompletion                   completion
)
{
    Log("--> _ICD_ScannerSendMessage\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    ICAObjectInfo   icaObjectInfo;
    
    require_action(objectInfo, bail, err = paramErr);
    icaObjectInfo = objectInfo->icaObjectInfo;
    scanner = (VirtualScanner*)objectInfo->privateData;
    require_action(scanner, bail, err = paramErr);

    switch ( pb->message.messageType )
    {
        case kICAMessageCameraDeleteOne:
            // ICADevices framework will send this message after successfully retrieving the object 
            // data by calling _ICD_ScannerReadFileData().
            err = [scanner removeObject:objectInfo];
            break;
            
        case kICAMessageGetLastButtonPressed:
        {
            // The scanner client sends this message to retrieve information about the last pressed button 
            // on the scanner. Return the last button that was pressed on the device so that a custom work-flow
            // could be initiated based on this information.
            
            // check to make sure that the message received is for a device object
            require_action( icaObjectInfo.objectType == kICADevice, bail, err = paramErr );
            
            // check to make sure message.dataPtr != nil, and message.dataSize == 4
            require_action( pb->message.dataPtr && pb->message.dataSize == 4, bail, err = paramErr );
            
            *((OSType*)(pb->message.dataPtr)) = scanner.lastButtonPressed;
            pb->message.dataType              = scanner.lastButtonPressed;
        }
        break;
        
        case kICAMessageScannerOverviewSelectionChanged:
        {
            /*
            The scanner client sends this message whenever the selection area is changed in the scanner UI. 
            
            The device module could respond to this message using a notification that updates the image content of the
            selected area. For example, if the currently used functional unit is negative film scanner, then the
            device module could send a notification with "positive" image data for the selected area.
            
            If the user has selected a vendor-feature like dust-removal, then the device could send a dust-removed
            version of the image for the selected area.
            
            The image data sent through the notification should be an RGB buffer.
            
            The client application (e.g. the Image Capture application) uses this RGB buffer to update the 
            selection area.
            
            The device module need not send any notification if there is nothing to do in response to this message.
            
            You get this message whenever the user changes the selection / target rectangle.  We have a corresponding
            message where you can pass an 8 bit RGB buffer back.  You do not have to handle this message.  However, 
            this is the mechanism where you could implement advanced UI interaction like converting from negative to
            positive, repairing scratch, etc.  The client application ( e.g. the Image Capture application ) uses
            the RGB buffer you sent back to update the target rect in real time ( assuming that you have buffer the
            overview image data for processing so you can generate the RGB data for the update ).

            A pointer to NSMutableDictionary instance that contains the selection area is found at pb->message.dataPtr.
            Here is an example of this dictionary: (All the numbers are in pixels)
            
            {
                ICAP_XRESOLUTION : {
                    type. : TWON_ONEVALUE
                    value : 150
                }
                ICAP_YRESOLUTION : {
                    type. : TWON_ONEVALUE
                    value : 150
                }
                height.......... : 208
                offsetX......... : 59
                offsetY......... : 92
                width........... : 345
            }
             
            If the device chose to respond to this message, then it should send this dictionary back along with three
            key-value pairs:
            
                        key                                  value
                        ---                                  -----
                kICANotificationDataKey         NSData* containing the RGB buffer for the selection area
                kICANotificationICAObjectKey    device ICAObject
                kICANotificationTypeKey         kICANotificationTypeScannerOverviewOverlayAvailable
                
            Here is an example of the notification dictionary:
            
            ICANotificationDictionaryKey : {
                ICANotificationDataKey........... : <NSData>
                ICANotificationICAObjectKey...... : <device ica object>
                ICANotificationTypeKey........... : kICANotificationTypeScannerOverviewOverlayAvailable

                ICAP_XRESOLUTION................. : {
                    type. : TWON_ONEVALUE
                    value : 150
                }
                ICAP_YRESOLUTION................. : {
                    type. : TWON_ONEVALUE
                    value : 150
                }
                height........................... : 208
                offsetX.......................... : 59
                offsetY.......................... : 92
                width............................ : 345
            }
            */
             
            // Below is an example of asking the scanner to send an inverted rectangle corresponding to the selection
            // Because we have also added a vendor specific button, the rectangle will only be updated if the box
            // is selected to enable inversion.
            
            NSMutableDictionary*  paramDict   = (NSMutableDictionary*)(pb->message.dataPtr);
            NSData*               data        = NULL;
            
            // Scanner module function that creates an RGB data object for the inverted rectangle that has been selected
            data = [scanner newInvertedRect: paramDict];
            // Only if we actually got an updated value for the RGB buffer shall we send a notification update.  If no 
            // notification is received, the selection will appear unhandled.
            if( data )
            {
                ICASendNotificationPB notePB        = {};
                NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithDictionary:paramDict];

                [notification setObject:[NSNumber numberWithUnsignedInt:objectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
                [notification setObject:data forKey:(id)kICANotificationDataKey];
                [notification setObject:(id)kICANotificationTypeScannerOverviewOverlayAvailable forKey:(id)kICANotificationTypeKey];

                notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
                err = ICDSendNotification( &notePB );  
                [notification release];
                [data release];
            }
        }
        break;
        
        default:
        {
            // Unknown message!
            err = paramErr;
            pb->result = err;
        }
        break;
    }
    
bail:
    pb->header.err = err;

#if ( SCANNER_DEBUG == 1 )
    if ( err )
        Log( "    _ICD_ScannerSendMessage error %d occured.\n", err );
#endif

    if ( (err == noErr) && completion )
        completion((ICDHeader*)pb);

    Log("<-- _ICD_ScannerSendMessage\n");
    
    return err;
}

//------------------------------------------------------------------------------ _ICD_ScannerAddPropertiesToCFDictionary
/*
  Add properties to dictionary for the device object.
*/
 
ICAError
_ICD_ScannerAddPropertiesToCFDictionary(
    ScannerObjectInfo*      objectInfo,
    CFMutableDictionaryRef  dict
)
{
    Log("--> _ICD_ScannerAddPropertiesToCFDictionary\n");

    ICAError              err         = paramErr;
    VirtualScanner*       scanner     = NULL;
    NSMutableDictionary*  propDict    = (NSMutableDictionary*)dict;
    
    require_action(objectInfo, bail, err = paramErr);
    
    if ( objectInfo->icaObjectInfo.objectType == kICADevice )
    {
        scanner = (VirtualScanner*)objectInfo->privateData;
        require_action(scanner, bail, err = paramErr);
        [scanner addPropertiesToDictionary:propDict];
        err = noErr;
    }
    
bail:
    Log("<-- _ICD_ScannerAddPropertiesToCFDictionary\n");
    return err;
}

//---------------------------------------------------------------------------------------------- _ICD_ScannerOpenSession
/*
  This gives a client exclusive access to the scanner.
*/

ICAError 
_ICD_ScannerOpenSession(
    const ScannerObjectInfo*  deviceObjectInfo,
    ICD_ScannerOpenSessionPB* pb
)
{
    Log("--> _ICD_ScannerOpenSession\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)deviceObjectInfo->privateData;    
    require_action(scanner, bail, err = paramErr);
    err = [scanner openSessionWithParams:pb];
    
bail:    
    Log("<-- _ICD_ScannerOpenSession\n");
    return err;
}

//--------------------------------------------------------------------------------------------- _ICD_ScannerCloseSession
/*
  Remove exclusive access to the scanner.
*/

ICAError
_ICD_ScannerCloseSession(
    const ScannerObjectInfo*    deviceObjectInfo,
    ICD_ScannerCloseSessionPB*  pb
)
{
    Log("--> _ICD_ScannerOpenSession\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)deviceObjectInfo->privateData;    
    require_action(scanner, bail, err = paramErr);
    err = [scanner closeSessionWithParams:pb];
    
bail:    
    Log("<-- _ICD_ScannerOpenSession\n");
    return err;
}

//-------------------------------------------------------------------------------------------- _ICD_ScannerGetParameters
/*
  _ICD_ScannerGetParameters returns the setting of our scanner and its current functional unit
  that is selected -- not a particular scan.  We are using TWAIN keys in our dictionary whenever 
  possible. 
*/

ICAError
_ICD_ScannerGetParameters(
    const ScannerObjectInfo*    deviceObjectInfo,
    ICD_ScannerGetParametersPB* pb
)
{
    Log("--> _ICD_ScannerGetParameters\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)deviceObjectInfo->privateData;    
    require_action(scanner, bail, err = paramErr);
    err = [scanner getSelectedFunctionalUnitParams:pb];
    
bail:
    Log("<-- _ICD_ScannerGetParameters\n");
    return err;
}

//-------------------------------------------------------------------------------------------- _ICD_ScannerSetParameters
/*
  _ICD_ScannerSetParameters sets up the scanner for a particular scan.  The keys we passed are very 
  different from the those passed in _ICD_ScannerGetParameters.  We are using TWAIN keys in our dictionary 
  whenever possible.
 
  Note that offsets are in native resolutions.
*/

ICAError
_ICD_ScannerSetParameters(
    const ScannerObjectInfo*    deviceObjectInfo,
    ICD_ScannerSetParametersPB* pb
)
{
    Log("--> _ICD_ScannerSetParameters\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*) deviceObjectInfo->privateData;
    require_action(scanner, bail, err = paramErr);
    err = [scanner setSelectedFunctionalUnitParams:pb];

bail:
    Log("<-- _ICD_ScannerSetParameters\n");
    return err;
}

//--------------------------------------------------------------------------------------------------- _ICD_ScannerStatus
/*
  _ICD_ScannerStatus is not yet implemented in Image Capture Architecture. Therefore, this function will not
  be called.
*/

ICAError
_ICD_ScannerStatus(
    const ScannerObjectInfo*  deviceObjectInfo,
    ICD_ScannerStatusPB*      pb
)
{
    ICAError    err = noErr;
    Log("--> _ICD_ScannerStatus\n");
    Log("<-- _ICD_ScannerStatus\n");
    return err;
}

//---------------------------------------------------------------------------------------------------- _ICD_ScannerStart
/*
  _ICD_ScannerStart issues a scan with the current settings and functional unit selected. 
*/

ICAError
_ICD_ScannerStart(
    const ScannerObjectInfo*  deviceObjectInfo,
    ICD_ScannerStartPB*       pb
)
{
    Log("--> _ICD_ScannerScannerStart\n");
    
    ICAError        err     = noErr;
    VirtualScanner* scanner = NULL;
    
    require_action(deviceObjectInfo, bail, err = paramErr);
    scanner = (VirtualScanner*)deviceObjectInfo->privateData;
    require_action(scanner, bail, err = paramErr);
    err = [scanner startScanningWithParams:pb];

bail:
    Log("<-- _ICD_ScannerScannerStart\n");
    return err;
}

//----------------------------------------------------------------------------------------------------------------------