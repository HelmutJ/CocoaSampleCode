/*
     File: AIFFTrack.m
 Abstract: Simple class that illustrates how to implement a track data producer.
  Version: 1.2
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "AIFFTrack.h"
#import "EXBuffer.h"

#import <fcntl.h>

#if PRAGMA_STRUCT_ALIGN
	#pragma options align=mac68k
#elif PRAGMA_STRUCT_PACKPUSH
	#pragma pack(push, 2)
#elif PRAGMA_STRUCT_PACK
	#pragma pack(2)
#endif

typedef struct IFFChunkHeader	IFFChunkHeader;
typedef struct AIFFHeader AIFFHeader;
typedef struct AIFFChunk AIFFChunk;
typedef struct AIFFCommonChunk AIFFCommonChunk;
typedef struct AIFFSoundChunk AIFFSoundChunk;

struct IFFChunkHeader
{
	UInt32			_chunkID;		// id for this chunk
	UInt32			_chunkSize;		// size of this chunk not including header
};

#define IFFChunkHeader_getChunkID(iffch) OSSwapBigToHostInt32((iffch)->_chunkID)
#define IFFChunkHeader_setChunkID(iffch, chunkID) ((iffch)->_chunkID = OSSwapHostToBigInt32(chunkID))
#define IFFChunkHeader_getChunkSize(iffch) OSSwapBigToHostInt32((iffch)->_chunkSize)
#define IFFChunkHeader_setChunkSize(iffch, chunkSize) ((iffch)->_chunkSize = OSSwapHostToBigInt32(chunkSize))

struct AIFFChunk
{
	UInt32			_chunkID;		// id for this chunk
	UInt32			_chunkSize;		// size of this chunk not including header
	UInt32			data[1];		// streamed data
};

#define AIFFChunk_getChunkID(aiffc) OSSwapBigToHostInt32((aiffc)->_chunkID)
#define AIFFChunk_setChunkID(aiffc, chunkID) ((aiffc)->_chunkID = OSSwapHostToBigInt32(chunkID))
#define AIFFChunk_getChunkSize(aiffc) OSSwapBigToHostInt32((aiffc)->_chunkSize)
#define AIFFChunk_setChunkSize(aiffc, chunkSize) ((aiffc)->_chunkSize = OSSwapHostToBigInt32(chunkSize))


struct AIFFHeader
{
	UInt32			_form;			// 'FORM'
	UInt32			_formChunkSize;	// largely ignored, but it should be (filesize - 8)
	UInt32			_aiff;			// 'AIFF'
	AIFFChunk		chunk[1];		// packed array of chunks
};

#define AIFFHeader_getForm(aiffh) OSSwapBigToHostInt32((aiffh)->_form)
#define AIFFHeader_setForm(aiffh, chunkID) ((aiffh)->_chunkID = OSSwapHostToBigInt32(form))
#define AIFFHeader_getFormChunkSize(aiffh) OSSwapBigToHostInt32((aiffh)->_formChunkSize)
#define AIFFHeader_setFormChunkSize(aiffh, formChunkSize) ((aiffh)->_chunkSize = OSSwapHostToBigInt32(formChunkSize))
#define AIFFHeader_getAIFF(aiffh) OSSwapBigToHostInt32((aiffh)->_aiff)
#define AIFFHeader_setAIFF(aiffh, aiff) ((aiffh)->_aiff = OSSwapHostToBigInt32(aiff))

struct AIFFCommonChunk
{
	UInt32			_comm;				// 'COMM'
	UInt32			_commChunkSize;		// size of this chunk not including header (18 bytes)
	UInt16			_numChannels;		// number of sound channels
	UInt32			_numSampleFrames;	// number of sample frames - probably incorrect!
	UInt16			_sampleSize;			// sample size in bits (eg, 16)
	UInt32			_sampleFreq;			// sample frequency
	UInt8			zeroes[6];			// AIFF defines the preceding as an 80-bit IEEE 754 fp number... most folks seem to use only 4 bytes
};

#define AIFFCommonChunk_getCOMM(aiffcc) OSSwapBigToHostInt32((aiffcc)->_comm)
#define AIFFCommonChunk_setCOMM(aiffcc, comm) ((aiffcc)->_comm = OSSwapHostToBigInt32(comm))
#define AIFFCommonChunk_getCOMMChunkSize(aiffcc) OSSwapBigToHostInt32((aiffcc)->_commChunkSize)
#define AIFFCommonChunk_setCOMMChunkSize(aiffcc, commChunkSize) ((aiffcc)->_commChunkSize = OSSwapHostToBigInt32(commChunkSize))
#define AIFFCommonChunk_getNumChannels(aiffcc) OSSwapBigToHostInt16((aiffcc)->_numChannels)
#define AIFFCommonChunk_setNumChannels(aiffcc, numChannels) ((aiffcc)->_numChannels = OSSwapHostToBigInt16(numChannels))
#define AIFFCommonChunk_getNumSampleFrames(aiffcc) OSSwapBigToHostInt32((aiffcc)->_numSampleFrames)
#define AIFFCommonChunk_setNumSampleFrames(aiffcc, numSampleFrames) ((aiffcc)->_numSampleFrames = OSSwapHostToBigInt32(numSampleFrames))
#define AIFFCommonChunk_getSampleSize(aiffcc) OSSwapBigToHostInt16((aiffcc)->_sampleSize)
#define AIFFCommonChunk_setSampleSize(aiffcc, sampleSize) ((aiffcc)->_sampleSize = OSSwapHostToBigInt16(sampleSize))
#define AIFFCommonChunk_getSampleFreq(aiffcc) OSSwapBigToHostInt32((aiffcc)->_sampleFreq)
#define AIFFCommonChunk_setSampleFreq(aiffcc, sampleFreq) ((aiffcc)->_sampleFreq = OSSwapHostToBigInt32(sampleFreq))

struct AIFFSoundChunk
{
	UInt32			_ssnd;				// 'SSND'
	UInt32			_ssndChunkSize;		// size of this chunk not including header (8 bytes + samples)
	UInt32			_offset;				// used for aligning, usually zero
	UInt32			_blockSize;			// used for aligning, usually zero
};

#define AIFFSoundChunk_getSSND(aiffsc) OSSwapBigToHostInt32((aiffsc)->_ssnd)
#define AIFFSoundChunk_setSSND(aiffsc, ssnd) ((aiffsc)->_ssnd = OSSwapHostToBigInt32(ssnd))
#define AIFFSoundChunk_getSSNDChunkSize(aiffsc) OSSwapBigToHostInt32((aiffsc)->_ssndChunkSize)
#define AIFFSoundChunk_setSSNDChunkSize(aiffsc, ssndChunkSize) ((aiffsc)->_ssndChunkSize = OSSwapHostToBigInt32(ssndChunkSize))
#define AIFFSoundChunk_getOffset(aiffsc) OSSwapBigToHostInt32((aiffsc)->_offset)
#define AIFFSoundChunk_setOffset(aiffsc, offset) ((aiffsc)->_offset = OSSwapHostToBigInt32(offset))
#define AIFFSoundChunk_getBlockSize(aiffsc) OSSwapBigToHostInt32((aiffsc)->_blockSize)
#define AIFFSoundChunk_setBlockSize(aiffsc, blockSize) ((aiffsc)->_blockSize = OSSwapHostToBigInt32(blockSize))

const UInt32 AIFF_SAMPLE_RATE_44_1		= 0x400EAC44;
const UInt32 AIFF_SAMPLE_RATE_44_0		= 0x400DAC44;

#if PRAGMA_STRUCT_ALIGN
	#pragma options align=reset
#elif PRAGMA_STRUCT_PACKPUSH
	#pragma pack(pop)
#elif PRAGMA_STRUCT_PACK
	#pragma pack()
#endif

@implementation AIFFAudioTrack

- (id) initWithProducer:(id)producer
{
    self = [super initWithProducer:producer];
	if (self) {
		NSDictionary *properties = @{
        DRTrackLengthKey : [(AIFFTrackProducer*)producer length],
    DRBlockSizeKey:[NSNumber numberWithUnsignedShort:2352],
        DRDataFormKey : @0,
        DRBlockTypeKey : @0,
        DRTrackModeKey : @0,
        DRSessionFormatKey : @0
        /*
         Audio verification is not supported right now. We could leave this out, but it's here so I could add this nice comment about it.
         */
        // DRVerificationTypeKey : DRVerificationTypeProduceAgain
        };
		
		[self setProperties:properties];
	}
	
	return self;
}

@end

@implementation AIFFTrackProducer

// -------------------------------------------------------------------------
/* Simple, we'll write an AIFF file to CD. We're not going to do any checking here
	or before we burn since we assume that the file is a valid AIFF. Now wouldn't 
	be the place to find that out :-) */
- (id)initWithPath:(NSString*)filepath
{
    self = [super init];
	if (self)
	{
		// We're not going to keep the file open all this time.
		path = filepath;
		
		[[self class] parseFileAtPath:filepath fileInfo:&fileInfo];
	}
	
	return self;
}

// -------------------------------------------------------------------------
/* Return the size of the track data we'll be burning. This will  turn into the
	track length on disc. In this simple case we're just returning back to the 
	caller the length we were initialized with. In a real application, this would
	(for example) be the length of the audio file or data file or MPEG movie, etc. */
- (DRMSF*) length
{
	// Loosely, for every incoming sample frame we output a sample frame.  At least
	//	until we allow resampling, that is.
	// figure out how many actual byte sof data will be sent. This / 2352 is the length of the
	// audio in frames.
	unsigned long	byteSize = (fileInfo.dataEnd - fileInfo.dataStart) / (fileInfo.sampleBytes * fileInfo.numChannels) * 4;
	return [DRMSF msfWithFrames:byteSize / 2352];
}

#pragma mark -

// -------------------------------------------------------------------------
/* This method is called before the burn is to begin. Here's where we'll open up our
	file to read data from and then update the track length if the file got bigger. */
- (BOOL) prepareTrack:(DRTrack*)track forBurn:(DRBurn*)burn toMedia:(NSDictionary*)mediaInfo
{
	// Turn on F_NOCACHE for the file. We're not going to need this AIFF file data 
	// to be cached by the UBC.
	file = [NSFileHandle fileHandleForReadingAtPath:path];
	fcntl([file fileDescriptor], F_NOCACHE, 1);
	
	//
	// make sure we know how big the file is once and for all. This will probably never happen
	// to change, but it illustrates that you can update the track info here if need be.
	//
	[[self class] parseFile:file fileInfo:&fileInfo];
	if ([[track length] isEqualTo:[self length]] == NO)
	{
		NSMutableDictionary *properties = [[track properties] mutableCopy];
		[properties setObject:[track length] forKey:DRTrackLengthKey];
		[track setProperties:properties];
	}
	
	[file seekToFileOffset:fileInfo.dataStart];
	cursor = fileInfo.dataStart;
	mask = ((unsigned int)-0x10000) >> fileInfo.sampleBits;

	return YES;
}

// -------------------------------------------------------------------------
/* The meat of the producer object. This method is called repeatedly during a burn.
	It's the producer's job to write data into the passed in buffer each time it's 
	called.  It's best if you can fill up the buffer completely. The buffer is
	a multiple of blockSize in length. */
- (uint32_t) produceDataForTrack:(DRTrack*)track intoBuffer:(char*)buffer length:(uint32_t)bufferLength atAddress:(uint64_t)address blockSize:(uint32_t)blockSize ioFlags:(uint32_t*)flags
{
	unsigned long		expectedFrames = (bufferLength / 4);
	unsigned long		readSize = (fileInfo.sampleBytes * fileInfo.numChannels) * expectedFrames;
	NSData*				tempData;
	const char*			tempBuffer;
	char*				outBuffer = buffer;
	uint32_t            outLength;
	int					step = fileInfo.sampleBytes*fileInfo.numChannels;
	
	if (readSize + cursor > fileInfo.dataEnd)
		readSize = fileInfo.dataEnd - cursor;

	tempData = [file readDataOfLength:readSize];
	tempBuffer = [tempData bytes];
	
	outLength = 0;
	for (int i=0; i<readSize; i += step)
	{
		unsigned short	leftSample = 0, rightSample = 0;
		unsigned const char*	sampleFrame = (unsigned char*)tempBuffer + i;
		
		#define READ_SAMPLE_POINT(frame,index)		\
			(OSSwapBigToHostInt16((*(UInt16*)(frame + fileInfo.sampleBytes*index))) & mask)
		#define MIX(a,b)							\
			(((a * 2) / 3) + ((b * 2) / 3))
		
		// Handle our wonderful multichannel logic.  Yeah, it's almost certainly unnecessary,
		//	but it took an extra 2 minutes to write it this way since I was already thinking
		//	about how to parse the AIFF properly.  Maybe it'll make someone's world a better place.
		if (fileInfo.numChannels == 2)
		{
			leftSample = READ_SAMPLE_POINT(sampleFrame,0);
			rightSample = READ_SAMPLE_POINT(sampleFrame,1);
		}
		else if (fileInfo.numChannels == 1)
		{
			leftSample = READ_SAMPLE_POINT(sampleFrame,0);
			rightSample = leftSample;
		}
		else if (fileInfo.numChannels == 3)
		{
			unsigned short	centerSample = READ_SAMPLE_POINT(sampleFrame,2);
			leftSample = MIX(READ_SAMPLE_POINT(sampleFrame,0),centerSample);
			rightSample = MIX(READ_SAMPLE_POINT(sampleFrame,1),centerSample);
		}
		else if (fileInfo.numChannels == 4)
		{
			// The spec is unclear on how to distinguish quadrophonic vs 4 ch surround AIFFs, as
			//	they both have four channels.  Since surround seems to be the winner of these
			//	ancient audio wars, for now I'm going to assume 4 channels means surround.
			//	Not that it matters.
			UInt16	centerSample = MIX(READ_SAMPLE_POINT(sampleFrame,1),READ_SAMPLE_POINT(sampleFrame,3));
			leftSample = MIX(READ_SAMPLE_POINT(sampleFrame,0),centerSample);
			rightSample = MIX(READ_SAMPLE_POINT(sampleFrame,2),centerSample);
		}
		else if (fileInfo.numChannels == 6)
		{
			unsigned short	centerSample = MIX(READ_SAMPLE_POINT(sampleFrame,2),READ_SAMPLE_POINT(sampleFrame,5));
			leftSample = MIX(MIX(READ_SAMPLE_POINT(sampleFrame,0),READ_SAMPLE_POINT(sampleFrame,1)),centerSample);
			rightSample = MIX(MIX(READ_SAMPLE_POINT(sampleFrame,3),READ_SAMPLE_POINT(sampleFrame,4)),centerSample);
		}
		
		#undef READ_SAMPLE_POINT
		#undef MIX
		
		// Dump the samples into the output.
		((unsigned short*)outBuffer)[0] = NSSwapHostShortToLittle(leftSample);
		((unsigned short*)outBuffer)[1] = NSSwapHostShortToLittle(rightSample);
		outBuffer += 4;
		outLength += 4;
	}
	
	cursor += readSize;
	return outLength;
}

// -------------------------------------------------------------------------
/* This method is called after the burn is finished and all data has been written
	to disc and optionally verified. This producer, since it's
	so simple, doesn't need to do anything in it, but this would be where you would
	free up any resources allocated in prepareTrackForBurn:. */
- (void) cleanupTrackAfterBurn:(DRTrack*)track
{
	// close up the file and get rid of it.
	[file closeFile];
	file = nil;
}

#pragma mark -

// -------------------------------------------------------------------------
/* Parse and check the file to make sure that we can read it. */
+ (BOOL) parseFile:(NSFileHandle*)aiffFile fileInfo:(AIFFFileInfo*)info
{
	AIFFHeader			aiffHeader;
	EXBuffer*			aiffHeaderBuf;
	AIFFCommonChunk		commonChunk;
	EXBuffer*			commonChunkBuf;
	AIFFSoundChunk		soundChunk;
	EXBuffer*			soundChunkBuf;
	IFFChunkHeader		chunkHeader;
	EXBuffer*			chunkHeaderBuf;
	
	
	if (info == NULL)
		return NO;
		
	// Initialize our file info to reasonable values.
	info->numChannels = 0;
	info->sampleFreq = 0;
	info->sampleBits = 0;
	info->sampleBytes = 0;
	info->dataStart = 0;
	info->dataEnd = 0;
	
	// Set up our reader buffers. 
	aiffHeaderBuf = [[EXBuffer alloc] initWithMemory:&aiffHeader capacity:sizeof(aiffHeader)];
	commonChunkBuf = [[EXBuffer alloc] initWithMemory:&commonChunk capacity:sizeof(commonChunk)];
	soundChunkBuf = [[EXBuffer alloc] initWithMemory:&soundChunk capacity:sizeof(soundChunk)];
	chunkHeaderBuf = [[EXBuffer alloc] initWithMemory:&chunkHeader capacity:sizeof(chunkHeader)];
	
	// Read in what should be the aiff file FORM header. Check for valid values.
	[aiffFile seekToFileOffset:0];
	[aiffFile readDataIntoBuffer:aiffHeaderBuf];
	if (AIFFHeader_getForm(&aiffHeader) != 'FORM' || AIFFHeader_getAIFF(&aiffHeader) != 'AIFF') return NO;
	
	// OK, it's a valid AIFF file, search through for the common chunk. We do this
	// by reading in the "header" (my terminology) of a chunk. This will give us the 
	// chunkID and the size of the chunk. If it's not the chunk we want, we'll skip over
	// it to the next one. If the file's corrupted, we'll eventually hit EOF and 
	// fall out.
	[aiffFile seekToFileOffset:[aiffFile offsetInFile] - sizeof(AIFFChunk)];	
	IFFChunkHeader_setChunkSize(&chunkHeader, 0);
	do
	{
		[aiffFile seekToFileOffset:[aiffFile offsetInFile] + IFFChunkHeader_getChunkSize(&chunkHeader)];	
		[aiffFile readDataIntoBuffer:chunkHeaderBuf];
	}
	while ([chunkHeaderBuf length] > 0 && IFFChunkHeader_getChunkID(&chunkHeader) != 'COMM');

	// If we read in no bytes into our buffer, we hit the end. Goodbye
	if ([chunkHeaderBuf length] == 0)
		return NO;
	
	// Back up a bit and read in the entire Common chunk.
	[aiffFile seekToFileOffset:[aiffFile offsetInFile] - sizeof(chunkHeader)];	
	[aiffFile readDataIntoBuffer:commonChunkBuf];

	// Check for unacceptable values.
	if (AIFFCommonChunk_getCOMMChunkSize(&commonChunk) != 18) {
		NSLog(@"invalid common chunk size (%ld)... ignoring", (long)AIFFCommonChunk_getCOMMChunkSize(&commonChunk));
	}
	if (AIFFCommonChunk_getNumSampleFrames(&commonChunk) == 0) {
		NSLog(@"No samples in the file... aborting");
		return YES;		// It's valid, just nothing we can really read from. We'll get a zero length track if we try.
	}

	info->numChannels = AIFFCommonChunk_getNumChannels(&commonChunk);
	info->sampleFreq = AIFFCommonChunk_getSampleFreq(&commonChunk);
	info->sampleBits = AIFFCommonChunk_getSampleSize(&commonChunk);
	info->sampleBytes = (info->sampleBits + 7) / 8;

	if ((info->numChannels == 0) || (info->numChannels == 5) || (info->numChannels > 6)) {
		NSLog(@"invalid number of channels (%ld)", (long)info->numChannels);
		return NO;
	}
	if (info->sampleFreq != AIFF_SAMPLE_RATE_44_1 && info->sampleFreq != AIFF_SAMPLE_RATE_44_0) {
		// we could resample, in fact possibly should for 22 KHz audio.  for others just show me a reason why...
		NSLog(@"invalid sample frequency ($%08lX)", (long)info->sampleFreq);
		return NO;
	}
	if ((info->sampleBits < 1) || (info->sampleBits > 128)) {
		NSLog(@"invalid sample size (%ld bits)", (long)info->sampleBits);
		return NO;
	}

	// go back the start of the file (remember chunks in an IFF file don't have to be in any order)
	// and look for the Sound chunk the same way we did the Common chunk.
	[aiffFile seekToFileOffset:12];	
	IFFChunkHeader_setChunkSize(&chunkHeader, 0);
	do
	{
		[aiffFile seekToFileOffset:[aiffFile offsetInFile] + IFFChunkHeader_getChunkSize(&chunkHeader)];	
		[aiffFile readDataIntoBuffer:chunkHeaderBuf];
	}
	while ([chunkHeaderBuf length] > 0 && IFFChunkHeader_getChunkID(&chunkHeader) != 'SSND');

	// If we read in no bytes into our buffer, we hit the end. Goodbye
	if ([chunkHeaderBuf length] == 0)
		return NO;
	
	// Once again, back up and read in the Sound chunk.
	[aiffFile seekToFileOffset:[aiffFile offsetInFile] - sizeof(chunkHeader)];	
	[aiffFile readDataIntoBuffer:soundChunkBuf];
	
	info->dataStart = [aiffFile offsetInFile] + AIFFSoundChunk_getOffset(&soundChunk);
	info->dataEnd = [aiffFile offsetInFile] + AIFFSoundChunk_getSSNDChunkSize(&soundChunk) - 8;
	if ((AIFFSoundChunk_getSSNDChunkSize(&soundChunk) < 8) || (info->dataEnd > [aiffFile seekToEndOfFile]))
		info->dataEnd = [aiffFile offsetInFile];
	
	return YES;
}

// -------------------------------------------------------------------------
/* This method is designed to be use by some other code (like in an open panel!)
	to determine if the file is one that this producer can read. */
+ (BOOL) parseFileAtPath:(NSString*)filepath fileInfo:(AIFFFileInfo*)info
{
	return [self parseFile:[NSFileHandle fileHandleForReadingAtPath:filepath] fileInfo:info];
}


@end

