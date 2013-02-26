/*

File: AssetCollectionView.m

Abstract: An AssetCollectionView displays a collection of Assets, each represented by an AssetViewCollectionViewNode that manages a small view subtree.  Specifically, this is the view in Cocoa Slides that displays the gray gradient (or Quartz Composition) background, and serves as a container view for the "slides".

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

#import "AssetCollectionView.h"
#import "AssetCollectionViewNode.h"
#import "AssetCollection.h"
#import "SlideCarrierView.h"
#import "ViewLayout.h"
#import <Quartz/Quartz.h>

// This is the document view class for Browser windows.

@implementation AssetCollectionView

- (void)startLayoutCycleTimer {
    if (layoutTimer == nil) {
        // Schedule an ordinary NSTimer that will invoke -cycleLayout: at regular intervals, prompting us to advance to the next layout.
        layoutTimer = [[NSTimer scheduledTimerWithTimeInterval:[self layoutCycleInterval] target:self selector:@selector(cycleLayout:) userInfo:nil repeats:YES] retain];
    }
}

- (void)stopLayoutCycleTimer {
    if (layoutTimer != nil) {
        // Cancel and release the layout advance timer.
        [layoutTimer invalidate];
        [layoutTimer release];
        layoutTimer = nil;
    }
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        assetCollection = nil;
        nodes = [[NSMutableArray alloc] init];
        subviewsLayoutType = 3;
        layoutCycleInterval = 3.0;
    }
    return self;
}

- (void)dealloc {
    [self setAutoCyclesLayout:NO];
    [self setAssetCollection:nil];
    [self setSortDescriptors:nil];
    [backgroundGradient release];
    [nodes release];
    [super dealloc];
}

- (BOOL)acceptsFirstMouse {
    return YES;
}

- (NSArray *)animatorsForArrangedSubviews {
    // Return a sorted array of the view's subviews' animator objects.  The way this code is written illustrates an important and useful property of view animators: Asking a view's animator for its "subviews" actually returns an array of the view's subviews' animator proxies.  Likewise, asking a view's animator for its "superview" would return the view's superview's animator.  Thus a view's animator can be passed to code that expects to traverse the view hierarchy via the "superview" and "subviews" relationships starting from some particular view.
    return [[[self animator] subviews] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSTimeInterval)layoutCycleInterval {
    return layoutCycleInterval;
}

- (void)setLayoutCycleInterval:(NSTimeInterval)newLayoutCycleInterval {
    if (layoutCycleInterval != newLayoutCycleInterval) {
        // Change the interval as requested, and then restart the layout cycle timer.
        layoutCycleInterval = newLayoutCycleInterval;
        if ([self autoCyclesLayout]) {
            [self stopLayoutCycleTimer];
            [self startLayoutCycleTimer];
        }
    }
}

- (double)layoutDuration {
    // Read layout duration from user defaults, or fall back to 2.5 seconds.
    id duration = [[NSUserDefaults standardUserDefaults] objectForKey:@"layoutDuration"];
    if (duration == nil) {
        duration = [NSNumber numberWithDouble:2.5];
        [[NSUserDefaults standardUserDefaults] setObject:duration forKey:@"layoutDuration"];
    }
    return [duration doubleValue];
}

- (void)layoutSubviews {
    ViewLayout *layout = nil;
    switch (subviewsLayoutType) {
        case 0: layout = [CircularViewLayout viewLayout]; break;
        case 1: layout = [LoopViewLayout viewLayout]; break;
        case 2: layout = [ScatterViewLayout viewLayout]; break;
        case 3: layout = [WrappedViewLayout viewLayout]; break;
    }
    if (layout) {
        // Push an NSAnimationContext on the animation context stack, and set its duration to the desired amount of time (expressed in seconds).  All animations initiated within this grouping will be given the same implied start time and duration.
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:[self layoutDuration]];

        // Note the power of "animator" proxy objects at work here!  The various ViewLayout classes were written to expect a view and an array of subviews (sorted in the desired order) as parameters.  By simply passing the animators of the subviews to be laid out in place of the subviews themselves, we can use our existing static layout code to initiate animations.  The -layoutSubviews:ofView: method that we invoke below ends up talking to view animators instead of the views themselves, without even knowing it.
        [layout layoutSubviews:[self animatorsForArrangedSubviews] ofView:self];

        // Pop the NSAnimationContext, triggering execution of the animations we just grouped in a single time-syncrhonized batch.
        [NSAnimationContext endGrouping];
    }
}

- (AssetCollection *)assetCollection {
    return assetCollection;
}

- (void)setAssetCollection:(AssetCollection *)newAssetCollection {
    if (assetCollection != newAssetCollection) {
        // Stop observing changes in our previous assetCollection.
        id old = assetCollection;
        [old removeObserver:self forKeyPath:@"assets"];

        // Retain our newly assigned assetCollection and release our previous one.
        assetCollection = [newAssetCollection retain];
        [old release];

        // Release our previous slide views and build new ones to represent the contents of our new assetCollection.
        [self reloadData];

        // Sign up to observe changes in our new assetCollection.  Whenever a new asset is added to or removed from the collection, the Key-Value Observing (KVO) mechanism will send us a -observeValueForKeyPath:ofObject:change:context: message, which we can respond to as needed to update the set of slides that we display.
        [assetCollection addObserver:self forKeyPath:@"assets" options:0 context:NULL];
    }
}

- (void)cycleLayout:(NSTimer *)timer {
    // Advance to the next layout type from among the four example layouts we provide, and re-layout our slide views.
    [self setSubviewsLayoutType:([self subviewsLayoutType] + 1) % 4];
}

- (BOOL)autoCyclesLayout {
    return autoCyclesLayout;
}

- (void)setAutoCyclesLayout:(BOOL)flag {
    if (autoCyclesLayout != flag) {
        autoCyclesLayout = flag;
        if (autoCyclesLayout) {
            // Schedule a timer to prompt us to -cycleLayout: at regular intervals, and also perform an initial -cycleLayout: now, to give the user immediate feedback.
            [self startLayoutCycleTimer];
            [self cycleLayout:layoutTimer];
        } else {
            // Cancel our layout cycle timer.
            [self stopLayoutCycleTimer];
        }
    }
}

- (BOOL)slidesHaveShadows {
    return slidesHaveShadows;
}

- (void)setSlidesHaveShadows:(BOOL)flag {
    if (slidesHaveShadows != flag) {
        slidesHaveShadows = flag;
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        if (slidesHaveShadows) {
            [shadow setShadowOffset:NSMakeSize(3, -3)];
            [shadow setShadowBlurRadius:4.0];
            [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.75]];
        } else {
            shadow = nil;
        }

        // Begin a grouping of animation target value settings.
        [NSAnimationContext beginGrouping];

        // Request a default animation duration of 0.5 seconds.
        [[NSAnimationContext currentContext] setDuration:0.5];

        // For each slide node, get the slide's rootView, and set the rootView's "shadow" property to the new shadow we chose above.  By messaging through the rootView's animator when we make this change, we allow for the change in shadow properties to be animated with the duration we just specified, instead of having the change take effect immediately.
        for (AssetCollectionViewNode *node in nodes) {
            [[[node rootView] animator] setShadow:shadow];
        }

        // End the grouping of animation target value settings, causing the animations in the grouping to be started simultaneously.
        [NSAnimationContext endGrouping];
    }
}

- (int)subviewsLayoutType {
    return subviewsLayoutType;
}

- (void)setSubviewsLayoutType:(int)layoutType {
    subviewsLayoutType = layoutType;

    // Update view layout when desired layout type changes.
    [self layoutSubviews];
}

- (NSArray *)sortDescriptors {
    return sortDescriptors;
}

- (void)setSortDescriptors:(NSArray *)newSortDescriptors {
    if (sortDescriptors != newSortDescriptors) {
        id old = sortDescriptors;
        sortDescriptors = [newSortDescriptors copy];
        [old release];

        // Update view layout when sort descriptors change.
        if (sortDescriptors) {
            [self layoutSubviews];
        }
    }
}

// Creates a new AssetCollectionViewNode to represent the asset at the given index in our assetCollection.  The node acts as a controller object that associates a given Asset with a view subtree (automatically created by the node when we ask it for its "rootView" below) that we use to visually represent the asset.  An AssetCollectionView invokes this method automatically whenever it's asked to "reloadData" or when it detects via Key-Value Observing that the AssetCollection it has been asked to display has acquired a new Asset.
- (AssetCollectionViewNode *)insertNodeForAssetAtIndex:(NSUInteger)index {
    Asset *asset = [[[self assetCollection] assets] objectAtIndex:index];
    AssetCollectionViewNode *node = [[AssetCollectionViewNode alloc] init];
    [node setAsset:asset];
    [[self animator] addSubview:[node rootView]];
    [nodes addObject:node];

    return [node autorelease];
}

// Removes the AssetCollectionViewNode and associated view subtree that represent the asset at the given index in our assetCollection.  An AssetCollectionView invokes this method automatically whenever it's asked to "reloadData" or when it detects via Key-Value Observing that the AssetCollection it has been asked to display has had an Asset removed from it.
- (void)removeNodeForAssetAtIndex:(NSUInteger)index {
    AssetCollectionViewNode *node = [nodes objectAtIndex:index];
    [[node rootView] removeFromSuperview];
    [nodes removeObjectAtIndex:index];
}

// This message is sent when some unspecified change has been to our assetCollection (including possibly its replacement with another, different assetCollection instance).  The AssetCollectionView responds by disposing of its nodes and associated slide views, creating new ones corresponding to the new set of assets, and performing layout of those new slide views.
- (void)reloadData {
    // Resize to accommodate the number of images in the catalog.
    NSArray *assets = [[self assetCollection] assets];

    // Remove all our current slide views and their associated node objects.  NSView's -setSubviews: method is new API on 10.5 that makes it easy to reorder, replace, or remove a view's subviews.  In this case, we're setting the AssetCollectionView's subviews list to an empty array, to remove all of its current subviews.
    [self setSubviews:[NSArray array]];
    [nodes removeAllObjects];

    // Create new slide views.
    NSUInteger count = [assets count];
    NSUInteger index;
    for (index = 0; index < count; index++) {
        [self insertNodeForAssetAtIndex:index];
    }

    // Now lay the slide views out.
    [self layoutSubviews];
}

// Invoked by -observeValueForKeyPath:ofObject:change:context:, below.  This method iterates through the set of assets that have been inserted, adding a new corresponding node for each such asset, and updates the layout of our new set of slide views accordingly.
- (void)handleAssetsInsertedInCatalogAtIndexes:(NSIndexSet *)indexes {
    NSUInteger index = [indexes firstIndex];
    while (index != NSNotFound) {
        [self insertNodeForAssetAtIndex:index];

        // Update view layout when new views have been inserted.
        [self layoutSubviews];
        [self display];

        index = [indexes indexGreaterThanIndex:index];
    }
}

// Invoked by -observeValueForKeyPath:ofObject:change:context:, below.  This method iterates through the set of assets that have been removed, removing the corresponding node for each such asset, and updates the layout of our remaining slide views accordingly.
- (void)handleAssetsRemovedFromCatalogAtIndexes:(NSIndexSet *)indexes {
    NSUInteger index = [indexes firstIndex];
    while (index != NSNotFound) {
        [self removeNodeForAssetAtIndex:index];

        // Update view layout when views have been removed.
        [self layoutSubviews];
        [self display];

        index = [indexes indexGreaterThanIndex:index];
    }
}

// As a result of the -addObserver:forKeyPath:options:context: call in -setAssetCollection:, Cocoa's Key-Value Observing mechanism will send us this message whenever a change occurs in our associated assetCollection.  To keep our code more cleanly compartmentalized, this method simply checks for the kind of change that's being reported, and dispatches an appropriate handler method: either -handleAssetsInsertedInCatalogAtIndexes: (if assets have been added to the collection), -handleAssetsRemovedFromCatalogAtIndexes: (if assets have been removed from the collection), or -reloadData (if the collection's contents have changed in an arbitrary, unspecified way).
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSKeyValueChange kind = [[change valueForKey:@"kind"] integerValue];

    switch (kind) {

        case NSKeyValueChangeInsertion:
            // New assets were found.  Add visual representations for them.
            [self handleAssetsInsertedInCatalogAtIndexes:[change valueForKey:@"indexes"]];
            break;

        case NSKeyValueChangeRemoval:
            // Assets we were tracking disappeared.  Remove their visual representations.
            [self handleAssetsRemovedFromCatalogAtIndexes:[change valueForKey:@"indexes"]];
            break;

        case NSKeyValueChangeSetting:
        default:
            [self reloadData];
            break;
    }
}

- (void)drawRect:(NSRect)rect {
    // Draw a dark gray gradient background, using the new NSGradient class that has been added in Leopard.
    if (backgroundGradient == nil) {
        backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.27 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.08 alpha:1.0]];
    }
    [backgroundGradient drawInRect:[self bounds] angle:90.0];
}

- (BOOL)usesQuartzCompositionBackground {
    return usesQuartzCompositionBackground;
}

- (void)setUsesQuartzCompositionBackground:(BOOL)flag {
    if (usesQuartzCompositionBackground != flag) {
        usesQuartzCompositionBackground = flag;

        // We can display a Quartz Composition in a layer-backed view tree by substituting our own QCCompositionLayer in place of the default automanaged layer that AppKit would otherwise create for the view.  Eventually, hosting of QCViews in a layer-backed view subtree may be made more automatic, rendering this unnecessary.  To minimize visual glitches during the transition, temporarily suspend window updates during the switch, and toggle layer-backed view rendering temporarily off and back on again while we prepare and set the layer.
        [[self window] disableScreenUpdatesUntilFlush];
        [self setWantsLayer:NO];
        if (usesQuartzCompositionBackground) {
            QCCompositionLayer *qcLayer = [QCCompositionLayer compositionLayerWithFile:[[NSBundle mainBundle] pathForResource:@"Cells" ofType:@"qtz"]];
            [self setLayer:qcLayer];
        } else {
            [self setLayer:nil]; // Discard the QCCompositionLayer we were using, and let AppKit automatically create self's backing layer instead.
        }
        [self setWantsLayer:YES];
    }
}

@end
