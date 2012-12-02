/*
    File: TreeView_Internal.h
Abstract: TreeView Internal Method Declarations
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

@class SubtreeView;

/* This category declares "Internal" methods that make up part of TreeView's implementation, but aren't intended to be used as TreeView API.
*/
@interface TreeView (Internal)

#pragma mark *** ModelNode -> SubtreeView Relationship Management ***

/* Returns the SubtreeView that corresponds to the specified modelNode, as tracked by the TreeView's modelNodeToSubtreeViewMapTable.
*/
- (SubtreeView *)subtreeViewForModelNode:(id)modelNode;

/* Associates the specified subtreeView with the given modelNode in the TreeView's modelNodeToSubtreeViewMapTable, so that it can later be looked up using -subtreeViewForModelNode:.
*/
- (void)setSubtreeView:(SubtreeView *)subtreeView forModelNode:(id)modelNode;


#pragma mark *** Model Tree Navigation ***

/* Returns YES if modelNode is a descendant of possibleAncestor, NO if not.  Raises an exception if either modelNode or possibleAncestor is nil.
*/
- (BOOL)modelNode:(id<TreeViewModelNode>)modelNode isDescendantOf:(id<TreeViewModelNode>)possibleAncestor;

/* Returns YES if modelNode is the TreeView's assigned modelRoot, or a descendant of modelRoot.  Returns NO if not.  TreeView uses this determination to avoid traversing nodes above its assigned modelRoot (if there are any).  Raises an exception if modelNode is nil.
*/
- (BOOL)modelNodeIsInAssignedTree:(id<TreeViewModelNode>)modelNode;

/* Returns the sibling at the given offset relative to the given modelNode.  (e.g. relativeIndex == -1 requests the previous sibling.  relativeIndex == +1 requests the next sibling.)  Returns nil if the modelNode has no sibling at the specified relativeIndex (resultant index out of bounds).  This method won't go above the subtree defined by the TreeView's modelRoot.  (That is: If the given modelNode is the TreeView's modelRoot, this method returns nil, even if the requested sibling exists.)  Raises an exception if modelNode is nil, or if modelNode is not within the subtree assigned to the TreeView.
*/
- (id<TreeViewModelNode>)siblingOfModelNode:(id<TreeViewModelNode>)modelNode atRelativeIndex:(NSInteger)relativeIndex;


#pragma mark *** Node View Nib Caching ***

/* Returns an NSNib instance created from the TreeView's nodeViewNibName and nodeViewNibBundle.  We automatically let go of the cachedNodeViewNib when either of these properties changes.  Keeping a cached NSNib instance helps speed up repeated instantiation of node views.
*/
@property(retain) NSNib *cachedNodeViewNib;

@end
