### OpenCL Histogram Example ###===========================================================================DESCRIPTION:This example demonstrates implementing histograms on the GPU.  
Approaches where the input image data is a buffer or an image (i.e. an 
image2d_t data type in CL) are implemented.  The input per-pixel data stored in
buffer or image can be a RGBA 8-bit/channel, RGBA half-float/channel or 
RGBA float/channel.

For RGBA 8-bit/channel image data, the histogram is computed for R, G and B
channels.  256-bins for each channel are created.  These 256-bins are stored
in a single histogram buffer.

For RGBA half-float and float image data, the histogram is computed for R, G 
and B channels.  257-bins for each channel are created.  These 257-bins are 
stored in a single histogram buffer.
Note that the .cl compute kernel file(s) are loaded and compiled atruntime.  The example source assumes that these files are in the same path as the built executable.For simplicity, this example is intended to be run from the command line.If run from within XCode, open the Run Log (Command-Shift-R) to see the output.  Alternatively, run the applications from within a Terminal.app session to launch from the command line.===========================================================================BUILD REQUIREMENTS:Mac OS X v10.6 or later===========================================================================RUNTIME REQUIREMENTS:Mac OS X v10.6 or later===========================================================================PACKAGING LIST:ReadMe.txt
gpu_histogram.c
gpu_histogram_buffer.cl
gpu_histogram_image.cl
histogram.xcodeproj===========================================================================CHANGES FROM PREVIOUS VERSIONS:Version 1.0- First version.===========================================================================Copyright (C) 2008 Apple Inc. All rights reserved.
