ImageBrowser
============

This sample demonstrates the ImageKit ImageBrowser in a basic Cocoa application. It uses Interface Builder to create a window an ImageBrowser and a zoom slider. This sample should present a reasonably complete correctly formed Cocoa application which can be used as a starting point for using the ImageBrowser in a Cocoa applications. 

Usual steps to use the ImageKit image browser in your application:

1) setup your nib file
    Add a custom view and set its class to IKImageBrowserView.
    Connect an IBOutlet from your controller to your image browser view 
    and connect the IKImageBrowserView's _datasource IBOutlet to your controller (if you want your controller to be the data source)

2) In the header of your controller, don't forget to include the Quartz header:

    #import <Quartz/Quartz.h>

3) create your own data source representation (here using a NSMutableArray). 

@interface MyController : NSWindowController 
{
    // my images to display and browse (ie my data source) 
    NSMutableArray *_myImages;

    // my browser (connected in the nib file)
    IButlet id _myImageView;
}

4) implement the required methods of the informal data source protocol (IKImageBrowserDataSource) :

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
{
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index
{
    return [_myImages objectAtIndex:index];
}


5)  The returned data source object must implement the 3 required methods 
from the IKImageBrowserItemProtocol informal protocol:

- (NSString *) imageUID;
- (NSString *) imageRepresentationType;
- (id) imageRepresentation;

- the id returned by imageUID MUST be different for each item displayed in the image-view. Moreover, the
image browser build it's own internal cache according to this UID. the imageUID can be for exemple the absolute 
path of an image existing on the filesystem or another UID based on your own data structures.

- "imageRepresentationType" return one of the following string constant depending of the client's choice of representation:

IKImageBrowserPathRepresentationType
IKImageBrowserNSImageRepresentationType
IKImageBrowserCGImageRepresentationType
IKImageBrowserNSDataRepresentationType
IKImageBrowserNSBitmapImageRepresentationType
IKImageBrowserQTMovieRepresentationType
	(see IKImageBrowserView.h for complete list)

- "imageRepresentation" return an object depending of the representation type:

a NSString for IKImageBrowserPathRepresentationType
a NSImage for IKImageBrowserNSImageRepresentationType
a CGImageRef for IKImageBrowserCGImageRepresentationType
...

Here is a sample code of a simple implementation of a data source item:

// the datasource object
@interface myItemObject : NSObject <IKImageBrowserItem>
{
	NSString *_path; 
}
@end

@implementation myItemObject

- (void) dealloc
{
    [_path release];
    [super dealloc];
}

- (NSString *) imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id) imageRepresentation
{
    return _path;
}

- (NSString *) imageUID
{
    return _path;
}

@end


6) Now to see your data displayed in your instance of the image browser view, you have to tell the browser to read your data using your IBOutlet connected to the browser and
invoke "reloadData" on it:

[_myImageView reloadData];

call reload data each time you want the image browser to reflect changes of your data source.

That's all for a very basic use. 
Then you may need to add a scroller or a scrollview and a slider to your interface
to let the user to scroll and zoom to browser his images. To do this
you will have to use some image browser public methods such as:

- (void) setZoomValue:(float) zoomValue;
- (void) setScroller:(NSScroller *) scroller; // if you choose to manage independent scroller instead of having a scrollview

===========================================================================
Changes from Previous Versions

1.2 - Upgraded for Mac OS X 10.6, fixed problematic nib file, now 64-bit clean, replaced deprecated APIs.
1.1 - Updated to the latest Leopard interfaces, minor adjustments according to the sample code guidelines.
1.0 - First version

===========================================================================
Copyright (C) 2006-2011 Apple Inc. All rights reserved.
