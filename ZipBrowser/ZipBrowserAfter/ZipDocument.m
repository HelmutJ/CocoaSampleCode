 /*
 
 File: ZipDocument.m
 
 Abstract: ZipDocument is the NSDocument subclass representing
 a zip archive and serving as the browser's delegate.
 
 Version: 1.1
 
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
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */ 

#import "ZipDocument.h"
#import "ZipEntry.h"
#import "ZipEntryView.h"
#import "FileBuffer.h"
#import <zlib.h>

#define MIN_DIRECTORY_END_OFFSET    20
#define MAX_DIRECTORY_END_OFFSET    66000
#define FILE_HEADER_LENGTH          30
#define DIRECTORY_ENTRY_LENGTH      46
#define ENTRY_READ_QUEUE_LENGTH     256

#define DIRECTORY_END_TAG           0x06054b50
#define DIRECTORY_ENTRY_TAG         0x02014b50
#define FILE_ENTRY_TAG              0x04034b50

static NSString *ZipDocumentReloadBrowserNotification = @"ZipDocumentReloadBrowserNotification";


/* NSOperation subclass representing background zip directory reading */

@interface ZipDirectoryReadOperation : NSOperation {
    ZipDocument *zipDocument;
}

- (id)initWithZipDocument:(ZipDocument *)document;

@end

@implementation ZipDirectoryReadOperation 

- (id)initWithZipDocument:(ZipDocument *)document {
    self = [super init];
    if (self) zipDocument = document;
    return self;
}

- (void)main {
    // Call on the document to do the actual work
    [zipDocument readEntriesForOperation:self];
}

@end


/* NSOperation subclass representing background zip entry extraction and writing to disk */

@interface ZipEntryWriteOperation : NSOperation {
    ZipDocument *zipDocument;
    ZipEntry *zipEntry;
    NSURL *fileURL;
    NSError *error;
    BOOL succeeded;
}

- (id)initWithZipDocument:(ZipDocument *)document entry:(ZipEntry *)entry fileURL:(NSURL *)url;

@property (readonly) BOOL succeeded;
@property (readonly) NSError *error;

@end

@implementation ZipEntryWriteOperation

- (id)initWithZipDocument:(ZipDocument *)document entry:(ZipEntry *)entry fileURL:(NSURL *)url {
    self = [super init];
    if (self) {
        zipDocument = document;
        zipEntry = entry;
        fileURL = url;
    }
    return self;
}

- (void)main {
    // Call on the document to do the actual work
    succeeded = [zipDocument writeEntry:zipEntry toFileURL:fileURL forOperation:self error:&error];
}

@synthesize succeeded;
@synthesize error;

@end


@implementation ZipDocument

/* Initialization and setup methods */

- (id)init {
    self = [super init];
    if (self) {
        rootEntry = [ZipEntry rootEntry];
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (NSString *)windowNibName {
    return @"ZipDocument";
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
    return (flag ? NSDragOperationNone : (NSDragOperationCopy|NSDragOperationGeneric));
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    
    // Set up state associated with the browser
    [zipDocumentBrowser setDraggingSourceOperationMask:[self draggingSourceOperationMaskForLocal:NO] forLocal:NO];
    [zipDocumentBrowser setDraggingSourceOperationMask:[self draggingSourceOperationMaskForLocal:YES] forLocal:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadBrowser:) name:ZipDocumentReloadBrowserNotification object:self];
    
    // Set up state associated with the preview column
    previewViewController = [[NSViewController alloc] initWithNibName:nil bundle:nil];
    previewEntryView = [[ZipEntryView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
    [previewViewController setView:previewEntryView];
    [previewEntryView setViewController:previewViewController];
    [previewEntryView setZipDocument:self];
    
    // Make sure services are registered
    [[self class] registerServices];
}


/* Document reading methods */

- (void)addEntries:(NSArray *)array {
    // This method is called on the main thread when a background read operation has entries to be added to the entry tree and displayed
    for (ZipEntry *entry in array) [entry addToRootEntry:rootEntry];

    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ZipDocumentReloadBrowserNotification object:self] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnSender forModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
}

- (void)readEntriesForOperation:(NSOperation *)operation {
    // This method is called in the background to read the entries from a zip archive's directory
    NSString *path = nil;
    ZipEntry *entry;
    NSMutableArray *entryArray = [NSMutableArray array];
    unsigned long long length = [fileBuffer fileLength];
    uint32_t i, directoryIndex;
    
    for (i = 0, directoryIndex = directoryEntriesStart; i < numberOfDirectoryEntries; i++) {
        uint16_t compression, namelen, extralen, commentlen;
        uint32_t crcval, csize, usize, headeridx;

        if ([operation isCancelled] || !fileBuffer) break;
        if (directoryIndex < directoryEntriesStart || directoryIndex >= length || directoryIndex + DIRECTORY_ENTRY_LENGTH <= directoryEntriesStart || directoryIndex + DIRECTORY_ENTRY_LENGTH > length || [fileBuffer littleUnsignedIntAtOffset:directoryIndex] != DIRECTORY_ENTRY_TAG) break;

        compression = [fileBuffer littleUnsignedShortAtOffset:directoryIndex + 10];
        crcval = [fileBuffer littleUnsignedIntAtOffset:directoryIndex + 16];
        csize = [fileBuffer littleUnsignedIntAtOffset:directoryIndex + 20];
        usize = [fileBuffer littleUnsignedIntAtOffset:directoryIndex + 24];
        namelen = [fileBuffer littleUnsignedShortAtOffset:directoryIndex + 28];
        extralen = [fileBuffer littleUnsignedShortAtOffset:directoryIndex + 30];
        commentlen = [fileBuffer littleUnsignedShortAtOffset:directoryIndex + 32];
        headeridx = [fileBuffer littleUnsignedIntAtOffset:directoryIndex + 42];

        if (directoryIndex + DIRECTORY_ENTRY_LENGTH + namelen <= directoryEntriesStart || directoryIndex + DIRECTORY_ENTRY_LENGTH + namelen > length) break;

        if (namelen > 0 && headeridx < directoryEntriesStart) {
            // We try to interpret the name using the document's encoding, but if this fails we fall back to the filesystem encoding, Windows Latin 1, and finally Mac Roman (which always succeeds)
            NSData *nameData = [fileBuffer dataAtOffset:directoryIndex + DIRECTORY_ENTRY_LENGTH length:namelen];
            if (nameData && [nameData length] == namelen) {
                path = [[NSString alloc] initWithData:nameData encoding:documentEncoding];
                if (!path) path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:[nameData bytes] length:[nameData length]];
                if (!path) path = [[NSString alloc] initWithData:nameData encoding:NSWindowsCP1252StringEncoding];
                if (!path) path = [[NSString alloc] initWithData:nameData encoding:NSMacOSRomanStringEncoding];
            }
        }

        if (path) {
            entry = [[ZipEntry alloc] initWithPath:path headerOffset:headeridx CRC:crcval compressedSize:csize uncompressedSize:usize compressionType:compression];
    
            // We place the entries on a queue, and when we have enough we send them over to the main thread to be added to the document's entry tree and displayed
            [entryArray addObject:entry];
            if ([entryArray count] >= ENTRY_READ_QUEUE_LENGTH) {
                [self performSelectorOnMainThread:@selector(addEntries:) withObject:[entryArray copy] waitUntilDone:NO];
                [entryArray removeAllObjects];
            }
        }
        directoryIndex += DIRECTORY_ENTRY_LENGTH + namelen + extralen + commentlen;
    }
    if ([entryArray count] > 0) {
        [self performSelectorOnMainThread:@selector(addEntries:) withObject:[entryArray copy] waitUntilDone:NO];
    }
}

static inline uint32_t _crcFromData(NSData *data) {
    uint32_t crc = crc32(0, NULL, 0);
    return crc32(crc, [data bytes], [data length]);
}

- (BOOL)writeEntry:(ZipEntry *)zipEntry toFileURL:(NSURL *)fileURL forOperation:(NSOperation *)operation error:(NSError **)error {
    // This method is called in the background to uncompress an individual zip entry and write it to disk as a result of a drag
    BOOL retval = NO;
    unsigned long long length = [fileBuffer fileLength];
    uint16_t compression = [zipEntry compressionType], namelen, extralen;
    uint32_t crcval = [zipEntry CRC], csize = [zipEntry compressedSize], usize = [zipEntry uncompressedSize], headeridx = [zipEntry headerOffset], dataidx;
    NSData *compressedData = nil, *uncompressedData = nil;
    NSMutableData *mutableData = nil;
    NSError *localError = nil;
    z_stream stream;
    
    if (headeridx < length && headeridx + FILE_HEADER_LENGTH > headeridx && headeridx + FILE_HEADER_LENGTH < length && csize > 0 && usize > 0 && [fileBuffer littleUnsignedIntAtOffset:headeridx] == FILE_ENTRY_TAG && [fileBuffer littleUnsignedShortAtOffset:headeridx + 8] == compression) {
        namelen = [fileBuffer littleUnsignedShortAtOffset:headeridx + 26];
        extralen = [fileBuffer littleUnsignedShortAtOffset:headeridx + 28];
        dataidx = headeridx + FILE_HEADER_LENGTH + namelen + extralen;

        if (dataidx < length && dataidx + csize > dataidx && dataidx + csize > headeridx && dataidx + csize < length) {
            // Currently this is all done in memory, but it could potentially be done block-by-block as a stream
            compressedData = [fileBuffer dataAtOffset:dataidx length:csize];
            if (0 == compression && compressedData && [compressedData length] == csize && usize == csize && _crcFromData(compressedData) == crcval) {
                // If the entry is stored uncompressed, we write it out verbatim
                uncompressedData = compressedData;
            } else if (8 == compression && compressedData && [compressedData length] == csize && usize / 64 < csize) {
                // If the entry is stored deflated, we inflate it and write out the results
                mutableData = [NSMutableData dataWithLength:usize];
                bzero(&stream, sizeof(stream));
                stream.next_in = (Bytef *)[compressedData bytes];
                stream.avail_in = [compressedData length];
                stream.next_out = (Bytef *)[mutableData mutableBytes];
                stream.avail_out = usize;

                if (mutableData && Z_OK == inflateInit2(&stream, -15)) {
                    if (Z_STREAM_END == inflate(&stream, Z_FINISH)) {
                        if (Z_OK == inflateEnd(&stream) && usize == stream.total_out && _crcFromData(mutableData) == crcval) uncompressedData = mutableData;
                    } else {
                        (void)inflateEnd(&stream);
                    }
                }
            }
            if (uncompressedData && [uncompressedData writeToURL:fileURL options:NSAtomicWrite error:&localError]) retval = YES;
        }
    }
    if (!retval && error) *error = localError ? localError : [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fileURL, NSURLErrorKey, nil]];
    return retval;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
    return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName encoding:(NSStringEncoding)encoding error:(NSError **)error {
    // This is the main method for reading a document from disk
    BOOL retval = NO;
    unsigned long long i, length, directoryEntriesEnd = 0;
    uint32_t potentialTag;
    ZipDirectoryReadOperation *operation;
    NSError *localError = nil;

    if (!fileBuffer) fileBuffer = [[FileBuffer alloc] initWithURL:absoluteURL error:&localError];
    if (fileBuffer) {
        documentURL = [absoluteURL copy];
        documentType = [typeName copy];
        documentEncoding = encoding;
        length = [fileBuffer fileLength];

        // First, we locate the zip directory
        for (i = MIN_DIRECTORY_END_OFFSET; directoryEntriesEnd == 0 && i < MAX_DIRECTORY_END_OFFSET && i < length; i++) {
            potentialTag = [fileBuffer littleUnsignedIntAtOffset:length - i];
            if (potentialTag == DIRECTORY_END_TAG) {
                directoryEntriesEnd = length - i;
                numberOfDirectoryEntries = [fileBuffer littleUnsignedShortAtOffset:directoryEntriesEnd + 8];
                directoryEntriesStart = [fileBuffer littleUnsignedIntAtOffset:directoryEntriesEnd + 16];
            }
        }

        // If we have a valid zip directory, report success and queue reading of the actual entries in the background
        if (numberOfDirectoryEntries > 0 && directoryEntriesEnd > 0 && directoryEntriesStart > 0 && directoryEntriesStart < length) {
            operation = [[ZipDirectoryReadOperation alloc] initWithZipDocument:self];
            [operationQueue addOperation:operation];
            retval = YES;
        } else {
            [fileBuffer close];
            fileBuffer = nil;
        }
    }
    if (!retval && error) *error = localError ? localError : [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:absoluteURL, NSURLErrorKey, nil]];
    return retval;
}

- (void)close {
    [operationQueue cancelAllOperations];
    [operationQueue waitUntilAllOperationsAreFinished];
    [fileBuffer close];
    fileBuffer = nil;
    [super close];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    return [self readFromURL:absoluteURL ofType:typeName encoding:NSUTF8StringEncoding error:outError];
}


/* Methods supporting reopening with encoding */

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    return ([item action] == @selector(reopenWithEncoding:) ? YES : [super validateUserInterfaceItem:item]);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    // Supply a check mark on the menu item corresponding to the current document encoding
    if ([menuItem action] == @selector(reopenWithEncoding:)) [menuItem setState:([menuItem tag] == documentEncoding ? 1 : 0)];
    return [self validateUserInterfaceItem:menuItem];
}

- (void)reopenWithEncoding:(id)sender {
    NSError *error = nil;
    ZipEntry *oldRootEntry = rootEntry;
    NSStringEncoding oldDocumentEncoding = documentEncoding;
    
    // First we must make sure that our file operations are all stopped
    [operationQueue cancelAllOperations];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    // Reset the entry tree and try to re-read it from disk
    rootEntry = [ZipEntry rootEntry];
    if (![self readFromURL:documentURL ofType:documentType encoding:[sender tag] error:&error]) {
        // If this fails, present an error and restore the old entry tree
        [self presentError:error modalForWindow:[zipDocumentBrowser window] delegate:nil didPresentSelector:0 contextInfo:NULL];
        rootEntry = oldRootEntry;
        documentEncoding = oldDocumentEncoding;
    }
    [zipDocumentBrowser loadColumnZero];
}


/* Browser support methods */

- (id)rootItemForBrowser:(NSBrowser *)browser {
    return rootEntry;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    return [[(ZipEntry *)item childEntries] count];
}    

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    return [[(ZipEntry *)item childEntries] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
    return [(ZipEntry *)item isLeaf];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    return [(ZipEntry *)item name];
}

- (NSViewController *)browser:(NSBrowser *)browser previewViewControllerForLeafItem:(id)item {
    return previewViewController;
}

- (void)reloadBrowser:(id)sender {
    [zipDocumentBrowser reloadColumn:0];
}


/* Drag support methods that set up drags */

- (ZipEntry *)entryForDraggingRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column browser:(NSBrowser *)browser {
    // This is the common method for locating the entry to be dragged
    ZipEntry *parentEntry = [browser itemAtIndexPath:[browser indexPathForColumn:column]], *childEntry = nil;
    NSArray *childEntries;
    NSUInteger childIndex;
    
    draggedRow = NSNotFound;
    draggedColumn = NSNotFound;
    
    // Currently this code handles only dragging a single leaf entry at a time
    if ([rowIndexes count] == 1) {
        childEntries = [parentEntry childEntries];
        childIndex = [rowIndexes firstIndex];
        if (childIndex < [childEntries count] && [[childEntries objectAtIndex:childIndex] isLeaf]) {
            childEntry = [childEntries objectAtIndex:childIndex];
            draggedRow = childIndex;
            draggedColumn = column;
        }
    }
    return childEntry;
}

- (BOOL)browser:(NSBrowser *)browser canDragRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event {
    // If a suitable entry is found, then dragging is allowed
    return [self entryForDraggingRowsWithIndexes:rowIndexes inColumn:column browser:browser] ? YES : NO;
}

- (NSImage *)browser:(NSBrowser *)browser draggingImageForRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
    // The image used for dragging is an icon from NSWorkspace
    NSImage *image = nil;
    ZipEntry *childEntry = [self entryForDraggingRowsWithIndexes:rowIndexes inColumn:column browser:browser];
    if (childEntry) {
        image = [[NSWorkspace sharedWorkspace] iconForFileType:[[childEntry name] pathExtension]];
        if (!image) image = [browser draggingImageForRowsWithIndexes:rowIndexes inColumn:column withEvent:event offset:dragImageOffset];
    }
    return image;
}

// The two methods that follow represent two ways by which the document may be asked to set up a drag pasteboard

- (BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard {
    // This method will be called for drags originating from the browser
    BOOL retval = NO;
    ZipEntry *childEntry = [self entryForDraggingRowsWithIndexes:rowIndexes inColumn:column browser:browser];
    if (childEntry) {
        // Note that all actual filesystem operations are done lazily later
        [pasteboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType, nil] owner:self];
        if ([pasteboard setPropertyList:[NSArray arrayWithObject:[[childEntry name] pathExtension]] forType:NSFilesPromisePboardType]) retval = YES;
        if ([pasteboard setString:[childEntry name] forType:NSStringPboardType]) retval = YES;
    }
    return retval;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pasteboard {
    // This method will be called for services, or for drags originating from the preview column ZipEntryView, and it calls the previous method
    NSInteger selectedColumn = [zipDocumentBrowser selectedColumn];
    return ((selectedColumn >= 0 && [self browser:zipDocumentBrowser writeRowsWithIndexes:[zipDocumentBrowser selectedRowIndexesInColumn:selectedColumn] inColumn:selectedColumn toPasteboard:pasteboard]) ? YES : NO);
}


/* Drag support methods that lazily provide the actual files */

- (NSURL *)writeDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column browser:(NSBrowser *)browser toDestination:(NSURL *)dropDestination {
    // This is the common method that queues the writing of the dragged entry to the disk
    NSURL *fileURL = nil;
    ZipEntry *childEntry = [self entryForDraggingRowsWithIndexes:rowIndexes inColumn:column browser:browser];
    ZipEntryWriteOperation *operation;
    NSError *error = nil;
    
    if (childEntry) {
        // Create an operation and wait for it to finish
        fileURL = [NSURL fileURLWithPath:[[dropDestination path] stringByAppendingPathComponent:[childEntry name]] isDirectory:NO];
        operation = [[ZipEntryWriteOperation alloc] initWithZipDocument:self entry:childEntry fileURL:fileURL];
        [operationQueue addOperation:operation];
        [operationQueue waitUntilAllOperationsAreFinished];

        if (![operation succeeded]) {
            // If it fails, present an appropriate error
            fileURL = nil;
            error = [operation error];
            if (error) [self presentError:error];
        }
    }
    return fileURL;
}

// The three methods that follow represent three ways by which the document may be asked for drag data

- (void)pasteboard:(NSPasteboard *)pasteboard provideDataForType:(NSString *)type {
    // This method will be called to provide data for NSFilenamesPboardType
    if ([type isEqualToString:NSFilenamesPboardType] && draggedRow != NSNotFound && draggedColumn != NSNotFound) {
        NSURL *fileURL = [self writeDraggedRowsWithIndexes:[NSIndexSet indexSetWithIndex:draggedRow] inColumn:draggedColumn browser:zipDocumentBrowser toDestination:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
        if (fileURL) [pasteboard setPropertyList:[NSArray arrayWithObject:[fileURL path]] forType:NSFilenamesPboardType];
    }
}

- (NSArray *)browser:(NSBrowser *)browser namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column {
    // This method will be called to provide data for NSFilesPromisePboardType, for drags originating from the browser
    NSURL *fileURL = [self writeDraggedRowsWithIndexes:rowIndexes inColumn:column browser:browser toDestination:dropDestination];
    return (fileURL ? [NSArray arrayWithObject:[[fileURL path] lastPathComponent]] : nil);
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    // This method will be called to provide data for NSFilesPromisePboardType, for drags originating from the preview column ZipEntryView, and it calls the previous method
    return ((draggedRow != NSNotFound && draggedColumn != NSNotFound) ? [self browser:zipDocumentBrowser namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedRowsWithIndexes:[NSIndexSet indexSetWithIndex:draggedRow] inColumn:draggedColumn] : nil);
}


/* Services support methods */

+ (void)registerServices {
    static BOOL registeredServices = NO;
    if (!registeredServices) {
        [NSApp setServicesProvider:self];
        registeredServices = YES;
    }
}

+ (void)exportData:(NSPasteboard *)pasteboard userData:(NSString *)data error:(NSString **)error {
    ZipDocument *document = [[[NSApp makeWindowsPerform:@selector(windowController) inOrder:YES] windowController] document];
    if (document) [document writeSelectionToPasteboard:pasteboard];
}

@end
