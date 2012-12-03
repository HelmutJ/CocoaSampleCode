/*
     File: AppController.m
 Abstract: Application Controller object, and the NSBrowser delegate. An instance of this object is in the MainMenu.xib. 
  Version: 1.2
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "AppController.h"
#import "FileSystemNode.h"
#import "FileSystemBrowserCell.h"

@implementation AppController

- (void)dealloc {
    [_rootNode release];
    [_sharedPreviewController release];
    [super dealloc];
}

- (void)awakeFromNib {
    [_browser setTarget:self];
    [_browser setCellClass:[FileSystemBrowserCell class]];
    // Drag and drop support
    [_browser registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_browser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [_browser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    // Double click support
    [_browser setTarget:self];
    [_browser setDoubleAction:@selector(_browserDoubleClick:)];
}

- (id)rootItemForBrowser:(NSBrowser *)browser {
    if (_rootNode == nil) {
        _rootNode = [[FileSystemNode alloc] initWithURL:[NSURL fileURLWithPath:@"/"]];
    }
    return _rootNode;    
}

// Required delegate methods
- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return node.children.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return !node.isDirectory;
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return node.displayName;
}

- (void)browser:(NSBrowser *)browser willDisplayCell:(FileSystemBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column {
    // Find the item and set the image.
    NSIndexPath *indexPath = [browser indexPathForColumn:column];
    indexPath = [indexPath indexPathByAddingIndex:row];
    FileSystemNode *node = [browser itemAtIndexPath:indexPath];
    cell.image = node.icon;
    cell.labelColor = node.labelColor;
}

- (NSViewController *)browser:(NSBrowser *)browser previewViewControllerForLeafItem:(id)item {
    if (_sharedPreviewController == nil) {
        _sharedPreviewController = [[NSViewController alloc] initWithNibName:@"PreviewView" bundle:[NSBundle bundleForClass:[self class]]];
    }
    return _sharedPreviewController; // NSBrowser will set the representedObject for us
}

- (NSViewController *)browser:(NSBrowser *)browser headerViewControllerForItem:(id)item {
    // Add a header for the first column, just as an example
    if (_rootNode == item) {
        return [[[NSViewController alloc] initWithNibName:@"HeaderView" bundle:[NSBundle bundleForClass:[self class]]] autorelease];
    } else {
        return nil;
    }
}

- (CGFloat)browser:(NSBrowser *)browser shouldSizeColumn:(NSInteger)columnIndex forUserResize:(BOOL)forUserResize toWidth:(CGFloat)suggestedWidth  {
    if (!forUserResize) {
        id item = [browser parentForItemsInColumn:columnIndex]; 
        if ([self browser:browser isLeafItem:item]) {
            suggestedWidth = 200; 
        }
    }
    return suggestedWidth;
}

#pragma mark ** Dragging Source Methods **

- (BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard {
    NSInteger i;
    NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    NSIndexPath *baseIndexPath = [browser indexPathForColumn:column]; 
    for (i = [rowIndexes firstIndex]; i <= [rowIndexes lastIndex]; i = [rowIndexes indexGreaterThanIndex:i]) {
        FileSystemNode *fileSystemNode = [browser itemAtIndexPath:[baseIndexPath indexPathByAddingIndex:i]]; 
        [filenames addObject:[fileSystemNode.URL path]];
    }
    [pasteboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
    [pasteboard setPropertyList:filenames forType:NSFilenamesPboardType];
    _draggedColumnIndex = column;
    return YES;
}

- (BOOL)browser:(NSBrowser *)browser canDragRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event {
    // We will allow dragging any cell -- even disabled ones. By default, NSBrowser will not let you drag a disabled cell
    return YES;
}


- (NSImage *)browser:(NSBrowser *)browser draggingImageForRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
    NSImage *result = [browser draggingImageForRowsWithIndexes:rowIndexes inColumn:column withEvent:event offset:dragImageOffset];
    // Create a custom drag image "badge" that displays the number of items being dragged
    if ([rowIndexes count] > 1) {
        NSString *str = [NSString stringWithFormat:@"%ld items being dragged", (long)[rowIndexes count]];
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0.5, 0.5)];
        [shadow setShadowBlurRadius:5.0];
        [shadow setShadowColor:[NSColor blackColor]];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               shadow, NSShadowAttributeName, 
                               [NSColor whiteColor], NSForegroundColorAttributeName,            
                               nil];
        
        [shadow release];
        NSAttributedString *countString = [[NSAttributedString alloc] initWithString:str attributes:attrs];
        NSSize stringSize = [countString size];
        NSSize imageSize = [result size];
        imageSize.height += stringSize.height;
        imageSize.width = MAX(stringSize.width + 3, imageSize.width);
        
        NSImage *newResult = [[[NSImage alloc] initWithSize:imageSize] autorelease];
        
        [newResult lockFocus];
    
        [result drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [countString drawAtPoint:NSMakePoint(0, imageSize.height - stringSize.height)];
        [newResult unlockFocus];
        
        [countString release];
        
        dragImageOffset->y += (stringSize.height / 2.0);
        result = newResult;
    }
    return result;
}

#pragma mark ** Dragging Destination Methods **

- (FileSystemNode *)_fileSystemNodeAtRow:(NSInteger)row column:(NSInteger)column {
    if (column >= 0) {
        NSIndexPath *indexPath = [_browser indexPathForColumn:column];
        if (row >= 0) {
            indexPath = [indexPath indexPathByAddingIndex:row];
        }
        id result = [_browser itemAtIndexPath:indexPath];
        return (FileSystemNode *)result;
    } else {
        return nil;
    }
}

- (NSDragOperation)browser:(NSBrowser *)browser validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger *)row column:(NSInteger *)column  dropOperation:(NSBrowserDropOperation *)dropOperation {
    NSDragOperation result = NSDragOperationNone;
    // We only accept file types
    if ([[[info draggingPasteboard] types] indexOfObject:NSFilenamesPboardType] != -1) {
        // For a between drop, we let the user drop "on" the parent item
        if (*dropOperation == NSBrowserDropAbove) {
            *row = -1;
        }
        // Only allow dropping in folders, but don't allow dragging from the same folder into itself, if we are the source
        if (*column != -1) {
            BOOL droppingFromSameFolder = ([info draggingSource] == browser) && (*column == _draggedColumnIndex);
            if (*row != -1) {
                // If we are dropping on a folder, then we will accept the drop at that row
                FileSystemNode *fileSystemNode = [self _fileSystemNodeAtRow:*row column:*column]; 
                if (fileSystemNode.isDirectory) {
                    // Yup, a good drop
                    result = NSDragOperationEvery;
                } else {
                    // Nope, we can't drop onto a file! We will retarget to the column, if it isn't the same folder.
                    if (!droppingFromSameFolder) {
                        result = NSDragOperationEvery;
                        *row = -1;
                        *dropOperation = NSBrowserDropOn;
                    }
                }
            } else if (!droppingFromSameFolder) {
                result = NSDragOperationEvery;
                *row = -1;
                *dropOperation = NSBrowserDropOn;
            }
        }
    }
    return result;
}

- (BOOL)browser:(NSBrowser *)browser acceptDrop:(id <NSDraggingInfo>)info atRow:(NSInteger)row column:(NSInteger)column dropOperation:(NSBrowserDropOperation)dropOperation {
    NSArray *filenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    // Find the target folder
    FileSystemNode *targetFileSystemNode = nil;
    if ((column != -1) && (filenames != nil)) {
        if (row != -1) {
            FileSystemNode *fileSystemNode = [self _fileSystemNodeAtRow:row column:column]; 
            if (fileSystemNode.isDirectory) {
                targetFileSystemNode = fileSystemNode;
            }
        } else {
            // Grab the parent for the column, which should be a directory
            targetFileSystemNode = (FileSystemNode *)[browser parentForItemsInColumn:column];
        }
    }
    
    // We now have the target folder, so move things around    
    if (targetFileSystemNode != nil) {
        NSString *targetFolder = [[targetFileSystemNode URL] path];
        NSMutableString *prettyNames = nil;
        NSInteger i;
        // Create a display name of all the selected filenames that are moving
        for (i = 0; i < [filenames count]; i++) {
            NSString *filename = [[NSFileManager defaultManager] displayNameAtPath:[filenames objectAtIndex:i]];
            if (prettyNames == nil) {
                prettyNames = [filename mutableCopy];                
            } else {
                [prettyNames appendString:@", "];
                [prettyNames appendString:filename];
            }
        }
        // Ask the user if they really want to move thos files.
        if ([[NSAlert alertWithMessageText:@"Verify file move" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"Would you like to move '%@' to '%@'?", prettyNames, targetFolder] runModal] == NSAlertDefaultReturn) {
            // Do the actual moving of the files.
            for (i = 0; i < [filenames count]; i++) {
                NSString *filename = [filenames objectAtIndex:i];
                NSString *targetPath = [targetFolder stringByAppendingPathComponent:[filename lastPathComponent]];
                // Normally, you should check the result of movePath to see if it worked or not.
                NSError *error = nil;
                if (![[NSFileManager defaultManager] moveItemAtPath:filename toPath:targetPath error:&error] && error) {
                    [NSApp presentError:error];
                    break;
                }
            }
            // It would be more efficient to invalidate the children of the "from" and "to" nodes and then call -reloadColumn: on each of the corresponding columns. However, we just reload every column
            [_rootNode invalidateChildren];
            for (NSInteger col = [_browser lastColumn]; col >= 0; col--) {
                [_browser reloadColumn:col];
            }
        }
        [prettyNames release];
        return YES;
    }
    return NO;
}

- (void)_browserDoubleClick:(id)sender {
    // Find the clicked item and open it in Finder
    FileSystemNode *clickedNode = [self _fileSystemNodeAtRow:_browser.clickedRow column:_browser.clickedColumn];
    if (clickedNode) {
        [[NSWorkspace sharedWorkspace] openFile:[clickedNode.URL path]];
    }
}


@end
