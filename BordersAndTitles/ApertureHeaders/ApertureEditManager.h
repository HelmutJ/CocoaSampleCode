/*
 
 File:ApertureEditManager.h
 
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


#import "ApertureSDKCommon.h"

@protocol ApertureEditManager

/* Returns an array of unique ids of the versions the user chose to edit, in the order they were selected. */
- (NSArray *)selectedVersionIds;
/* Returns an array of unique ids that the plug-in is allowed to edit. This may include some images the user selected. */
- (NSArray *)editableVersionIds;
/* Returns an array of unique ids of images the plug-in has imported during this session. */
- (NSArray *)importedVersionIds;

/* A dictionary containing all the available properties for the specified image, except a thumbnail. You may obtain a thumbnail
   separately using the method below. */
- (NSDictionary *)propertiesWithoutThumbnailForVersion:(NSString *)versionUniqueID;
/* Returns an NSImage containing the thumbnail for this image. Some plug-ins may choose to operate on the large thumbnail and not request and editable version
   of the image until the user is done */
- (NSImage *)thumbnailForVersion:(NSString *)versionUniqueID size:(ApertureExportThumbnailSize)size;

/* Returns the path to the file that the plug-in should read/write for this version. If this version is not editable, this method will return nil.*/
- (NSString *)pathOfEditableFileForVersion:(NSString *)versionUniqueID;

/* Returns an array of unique IDs. If an image was already editable and the user did not want to guarantee a copy (by holding the option key when
   selecting the plug-in from the menu) then this method will return the unique ID passed in for that version. Otherwise, this method will tell
   Aperture to write out an editable image in the format specified in the user's preferences (PSD or TIFF) and will create
   a new entry in the user's library. Normally, the plug-in would then call the -pathOfEditableFileForVersion: for the unique IDs returned from
   this method, or the -propertiesWithoutThumbnailForVersion: and -thumbnailForVersion: methods. */
- (NSArray *)editableVersionsOfVersions:(NSArray *)versionUniqueIDs stackWithOriginal:(BOOL)stackWithOriginal;
- (NSArray *)editableVersionsOfVersions:(NSArray *)versionUniqueIDs requestedFormat:(ApertureImageFormat)format stackWithOriginal:(BOOL)stackWithOriginal;


/* Returns YES if Aperture will allow the plug-in to import images into the current album. Aperture will not allow import into smart albums, for example. */
- (BOOL)canImport;

/* Asynchronously import an image into the current album and calls the -editManager:didImportImageAtPath:versionUniqueID: method upon completion.
   If -canImport returns NO, this method will do nothing and the plug-in will not get a callback */
- (void)importImageAtPath:(NSString *)imagePath referenced:(BOOL)isReferenced stackWithVersions:(NSArray *)versionUniqueIdsToStack;

/* Deletes the specified versions and their master files from the user's library. Aperture will only perform this operation for versions created by the plug-in
   during the current session. Unique IDs
   for any images that were not created by the plug-in will be ignored. This includes images that were already editable that the plug-in has modified.
   Note that this will delete all master files attached to these versions. */
- (void)deleteVersions:(NSArray *)versionUniqueIDs;

/* Will add the specified key-value pairs to the Custom Metadata for this image (The "Other" tab in the metadata inspector). If an image already has
   a value for the specified key, it will be updated to the new value */
- (void)addCustomMetadata:(NSDictionary *)customMetadata toVersions:(NSArray *)versionUniqueIDs;
/* Pass in an array of arrays. Each array specifies a keyword hierarchy.*/
- (void)addHierarchicalKeywords:(NSArray *)hierarchicalKeywords toVersions:(NSArray *)versionUniqueIDs;

/* Returns Aperture's main window - in case the plug-in needs to present a sheet, etc. */
- (NSWindow *)apertureWindow;

/* Tells Aperture that the plug-in has completed its work. The plug-in should be ready to dealloc at the time of this call and should not be running tasks
   on any other threads or running anything on the run loop that may call back after this call has finished. */
- (void)endEditSession;

/* Similar to the method above, but automatically deletes any versions that were created by the plug-in during this session. Note that this will NOT delete
   and versions that were edited by the plug-in, but not created during this session. */
- (void)cancelEditSession;


- (void)setUserDefaultsValue:(id)value forKey:(NSString *)key;
- (id)userDefaultsObjectForKey:(NSString *)key;

@end