# File: Makefile
# 
# Abstract: 
# This Makefile demonstrates how to utilize the OpenCL C compiler to build
# bitcode from your CL kernels.  The compilation commands below show how
# to build bitcode for 32bit CPUs, 64bit CPUs, and 32bit GPUs.  This bitcode
# can then be fed to the OpenCL runtime to build an executable program,
# without every shipping user-readable CL source code.
# 
# The accompaning test program, wholly contained in the file main.c, provides
# an example of how to load and use bitcode using the OpenCL runtime on
# OSX Lion.
# 
# Version: 1.0
# 
# Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
# Apple Inc. ("Apple") in consideration of your agreement to the
# following terms, and your use, installation, modification or
# redistribution of this Apple software constitutes acceptance of these
# terms.  If you do not agree with these terms, please do not use,
# install, modify or redistribute this Apple software.
# 
# In consideration of your agreement to abide by the following terms, and
# subject to these terms, Apple grants you a personal, non-exclusive
# license, under Apple's copyrights in this original Apple software (the
# "Apple Software"), to use, reproduce, modify and redistribute the Apple
# Software, with or without modifications, in source and/or binary forms;
# provided that if you redistribute the Apple Software in its entirety and
# without modifications, you must retain this notice and the following
# text and disclaimers in all such redistributions of the Apple Software. 
# Neither the name, trademarks, service marks or logos of Apple Inc. 
# may be used to endorse or promote products derived from the Apple
# Software without specific prior written permission from Apple.  Except
# as expressly stated in this notice, no other rights or licenses, express
# or implied, are granted by Apple herein, including but not limited to
# any patent rights that may be infringed by your derivative works or by
# other works in which the Apple Software may be incorporated.
# 
# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
# 
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# Copyright (C) 2011 Apple Inc. All Rights Reserved.

TARGET=test

# #
# The OpenCL compiler, used to compile OpenCL kernels.
# #
CLC = /System/Library/Frameworks/OpenCL.framework/Libraries/openclc

CC = cc
ARCHS=-arch i386 -arch x86_64
CFLAGS = -c -Wall -g -O0
FRAMEWORKS = -framework OpenCL

SOURCES = main.c
CL_SOURCES = kernel.cl

# #
# For each OpenCL C source file, we want to build:
#
#   file.cpu32.bc, file.cpu64.bc, and file.gpu32.bc, where file is the 
#   source name preceding the .cl extension.
# #
BITCODE += ${CL_SOURCES:.cl=.cpu32.bc}
BITCODE += ${CL_SOURCES:.cl=.cpu64.bc}
BITCODE += ${CL_SOURCES:.cl=.gpu32.bc}

OBJECTS := ${SOURCES:.c=.o}

$(TARGET): $(BITCODE) $(OBJECTS)
	$(CC) $(OBJECTS) -o $@ $(FRAMEWORKS) $(ARCHS)

%.o: %.c
	$(CC) $(CFLAGS) $(ARCHS) $< -o $@

# #
# The OpenCL C compilation commands for 32/64bit CPUs and 32bit GPUs:
#
# As an example, to compile for a 32bit GPU:
# openclc -x cl -triple gpu_32-applecl-darwin -emit-llvm-bc kernel.cl -o kernel.bc
# #
%.cpu32.bc: %.cl
	$(CLC) -x cl -triple i386-applecl-darwin -emit-llvm-bc $< -o $@

%.cpu64.bc: %.cl
	$(CLC) -x cl -triple x86_64-applecl-darwin -emit-llvm-bc $< -o $@

%.gpu32.bc: %.cl
	$(CLC) -x cl -triple gpu_32-applecl-darwin -emit-llvm-bc $< -o $@

clean:
	rm -rf $(TARGET) $(BITCODE) $(OBJECTS)
