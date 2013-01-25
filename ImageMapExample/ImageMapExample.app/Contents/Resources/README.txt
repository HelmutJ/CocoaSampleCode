ImageMapExample
===============

DESCRIPTION:

ImageMapExample demonstrates how to support accessibility. Some of the more interesting issues it deals with are: 

- How to add descriptions to the segments of a segmented control.

- How to accessorize a custom class (in this case ImageMap a subclass of NSView).

- How to represent UI Elements for which there exist no underlying NSObjects (in this case, the hot spots of the ImageMap).


ABOUT:

* FauxUIElement

The FauxUIElement class is used to create temporay UIElements object for accessibility. This is needed when a widget contains children widgets that need to be accessible, but for which there is no corresponding object to use as a UIElement.

One example might be a scroll bar implemented as a single object, but which need to represent itself for accessibility purposes as a group of objects - up arrow button, down arrow button, thumb, page up button, page down button.

A FauxUIElement object only knows its parent and its role. Other information is determined by messaging the parent. The parent object must implement the FauxUIElementChildSupport protocol to support these messages.

Most of the time you will need to subclass FauxUIElement in order to provide some way for the parent to distinguish children with the same role. Consider the scrollbar example. Without additional information, there is no way to distinguish the up arrow from the down arrow - they both have the same parent and the same role.

Note: when you create a subclass of FauxUIElement it is important that the subclass override isEqual to utilize the additional information to distinguish objects.

*ImageMap

The ImageMap class provides an image and overlayed hot spots that can be clicked by the user. This is similar in functionality to HTML's client-side image maps.


Specifying Hot Spots

The hot spots can be specified in one of two ways; manually, using the various addHotSpotForXXX methods; or by using the map from an HTML file.

Using the second approach allows you to take advantage of (numerous) existing tools for creating client-side image maps. Note, the HTML must be XML compliant (e.g. all tags balanced).

Note: client-side image maps specify coordinates from the top-left corner of the image. Because of this, the ImageMap will use flipped coordinates (see NSView's isFlipped method) when its hot spots came from an HTML file. 

For convenience the image and hot spots can be set with a single call:

- (void)setImageAndHotSpotsFromImageAndImageMapNamed:(NSString *)name;

This requires the name of the image, the name of the HTML file, and the name of the map in the HTML file to all be the same. E.g. foo.tiff, foo.html, and <map name="foo">.

Each hot spot has an "info" object associated with it. If you specify the hot spots manually this can be any NSObject. If the hot spots came from an HTML file, the info will be a dictionary of the alt, href, and title attributes from the map's areas. The keys will be the NSStrings, @"alt", @"href", and @"title". The values will be the corresponding attribute values as NSStrings.


Responding to Clicks

ImageMap uses target/action a la NSControl. When a hot spot is clicked the action will be sent to the target with the image map passed as the sender. To determine which spot was clicked, call selectedHotSpotInfo on the image map to get the hot spot's info object.

The setHasDefault method controls whether or not the action is invoked when the user clicks on an area of the image not covered by a hot spot. The setDefaultInfo method control what info object is returned by selectedHotSpotInfo in this situation. By default, hasDefault is NO and defaultInfo is nil.


Display Options

The setRolloverHighlighting method controls whether or not hot spots highlight as the cursor passes over them.

The setHotSpotsVisible method controls whether or not the hot spots are always highlighted.

The setSelectedHotSpotColor, setRolloverHotSpotColor, and setHotSpotsVisibleColor methods control the colors used to created the various highlighting effects. The setHotSpotCompositeOperation method contols how these colors are composited to create the highlighting effect. The default composite is NSCompositePlusDarker, but if the image is dark, NSCompositePlusLighter will create more visible highlights.

===========================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later.

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.1
- Fixed some type casting issues.
- Project updated for Xcode 4.
Version 1.0
- Initial Version

===========================================================================
Copyright (C) 2005-2011 Apple Inc. All rights reserved.