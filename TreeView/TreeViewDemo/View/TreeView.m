/*
    File: TreeView.m
Abstract: TreeView Implementation
 Version: 1.3

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

#import "TreeView.h"
#import "TreeView_Internal.h"
#import "SubtreeView.h"
#import "ContainerView.h"
#import "TreeViewColorConversion.h"
#import <QuartzCore/QuartzCore.h>

@interface NSScrollView (LionAdditionsWeUse)
- (void)flashScrollers;
@end

@implementation TreeView

@synthesize animatesLayout;
@synthesize layoutAnimationSuppressed;
@synthesize minimumFrameSize;

#pragma mark *** Creating Instances ***

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialize ivars directly.  As a rule, it's best to avoid invoking accessors from an -init... method, since they may wrongly expect the instance to be fully formed.
        modelNodeToSubtreeViewMapTable = [[NSMapTable weakToStrongObjectsMapTable] retain];
        backgroundColor = [[NSColor colorWithCalibratedRed:0.55 green:0.76 blue:0.93 alpha:1.0] copy];
        connectingLineColor = [[NSColor blackColor] copy];
        contentMargin = 40.0;
        parentChildSpacing = 50.0;
        siblingSpacing = 10.0;
        animatesLayout = YES;
        resizesToFillEnclosingScrollView = YES;
        layoutAnimationSuppressed = NO;
        connectingLineStyle = TreeViewConnectingLineStyleDirect;
        connectingLineWidth = 1.0;
        showsSubtreeFrames = NO;
        minimumFrameSize = NSMakeSize(2.0 * contentMargin, 2.0 * contentMargin);
        selectedModelNodes = [[NSMutableSet alloc] init];

        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
    }
    return self;
}


#pragma mark *** Optimizations for Layer-Backed Mode ***

/* Overrides NSView's default backing layer creation mechanism, to substitute a layer of a different type.  Ordinarily, for any view that's used as the documentView of an NSScrollView, AppKit creates a "tiled" backing layer, allowing the documentView to grow to sizes that exceed the maximum ordinary CALayer backing store size (which is the system's maximum texture size -- typically 2K pixels square).  Since TreeView only draws a solid fill color, and relies on its descendant views to provide all the other content, it's unnecessary to allocate any layer backing store for it at all.  Instead, we can just give the TreeView an ordinary CALayer as a backing layer, and set that CALayer to be programmatically filled with the TreeView's backgroundColor.  Since the CALayer will never acquire a backing store (because we set the TreeViewe's layerContentsRedrawPolicy to NSViewLayerContentsRedrawNever), it can safely exceed the maximum texture size.  This approach is faster, and saves backing store memory too!
*/
- (CALayer *)makeBackingLayer {
    CALayer *layer = [CALayer layer];
    [layer setBackgroundColor:TreeView_CGColorFromNSColor(backgroundColor)];
    return layer;
}


#pragma mark *** Root SubtreeView Access ***

- (SubtreeView *)rootSubtreeView {
    return [self subtreeViewForModelNode:[self modelRoot]];
}


#pragma mark *** Node View Nib Specification ***

- (NSString *)nodeViewNibName {
    return nodeViewNibName;
}

- (void)setNodeViewNibName:(NSString *)newName {
    if (nodeViewNibName != newName) {
        [self setCachedNodeViewNib:nil];

        [nodeViewNibName release];
        nodeViewNibName = [newName copy];

        // TODO: Tear down and (later) rebuild view tree.
    }
}

- (NSBundle *)nodeViewNibBundle {
    return nodeViewNibBundle;
}

- (void)setNodeViewNibBundle:(NSBundle *)newBundle {
    if (nodeViewNibBundle != newBundle) {
        [self setCachedNodeViewNib:nil];

        [nodeViewNibBundle release];
        nodeViewNibBundle = [newBundle retain];

        // TODO: Tear down and (later) rebuild view tree.
    }
}


#pragma mark *** Node View Nib Caching ***

- (NSNib *)cachedNodeViewNib {
    return cachedNodeViewNib;
}

- (void)setCachedNodeViewNib:(NSNib *)newNib {
    if (cachedNodeViewNib != newNib) {
        [cachedNodeViewNib release];
        cachedNodeViewNib = [newNib retain];
    }
}


#pragma mark *** Selection State ***

/* The unordered set of model nodes that are currently selected in the TreeView.  When no nodes are selected, this is an empty NSSet.  It will never be nil (and attempting to set it to nil will raise an exception).
*/
- (NSSet *)selectedModelNodes {
    return [[selectedModelNodes retain] autorelease];
}

- (void)setSelectedModelNodes:(NSSet *)newSelectedModelNodes {
    NSParameterAssert(newSelectedModelNodes != nil); // Never pass nil. Pass [NSSet set] instead.
    
    // Verify that each of the nodes in the new selection is in the TreeView's assigned model tree.
    for (id modelNode in newSelectedModelNodes) {
        NSAssert([self modelNodeIsInAssignedTree:modelNode], @"modelNode is not in the tree");
    }

    if (selectedModelNodes != newSelectedModelNodes) {
        // Determine which nodes are changing selection state (either becoming selected, or ceasing to be selected), and mark affected areas as needing display.  Take the union of the previous and new selected node sets, subtract the set of nodes that are in both the old and new selection, and the result is the set of nodes whose selection state is changing.
        NSMutableSet *combinedSet = [selectedModelNodes mutableCopy];
        [combinedSet unionSet:newSelectedModelNodes];

        NSMutableSet *intersectionSet = [selectedModelNodes mutableCopy];
        [intersectionSet intersectSet:newSelectedModelNodes];

        NSMutableSet *differenceSet = [combinedSet mutableCopy];
        [differenceSet minusSet:intersectionSet];

        // Discard the old selectedModelNodes set and replace it with the new one.
        [selectedModelNodes release];
        selectedModelNodes = [newSelectedModelNodes mutableCopy];

        for (id<TreeViewModelNode> modelNode in differenceSet) {
            SubtreeView *subtreeView = [self subtreeViewForModelNode:modelNode];
            NSView *nodeView = [subtreeView nodeView];
            if (nodeView && [nodeView isKindOfClass:[ContainerView class]]) {
                // TODO: Selection-highlighting is currently hardwired to our use of ContainerView.  This should be generalized.
                [(ContainerView *)nodeView setShowingSelected:([newSelectedModelNodes containsObject:modelNode] ? YES : NO)];
            }
        }

        // Release the temporary sets we created.
        [differenceSet release];
        [combinedSet release];
        [intersectionSet release];
    }
}

- (id<TreeViewModelNode>)singleSelectedModelNode {
    NSSet *selection = [self selectedModelNodes];
    return ([selection count] == 1) ? [selection anyObject] : nil;
}

- (NSRect)selectionBounds {
    return [self boundsOfModelNodes:[self selectedModelNodes]];
}


#pragma mark *** Graph Building ***

- (SubtreeView *)newRecursiveBuildGraphForModelNode:(id<TreeViewModelNode>)modelNode {
    NSParameterAssert(modelNode);

    SubtreeView *subtreeView = [[SubtreeView alloc] initWithModelNode:modelNode];
    if (subtreeView) {

        // Get nib from which to load nodeView.
        NSNib *nodeViewNib = [self cachedNodeViewNib];
        if (nodeViewNib == nil) {
            NSString *nibName = [self nodeViewNibName];
            NSAssert(nibName != nil, @"You must set a non-nil nodeViewNibName for TreeView to be able to build its view tree");
            if (nibName != nil) {
                nodeViewNib = [[NSNib alloc] initWithNibNamed:[self nodeViewNibName] bundle:[self nodeViewNibBundle]];
                [self setCachedNodeViewNib:nodeViewNib];
                [nodeViewNib release];
            }
        }

        // Instantiate the nib to create our nodeView and associate it with the subtreeView (the nib's owner).
        // TODO: Keep track of topLevelObjects, to release later.
        if ([nodeViewNib instantiateWithOwner:subtreeView topLevelObjects:nil]) {

            // Add the nodeView as a subview of the subtreeView.
            [subtreeView addSubview:[subtreeView nodeView]];

            // Register the subtreeView in our map table, so we can look it up by its modelNode.
            [self setSubtreeView:subtreeView forModelNode:modelNode];

            // Recurse to create a SubtreeView for each descendant of modelNode.
            NSArray *childModelNodes = [modelNode childModelNodes];
            for (id<TreeViewModelNode> childModelNode in childModelNodes) {
                SubtreeView *childSubtreeView = [self newRecursiveBuildGraphForModelNode:childModelNode];
                if (childSubtreeView) {
                    // Add the child subtreeView behind the parent subtreeView's nodeView (so that when we collapse the subtree, its nodeView will remain frontmost).
                    [subtreeView addSubview:childSubtreeView positioned:NSWindowBelow relativeTo:[subtreeView nodeView]];
                    [childSubtreeView release];
                }
            }
        } else {
            [subtreeView release];
            subtreeView = nil;
        }
    }
    return subtreeView;
}

- (void)buildGraph {

    // Traverse the model tree, building a SubtreeView for each model node.
    id<TreeViewModelNode> root = [self modelRoot];
    if (root) {
        SubtreeView *rootSubtreeView = [self newRecursiveBuildGraphForModelNode:root];
        if (rootSubtreeView) {
            [self addSubview:rootSubtreeView];
            [rootSubtreeView release];
        }
    }
}


#pragma mark *** Layout ***

- (void)updateFrameSizeForContentAndClipView {
    NSSize newFrameSize;
    NSSize newMinimumFrameSize = [self minimumFrameSize];
    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    if ([self resizesToFillEnclosingScrollView] && enclosingScrollView && [enclosingScrollView documentView] == self) {
        // This TreeView is an NSScrollView's documentView: Size it to always fill the content area (at minimum).
        NSClipView *contentView = [enclosingScrollView contentView];
        NSRect contentViewBounds = [contentView bounds];
        newFrameSize.width = MAX(newMinimumFrameSize.width, contentViewBounds.size.width);
        newFrameSize.height = MAX(newMinimumFrameSize.height, contentViewBounds.size.height);
    } else {
        newFrameSize = newMinimumFrameSize;
    }

    // If we're resizing the TreeView, and are running on 10.7 or later, prompt our enclosing NSScrollView (if any) to pulse its scrollers to visible to indicate the new scrollable range.  (If the scroller style is not overlay, or if there is no scrollable range, this will have no effect.)
    NSSize oldFrameSize = [self frame].size;
    if (!NSEqualSizes(newFrameSize, oldFrameSize)) {
        NSScrollView *scrollView = [self enclosingScrollView];
        if ([scrollView respondsToSelector:@selector(flashScrollers)]) {
            [scrollView flashScrollers];
        }
        [self setFrameSize:newFrameSize];
    }
}

- (void)updateRootSubtreeViewPositionForSize:(NSSize)rootSubtreeViewSize {
    // Position the rootSubtreeView within the TreeView.
    SubtreeView *rootSubtreeView = [self rootSubtreeView];
    BOOL animateLayout = [self animatesLayout] && ![self layoutAnimationSuppressed];
    NSPoint newOrigin;
    if ([self resizesToFillEnclosingScrollView]) {
        NSRect bounds = [self bounds];
        newOrigin = NSMakePoint([self contentMargin], 0.5 * (bounds.size.height - rootSubtreeViewSize.height));
    } else {
        newOrigin = NSMakePoint([self contentMargin], [self contentMargin]);
    }
    [(animateLayout ? [rootSubtreeView animator] : rootSubtreeView) setFrameOrigin:newOrigin];
}

- (BOOL)resizesToFillEnclosingScrollView {
    return resizesToFillEnclosingScrollView;
}

- (void)setResizesToFillEnclosingScrollView:(BOOL)flag {
    if (resizesToFillEnclosingScrollView != flag) {
        resizesToFillEnclosingScrollView = flag;
        [self updateFrameSizeForContentAndClipView];
        [self updateRootSubtreeViewPositionForSize:[[self rootSubtreeView] frame].size];
    }
}

- (void)parentClipViewDidResize:(id)object {
    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    if (enclosingScrollView && [enclosingScrollView documentView] == self) {
        [self updateFrameSizeForContentAndClipView];
        [self updateRootSubtreeViewPositionForSize:[[self rootSubtreeView] frame].size];
    }
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    // Ask to be notified when our superview's frame size changes (if it's an NSClipView, which is a pretty good indication that this TreeView is an NSScrollView's documentView), so that we can automatically resize to always fill the NSScrollView's content area.
    NSView *oldSuperview = [self superview];
    if (oldSuperview) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:oldSuperview];
    }
    if (newSuperview && [newSuperview isKindOfClass:[NSClipView class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentClipViewDidResize:) name:NSViewFrameDidChangeNotification object:newSuperview];
    }
    [super viewWillMoveToSuperview:newSuperview];
}

- (void)viewWillDraw {

    // Do graph layout if we need to.
    [self layoutGraphIfNeeded];

    // Always call up to [super viewWillDraw], either before or after doing your work, to continue the -viewWillDraw recursion for descendant views.
    [super viewWillDraw];
}

- (NSSize)layoutGraphIfNeeded {
    SubtreeView *rootSubtreeView = [self rootSubtreeView];
    if ([self needsGraphLayout] && [self modelRoot]) {

        // TODO: Build graph tree if needed.

        // Do recursive graph layout, starting at our rootSubtreeView.
        NSSize rootSubtreeViewSize = [rootSubtreeView layoutGraphIfNeeded];

        // Compute self's new minimumFrameSize.  Make sure it's pixel-integral.
        CGFloat margin = [self contentMargin];
        NSSize minimumBoundsSize = NSMakeSize(rootSubtreeViewSize.width + 2.0 * margin, rootSubtreeViewSize.height + 2.0 * margin);
        NSSize pixelSize = [self convertSize:minimumBoundsSize toView:nil];
        pixelSize.width = ceil(pixelSize.width);
        pixelSize.height = ceil(pixelSize.height);
        NSSize newMinimumFrameSize = [[self superview] convertSize:pixelSize fromView:nil];
        [self setMinimumFrameSize:newMinimumFrameSize];

        // Set the TreeView's frame size.
        [self updateFrameSizeForContentAndClipView];

        // Position the TreeView's root SubtreeView.
        [self updateRootSubtreeViewPositionForSize:rootSubtreeViewSize];

        return rootSubtreeViewSize;
    } else {
        return rootSubtreeView ? [rootSubtreeView frame].size : NSZeroSize;
    }
}

- (BOOL)needsGraphLayout {
    return [[self rootSubtreeView] needsGraphLayout];
}

- (void)setNeedsGraphLayout {
    [[self rootSubtreeView] recursiveSetNeedsGraphLayout];
    [self setNeedsDisplay:YES];
}

- (void)collapseRoot {
    [[self rootSubtreeView] setExpanded:NO];
}

- (void)expandRoot {
    [[self rootSubtreeView] setExpanded:YES];
}

- (IBAction)toggleExpansionOfSelectedModelNodes:(id)sender {
    for (id<TreeViewModelNode> modelNode in [self selectedModelNodes]) {
        SubtreeView *subtreeView = [self subtreeViewForModelNode:modelNode];
        [subtreeView toggleExpansion:sender];
    }
}

- (NSRect)boundsOfModelNodes:(NSSet *)modelNodes {
    NSRect boundingBox = NSZeroRect;
    for (id<TreeViewModelNode> modelNode in modelNodes) {
        SubtreeView *subtreeView = [self subtreeViewForModelNode:modelNode];
        if (subtreeView && [subtreeView isExpanded]) {
            NSView *nodeView = [subtreeView nodeView];
            if (nodeView) {
                NSRect rect = [self convertRect:[nodeView bounds] fromView:nodeView];
                boundingBox = NSUnionRect(boundingBox, rect);
            }
        }
    }
    return boundingBox;
}


#pragma mark *** Scrolling ***

- (void)scrollModelNodesToVisible:(NSSet *)modelNodes {
    NSRect targetRect = [self boundsOfModelNodes:modelNodes];
    if (!NSIsEmptyRect(targetRect)) {
        CGFloat padding = [self contentMargin];
        [self scrollRectToVisible:NSInsetRect(targetRect, -padding, -padding)];
    }
}

- (void)scrollSelectedModelNodesToVisible {
    [self scrollModelNodesToVisible:[self selectedModelNodes]];
}


#pragma mark *** Drawing ***

/* TreeView always completely fills its bounds with its backgroundColor, so as long as the TreeView's backgroundColor is opaque, the TreeView can be considered opaque.  Returning YES from this method is usually an easy, high-reward optimization in window-backed mode, as it enables AppKit to skip drawing content behind the view that the view would just paint over.
*/
- (BOOL)isOpaque {
    return ([[self backgroundColor] alphaComponent] < 1.0) ? NO : YES;
}

- (void)drawRect:(NSRect)rect {
    // Fill background.
    [[self backgroundColor] set];
    NSRectFill(rect);
}


#pragma mark *** Data Source ***

- (id<TreeViewModelNode>)modelRoot {
    return modelRoot;
}

- (void)setModelRoot:(id<TreeViewModelNode>)newModelRoot {
    NSParameterAssert(newModelRoot == nil || [newModelRoot conformsToProtocol:@protocol(TreeViewModelNode)]);
    if (modelRoot != newModelRoot) {
        SubtreeView *rootSubtreeView = [self rootSubtreeView];
        [rootSubtreeView removeFromSuperview];
        [modelNodeToSubtreeViewMapTable removeAllObjects];

        // Discard any previous selection.
        [self setSelectedModelNodes:[NSSet set]];

        // Switch to new modelRoot.
        modelRoot = newModelRoot;

        // Discard and reload content.
        [self buildGraph];
        [self setNeedsDisplay:YES];

        // Start with modelRoot selected.
        if (modelRoot) {
            [self setSelectedModelNodes:[NSSet setWithObject:modelRoot]];
            [self scrollSelectedModelNodesToVisible];
        }
    }
}


#pragma mark *** Node Hit-Testing ***

/* Returns the model node under the given point, which must be expressed in the TreeView's interior (bounds) coordinate space.  If there is a collapsed subtree at the given point, returns the model node at the root of the collapsed subtree.  If there is no model node at the given point, returns nil.
*/
- (id<TreeViewModelNode>)modelNodeAtPoint:(NSPoint)p {

    // Since we've composed our content using views (SubtreeViews and enclosed nodeViews), we can use NSView's -hitTest: method to easily identify our deepest descendant view under the given point.  We rely on the front-to-back order of hit-testing to ensure that we return the root of a collapsed subtree, instead of one of its descendant nodes.  (To do this, we must make sure, when collapsing a subtree, to keep the SubtreeView's nodeView frontmost among its siblings.)
    SubtreeView *rootSubtreeView = [self rootSubtreeView];
    NSPoint subviewPoint = [self convertPoint:p toView:rootSubtreeView];
    id<TreeViewModelNode> hitModelNode = [[self rootSubtreeView] modelNodeAtPoint:subviewPoint];

    return hitModelNode;
}


#pragma mark *** Key Event Handling ***

/* Make TreeViews able to -becomeFirstResponder, so they can receive key events.
*/
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)moveToSiblingByRelativeIndex:(NSInteger)relativeIndex {
    id<TreeViewModelNode> modelNode = [self singleSelectedModelNode];
    if (modelNode) {
        id<TreeViewModelNode> sibling = [self siblingOfModelNode:modelNode atRelativeIndex:relativeIndex];
        if (sibling) {
            [self setSelectedModelNodes:[NSSet setWithObject:sibling]];
        }
    } else if ([[self selectedModelNodes] count] == 0) {
        // If nothing selected, select root.
        [self setSelectedModelNodes:([self modelRoot] ? [NSSet setWithObject:[self modelRoot]] : nil)];
    }

    // Scroll new selection to visible.
    [self scrollSelectedModelNodesToVisible];
}

- (void)moveToParent:(id)sender {
    id<TreeViewModelNode> modelNode = [self singleSelectedModelNode];
    if (modelNode) {
        if (modelNode != [self modelRoot]) {
            id<TreeViewModelNode> parent = [modelNode parentModelNode];
            if (parent) {
                [self setSelectedModelNodes:[NSSet setWithObject:parent]];
            }
        }
    } else if ([[self selectedModelNodes] count] == 0) {
        // If nothing selected, select root.
        [self setSelectedModelNodes:([self modelRoot] ? [NSSet setWithObject:[self modelRoot]] : nil)];
    }

    // Scroll new selection to visible.
    [self scrollSelectedModelNodesToVisible];
}

- (void)moveToNearestChild:(id)sender {
    id<TreeViewModelNode> modelNode = [self singleSelectedModelNode];
    if (modelNode) {
        SubtreeView *subtreeView = [self subtreeViewForModelNode:modelNode];
        if (subtreeView && [subtreeView isExpanded]) {
            NSView *nodeView = [subtreeView nodeView];
            if (nodeView) {
                NSRect nodeViewFrame = [nodeView frame];
                id<TreeViewModelNode> nearestChild = [subtreeView modelNodeClosestToY:NSMidY(nodeViewFrame)];
                if (nearestChild) {
                    [self setSelectedModelNodes:[NSSet setWithObject:nearestChild]];
                }
            }
        }
    } else if ([[self selectedModelNodes] count] == 0) {
        // If nothing selected, select root.
        [self setSelectedModelNodes:([self modelRoot] ? [NSSet setWithObject:[self modelRoot]] : nil)];
    }

    // Scroll new selection to visible.
    [self scrollSelectedModelNodesToVisible];
}

- (void)moveUp:(id)sender {
    [self moveToSiblingByRelativeIndex:-1];
}

- (void)moveDown:(id)sender {
    [self moveToSiblingByRelativeIndex:1];
}

- (void)moveLeft:(id)sender {
    [self moveToParent:sender];
}

- (void)moveRight:(id)sender {
    [self moveToNearestChild:sender];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent characters];
    if (characters && [characters length] > 0) {
        switch ([characters characterAtIndex:0]) {
            case ' ':
                [self toggleExpansionOfSelectedModelNodes:self];
                break;

            default:
                [super keyDown:theEvent];
                break;
        }
    }
}


#pragma mark *** Mouse Event Handling ***

/* Always receive -mouseDown: messages for clicks that occur in a TreeView, even if the click is one that's activating the window.  This lets the user start interacting with the TreeView's contents without having to click again.
*/
- (BOOL)acceptsFirstMouse {
    return YES;
}

/* User clicked the main mouse button inside the TreeView.
*/
- (void)mouseDown:(NSEvent *)theEvent {

    // Identify the mdoel node (if any) that the user clicked, and make it the new selection.
    NSPoint viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    id<TreeViewModelNode> hitModelNode = [self modelNodeAtPoint:viewPoint];
    [self setSelectedModelNodes:(hitModelNode ? [NSSet setWithObject:hitModelNode] : [NSSet set])];

    // Make the TreeView the window's firstResponder when clicked.
    [[self window] makeFirstResponder:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    // For debugging: Dump a compact description of the tree.
    if (modelRoot) {
        SubtreeView *rootSubtreeView = [self rootSubtreeView];
        NSLog(@"Tree=\n%@", [rootSubtreeView treeSummaryWithDepth:0]);
    }
}


#pragma mark *** Gesture Event Handling ***

- (void)beginGestureWithEvent:(NSEvent *)event {
    // Temporarily suspend layout animations during handling of a gesture sequence.
    [self setLayoutAnimationSuppressed:YES];
}

- (void)endGestureWithEvent:(NSEvent *)event {
    // Re-enable layout animations at the end of a gesture sequence.
    [self setLayoutAnimationSuppressed:NO];
}

- (void)magnifyWithEvent:(NSEvent *)event {
    CGFloat spacing = [self parentChildSpacing];
    spacing = spacing * (1.0 + [event magnification]);
    [self setParentChildSpacing:spacing];
}

- (void)swipeWithEvent:(NSEvent *)event {
    // Expand or collapse the entire tree according to the direction of the swipe.  (An alternative behavior might be to identify node under mouse, and collapse/expand that instead of root node.)
    CGFloat deltaX = [event deltaX];
    if (deltaX < 0.0) {
        // Swipe was to the right.
        [self expandRoot];
    } else if (deltaX > 0.0) {
        // Swipe was to the left.
        [self collapseRoot];
    }
}


#pragma mark *** Making Style Properties Animatable Using "animator" Syntax ***

+ (id)defaultAnimationForKey:(NSString *)key {
    static NSSet *animatablePropertyKeys = nil;
    if (animatablePropertyKeys == nil) {
        animatablePropertyKeys = [[NSSet alloc] initWithObjects:@"parentChildSpacing", @"siblingSpacing", @"backgroundColor", @"connectingLineColor", @"connectingLineWidth", nil];
    }
    if ([animatablePropertyKeys containsObject:key]) {
        // If the key names one of our appearance properties that we want to make animatable using the "animator" proxy syntax, return a default animation specification.  Note that, in order for this to work, the setter methods for these properties *must* mark affected view areas as needing display.
        return [CABasicAnimation animation];
    } else {
        // For keys you don't handle, always delegate up to super.
        return [super defaultAnimationForKey:key];
    }
}


#pragma mark *** Styling ***

/* Getters and setters for TreeView's appearance-related properties: colors, metrics, etc.  We could almost auto-generate these using "@synthesize", but we want each setter to automatically mark the affected parts of the TreeView (and/or the descendant views that it's responsible for) as needing drawing to reflet the appearance change.  In other respects, these are unremarkable accessor methods that follow standard accessor conventions.
*/

- (NSColor *)backgroundColor {
    return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)newBackgroundColor {
    if (backgroundColor != newBackgroundColor) {
        [backgroundColor release];
        backgroundColor = [newBackgroundColor copy];

        CALayer *layer = [self layer];
        if (layer) {
            [layer setBackgroundColor:TreeView_CGColorFromNSColor(backgroundColor)];
        } else {
            [self setNeedsDisplay:YES];
        }
    }
}

- (NSColor *)connectingLineColor {
    return connectingLineColor;
}

- (void)setConnectingLineColor:(NSColor *)newConnectingLineColor {
    if (connectingLineColor != newConnectingLineColor) {
        [connectingLineColor release];
        connectingLineColor = [newConnectingLineColor copy];
        [[self rootSubtreeView] recursiveSetConnectorsViewsNeedDisplay];
    }
}

- (CGFloat)contentMargin {
    return contentMargin;
}

- (void)setContentMargin:(CGFloat)newContentMargin {
    if (contentMargin != newContentMargin) {
        contentMargin = newContentMargin;
        [self setNeedsGraphLayout];
        [self displayIfNeeded];
    }
}

- (CGFloat)parentChildSpacing {
    return parentChildSpacing;
}

- (void)setParentChildSpacing:(CGFloat)newParentChildSpacing {
    if (parentChildSpacing != newParentChildSpacing) {
        parentChildSpacing = newParentChildSpacing;
        [self setNeedsGraphLayout];
        [self displayIfNeeded];
    }
}

- (CGFloat)siblingSpacing {
    return siblingSpacing;
}

- (void)setSiblingSpacing:(CGFloat)newSiblingSpacing {
    if (siblingSpacing != newSiblingSpacing) {
        siblingSpacing = newSiblingSpacing;
        [self setNeedsGraphLayout];
        [self displayIfNeeded];
    }
}

- (TreeViewConnectingLineStyle)connectingLineStyle {
    return connectingLineStyle;
}

- (void)setConnectingLineStyle:(TreeViewConnectingLineStyle)newConnectingLineStyle {
    if (connectingLineStyle != newConnectingLineStyle) {
        connectingLineStyle = newConnectingLineStyle;
        [[self rootSubtreeView] recursiveSetConnectorsViewsNeedDisplay];
    }
}

- (CGFloat)connectingLineWidth {
    return connectingLineWidth;
}

- (void)setConnectingLineWidth:(CGFloat)newConnectingLineWidth {
    if (connectingLineWidth != newConnectingLineWidth) {
        connectingLineWidth = newConnectingLineWidth;
        [[self rootSubtreeView] recursiveSetConnectorsViewsNeedDisplay];
    }
}

- (BOOL)showsSubtreeFrames {
    return showsSubtreeFrames;
}

- (void)setShowsSubtreeFrames:(BOOL)newShowsSubtreeFrames {
    if (showsSubtreeFrames != newShowsSubtreeFrames) {
        showsSubtreeFrames = newShowsSubtreeFrames;
        [[self rootSubtreeView] resursiveSetSubtreeBordersNeedDisplay];
    }
}


#pragma mark *** Deallocation ***

- (void)dealloc {
    [cachedNodeViewNib release];
    [nodeViewNibBundle release];
    [nodeViewNibName release];
    [selectedModelNodes release];
    [modelRoot release];
    [modelNodeToSubtreeViewMapTable release];
    [backgroundColor release];
    [super dealloc];
}

@end

@implementation TreeView (Internal)

#pragma mark *** ModelNode -> SubtreeView Relationship Management ***

- (SubtreeView *)subtreeViewForModelNode:(id)modelNode {
    return [modelNodeToSubtreeViewMapTable objectForKey:modelNode];
}

- (void)setSubtreeView:(SubtreeView *)subtreeView forModelNode:(id)modelNode {
    [modelNodeToSubtreeViewMapTable setObject:subtreeView forKey:modelNode];
}


#pragma mark *** Model Tree Navigation ***

- (BOOL)modelNode:(id<TreeViewModelNode>)modelNode isDescendantOf:(id<TreeViewModelNode>)possibleAncestor {
    NSParameterAssert(modelNode != nil);
    NSParameterAssert(possibleAncestor != nil);
    id<TreeViewModelNode> node = [modelNode parentModelNode];
    while (node != nil) {
        if (node == possibleAncestor) {
            return YES;
        }
        node = [node parentModelNode];
    }
    return NO;
}

- (BOOL)modelNodeIsInAssignedTree:(id<TreeViewModelNode>)modelNode {
    NSParameterAssert(modelNode != nil);
    id<TreeViewModelNode> root = [self modelRoot];
    return (modelNode == root || [self modelNode:modelNode isDescendantOf:root]) ? YES : NO;
}

- (id<TreeViewModelNode>)siblingOfModelNode:(id<TreeViewModelNode>)modelNode atRelativeIndex:(NSInteger)relativeIndex {
    NSParameterAssert(modelNode != nil);
    NSAssert([self modelNodeIsInAssignedTree:modelNode], @"modelNode is not in the tree");

    if (modelNode == [self modelRoot]) {
        // modelNode is modelRoot.  Disallow traversal to its siblings (if it has any).
        return nil;
    } else {
        // modelNode is a descendant of modelRoot.
        // Find modelNode's position in its parent node's array of children.
        id<TreeViewModelNode> parent = [modelNode parentModelNode];
        NSArray *siblings = [parent childModelNodes];
        if (siblings) {
            NSInteger index = [siblings indexOfObject:modelNode];
            if (index != NSNotFound) {
                index += relativeIndex;
                if (index >= 0 && index < [siblings count]) {
                    return [siblings objectAtIndex:index];
                }
            }
        }
        return nil;
    }
}

@end
