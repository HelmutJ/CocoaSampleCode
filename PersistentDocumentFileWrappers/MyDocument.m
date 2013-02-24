
/*
    File: MyDocument.m
Abstract: A subclass of NSPersistentDocument that illustrates how to use a directory wrapper to allow the document to be saved as a package.
 
 In addition to the usual Core Data store, the document manages a file that contains the data for a picture.
 The user interface is configured using Cocoa bindings.  An array controller manages the display of a collection of Item objects, and the data for the NSImageView is managed using a binding to the document's 'picture' property.

 
 Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

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

Copyright (C) 2009 Apple Inc. All Rights Reserved.

 */


#import "MyDocument.h"
#import "FileWrapperSupport.h"

/*
 This is the name of the Core Data store file contained within the document package.
 You can change this whatever you want -- the user will not see this file.
 */
static NSString *StoreFileName = @"CoreDataStore.sql";

/*
 This is the key for the image file wrapper contained within the document package.
 */
static NSString *ImageFileNameKey = @"MyImage";


@implementation MyDocument


- (NSString *)windowNibName {
    return @"MyDocument";
}


#pragma mark -
#pragma mark URL management

/*
 Sets the on-disk location.  NSPersistentDocument's implementation is bypassed using the FileWrapperSupport category.  The persistent store coordinator is directed to use an internal URL rather than NSPersistentDocument's default (the main file URL).
*/
- (void)setFileURL:(NSURL *)fileURL {
	
    NSURL *originalFileURL = [self storeURLFromPath:[[self fileURL] path]];
    if (originalFileURL != nil) {
        NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
        id store = [psc persistentStoreForURL:originalFileURL];
        if (store != nil) {
            // Switch the coordinator to an internal URL.
            [psc setURL:[self storeURLFromPath:[fileURL path]] forPersistentStore:store];
        }
    }
    [self simpleSetFileURL:fileURL];
}


/*
 Returns the URL for the wrapped Core Data store file. This appends the StoreFileName to the document's path.
*/
- (NSURL *)storeURLFromPath:(NSString *)filePath {
    filePath = [filePath stringByAppendingPathComponent:StoreFileName];
    if (filePath != nil) {
        return [NSURL fileURLWithPath:filePath];
    }
    return nil;
}


#pragma mark -
#pragma mark Reading (Opening)

/*
 This is a utility method called by readFromURL:ofType:error: (when the document is opened).
 All non-Core Data content is read from disk here. 
*/
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper atPath:(NSString *)path error:(NSError **)error {

	/*
	 In general, you should perform error checking throughout and if there is a problem return in &error a new NSError object that describes the issue.
	 */
    
	// Create a file wrapper for each object saved to a separate file.
    NSFileWrapper *imageFile = [[fileWrapper fileWrappers] objectForKey:ImageFileNameKey];
	
    if (imageFile) {
		// Restore the picture from the file wrapper's data.
		// Disable undo registration so that this is not registered with the undo manager -- see the implementation of setPicture:.
		[[self undoManager] disableUndoRegistration];
		[self setPicture:[imageFile regularFileContents]];
		[[self undoManager] enableUndoRegistration];
    }	
	
    return YES;
}


/*
 Overridden NSDocument/NSPersistentDocument method to open existing documents.
*/
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)error {
	
    BOOL success = NO;
    // Create a file wrapper for the document package.
    NSFileWrapper *directoryFileWrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];    
    // File wrapper for the Core Data store within the document package.
    NSFileWrapper *dataStore = [[directoryFileWrapper fileWrappers] objectForKey:StoreFileName];
	
    if (dataStore != nil) {
        NSString *path = [[absoluteURL path] stringByAppendingPathComponent:[dataStore filename]];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        // Set the document persistent store coordinator to use the internal Core Data store.
        success = [self configurePersistentStoreCoordinatorForURL:storeURL ofType:typeName 
                modelConfiguration:nil storeOptions:nil error:error];
    }
	
    // Don't read anything else if reading the main store failed.
    if (success == YES) {
        // Read the other contents of the document.
        success = [self readFromFileWrapper:directoryFileWrapper atPath:[absoluteURL path] error:error];
    }
    [directoryFileWrapper release];
	
    return success;
}


#pragma mark -
#pragma mark Writing (Saving)

/*
 This is a utility method called from writeSafelyToURL:ofType:forSaveOperation:error: (when the document is saved).  This is where you prepare the non-Core Data content to be written to disk.  You create a new file wrapper for each piece of data that is to be saved to its own file (this sample has only the picture object).
*/
- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper atPath:(NSString *)path error:(NSError **)error {
	
	/*
	 In general, you should perform error checking throughout and if there is a problem return in &error a new NSError object that describes the issue.
	*/
	
    // First, remove any previous existing wrappers for the custom content.
    NSFileWrapper *imageFileWrapper = [[documentFileWrapper fileWrappers] objectForKey:ImageFileNameKey];
    if (imageFileWrapper != nil) {
        [documentFileWrapper removeFileWrapper:imageFileWrapper];
    }
	
    // Create a new wrapper for each piece of data, set its name, and add it to the document file wrapper.
    imageFileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:picture] autorelease];
    [imageFileWrapper setPreferredFilename:@"MyImage"];
    [documentFileWrapper addFileWrapper:imageFileWrapper];
	
    return YES;
}

/*
 Overridden NSDocument/NSPersistentDocument method to save documents.
*/
- (BOOL)writeSafelyToURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName forSaveOperation:(NSSaveOperationType)inSaveOperation error:(NSError **)outError {
	
    BOOL success = YES;
    NSFileWrapper *filewrapper = nil;
    NSURL *originalURL = [self fileURL];
    NSString *filePath = [inAbsoluteURL path];
	
    // Depending on the type of save operation:
    if (inSaveOperation == NSSaveAsOperation) {
		
        // Nothing exists at the URL: set up the directory and migrate the Core Data store.
        filewrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        // Need to write once so there's somewhere for the store file to go.
        [filewrapper writeToFile:filePath atomically:NO updateFilenames:NO];
        
        // Now, the Core Data store...
        NSURL *storeURL = [self storeURLFromPath:filePath];
        NSURL *originalStoreURL = [self storeURLFromPath:[originalURL path]];
		
        if (originalStoreURL != nil) {
            // This is a "Save As", so migrate the store to the new URL.
            NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
            id originalStore = [coordinator persistentStoreForURL:originalStoreURL];
            success = ([coordinator migratePersistentStore:originalStore toURL:storeURL options:nil withType:[self persistentStoreTypeForFileType:inTypeName] error:outError] != nil);
        }
		else {
            // This is the first Save of a new document, so configure the store.
            success = [self configurePersistentStoreCoordinatorForURL:storeURL ofType:inTypeName modelConfiguration:nil storeOptions:nil error:nil];
        }	
        
        [filewrapper addFileWithPath:[storeURL path]];
	
    }
	else { // This is not a Save-As operation.
        // Just create a file wrapper pointing to the existing URL.
        filewrapper = [[NSFileWrapper alloc] initWithPath:[inAbsoluteURL path]];
    }
    
    /*
     * Important *
     Atomicity during write is a problem that is not addressed in this sample.
     See the ReadMe for discussion.
    */
    
    if (success == YES) {
        // Update the file wrapper: this writes the non-Core Data portions of the document.
        success = [self updateFileWrapper:filewrapper atPath:[inAbsoluteURL path] error:outError];
        [filewrapper writeToFile:filePath atomically:NO updateFilenames:NO];
    }
    
    if (success == YES) {
        // Save the Core Data portion of the document.
        success = [[self managedObjectContext] save:outError];
    }
    
    if (success == YES) {
        // Set the appropriate file attributes (such as "Hide File Extension")
        NSDictionary *fileAttributes = [self fileAttributesToWriteToURL:inAbsoluteURL ofType:inTypeName forSaveOperation:inSaveOperation originalContentsURL:originalURL error:outError];
        [[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:[inAbsoluteURL path]];
    }
    [filewrapper release];
	
    return success;
}


#pragma mark -
#pragma mark Revert

/*
 The revert method needs to completely tear down the object graph assembled by the document. In this case, you also want to remove the persistent store manually, because NSPersistentDocument will expect the store for its coordinator to be located at the document URL (instead of inside that URL as part of the file wrapper).
 */
- (BOOL)revertToContentsOfURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName error:(NSError **)outError {
    [self setPicture:nil];
    NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
    id store = [psc persistentStoreForURL:[self storeURLFromPath:[inAbsoluteURL path]]];
    if (store) {
        [psc removePersistentStore:store error:outError];
    }
    return [super revertToContentsOfURL:inAbsoluteURL ofType:inTypeName error:outError];
}


#pragma mark -
#pragma mark Picture accessors

- (NSData *)picture {
    return picture;
}

/*
 Because the image is stored without using Core Data, undo must be managed directly.
 You can use the undo manager from the document's managed object context, but you have to register the old values and the appropriate selector for restoring them.
 */
- (void)setPicture:(NSData *)newPictureData {
    
	if (picture != newPictureData) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setPicture:) object:picture];
		[picture release];
		picture = [newPictureData retain];
	}
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
	[picture release];
	[super dealloc];
}


@end
