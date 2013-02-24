/*
     File: iffToTiff.m
 Abstract: IFF to TIFF converter. Somewhat incomplete.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */


#import <AppKit/AppKit.h>

/* IFF related structures */

typedef struct {
    char chunkID[4];
    NSUInteger chunkSize;
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
    NSUInteger curLocation;
    NSUInteger endLocation;
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

static inline void getBytes(InputBytes *input, unsigned char *buf, NSUInteger count) {
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
	    NSInteger cnt;
	    BOOL oldStyleImage = YES;
	    pic->colorCount = (NSUInteger)(header.chunkSize/3);
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

static unsigned char *expandIFFBody (IFFBitMapHeader *bmhd, unsigned char *sourceBuf) {
    signed char n;
    unsigned char *start, *cur, *destBuf;
    short lineLen, plane, i, numPlanes, rowBytes;

    numPlanes = (bmhd->nPlanes + ((bmhd->masking == MASKEXPLICIT) ? 1 : 0));
    lineLen = (bmhd->w + 7) / 8;
    destBuf = (unsigned char *)malloc(lineLen * bmhd->h * (bmhd->nPlanes + ((bmhd->masking == MASKEXPLICIT) ? 1 : 0)));

    start = sourceBuf;
    cur = destBuf;

    for (i = 0; i < bmhd->h; i++) {
	for (plane = 0; plane < numPlanes; plane++) { /* n planes/line */
	    if (bmhd->compression == CMPBYTERUN1) { /* compressed */
		rowBytes = lineLen;
		while (rowBytes) { /* unpack until 1 scan-line complete */
		    n = *sourceBuf++; /* fetch block run marker */	
		    if (n >= 0) {
			NSInteger move = (++n > rowBytes) ? rowBytes : n;
			memmove (cur, sourceBuf, n);
			rowBytes -= move;
			cur += move;
			sourceBuf+=n;
		    } else { /* Compressed block */
			n = -n+1;
			if (n > rowBytes) {n = rowBytes;}
			rowBytes -= n;
			memset (cur, (unsigned int)*sourceBuf++, (NSUInteger)n);
			cur += n;
		    }
	
		}
	    } else { /* uncompressed */
		memmove (cur, sourceBuf, (NSUInteger)lineLen);
		sourceBuf += lineLen;
		cur += lineLen;
	    }
	}
	if ((bmhd->compression == CMPNONE) && ((sourceBuf - start) & 1)){
	    sourceBuf++;	/* Each scanline should be in increments of 2-bytes wide */
	}
    }
    
    return destBuf;
}

NSBitmapImageRep *bitmapImageRepFromIFF(NSData *data) {
    IFFILBMInfo pic;
    unsigned char *tiffData, *iffData;
    unsigned char mask[8] = {128,64,32,16,8,4,2,1};
    NSInteger spp, bps, scrw, scrh, scrd, scrc, actuald;
    NSInteger readMask = 0;			// Read transparency if provided?
    BOOL adjustAspectRatio = YES;	// Set resolution so that the aspect ratio is correct?
    BOOL guessAspectRatio = YES;	// Attempt to make a guess as to what the correct aspect ratio is?
    NSSize tiffSize = NSZeroSize;
    NSBitmapImageRep *tiff = nil;
    InputBytes stream;

    stream.inputBytes = [data bytes];
    stream.curLocation = 0;
    stream.endLocation = [data length];

    if (!readILBM (&stream, &pic)) {
	return nil;
    }

    scrw = pic.bmhd.w;         /* Screen width in bits */
    scrh = pic.bmhd.h;         /* Screen height in scanlines */
    scrd = pic.bmhd.nPlanes;   /* Screen depth in bit planes */
    actuald = scrd + ((pic.bmhd.masking == MASKEXPLICIT) ? 1 : 0);
    scrc = pic.colorCount;     /* Screen colors in # of color registers */
    
    /* Uncompress the IFF image */
    
    iffData = expandIFFBody (&pic.bmhd, pic.imageData);
    free (pic.imageData);
    pic.imageData = NULL;
    
    if (guessAspectRatio && adjustAspectRatio) {
	NSInteger xGuess;
	CGFloat aspect = (pic.bmhd.yAspect && pic.bmhd.xAspect) ? (((CGFloat)pic.bmhd.xAspect) / ((CGFloat)pic.bmhd.yAspect)) : 0.0f;
	if ((pic.viewMode & HIRES) && !(pic.viewMode & LACE)) {
	    xGuess = 5;
	} else if (!(pic.viewMode & HIRES) && (pic.viewMode & LACE)) {
	    xGuess = 20;
	} else {
	    xGuess = 10;
	}
	if (fabs((((CGFloat)xGuess) / 11.0) - aspect) > 0.001) {	// Might be wrong; fix it up...
	    pic.bmhd.xAspect = xGuess;
	    pic.bmhd.yAspect = 11;
	}
    }

    if (tiffSize.width < 1 || tiffSize.height < 1) {
	NSInteger realWidth, realHeight;
	CGFloat aspect = (adjustAspectRatio && pic.bmhd.yAspect && pic.bmhd.xAspect) ? (((CGFloat)pic.bmhd.xAspect) / ((CGFloat)pic.bmhd.yAspect)) : 1.0f;
	if (adjustAspectRatio) {
	    realWidth = (aspect > 1.0) ? scrw : (scrw * aspect);
	    realHeight = (aspect < 1.0) ? scrh : (scrh / aspect);
	} else {
	    realWidth = (aspect < 1.0) ? scrw : (scrw * aspect);
	    realHeight = (aspect > 1.0) ? scrh : (scrh / aspect);
	}
	if ((tiffSize.width < 1) && (tiffSize.height < 1)) {
	    tiffSize.width = realWidth;
	    tiffSize.height = realHeight;
	} else if (tiffSize.width < 1) {
	    tiffSize.width = tiffSize.height * realWidth / realHeight;
	} else {
	    tiffSize.height = tiffSize.width * realHeight / realWidth;
	}
	tiffSize.width = MAX(tiffSize.width, 1);
	tiffSize.height = MAX(tiffSize.height, 1);
    }

    if (scrd == 24) {
    
 	unsigned char curMask;
	NSInteger rowBytes = ((scrw + 7) / 8);
	NSInteger h, w, rshift;
	unsigned char *bm, *scanline;
	register unsigned char comp;
	unsigned char r, g, b;
	register NSInteger cnt;
	
	spp = 3;
	bps = 8;
	readMask = 0;
	
        tiff = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:scrw pixelsHigh:scrh bitsPerSample:bps samplesPerPixel:spp hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	tiffData = [tiff bitmapData];
		
	/*

	Video Toaster 24 Bit IFF file format:

	Below, rNM indicates red component, Nth pixel, Mth bit, where bits in a byte are numbered 7 6 5 4 3 2 1 0

	Scanline 1:	

		byte 0                             byte 1  
		r00 r10 r20 r30 r40 r50 r60 r70    r80 r90 ...
	
		byte rowBytes                      byte rowBytes+1
		r01 r11 r21 r31 r41 r51 r61 r71    r81 r91 ...
	
		...
	
		byte rowBytes*8
		g00 g10 g20 g30 ...

		byte rowBytes*8*2
	
		b00 b10 b20 b30 ...
	
	Scanline 2:
	
		byte rowBytes*8*3
		
		...
	
	*/
	
	for (h = 0; h < scrh; h++) {
	    scanline = iffData + h * rowBytes * scrd;
	    for (w = 0; w < scrw; w++) {
	    bm = scanline + (w >> 3);
	    curMask = mask[w & 7];
	    rshift = 7 - (w & 7);
		
	    comp = 0;
	    for (cnt = 0; cnt < 8; cnt++) {
		comp += (((*bm & curMask) >> rshift) << cnt);
		bm += rowBytes;
	    }
	    r = comp;
	
	    comp = 0;
	    for (cnt = 0; cnt < 8; cnt++) {
		comp += (((*bm & curMask) >> rshift) << cnt);
		bm += rowBytes;
	    }
	    g = comp;
	
	    comp = 0;
	    for (cnt = 0; cnt < 8; cnt++) {
		comp += (((*bm & curMask) >> rshift) << cnt);
		bm += rowBytes;
	    }
	    b = comp;
	
	    *tiffData++ = r;
	    *tiffData++ = g;
	    *tiffData++ = b;
	    }
	}
    } else {
	unsigned char *scanLines[8], curMask;
	unsigned short alpha;
	unsigned long color = 0;
	NSInteger w, h, cnt, rshift, byte, reg;
	NSInteger rowBytes = ((scrw + 7) / 8);
	NSInteger ham, halfbrite;
	
	if (readMask && (pic.bmhd.masking == MASKEXPLICIT || pic.bmhd.masking == MASKTRANSPARENTCOLOR)) {
	    readMask = pic.bmhd.masking;
	} else {
	    readMask = 0;
	}
	    
	halfbrite = pic.viewMode & EXTRA_HALFBRITE;
	if (ham = ((pic.viewMode & HAM) != 0)) {
	    spp = 3;
	} else {
	    spp = 1;
	    /* is the image grayscale? (for all colors in the palette, r == g == b?) */
	    for (cnt = 0; cnt < pic.colorCount; cnt++) {
		color = pic.colorTable[cnt];
		if ((((color >> 16) & 255) != (color & 255)) || (((color >> 16) & 255) != ((color >> 8) & 255))) {
		    spp = 3;
		    break;
		}
	    }
	}
	spp += (readMask ? 1 : 0);
    
	bps = 4;
	/* can the image be represented in 4-bits? */
	for (cnt = 0; cnt < pic.colorCount; cnt++) {
	    color = pic.colorTable[cnt];
	    if ((pic.colorTable[cnt] & 0x00f0f0f0) != ((pic.colorTable[cnt] << 4) & 0x00f0f0f0)) {
		bps = 8;
		break;
	    }
	}
	    
	tiff = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
					    pixelsWide:scrw
					    pixelsHigh:scrh
					    bitsPerSample:bps
					    samplesPerPixel:spp
					    hasAlpha:((readMask != 0) ? YES : NO)
					    isPlanar:NO
					    colorSpaceName:(spp > 2) ? NSCalibratedRGBColorSpace : NSCalibratedWhiteColorSpace
					    bytesPerRow:((bps*spp * scrw) + 7)/ 8
					    bitsPerPixel:0];
	[tiff setSize:tiffSize];
	tiffData = [tiff bitmapData];
    
	alpha = (bps == 8) ? 0x0ff : 0x0f;
	    
	for (h = 0; h < scrh; h++) {
    
	    for (cnt = 0; cnt < scrd; cnt++) {
		scanLines[cnt] = iffData + rowBytes * ((actuald * h) + cnt);
	    }
	    
	    for (w = 0; w < scrw; w++) {
		curMask = mask[w & 7];
		rshift = 7 - (w & 7);
		byte = w >> 3;
		reg = 0;
		for (cnt = 0; cnt < scrd; cnt++) {
		    reg += ((((*(scanLines[cnt] + byte)) & curMask) >> rshift) << cnt);
		}
		switch (readMask) {
		    case MASKNONE:
			break;
		    case MASKEXPLICIT: 
			if ((*(iffData + rowBytes * ((actuald * h) + scrd) + byte)) & curMask) {
			    alpha = (bps == 8) ? 0x0ff : 0x0f;
			} else {
			    alpha = 0;
			}
			break;
		    case MASKTRANSPARENTCOLOR: 
			if (reg == pic.bmhd.transparentColor) {
			    alpha = 0;
			} else {
			    alpha = (bps == 8) ? 0x0ff : 0x0f;
			}
			break;
		}
	
		if (ham) {
		    NSInteger regf = reg & 0x0f;
		    if (w == 0) {
			color = pic.colorTable[0];
		    }
		    switch (reg & 0x030) {
			case 0x000: color = pic.colorTable[reg]; break;
			case 0x010: color = (color & 0x00ffff00) | (regf | (regf << 4)); break;
			case 0x030: color = (color & 0x00ff00ff) | ((regf | (regf << 4)) << 8); break;  
			case 0x020: color = (color & 0x0000ffff) | ((regf | (regf << 4)) << 16); break;  
		    }
		} else if (halfbrite && (reg >= 32)) {
		    color = ((pic.colorTable[reg % 32]) >> 1) & 0x007f7f7f;
		} else {
		    color = pic.colorTable[reg];
		}
	
		if (!alpha) color = 0;
	
		if (bps == 8) {
		    if (spp == 1 || spp == 2) {
			*tiffData++ = color & 0x0ff;
			if (spp == 2) *tiffData++ = alpha;
		    } else if (spp == 3 || spp == 4) {
			*tiffData++ = (color >> 16) & 0x0ff;
			*tiffData++ = (color >> 8) & 0x0ff;
			*tiffData++ = (color & 0x0ff);
			if (spp == 4) *tiffData++ = alpha;
		    }
		} else {	/* bps == 4 */
		    switch (spp) {
			case 1:
			if (w & 1) {	/* odd pixel */
			    *tiffData |= (color & 0x0f);
			    tiffData++;
			} else {		/* even pixel */
			    *tiffData = (color & 0x0f0);
			}
			break;
			case 2:
			*tiffData++ = (color & 0x0f0) | alpha;
			break;
			case 3:
			if (w & 1) {	/* odd pixel */
			    *tiffData |= (color >> 16) & 0x0f; /* the red */
			    tiffData++;
			    *tiffData++ = ((color >> 8) & 0xf0) | (color & 0x0f); /* green & blue */
			} else {		/* even pixel */
			    *tiffData++ = ((color >> 16) & 0xf0) | ((color >> 8) & 0x0f);
			    *tiffData = (color & 0x0f0);
			}
			break;
			case 4:
			*tiffData++ = ((color >> 16) & 0xf0) | ((color >> 8) & 0x0f);
			*tiffData++ = (color & 0x0f0) | alpha;
		    }
		}
	    }
    
	    if ((spp & 1) && (bps == 4) && (scrw & 1)) tiffData++;	/* We're stuck in mid byte! */
    
	}
    }

    free(iffData);

    return [tiff autorelease];
}
