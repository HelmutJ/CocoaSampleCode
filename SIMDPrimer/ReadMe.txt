This directory contains sample code that illustrates using Single-Instruction
Multiple-Data (SIMD) features of a processsor.  To test and time the routine,
execute "make test" or "make time".

Files here are:

	vector.h.

		Declarations useful for SIMD programming.

	vAdd.h, vAdd.c.

		Declaration and implementation of the vAdd routine.  This is the
		primary subject of this lesson.

	ClockServices.h, ClockServices.c.

		Declaration and implementation of routine for measuring execution
		time of a routine.

	Test.c, Time.c.

		Simple programs for testing and timing vAdd.

	ReadMe.txt.

		This file.

	makefile.

		Build instructions for make.
