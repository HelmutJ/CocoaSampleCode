TreeView
========
WWDC 2010 Session 141, “Crafting Custom Cocoa Views”


Purpose
=======================================================
“TreeView” presents an example of a creating an entirely new custom view from scratch (by directly subclassing NSView).  Its implementation illustrates many of the considerations involved in creating a custom view, including issues of content layout, drawing, handling user interaction, providing Accessibility support, and optimizing for layer-backed operation.


Requirements
=======================================================
TreeView takes advantage of APIs that were introduced in Mac OS X 10.6, but requires OS X 10.8 or later.


Usage
=======================================================
On launch, TreeView.app shows a portion of the Objective-C class hierarchy (discovered programmatically using the Objective-C runtime's introspection APIs) as its example content.  You can specify a different class subtree to display by entering a new class name in the "Root Class" text field.

Clicking in the TreeView makes it the window's firstResponder, after which you can use the arrow keys to navigate the tree, and [spacebar] to toggle the expanded/collapsed state of the currently selected node.

Clicking the main (left) mouse button on a node makes it the TreeView's "selected" node, and causes it to appear highlighted.  The TreeView remains the window's firstResponder, but it interprets key events to act upon or change its current selection.  Clicking outside of a node clears the selection back to zero nodes selected.  Non-leaf nodes have a button that you can toggle to collapse or re-expand the subtree.

On hardware equipped with a multi-touch trackpad, the "pinch" gesture can be used to vary the spacing between nodes in the tree layout.  A three-finger swipe (or a two-finger swipe on a Magic Mouse) can be used to collapse or expand the entire tree.

Controls along the right side of the window can be used to configure the TreeView's behaviors and appearance properties, and to toggle between window-backed and layer-backed operation.


Implementation Features to Notice
=======================================================
TreeView's implementation makes noteworthy adaptations for layer-backed mode, that reduce backing store usage by using layer border, cornerRadius, and backgroundColor properties, together with the NSView layerContentsRedrawPolicy property added in 10.6, to delegate simple color fills and outline drawing to the GPU.  Search for "Optimizations for Layer-Backed Mode" to see how this is done.

TreeView uses the -viewWillDraw override point to deter tree layout to just before drawing.


Potential Future Improvements
=======================================================
TreeView's API design and implementaiton allow for its current selection to include more than one node.  Its mouse and key event handling could be extended to take advantage of this, and enable the user to select more than one node.

TreeView is currently geared toward display of static trees.  Support for editing trees would be intresting to add.

The highlighting mechanism for the current node is currently hardwired, and should be generalized to allow use of arbitrary nodeView types with arbitrary selection styles.

TreeView contains no special provisions for printing.  Drawing customizations for printed output could be useful.

An Interface Builder plugin that provided an inspector for TreeView would be nice to have.


Version History
=======================================================
1.0 - As demonstrated at WWDC 2010 Session 141.
1.1 - Added needed scaling of layer properties for UI scale factors > 1.0, pixel alignment of nodeViews and orthogonal connecting lines, and +defaultAnimationForKey: overrides.
1.2 - Added use of -flashScrollers to indicate the document view's new size when we resize it (when running on 10.7 and later).  Fixed a leak of nodeViewNib.  Set a reasonable minimum window size.  Upgraded project to Xcode 4.1.
1.3 - Upgraded to Xcode 4.3 and Mac OS X 10.7, fixed from deprecated API usage, plugged up 2 leaks.