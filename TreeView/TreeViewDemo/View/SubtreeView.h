/*
    File: SubtreeView.h
Abstract: SubtreeView Interface
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

@class SubtreeConnectorsView;
@class TreeView;

/* A SubtreeView draws nothing itself (unless showsSubtreeFrames is set to YES for the enclosingTreeView), but provides a local coordinate frame and grouping mechanism for a graph subtree, and implements subtree layout.
*/
@interface SubtreeView : NSView
{
    // Model
    id<TreeViewModelNode> modelNode;        // the model node that nodeView represents

    // Views
    NSView *nodeView;                       // the subview of this SubtreeView that shows a representation of the modelNode
    SubtreeConnectorsView *connectorsView;  // the view that shows connections from nodeView to its child nodes

    // State
    BOOL expanded;                          // YES if this subtree is expanded to show its descendants; NO if it's been collapsed to show just its root node
    BOOL needsGraphLayout;                  // YES if this SubtreeView needs to position its child views and assess its size; NO if we're sure its layout is up to date
}

/* Initializes a SubtreeView with the associated modelNode.  This is SubtreeView's designated initializer.
*/
- initWithModelNode:(id<TreeViewModelNode>)newModelNode;

/* The root of the model subtree that this SubtreeView represents.
*/
@property(retain) id<TreeViewModelNode> modelNode;

/* The view that represents the modelNode.  Is a subview of SubtreeView, and may itself have descendant views.
*/
@property(assign) IBOutlet NSView *nodeView;

/* Link to the enclosing TreeView.  (The getter for this is a convenience method that ascends the view tree until it encounters a TreeView.)
*/
@property(readonly) TreeView *enclosingTreeView;

/* Whether the model node represented by this SubtreeView is a leaf node (one without child nodes).  This can be a useful property to bind user interface state to.  In the TreeView demo app, for example, we've bound the "isHidden" property of subtree expand/collapse buttons to this, so that expand/collapse buttons will only be shown for non-leaf nodes.
*/
@property(readonly,getter=isLeaf) BOOL leaf;


#pragma mark *** Selection State ***

/* Whether the node is part of the TreeView's current selection.  This can be a useful property to bind user interface state to.
*/
@property(readonly) BOOL nodeIsSelected;


#pragma mark *** Layout ***

/* Returns YES if this subtree needs relayout.
*/
- (BOOL)needsGraphLayout;

/* Marks this subtree as needing relayout.
*/
- (void)setNeedsGraphLayout;

/* Recursively marks this subtree, and all of its descendants, as needing relayout.
*/
- (void)recursiveSetNeedsGraphLayout;

/* Recursively performs graph layout, if this subtree is marked as needing it.
*/
- (NSSize)layoutGraphIfNeeded;

/* Resizes this subtree's nodeView to the minimum size required to hold its content, and returns the nodeView's new size.  (This currently does nothing, and is just stubbed out for future use.)
*/
- (NSSize)sizeNodeViewToFitContent;

/* Whether this subtree is currently shown as expanded.  If NO, the node's children have been collapsed into it.
*/
@property(getter=isExpanded) BOOL expanded;

/* Toggles expansion of this subtree.  This can be wired up as the action of a button or other user interface control.
*/
- (IBAction)toggleExpansion:(id)sender;


#pragma mark *** Invalidation ***

/* Marks all SubtreeConnectorsView instances in this subtree as needing display.
*/
- (void)recursiveSetConnectorsViewsNeedDisplay;

/* Marks all SubtreeView debug borders as needing display.
*/
- (void)resursiveSetSubtreeBordersNeedDisplay;


#pragma mark *** Node Hit-Testing ***

/* Returns the visible model node whose nodeView contains the given point "p", where "p" is specified in the SubtreeView's interior (bounds) coordinate space.  Returns nil if there is no node under the specified point.  When a subtree is collapsed, only its root nodeView is eligible for hit-testing.
*/
- (id<TreeViewModelNode>)modelNodeAtPoint:(NSPoint)p;

/* Returns the visible model node that is closest to the specified y coordinate, where "y" is specified in the SubtreeView's interior (bounds) coordinate space.
*/
- (id<TreeViewModelNode>)modelNodeClosestToY:(CGFloat)y;


#pragma mark *** Debugging ***

/* Returns an indented multi-line NSString summary of the displayed tree.  Provided as a debugging aid.
*/
- (NSString *)treeSummaryWithDepth:(NSInteger)depth;

@end
