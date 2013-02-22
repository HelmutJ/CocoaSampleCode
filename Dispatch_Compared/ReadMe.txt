### Dispatch_Compared ###

===========================================================================
USAGE:	Dispatch_Compared [<n_benchmarks> [<n_folds>  [<n_iterations>]]]

All arguments are optional, though the earlier arguments must be specified to use the later ones.

n_benchmarks - argument passed to dispatch_benchmark; more runs reduces fluctuations

n_folds - how many times to run the work_function, to increase computation vs. overhead

n_iterations - maximum # of times to iterate each API


===========================================================================
DESCRIPTION:

This sample code uses dispatch_benchmark to time the performance of
a relatively compute-intensive loop using different APIs:
- simple for loop
- GCD: dispatch_apply
- GCD: serial queue (private)
- GCD: parallel queue (global)
- GCD: multiple queues
- POSIX threads

Please note that this is NOT a "macro" benchmark that compares the real-world performance of different implementations.
Rather, it is a *micro* benchmark that simply shows the overhead of invoking each API that number of times.

Also note that a complete run with the default arguments can take several hours.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6 or later

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X v10.6 or later

===========================================================================
PACKAGING LIST:

ReadMe.txt - This document
main.c - Primary source code file
Sample_Results.txt - Sample output plus discussion of results

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009 Apple Inc. All rights reserved.
