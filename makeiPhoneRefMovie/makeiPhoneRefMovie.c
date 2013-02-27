/*
	makeiPhoneRefMovie.c
	cc -o makeiPhoneRefMovie -g makeiPhoneRefMovie.c
	
	Creates a special-purpose reference movie for iPhone.
	
	Copyright 2007. All rights reserved.
	
IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
consideration of your agreement to the following terms, and your use, installation,
modification or redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject to these
terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
this original Apple software (the "Apple Software"), to use, reproduce, modify and
redistribute the Apple Software, with or without modifications, in source and/or binary
forms; provided that if you redistribute the Apple Software in its entirety and without
modifications, you must retain this notice and the following text and disclaimers in all
such redistributions of the Apple Software. Neither the name, trademarks, service marks
or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
the Apple Software without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or implied, are
granted by Apple herein, including but not limited to any patent rights that may be
infringed by your derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF
NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE
APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE
USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER
CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/****

	For information about reference movies see the following documentation:
    
    Ice Floe #15 Creating Alternate Movies
    
	    http://developer.apple.com/quicktime/icefloe/dispatch015.html
    
    QuickTime File Format Specification - Reference Movies
    
        http://developer.apple.com/documentation/QuickTime/QTFF/QTFFChap2/chapter_3_section_7.html
    
    
    NOTE: iPhone 1.0 synthesises a fake Gestalt selector 'mobi' with bitfield value 0x00000001.
    
****/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <libkern/OSByteOrder.h>

struct Options {
	const char *desktopPath;
	const char *lowPath;
	const char *highPath;
};

// writeHeader and patchHeader are utility functions
// writeHeader writes the atom header returning the header offset for each atom being written
// patchHeader updates the atom size correctly after all the atom data has been written
static void writeHeader( FILE *outputFile, uint32_t atomType, off_t *headerOffset )
{
	uint32_t atomSize = 'patc';
	atomSize = OSSwapHostToBigInt32( atomSize );
	atomType = OSSwapHostToBigInt32( atomType );
	*headerOffset = ftello( outputFile );                 // ftello is identical to ftell but returns an off_t which can be a 64-bit type
	fwrite( &atomSize, sizeof(atomSize), 1, outputFile ); // will be patched later
	fwrite( &atomType, sizeof(atomType), 1, outputFile );
}

static void patchHeader( FILE *outputFile, off_t headerOffset )
{
	off_t saveOffset = ftello( outputFile );
	uint32_t atomSize = saveOffset - headerOffset;
	fseeko( outputFile, headerOffset, SEEK_SET );
	atomSize = OSSwapHostToBigInt32( atomSize );
	fwrite( &atomSize, sizeof(atomSize), 1, outputFile );
	fseeko( outputFile, saveOffset, SEEK_SET );
}

// write the data rate atom 'rmdr'
static void write_rdrf( FILE *outputFile, const char *path )
{
	off_t headerOffset;
	size_t pathSize = strlen( path ) + 1; // include NULL
	uint32_t flags = 0;
	uint32_t dataRefType = OSSwapHostToBigInt32( 'url ' );
	uint32_t dataRefSize = OSSwapHostToBigInt32( pathSize );
	writeHeader( outputFile, 'rdrf', &headerOffset );
	fwrite( &flags, sizeof(flags), 1, outputFile );
	fwrite( &dataRefType, sizeof(dataRefType), 1, outputFile );
	fwrite( &dataRefSize, sizeof(dataRefSize), 1, outputFile );
	fwrite( path, pathSize, 1, outputFile );
	patchHeader( outputFile, headerOffset );
}

// taken from MoviesFormat.h
enum {
	kDataRate288ModemRate         = 2800L,
	kDataRateLowRate              = 11200L,
	kDataRate1MbpsRate            = 100000L,
};

// write the data reference atom 'rdrf'
static void write_rmdr( FILE *outputFile, uint32_t dataRate )
{
	off_t headerOffset;
	uint32_t flags = 0;
	dataRate = OSSwapHostToBigInt32( dataRate );
	writeHeader( outputFile, 'rmdr', &headerOffset );
	fwrite( &flags, sizeof(flags), 1, outputFile );
	fwrite( &dataRate, sizeof(dataRate), 1, outputFile );
	patchHeader( outputFile, headerOffset );
}

// write the iPhone version check atom 'rmvc'
static void write_iPhone_rmvc( FILE *outputFile )
{
	off_t headerOffset;
	uint32_t flags = 0;
	uint32_t gestaltTag = OSSwapHostToBigInt32( 'mobi' );
	uint32_t val1 = OSSwapHostToBigInt32( 1 ); // bitflags is 1
	uint32_t val2 = OSSwapHostToBigInt32( 1 ); // bitmask is 1
	uint16_t checkType = OSSwapHostToBigInt16( 1 ); // type is mask
	writeHeader( outputFile, 'rmvc', &headerOffset );
	fwrite( &flags, sizeof(flags), 1, outputFile );
	fwrite( &gestaltTag, sizeof(gestaltTag), 1, outputFile );
	fwrite( &val1, sizeof(val1), 1, outputFile );
	fwrite( &val2, sizeof(val2), 1, outputFile );
	fwrite( &checkType, sizeof(checkType), 1, outputFile );
	patchHeader( outputFile, headerOffset );
}

enum {
	kNoRequirements = 0,
	kRequireiPhone = 1,
};

// for each reference, create the appropriate 'rmda'
// in each reference write a data reference atom 'rdrf' and a data rate atom 'rmdr'
// in the iPhone cases "kRequireiPhone" also write a version check atom 'rmvc'
static void write_rmda( FILE *outputFile, const char *path, int requirements, uint32_t dataRate )
{
	off_t headerOffset;
	writeHeader( outputFile, 'rmda', &headerOffset );
	write_rdrf( outputFile, path );
	write_rmdr( outputFile, dataRate );
	if( requirements & kRequireiPhone )
		write_iPhone_rmvc( outputFile );
	patchHeader( outputFile, headerOffset );
}

// write the 'rmra' and add each Reference Movie Descriptor Atom 'rmda'
// NOTE: The order DOES matter here  -- the last one that passes all of
// its checks (data rate, version check) wins. Since we can only describe
// "data rate >= x" and "we are on iPhone" and not the opposites of those checks,
// there's only one order to put the 'rmra' atoms in such that they can all be effective.
static void write_rmra( FILE *outputFile, struct Options *options )
{
	off_t headerOffset;
	writeHeader( outputFile, 'rmra', &headerOffset );
	write_rmda( outputFile, options->desktopPath, kNoRequirements, kDataRate288ModemRate );
	write_rmda( outputFile, options->lowPath,     kRequireiPhone,  kDataRateLowRate );
	write_rmda( outputFile, options->highPath,    kRequireiPhone,  kDataRate1MbpsRate );
	patchHeader( outputFile, headerOffset );
}

// create the reference movie - write the 'moov' header and populate the 'rmra' atom
static void write_moov( FILE *outputFile, struct Options *options )
{
	off_t headerOffset;
	writeHeader( outputFile, 'moov', &headerOffset );
	write_rmra( outputFile, options );
	patchHeader( outputFile, headerOffset );
}

// display the usage message
static void usage( const char *argv0 )
{
	fprintf( stderr, "usage: %s foo-low.3gp foo-high.m4v foo-desktop.mov foo-ref.mov\n", argv0 );
	fprintf( stderr, "\tcreates foo-ref.mov with a special-purpose iPhone ref movie\n" );
	fprintf( stderr, "\tthe other files need not exist; they're just embedded as URLs\n" );
	exit(1);
}

int main(int argc, const char **argv)
{
	const char *argv0 = argv[0];
	struct Options options = {0};
	const char *outputPath;
	FILE *outputFile = NULL;
	struct stat sb;
	
	if( argc != 5 )
		usage( argv0 );
	
    // grab the paths to the sources and destination
	options.lowPath = argv[1];
	options.highPath = argv[2];
	options.desktopPath = argv[3];
	outputPath = argv[4];
	
	if( 0 == stat( outputPath, &sb ) ) {
		fprintf( stderr, "%s: file exists\n", outputPath );
		return 1;
	}
	
	outputFile = fopen( outputPath, "w" );
	
	printf( "writing an iPhone ref movie to %s with:\n", outputPath );
	printf( "  on iPhone, low bitrate    => %s\n", options.lowPath );
	printf( "  on iPhone, higher bitrate => %s\n", options.highPath );
	printf( "  otherwise                 => %s\n", options.desktopPath );
	
    // do the work
	write_moov( outputFile, &options );
	
	fclose( outputFile );
	
	return 0;
}
