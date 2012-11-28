ifdef BUILD_WITH_ATF
ATF = -framework ATF
USE_ATF = -DUSE_ATF
endif

SRCS = fft_execute.cpp fft_setup.cpp main.cpp fft_kernelstring.cpp
HEADERS = procs.h fft_internal.h fft_base_kernels.h clFFT.h
TARGET = test_clFFT
COMPILERFLAGS = -c -g -Wall -Werror -O3
CFLAGS = $(COMPILERFLAGS) ${RC_CFLAGS} ${USE_ATF}
CC = g++
LIBRARIES = -framework OpenCL -framework Accelerate -framework AppKit ${RC_CFLAGS} ${ATF}

OBJECTS = fft_execute.o fft_setup.o main.o fft_kernelstring.o
TARGETOBJECT =
all: $(TARGET)

$(OBJECTS): $(SRCS) $(HEADERS)
	$(CC) $(CFLAGS) $(SRCS)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $@ $(LIBRARIES)

clean:
	rm -f $(TARGET) $(OBJECTS)

.DEFAULT:
	@echo The target \"$@\" does not exist in Makefile.
