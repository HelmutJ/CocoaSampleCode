### avmetadataeditor Example ###===========================================================================DESCRIPTION:avmetadataeditor is a command line application demonstrating the AVFoundation metadata API.

===========================================================================USAGE:

avmetadataeditor [-w] [-a] [ <options> ] src dst
avmetadataeditor [-p] [-o] [ <options> ] src
src is a path to a local file.
dst is a path to a destination file.
Options:

  -w, --write-metadata=PLISTFILE
		  Use a PLISTFILE as metadata for the destination file
  -a, --append-metadata=PLISTFILE
		  Use a PLISTFILE as metadata to merge with the source metadata for the destination file
  -p, --print-metadata=PLISTFILE
		  Write in a PLISTFILE the metadata from the source file
  -f, --file-type=UTI
		  Use UTI as output file type
  -o, --output-metadata
		  Output the metadata from the source file
  -d, --description-metadata
		  Output the metadata description from the source file
  -q, --quicktime-metadata
		  Quicktime metadata format
  -u, --quicktime-user-metadata
		  Quicktime user metadata format
  -i, --iTunes-metadata
		  iTunes metadata format
  -h, --help
		  Print this message and exit===========================================================================BUILD REQUIREMENTS:Mac OS X v10.7===========================================================================RUNTIME REQUIREMENTS:Mac OS X v10.7===========================================================================PACKAGING LIST:ReadMe.txtavmetadataeditor.mavmetadataeditor.xcodeproj===========================================================================CHANGES FROM PREVIOUS VERSIONS:Version 1.0- First version.===========================================================================Copyright (C) 2011 Apple Inc. All rights reserved.