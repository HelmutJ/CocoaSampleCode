These files demonstrate how to use some routines in the Accelerate framework.


There are three targets in the project:

	Demonstrate
		This target demonstrates convolution, Discrete Fourier
		Transform (DFT), and Fast Fourier Transform (FFT) routines.
		It uses the sources files:

			Demonstrate.c (main routine),
			Demonstrate.h (common declarations),
			DemonstrateConvolution.c (demonstrate convolution),
			DemonstrateDFT.c (demonstrate DFT),
			DemonstrateFFT.c (demonstrate FFT), and
			DemonstrateFFT2D.c (demonstrate two-dimensional FFT).

	DTMF.DFT
		This target demonstrates uses the DFT to identify "Touch Tones"
		in a signal.

	DTMF.FFT
		This target demonstrates uses the DFT to identify "Touch Tones"
		in a signal.

The project also includes BuildAndRun.sh, a script to build and execute the
demonstration programs from a Terminal command line.
