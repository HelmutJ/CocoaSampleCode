DispatchFractal
===============

This example shows how to combine parallel computation on the CPU via GCD with
results processing and display on the GPU via OpenCL and OpenGL.

It computes escape-time fractals in parallel on the global concurrent GCD queue
and uses another GCD queue to upload results to the GPU for processing via two
OpenCL kernels. Calls to OpenCL and OpenGL for display are serialized with a
third GCD queue.

The fractal computation example (without the display) is also available as a
commandline  tool, with flags to control the computation parameters available
in the GUI (see usage message).


Build Requirements:
    - Mac OS X v10.6 or later
    - Xcode 3.2

Runtime Requirements:
    - Mac OS X v10.6 or later
    - OpenCL-compliant GPU, e.g.
        - NVIDIA GeForce 8600M, 8800 GS, 8800 GT, 9400M, 9600M GT
        - ATI Radeon HD 4870
    - GPUs known not to be supported yet by OpenCL:
        - ATI Radeon HD 2600 Pro, NVIDIA GeForce 7300 GT


Source file details:
--------------------

DispatchFractal.c:  Parallel fractal computation engine via recursive square
                    subdivision. The 'subdivisions' parameter controls how many
                    times the initial square is subdivided, and thus the
                    resolution of the final fractal (i.e. subdivisions = 10 ->
                    resolution 1024 * 1024).
                    Parallel computation is performed by enqueuing blocks onto
                    the global GCD queue. The 'stride' parameter controls how
                    many subdivision steps are performed in each block, once
                    that limit is reached, the next subdivision step enqueues
                    four new blocks. This allows control of the per-block
                    workload, note how performance decreases when stride is
                    very small (too many blocks being enqueued and dispatch
                    overhead larger than useful workload).
                    The computation results in one float value per square in
                    the subdivision, this is stored lock-free into a global
                    buffer as a quadtree (i.e. every subdivision square has a
                    distinct result location in the buffer).

DFFractals.c:       Computation blocks for the different fractals available.
                    Uses long double precision and -ffast-math. Roughly
                    estimates how many floating point operations are used for
                    fractal computation.

DFView.m:           OpenCL/OpenGL display of quadtree results buffer. During
                    fractal computation, a GCD queue asynchronously uploads the
                    results buffer to OpenCL and performs the 'quadtree' kernel
                    on it. The resulting OpenCL memory buffer is passed to a
                    separate GCD display queue, which performs the 'colorize'
                    kernel on it and copies the result to an OpenGL texture,
                    this is then drawn via VBO. The result of the 'quadtree'
                    kernel is double-buffered so that display can proceed
                    independently of results buffer upload and processing.
                    Display refresh rate can be controlled by CoreVideo
                    DisplayLink or by enabling vertical retrace sync (which
                    blocks the display queue in CGLFlushDrawable() until VBL),
                    otherwise the display is redrawn as fast as possible
                    (wasteful, only interesting for FPS measurement).
                    Also contains code to download the OpenGL texture from GPU
                    via CoreImage for image saving, and to interact with the
                    mouse and display a selection rectangle via an OpenGL
                    display list.

DispatchFractal.cl: OpenCL kernel sources. The 'quadtree' kernel assembles a
                    float buffer the size of the final texture. For every pixel
                    it traverses the quadtree results buffer from the bottom up
                    until a valid value is found.
                    The 'colorize' kernel transforms this float buffer into
                    BGRA8 color values. For every pixel it looks up a color in
                    a constant gradient buffer, according to a curve based on
                    the 'falloff' and 'cycle speed' parameters.

DFAppDelegate.m:    Interaction of the fractal computation and display engines
                    with the GUI controls. Image saving via ImageKit/ImageIO.

DispatchFractalCLI.c: Interaction of the fractal computation engine with the
                    command line.


Copyright (C) 2009 Apple Inc. All rights reserved.
