### SpecialPictureProtocol ###

ABOUT:

This sample includes a custom NSURLProtocol that creates jpeg images on the fly in memory 
so they can be displayed in a webView.  In addition sample demonstrates how to render an 
NSString into an NSImage and then convert the resulting NSImage into jpeg format.  Also 
this sample illustrates the recommended technique for sharing information between your 
webView's WebResourceLoadDelegate object and your custom NSURLProtocol object.

We subclass the abstract class NSURLProtocol which provides the basic
structure for performing protocol-specific loading of URL data.  Our concrete subclass
will add support for the 'special':// URL scheme.  We override the following methods:

+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest
This method must be overridden by all subclasses of NSURLProtocol and is called to
determine if a subclass can be used to load the requested URL.

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
This method gives a subclass the opportunity to modify an NSURLRequest before it
is asked to load it.  Subclasses are required to provide an implementation.  In 
our sample this method is overridden only as a formality and we simply return the 
argument.

- (void)startLoading
This is where we do most of our processing for our class.  We take the
requested string and render it into an image that we return as our response.

- (void)stopLoading
Called when the load needs to abort.  We don't do anything special here.


===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6 Snow Leopard or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Added a ReadMe
- Updated html file loading routine.
- Project updated for Xcode 4.
Version 1.0
- First release


===========================================================================
Copyright (C) 2006-2011, Apple Inc.