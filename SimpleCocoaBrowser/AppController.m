/*
     File: AppController.m
 Abstract: Application Controller object, and the NSBrowser delegate. An instance of this object is in the MainMenu.xib.
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */



#import "AppController.h"
#import "FileSystemNode.h"

// Turn on or off this define to use the new SnowLeopard item-based API
#define USE_ITEM_BASED_API 1

@implementation AppController

- (void)dealloc {
    [_rootNode release];
    [super dealloc];
}

#if USE_ITEM_BASED_API

// This method is optional, but makes the code much easier to understand
- (id)rootItemForBrowser:(NSBrowser *)browser {
    if (_rootNode == nil) {
        _rootNode = [[FileSystemNode alloc] initWithURL:[NSURL fileURLWithPath:@"/"]];
    }
    return _rootNode;    
}

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

#else

// This is a utility method to find the parent item for a given column. The item based API eliminates the need for this method.
- (FileSystemNode *)parentNodeForColumn:(NSInteger)column {
    if (_rootNode == nil) {
        _rootNode = [[FileSystemNode alloc] initWithURL:[NSURL fileURLWithPath:@"/"]];
    }
    
    FileSystemNode *result = _rootNode;
    // Walk up to this column, finding the selected row in the column before it and using that in the children array
    for (NSInteger i = 0; i < column; i++) {
        NSInteger selectedRowInColumn = [_browser selectedRowInColumn:i];
        FileSystemNode *selectedChildNode = [result.children objectAtIndex:selectedRowInColumn];
        result = selectedChildNode;
    }
    
    return result;
}

// Non-item based API example. This code will work on all systems, but applications targeting SnowLeopard and higher should use the new item-based API.

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column {
    FileSystemNode *parentNode = [self parentNodeForColumn:column];
    return parentNode.children.count;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(NSBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column {
    // Lazily setup the cell's properties in this method
    FileSystemNode *parentNode = [self parentNodeForColumn:column];
    FileSystemNode *childNode = [parentNode.children objectAtIndex:row];
    [cell setTitle:childNode.displayName];
    [cell setLeaf:!childNode.isDirectory];
}

#endif

@end
