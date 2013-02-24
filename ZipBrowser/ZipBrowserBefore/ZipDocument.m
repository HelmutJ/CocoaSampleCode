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

#define MIN_DIRECTORY_END_OFFSET    20
#define MAX_DIRECTORY_END_OFFSET    66000
#define DIRECTORY_END_TAG           0x06054b50

@implementation ZipDocument

/* Initialization and setup methods */

- (id)init {
    self = [super init];
    if (self) {
        rootEntry = [ZipEntry rootEntry];
    }
    return self;
}

- (NSString *)windowNibName {
    return @"ZipDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    
    // Set up state associated with the preview column
    previewViewController = [[NSViewController alloc] initWithNibName:nil bundle:nil];
    previewEntryView = [[ZipEntryView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
    [previewViewController setView:previewEntryView];
    [previewEntryView setViewController:previewViewController];
}


/* Document reading methods */

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)error {
    BOOL retval = NO;
    NSData *data = [NSData dataWithContentsOfURL:absoluteURL options:0 error:error];
    const uint8_t *bytes = [data bytes];
    unsigned i, length = [data length], directoryEntriesEnd = 0;
    unsigned numberOfDirectoryEntries = 0;
    unsigned potentialTag, directoryEntriesStart = 0, directoryIndex;
    NSString *path;
    ZipEntry *entry;
    
    if (data) {
        for (i = MIN_DIRECTORY_END_OFFSET; directoryEntriesEnd == 0 && i < MAX_DIRECTORY_END_OFFSET && i < length; i++) {
            potentialTag = NSSwapLittleIntToHost(*(uint32_t *)(bytes + length - i));
            if (potentialTag == DIRECTORY_END_TAG) {
                directoryEntriesEnd = length - i;
                numberOfDirectoryEntries = NSSwapLittleShortToHost(*(uint16_t *)(bytes + directoryEntriesEnd + 8));
                directoryEntriesStart = NSSwapLittleIntToHost(*(uint32_t *)(bytes + directoryEntriesEnd + 16));
            }
        }
        for (i = 0, directoryIndex = directoryEntriesStart; i < numberOfDirectoryEntries; i++) {
            unsigned compression, namelen, extralen, commentlen;
            unsigned crcval, csize, usize, headeridx;

            compression = NSSwapLittleShortToHost(*(uint16_t *)(bytes + directoryIndex + 10));
            crcval = NSSwapLittleIntToHost(*(uint32_t *)(bytes + directoryIndex + 16));
            csize = NSSwapLittleIntToHost(*(uint32_t *)(bytes + directoryIndex + 20));
            usize = NSSwapLittleIntToHost(*(uint32_t *)(bytes + directoryIndex + 24));
            namelen = NSSwapLittleShortToHost(*(uint16_t *)(bytes + directoryIndex + 28));
            extralen = NSSwapLittleShortToHost(*(uint16_t *)(bytes + directoryIndex + 30));
            commentlen = NSSwapLittleShortToHost(*(uint16_t *)(bytes + directoryIndex + 32));
            headeridx = NSSwapLittleIntToHost(*(uint32_t *)(bytes + directoryIndex + 42));
            path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char *)(bytes + directoryIndex + 46) length:namelen];

            if (path) {
                entry = [[ZipEntry alloc] initWithPath:path headerOffset:headeridx CRC:crcval compressedSize:csize uncompressedSize:usize compressionType:compression];
                [entry addToRootEntry:rootEntry];
                retval = YES;
            } else {
                break;
            }
            directoryIndex += 46 + namelen + extralen + commentlen;
        }
        if (!retval && error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:absoluteURL, NSURLErrorKey, nil]];
    }
    return retval;
}


/* Browser support methods */

- (id)rootItemForBrowser:(NSBrowser *)browser {
    return rootEntry;
}

- (int)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    return [[(ZipEntry *)item childEntries] count];
}    

- (id)browser:(NSBrowser *)browser child:(int)index ofItem:(id)item {
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

@end
