OpenCLOfflineCompilation
========================
 
ABOUT:
 
This sample demonstrates how developers can utilize the OpenCL offline compiler to transform their human-readable OpenCL source files into shippable bitcode. It includes an example Makefile that demonstrates how to invoke the compiler, and a self-contained OpenCL program that shows how to build a program from the generated bitcode. The sample covers the case of using bitcode on 64 and 32 bit CPU devices, as well as 32 bit GPU devices.
 
BUILDING:
 
Type 'make' in the sample directory to build the test executable, bitcode for 32 and 64 bit CPU devices, and bitcode for 32 bit GPU devices.

RUNNING:

Test usage is as follows:

./test -t cpu32|cpu64|gpu32 -i num -f kernel.bc

Where '-t' indicates the type of device you wish to target during execution and '-i' indicates the index of that devices. You designate the appropriate bitcode for this device using '-f' along with the path to the file.

For example, to execute against the first gpu in your system:
./test -t gpu32 -i 0 -f kernel.gpu32.bc

If you have two GPUs, and would prefer to target the second:
./test -t gpu32 -i 1 -f kernel.gpu32.bc

Or to test 32bit CPU bitcode:
arch -i386 ./test -t cpu32 -f kernel.cpu32.bc

Or 64bit CPU, presuming a 64bit machine:
./test -t cpu64 -f kernel.cpu64.bc
 
===========================================================================
BUILD REQUIREMENTS
 
Xcode 4, Mac OS X 10.7 Lion or later.
 
===========================================================================
RUNTIME REQUIREMENTS
 
Mac OS X 10.7 Lion or later.
 
===========================================================================
CHANGES FROM PREVIOUS VERSIONS
 
Version 1.0
- Initial Version
 
===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.