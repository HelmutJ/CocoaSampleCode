### Deep Image Display ###

===========================================================================
DESCRIPTION:

The “Deep Image Display with Quartz” sample shows how to take advantage of specialized dithering to improve the appearance of “deep” images (i.e. greater than 8-bits per color channel) drawn using Quartz.

When a window’s color depth limit is set to 64-bit (RGBA 16-16-16-16), a specialized dither pattern is automatically applied to the window’s content as it is composited into the 8-bits per color channel frame buffer. This dithering minimizes the appearance of quantization artifacts on screen.

For comparison purposes, the sample application shows a color gradient image in two windows. The left image shows a deep version of the image drawn using the above technique while the right shows a “standard” (8-bits per color channel) version.

Using the technique demonstrated by the sample you can also display 32-bit "deep" formats like 10-10-10-2 RGBX (or 2-10-10-10 XRGB). However, 
  note that the image pipeline operates on 8-bpc, 16-bpc and floats, so when the 10-10-10-2 image is drawn into a deep window, it will eventually be 
  promoted-to/cached-as 16-bpc. The same is true for destination CG bitmap contexts. Therefore, for deep window backing stores, the preferred source 
  format is RGBA 16-16-16-16. 

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.7 SDK or greater

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.7 or greater

===========================================================================
PACKAGING LIST:

- DeepImageDisplayAppDelegate: this class illustrates the heart of the sample, i.e. setting window depth limits, and supplying window/view contents with 
    the deep and standard images.

- CustomView: the NSView subclass that draws the deep image content into the window backing store via -drawRect:.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version. 

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
