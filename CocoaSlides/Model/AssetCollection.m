/*

File: AssetCollection.m

Abstract: Asset Collection Model Class for CocoaSlides

Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/

#import "AssetCollection.h"
#import "Asset.h"
#import "ImageAsset.h"

@interface AssetCollection (Internals)
- (Asset *)assetForFilename:(NSString *)filename;
- (NSArray *)findAssetFilesInRootURL;
@end

@implementation AssetCollection

- initWithRootURL:(NSURL *)newRootURL {
    self = [super init];
    if (self) {
        rootURL = [newRootURL retain];
        assets = [[NSMutableArray alloc] init];
        previewImagePixelsPerSide = 80;
    }
    return self;
}

- (void)dealloc {
    [rootURL release];
    [assets release];
    [super dealloc];
}

- (NSURL *)rootURL {
    return rootURL;
}

- (NSArray *)assets {
    return [[assets retain] autorelease];
}

- (void)setAssets:(NSArray *)newAssets {
    if (assets != newAssets) {
        id old = assets;
        assets = [newAssets mutableCopy];
        [old release];
    }
}

- (void)insertObject:(id)obj inAssetsAtIndex:(NSUInteger)index {
    [assets insertObject:obj atIndex:index];
}

- (void)removeObjectFromAssetsAtIndex:(NSUInteger)index {
    [assets removeObjectAtIndex:index];
}

- (NSInteger)previewImagePixelsPerSide {
    return previewImagePixelsPerSide;
}

#pragma mark *** Background Update Control ***

- (void)refreshInBackgroundThread:(id)unusedObject {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Get a list of all the possible image files in root directory.
    NSArray *assetFiles = [self findAssetFilesInRootURL];

    // Identify three groups of image files:
    // (1) files that are in the catalog, but have since changed (the file's modification date is later than its last-cached date)
    // (2) files that exist on disk but are not yet in the catalog (presumably the file was added and we should create a catalog entry for it)
    // (3) files that exist in the catalog but not on disk (presumably the file was deleted and we should remove the corresponding catalog entry)
    NSMutableArray *assetsToProcess = [[self assets] mutableCopy];
    Asset *asset;
    NSMutableArray *assetsChanged = [NSMutableArray array];
    NSMutableArray *filesAdded = [NSMutableArray array];
    NSMutableArray *assetsRemoved = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *rootPath = [[self rootURL] path];
    NSEnumerator *fileEnumerator = [assetFiles objectEnumerator];
    NSString *filename;
    while (filename = [fileEnumerator nextObject]) {

        // Get full path to file.
        NSString *path = [rootPath stringByAppendingPathComponent:filename];

        // Look for a corresponding entry in the catalog.
        asset = [self assetForFilename:filename];
        if (asset != nil) {
            // Check whether file has changed.
            NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:path traverseLink:YES];
            if (fileAttributes != nil) {
                // Get file's modification date.
                NSDate *fileModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
                if ([fileModificationDate compare:[asset dateLastUpdated]] == NSOrderedDescending) {
                    [assetsChanged addObject:asset];
                }
            } else {
                // NOTE: This shouldn't ever really happen, unless the file was deleted between our initial scan and getting to the file attribute check, but just in case, allow for the file to have been removed in that interval.
                [assetsRemoved addObject:asset];
            }

            // We've dealt with this catalogImage instance.
            [assetsToProcess removeObject:asset];
        } else {
            // File was added.
            [filesAdded addObject:filename];
        }
    }

    // Check for images in the catalog for which no corresponding file was found.
    [assetsRemoved addObjectsFromArray:assetsToProcess];
    [assetsToProcess release];
    assetsToProcess = nil;

    // Remove assets to be removed.
    NSEnumerator *assetEnumerator = [assetsRemoved objectEnumerator];
    while (asset = [assetEnumerator nextObject]) {
        [self performSelectorOnMainThread:@selector(removeAsset:) withObject:asset waitUntilDone:YES];
    }

    // Add assets to be added.
    fileEnumerator = [filesAdded objectEnumerator];
    while (filename = [fileEnumerator nextObject]) {
        NSURL *assetURL = [NSURL URLWithString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:[self rootURL]];
        NSString *extension = [filename pathExtension];
        Asset *asset = nil;
        if ([[ImageAsset fileTypes] containsObject:extension]) {
            asset = [[ImageAsset alloc] initWithURL:assetURL];
        }
        if (asset != nil) {
            [self performSelectorOnMainThread:@selector(addAsset:) withObject:asset waitUntilDone:YES];
            [asset release];
            asset = nil;
        }
    }

    [pool release];
    inRefresh = NO;
}

- (void)startRefresh {
    if (!inRefresh) {
        inRefresh = YES;
        [NSThread detachNewThreadSelector:@selector(refreshInBackgroundThread:) toTarget:self withObject:nil];
    }
}

#pragma mark *** Main Thread Callback Points ***

- (void)addAsset:(Asset *)asset {
    [self insertObject:asset inAssetsAtIndex:[assets count]];
}

- (void)removeAsset:(Asset *)asset {
    NSUInteger index = [assets indexOfObject:asset];
    if (index != NSNotFound) {
        [self removeObjectFromAssetsAtIndex:index];
    }
}

@end

@implementation AssetCollection (Internals)

- (Asset *)assetForFilename:(NSString *)filename {
    // (Use of a dictionary or other more search-efficient construct would speed this up.)
    for (Asset *asset in [self assets]) {
        if ([filename isEqualToString:[asset filename]]) {
            return asset;
        }
    }
    return nil;
}

- (NSArray *)findAssetFilesInRootURL {
    NSString *rootPath = [[self rootURL] path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *possibleAssetFiles = [fileManager directoryContentsAtPath:rootPath];
    NSArray *supportedAssetFileTypes = [ImageAsset fileTypes];
    NSMutableArray *assetFiles = [NSMutableArray array];

    for (NSString *filename in possibleAssetFiles) {
        // (In a real-world application, if we have a filename with no extension, we should be prepared to check the file's HFS type code or other identifying metadata here.)
        if ([supportedAssetFileTypes containsObject:[filename pathExtension]]) {
            [assetFiles addObject:filename];
        }
    }
    return assetFiles;
}

@end

