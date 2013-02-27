/*!
	@header			ApertureExportManager.h
	@copyright		2006 Apple Computer, Inc. All rights reserved.
	@abstract		Version 2 of the protocol declaration for Aperture's export interface. 
	@discussion		An Aperture export plug-in uses these methods to control the export process. Version 2 supported by Aperture 1.5.1 and later. 
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

/* New in version 2 of the ApertureExportManager protocol. */
/*!
	@define			kExportKeyHierarchicalKeywords
	@discussion		New in version 2 of the ApertureExportManager protocol. Supported by Aperture 1.5.1 and later. An NSArray containing hierarchical keywords. Each entry in the array represents a single keyword and is itself an NSArray of NSStrings. Each hierarchy array starts with the keyword itself at index 0, followed by its parent, and so on.
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



/* New in version 2 of the ApertureExportManager protocol. */
/*!
	@typedef		ApertureExportThumbnailSize
	@discussion		New in version 2 of the ApertureExportManager protocol. Supported by Aperture 1.5.1 and later. These constants are used in the -thumbnailForImageAtIndex:size: method to specify the size that Aperture should return. Tiny images are 32px, Mini are 250px, and Thumbnails are 1024px.
*/
typedef enum
{
	kExportThumbnailSizeThumbnail = 0,
	kExportThumbnailSizeMini,
	kExportThumbnailSizeTiny
} ApertureExportThumbnailSize;

/*!
	@protocol		ApertureExportManager
	@discussion		Version 2 of the protocol definition for the Aperture export interface. You use this protocol to communicate with the Aperture application.
 */
@protocol ApertureExportManager


/*!
	@method			imageCount
	@abstract		Returns the number of images the user wants to export.
	@result			An unsigned integer indicating the number of images the user wants to export. 
	@discussion		Note that the image count may change if the user is allowed to choose between Master and Version export (see -allowsMasterExport). If the user switches, the Aperture export manager sends the plug-in a message (see -exportManagerExportTypeDidChange). The plug-in should then call -imageCount to make sure the number of images to export is correct.
*/
- (unsigned)imageCount;


/*!
	@method			propertiesForImageAtIndex:
	@abstract		Returns a dictionary containing all the properties for an image.
	@param			index  The index of the target image.
	@result			A dictionary containing the available properties for the specified image. The returned dictionary contains a thumbnail image whose size is kExportThumbnailSizeMini.
	@discussion		For Master images, the returned properties come from the original import properties. These include properties from the image file and camera as well as any IPTC values the user added on import. The keys contained in the properties dictionary are defined at the beginning of this header file.
 */
- (NSDictionary *)propertiesForImageAtIndex:(unsigned)index;


/* New in version 2 of the ApertureExportManager protocol.  */
/*!
	@method			propertiesWithoutThumbnailForImageAtIndex:
	@abstract		Returns a dictionary containing all the properties for an image, but without a value for the kExportKeyThumbnailImage key. (Version 2)
	@param			index  The index of the target image.
	@result			A dictionary containing all the available properties for the specified image, except a thumbnail. You may obtain a thumbnail separately using the -thumbnailImageForImageAtIndex:size: method.
	@discussion		New in version 2 of the ApertureExportManager protocol. Supported by Aperture 1.5.1 and later. For Master images, the returned properties come from the original import properties. These include properties from the image file and camera as well as any IPTC values the user added on import. The keys contained in the properties dictionary are defined at the beginning of this header file. You may check if the Aperture your plug-in is running in supports version 2 by using the PROAPIAccessing protocol.
*/
- (NSDictionary *)propertiesWithoutThumbnailForImageAtIndex:(unsigned)index;


/* New in version 2 of the ApertureExportManager protocol.  */
/*!
	@method			thumbnailForImageAtIndex:size:
	@abstract		Returns a small version of the specified image. (Version 2)
	@param			index The index of the target image
	@param			size The constant indicating how large of a thumbnail image Aperture should return.
	@result			An image object containing the thumbnail data
	@discussion		New in version 2 of the ApertureExportManager protocol. Supported by Aperture 1.5.1 and later. For master images, this method may return nil. You may check if the Aperture your plug-in is running in supports version 2 by using the PROAPIAccessing protocol.
*/
- (NSImage *)thumbnailForImageAtIndex:(unsigned)index
								 size:(ApertureExportThumbnailSize)size;

/*!
	@method			selectedExportPresetDictionary
	@abstract		Returns the key-value pairs defining the currently-selected export presets for a Version export.
	@result			A pointer to an NSDictionary structure.
	@discussion		Returns the key-value pairs defining the currently-selected export presets for a Version export. Returns nil if the user is exporting a Master image. 
*/
- (NSDictionary *)selectedExportPresetDictionary;


/*!
	@method			addKeywords:toImageAtIndex:
	@abstract		Adds keywords to a Version image.
	@param			keywords An NSArray of NSString objects representing the keywords to add.
	@param			index The index of the target image.
	@discussion		This method has no effect if called on a Master image.
*/
- (void)addKeywords:(NSArray *)keywords 
	 toImageAtIndex:(unsigned)index;



/* New in version 2 of the ApertureExportManager protocol.  */
/*!
	 @method		addHierarchicalKeywords:toImageAtIndex:
	 @abstract		Adds keyword hierarchies to a Version image. (Version 2)
	 @param			hierarchicalKeywords An NSArray of NSArray objects, each containing NSString objects representing the hierarchy of a single keyword. For each NSArray, the NSString at index 0 is the keyword, with the item at index 1 being its parent, and so on.
	 @param			index The index of the target image.
	 @discussion	New in version 2 of the ApertureExportManager protocol. Supported by Aperture 1.5.1 and later. You may check if the Aperture your plug-in is running in supports version 2 by using the PROAPIAccessing protocol. This method has no effect if called on a Master image.
	 */
- (void)addHierarchicalKeywords:(NSArray *)hierarchicalKeywords
				 toImageAtIndex:(unsigned)index;

/*!
	@method			addCustomMetadataKeyValues:toImageAtIndex
	@abstract		Adds custom metadata to a Version image.
	@param			customMetadata	An NSDictionary containing NSString key-value pairs representing the custom metadata.
	@param			index The index of the target image.
	@discussion		This method has no effect if called on a Master image.
*/
- (void)addCustomMetadataKeyValues:(NSDictionary *)customMetadata 
					toImageAtIndex:(unsigned)index;


/*!
	@method			window
	@abstract		Provides reference to frontmost window.
	@result			A reference to the current frontmost window.
	@discussion		Until the plug-in calls -shouldBeginExport, the reference points to the export window. After the export process begins, the reference points to the progress sheet or to Aperture's main window.
*/
- (id)window;


/*!
	@method			isMasterExport
	@abstract		Indicates whether Aperture is exporting Master or Version images.
	@result			Returns YES if Aperture is exporting Master images. Returns NO if Aperture is exporting Version images.
*/
- (BOOL)isMasterExport;


/*!
	@method			shouldBeginExport
	@abstract		Tells Aperture to start the export process.
	@discussion		Calling this method causes Aperture to determine the destination path for export, confirm the images to export, put away the export window, and begin the export process. A plug-in should call this method only in response to -exportManagerShouldBeginExport and after performing any necessary validations, network checks, and so on.
*/
- (void)shouldBeginExport;


/*!
	@method			shouldCancelExport
	@abstract		Tells Aperture to cancel the export process.
	@discussion		The plug-in can call this method at any time to have Aperture put away all export windows, stop the export process, and return the user to the workspace. Additionally, if Aperture calls -exportManagerShouldCancelExport, Aperture then halts all activity and waits for the plug-in to call this method.
*/
- (void)shouldCancelExport;


/*!
	@method			shouldFinishExport
	@abstract		Signals that Aperture can deallocate the plug-in.
	@discussion		When Aperture finishes processing the export image data, it calls -exportManagerDidFinishExport. It continues to ask the plug-in for progress updates until the plug-in calls this method. Once this happens, Aperture closes the export modal window and deallocates the plug-in. 
*/
- (void)shouldFinishExport;


@end