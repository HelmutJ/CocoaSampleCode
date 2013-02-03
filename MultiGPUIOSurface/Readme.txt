MultiGPUIOSurface

================================================================================
DESCRIPTION:

MutiGPUIOSurface shows how to create IOSurfaces and bind them to OpenGL textures 
for both reading and writing.  It demonstrates one way of passing IOSurfaces from 
one process to another via Mach RPC calls.  It also demonstrates the system's 
ability to track IOSurface changes across process and GPU boundaries.

This sample uses OpenGL 2.

To test, after building the integrated target "MultiGPUApps", first run the server 
application "MultiGPUServer" and then the client application "MultiGPUClient".

================================================================================
BUILD REQUIREMENTS:

Mac OS X 10.6 or later, Xcode 3.1 or later

================================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6 or later

================================================================================
PACKAGING LIST:

ClientController.h
ClientController.m
This class implements the controller object for the client application. It is 
responsible for looking up the server application, and responding to frame
rendering requests from the server.

ClientOpenGLView.h
ClientOpenGLView.m
This class implements the client specific subclass of NSOpenGLView. 
It handles the client side rendering, which calls into the GLUT-based
BluePony rendering code, substituting the contents of an IOSurface from
the server application instead of the OpenGL logo.

It also shows how to bind IOSurface objects to OpenGL textures.

ServerController.h
ServerController.m
This class implements the controller object for the server application. It is 
responsible for setting up public Mach port for the server and listening for
client applications to start up.  It also sends frame display update requests
to all clients after every frame update.

It is also responsible for creating the initial set of IOSurfaces used to send
rendered frames to the client applications.

ServerOpenGLView.h
ServerOpenGLView.m
This class implements the server specific subclass of NSOpenGLView. 
It handles the server side rendering, which calls into the GLUT-based
Atlantis rendering code to draw into an IOSurface using an FBO.  It
also performs local rendering of each frame for display purposes.

It also shows how to bind IOSurface objects to OpenGL textures, and
how to use those for rendering with FBOs.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- First public release.

================================================================================
Copyright (C) 2010~2011 Apple Inc. All rights reserved.