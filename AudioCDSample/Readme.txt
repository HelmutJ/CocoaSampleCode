AudioCDSample
Command-line tool demonstrating how to discover audio CDs and access the table of contents (TOC) information presented by the CD-DA filesystem.

Version: 1.1 - 09/28/2001

Techniques shown are:
- Finding audio CD volumes
- Opening and reading the TOC file on the disc
- Parsing and printing the TOC information

Version: 1.4 - 07/20/2005

- Updated to produce a universal binary.
- Use FSEjectVolumeSync instead of deprecated function PBUnmountVol.

Version 1.5 - 04/25/2011

- Updated to Xcode 4.
- Use CFURLGetFSRef instead of deprecated function PBMakeFSRefSync.