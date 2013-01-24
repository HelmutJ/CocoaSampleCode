CALayerEssentials

This sample project demonstrates how to setup various Core Animation layer types that are shipped with Mac OS X 10.5. These layer types are CALayer, CAOpenGLLayer, CATextLayer, CAScrollLayer, CATiledLayer, QCCompositionLayer (provided by Quartz framework), and QTMovieLayer (provided by the QTKit framework). This sample is meant to demonstrate reasonably minimal requirements for setting up each of these layer types and defers exploration of the full capabilities of each.

AppController.h/m
This source file contains the setup code for each of the layer types as well as some minimal control methods that help to demonstrate the layer types. Note that layer backing is turned on in MainMenu.xib for each of the views rather than programatically via -setWantsLayer.

-setupCALayer:
This method demonstrates how to setup a basic CALayer with content provided by Quartz. For this sample, we use a delegate method implementing -drawLayer:inContext: to do the rendering rather than using the "contents" property to specify the layer contents or subclassing CALayer to override -drawInContext:.

-setupCAOpenGLLayer:
This method demonstrates how to setup a CAOpenGLLayer to provide OpenGL content for Core Animation. By necessity you must subclass CAOpenGLLayer to provide OpenGL content. See ExampleCAOpenGLLayer.h/m for more information on how this is done.

-setupCATextLayer:
This method demonstrates how to setup a CATextLayer to provide basic text rendering to a layer. This sample uses a plain NSString for the string contents, but the CATextLayer also supports using an NSAttributedString for rendering attributed text (Note: CFStringRef and CFAttributedStringRef are toll-free bridged to NSString/NSAttributedString and can be used here as well).

-setupCAScrollLayer:
This method demonstrates how to setup a CAScrollLayer to provide a view into another layer. In this case we use a standard CALayer for our content. See the -scroll* actions on the WindowController class to see how to scroll to particular content in a CAScrollLayer.

-setupCATiledLayer:
This method demonstrates how to setup a CATiledLayer to provide content that has multiple levels-of-detail. A CATiledLayer is also a good choice for a layer that has a lot of content (larger than is possible to display with a single CALayer). So that the layer can be sized independently of the view, we use another layer for the view and add the tiled layer as a sublayer.

-setupQCCompositionLayer:
This method demonstrates how to setup a QCCompositionLayer to play a QuartzComposer composition.

-setupQTMovieLayer:
This method demonstrates how to setup a QTMovieLayer to present a movie within a Core Animation layer tree.
