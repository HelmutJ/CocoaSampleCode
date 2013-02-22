/*
     File: MyDocument.m
 Abstract: MyDocument manages a list of downloaded items.
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
#import "DownloadItem.h"
#import "DownloadCell.h"

NSString* const MyDocumentUTI = @"com.yourcompany.qldownloadlist";

// DownloadItem will be used directlty as the items in preview panel
// The class just need to implement the QLPreviewItem protocol
@interface DownloadItem (QLPreviewItem) <QLPreviewItem>

@end

@implementation DownloadItem (QLPreviewItem)

- (NSURL *)previewItemURL
{
    return self.resolvedFileURL;
}

- (NSString *)previewItemTitle
{
    return [self.originalURL absoluteString];
}

@end

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
        downloads = [[NSMutableArray alloc] init];
        selectedIndexes = [[NSIndexSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [download cancel];
    [download release];
    [originalURL release];
    [fileURL release];
    [downloads release];
    [selectedDownloads release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableArray* propertyList = [[NSMutableArray alloc] initWithCapacity:[downloads count]];
    
    for (DownloadItem* item in downloads) {
        id plistForItem = [item propertyListForSaving];
        if (plistForItem) {
            [propertyList addObject:plistForItem];
        }
    }
    
    NSData* result = [NSPropertyListSerialization dataWithPropertyList:propertyList
                                                                format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    [propertyList release];
    
    assert(result);
    
    return result;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSArray* propertyList = [NSPropertyListSerialization propertyListWithData:data
                                                                      options:NSPropertyListImmutable
                                                                       format:NULL error:outError];
    if (!propertyList) {
        return NO;
    }
    
    if (![propertyList isKindOfClass:[NSArray class]]) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:NULL];
        }
        return NO;
    }
    
    NSMutableArray* observableDownloads = [self mutableArrayValueForKey:@"downloads"];
    [observableDownloads removeAllObjects];
    
    for (id plistItem in propertyList) {
        DownloadItem* item = [[DownloadItem alloc] initWithSavedPropertyList:plistItem];
        if (item) {
            [observableDownloads addObject:item];
            [item release];
        }
    }
    
    return YES;
}

- (IBAction)startDownload:(id)sender
{
    assert(!download);
    
    NSString* urlString = [downloadURLField stringValue];
    assert(urlString);
    
    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([urlString length] == 0) {
        NSBeep();
        return;
    }
    
    NSURL* url = [NSURL URLWithString:urlString];
    if (!url) {
        NSBeep();
        return;
    }
    
    originalURL = [url copy];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    self.downloadIsIndeterminate = YES;
    self.downloadProgress = 0.0f;
    self.downloading = YES;
    
    download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
    
    [[downloadsTableView window] makeFirstResponder:downloadsTableView];
}

@synthesize downloading, downloadProgress, downloadIsIndeterminate, selectedDownloads, selectedIndexes;

- (void)setSelectedIndexes:(NSIndexSet *)indexSet
{
    if (indexSet != selectedIndexes) {
        indexSet = [indexSet copy];
        [selectedIndexes release];
        selectedIndexes = indexSet;
        self.selectedDownloads = [downloads objectsAtIndexes:indexSet];
    }
}

- (void)setSelectedDownloads:(NSArray *)array
{
    if (array != selectedDownloads) {
        array = [array copy];
        [selectedDownloads release];
        selectedDownloads = array;
        [previewPanel reloadData];
    }
}

// Download support

- (void)displayDownloadProgressView
{
    if (!downloading) {
        return;
    }

    // position and size downloadsProgressFrame appropriately
    NSRect downloadProgressFrame = [downloadProgressView frame];
    NSRect downloadsFrame = [downloadsView frame];
    downloadProgressFrame.size.width = downloadsFrame.size.width;
    downloadProgressFrame.origin.y = NSMaxY(downloadsFrame);
    [downloadProgressView setFrame:downloadProgressFrame];
    
    [[[downloadsView superview] animator] addSubview:downloadProgressView positioned:NSWindowBelow relativeTo:downloadsView];
}

- (void)startDisplayingProgressView
{
    if (!downloading || [downloadProgressView superview]) {
        return;
    }
    
    
    // we are starting a download, display the download progress view
    NSRect downloadProgressFrame = [downloadProgressView frame];
    NSRect downloadsFrame = [downloadsView frame];
    
    // reduce the size of the downloads view
    downloadsFrame.size.height -= downloadProgressFrame.size.height;
    
    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setDuration:0.2];
    
    [[downloadsView animator] setFrame:downloadsFrame];
    
    [NSAnimationContext endGrouping];
    
    [self performSelector:@selector(displayDownloadProgressView) withObject:nil afterDelay:0.2];
}

- (void)hideDownloadProgressView
{
    if (downloading) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayDownloadProgressView) object:nil];
    
    // we are ending a download, remove the download progress view
    [downloadProgressView removeFromSuperview];

    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    [[downloadsView animator] setFrame:[[downloadsView superview] bounds]];
    
    [NSAnimationContext endGrouping];
}

- (void)setDownloading:(BOOL)flag
{
    if (!flag != !downloading) {
        if (flag) {
            [self performSelector:@selector(startDisplayingProgressView) withObject:nil afterDelay:0.0];
        } else {            
            [self performSelector:@selector(hideDownloadProgressView) withObject:nil afterDelay:0.1];
            [originalURL release];
            originalURL = nil;
            [fileURL release];
            fileURL = nil;
            [download release];
            download = nil;
        }
        downloading = flag;
    }
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response;
{
    expectedContentLength = [response expectedContentLength];
    if (expectedContentLength > 0.0) {
        self.downloadIsIndeterminate = NO;
        downloadedSoFar = 0;
    }
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    downloadedSoFar += length;
    if (downloadedSoFar >= expectedContentLength) {
        // the expected content length was wrong as we downloaded more than expected
        // make the progress indeterminate
        self.downloadIsIndeterminate = YES;
    } else {
        self.downloadProgress = (float)downloadedSoFar / (float)expectedContentLength;
    }
}


- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSString* path = [[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:filename];
    [aDownload setDestination:path allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
    fileURL = [[NSURL alloc] initFileURLWithPath:path];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    if (originalURL && fileURL) {
        DownloadItem* item = [[DownloadItem alloc] initWithOriginalURL:originalURL fileURL:fileURL];
        if (item) {
            [[self mutableArrayValueForKey:@"downloads"] addObject:item];
            [item release];
            [self updateChangeCount:NSChangeDone];
        } else {
            NSLog(@"Can't create download item at %@", fileURL);
        }
    }
    
    self.downloading = NO;
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
    [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    self.downloading = NO;
}

// table view delegate
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqual:@"Filename"]) {
        ((DownloadCell *)cell).originalURL = ((DownloadItem *)[downloads objectAtIndex:row]).originalURL;
        [cell setFont:[NSFont systemFontOfSize:TEXT_SIZE]];
    }
}

// Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = [panel retain];
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    [previewPanel release];
    previewPanel = nil;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [selectedDownloads count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [selectedDownloads objectAtIndex:index];
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    // redirect all key down events to the table view
    if ([event type] == NSKeyDown) {
        [downloadsTableView keyDown:event];
        return YES;
    }
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    NSInteger index = [downloads indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    }
        
    NSRect iconRect = [downloadsTableView frameOfCellAtColumn:0 row:index];
    
    // check that the icon rect is visible on screen
    NSRect visibleRect = [downloadsTableView visibleRect];
    
    if (!NSIntersectsRect(visibleRect, iconRect)) {
        return NSZeroRect;
    }
    
    // convert icon rect to screen coordinates
    iconRect = [downloadsTableView convertRectToBase:iconRect];
    iconRect.origin = [[downloadsTableView window] convertBaseToScreen:iconRect.origin];
    
    return iconRect;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    DownloadItem* downloadItem = (DownloadItem *)item;

    return downloadItem.iconImage;
}

@end
