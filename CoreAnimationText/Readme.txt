Description:
This sample demonstrates using CAShapeLayers to layout and render vector text. For simplicity, this sample only lays out a single line of text and does not support all text attributes.

Advanced Text Features:
This sample does not support all rendering attributes, such as underlines or shadows, that are supported by higher level text services such as the drawing methods of NSAttributedString or NSLayoutManager or drawing directly with Core Text.
In some situations to render text correctly (such as vertically laid out text) some of the neccessary attributes are only available from a graphics context. Also some rendering features not used by this sample are not available in Core Text (such as paragraph style).
If you need these advanced rendering features, you can obtain them by subclassing NSLayoutManager and overriding -showPackedGlyphs:length:glyphRange:atPoint:font:color:printingAdjustment: to obtain the necessary layout information. This approach is not demonstrated in this sample.

Usage:
The Format menu and the Font Panel can be used to alter text attributes. The "Zoom to fit" checkbox can be used to enable or disable scaling that fits the text line to fill all available space. The splitter can be used to make additional space for the NSTextField.

The VectorTextLayer class implements the layout and rendering functionality used in this sample, with the VectorTextView providing a simple NSView wrapper for that layer. Descriptions of the important methods of VectorTextLayer follow.

-layout: This is the method that provides actual layout. It is responsible for ensuring that there are enough CAShapeLayers to display the glyphs generated from the text and uses a simple cache (the GlyphCache object) to ensure that glyph paths are reused to allow Core Animation to optimize rendering of its CAShapeLayers.

AttributesToStyle: This function converts attributes from a run of text into a style dictionary appropriate for use with a CALayer. This allows for quickly stamping the same style attributes upon a number of layers and in this sample is used to implement text fill and stroke parameters.

-layoutSublayers: This method is overridden to setup a sublayerTransform that moves the shape layers correctly to the upper left corner of the parent layer, and to scale them appropriately when zoomToFit is enabled.