/*
	File:		iffToTiff.m

	Version:	1.0

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple's
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 */

#import <AppKit/AppKit.h>
#include <CoreServices/CoreServices.h> 


/* IFF related structures */

typedef struct {
    char chunkID[4];
    unsigned int chunkSize;
} IFFChunkHeader;

typedef struct {
    short w, h, x, y;
    char  nPlanes, masking, compression, pad1;
    short transparentColor;
    char  xAspect, yAspect;
    short pageWidth, pageHeight;
} IFFBitMapHeader;

typedef struct {
    IFFBitMapHeader    bmhd;		/* From BMHD chunk */
    unsigned long   *colorTable;	/* Each entry 32 bits; 00rrggbb */
    unsigned short  colorCount;		/* Number of colors read in from CMAP; upto 256 */
    unsigned char   *imageData;		/* Image data */
    unsigned long   viewMode;		/* CAMG chunk */
} IFFILBMInfo;

/* Various IFF bits. */

#define	HIRES			0x8000
#define	LACE			0x0004
#define	HAM			0x0800
#define	EXTRA_HALFBRITE		0x0080

#define MASKNONE		0
#define MASKEXPLICIT		1
#define MASKTRANSPARENTCOLOR	2
#define MASKLASSO		3

#define CMPNONE			0
#define CMPBYTERUN1		1

/* Struct for maintaining input state */

typedef struct {
    const unsigned char *inputBytes;
    unsigned curLocation;
    unsigned endLocation;
} InputBytes;

/* Functions for reading input */

static void badIFFError(void) {
    [NSException raise:@"BadIFFFileException" format:@"Can't read IFF file"];
}

static inline unsigned char getByte(InputBytes *input) {
    if (input->curLocation + 1 > input->endLocation) badIFFError();
    return input->inputBytes[(input->curLocation)++];
}

static inline unsigned short getShort(InputBytes *input) {	/* Gets big endian short */
unsigned short tmp;
if (input->curLocation + 2 > input->endLocation) badIFFError();
tmp = input->inputBytes[input->curLocation + 1] | (input->inputBytes[input->curLocation] << 8);
input->curLocation += 2;
return tmp;
}

static inline unsigned long getLong(InputBytes *input) {
    unsigned long tmp;
    if (input->curLocation + 4 > input->endLocation) badIFFError();
    tmp = input->inputBytes[input->curLocation + 3] | (input->inputBytes[input->curLocation + 2] << 8) | (input->inputBytes[input->curLocation + 1] << 16) | (input->inputBytes[input->curLocation] << 24);
    input->curLocation += 4;
    return tmp;
}

static inline void getBytes(InputBytes *input, unsigned char *buf, unsigned count) {
    if (input->curLocation + count > input->endLocation) badIFFError();
    memcpy(buf, input->inputBytes + input->curLocation, count);
    input->curLocation += count;
}

static void getBMHD (InputBytes *stream, IFFBitMapHeader *bmhd) {
    bmhd->w = getShort(stream);
    bmhd->h = getShort(stream);
    bmhd->x = getShort(stream);
    bmhd->y = getShort(stream);
    bmhd->nPlanes = getByte(stream);
    bmhd->masking = getByte(stream);
    bmhd->compression = getByte(stream);
    bmhd->pad1 = getByte(stream);
    bmhd->transparentColor = getShort(stream);
    bmhd->xAspect = getByte(stream);
    bmhd->yAspect = getByte(stream);
    bmhd->pageWidth = getShort(stream);
    bmhd->pageHeight = getShort(stream);
}

static void getID (InputBytes *stream, char str[4]) {
    str[0] = getByte(stream);
    str[1] = getByte(stream);
    str[2] = getByte(stream);
    str[3] = getByte(stream);
}

static void getHeader (InputBytes *stream, IFFChunkHeader *header) {
    getID (stream, header->chunkID);
    header->chunkSize = getLong(stream);
}

static BOOL readILBM (InputBytes *stream, IFFILBMInfo *pic) {
    IFFChunkHeader header;
    
    memset (pic, 0, sizeof(IFFILBMInfo));
	
    getHeader (stream, &header);
    if (strncmp(header.chunkID, "FORM", 4)) return 0;
    
    getID (stream, header.chunkID);
    if (strncmp(header.chunkID, "ILBM", 4)) return 0;
    
    // Read chunks until we get to the body chunk
    
    while (stream->curLocation < stream->endLocation) {
		
		getHeader (stream, &header);
		
		if (strncmp(header.chunkID, "BODY", 4) == 0) {
			pic->imageData = (unsigned char *)malloc(header.chunkSize);
			getBytes (stream, pic->imageData, header.chunkSize);
			return 1;	// Done, get out of here...
		} else if (strncmp(header.chunkID, "BMHD", 4) == 0) {
			getBMHD (stream, &(pic->bmhd));
		} else if (strncmp(header.chunkID, "CMAP", 4) == 0) {
			int cnt;
			BOOL oldStyleImage = YES;
			pic->colorCount = (unsigned int)(header.chunkSize/3);
			pic->colorTable = (unsigned long *)malloc(pic->colorCount * sizeof(long));
			for (cnt = 0; cnt < pic->colorCount; cnt++) {
				unsigned char r, g, b;
				r = getByte(stream);
				g = getByte(stream);
				b = getByte(stream);
				pic->colorTable[cnt] = (((unsigned long)r) << 16) | (((unsigned long)g) << 8) | (((unsigned long)b));
			}
			if (pic->colorCount & 1) stream->curLocation++;	/* Align to even boundary... */
			/* Check to see if this is an old-style image */
			for (cnt = 0; cnt < pic->colorCount; cnt++) {
				if (((pic->colorTable[cnt] & 0x000f0f0f) != 0) && (pic->colorTable[cnt] != 0x00ffffff)) {
					oldStyleImage = NO;
					break;
				}
			}
			if (oldStyleImage) {
				for (cnt = 0; cnt < pic->colorCount; cnt++) {
					pic->colorTable[cnt] |= ((pic->colorTable[cnt] & 0x00f0f0f0) >> 4);
				}
			}
		} else if (strncmp(header.chunkID, "CAMG", 4) == 0) {
			pic->viewMode = getLong(stream);
		} else {
			// Ignore this chunk
			stream->curLocation += header.chunkSize + ((header.chunkSize & 1) ? 1 : 0);
		}
    }
	
    return 0;
}      



int
extract_iff_info(NSString *path, NSMutableDictionary *attributes)
{
    NSData *data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// load the data from the file
	data = [NSData dataWithContentsOfFile:path];
	if (data == NULL) {
		[pool release];
		return FALSE;
    }
	

	// get setup to parse the data in the file
	// the result goes into the "pic" structure
	IFFILBMInfo pic;
    InputBytes stream;
	
    stream.inputBytes = [data bytes];
    stream.curLocation = 0;
    stream.endLocation = [data length];
	
    if (!readILBM (&stream, &pic)) {
	    [data release];
		[pool release];
        return FALSE;
    }
	
	
	// create the width and height attributes and add
	// them to the attributes dictionary
	NSNumber *num;
	num = [NSNumber numberWithInt:pic.bmhd.w];
	[num retain];
	[attributes setValue:num forKey:(id)kMDItemPixelWidth];
	
	num = [NSNumber numberWithInt:pic.bmhd.h];
	[num retain];
	[attributes setValue:num forKey:(id)kMDItemPixelHeight];
	
	[pool release];
	
	return TRUE;
}
