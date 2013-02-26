/*

File: BrowserWindowController.m

Abstract: Window Controller Class for CocoaSlides Browser Windows

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

#import "BrowserWindowController.h"
#import "Asset.h"
#import "AssetCollection.h"
#import "AssetCollectionView.h"

@implementation BrowserWindowController

- initWithPath:(NSString *)newPath {
    self = [super initWithWindowNibName:@"BrowserWindow"];
    if (self) {
        path = [newPath copy];
        sortKey = [@"filename" copy];
        sortsAscending = YES;
    }
    return self;
}

- (void)dealloc {
    [sortKey release];
    [assetCollection release];
    [path release];
    [super dealloc];
}

- (void)updateSortDescriptors {
    // Build a new NSSortDescriptor that we can use to order our image assets, according to the current "sortKey" and "sortsAscending" setting.
    NSString *effectiveSortKey = [[NSString alloc] initWithFormat:@"asset.%@", [self sortKey]];
    NSSortDescriptor *sortDescriptor = nil;
    if ([[self sortKey] isEqualToString:@"filename"]) {
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:effectiveSortKey ascending:[self sortsAscending] selector:@selector(caseInsensitiveCompare:)];
    } else {
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:effectiveSortKey ascending:[self sortsAscending]];
    }

    // Tell our AssetCollectionView to use the new sort descriptor.
    [assetCollectionView setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
}

- (NSString *)sortKey {
    return sortKey;
}

- (void)setSortKey:(NSString *)newSortKey {
    if (sortKey != newSortKey) {
        id old = sortKey;
        sortKey = [newSortKey copy];
        [old release];

        [self updateSortDescriptors];
    }
}

- (BOOL)sortsAscending {
    return sortsAscending;
}

- (void)setSortsAscending:(BOOL)flag {
    if (sortsAscending != flag) {
        sortsAscending = flag;

        [self updateSortDescriptors];
    }
}

- (void)windowDidLoad {
    // Ask for assetCollectionView and all its descendants to be rendered and animated using layers.  Note that this is the only part of this code sample that refers in any way to the existence of layers. -- AppKit takes care of the implications of this automatically!  Interface Builder 3.0 even allows the per-view "wantsLayer" flag to be set in the .nib, which would allow removing these two lines of code.
    [assetCollectionView setWantsLayer:YES];

    // Create an AssetCollection for browsing our assigned path.
    assetCollection = [[AssetCollection alloc] initWithRootURL:[NSURL fileURLWithPath:path]];

    // Set the window's title to the name of the folder we're browsing.
    [[assetCollectionView window] setTitle:[path lastPathComponent]];

    // Hook things up and start loading thumbnails.
    [self updateSortDescriptors];
    [assetCollectionView setAssetCollection:assetCollection];
    [assetCollection startRefresh];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    // Rescan for filesystem changes each time window becomes key again.
    [assetCollection startRefresh];
}

- (void)refresh:(id)sender {
    // Ask our assetCollection to check for new, changed, and removed asset files.  Our assetCollectionView will be automatically notified of any changes to the assetCollection via KVO.
    [assetCollection startRefresh];
}

- (IBAction)showSlideshowWindow:(id)sender {
    [slideshowWindowController setAssetCollection:assetCollection];
    [slideshowWindowController showWindow:self];
}

@end
