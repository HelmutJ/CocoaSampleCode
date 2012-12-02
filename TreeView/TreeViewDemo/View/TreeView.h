/*
    File: TreeView.h
Abstract: TreeView Interface
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

#import <Cocoa/Cocoa.h>
#import "TreeViewModelNode.h"


/* A TreeView's nodes may be connected by either "direct" or "orthogonal" lines.
*/
enum TreeViewConnectingLineStyle {
    TreeViewConnectingLineStyleDirect = 0,
    TreeViewConnectingLineStyleOrthogonal = 1
};
typedef NSInteger TreeViewConnectingLineStyle;


/* A TreeView recursively composes the tree it displays using SubtreeView instances.  SubtreeView is declared in SubtreeView.h.
*/
@class SubtreeView;


/* A TreeView displays a graphical tree of "nodes" connected by lines, and provides for basic interaction with the tree -- selection of nodes, keyboard navigation, and collapsing/expanding subtrees.  Each model node is represented by a "node view" that's loaded from a prototype .nib, which may be an arbitrarily complex subtree of views.
*/
@interface TreeView : NSView
{
    // Model
    id<TreeViewModelNode> modelRoot;

    // Model Object -> SubtreeView Mapping
    NSMapTable *modelNodeToSubtreeViewMapTable;

    // Node View Nib Specification
    NSString *nodeViewNibName;
    NSBundle *nodeViewNibBundle;
    NSNib *cachedNodeViewNib;

    // Selection State
    NSMutableSet *selectedModelNodes;

    // Layout State
    NSSize minimumFrameSize;

    // Animation Support
    BOOL animatesLayout;
    BOOL layoutAnimationSuppressed;

    // Layout Metrics
    CGFloat contentMargin;
    CGFloat parentChildSpacing;
    CGFloat siblingSpacing;

    // Layout Behavior
    BOOL resizesToFillEnclosingScrollView;

    // Styling
    NSColor *backgroundColor;

    NSColor *connectingLineColor;
    CGFloat connectingLineWidth;
    TreeViewConnectingLineStyle connectingLineStyle;

    BOOL showsSubtreeFrames;
}


#pragma mark *** Creating Instances ***

/* Initializes a new TreeView instance.  (TreeView's designated initializer is the same as NSView's: -initWithFrame:.)  The TreeView has default appearance properties and layout metrics, but to have a usable TreeView with actual content, you need to specify a nodeViewNibName, an optional nodeViewNibBundle, and a modelRoot.
*/
- (id)initWithFrame:(NSRect)frame;


#pragma mark *** Connection to Model ***

/* The root of the model node tree that the TreeView is being asked to display.  (The modelRoot may have ancestor nodes, but TreeView will ignore them and treat modelRoot as the root.)  May be set to nil, in which case the TreeView displays no content.  The modelRoot object, and all of its desdendants as discovered through recursive application of the "-childModelNodes" accessor to traverse the model tree, must conform to the TreeViewModelNode protocol declared in TreeViewModelNode.h
*/
@property(retain) id<TreeViewModelNode> modelRoot;


#pragma mark *** Root SubtreeView Access ***

/* A TreeView builds the tree it displays using recursively nested SubtreeView instances.  This read-only accessor provides a way to get the rootmost SubtreeView (the one that corresponds to the modelRoot model node).
*/
@property(readonly) SubtreeView *rootSubtreeView;


#pragma mark *** Node View Nib Specification ***

/* The name of the .nib file from which to instantiate node views.  (This API design assumes that all node views should be instantiated from the same .nib.  If a tree of heterogeneous nodes was desired, we could switch to a different mechanism for identifying the .nib to instantiate.)  Must specify a "View" .nib file, whose File's Owner is a SubtreeView, or the TreeView will be unable to instantiate node views.
*/
@property(copy) NSString *nodeViewNibName;

/* The NSBundle from which the .nib named by nodeViewNibName can be loaded.  May be nil, in which case we follow the usual AppKit-implemented rules for automatically finding the named .nib file.
*/
@property(retain) NSBundle *nodeViewNibBundle;


#pragma mark *** Selection State ***

/* The unordered set of model nodes that are currently selected in the TreeView.  When no nodes are selected, this is an empty NSSet.  It will never be nil (and attempting to set it to nil will raise an exception).  Every member of this set must be a descendant of the TreeView's modelRoot (or modelRoot itself).  If any member is not, TreeView will raise an exception.
*/
@property(copy) NSSet *selectedModelNodes;

/* Convenience accessor that returns the selected node, if exactly one node is currently selected.  Returns nil if zero, or more than one, nodes are currently selected.
*/
@property(readonly) id<TreeViewModelNode> singleSelectedModelNode;

/* Returns the bounding box of the selectedModelNodes.  The bounding box takes only the selected nodes into account, disregarding any descendants they might have.
*/
@property(readonly) NSRect selectionBounds;


#pragma mark *** Node Hit-Testing ***

/* Returns the model node under the given point, which must be expressed in the TreeView's interior (bounds) coordinate space.  If there is a collapsed subtree at the given point, returns the model node at the root of the collapsed subtree.  If there is no model node at the given point, returns nil.
*/
- (id<TreeViewModelNode>)modelNodeAtPoint:(NSPoint)p;


#pragma mark *** Sizing and Layout ***

/* A TreeView's minimumFrameSize is the size needed to accommodate its content (as currently laid out) and margins.  Changes to the TreeView's content, layout, or margins will update this.  When a TreeView is the documentView of an NSScrollView, its actual frame may be larger than its minimumFrameSize, since we automatically expand the TreeView to always be at least as large as the NSScrollView's clip area (contentView) to provide a nicer user experience.
*/
@property NSSize minimumFrameSize;

/* If YES, and if the TreeView is the documentView of an NSScrollView, the TreeView will automatically resize itself as needed to ensure that it always at least fills the content area of its enclosing NSScrollView.  If NO, or if the TreeView is not the documentView of an NSScrollView, the TreeView's size is determined only by its content and margins.
*/
@property BOOL resizesToFillEnclosingScrollView;

/* Returns YES if the tree needs relayout.
*/
- (BOOL)needsGraphLayout;

/* Marks the tree as needing relayout.
*/
- (void)setNeedsGraphLayout;

/* Performs graph layout, if the tree is marked as needing it.  Returns the size computed for the tree (not including contentMargin).
*/
- (NSSize)layoutGraphIfNeeded;

/* Collapses the root node, if it is currently expanded.
*/
- (void)collapseRoot;

/* Expands the root node, if it is currently collapsed.
*/
- (void)expandRoot;

/* Toggles the expansion state of the TreeView's selectedModelNodes, expanding those that are currently collapsed, and collapsing those that are currently expanded.
*/
- (IBAction)toggleExpansionOfSelectedModelNodes:(id)sender;

/* Returns the bounding box of the node views that represent the specified modelNodes.  Model nodes that aren't part of the displayed tree, or are part of a collapsed subtree, are ignored and don't contribute to the returned bounding box.  The bounding box takes only the specified nodes into account, disregarding any descendants they might have.
*/
- (NSRect)boundsOfModelNodes:(NSSet *)modelNodes;


#pragma mark *** Scrolling ***

/* Does a [self scrollRectToVisible:] with the bounding box of the specified model nodes.
*/
- (void)scrollModelNodesToVisible:(NSSet *)modelNodes;

/* Does a [self scrollRectToVisible:] with the bounding box of the selected model nodes.
*/
- (void)scrollSelectedModelNodesToVisible;


#pragma mark *** Animation Support ***

/* Whether the TreeView animates layout operations.  Defaults to YES.  If set to NO, layout jumpst instantaneously to the tree's new state.
*/
@property BOOL animatesLayout;

/* Used to temporarily suppress layout animation during event tracking.  Layout animation happens only if animatesLayout is YES and this is NO.
*/
@property BOOL layoutAnimationSuppressed;


#pragma mark *** Layout Metrics ***

/* The amount of padding to leave between the displayed tree and each of the four edges of the TreeView's bounds.
*/
@property CGFloat contentMargin;

/* The horizonal spacing between each parent node and its child nodes.
*/
@property CGFloat parentChildSpacing;

/* The vertical spacing betwen sibling nodes.
*/
@property CGFloat siblingSpacing;


#pragma mark *** Styling ***

/* The fill color for the TreeView's content area.
*/
@property(copy) NSColor *backgroundColor;

/* The stroke color for node connecting lines.
*/
@property(copy) NSColor *connectingLineColor;

/* The width for node connecting lines.
*/
@property CGFloat connectingLineWidth;

/* The style for node connecting lines.  (See the TreeViewConnectingLineStyle enumeration above.)
*/
@property TreeViewConnectingLineStyle connectingLineStyle;

/* Defaults to NO.  If YES, a stroked outline is shown around each of the TreeView's SubtreeViews.  This can be helpful for visualizing the TreeView's structure and layout.
*/
@property BOOL showsSubtreeFrames;


@end


