//     File: VirtualScanner.h
// Abstract: Virtual Scanner function definitions for a sample scanner device module.
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

#pragma once

//----------------------------------------------------------------------------------------------------------------------

#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/IOMessage.h>
#import <IOKit/usb/IOUSBLib.h>
#import <DiskArbitration/DiskArbitration.h>
#import <asl.h>

//----------------------------------------------------------------------------------------------------------------------
// Debug logging Macros. The preprocessor symbol SCANNER_DEBUG is defined in the Debug configuration of 
// the target build settings.

#if ( SCANNER_DEBUG == 1 )
#define Log( FMT, ARGS...)    asl_log( NULL, NULL, ASL_LEVEL_NOTICE, FMT, ## ARGS)
#else
#define Log( FMT, ARGS...)
#endif

//----------------------------------------------------------------------------------------------------------------------
// These are defined in <ICADevices/ICADevices,h> in 10.7. We need the following for backward compatibiity in 10.6

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070

extern CGColorSpaceRef  ICDCreateColorSpace( UInt32 bitsPerPixel, UInt32 samplesPerPixel, ICAObject icaObject, CFStringRef colorSyncMode, CFDataRef abstractProfile, char* tmpProfilePath);

// ICA Raw File Header
typedef struct ICARawFileHeader
{
    UInt32    imageDataOffset;
    UInt32    version;
    UInt32    imageWidth;
    UInt32    imageHeight;
    UInt32    bytesPerRow;
    UInt32    numberOfComponents;
    UInt32    bitsPerComponent;
    UInt32    bitsPerPixel;
    UInt32    cgColorSpaceModel;
    UInt32    bitmapInfo;
    UInt32    orientation;
    UInt32    dpi;
    char      colorSyncModeStr[64];
} ICARawFileHeader;

#endif

//----------------------------------------------------------------------------------------------------------------------

@interface VirtualScanner : NSObject
{
    UInt32                  _usbLocationID;
    UInt64                  _firewireGuid;
    NSDictionary*           _networkParams;

    ScannerObjectInfo*      _deviceObjectInfo;

    BOOL                    _createdForDiskImage;
    DADiskRef               _diskRef;             // Disk arbitration references only used in the "Virtual Scanner"
    NSString*               _bsdName;             // BSD name of the mounted virtual scanner disk image
    NSString*               _volumePath;          // Volume path of the mounted virtual scanner disk image 
    NSString*               _sampleImageFilePath;
    
    NSString*               _propertyListPath;
    NSString*               _deviceInfoPath;
    
    BOOL                    _scannerSessionOpened;
    
    //Scanner Property List in the format that will be sent from the device to the Image Capture Extension
    NSMutableDictionary*    _propertyListDictionary;
    
    //Functional Unit settings, initially a copy of the device property information, modified by the user
    //when they interact with the scanner settings.
    NSMutableDictionary*    _functionalUnitSettings;
    
    NSString*               _selectedFunctionalUnitTypeString;
    
    // Scan image settings passed when a scan has been requested
    NSMutableDictionary*    _scanImageSettings;
        
    BOOL                    _devicePollsForButtonPresses;   
    OSType                  _lastButtonPressed;
    
    // Progressive notifications with or without data
    BOOL                    _sendProgressNotificationsWithOverviewData;       // used when performing an overview/preview scan
    BOOL                    _sendProgressNotificationsWithScanData;       // used when performing an overview/preview scan
    BOOL                    _sendProgressNotificationsWithoutData;    // used when performing a final scan
    
    // Maximum band size sent for memory based progress notification
    UInt32                  _maxProgressBandSize;

    NSString*               _colorSyncMode;
    NSDictionary*           _scannedImageMetadata;

    NSString*               _documentFolderPath;
    NSString*               _documentName;
    NSString*               _documentUTI;
    NSString*               _documentExtension;
    NSString*               _documentFilePath;
    
    NSMutableArray*         _scannedImages;
    
    char                    _rawImageFileCachePath[512];
    FILE*                   _rawImageFile;
    CGImageRef              _rawCGImageRef;
}

/*! 
  @property name
  @abstract Name of the scanner device.
*/
@property(readonly)       NSString*           name;

/*! 
  @property usbLocationID
  @abstract Location ID of the USB scanner.
*/
@property(assign)         UInt32              usbLocationID;

/*! 
  @property firewireGuid
  @abstract GUID of the FireWire scanner.
*/
@property(assign)         UInt64              firewireGuid;

/*! 
  @property networkParams
  @abstract Parameter dictionary used to create a TCP/IP scanner.
*/
@property(readwrite,copy) NSDictionary*       networkParams;

/*! 
  @property deviceObjectInfo
  @abstract Reference to the ScannerObjectInfo struct received in one of the _ICD_ScannerOpen*() calls defined in EntryPoints.m
*/
@property(assign)         ScannerObjectInfo*  deviceObjectInfo;

/*! 
  @property createdForDiskImage
  @abstract This is set to YES if the scanner object is created for a virtual scanner disk image.
  @discussion Information from the mounted virtual scanner disk image is used to created a virtual scanner.
*/
@property(assign)         BOOL                createdForDiskImage;

/*! 
  @property bsdName
  @abstract BSD name of the mounted virtual scanner disk image.
*/
@property(readwrite,copy) NSString*           bsdName;

/*! 
  @property volumePath
  @abstract Volume path of the mounted virtual scanner disk image.
*/
@property(readwrite,copy) NSString*           volumePath;

/*! 
  @property sampleImageFilePath
  @abstract Path to a sample image use by the virtual scanner. This sample image is used to synthesize scan data.
*/
@property(readwrite,copy) NSString*           sampleImageFilePath;

/*! 
  @property propertyListPath
  @abstract Path to scanner property plist file. This file contains information about functional units available on the scanner.
*/
@property(readwrite,copy) NSString*           propertyListPath;

/*! 
  @property deviceInfoPath
  @abstract Path to scanner device info plist file. This file contains information about device icon, buttons supported by the device and an overview of functional units available on the device.
*/
@property(readwrite,copy) NSString*           deviceInfoPath;

/*! 
  @property scannerSessionOpened
  @abstract Scanner session variable to make sure we don't allow more than one client application access to the scanner at one time.
*/
@property(assign)         BOOL                scannerSessionOpened;

/*! 
  @property devicePollsForButtonPresses
  @abstract This property is set to YES of the device module polls the device for button presses.
  @discussion The _ICD_ScannerPeriodicTask() function implemented in EntryPoints.m file is called periodically. You should send a message to the scanner object instance to poll the device for button press and save the button press information in the lastButtonPressed property. In addition, you should send out a notification to inform clients about the button press.
*/
@property(assign)         BOOL                devicePollsForButtonPresses;

/*! 
  @property lastButtonPressed
  @abstract This property holds the value associated with the last button that was pressed on the device.
  @discussion The device module should receive button-presses on the device asynchronously (e.g., via asynchronous read of USB interrupt pipe) and resort to polling the device only that is not possible.
*/
@property(assign)         OSType              lastButtonPressed;

/*! 
  @property selectedFunctionalUnitTypeString
  @abstract A string value representing the selected functional unit type
*/
@property(readwrite,copy) NSString*           selectedFunctionalUnitTypeString;

/*! 
  @property documentFolderPath
  @abstract Path to folder where the scanned document should be saved.
  @discussion This path is write-accessible. This path will be NULL if the scan is done by a remote client. This is sent by the client to the device module.
*/
@property(readwrite,copy) NSString*           documentFolderPath;

/*! 
  @property documentName
  @abstract The desired name of the scanned document.
  @discussion This is sent by the client to the device module.
*/
@property(readwrite,copy) NSString*           documentName;

/*! 
  @property documentUTI
  @abstract The UTType of the scanned document.
  @discussion This is sent by the client to the device module.
*/
@property(readwrite,copy) NSString*           documentUTI;

/*! 
  @property documentExtension
  @abstract The file extension of the scanned document
  @discussion This is sent by the client to the device module.
*/
@property(readwrite,copy) NSString*           documentExtension;

/*! 
  @property documentFilePath
  @abstract Full path specifying where the scanned document should be saved.
*/
@property(readwrite,copy) NSString*           documentFilePath;

/*! 
  @property colorSyncMode
  @abstract ColorSync mode string for creating a color space associated with the scanned image.
  @discussion This is sent by the client to the device module.
*/
@property(readwrite,copy) NSString*           colorSyncMode;

/*! 
  @property scannedImageMetadata
  @abstract Metadata that should be added to the scanned image.
  @discussion This is sent by the client to the device module.
*/
@property(readwrite,copy) NSDictionary*       scannedImageMetadata;

/*! 
  @property isDocumentUTI_ICA_RAW
  @abstract True if documentUTI is kICUTTypeRaw.
*/
@property(readonly)       BOOL                isDocumentUTI_ICA_RAW;

/*! 
  @property sendProgressNotificationsWithOverviewData
  @abstract This is true when performing an overview/preview scan.
  @discussion The data will be sent in an RGB buffer.
*/
@property(assign)         BOOL                sendProgressNotificationsWithOverviewData;

/*! 
 @property sendProgressNotificationsWithScanData
 @abstract This is true if the client has selected data based transfer.
 @discussion The data will be sent using whatever image data type indicated in the header. 
 */
@property(assign)         BOOL                sendProgressNotificationsWithScanData;

/*! 
  @property sendProgressNotificationsWithoutData
  @abstract This is true if the client has selected file based transfer.
  @discussion This will let the module create and process the file independent of the data.
*/
@property(assign)         BOOL                sendProgressNotificationsWithoutData;

/*! 
 @property maxProgressBandSize
 @abstract A value representing the maximum byte size of any individual band scanned which
 can be overridden by the property of the scanner and client using it.
 */
@property(assign) UInt32                      maxProgressBandSize;

/*! 
  @property numberOfScannedImages
  @abstract Returns the number of scanned images that are to be transferred to the client machine.
  @discussion This is relevant only when scanning is performed for a remote client.
*/
@property(readonly)       NSUInteger          numberOfScannedImages;

// Initializers
- (id)init;
- (id)initWithDiskBSDName:(NSString*)diskBSDName andDASession:(DASessionRef)daSession;
- (id)initWithLocationID:(UInt32)locationID;
- (id)initWithGUID:(UInt64)guid andIORegPath:(io_string_t)ioRegPath;
- (id)initWithParameters:(NSDictionary*)params;

// Add device-specific properties
- (void)addPropertiesToDictionary:(NSMutableDictionary*)propDict;

// Open a session
- (ICAError)openSessionWithParams:(ICD_ScannerOpenSessionPB*)pb;

// Close a session
- (ICAError)closeSessionWithParams:(ICD_ScannerCloseSessionPB*)pb;

// Get parameters for currently selected functional unit
- (ICAError)getSelectedFunctionalUnitParams:(ICD_ScannerGetParametersPB*)pb;

// Set parameters for currently selected functional unit
- (ICAError)setSelectedFunctionalUnitParams:(ICD_ScannerSetParametersPB*)pb;

// Start scanning using parameters
- (ICAError)startScanningWithParams:(ICD_ScannerStartPB*)pb;

// Vendor Specific Example Function
- (NSData*)newInvertedRect:(NSDictionary*)paramDict;

// Method called in a periodic task to poll the scanner for last button press information
- (void)acquireButtonPress;

// Method to support scanning by remote clients
- (ICAError)updateObjectInfo:(ScannerObjectInfo*)objectInfo forScannedImageAtIndex:(NSUInteger)index;
- (ICAError)removeObject:(const ScannerObjectInfo*)objectInfo;
- (ICAError)readFileDataWithObjectInfo:(const ScannerObjectInfo*)objectInfo intoBuffer:(char*)buffer withOffset:(UInt32)offset andLength:(UInt32*)length;
@end

//----------------------------------------------------------------------------------------------------------------------
