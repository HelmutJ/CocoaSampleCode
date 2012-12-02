//     File: VirtualScanner.m
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

#import <TWAIN/TWAIN.h>
#import <sys/stat.h>
#import <notify.h>

#import "VirtualScanner.h"
#import "ScannedImage.h"
#import <ImageCaptureCore/ICScannerFunctionalUnits.h>
#include <dlfcn.h>

extern  BOOL  _gIsVirtualScanner;

void
virtualButtonCallback(
    CFNotificationCenterRef center,
    void*                   observer,
    CFStringRef             name,
    const void*             object,
    CFDictionaryRef         userInfo
);

#pragma mark -
#pragma mark VirtualScanner Private Interface
//---------------------------------------------------------------------------------------------- VirtualScanner(Private)

@interface VirtualScanner(Private)

@property(readonly) unsigned int  bitDepth;
@property(readonly) unsigned int  pixelType;
@property(readonly) double        xResolution;
@property(readonly) double        yResolution;
@property(readonly) double        xNativeResolution;
@property(readonly) double        yNativeResolution;
@property(readonly) double        physicalWidth;
@property(readonly) double        physicalHeight;

- (void)readProperties;

- (CGColorSpaceRef)newColorspaceForCurrentFunctionalUnitSettings:(unsigned int*)bitsPerComponent andBitsPerPixel:(unsigned int*)bitsPerPixel;

// Methods to handle button presses on the device
- (void)startReceivingButtonPressesFromDevice;
- (void)stopReceivingButtonPressesFromDevice;
- (void)buttonPressed:(NSNumber*)button;

 // Methods to send notifications to client
- (void)requestOverviewScanMsg;
- (void)showWarmUpMsg;
- (void)doneWarmUpMsg;
- (void)feederNoPaperMsg;

// Raw File Based Methods
- (BOOL)openRawFileForWriting;
- (void)openRawFileForReading;
- (size_t)readRawFileWithBuffer:(void*)buffer ofSize:(size_t)size;
- (void)writeRawFileWithBuffer:(char*)buffer ofSize:(size_t)size;
- (void)closeRawFile;
- (void)rewindRawFile;

// CG Data Provider Methods
- (off_t)skipBytes:(size_t)size;
- (void)rewind;
- (size_t)getBytes:(void*)buffer ofSize:(size_t)size;
- (void)releaseProvider;
- (void)setOutputFilePath;
- (void)saveImageWithWidth:(UInt32)scanImageWidth andHeight:(UInt32)scanImageHeight;

// Methods to process scan parameters
- (void)updateScanParamsUsingValuesInDictionary:(NSDictionary*)dict;
- (void)setValueForKey:(NSString*)key fromDictionary:(NSDictionary*)dict;
- (void)setValuesForVendorFeaturesFromDictionary:(NSDictionary*)dict;
- (NSNumber*)getValueForKey:(NSString*)key;
- (NSNumber*)getValueForVendorFeature:(NSString*)featureName;
@end

#pragma mark -
#pragma mark Data Provider
//----------------------------------------------------------------------------------------------------------- dpGetBytes

static size_t dpGetBytes( void *info, void *buffer, size_t size )
{
    return [((VirtualScanner*)info) getBytes:buffer ofSize:size];
}

//---------------------------------------------------------------------------------------------------------- dpSkipBytes

static off_t dpSkipBytes( void *info, off_t size )
{
    return [((VirtualScanner*)info) skipBytes:size];
}

//------------------------------------------------------------------------------------------------------------- dpRewind

static void dpRewind( void *info )
{
    [((VirtualScanner*)info) rewind];
}

//---------------------------------------------------------------------------------------------------- dpReleaseProvider

static void dpReleaseProvider( void *info )
{
    [((VirtualScanner*)info) releaseProvider];
}

#pragma mark -
#pragma mark Button Callbacks
//------------------------------------------------------------------------------------------------ virtualButtonCallback
// This method is called only for a virtual scanner device. The developer should create appriate functions for 
// handling device-event callbacks for USB, FireWire and network devices.

void
virtualButtonCallback(
    CFNotificationCenterRef center,
    void*                   observer,
    CFStringRef             name,
    const void*             object,
    CFDictionaryRef         userInfo
)
{
    VirtualScanner* s = (VirtualScanner*)observer;

    if( [(NSString*)name isEqualToString:@"com.apple.VirtualScanner.scanButtonPressed"] )
    {
        [s performSelectorOnMainThread:@selector(buttonPressed:) withObject:[NSNumber numberWithInt:kICAButtonScan] waitUntilDone:NO];
    }
    if( [(NSString*)name isEqualToString:@"com.apple.VirtualScanner.copyButtonPressed"] )
    {
        [s performSelectorOnMainThread:@selector(buttonPressed:) withObject:[NSNumber numberWithInt:kICAButtonCopy] waitUntilDone:NO];
    }
    if( [(NSString*)name isEqualToString:@"com.apple.VirtualScanner.emailButtonPressed"] )
    {
        [s performSelectorOnMainThread:@selector(buttonPressed:) withObject:[NSNumber numberWithInt:kICAButtonEMail] waitUntilDone:NO];
    }
    if( [(NSString*)name isEqualToString:@"com.apple.VirtualScanner.webButtonPressed"] )
    {
        [s performSelectorOnMainThread:@selector(buttonPressed:) withObject:[NSNumber numberWithInt:kICAButtonWeb] waitUntilDone:NO];
    }
}

#pragma mark -
#pragma mark Virtual Scanner implementation
//------------------------------------------------------------------------------------------------------- VirtualScanner

@implementation VirtualScanner

@synthesize usbLocationID                               = _usbLocationID;
@synthesize firewireGuid                                = _firewireGuid;
@synthesize networkParams                               = _networkParams;
@synthesize deviceObjectInfo                            = _deviceObjectInfo;

@synthesize createdForDiskImage                         = _createdForDiskImage;
@synthesize scannerSessionOpened                        = _scannerSessionOpened;

@synthesize bsdName                                     = _bsdName;
@synthesize volumePath                                  = _volumePath;

@synthesize propertyListPath                            = _propertyListPath;
@synthesize deviceInfoPath                              = _deviceInfoPath;
@synthesize sampleImageFilePath                         = _sampleImageFilePath;

@synthesize documentFolderPath                          = _documentFolderPath;
@synthesize documentName                                = _documentName;
@synthesize documentUTI                                 = _documentUTI;
@synthesize documentExtension                           = _documentExtension;;
@synthesize documentFilePath                            = _documentFilePath;

@synthesize sendProgressNotificationsWithOverviewData   = _sendProgressNotificationsWithOverviewData;
@synthesize sendProgressNotificationsWithScanData       = _sendProgressNotificationsWithScanData;
@synthesize sendProgressNotificationsWithoutData        = _sendProgressNotificationsWithoutData;

@synthesize scannedImageMetadata                        = _scannedImageMetadata;

@synthesize colorSyncMode                               = _colorSyncMode;

@synthesize devicePollsForButtonPresses                 = _devicePollsForButtonPresses;
@dynamic    lastButtonPressed;

@synthesize selectedFunctionalUnitTypeString            = _selectedFunctionalUnitTypeString;

@synthesize maxProgressBandSize                         = _maxProgressBandSize;

#pragma mark -
//------------------------------------------------------------------------------------ initWithDiskBSDName:andDASession:

- (id)initWithDiskBSDName:(NSString*)diskBSDName andDASession:(DASessionRef)daSession;
{
    if ( ( self = [super init] ) )
    {
        CFDictionaryRef diskDesc  = NULL;            

        if ( ( diskBSDName != NULL ) && ( daSession != NULL ) )
        {
            _diskRef  = DADiskCreateFromBSDName( kCFAllocatorDefault, daSession, [diskBSDName UTF8String] );
            diskDesc  = DADiskCopyDescription( _diskRef );
        }
        
        if ( diskDesc )
        {
            NSString* volumePath = [NSString stringWithString:[(NSURL*)[(NSDictionary*)diskDesc objectForKey:(id)kDADiskDescriptionVolumePathKey] path]];
            
            if ( volumePath )
            {
                struct stat status;
                NSString*   tempPath = NULL;
                
                self.createdForDiskImage  = YES;
                self.volumePath           = volumePath;
                self.bsdName              = diskBSDName;

                tempPath = [NSString stringWithFormat:@"%@/VSCAN/ScannerProperties.plist", volumePath];
                
                if ( stat( [tempPath UTF8String], &status) == 0 )
                    self.propertyListPath = tempPath;
                else
                    self.propertyListPath = NULL;
                    
                tempPath = [NSString stringWithFormat:@"%@/VSCAN/DeviceInfo.plist", volumePath];
                
                if ( stat( [tempPath UTF8String], &status) == 0 )
                    self.deviceInfoPath = tempPath;
                else
                {
                    tempPath = [[NSBundle mainBundle] pathForResource:@"DeviceInfo" ofType:@"plist"];

                    if ( stat( [tempPath UTF8String], &status) == 0 )
                        self.deviceInfoPath = tempPath;
                    else
                        self.deviceInfoPath = NULL;
                }
                
                tempPath = [NSString stringWithFormat:@"%@/VSCAN/test.tiff", volumePath];
                
                if ( stat( [tempPath UTF8String], &status) == 0 )
                    self.sampleImageFilePath = tempPath;
                else
                    self.sampleImageFilePath = NULL;
            }
            
            CFRelease( diskDesc );
        }
        else
        {
            struct stat status;
            NSString*   tempPath  = NULL;
            
            tempPath = [[NSBundle mainBundle] pathForResource:@"ScannerProperties" ofType:@"plist"];

            if ( stat( [tempPath UTF8String], &status) == 0 )
                self.propertyListPath = tempPath;
            else
                self.propertyListPath = NULL;
            
            tempPath = [[NSBundle mainBundle] pathForResource:@"DeviceInfo" ofType:@"plist"];

            if ( stat( [tempPath UTF8String], &status) == 0 )
                self.deviceInfoPath = tempPath;
            else
                self.deviceInfoPath = NULL;

            tempPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"tiff"];

            if ( stat( [tempPath UTF8String], &status) == 0 )
                self.sampleImageFilePath = tempPath;
            else
                self.sampleImageFilePath = NULL;
        }
        
        if ( self.propertyListPath && self.deviceInfoPath && self.sampleImageFilePath )
        {
            _scannedImages = [[NSMutableArray alloc] init];
            [self readProperties];
            
            _devicePollsForButtonPresses  = NO;   // set this to YES if the device module polls the device to 
                                                  // find if a button was pressed on the device

            if ( _devicePollsForButtonPresses == NO )
                [self startReceivingButtonPressesFromDevice];
        }
        else
        {
            [self release];
            self = NULL;
        }
    }
    
    return self;
}

//----------------------------------------------------------------------------------------------------------------- init

- (id)init
{
    return [self initWithDiskBSDName:NULL andDASession:NULL];
}

//-------------------------------------------------------------------------------------------------- initWithLocationID:

- (id)initWithLocationID:(UInt32)locationID
{
    if ( ( self = [super init] ) )
    {
        self.usbLocationID  = locationID;
        _scannedImages      = [[NSMutableArray alloc] init];
        
        // add code to initialize the USB device object
    }
    
    return self;
}

//------------------------------------------------------------------------------------------- initWithGUID:andIORegPath:

- (id)initWithGUID:(UInt64)guid andIORegPath:(io_string_t)ioRegPath
{
    if ( ( self = [super init] ) )
    {
        self.firewireGuid = guid;
        _scannedImages    = [[NSMutableArray alloc] init];
        
        // add code to initialize the FireWire device object
    }
    
    return self;
}

//-------------------------------------------------------------------------------------------------- initWithParameters:

- (id)initWithParameters:(NSDictionary*)params
{
    if ( ( self = [super init] ) )
    {
        self.networkParams  = params;
        _scannedImages      = [[NSMutableArray alloc] init];
        
        // add code to initialize the TCP/IP device object
    }
    
    return self;
}

//-------------------------------------------------------------------------------------------------------------- dealloc

- (void)dealloc
{
    [self stopReceivingButtonPressesFromDevice];
    
    if ( _diskRef )
        CFRelease( _diskRef );
    
    [_propertyListDictionary release];
    [_functionalUnitSettings release];    
    [_scanImageSettings release];
    [_scannedImages release];
    
    self.volumePath           = NULL;
    self.sampleImageFilePath  = NULL;
    self.propertyListPath     = NULL;
    self.deviceInfoPath       = NULL;
    self.documentFolderPath   = NULL;
    self.documentName         = NULL;
    self.documentExtension    = NULL;
    self.documentFilePath     = NULL;
    self.scannedImageMetadata = NULL;
    self.colorSyncMode        = NULL;
    
    self.selectedFunctionalUnitTypeString = NULL;
    
    [super dealloc];
}

#pragma mark -
//------------------------------------------------------------------------------------------------------- readProperties

- (void)readProperties
{
    _propertyListDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[self propertyListPath]];
    _functionalUnitSettings = [[NSMutableDictionary alloc] init];
    _scanImageSettings      = [[NSMutableDictionary alloc] init];
    
    NSMutableArray* readFunctionalUnits = [[_propertyListDictionary objectForKey:@"Scanner Properties"] objectForKey:@"functionalUnitProperties"];
    
    for( NSMutableDictionary* p in readFunctionalUnits )
    {
        NSNumber*               unitNumber      = [p objectForKey:@"unitNumber"];
        NSMutableDictionary*    unitProperties  = [p objectForKey:@"unitProperties"];
        NSNumber*               unitDelay       = [p objectForKey:@"unitDelay"];
        
        if ( unitDelay == NULL )
            unitDelay = [NSNumber numberWithInt:0];
        
        NSString *key = [NSString stringWithFormat:@"%ld",[unitNumber unsignedIntegerValue]];
        [_functionalUnitSettings setObject:unitProperties forKey:key];
        NSString *delayKey = [NSString stringWithFormat:@"%d-Delay", [unitNumber unsignedIntValue]];
        [_functionalUnitSettings setObject:unitDelay forKey:delayKey];
          
        self.selectedFunctionalUnitTypeString = [NSString stringWithFormat:@"%d",0];
    }
}

//-------------------------------------------------------------------------------- startReceivingButtonPressesFromDevice

- (void)startReceivingButtonPressesFromDevice
{
    if ( _gIsVirtualScanner )
    {
        CFNotificationCenterRef noteCenter = CFNotificationCenterGetDarwinNotifyCenter();

        if ( noteCenter ) 
        {
            CFNotificationCenterAddObserver(noteCenter,
                                            self,
                                            virtualButtonCallback,
                                            CFSTR("com.apple.VirtualScanner.scanButtonPressed"),
                                            NULL,
                                            CFNotificationSuspensionBehaviorDeliverImmediately);
            
            CFNotificationCenterAddObserver(noteCenter,
                                            self,
                                            virtualButtonCallback,
                                            CFSTR("com.apple.VirtualScanner.copyButtonPressed"),
                                            NULL,
                                            CFNotificationSuspensionBehaviorDeliverImmediately);
            
            CFNotificationCenterAddObserver(noteCenter,
                                            self,
                                            virtualButtonCallback,
                                            CFSTR("com.apple.VirtualScanner.emailButtonPressed"),
                                            NULL,
                                            CFNotificationSuspensionBehaviorDeliverImmediately);
            
            CFNotificationCenterAddObserver(noteCenter,
                                            self,
                                            virtualButtonCallback,
                                            CFSTR("com.apple.VirtualScanner.webButtonPressed"),
                                            NULL,
                                            CFNotificationSuspensionBehaviorDeliverImmediately);
        }
    }
    else if ( self.usbLocationID != 0 )
    {
        // Setup to asynchronously receive scanner button presses from a USB scanner 
    }
    else if ( self.firewireGuid != 0 )
    {
        // Setup to asynchronously receive scanner button presses from a FireWire scanner 
    }
    else if ( self.networkParams != NULL )
    {
        // Setup to asynchronously receive scanner button presses from a network scanner 
    }
}

//--------------------------------------------------------------------------------- stopReceivingButtonPressesFromDevice

- (void)stopReceivingButtonPressesFromDevice
{
    if ( _gIsVirtualScanner )
    {
        CFNotificationCenterRef noteCenter = CFNotificationCenterGetDarwinNotifyCenter();

        if ( noteCenter ) 
        {
            CFNotificationCenterRemoveObserver(noteCenter,
                                            self,
                                            CFSTR("com.apple.VirtualScanner.scanButtonPressed"),
                                            NULL);

            CFNotificationCenterRemoveObserver(noteCenter,
                                            self,
                                            CFSTR("com.apple.VirtualScanner.copyButtonPressed"),
                                            NULL);

            CFNotificationCenterRemoveObserver(noteCenter,
                                            self,
                                            CFSTR("com.apple.VirtualScanner.emailButtonPressed"),
                                            NULL);

            CFNotificationCenterRemoveObserver(noteCenter,
                                            self,
                                            CFSTR("com.apple.VirtualScanner.webButtonPressed"),
                                            NULL);
            
        }
    }
    else if ( self.usbLocationID != 0 )
    {
        // Add code to stop receiving scanner button presses from a USB scanner 
    }
    else if ( self.firewireGuid != 0 )
    {
        // Add code to stop receiving scanner button presses from a FireWire scanner 
    }
    else if ( self.networkParams != NULL )
    {
        // Add code to stop receiving scanner button presses from a network scanner 
    }
}

//----------------------------------------------------------------------------------------------------------------- name
// Return the name of the scanner

- (NSString*)name
{
    NSString* n = [_propertyListDictionary objectForKey:@"Scanner Name"];
    
    if ( n )
        return n;
    else
        return @"Unknown Scanner";
}

//------------------------------------------------------------------------------------------------ numberOfScannedImages
// Return the number of scanned images cached for remote client. Scanned images are not cached for local clients

- (NSUInteger)numberOfScannedImages
{
    return [_scannedImages count];
}

//------------------------------------------------------------------------------------------------ isDocumentUTI_ICA_RAW

- (BOOL)isDocumentUTI_ICA_RAW
{
    return [_documentUTI isEqualToString:(NSString*)kICUTTypeRaw];
}

//------------------------------------------------------ newColorspaceForCurrentFunctionalUnitSettings:bitsPerComponent:andBitsPerPixel

- (CGColorSpaceRef)newColorspaceForCurrentFunctionalUnitSettings:(unsigned int*)bitsPerComponent andBitsPerPixel:(unsigned int*)bitsPerPixel
{
    NSString*       tDirectoryString  = NSTemporaryDirectory();
    NSString*       tPathString       = [tDirectoryString stringByAppendingFormat:@"vs-%d",getpid()];
    CGColorSpaceRef colorspace        = NULL;
    
    switch ( self.pixelType )
    {
        case TWPT_BW:
            colorspace = ICDCreateColorSpace( 8, 1, _deviceObjectInfo->icaObject, (CFStringRef)(self.colorSyncMode), NULL, (char*)[tPathString UTF8String]);
            *bitsPerPixel = 8;
            *bitsPerComponent = 8;
            break;
            
        case TWPT_GRAY:
            colorspace = ICDCreateColorSpace( self.bitDepth, 1, _deviceObjectInfo->icaObject, (CFStringRef)(self.colorSyncMode), NULL, (char*)[tPathString UTF8String]);
            *bitsPerPixel = self.bitDepth;
            *bitsPerComponent = self.bitDepth;
            break;
            
        case TWPT_RGB:
            colorspace = ICDCreateColorSpace(3 * self.bitDepth, 3, _deviceObjectInfo->icaObject, (CFStringRef)(self.colorSyncMode), NULL, (char*)[tPathString UTF8String]);
            *bitsPerPixel = 24*(self.bitDepth/8);
            *bitsPerComponent = self.bitDepth;
            break;
            
        case TWPT_CMYK:
            colorspace = ICDCreateColorSpace(4 * self.bitDepth, 4, _deviceObjectInfo->icaObject, (CFStringRef)(self.colorSyncMode), NULL, (char*)[tPathString UTF8String]);
            *bitsPerPixel = 32*(self.bitDepth/8);
            *bitsPerComponent = self.bitDepth;
            break;
            
        default:
            break;
    }
    
    return colorspace;
}

#pragma mark -
#pragma mark Methods corresponding to functions in EntryPoints.m
//------------------------------------------------------------------------------------------- addPropertiesToDictionary:
// Add device-specific properties to propDict

- (void)addPropertiesToDictionary:(NSMutableDictionary*)propDict
{
    NSString* path  = self.deviceInfoPath;
    
    if ( path )
    {
        NSDictionary* deviceInfoPlistDict = [NSDictionary dictionaryWithContentsOfFile:path];
        
        if ( deviceInfoPlistDict )
        {
            NSString* name  = self.name;
            
            if ( name )
            {
                NSDictionary* devicesDict = [deviceInfoPlistDict objectForKey:@"devices"];
                
                if ( devicesDict )
                {
                    NSDictionary* deviceDict  = [devicesDict objectForKey:name];
                    NSDictionary* buttonDict  = [deviceDict objectForKey:@"ButtonTypes"];
                    NSString*     iconFile    = [deviceDict objectForKey:@"iconFile"];
                    
                    if ( buttonDict )
                        [propDict setObject:buttonDict forKey:@"Buttons"];
                    
                    // If this is properly setup in the DeviceInfo.plist, this is not needed.  This is mostly here to add
                    // more realism to the virtual scanner when a device has been created from a disk image.
                    if ( iconFile && self.createdForDiskImage )
                        [propDict setObject:[NSString stringWithFormat:@"%@/VSCAN/%@", self.volumePath,[iconFile lastPathComponent]] forKey:@"deviceIconPath"];
                }
            }
        }
    }
    
    // Add kICAUserAssignedDeviceNameKey.  Since this key is a simple NSString, the value may be of
    // any length.  This key supercedes any name already provided in the device information before, which
    // is limited to 32 characters.
    [propDict setObject:self.name forKey:(NSString*)kICAUserAssignedDeviceNameKey];             
        
    // Add key indicating that the module supports using the ICA Raw File as a backing store for image io
    [propDict setObject:[NSNumber numberWithInt:1] forKey:@"supportsICARawFileFormat"];
}

//----------------------------------------------------------------------------------------------- openSessionWithParams:
// Open a session

- (ICAError)openSessionWithParams:(ICD_ScannerOpenSessionPB*)pb
{
    ICAError err = noErr;
    
	// This is a very simplistic model for checking if there is already an open session.
    // Other items in the parameter block may be useful to save if one would like to keep
    // the session information and ID, etc. 
    
	if ( YES == self.scannerSessionOpened )
		err = kICAInvalidSessionErr;
    else 
    {
        if ( _gIsVirtualScanner )
        {
            //This is done to clue the bonjour application that's broadcasting in to set the
            //availability appropriately.
            if (notify_post("com.apple.VirtualScanner.scannerUnavailable")) 
            {
                printf("Scanner Notification Failed.\n");
            }
        }
        
        self.scannerSessionOpened = YES;
    }
    
    return err;
}

//---------------------------------------------------------------------------------------------- closeSessionWithParams:
// Close a session

- (ICAError)closeSessionWithParams:(ICD_ScannerCloseSessionPB*)pb
{
    ICAError err = noErr;
    
	// This is a very simplistic model for checking if there is already an open session.
    // Other items in the parameter block may be useful to save if one would like to keep
    // the session information and ID, etc. 
    
	if ( YES != self.scannerSessionOpened )
		err = kICAInvalidSessionErr;
    else 
    {
        if ( _gIsVirtualScanner )
        {
            //This is done to clue the bonjour application that's broadcasting in to set the
            //availability appropriately.
            if (notify_post("com.apple.VirtualScanner.scannerAvailable")) 
            {
                printf("Scanner Notification Failed.\n");
            }
        }
        
        self.scannerSessionOpened = NO;
    }
    
    return err;
}

//------------------------------------------------------------------------------------- getSelectedFunctionalUnitParams:
// Get parameters for currently selected functional unit

- (ICAError)getSelectedFunctionalUnitParams:(ICD_ScannerGetParametersPB*)pb
{
    ICAError              err         = noErr;
	NSMutableDictionary*  paramDict;
    NSMutableDictionary*  deviceDict  = [[NSMutableDictionary alloc] init];
    
	paramDict = (NSMutableDictionary*)(pb->theDict);
	require_action(paramDict, bail, err = paramErr);    
    
    [paramDict setObject:[_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString] forKey:@"device"];
    Log( "Parameters Sent:%s\n",[[[_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString] description] UTF8String] );
    
bail:
    if( deviceDict )
        [deviceDict release];
    
	return err;
}

//------------------------------------------------------------------------------------- setSelectedFunctionalUnitParams:
// Set parameters for currently selected functional unit

- (ICAError)setSelectedFunctionalUnitParams:(ICD_ScannerSetParametersPB*)pb
{
    ICAError              err = noErr;
	NSMutableDictionary*  paramDict;
	NSMutableDictionary*  dict;
		
	// modify scan params and write it back
	paramDict = (NSMutableDictionary*)(pb->theDict);
	require_action(paramDict, bail, err = -1);
    
    Log( "Scan Parameters Passed In:%s\n", [[paramDict description] UTF8String] );
    
    if ([paramDict objectForKey:@"userScanArea"])
    {
        NSObject*   userScanArea = [paramDict objectForKey:@"userScanArea"];
        
        // Check if the user scan area is an array or a dictionary
        if ( [userScanArea isKindOfClass:[NSArray class]] )
		{
			NSArray *array = (NSArray*)userScanArea;
			dict = [array objectAtIndex:1];
        } 
        else
        {
            dict = (NSMutableDictionary*)userScanArea;
        }
 		        
		if ( dict )
		{
            if( [dict objectForKey:@"selectedFunctionalUnitType"] )
            {
                Log( "    Changing Functional Unit\n" );
                // check if we are switching to the current selected unit
                NSString* selectedFunctionalUnit = [NSString stringWithFormat:@"%ld",[[dict objectForKey:@"selectedFunctionalUnitType"] unsignedIntegerValue]];
                
                if ( [selectedFunctionalUnit isEqualToString:self.selectedFunctionalUnitTypeString] )
                    return noErr;
            
                self.selectedFunctionalUnitTypeString = [NSString stringWithFormat:@"%ld", [[dict objectForKey:@"selectedFunctionalUnitType"] unsignedIntegerValue]];
                
                NSString *delayKey = [NSString stringWithFormat:@"%s-Delay", [self.selectedFunctionalUnitTypeString UTF8String]];
                NSNumber *delay = [_functionalUnitSettings objectForKey:delayKey];
                if ( delay )
                    usleep( 1000000LL * [delay unsignedIntValue] );
                
                return noErr;
            }
            else 
            {
                Log( "   Update scan parameters: \n" );
                [self updateScanParamsUsingValuesInDictionary:dict];
            }
        }
            
		// check if we want to use progressive notification
		if ([dict objectForKey:@"progressNotificationWithData"])
			self.sendProgressNotificationsWithOverviewData  = [[dict objectForKey:@"progressNotificationWithData"] boolValue];
		else
			self.sendProgressNotificationsWithOverviewData  = NO;
        
		if ([dict objectForKey:@"progressNotificationNoData"])
			self.sendProgressNotificationsWithoutData = [[dict objectForKey:@"progressNotificationNoData"] boolValue];
		else
			self.sendProgressNotificationsWithoutData = NO;
        
        if ([dict objectForKey:@"progressNotificationWithScanData"])
			self.sendProgressNotificationsWithScanData = [[dict objectForKey:@"progressNotificationWithScanData"] boolValue];
		else
			self.sendProgressNotificationsWithScanData = NO;
        
        if ([dict objectForKey:@"progressNotificationWithScanDataMaxBandSize"])
			self.maxProgressBandSize = [[dict objectForKey:@"progressNotificationWithScanDataMaxBandSize"] intValue];
		else
			self.maxProgressBandSize = 512 * 1024;        
		
		// save color profile mode string
        self.colorSyncMode    = [dict objectForKey:@"ColorSyncMode"];
 
		// The value of the "document name" key is the name of the scanned document 
        self.documentName = [dict objectForKey:@"document name"];
        
        // The "document folder" key will be absent when a scan is performed by a remote client
        self.documentFolderPath = [dict objectForKey:@"document folder"];
            
		self.documentUTI        = [dict objectForKey:@"document format"];

        if ( ( self.documentUTI == NULL ) && [[dict objectForKey:@"progressNotificationNoData"] boolValue] )
            self.documentUTI = (NSString*)kUTTypeTIFF;
        
		self.documentExtension  = [dict objectForKey:@"document extension"];
        
        if ( ( self.documentExtension == NULL ) && [[dict objectForKey:@"progressNotificationNoData"] boolValue] )
        {
            NSString* ext = (NSString*)UTTypeCopyPreferredTagWithClass( (CFStringRef)self.documentUTI, kUTTagClassFilenameExtension);
    
            if ( ext )
            {
                self.documentExtension = ext;
                [ext release];
            }
        }
        
		// Save metadata like rotation, dpi info, etc.
		self.scannedImageMetadata = [dict objectForKey: @"metadata"];
                
        NSNumber* imageHeight = nil;
        if( ( imageHeight = [dict objectForKey:@"height"] ) )
            [_scanImageSettings setObject:imageHeight forKey:@"scanImageHeight"];
        
        NSNumber* imageWidth = nil;
        if( ( imageWidth = [dict objectForKey:@"width"] ) )
            [_scanImageSettings setObject:imageWidth forKey:@"scanImageWidth"];
        
        NSNumber* offsetX = nil;
        if( ( offsetX = [dict objectForKey:@"offsetX"] ) )
            [_scanImageSettings setObject:offsetX forKey:@"offsetX"];
        
        NSNumber* offsetY = nil;
        if( ( offsetY = [dict objectForKey:@"offsetY"] ) )
            [_scanImageSettings setObject:offsetY forKey:@"offsetY"];
    }

bail:
	return err;
}

//--------------------------------------------------------------------------------------------- startScanningWithParams:
// Start scanning using parameters

/*
  Discussion:  This method goes through the motions to create a byte buffer with the selected bit depth and
  output type from an image.
 
  In reality, receiving data from the scanner at this point and formatting the buffers for each mode would 
  be the appropriate way to go, and this is only a demonstration of the virtual scanning capability at the moment.
  
  The developer should modify this method when scanning from a USB, FireWire or network scanner.
*/

- (ICAError)startScanningWithParams:(ICD_ScannerStartPB*)pb
{
    ICAError  err         = noErr;
    BOOL      userCancel  = NO;
    
    //Scan requested DPI settings
    double    xDPI = self.xResolution;
    double    yDPI = self.yResolution;

    //512k will be used for each band unless overridden by band size settings from the client
    double    maxBandByteSize = self.maxProgressBandSize;
    
    //Loadable test image
    CFURLRef          fileRef     = CFURLCreateWithFileSystemPath(
                                                    kCFAllocatorDefault,
                                                    (CFStringRef)(self.sampleImageFilePath),
                                                    kCFURLPOSIXPathStyle,
                                                    0
                                                );
    
    CGImageSourceRef  imageSrcRef = CGImageSourceCreateWithURL( fileRef, NULL );

    // set up image io if we are doing final scan
    NSDictionary*     metaData    = (NSMutableDictionary*)CGImageSourceCopyPropertiesAtIndex( imageSrcRef, 0, NULL );
        
    //Create a data provider so we can skip around the bitmap
    CGDataProviderSequentialCallbacks scanCallbacks = {0, dpGetBytes, dpSkipBytes, dpRewind, dpReleaseProvider};
    CGDataProviderRef                 scanDataProvider;
    
    //Grab our source images parameters so we can stretch.
    //For now, we don't maintain any aspect ratio, but in the future we could figure out which aspect to clip to.
    NSNumber* imageWidth  = [metaData objectForKey:@"PixelWidth"];
    NSNumber* imageHeight = [metaData objectForKey:@"PixelHeight"];
    
    if( !( imageWidth && imageHeight ) )
    {
        
        if( metaData )
            [metaData release];
        
        if( fileRef )
            CFRelease ( fileRef );
        
        if( imageSrcRef )
            CFRelease ( imageSrcRef );
        
        return kICADeviceInternalErr;
    }
    
    double        scanImageDPIRatioWidth  =  ( ( self.physicalWidth / self.xNativeResolution ) * (double)xDPI);
    double        scanImageDPIRatioHeight =  ( ( self.physicalHeight / self.yNativeResolution ) * (double)yDPI);
 
    unsigned int  scanImageWidth          = [[_scanImageSettings objectForKey:@"scanImageWidth"] unsignedIntValue];
    unsigned int  scanImageHeight         = [[_scanImageSettings objectForKey:@"scanImageHeight"] unsignedIntValue];
    
    // If we wanted to specify more than one scan here for document feeder, we could do it as an example.
    int documentFeederScans = 2;

    do
    {
        CGImageRef  imageRefFinal = NULL;

        // Set up image io if we are doing the final scan
        if ( !self.sendProgressNotificationsWithOverviewData )
        {
            if( self.sendProgressNotificationsWithoutData )
            {
                // Set a unique file path for the new scan file including the temp ICA raw file as backing store
                [self setOutputFilePath];
                // Create a raw image data file
                [self openRawFileForWriting];
            }
            
            // Compute the points and offsets using the original image to create a subimage to pull from.
            double xOffsetRatio = scanImageDPIRatioWidth / [imageWidth doubleValue];
            double yOffsetRatio = scanImageDPIRatioHeight / [imageHeight doubleValue];
            
            int xCoord =  xDPI * ( [[_scanImageSettings objectForKey:@"offsetX"] doubleValue] / self.xNativeResolution );
            int yCoord =  yDPI * ( [[_scanImageSettings objectForKey:@"offsetY"] doubleValue] / self.yNativeResolution );
            
            CGImageRef tempImage = ( imageSrcRef ? CGImageSourceCreateImageAtIndex( imageSrcRef, 0, nil ) : nil );
            
            if( tempImage )
            {
                imageRefFinal = CGImageCreateWithImageInRect(
                                                        tempImage, 
                                                        CGRectMake( 
                                                            xCoord / xOffsetRatio, 
                                                            yCoord / yOffsetRatio, 
                                                            scanImageWidth / xOffsetRatio, 
                                                            scanImageHeight / yOffsetRatio
                                                        ) 
                                                    );
                
                CGImageRelease( tempImage );
            }
        }
        else
        {
            //If we are doing an overview scan we don't need to bother with the above, because the entire image will be transferred 
            //regardless of subsampling.
            imageRefFinal = ( imageSrcRef ? CGImageSourceCreateImageAtIndex( imageSrcRef, 0, nil ) : nil );
        }
        
        //If something happened to the image when we were doing all of the above, bail!
        if( !imageRefFinal )
        {
            if( metaData )
                [metaData release];
            
            if( fileRef )
                CFRelease ( fileRef );
            
            if( imageSrcRef )
                CFRelease ( imageSrcRef );
            
            return kICADeviceInternalErr;
        }
        
        
        // Fake warmup status
        unsigned int warmupTestTime = 0500000L;
        
        if( warmupTestTime > 0 )
        {
            [self showWarmUpMsg];
            // Warming up those transistors and tubes.
            usleep(warmupTestTime);		
            [self doneWarmUpMsg];
        }

        //Setup bitmap context information
        CGContextRef  bitmapContext = nil;  
        
        // Create a color space profile based on the settings that were passed in, retrieve bit settings
        unsigned int bitsPerComponent           = 0;
        unsigned int bitsPerPixel               = 0;
        
        CGColorSpaceRef newcolorspace           = [self newColorspaceForCurrentFunctionalUnitSettings:&bitsPerComponent andBitsPerPixel:&bitsPerPixel];
        CGColorSpaceModel colorSpaceModel       = CGColorSpaceGetModel( newcolorspace );
        
        int           bytesPerComponent         = bitsPerComponent/8;    
        int           numComponents             = ( bitsPerPixel / bitsPerComponent );
        CGImageAlphaInfo    alphaInfo           = kCGImageAlphaNone;
        
        ICScannerPixelDataType pixelDataType    = ICScannerPixelDataTypeRGB;
        
        switch ( colorSpaceModel )
        {
            case kCGColorSpaceModelMonochrome:
            {
                alphaInfo       = kCGImageAlphaNone;
                pixelDataType   = ICScannerPixelDataTypeGray;
            }
                break;
                
            case kCGColorSpaceModelCMYK:
            {
                alphaInfo       = kCGImageAlphaNone;
                pixelDataType   = ICScannerPixelDataTypeCMYK;
            }            
                break;
                
            case kCGColorSpaceModelRGB:
            default:
            {
                alphaInfo       = kCGImageAlphaPremultipliedLast;
                pixelDataType   = ICScannerPixelDataTypeRGB;
            }
                break;
        }
        
        // Setting up the bitmap context variables
        unsigned int  bitmapBytesPerRow         = scanImageWidth * ( numComponents*bytesPerComponent + ( ( alphaInfo == kCGImageAlphaNone ) ? 0:1 )*bytesPerComponent );
        int           bitmapRowsPerBand         = ( bitmapBytesPerRow >= maxBandByteSize ) ? 1 : ( maxBandByteSize / bitmapBytesPerRow );
        int           bitmapNumBands            = scanImageHeight / bitmapRowsPerBand;
        int           bitmapLastBandSize        = scanImageHeight % bitmapRowsPerBand;
        unsigned int  bitmapBytesPerBand        = bitmapBytesPerRow * bitmapRowsPerBand;
        UInt8*        bitmapImage               = nil;
        
        // Setting up image context variables
        int           imageBytesPerRow          = 0;
        int           imageBitsPerPixel         = 0;
        int           imageBitsPerComponent     = 0;
        int           imageSkipBits             = 0;
        int           imageContextRowsPerBand   = 0; 
        int           imageBlackThreshold       = 0x80;
        
        if ( self.bitDepth != 1 )
        {
            imageBytesPerRow        = ( scanImageWidth * numComponents * ( bytesPerComponent ) );
            imageBitsPerPixel       = bitsPerPixel;
            imageBitsPerComponent   = bitsPerComponent;
        }
        else 
        {
            imageBytesPerRow = ( scanImageWidth * numComponents * ( bytesPerComponent ) ) / 8;
            imageSkipBits    = ( scanImageWidth * numComponents * ( bytesPerComponent ) ) % 8;
            
            if( imageSkipBits  > 1 )
                imageBytesPerRow++;
           
            imageBitsPerPixel       = 1;
            imageBitsPerComponent   = 1;
        }
        
        bitmapImage   = malloc( bitmapBytesPerBand ); 
        
        //Start point for the Translate needs to be in the negative y coordinate starting at the top of the image
        int startPoint = scanImageHeight*-1;
        
        //Start point for the Image to be sent to ImageCapture Extension needs to be in the positive coordinate starting at zero
        int fillPoint  = 0;
        
        // write ica raw file image header
        if ( self.sendProgressNotificationsWithoutData )
        {
            ICARawFileHeader* h = (ICARawFileHeader *)bitmapImage;

            h->imageDataOffset      = sizeof(ICARawFileHeader);
            h->version              = 1;
            h->imageWidth           = scanImageWidth;
            h->imageHeight          = scanImageHeight;
            h->bytesPerRow          = imageBytesPerRow;
            h->bitsPerComponent     = imageBitsPerComponent;
            h->bitsPerPixel         = imageBitsPerPixel;     
            h->numberOfComponents   = numComponents;
            h->cgColorSpaceModel    = CGColorSpaceGetModel(newcolorspace);
            h->bitmapInfo           = kCGImageAlphaNone;
            h->dpi                  = xDPI;
            h->orientation          = [self.scannedImageMetadata objectForKey:@"Orientation"] ? 
                                      [[self.scannedImageMetadata objectForKey:@"Orientation"] intValue] : 1;
            strlcpy( h->colorSyncModeStr, [self.colorSyncMode UTF8String], sizeof(h->colorSyncModeStr) );
            
            [self writeRawFileWithBuffer:(char*)bitmapImage ofSize:sizeof(ICARawFileHeader)];
        }
        
        for ( int i = bitmapNumBands; (i >= 0 && !userCancel); --i )
        {
            if( ( i == bitmapNumBands ) && ( bitmapNumBands != 0 ) )
            {
                bitmapContext = CGBitmapContextCreate( 
                                                     bitmapImage, 
                                                     scanImageWidth, 
                                                     bitmapRowsPerBand, 
                                                     bitsPerComponent,
                                                     bitmapBytesPerRow, 
                                                     newcolorspace,
                                                     alphaInfo
                                                     );
                
                imageContextRowsPerBand = bitmapRowsPerBand;
            }
            else if( ( bitmapLastBandSize > 1 ? 1 : 0 ) && i == 0 )
            {
                CGContextRelease( bitmapContext );
                bitmapContext = CGBitmapContextCreate( 
                                                      bitmapImage, 
                                                      scanImageWidth, 
                                                      bitmapLastBandSize, 
                                                      bitsPerComponent,  
                                                      bitmapBytesPerRow, 
                                                      newcolorspace,
                                                      alphaInfo
                                                      );
                
                imageContextRowsPerBand = bitmapLastBandSize;
            }
               
            
            if ( bitmapContext )
            {   
                startPoint += imageContextRowsPerBand;
                
                CGContextSaveGState(bitmapContext);
                CGRect drawRect = CGRectMake( 0, 0, scanImageWidth, scanImageHeight );
                
                CGContextTranslateCTM( bitmapContext, 0, startPoint );
                CGContextClearRect( bitmapContext, drawRect ); 
                CGContextDrawImage( bitmapContext, drawRect, imageRefFinal ); 
                
                //If there is an alpha channel, we have to fake like we're coming from a scanner and 
                //remove it here.
                if( ( kCGImageAlphaNone != alphaInfo ) )
                {
                    int offset = 0;
                    int j = 0;
                    
                    for( j=numComponents*bytesPerComponent; j < (imageContextRowsPerBand*imageBytesPerRow); j+=numComponents*bytesPerComponent )
                    {
                        int k = 0;
                        for( k = 0; k < numComponents*bytesPerComponent; k++)
                            bitmapImage[j+k] = bitmapImage[j+k+bytesPerComponent+offset];
                        offset+=bytesPerComponent;
                    }
                }
                else if ( imageBitsPerPixel == 1 )
                {
                    int offset = 0;
                    int j      = 0;
                    int rowPos = 0;
                    int inc    = 8;
                    
                    for ( j = 0; j < imageContextRowsPerBand*bitmapBytesPerRow; j+=inc )
                    {
                        char b = 0;
                        for( int k = 0; k<8 && rowPos != bitmapBytesPerRow; k++ )
                        {
                            b += ( bitmapImage[k+j] > imageBlackThreshold ? 1 : 0 ) << 7-k;
                            rowPos++;
                        }
                        if( rowPos == bitmapBytesPerRow )
                        {
                            if( imageSkipBits!=0 )
                                inc = imageSkipBits;
                            rowPos = 0;
                        }
                        else
                            inc = 8;
                        
                        bitmapImage[offset]=b;
                        offset++;
                    }
                }
                
                ICASendNotificationPB notePB        = {};
                NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
                
                [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
                [notification setObject:(id)kICANotificationTypeScanProgressStatus forKey:(id)kICANotificationTypeKey];

                notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
                
                if ( self.sendProgressNotificationsWithOverviewData )
                {
                    ICDAddImageInfoToNotificationDictionary(
                                          (CFMutableDictionaryRef)notification,
                                          scanImageWidth,
                                          scanImageHeight,
                                          imageBytesPerRow, 
                                          fillPoint,
                                          imageContextRowsPerBand,
                                          (imageBytesPerRow*imageContextRowsPerBand),
                                          bitmapImage
                                      );
                }
                else if ( self.sendProgressNotificationsWithScanData )
                {
                    void    *dlHandle;
                     
                    // Open ICADevices to check and see if we can use the banded data function.
                    // This will ensure interoperability with both 10.6 and 10.7+ 
                    dlHandle = dlopen("/System/Library/Frameworks/ICADevices.framework/ICADevices", RTLD_LOCAL | RTLD_LAZY );
                    
                    if ( NULL != dlHandle ) 
                    {
                        int       (*fPtr)(CFMutableDictionaryRef, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, ICScannerPixelDataType, unsigned int, int, unsigned int, unsigned int, void*);
                        *(void **)(&fPtr) = dlsym( dlHandle, "ICDAddBandInfoToNotificationDictionary");
                        
                        if( NULL != fPtr )
                        {
                            (*fPtr)( (CFMutableDictionaryRef)notification,
                                    scanImageWidth,
                                    scanImageHeight,
                                    imageBitsPerPixel,
                                    imageBitsPerComponent,
                                    numComponents,
                                    0,
                                    pixelDataType,
                                    imageBytesPerRow, 
                                    fillPoint,
                                    imageContextRowsPerBand,
                                    (imageBytesPerRow*imageContextRowsPerBand),
                                    bitmapImage
                                    );
                        }
                        dlclose(dlHandle);
                    }
                }
                else if ( self.sendProgressNotificationsWithoutData )
                {
                    ICDAddImageInfoToNotificationDictionary( 
                                          (CFMutableDictionaryRef)notification,
                                          scanImageWidth,
                                          scanImageHeight,
                                          imageBytesPerRow, 
                                          fillPoint,
                                          imageContextRowsPerBand, 
                                          0, 
                                          NULL
                                      );
                                      
                    // write band to raw image file
                    [self writeRawFileWithBuffer:(char*)bitmapImage ofSize:(imageBytesPerRow*imageContextRowsPerBand)];
                    if( i == 0 )
                        [self closeRawFile];
                }
            
                if ( ICDSendNotificationAndWaitForReply( &notePB ) == noErr )
                {
                    userCancel = (notePB.replyCode == userCanceledErr);
                }
                
                [notification release];
                fillPoint+= (imageContextRowsPerBand);
                CGContextRestoreGState(bitmapContext);
            }        
        }
        // set up image io if we are doing final scan and we are generating real image file ( not ICA RAW file ).
        if ( self.sendProgressNotificationsWithoutData && (self.isDocumentUTI_ICA_RAW == NO) )
        {
            scanDataProvider = CGDataProviderCreateSequential( self, &scanCallbacks );
            
            _rawCGImageRef = CGImageCreate(
                                           scanImageWidth, 
                                           scanImageHeight,
                                           imageBitsPerComponent, 
                                           imageBitsPerPixel, 
                                           imageBytesPerRow,
                                           newcolorspace,
                                           kCGImageAlphaNone,
                                           scanDataProvider,
                                           NULL,
                                           false,
                                           kCGRenderingIntentDefault
                                           );
            
            if ( NULL == _rawCGImageRef )
            {
                printf("    ERROR - CGImageCreate failed\n"); 
            }
            
            CGDataProviderRelease( scanDataProvider );
            
            // user did not cancel
            if ( !userCancel )
            {
                // write image file via data provider processing raw image data file                
                [self saveImageWithWidth: scanImageWidth andHeight:scanImageHeight];
            }
            
            if (_rawCGImageRef) 
            {
                CGImageRelease(_rawCGImageRef);
                _rawCGImageRef = NULL;
            }
        }
        
        if ( bitmapContext )
            CGContextRelease( bitmapContext );
     
        //Send the page done notifications.
        ICASendNotificationPB notePB        = {};
        NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        // send page done notification
        [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
        [notification setObject:(id)kICANotificationTypeScannerPageDone forKey:(id)kICANotificationTypeKey];
        
        if ( self.sendProgressNotificationsWithoutData )
            CFDictionaryAddValue( (CFMutableDictionaryRef)notification, kICANotificationScannerDocumentNameKey, self.documentFilePath );
        
        notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
        ICDSendNotification( &notePB );
        [notification release];
        documentFeederScans--;
        
        free( bitmapImage );
        
        // If the client is a network client trigger a new object created for every page that has been scanned
        if ( ( !userCancel ) && 
             ( self.documentFolderPath == NULL ) && 
             ( self.sendProgressNotificationsWithoutData ) )
        {
            ScannedImage* newImage = [[ScannedImage alloc] initWithFilePath:self.documentFilePath scannerObject:self imageWidth:scanImageWidth imageHeight:scanImageHeight];
                        
            if ( newImage )
            {
                ICAObject newICAObject = 0;
                
                [_scannedImages addObject:newImage];
                [newImage release];
            
            
                if ( ICDScannerNewObjectInfoCreated( _deviceObjectInfo, 0, &newICAObject ) == noErr )
                {
                    newImage.icaObject = newICAObject;
                    memset( &notePB, 0, sizeof(notePB) );
                    notification = [[NSMutableDictionary alloc] initWithCapacity:0];
                    [notification setObject:[NSNumber numberWithUnsignedInt:newICAObject] forKey:(id)kICANotificationICAObjectKey];
                    [notification setObject:(id)kICANotificationTypeObjectAdded forKey:(id)kICANotificationTypeKey];
                    
                    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
                    ICDSendNotification( &notePB );
                    [notification release];
                }
                else
                {
                    [_scannedImages removeObject:newImage];
                }
            }
        }
        
        if( imageRefFinal )
            CGImageRelease( imageRefFinal );
        
        if( newcolorspace )
            CGColorSpaceRelease( newcolorspace );
    } 
    while ( ( [self.selectedFunctionalUnitTypeString isEqualToString:@"3"] ) && ( documentFeederScans > 0 ) && !userCancel );
    
    // send job done notification
    ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];

    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeScannerScanDone forKey:(id)kICANotificationTypeKey];

    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
    ICDSendNotification( &notePB );
    [notification release];
    
    if ( metaData )
        CFRelease( metaData );        

    if ( fileRef )
        CFRelease( fileRef );
    
    if ( imageSrcRef )
        CFRelease( imageSrcRef );
    
	if ( userCancel )
	{
        printf("----> User Canceled Scan! \n");
        ICASendNotificationPB notePB = {};
        NSMutableDictionary*  notification = [NSMutableDictionary dictionaryWithCapacity:0]; 
        
        [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
        [notification setObject:(id)kICANotificationTypeTransactionCanceled forKey:(id)kICANotificationTypeKey];
        
        notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
        err = ICDSendNotification( &notePB );
	}
    
bail:
    return err;
    
}

#pragma mark -
#pragma mark Accessors for scan parameters
//--------------------------------------------------------------------------------------- setValueForKey:fromDictionary:

- (void)setValueForKey:(NSString*)key fromDictionary:(NSDictionary*)dict
{
    if( [dict objectForKey:key] )
    {
        NSMutableDictionary* selectedFunctionalUnitSettings = [_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString];
        
        NSMutableDictionary* scannerElement = [selectedFunctionalUnitSettings objectForKey:key];
        
        if( scannerElement )
        {
            if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_ONEVALUE"] )
            {
                [selectedFunctionalUnitSettings setObject: [dict objectForKey:key] forKey:key];
            }
            else if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_ENUMERATION"] )
            {
                int index = 0;
                for( NSNumber* scannerElementValue in [scannerElement objectForKey:@"value"] )
                {
                    if( [scannerElementValue isEqualToNumber:[[dict objectForKey:key] objectForKey:@"value"]] )
                    {
                        [scannerElement setObject:[NSNumber numberWithUnsignedInt:index] forKey:@"current"];
                        break;
                    }
                    index++;
                }
            }
            else if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_RANGE"] )
            {
                NSNumber* minValue = [scannerElement objectForKey:@"min"];
                NSNumber* maxValue = [scannerElement objectForKey:@"max"];
                
                NSNumber* value    = [[dict objectForKey:key] objectForKey:@"value"];
                
                if( [value unsignedIntegerValue] >= [minValue unsignedIntegerValue] &&
                    [value unsignedIntegerValue] <= [maxValue unsignedIntegerValue] )
                {
                    [scannerElement setObject:[NSNumber numberWithUnsignedInt:[value unsignedIntegerValue]] forKey:@"current"];
                }
            }
        }
        else 
        {
            [selectedFunctionalUnitSettings setObject: [dict objectForKey:key] forKey:key];
        }
    }
}

//---------------------------------------------------------------------------- setValuesForVendorFeaturesFromDictionary:

- (void)setValuesForVendorFeaturesFromDictionary:(NSDictionary*)dict
{
    NSMutableDictionary* selectedFunctionalUnitSettings = [_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString];
        
    NSArray* currentVendorFeatures = [selectedFunctionalUnitSettings objectForKey:@"vendor features"];
 
    NSArray* inputVendorFeatures = [dict objectForKey:@"vendor features"];
        
    if( currentVendorFeatures )
    {
        for ( NSMutableDictionary *currentFeature in currentVendorFeatures )
        {
            for ( NSDictionary *inputFeature in inputVendorFeatures )
            {
                if( [[currentFeature objectForKey:@"feature"] isEqualToString:[inputFeature objectForKey:@"feature"]] )
                {
                    if( [[currentFeature objectForKey:@"type"] isEqualToString:@"TWON_ONEVALUE"] )
                    {
                        [currentFeature setObject:[inputFeature objectForKey:@"value"] forKey:@"value"];
                    }
                    else if( [[currentFeature objectForKey:@"type"] isEqualToString:@"TWON_ENUMERATION"] )
                    {
                        int index = 0;
                        for( NSNumber* featureValue in [currentFeature objectForKey:@"value"] )
                        {
                            if( [featureValue isEqualToNumber:[inputFeature objectForKey:@"value"]] )
                            {
                                [currentFeature setObject:[NSNumber numberWithUnsignedInt:index] forKey:@"current"];
                                break;
                            }
                            index++;
                        }
                    }
                    else if( [[currentFeature objectForKey:@"type"] isEqualToString:@"TWON_RANGE"] )
                    {
                        NSNumber* minValue = [currentFeature objectForKey:@"min"];
                        NSNumber* maxValue = [currentFeature objectForKey:@"max"];
                        
                        NSNumber* value    = [inputFeature objectForKey:@"value"];
                        
                        if( [value unsignedIntegerValue] >= [minValue unsignedIntegerValue] &&
                           [value unsignedIntegerValue] <= [maxValue unsignedIntegerValue] )
                        {
                            [currentFeature setObject:[NSNumber numberWithUnsignedInt:[value unsignedIntegerValue]] forKey:@"current"];
                        }
                    }
                    break;
                }
            }
        }
    }
}

//------------------------------------------------------------------------------------------------------ getValueForKey:

- (NSNumber*)getValueForKey:(NSString*)key
{
    NSMutableDictionary* selectedFunctionalUnitSettings = [_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString];
    
    NSMutableDictionary* scannerElement = [selectedFunctionalUnitSettings objectForKey:key];
    
    if( scannerElement )
    {
        if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_ONEVALUE"] )
        {
            return [scannerElement objectForKey:@"value"];
        }
        else if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_ENUMERATION"] )
        {
            NSNumber* current = [scannerElement objectForKey:@"current"];
            
            NSArray*  values = [scannerElement objectForKey:@"value"];
            
            return [values objectAtIndex:[current unsignedIntValue]];
            
        }
        else if( [[scannerElement objectForKey:@"type"] isEqualToString:@"TWON_RANGE"] )
        {
            return [scannerElement objectForKey:@"current"];
        }
    }
    return nil;
}

//-------------------------------------------------------------------------------------------- getValueForVendorFeature:

- (NSNumber*)getValueForVendorFeature:(NSString*)featureName
{
    NSMutableDictionary* selectedFunctionalUnitSettings = [_functionalUnitSettings objectForKey:self.selectedFunctionalUnitTypeString];
    
    NSArray* vendorFeatures = [selectedFunctionalUnitSettings objectForKey:@"vendor features"];
    
    if( vendorFeatures )
    {
        for ( NSDictionary *feature in vendorFeatures )
        {
            if( [[feature objectForKey:@"feature"] isEqualToString:featureName] )
            {
                if( [[feature objectForKey:@"type"] isEqualToString:@"TWON_ONEVALUE"] )
                {
                    return [feature objectForKey:@"value"];
                }
                else if( [[feature objectForKey:@"type"] isEqualToString:@"TWON_ENUMERATION"] )
                {
                    NSNumber* current = [feature objectForKey:@"current"];
                    
                    NSArray*  values = [feature objectForKey:@"value"];
                    
                    return [values objectAtIndex:[current unsignedIntValue]];
                    
                }
                else if( [[feature objectForKey:@"type"] isEqualToString:@"TWON_RANGE"] )
                {
                    return [feature objectForKey:@"current"];
                }
            }
        }
    }
    return nil;
}

//--------------------------------------------------------------------------------------------------------------- setter

- (void)updateScanParamsUsingValuesInDictionary:(NSDictionary*)dict
{
    [self setValueForKey:@"ICAP_BITDEPTH" fromDictionary:dict];
    [self setValueForKey:@"ICAP_PIXELTYPE" fromDictionary:dict];
    [self setValueForKey:@"ICAP_UNITS" fromDictionary:dict];
    [self setValueForKey:@"ICAP_XRESOLUTION" fromDictionary:dict];
    [self setValueForKey:@"ICAP_YRESOLUTION" fromDictionary:dict];
    [self setValueForKey:@"ICAP_XSCALING" fromDictionary:dict];
    [self setValueForKey:@"ICAP_YSCALING" fromDictionary:dict];
    [self setValuesForVendorFeaturesFromDictionary:dict];
}

//-------------------------------------------------------------------------------------------------------------- getters

- (unsigned int)bitDepth        { return [[self getValueForKey:@"ICAP_BITDEPTH"] unsignedIntValue]; }
- (unsigned int)pixelType       { return [[self getValueForKey:@"ICAP_PIXELTYPE"] unsignedIntValue]; }
- (double)xResolution           { return [[self getValueForKey:@"ICAP_XRESOLUTION"] doubleValue]; }
- (double)yResolution           { return [[self getValueForKey:@"ICAP_YRESOLUTION"] doubleValue]; }
- (double)xNativeResolution     { return [[self getValueForKey:@"ICAP_XNATIVERESOLUTION"] doubleValue]; }
- (double)yNativeResolution     { return [[self getValueForKey:@"ICAP_YNATIVERESOLUTION"] doubleValue]; }
- (double)physicalWidth         { return [[self getValueForKey:@"ICAP_PHYSICALWIDTH"] doubleValue]; }
- (double)physicalHeight        { return [[self getValueForKey:@"ICAP_PHYSICALHEIGHT"] doubleValue]; }

#pragma mark -
#pragma mark Method to send out notifications to client
//----------------------------------------------------------------------------------------------- requestOverviewScanMsg

- (void)requestOverviewScanMsg
{
	ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	// Send a message to client to invoke an overview scan
    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeDeviceStatusInfo forKey:(id)kICANotificationTypeKey];
    [notification setObject:(id)kICANotificationSubTypePerformOverviewScan forKey:(id)kICANotificationSubTypeKey];
    
    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
	ICDSendNotification( &notePB );
    [notification release];
}

//-------------------------------------------------------------------------------------------------------- showWarmUpMsg

- (void)showWarmUpMsg
{
	ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
    
	// Send scanner warm up started notification
    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeDeviceStatusInfo forKey:(id)kICANotificationTypeKey];
    [notification setObject:(id)kICANotificationSubTypeWarmUpStarted forKey:(id)kICANotificationSubTypeKey];

    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
	ICDSendNotification( &notePB );
    [notification release];
}

//-------------------------------------------------------------------------------------------------------- doneWarmUpMsg

- (void)doneWarmUpMsg
{
	ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
    
	// Send scanner warm up done notification
    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeDeviceStatusInfo forKey:(id)kICANotificationTypeKey];
    [notification setObject:(id)kICANotificationSubTypeWarmUpDone forKey:(id)kICANotificationSubTypeKey];
    
    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
	ICDSendNotification( &notePB );
    [notification release];
}

//----------------------------------------------------------------------------------------------------- feederNoPaperMsg

- (void)feederNoPaperMsg
{
	ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
    
	// Send scanner document feeder error notification
    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeDeviceStatusError forKey:(id)kICANotificationTypeKey];
    [notification setObject:@"kICAErrStrDFEmptyErr" forKey:(id)kICANotificationSubTypeKey]; // error strings located in ICADevices.framework

    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
	ICDSendNotification( &notePB );
    [notification release];
}

//--------------------------------------------------------------------------------------------------- createInvertedRect

- (NSData*)newInvertedRect:(NSDictionary*)paramDict
{
    if( [[self getValueForVendorFeature:@"VF_Invert"] unsignedIntValue] == YES )
    {
        NSNumber* xDPI = [[paramDict objectForKey:@"ICAP_XRESOLUTION"] objectForKey:@"value"];
        NSNumber* yDPI = [[paramDict objectForKey:@"ICAP_YRESOLUTION"] objectForKey:@"value"];
        
        //Loadable test image
        CFURLRef fileRef= CFURLCreateWithFileSystemPath( kCFAllocatorDefault,
                                                        (CFStringRef)(self.sampleImageFilePath),
                                                        kCFURLPOSIXPathStyle, 0
                                                        );
        
        CGImageSourceRef    imageSrcRef     = CGImageSourceCreateWithURL( fileRef, NULL );
        CGImageRef          imageRefOrig    = ( imageSrcRef ? CGImageSourceCreateImageAtIndex( imageSrcRef, 0, nil ) : nil );
        CGImageRef          imageRefFinal   = NULL;
          
        // set up image io if we are doing final scan
        NSDictionary * metaData = (NSMutableDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSrcRef, 0, NULL);

        //Grab our source images parameters so we can stretch.
        //For now, we don't maintain any aspect ratio, but in the future we could figure out which aspect to clip to.
        NSNumber* imageWidth  = [metaData objectForKey:@"PixelWidth"];
        NSNumber* imageHeight = [metaData objectForKey:@"PixelHeight"];
        
        if( !( imageWidth && imageHeight ) )
        {
            if( metaData )
                [metaData release];
            
            if( fileRef )
                CFRelease ( fileRef );
            
            if( imageSrcRef )
                CFRelease ( imageSrcRef );
            
            if( imageRefOrig )
                CFRelease ( imageRefOrig );
            
            return NULL;
        }
        
        double      scanImageDPIRatioWidth  =  ( ( self.physicalWidth / self.xNativeResolution ) * [xDPI doubleValue]);
        double      scanImageDPIRatioHeight =  ( ( self.physicalHeight / self.yNativeResolution ) * [yDPI doubleValue]);
        
        unsigned int scanImageWidth         = [[paramDict objectForKey:@"width"] unsignedIntValue];
        unsigned int scanImageHeight        = [[paramDict objectForKey:@"height"] unsignedIntValue];
        
        // Compute the points and offsets using the original image to create a subimage to pull from.
        double  xOffsetRatio  = scanImageDPIRatioWidth / [imageWidth doubleValue];
        double  yOffsetRatio  = scanImageDPIRatioHeight / [imageHeight doubleValue];
        
        int     xCoord        =   ( [[paramDict objectForKey:@"offsetX"] doubleValue] );
        int     yCoord        =   ( [[paramDict objectForKey:@"offsetY"] doubleValue] );
        
        imageRefFinal = CGImageCreateWithImageInRect(imageRefOrig, 
                                                        CGRectMake( 
                                                                   xCoord / xOffsetRatio, 
                                                                   yCoord / yOffsetRatio, 
                                                                   scanImageWidth / xOffsetRatio, 
                                                                   scanImageHeight / yOffsetRatio
                                                                   ) 
                                                        );
        
        //If something happened to the image when we were doing all of the above, bail!
        if( !imageRefFinal )
        {
            if( metaData )
                [metaData release];
            
            if( fileRef )
                CFRelease ( fileRef );
            
            if( imageSrcRef )
                CFRelease ( imageSrcRef );
            
            if( imageRefOrig )
                CFRelease ( imageRefOrig );
            
            return NULL;
        }
        
        //Setup bitmap context information
        CGContextRef  bitmapContext = nil;    
        unsigned int  bytesPerRow   = scanImageWidth  * 4;
        unsigned int  bytesPerBand  = bytesPerRow     * scanImageHeight;
        UInt8*        bitmap        = nil;
        
        //Fix this, we should be using the colorspace that we received from the client.
        CGColorSpaceRef   newcolorspace = CGColorSpaceCreateDeviceRGB();
        
        bitmap        = malloc( bytesPerBand ); 
        
        bitmapContext = CGBitmapContextCreate( 
                                              bitmap, 
                                              scanImageWidth, 
                                              scanImageHeight, 
                                              8,  /* bits per component */
                                              bytesPerRow, 
                                              newcolorspace,
                                              kCGImageAlphaPremultipliedFirst
                                              );
        
        CGContextSaveGState(bitmapContext);
        CGRect drawRect = CGRectMake( 0, 0, scanImageWidth, scanImageHeight );
        CGContextClearRect( bitmapContext, drawRect ); 
        CGContextDrawImage( bitmapContext, drawRect, imageRefFinal ); 
        
        
        int offset = 0;
        for(int j=0;j<(scanImageHeight*scanImageWidth*3);j+=3)
        {
            
            bitmap[j]    =  0xFF - bitmap[j+1+offset];
            bitmap[j+1]  =  0xFF - bitmap[j+2+offset];
            bitmap[j+2]  =  0xFF - bitmap[j+3+offset];
            offset++;
        }
        
        CGContextRestoreGState(bitmapContext);
        CGContextRelease( bitmapContext );
        
        if( imageSrcRef )
            CFRelease( imageSrcRef );
        
        if( imageRefOrig )
            CFRelease( imageRefOrig );
        
        if( imageRefFinal)
            CFRelease( imageRefFinal );
        
        if( fileRef )
            CFRelease( fileRef );
        
        if( metaData )
            [metaData release];
        
        if( newcolorspace )
            CGColorSpaceRelease( newcolorspace );
        
        return [[NSData alloc] initWithBytesNoCopy: bitmap length: (scanImageHeight * scanImageWidth * 3) freeWhenDone:YES];
    }
    else 
    {
        return NULL;
    }
}

#pragma mark -
#pragma mark Methods to handle file I/O
// --------------------------------------------------------------------------------------------------- setOutputFilePath
// Set up temp file location for file I/O

- (void)setOutputFilePath
{
    NSString* filePath;
    
    if ( self.documentFolderPath == NULL )
    {
        UInt32 i = 0;
        struct stat status;
        
        do
        {
            if (i == 0)
            {
                filePath = [NSString stringWithFormat: @"%@/%08x_scan.%@", NSTemporaryDirectory() ,_deviceObjectInfo->icaObject, self.documentExtension];
            }
            else
            {
                filePath = [NSString stringWithFormat: @"%@/%08x_scan %d.%@", NSTemporaryDirectory(), _deviceObjectInfo->icaObject, i, self.documentExtension];
            }
            i++;
        } while ( 0 == lstat([filePath fileSystemRepresentation], &status) );
    }
    else
    {
        NSString*   localFolderPath = [self.documentFolderPath stringByExpandingTildeInPath];
        UInt32      i               = 0;
        struct stat status;
        
        do
        {
            if (i == 0)
            {
                filePath = [NSString stringWithFormat: @"%@/%@.%@", localFolderPath, self.documentName, self.documentExtension];
            }
            else
            {
                filePath = [NSString stringWithFormat: @"%@/%@ %d.%@", localFolderPath, self.documentName, i, self.documentExtension];
            }
            i++;
        } while ( 0 == lstat([filePath fileSystemRepresentation], &status) );
    }
    
    // remember download file path
    self.documentFilePath = filePath; 
    
    if ( self.isDocumentUTI_ICA_RAW == NO )
    {
        // The client has requested the scan file to be saved in a format other than ICA RAW format.
        // But, we will first save the scanned image in a ICA RAW file in a temporary location and then use it
        // to create an image file in the location specified by the client in the format specified by the client.
        
        NSString* temporaryDirectoryPath = [NSString stringWithFormat:@"%@/icaRawImageXXXXXX.ica", NSTemporaryDirectory()];
        char template[512] = {0};
        // creating temp raw image file as backing store
        strlcpy(template, [temporaryDirectoryPath UTF8String], 512);
        mkstemps(template, 4);
        strlcpy( _rawImageFileCachePath, template, 512 );
    }
}

//------------------------------------------------------------------------------------------------ openRawFileForWriting

- (BOOL)openRawFileForWriting
{
    if ( _rawImageFile != NULL )
    {
        [self closeRawFile];
        _rawImageFile = NULL;
    }
    
    if ( self.isDocumentUTI_ICA_RAW ) 
    {
        // The client has requested final scan in ICA RAW format. Therefore we do no create an intermediary
        // raw cache file. 
        _rawImageFile = fopen( [self.documentFilePath fileSystemRepresentation], "w" );
    }
    else
    {
        // The client has requested final scan in a format other than ICA RAW format. Therefore we need to create 
        // an intermediary raw cache file. 
        _rawImageFile = fopen( _rawImageFileCachePath, "w" );
    }
    
    return (_rawImageFile != NULL);
}

//--------------------------------------------------------------------------------------- writeRawFileWithBuffer:ofSize:

- (void)writeRawFileWithBuffer:(char*)buffer ofSize:(size_t)size
{
    fwrite( buffer, 1, size, _rawImageFile );
}

//------------------------------------------------------------------------------------------------ openRawFileForReading

- (void)openRawFileForReading
{
    _rawImageFile = fopen( _rawImageFileCachePath, "r" );
    fseek( _rawImageFile, sizeof( ICARawFileHeader ), SEEK_SET);
}

//---------------------------------------------------------------------------------------- readRawFileWithBuffer:ofSize:

- (size_t)readRawFileWithBuffer:(void *)buffer ofSize:(size_t)size
{
    return fread( buffer, 1, size, _rawImageFile );
}

//-------------------------------------------------------------------------------------------------------- rewindRawFile

- (void)rewindRawFile
{
    fseek( _rawImageFile, sizeof(ICARawFileHeader), SEEK_SET);
}

//--------------------------------------------------------------------------------------------------------- closeRawFile

- (void)closeRawFile
{
    fflush( _rawImageFile );
    fclose( _rawImageFile );
    _rawImageFile = NULL;
}

// --------------------------------------------------------------------------------------- saveImageWithWidth:andHeight:

- (void)saveImageWithWidth:(UInt32)scanImageWidth andHeight:(UInt32)scanImageHeight
{
    CGImageDestinationRef cgImgDst  = NULL;
    NSURL*                url       = [NSURL fileURLWithPath:self.documentFilePath];
    
    [self openRawFileForReading];
    
    cgImgDst = CGImageDestinationCreateWithURL( (CFURLRef)url, (CFStringRef)self.documentUTI, 1, nil );
    
    if ( cgImgDst )
    {
        CGImageDestinationAddImage( cgImgDst, _rawCGImageRef, (CFDictionaryRef)(self.scannedImageMetadata) );
        CGImageDestinationFinalize( cgImgDst);
        CFRelease( cgImgDst );
    }
    else
    {
        printf("    ERROR - CGImageDestinationCreateWithURL failed\n");
    }

    [self closeRawFile];
    
    // get rid of raw image file cache
    remove( _rawImageFileCachePath );    
}

#pragma mark -
#pragma mark Data Provider Methods
//------------------------------------------------------------------------------------------------------ getBytes:ofSize:

- (size_t)getBytes:(void *)buffer ofSize:(size_t)size
{
    return [self readRawFileWithBuffer:buffer ofSize:size];
}

//----------------------------------------------------------------------------------------------------------- skipBytes:

- (off_t)skipBytes:(size_t)size
{
    return size;
}

//--------------------------------------------------------------------------------------------------------------- rewind

- (void)rewind
{
    [self rewindRawFile];
}

//------------------------------------------------------------------------------------------------------ releaseProvider

- (void)releaseProvider
{
    printf("Release Provider\n");
}

#pragma mark -
#pragma mark Methods to handle button presses on the scanner
// ----------------------------------------------------------------------------------------------- setLastButtonPressed:
// Set the '_lastButtonPressed' and send a notification about the button press.

- (void)setLastButtonPressed:(OSType)button
{
    ICASendNotificationPB notePB        = {};
    NSMutableDictionary*  notification  = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSNumber*             buttonType    = [NSNumber numberWithUnsignedInt:(unsigned int)button];
    
    _lastButtonPressed = button;
    
    [notification setObject:[NSNumber numberWithUnsignedInt:_deviceObjectInfo->icaObject] forKey:(id)kICANotificationICAObjectKey];
    [notification setObject:(id)kICANotificationTypeScannerButtonPressed forKey:(id)kICANotificationTypeKey];
    [notification setObject:buttonType forKey:(id)kICANotificationScannerButtonTypeKey];

    notePB.notificationDictionary = (CFMutableDictionaryRef)notification;
    (void)ICDSendNotification( &notePB );
    [notification release];
}

// -------------------------------------------------------------------------------------------------- acquireButtonPress

- (void)acquireButtonPress
{
    // If we were interacting with a real device here, we would want to acquire the status from the device
    // and save it locally for use with the polling mechanism.  See the interactive mechanism as well for 
    // another example of delivering the notification.
    
    if ( self.devicePollsForButtonPresses )
    {
        // Add code here to read button-press information from the device and save it to 'lastButtonPressed' property
        
        //self.lastButtonPressed = <button press value read from the device>;
    }
}

// ------------------------------------------------------------------------------------------------------ buttonPressed:
// This method is invoked by asynchronous callback function that receives button press information from the device.

- (void)buttonPressed:(NSNumber*)button
{
    self.lastButtonPressed = [button unsignedIntValue];
}

#pragma mark -
#pragma mark Support for scanning from remote clients
//----------------------------------------------------------------------------- updateObjectInfo:forScannedImageAtIndex:

- (ICAError)updateObjectInfo:(ScannerObjectInfo*)objectInfo forScannedImageAtIndex:(NSUInteger)index
{
    ScannedImage* image = ((index < [_scannedImages count]) ? [_scannedImages objectAtIndex:index] : NULL);

    if ( image )
    {
        ScannerObjectInfo info = [image objectInfo];
        memcpy( objectInfo, &info , sizeof( info ) );
        return noErr;
    }
    else 
    {
        return paramErr;
    }
}

//---------------------------------------------------------- readFileDataWithObjectInfo:intoBuffer:withOffset:andLength:

- (ICAError)readFileDataWithObjectInfo:(const ScannerObjectInfo*)objectInfo 
                            intoBuffer:(char*)buffer 
                            withOffset:(UInt32)offset 
                             andLength:(UInt32*)length
{
    ICAError      err   = paramErr;
    ScannedImage* image = NULL;
    
    for ( ScannedImage* img in _scannedImages )
    {
        if ( img.icaObject == objectInfo->icaObject )
        {
            image = img;
            break;
        }
    }
    
    if ( image )
    {
        FILE*       file;
        struct stat status;

        if ( 0 == lstat( [image.filePath UTF8String], &status) )
        {
            file = fopen( [image.filePath UTF8String], "r" );
            
            if ( file )
            {
                fseek( file, offset, 0 );
                fread( buffer, *length, 1, file );
                fclose( file );
                err = noErr;
            }
        }
    }
    
    return err;
}

//-------------------------------------------------------------------------------------------------------- removeObject:

- (ICAError)removeObject:(const ScannerObjectInfo*)objectInfo 
{
    ICAError      err   = paramErr;
    ScannedImage* image = NULL;
    
    for ( ScannedImage* img in _scannedImages )
    {
        if ( img.icaObject == objectInfo->icaObject )
        {
            image = img;
            break;
        }
    }
    
    if ( image )
    {
        remove ( [image.filePath UTF8String] );
        [_scannedImages removeObject:image];
        err = noErr;
    }
    
    return err;
}

//----------------------------------------------------------------------------------------------------------------------

@end

