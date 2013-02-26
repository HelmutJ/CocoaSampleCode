/*
 
 File:ApertureSDKCommon.h
 
 Abstract: Demonstrate how to create a edit plugin for use in Aperture
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */ 

/*!
 @define			kExportKeyThumbnailImage
 @discussion		An NSImage object containing a reduced-size JPEG of the specified image. Note that values may be nil for this key for master images, or for versions of unsupported master formats. 
 */
#define kExportKeyThumbnailImage @"kExportKeyThumbnailImage"


/*!
 @define			kExportKeyVersionName
 @discussion		An NSString containing the version name of the selected image.
 */
#define kExportKeyVersionName @"kExportKeyVersionName"


/*!
 @define			kExportKeyProjectName
 @discussion		An NSString containing the name of the project containing the image.
 */
#define kExportKeyProjectName @"kExportKeyProjectName"


/*!
 @define			kExportKeyEXIFProperties
 @discussion		An NSDictionary containing the EXIF key-value pairs for the image.
 */
#define kExportKeyEXIFProperties @"kExportKeyEXIFProperties"


/*!
 @define			kExportKeyIPTCProperties
 @discussion		An NSDictionary containing all the IPTC key-value pairs for the image.
 */
#define kExportKeyIPTCProperties @"kExportKeyIPTCProperties"


/*!
 @define			kExportKeyCustomProperties
 @discussion		An NSDictionary containing all the Custom Metadata key-value pairs for the image.
 */
#define kExportKeyCustomProperties @"kExportKeyCustomProperties"


/*!
 @define			kExportKeyKeywords
 @discussion		An NSArray containing an NSString for each keyword for this image.
 */
#define kExportKeyKeywords @"kExportKeyKeywords"

/* New in Aperture 1.5.1, Part of ApertureExportManager version 2 */
/*!
 @define			kExportKeyHierarchicalKeywords
 @discussion		An NSArray containing hierarchical keywords. Each entry in the array represents a single keyword and is itself an NSArray of NSStrings. Each hierarchy array starts with the keyword itself at index 0, followed by its parent, and so on. 
 */
#define kExportKeyHierarchicalKeywords @"kExportKeyHierarchicalKeywords"


/*!
 @define			kExportKeyMainRating
 @discussion		An NSNumber representing the rating for this image.
 */
#define kExportKeyMainRating @"kExportKeyMainRating"


/*!
 @define			kExportKeyXMPString
 @discussion		An NSString containing the XMP data for the original master of this image.
 */
#define kExportKeyXMPString @"kExportKeyXMPString"


/*!
 @define			kExportKeyReferencedMasterPath
 @discussion		An NSString containing the absolute path to the master image file. If the image is not referenced (i.e. the master is inside the Aperture Library bundle), then this value is nil.
 */
#define kExportKeyReferencedMasterPath @"kExportKeyReferencedMasterPath"
#define kExportKeyMasterPath @"kExportKeyReferencedMasterPath"


/*!
 @define			kExportKeyUniqueID
 @discussion		An NSString containing a unique identifier for specified image.
 */
#define kExportKeyUniqueID @"kExportKeyUniqueID"


/*!
 @define			kExportKeyImageSize
 @discussion		An NSValue object containing an NSSize with the pixel dimensions of the specified image. For Version images, the pixel dimensions take all cropping, adjustments, and rotations into account. For Master images, the size is the original pixel dimensions of the image.
 */
#define kExportKeyImageSize @"kExportKeyImageSize"

/*!
 @define			kExportKeyImageHasAdjustments
 @discussion		(New in Aperture 2.0) An NSNumber object containing a bool. A value of YES indicates that the user has applied at least one adjustment to this version besides the RAW decode.
 */
#define kExportKeyImageHasAdjustments @"kExportKeyImageHasAdjustments"


#define kExportKeyWhiteBalanceTemperature @"kExportKeyWhiteBalanceTemperature"
#define kExportKeyWhiteBalanceTint @"kExportKeyWhiteBalanceTint"
#define kExportKeyIsRAWImage @"kExportKeyIsRAWImage"

/* New in Aperture 1.5.1, Part of ApertureExportManager version 2 */
/*!
 */
typedef enum
{
	kExportThumbnailSizeThumbnail = 0,
	kExportThumbnailSizeMini,
	kExportThumbnailSizeTiny
} ApertureExportThumbnailSize;


/*!
 @typedef		ApertureExportProgress
 @abstract		Provides values for UI progress display during export.
 @field			currentValue Current progress
 @field			total Total to do.
 @field			message Progress message.
 @field			indeterminateProgress Set to YES to display an indeterminate progress bar.
 @discussion		Aperture uses the values in this structure to display the export progress in the 
 UI. Aperture starts calling this method after a plug-in calls -shouldBeginExport
 and stops calling this method after the plug-in calls -shouldFinishExport or 
 -shouldCancelExport.
 */
typedef struct
{
	unsigned long	currentValue;
	unsigned long	totalValue;
	NSString		*message;
	BOOL			indeterminateProgress;	
} ApertureExportProgress;

/* New in Aperture 2 - Allows edit plug-ins to specify the format of new editable versions */
typedef enum
{	
	kApertureImageFormatTIFF8 = 2,
	kApertureImageFormatTIFF16 = 3,
	kApertureImageFormatPSD16 = 4,
	kApertureImageFormatPSD8 = 5,
} ApertureImageFormat;
