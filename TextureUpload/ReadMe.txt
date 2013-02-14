TextureUpload

===========================================================================
DESCRIPTION:

This sample code demonstrates the fundamental techniques to obtain optimal 
texture upload performance. There are two levels of optimizations here:

- The Apple Client Storage extension allows you to eliminate a texture copy 
at the client. 

- When working with non-power-of-two texture target (GL_TEXTURE_RECTANGLE_EXT), 
you may use the Rectangle Texture extension and the Apple Texture Range 
extension to further optimize texture upload performance.

Note, the first level of optimization applies to both GL_TEXTURE_2D and 
GL_TEXTURE_RECTANGLE_EXT targets; the second level of optimization applies to 
the GL_TEXTURE_RECTANGLE_EXT target only.

See the OpenGL Programming Guide for Mac OS X for more information, in 
particular, the chapter of "Best Practices for Working with Texture Data".

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6 or later, Xcode 3.1 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.6 or later

===========================================================================
PACKAGING LIST:

MyOpenGLView.h
MyOpenGLView.m

The MyOpenGLView class is an NSOpenGLView subclass, which defines the view 
object that handles 3D OpenGL drawing.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.