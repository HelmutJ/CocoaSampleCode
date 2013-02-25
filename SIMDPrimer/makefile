#------------------------------------------------------------------------------
# Define default target.
target:  test time
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# Set desired flags.

# Set architectures to build for.
ARCHS = i386 ppc x86_64

# Set architecture to run on.
#RUN_ARCH = i386

# Set flags for C compilations.
CFLAGS = -Wmost -Werror -pedantic -O3 -std=c99 -g \
	-Xarch_ppc -maltivec
# Note:
#    To use AltiVec features in C, we need to specify the -maltivec switch to
#    GCC.  In GCC 4.2, the -Xarch_ppc switch allows us to tell GCC to use a
#    switch only when compiling for ppc.  Earlier versions of GCC do not have
#    this switch and will fail when -maltivec is used in a command that
#    compiles for non-PowerPC architectures.  To build using older versions of
#    GCC, it is necessary to build separate object modules for each
#    architecture and use the lipo command to combine them.  Xcode does this
#    automatically.  It can be done in make files, but the necessary rules are
#    not included here.

# Add -arch switch(es) to compile and link commands, to build for selected
# architectures.
TARGET_ARCH = $(patsubst %, -arch %, $(ARCHS))
CFLAGS  += $(TARGET_ARCH)
LDFLAGS += $(TARGET_ARCH)

#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# Define things for make and the build environment.

# List phony targets that do not build files.
.PHONY: target test time clean

# Clean up by removing files made by build.
clean:
	@echo
	@echo "#-- Removing recreatable files at `date +%T`. --"
	rm -f *.exe *.o

# Define how to run an executable file.
Run%:	%
	@echo
	@echo "#-- Executing $< at `date +%T`. --"
ifdef RUN_ARCH
	arch -arch $(RUN_ARCH) ./$<
else
	./$<
endif

# Define compile command.  This is the same as the built-in make command except
# we had some annotation to the output with echo.
%.o:	%.c
	@echo
	@echo "#-- Compiling $< to $@ at `date +%T`. --"
	$(COMPILE.c) $(OUTPUT_OPTION) $<

# Define link command.  This is the same as the built-in make command except we
# had some annotation to the output with echo and we use a ".exe" suffix to
# make it easy to distinguish executable files for clean-up.
%.exe:	%.o
	@echo
	@echo "#-- Linking to $@ at `date +%T`. --"
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) $(OUTPUT_OPTION)

#------------------------------------------------------------------------------





#------------------------------------------------------------------------------
# Define build dependencies.

vAdd.o:             vAdd.c vAdd.h vector.h

ClockServices.o:    ClockServices.c ClockServices.h

Test.o:             Test.c vAdd.h
Time.o:             Time.c vAdd.h ClockServices.h

Test.exe:           Test.o vAdd.o
Time.exe:           Time.o vAdd.o ClockServices.o

test:               RunTest.exe
time:               RunTime.exe

#------------------------------------------------------------------------------
