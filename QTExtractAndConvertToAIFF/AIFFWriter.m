/*

File: AIFFWriter.m

Author: QuickTime DTS

Change History (most recent first): 

    <3> 09/10/06 modified to perform audio extraction/conversion for QTExtractAndConvertToAIFF
    <2> 03/24/06 must pass NSError objects to exportCompleted
    <1> 11/10/05 initial release as part of ExtractMovieAudioToAIFF

© Copyright 2005 - 2006 Apple Computer, Inc. All rights reserved.

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

/*

QTExtractAndConvertToAIFF contains two Objective-C objects that are used together to
implement audio extraction and audio conversion from a QuickTime Movie's sound track to
an AIFF file.

The first is a simple class called AIFFWriter (a modified version of the AIFFWriter
class that was included with the ExtractMovieAudioToAIFF sample) that encapsulates the
functionality of two sets of APIs; QuickTime's Audio Extraction API's and Core Audio's
Audio File APIs. The second is another simple class called AudioConverter which
encapsulates Core Audio's Audio Converter API.

The sample uses an instance of the AIFFWriter class to easily set up audio extraction
from a QTKit QTMovie to an AIFF file. AIFFWriter uses an instance of the AudioConverter
class to perform the conversion to a user selected destination format which is
configured by the Standard Audio Dialog Component. The Audio Converter uses a Movie
Audio Extraction Session in it's Read Input Procedure to pull audio out of the Movie.

This sample uses the default extraction channel layout which is the aggregate channel
layout of the movie (for example, all Rights mixed together, all Left Surrounds mixed
together, etc).

References:

http://developer.apple.com/documentation/QuickTime/Conceptual/QT7UpdateGuide/Chapter02/chapter_2_section_6.html

http://developer.apple.com/documentation/MusicAudio/Conceptual/CoreAudioOverview/WhatsinCoreAudio/chapter_3_section_4.html

*/

#import "AIFFWriter.h"

#pragma mark ---- AIFFWriterProgressInfo ----

// AIFFWriterProgressInfo is the object passed back to the progress callback
// if implemented by the client. It contains information regarding the current
// state of the export session which can be used to drive a UI.
@interface AIFFWriterProgressInfo (Private)

- (BOOL)continueOperation;
- (void)setPhase:(AIFFWriterExportOperationPhase)value;
- (void)setProgressValue:(NSNumber *)value;
- (void)setExportStatus:(NSError *)status;

@end

@implementation AIFFWriterProgressInfo

- (AIFFWriterExportOperationPhase)phase 
{
    return phase;
}

- (NSNumber *)progressValue
{
    return [[progressValue retain] autorelease];
}

- (NSError *)exportStatus {
    return [[exportStatus retain] autorelease];
}

- (BOOL)continueOperation;
{
    return continueOperation;
}

- (void)setContinueOperation:(BOOL)value
{
    continueOperation = value;
}

- (void)setPhase:(AIFFWriterExportOperationPhase)value
{
    phase = value;
}

- (void)setProgressValue:(NSNumber *)value
{
    if (progressValue != value) {
        [progressValue release];
        progressValue = [value copy];
    }
}

- (void)setExportStatus:(NSError *)status
{
    if (exportStatus != status) {
        [exportStatus release];
        exportStatus = [status copy];
    }
}

- (void)dealloc
{
    [progressValue release];
    [exportStatus release];
    
    [super dealloc];
}

@end

#pragma mark ---- AIFFWriter private interface ----

@interface AIFFWriter (Private)

- (void)exportOnMainThreadCallBack:(id)inObject;
- (void)exportOnWorkerThread:(id)inObject;

- (OSStatus)convertAudioToFile:(SInt64 *)ioNumFrames;

- (OSStatus)configureExtractionSessionWithMovie:(Movie)inMovie;
- (OSStatus)createOutputFile;
- (void)setMovieConversionDuration;

- (void)exportCompletedNotification:(NSError *)inError;

- (MovieAudioExtractionRef)audioExtractionSession;
- (AudioBufferList *)extractionBufferList;
- (UInt32)extractionBytesPerFrame;
- (BOOL)extractionComplete;
- (void)setExtractionComplete:(BOOL)flag;

@end

@implementation AIFFWriter

#pragma mark ---- Audio Converter InputDataProc Implementation  ----

// Read Input Procedure used to supply data to the Audio Converter
static OSStatus ReadInputProc(AudioConverterRef inAudioConverter,
                              UInt32 *ioNumberDataPackets,
                              AudioBufferList *ioData,
                              AudioStreamPacketDescription **outDataPacketDescription,
                              void *inUserData)
{
#pragma unused(inAudioConverter, outDataPacketDescription)

    if (NULL == inUserData) return paramErr;

    AIFFWriter *theAIFFWriter = (AIFFWriter *)inUserData;
    
    AudioBufferList *extractionBufferList;
	UInt32 i, flags;
    
    UInt32 numFrames = kMaxExtractionFrameCount;
    UInt32 bytesPerFrame;
    MovieAudioExtractionRef audioExtractionSession;
    
    OSStatus err = noErr;
    
    extractionBufferList = [theAIFFWriter extractionBufferList];
    bytesPerFrame = [theAIFFWriter extractionBytesPerFrame];
    audioExtractionSession = [theAIFFWriter audioExtractionSession];
    
    if (![theAIFFWriter extractionComplete]) {

		for (i = 0; i < extractionBufferList->mNumberBuffers; i++) {
			extractionBufferList->mBuffers[i].mDataByteSize = numFrames * bytesPerFrame;
		}
		
		
        // read the number of requested samples from the movie
        // we're using movie audio extraction therefore we know we're supplying pcm so packet descriptions are unnecessary
        err = MovieAudioExtractionFillBuffer(audioExtractionSession, &numFrames, extractionBufferList, &flags);

	    
        if (flags & kQTMovieAudioExtractionComplete) {
            [theAIFFWriter setExtractionComplete:YES];
        }
            
        *ioNumberDataPackets = numFrames;
        for (i = 0; i < extractionBufferList->mNumberBuffers; i++) {
            ioData->mBuffers[i] = extractionBufferList->mBuffers[i];
        }
    } else {
        *ioNumberDataPackets = 0;
    }
	
    return err;
}

#pragma mark ---- initialization/dealocation ----

- (id)init;
{
	if (self = [super init]) {
    
        mLock = [[NSLock alloc] init];
        mProgressInfo = [[AIFFWriterProgressInfo alloc] init];
    }

	return self;
}

- (void)dealloc
{
	if (mFileName) {
    	[mFileName release];
    }
    
	if (mAudioExtractionSession){
		MovieAudioExtractionEnd(mAudioExtractionSession);
    }
    
    if (mMyAudioConverter) {
        [mMyAudioConverter release];
    }
    
    if (mQTMovie) {
    	[mQTMovie release];
    }
    
    if (mExtractionBuffList) {
    	free(mExtractionBuffList);
    }
    
    if (mExtractionBuffer) {
    	free(mExtractionBuffer);
    }
    
    if (mOutputBufferList) {
    	free(mOutputBufferList);
    }
    
    if (mOutputBuffer) {
    	free(mOutputBuffer);
    }
    
    [mLock release];
    
    [mProgressInfo release];
    
    [super dealloc]; 
}

#pragma mark ---- public ----

// main method call that will produce an AIFF file - it will try to
// export the movie on a separate thread but if it can't will schedule
// callbacks on the main thread
- (OSStatus)exportFromMovie:(QTMovie *)inMovie toFile:(NSString *)inFullPath
{
    BOOL extractionOnWorkerThread = NO;
    BOOL continueExport = YES;
    Handle cloneHandle = NULL;
    NSString *directory;
    
    OSStatus err = noErr;
    
    // sanity
    if (nil == inMovie || nil == inFullPath) return paramErr;
    
    // if we're busy already doing an export return
    if (![mLock tryLock]) return kObjectInUseErr;
    
    mIsConverting = YES;
    
    // if the client implemented a progress proc. call it now
    if (TRUE == mDelegateShouldContinueOp) {
        [mProgressInfo setPhase:AIFFWriterExportBegin];
        [mProgressInfo setProgressValue:nil];
        [mProgressInfo setExportStatus:nil];
        
        continueExport = [[self delegate] shouldContinueOperationWithProgressInfo:mProgressInfo];

        if (NO == continueExport) goto bail;
    }
    
    directory = [inFullPath stringByDeletingLastPathComponent];
    
    mFileName = [[NSString alloc] initWithString:[inFullPath lastPathComponent]];
    
	// retain the QTMovie object passed in, we need it for the duration of
    // the export regardless of what the client decides to do with it
    mQTMovie = [inMovie retain];
    
    // create a new Audio Converter object for this conversion operation
    mMyAudioConverter = [AudioConverter newAudioConverterWithMovie:[mQTMovie quickTimeMovie] status:&err];
    if (NULL == mMyAudioConverter) goto bail;
        
    // set the Audio Converter Read Input Data Proc
    [mMyAudioConverter setInputDataProc:ReadInputProc];
 
    // if the file already exists, delete it
    err = FSPathMakeRef((const UInt8*)[inFullPath fileSystemRepresentation], &mFileRef, false);
    if (err == noErr) {
        err = FSDeleteObject(&mFileRef);
        if (err) goto bail;
    }
    
    err = FSPathMakeRef((const UInt8*)[directory fileSystemRepresentation], &mParentRef, NULL);
    if (err) goto bail;
    
    // set the movies duration in floating-point seconds
    [self setMovieConversionDuration];
    
    // clone the movie and see if we can migrate it to a worker thread for extraction
    cloneHandle = NewHandle(0);
    if (NULL == cloneHandle) { err = memFullErr; goto bail; }
    
    err = PutMovieIntoHandle([mQTMovie quickTimeMovie], cloneHandle);
    if (err) goto bail;
    
    err = NewMovieFromHandle(&mCloneMovie, cloneHandle, newMovieActive, NULL);
    if (err != noErr || mCloneMovie == NULL) goto bail;
    
    // if we couldn't migrate this movie, export from the movie on the main thread
    if (DetachMovieFromCurrentThread(mCloneMovie) == noErr) {
        extractionOnWorkerThread = YES;
    } else {
        DisposeMovie(mCloneMovie);
        mCloneMovie = NULL;
    }
    
    if (extractionOnWorkerThread == YES) {
        // export on a worker thread if we can...
        [NSThread detachNewThreadSelector:@selector(exportOnWorkerThread:) toTarget:self withObject:nil];
    } else {
        // ...if not, we're on the main thread so just call the main-thread worker method
        [self exportOnMainThreadCallBack:nil];
    }

bail:

    if (cloneHandle) DisposeHandle(cloneHandle);
    
    if (err) [self exportCompletedNotification:[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]];
    
	return err;
}

- (BOOL)isConverting
{
    return mIsConverting;
}

#pragma mark ---- private ----

// this callback is scheduled on the main thread - In order to keep from locking up the UI,
// it does one slice of export, writes it to file and then reschedule itself
-(void)exportOnMainThreadCallBack:(id)inObject
{
#pragma unused(inObject)

    BOOL continueExport = YES;
    
	OSStatus err;
    
	// prepare for extraction if this is the first entry
	if (NULL == mAudioExtractionSession) {
    
		err = [self configureExtractionSessionWithMovie:[mQTMovie quickTimeMovie]];
        if (err) goto bail;
	}
     
    // create the file
    // set the number of total samples to export
    if (0 == mExportFileID) {
        AudioStreamBasicDescription *outputASBD = [mMyAudioConverter outputFormat];
    
        err = [self createOutputFile];
        if (err) goto bail;
        
        mTotalNumberOfOutputFrames = mMovieDuration ? (mMovieDuration * outputASBD->mSampleRate) : -1;
        mOneSegmentOfOutputFrames = (0.50 * outputASBD->mSampleRate);
        
        if (-1 == mTotalNumberOfOutputFrames) { mConversionComplete = YES; err = paramErr; }
    }
    
    // perform conversion
    if (!mConversionComplete) {
    
        // if the client implemented a progress proc. call it now
        if (TRUE == mDelegateShouldContinueOp) {
        	NSNumber *progressValue = [NSNumber numberWithFloat:(float)((float)mOutputFramesCompleted / (float)mTotalNumberOfOutputFrames)];
            
            [mProgressInfo setPhase:AIFFWriterExportPercent];
            [mProgressInfo setProgressValue:progressValue];
            [mProgressInfo setExportStatus:nil];
            
            continueExport = [[self delegate] shouldContinueOperationWithProgressInfo:mProgressInfo];
            if (NO == continueExport) { err = userCanceledErr; goto bail; }
        }
    
       // convert and write a half-second's worth of data
       SInt64 numFramesThisSlice = mOneSegmentOfOutputFrames;

        // extract and convert the audio and write it to the file
        err = [self convertAudioToFile:&numFramesThisSlice];	
        if (err) goto bail;
        
		mOutputFramesCompleted += numFramesThisSlice;
    }

bail:
	if (err || mConversionComplete) {
        // we're done either way so close the file
        if (mExportFileID) AudioFileClose(mExportFileID);
        
        if (err && mExportFileID) {
            // if we erred out, delete the file
            FSDeleteObject(&mFileRef);
            mExportFileID = 0;
        }
        
		// call the completion routine to clean up
        [self exportCompletedNotification:[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]];
        
	} else {
    
		// reschedule to perform this routine again on the next run loop cycle
		[self performSelectorOnMainThread:@selector(exportOnMainThreadCallBack:)
										  withObject:(id)nil
										  waitUntilDone:NO];
	}
}

// this method will be performed on a background thread
- (void)exportOnWorkerThread:(id)inObject
{
#pragma unused(inObject)

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL continueExport = YES;
	
    OSStatus err;

	[NSThread setThreadPriority:[NSThread threadPriority]+.1];
    
	// attach the movie to this thread
	err = EnterMoviesOnThread(0);
	if (err) goto bail;;
	
	err = AttachMovieToCurrentThread(mCloneMovie);
	if (err) goto bail;
    
	// prepare extraction session
	if (NULL == mAudioExtractionSession) {
		 
		err = [self configureExtractionSessionWithMovie:mCloneMovie];
        if (err) goto done;
	}
     
    // create the file
    if (0 == mExportFileID) {
        AudioStreamBasicDescription *outputASBD = [mMyAudioConverter outputFormat];
    
        err = [self createOutputFile];
        if (err) goto bail;
        
        mTotalNumberOfOutputFrames = mMovieDuration ? (mMovieDuration * outputASBD->mSampleRate) : -1;
        mOneSegmentOfOutputFrames = (5.0 * outputASBD->mSampleRate); // five seconds of audio at a time
        
        if (-1 == mTotalNumberOfOutputFrames) { mConversionComplete = YES; err = paramErr; }
    }
    
    // loop until stopped from an external event, or finished the entire operation
	while (YES == continueExport && NO == mConversionComplete) {
        
        if (!mConversionComplete) {
        
            // if the client implemented a progress proc. call it now we wait for the
            // progress fuction to return before continuing so we can check the return code
            if (TRUE == mDelegateShouldContinueOp) {
                NSNumber *progressValue = [NSNumber numberWithFloat:(float)((float)mOutputFramesCompleted / (float)mTotalNumberOfOutputFrames)];
                
                [mProgressInfo setPhase:AIFFWriterExportPercent];
                [mProgressInfo setProgressValue:progressValue];
                [mProgressInfo setExportStatus:nil];
                
                [[self delegate] performSelectorOnMainThread:@selector(shouldContinueOperationWithProgressInfo:)
                                 withObject:(id)mProgressInfo
								 waitUntilDone:YES];
                
                continueExport = [mProgressInfo continueOperation];
                if (NO == continueExport) { err = userCanceledErr; break; }
            }
        
            // read numSamplesThisSlice number of samples
            SInt64 numFramesThisSlice = mOneSegmentOfOutputFrames;

            // extract and convert the audio and write it to the file
            err = [self convertAudioToFile:&numFramesThisSlice];	
            if (err) break;
            
            mOutputFramesCompleted += numFramesThisSlice;
        }
    }

done:

    // detach the exported movie from this thread
	DetachMovieFromCurrentThread(mCloneMovie);
    ExitMoviesOnThread(); 
    
    if (mExportFileID) AudioFileClose(mExportFileID);
 	
    if (err && mExportFileID) {
    	// if we erred out, delete the file
        FSDeleteObject(&mFileRef);
        mExportFileID = 0;
    }

bail:
	// call the completion routine to clean up on the main thread
	[self performSelectorOnMainThread:@selector(exportCompletedNotification:)
                                                withObject:(id)[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]
												waitUntilDone:YES];
	
    [pool release];
}

// convert a slice of PCM audio and write it to an AIFF file - we proceed serially
// from the last position, 'ploc' specifies the file offset that the converted buffer should be written to
- (OSStatus)convertAudioToFile:(SInt64 *)ioNumFrames
{	
	UInt32   i;
	UInt32   numFrames, numPackets;
    OSStatus err;

    AudioStreamBasicDescription *extractionASBD = [mMyAudioConverter inputFormat];
    AudioStreamBasicDescription *outputASBD = [mMyAudioConverter outputFormat];
    
	// the AudioConverter doesn't seem to like to emit one packet at a time for QDesign/QualComm,
	// so make sure there are at least 2 packets per buffer
	numFrames = *ioNumFrames;
	numPackets = 2 + (numFrames / outputASBD->mFramesPerPacket);
    
    /* First time though we'll need to set up the Extraction Buffer and BufferList
       This is the buffer Movie Audio Extraction is writing into, in other words the source
       buffers for the Audio Converter
       
       We're always pulling non-interleaved buffers of LPCM from Movie Audio Extraction
       
       When working with non-interleaved audio, you need to allocate n buffers of bufferSize,
       and assign each mData to one of them
       
       NOTE - The extraction pull size will always be 4096 is this sample (kMaxExtractionFrameCount)
       
    */    
    if (NULL == mExtractionBuffList) {
    
        mExtractionBufferSize = (kMaxExtractionFrameCount * extractionASBD->mBytesPerFrame);
        mExtractionBuffer = (char *)malloc(mExtractionBufferSize * extractionASBD->mChannelsPerFrame);
        if (NULL == mExtractionBuffer) {
            err = memFullErr;
            goto bail;
        }
        
        mExtractionBuffList = (AudioBufferList *)calloc(1, offsetof(AudioBufferList, mBuffers[extractionASBD->mChannelsPerFrame]));
        if (NULL == mExtractionBuffList) {
            err = memFullErr;
            goto bail;
        }

    	mExtractionBuffList->mNumberBuffers = extractionASBD->mChannelsPerFrame;
		for (i = 0; i < extractionASBD->mChannelsPerFrame; i++) {
			mExtractionBuffList->mBuffers[i].mNumberChannels = 1;
			mExtractionBuffList->mBuffers[i].mDataByteSize = mExtractionBufferSize;
			mExtractionBuffList->mBuffers[i].mData = &mExtractionBuffer[i * mExtractionBufferSize];
		}		
	}
    
    /* First time though we'll need to set up the Output BufferList
       We're always converting to interleaved data since we're writing to a file
       so one output buffer is all we need
    
    */    
    if (NULL == mOutputBufferList) {
    
    	// calculate the output buffer size
        if (0 == outputASBD->mBytesPerPacket) {
            // if bytes per packet value is 0 in the asbd, we will need to use the
            // largest possible packet size -- this information is available from the audio converter
            UInt32 maxPacketSize = 0;
            UInt32 propertySize = sizeof(UInt32);
            
            [mMyAudioConverter getProperty:kAudioConverterPropertyMaximumOutputPacketSize: &propertySize: &maxPacketSize];
            
            mOutputBufferSize = (numPackets * maxPacketSize);
        } else {
            mOutputBufferSize = (numPackets * outputASBD->mBytesPerPacket);
        }
        
        mOutputBuffer = (char *)malloc(mOutputBufferSize);
        if (NULL == mOutputBuffer) {
            err = memFullErr;
            goto bail;
        }
        
        mOutputBufferList = (AudioBufferList *)calloc(1, sizeof(AudioBufferList));
        if (NULL == mOutputBufferList) {
            err = memFullErr;
            goto bail;
        }
        
        [mMyAudioConverter setOutputAudioBufferList:mOutputBufferList];
    }
    
    // make sure we don't try to convert more than we allocated room for
    if (numPackets > (mOutputBufferSize / outputASBD->mBytesPerPacket)) {
        numPackets = mOutputBufferSize / outputASBD->mBytesPerPacket;
    }
    
	mOutputBufferList->mNumberBuffers = 1;
	mOutputBufferList->mBuffers[0].mNumberChannels = outputASBD->mChannelsPerFrame;
	mOutputBufferList->mBuffers[0].mDataByteSize = mOutputBufferSize;
	mOutputBufferList->mBuffers[0].mData = mOutputBuffer;
    
    err = [mMyAudioConverter convert:&numPackets :NULL :self];
    if (err) goto bail;
    
	numFrames = numPackets * outputASBD->mFramesPerPacket;

	// we have completed the conversion when AudioConverterFillComplexBuffer returns zero packets
	mConversionComplete = (numPackets == 0);

	// write it to the AIFF file
	if (numPackets > 0) {
		err = AudioFileWritePackets(mExportFileID,
        							false,
                                    mOutputBufferList->mBuffers[0].mDataByteSize,
									NULL,
                                    mLocationInFile,
                                    &numPackets,
                                    mOutputBufferList->mBuffers[0].mData);
		if (err) goto bail;							
		
        mLocationInFile += numPackets;
	}
		
bail:
	
    if (err) numFrames = 0;
    
	*ioNumFrames = numFrames;
	
    return err;
}

// this method prepare the specified movie for extraction by opening an extraction session, configuring
// and setting the output ASBD and the output layout if one exists - it also sets the start time to 0
// and calculates the total number of samples to export
- (OSStatus) configureExtractionSessionWithMovie:(Movie)inMovie
{
	OSStatus err;
    
	// open a movie audio extraction session
	err = MovieAudioExtractionBegin(inMovie, 0, &mAudioExtractionSession);
	if (err) goto bail;

	// set the extraction ASBD
	err = MovieAudioExtractionSetProperty(mAudioExtractionSession,
                                          kQTPropertyClass_MovieAudioExtraction_Audio,
                                          kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
                                          sizeof(AudioStreamBasicDescription),
                                          [mMyAudioConverter inputFormat]);
	if (err) goto bail;
    
    // set the extraction channel layout
    err = MovieAudioExtractionSetProperty(mAudioExtractionSession,
                                          kQTPropertyClass_MovieAudioExtraction_Audio,
                                          kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
                                          [mMyAudioConverter channelLayoutSize],
                                          [mMyAudioConverter channelLayout]);
	if (err) goto bail;
    
    // set the chosen render quality - this is the same quality value set on the Audio Converter
    err = MovieAudioExtractionSetProperty(mAudioExtractionSession,
                                          kQTPropertyClass_MovieAudioExtraction_Audio,
                                          kQTMovieAudioExtractionAudioPropertyID_RenderQuality,
                                          sizeof(UInt32), [mMyAudioConverter renderQuality]);
	if (err) goto bail;

    // set the extraction start time - we always start at zero, but you don't have to
    // this is the default but we set it anyway for completeness
	TimeRecord startTime = { 0, 0, GetMovieTimeScale(inMovie), GetMovieTimeBase(inMovie) };
	
   	err = MovieAudioExtractionSetProperty(mAudioExtractionSession,
    									  kQTPropertyClass_MovieAudioExtraction_Movie,
                                          kQTMovieAudioExtractionMoviePropertyID_CurrentTime,
                                          sizeof(TimeRecord), &startTime);
	if (err) goto bail;

bail:
    	
	return err;
}

// create and configure the output file
- (OSStatus)createOutputFile
{
    OSStatus err;

    err = AudioFileCreate(&mParentRef, (CFStringRef)mFileName, kAudioFileAIFCType, [mMyAudioConverter outputFormat], 0, &mFileRef, &mExportFileID);
    if (err) goto bail;

    err = AudioFileSetProperty(mExportFileID, 
                               kAudioFilePropertyChannelLayout,
                               [mMyAudioConverter channelLayoutSize],
                               [mMyAudioConverter channelLayout]);
    if (err) goto bail;

    if (0 != [mMyAudioConverter magicCookieSize]) {
        err = AudioFileSetProperty(mExportFileID, 
                                   kAudioFilePropertyMagicCookieData,
                                   [mMyAudioConverter magicCookieSize],
                                   [mMyAudioConverter magicCookie]);
    }
    
bail:

    return err;
}

// calculate the duration of the longest audio track in the movie
// if the audio tracks end at time N and the movie is much 
// longer we don't want to keep converting - the Movie Audio Extration
// (the API we're using to provide source) will happily
// return zeroes until it reaches the movie duration
- (void)setMovieConversionDuration
{
    TimeValue maxDuration = 0;
    UInt8 i;

    SInt32 trackCount = GetMovieTrackCount([mQTMovie quickTimeMovie]);
    
    if (trackCount) {
        for (i = 1; i < trackCount + 1; i++) {
            Track aTrack = GetMovieIndTrackType([mQTMovie quickTimeMovie],
                                                i,
                                                SoundMediaType,
                                                movieTrackMediaType);
            if (aTrack) {
                TimeValue aDuration = GetTrackDuration(aTrack);
            
                if (aDuration > maxDuration) maxDuration = aDuration;
            }
        }
        
        mMovieDuration = (Float64)maxDuration / (Float64)GetMovieTimeScale([mQTMovie quickTimeMovie]);
    }
}

// this completion method gets called at the end of the extraction session or may be called
// earlier if an error has occured - its main purpose is to clean up the world so an AIFFWriter
// instance can be used over and over again
//
// in this particular case if we completed successfully we launch QTPlayer with the .aif file
// and if an error occurs we pass it back to the client though the progress info object
- (void) exportCompletedNotification:(NSError *)inError
{
	if (noErr == [inError code]) {
    	CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &mFileRef);
    	
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        
		[ws openFile:[(NSURL *)url path] withApplication:@"QuickTime Player"];
        
        CFRelease(url);
    }
    
	if (mFileName) {
    	[mFileName release];
        mFileName = nil;
    }
    
	if (mAudioExtractionSession){
		MovieAudioExtractionEnd(mAudioExtractionSession);
        mAudioExtractionSession = NULL;
    }
    
    if (mMyAudioConverter) {
        [mMyAudioConverter release];
        mMyAudioConverter = nil;
    }
    
    if (mQTMovie) {
    	[mQTMovie release];
        mQTMovie = nil;
    }
    
    mMovieDuration = 0;
    
    if (mCloneMovie) {
        DisposeMovie(mCloneMovie);
        mCloneMovie = NULL;
    }
    
    mExtractionComplete = NO;
    mConversionComplete = NO;
    mIsConverting = NO;
    
    mLocationInFile = 0;
    mOutputFramesCompleted = 0;
    mTotalNumberOfOutputFrames = 0;
    mOneSegmentOfOutputFrames = 0;
    
    mExportFileID = 0;
    
    if (mExtractionBuffList) {
    	free(mExtractionBuffList);
        mExtractionBuffList = NULL;
    }
    
    if (mExtractionBuffer) {
    	free(mExtractionBuffer);
        mExtractionBuffer = NULL;
        mExtractionBufferSize = 0;
    }
    
    if (mOutputBufferList) {
    	free(mOutputBufferList);
        mOutputBufferList = NULL;
    }
    
    if (mOutputBuffer) {
    	free(mOutputBuffer);
        mOutputBuffer = NULL;
        mOutputBufferSize = 0;
    }
    
	[mLock unlock];

    // if the client implemented a progress proc. call it now
    if (TRUE == mDelegateShouldContinueOp) {
        
        [mProgressInfo setPhase:AIFFWriterExportEnd];
        [mProgressInfo setProgressValue:nil];
        [mProgressInfo setExportStatus:((noErr != [inError code]) && (userCanceledErr != [inError code]) ? inError : nil)];
        
        [[self delegate] shouldContinueOperationWithProgressInfo:mProgressInfo];
    }
}

- (MovieAudioExtractionRef)audioExtractionSession;
{
    return mAudioExtractionSession;
}

- (AudioBufferList *)extractionBufferList
{
    return mExtractionBuffList;
}

- (UInt32)extractionBytesPerFrame
{
    AudioStreamBasicDescription *extractionASBD = [mMyAudioConverter inputFormat];

    return extractionASBD->mBytesPerFrame;
}

- (BOOL)extractionComplete
{
    return mExtractionComplete;
}

- (void)setExtractionComplete:(BOOL)flag
{
    mExtractionComplete = flag;
}

#pragma mark ---- delegate ----

// methods to support setting up a delegate of this class
- (id)delegate
{
    return mDelegate;
}

- (void)setDelegate:(id)inDelegate
{
    mDelegate = inDelegate;
    
    mDelegateShouldContinueOp = [mDelegate respondsToSelector:@selector(shouldContinueOperationWithProgressInfo:)];
}

@end
