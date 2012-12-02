/*
    File: SubtreeView.m
Abstract: SubtreeView Implementation
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

#import "SubtreeView.h"
#import "SubtreeConnectorsView.h"
#import "TreeView.h"
#import "TreeViewColorConversion.h"
#import <QuartzCore/QuartzCore.h>

#define CENTER_COLLAPSED_SUBTREE_ROOT   1

static NSColor *subtreeBorderColor(void) {
    return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0];
}

static CGFloat subtreeBorderWidth(void) {
    return 2.0;
}

@implementation SubtreeView

- (NSString *)description {
    return [NSString stringWithFormat:@"SubtreeView<%@>", [modelNode description]];
}

- (NSString *)nodeSummary {
    return [NSString stringWithFormat:@"f=%@ %@", NSStringFromRect([nodeView frame]), [modelNode description]];
}

- (NSString *)treeSummaryWithDepth:(NSInteger)depth {
    NSEnumerator *subviewsEnumerator = [[self subviews] objectEnumerator];
    NSView *subview;
    NSMutableString *description = [NSMutableString string];
    NSInteger i;
    for (i = 0; i < depth; i++) {
        [description appendString:@"  "];
    }
    [description appendFormat:@"%@\n", [self nodeSummary]];
    while (subview = [subviewsEnumerator nextObject]) {
        if ([subview isKindOfClass:[SubtreeView class]]) {
            [description appendString:[(SubtreeView *)subview treeSummaryWithDepth:(depth + 1)]];
        }
    }
    return description;
}

@synthesize modelNode;
@synthesize nodeView;

- (BOOL)isLeaf {
    return [[[self modelNode] childModelNodes] count] == 0;
}

#pragma mark *** Instance Initialization ***

- initWithModelNode:(id<TreeViewModelNode>)newModelNode {
    NSParameterAssert(newModelNode);
    self = [super initWithFrame:NSMakeRect(10, 10, 100, 25)];
    if (self) {

        // Initialize ivars directly.  As a rule, it's best to avoid invoking accessors from an -init... method, since they may wrongly expect the instance to be fully formed.

        expanded = YES;
        needsGraphLayout = YES;

        // autoresizesSubviews defaults to YES.  We don't want autoresizing, which would interfere with the explicit layout we do, so we switch it off for SubtreeView instances.
        [self setAutoresizesSubviews:NO];

        modelNode = [newModelNode retain];
        connectorsView = [[SubtreeConnectorsView alloc] initWithFrame:NSZeroRect];
        if (connectorsView) {
            [connectorsView setAutoresizesSubviews:YES];
            [self addSubview:connectorsView];
        }
    }
    return self;
}

- (TreeView *)enclosingTreeView {
    NSView *ancestor = [self superview];
    while (ancestor) {
        if ([ancestor isKindOfClass:[TreeView class]]) {
            return (TreeView *)ancestor;
        }
        ancestor = [ancestor superview];
    }
    return nil;
}

#pragma mark *** Optimizations for Layer-Backed Mode ***

- (void)updateSubtreeBorder {
    CALayer *layer = [self layer];
    if (layer) {
        // Disable implicit animations during these layer property changes, to make them take effect immediately.
        BOOL actionsWereDisabled = [CATransaction disableActions];
        [CATransaction setDisableActions:YES];

        // If the enclosing TreeView has its "showsSubtreeFrames" debug feature enabled, configure the backing layer to draw its border programmatically.  This is much more efficient than allocating a backing store for each SubtreeView's backing layer, only to stroke a simple rectangle into that backing store.
        TreeView *treeView = [self enclosingTreeView];
        if ([treeView showsSubtreeFrames]) {
            [layer setBorderWidth:subtreeBorderWidth()];
            [layer setBorderColor:TreeView_CGColorFromNSColor(subtreeBorderColor())];
        } else {
            [layer setBorderWidth:0.0];
        }

        [CATransaction setDisableActions:actionsWereDisabled];
    }
}

- (void)setLayer:(CALayer *)newLayer {
    [super setLayer:newLayer];
    if (newLayer) {

        // A SubtreeView has nothing to draw (except its border, if TreeView's "showsSubtreeFrames" debug feature is enabled), so set its layerContentsRedrawPolicy to NSViewLayerContentsRedrawNever.  This ensures that its backing layer will never be marked as needing display, and therefore will never acquire a bitmap backing store that would contain no content.  This also gives AppKit permission to delegate animation of SubtreeView frameSize changes to Core Animation, which is better for performance.
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];

        // If the enclosing TreeView has its "showsSubtreeFrames" debug feature enabled, configure the backing layer to draw its border programmatically.  This is much more efficient than allocating a backing store for each SubtreeView's backing layer, only to stroke a simple rectangle into that backing store.
        [self updateSubtreeBorder];
    }
}

#pragma mark *** Layout ***

- (BOOL)needsGraphLayout {
    return needsGraphLayout;
}

- (void)setNeedsGraphLayout {
    needsGraphLayout = YES;
}

- (void)recursiveSetNeedsGraphLayout {
    [self setNeedsGraphLayout];
    for (NSView *subview in [self subviews]) {
        if ([subview isKindOfClass:[SubtreeView class]]) {
            [(SubtreeView *)subview recursiveSetNeedsGraphLayout];
        }
    }
}

- (NSSize)sizeNodeViewToFitContent {
    // TODO: Node size is hardwired for now, but the layout algorithm could accommodate variable-sized nodes if we implement size-to-fit for nodes.
    return [nodeView frame].size;
}

- (NSSize)layoutGraphIfNeeded {
    NSSize selfTargetSize;

    if (!needsGraphLayout)
        return [self frame].size;

    TreeView *treeView = [self enclosingTreeView];
    BOOL animateLayout = [treeView animatesLayout] && ![treeView layoutAnimationSuppressed];
    CGFloat parentChildSpacing = [treeView parentChildSpacing];
    CGFloat siblingSpacing = [treeView siblingSpacing];

    // Size this SubtreeView's nodeView to fit its content.  Our tree layout model assumes the assessment of a node's natural size is a function of intrinsic properties of the node, and isn't influenced by any other nodes or layout in the tree.
    NSSize rootNodeViewSize = [self sizeNodeViewToFitContent];

    if ([self isExpanded]) {

        // Recurse to lay out each of our child SubtreeViews (and their non-collapsed descendants in turn).  Knowing the sizes of our child SubtreeViews will tell us what size this SubtreeView needs to be to contain them (and our nodeView and connectorsView).
        NSArray *subviews = [self subviews];
        NSInteger count = [subviews count];
        NSInteger index;
        NSUInteger subtreeViewCount = 0;
        CGFloat maxWidth = 0.0;
        NSPoint nextSubtreeViewOrigin = NSMakePoint(rootNodeViewSize.width + parentChildSpacing, 0.0);

        // Since SubtreeView is unflipped, lay out our child SubtreeViews going upward from our bottom edge, from last to first.
        for (index = count - 1; index >= 0; index--) {
            NSView *subview = [subviews objectAtIndex:index];

            if ([subview isKindOfClass:[SubtreeView class]]) {
                ++subtreeViewCount;

                // Recursively layout the subtree, and obtain the SubtreeView's resultant size.
                NSSize subtreeViewSize = [(SubtreeView *)subview layoutGraphIfNeeded];

                // Position the SubtreeView.
                [(animateLayout ? [subview animator] : subview) setFrameOrigin:nextSubtreeViewOrigin];

                // Advance nextSubtreeViewOrigin for the next SubtreeView.
                nextSubtreeViewOrigin.y += subtreeViewSize.height + siblingSpacing;

                // Keep track of the widest SubtreeView width we encounter.
                if (maxWidth < subtreeViewSize.width) {
                    maxWidth = subtreeViewSize.width;
                }
            }
        }

        // Calculate the total height of all our SubtreeViews, including the vertical spacing between them.  We have N child SubtreeViews, but only (N-1) gaps between them, so subtract 1 increment of siblingSpacing that was added by the loop above.
        CGFloat totalHeight = nextSubtreeViewOrigin.y;
        if (subtreeViewCount > 0) {
            totalHeight -= siblingSpacing;
        }

        // Size self to contain our nodeView all our child SubtreeViews, and position our nodeView and connectorsView.
        if (subtreeViewCount > 0) {

            // Determine our width and height.
            selfTargetSize = NSMakeSize(rootNodeViewSize.width + parentChildSpacing + maxWidth, MAX(totalHeight, rootNodeViewSize.height));

            // Resize to our new width and height.
            [(animateLayout ? [self animator] : self) setFrameSize:selfTargetSize];

            // Position our nodeView vertically centered along the left edge of our new bounds.  Pixel-align its position to keep its rendering crisp.
            NSPoint nodeViewOrigin = NSMakePoint(0.0, 0.5 * (selfTargetSize.height - rootNodeViewSize.height));

            NSPoint windowPoint = [self convertPoint:nodeViewOrigin toView:nil];
            windowPoint.x = round(windowPoint.x);
            windowPoint.y = round(windowPoint.y);
            nodeViewOrigin = [self convertPoint:windowPoint fromView:nil];
            
            [(animateLayout ? [nodeView animator] : nodeView) setFrameOrigin:nodeViewOrigin];

            // Position and show our connectorsView.
            // TODO: Can shrink height a bit on top and bottom ends, since the connecting lines meet at the nodes' vertical centers
            [connectorsView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
            [(animateLayout ? [connectorsView animator] : connectorsView) setFrameSize:NSMakeSize(parentChildSpacing, selfTargetSize.height)];
            [(animateLayout ? [connectorsView animator] : connectorsView) setFrameOrigin:NSMakePoint(rootNodeViewSize.width, 0.0)];
            [connectorsView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
            [connectorsView setHidden:NO];
        } else {
            // No SubtreeViews; this is a leaf node.  Size self to exactly wrap nodeView, and hide connectorsView.
            selfTargetSize = rootNodeViewSize;
            [self setFrameSize:selfTargetSize];
            [nodeView setFrameOrigin:NSZeroPoint];
            [connectorsView setHidden:YES];
        }
    } else {
        // This node is collapsed.
        selfTargetSize = rootNodeViewSize;
        [(animateLayout ? [self animator] : self) setFrameSize:selfTargetSize];
        for (NSView *subview in [self subviews]) {
            if ([subview isKindOfClass:[SubtreeView class]]) {
                [(SubtreeView *)subview layoutGraphIfNeeded];
                [(animateLayout ? [subview animator] : subview) setFrameOrigin:NSZeroPoint];
            } else if (subview == connectorsView) {
                [connectorsView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
                [(animateLayout ? [connectorsView animator] : connectorsView) setFrameSize:NSZeroSize];
                [(animateLayout ? [connectorsView animator] : connectorsView) setFrameOrigin:NSMakePoint(0.0, 0.5 * selfTargetSize.height)];
                [connectorsView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
            } else if (subview == nodeView) {
                [(animateLayout ? [subview animator] : subview) setFrameSize:selfTargetSize];
                [(animateLayout ? [subview animator] : subview) setFrameOrigin:NSZeroPoint];
            }
        }
    }

    // Mark as having completed layout.
    needsGraphLayout = NO;

    // Return our new size.
    return selfTargetSize;
}

- (BOOL)isExpanded {
    return expanded;
}

- (void)setExpanded:(BOOL)flag {
    if (expanded != flag) {

        // Remember this SubtreeView's new state.
        expanded = flag;

        // Notify the TreeView we need layout.
        [[self enclosingTreeView] setNeedsGraphLayout];

        // Expand or collapse subtrees recursively.
        for (NSView *subview in [self subviews]) {
            if ([subview isKindOfClass:[SubtreeView class]]) {
                [(SubtreeView *)subview setExpanded:expanded];
            }
        }
    }
}

- (IBAction)toggleExpansion:(id)sender {
    [NSAnimationContext beginGrouping];
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration:1.0];
    }

    [self setExpanded:![self isExpanded]];

    [[self enclosingTreeView] layoutGraphIfNeeded];

    [NSAnimationContext endGrouping];
}

#pragma mark *** Drawing ***

- (void)drawRect:(NSRect)dirtyRect {

    // DEBUG: Stroke bounds if requested. In practice, SubtreeViews don't normally draw anything.
    if ([[self enclosingTreeView] showsSubtreeFrames]) {
        CGFloat strokeWidth = subtreeBorderWidth();
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect([self bounds], 0.5 * strokeWidth, 0.5 * strokeWidth)];
        [path setLineWidth:strokeWidth];
        [subtreeBorderColor() setStroke];
        [path stroke];
    }
}

#pragma mark *** Invalidation ***

- (void)recursiveSetConnectorsViewsNeedDisplay {

    // Mark this SubtreeView's connectorsView as needing display.
    [connectorsView setNeedsDisplay:YES];

    // Recurse for descendant SubtreeViews.
    NSArray *subviews = [self subviews];
    for (NSView *subview in subviews) {
        if ([subview isKindOfClass:[SubtreeView class]]) {
            [(SubtreeView *)subview recursiveSetConnectorsViewsNeedDisplay];
        }
    }
}

- (void)resursiveSetSubtreeBordersNeedDisplay {
    if ([self layer]) {
        // We only need this if layer-backed.  When we have a backing layer, we use the layer's "border" properties to draw the subtree debug border.
        [self updateSubtreeBorder];

        // Recurse for descendant SubtreeViews.
        NSArray *subviews = [self subviews];
        for (NSView *subview in subviews) {
            if ([subview isKindOfClass:[SubtreeView class]]) {
                [(SubtreeView *)subview updateSubtreeBorder];
            }
        }
    } else {
        [self setNeedsDisplay:YES];
    }
}


#pragma mark *** Selection State ***

- (BOOL)nodeIsSelected {
    return [[[self enclosingTreeView] selectedModelNodes] containsObject:[self modelNode]];
}

#pragma mark *** Node Hit-Testing ***

- (id<TreeViewModelNode>)modelNodeAtPoint:(NSPoint)p {
    // Check for intersection with our subviews, enumerating them in reverse order to get front-to-back ordering.  We could use NSView's -hitTest: method here, but we don't want to bother hit-testing deeper than the nodeView level.
    NSArray *subviews = [self subviews];
    NSInteger count = [subviews count];
    NSInteger index;
    for (index = count - 1; index >= 0; index--) {
        NSView *subview = [subviews objectAtIndex:index];
        NSRect subviewBounds = [subview bounds];
        NSPoint subviewPoint = [subview convertPoint:p fromView:self];
        if (NSPointInRect(subviewPoint, subviewBounds)) {
            if (subview == [self nodeView]) {
                return [self modelNode];
            } else if ([subview isKindOfClass:[SubtreeView class]]) {
                return [(SubtreeView *)subview modelNodeAtPoint:subviewPoint];
            } else {
                // Ignore subview. It's probably a SubtreeConnectorsView.
            }
        }
    }

    // We didn't find a hit.
    return nil;
}

- (id<TreeViewModelNode>)modelNodeClosestToY:(CGFloat)y {
    // Do a simple linear search of our subviews, ignoring non-SubtreeViews.  If performance was ever an issue for this code, we could take advantage of knowing the layout order of the nodes to do a sort of binary search.
    NSArray *subviews = [self subviews];
    SubtreeView *subtreeViewWithClosestNodeView = nil;
    CGFloat closestNodeViewDistance = MAXFLOAT;
    for (NSView *subview in subviews) {
        if ([subview isKindOfClass:[SubtreeView class]]) {
            NSView *childNodeView = [(SubtreeView *)subview nodeView];
            if (childNodeView) {
                NSRect rect = [self convertRect:[childNodeView bounds] fromView:childNodeView];
                CGFloat nodeViewDistance = fabs(y - NSMidY(rect));
                if (nodeViewDistance < closestNodeViewDistance) {
                    closestNodeViewDistance = nodeViewDistance;
                    subtreeViewWithClosestNodeView = (SubtreeView *)subview;
                }
            }
        }
    }
    return [subtreeViewWithClosestNodeView modelNode];
}

#pragma mark *** Cleanup ***

- (void)dealloc {
//    [nodeView release]; // not retained, since an IBOutlet
    [connectorsView release];
    [modelNode release];
    [super dealloc];
}

@end
