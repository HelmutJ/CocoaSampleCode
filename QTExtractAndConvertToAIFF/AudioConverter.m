/*

File: AudioConverter.m

Author: QuickTime DTS

Change History (most recent first): <1> 09/05/06 initial release

© Copyright 2006 Apple Computer, Inc. All rights reserved.

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

#import "AudioConverter.h"
#include "Carbon/Carbon.h"

@implementation AudioConverter

#pragma mark ---- class methods ----

+ (id)newAudioConverterWithMovie:(Movie)inMovie status:(OSStatus *)outStatus
{
    if (NULL == inMovie) {
        NSLog(@"Can't create an AudioConverter object, the Movie is invalid!\n");
        return nil;
    }
 
    return [[self alloc] initWithMovie:inMovie status:outStatus];
}

#pragma mark ---- instance methods ----
#pragma mark ---- initialization/dealocation ----

- (id)initWithMovie:(Movie)inMovie status:(OSStatus *)outStatus
{
    ComponentInstance ci;
    OSStatus err = *outStatus = noErr;
        
	if (self = [super init]) {
        Boolean trueValue = true;
        SCAudioFormatFlagsRestrictions pcmRestrictions = {kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved,
                                                          kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger}; // only big, only SIGNED (8-bit)
        UInt32 flags;
        SCExtendedProcs extendedProcs = {0}; // used for a custom name on the dialog
        
        //*** Get the summary channel layout and ASBD from the movie ***/
        
        // get the audio stream basic description
        err = QTGetMovieProperty(inMovie,
                                 kQTPropertyClass_Audio,
                                 kQTAudioPropertyID_SummaryASBD,
                                 sizeof(AudioStreamBasicDescription),
                                 &mInputFormat,
                                 NULL);
        if (err) goto bail;
        
        // get the size of the movie summary channel layout
        err = QTGetMoviePropertyInfo(inMovie,
                                     kQTPropertyClass_Audio,
                                     kQTAudioPropertyID_SummaryChannelLayout,
                                     NULL,
                                     &mInputChannelLayoutSize,
                                     NULL);
        if (err) goto bail;

        // allocate memory for the layout
        mInputChannelLayoutPtr = (AudioChannelLayout *)calloc(1, mInputChannelLayoutSize);
        if (NULL == mInputChannelLayoutPtr)  { err = memFullErr; goto bail; }

        // get the layout for the current extraction configuration
        err = QTGetMovieProperty(inMovie,
                                 kQTPropertyClass_Audio,
                                 kQTAudioPropertyID_SummaryChannelLayout,
                                 mInputChannelLayoutSize,
                                 mInputChannelLayoutPtr,
                                 NULL);
        if (err) goto bail;
        
        // initially set the main channel layout
        // this will change if the number of output channels changes
        mChannelLayout = mInputChannelLayoutPtr;
        mChannelLayoutSize = mInputChannelLayoutSize;

        //*** Bring up the StdAudio dialog and get the desired output configuration ***/
    
        // open StdAudio
        err = OpenADefaultComponent(StandardCompressionType, StandardCompressionSubTypeAudio, &ci);
        if (err) goto bail;
    
        // set the input format of the StdAudio component to that of our input asbd
        err = QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                     kQTSCAudioPropertyID_InputBasicDescription,
                                     sizeof(mInputFormat), &mInputFormat);
        if (err) goto bail;
                           
        // set the input channel layout
        err =  QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                      kQTSCAudioPropertyID_InputChannelLayout,
                                      mInputChannelLayoutSize, mInputChannelLayoutPtr);
        if (err) goto bail;

        // NOTE: Because we're using this code in a sample that specifically writes an AIFF file
        // we need to set some compression limits. While AIFF doesn't need to limit specific compressors,
        // it does need to exclude the VBR ones.
        err = QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                     kQTSCAudioPropertyID_ConstantBitRateFormatsOnly,
                                     sizeof(Boolean), &trueValue);
        if (err) goto bail;
                               
        // set the lpcm restrictions    
        err = QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                     kQTSCAudioPropertyID_ClientRestrictedLPCMFlags,
                                     sizeof(SCAudioFormatFlagsRestrictions),
                                     &pcmRestrictions);
        if (err) goto bail;
        
        // set a custom dialog name
        strcpy((char*)extendedProcs.customName + 1, "Select Output Encoding Format");
		extendedProcs.customName[0] = (unsigned char)strlen((char*)extendedProcs.customName + 1);
		err = QTSetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                     kQTSCAudioPropertyID_ExtendedProcs, 
                                     sizeof(SCExtendedProcs), &extendedProcs);
        if (err) goto bail;
                           
        // show the dialog (this call blocks until the dialog is finished)
        err = SCRequestImageSettings(ci);
        if (err) goto bail;
        
        // *** Get the information we need to create an Audio Converter to convert to the selected output format
        
        // get the desired output format
        err = QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                     kQTSCAudioPropertyID_BasicDescription,
                                     sizeof(mOutputFormat), &mOutputFormat, NULL);
        if (err) goto bail;
        
        // get the output channel layout
        err = QTGetComponentPropertyInfo(ci, kQTPropertyClass_SCAudio,
                                         kQTSCAudioPropertyID_ChannelLayout,
                                         NULL, &mOutputChannelLayoutSize, NULL);
        if (err) goto bail;
                                                                  
        // allocate memory for it
        mOutputChannelLayoutPtr = (AudioChannelLayout *)calloc(1, mOutputChannelLayoutSize);
        if (NULL == mOutputChannelLayoutPtr) { err = memFullErr; goto bail; }
        
        // get the channel layout
        err = QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                         kQTSCAudioPropertyID_ChannelLayout,
                                         mOutputChannelLayoutSize, mOutputChannelLayoutPtr, &mOutputChannelLayoutSize);
        if (err) goto bail;
         
        // retrive the render quality
        err = QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                     kQTSCAudioPropertyID_RenderQuality,
                                     sizeof(mRenderQuality), &mRenderQuality, NULL);
        if (err) goto bail;

        // get the codec specific settings if available
        // used to configure the audio converter
        if (noErr == QTGetComponentPropertyInfo(ci, kQTPropertyClass_SCAudio,
                                                kQTSCAudioPropertyID_CodecSpecificSettingsArray,
                                                NULL, NULL, &flags) && (flags & kComponentPropertyFlagCanGetNow)) {                                
                                                                                                  
            err = QTGetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                         kQTSCAudioPropertyID_CodecSpecificSettingsArray,
                                         sizeof(CFArrayRef), &mCodecSpecificSettings, NULL);
            if (err) goto bail;
                                         
        }
        
        // get the magic cookie if available
        // maybe used to configure the audio converter if CodecSpecificSettingsArray is not available
        // must be written to the file if it exists
        if (noErr == QTGetComponentPropertyInfo(ci, kQTPropertyClass_SCAudio,
                                                    kQTSCAudioPropertyID_MagicCookie,
                                                    NULL, &mMagicCookieSize, NULL) && mMagicCookieSize) {
            
            mMagicCookie = calloc(1, mMagicCookieSize);
            if (NULL == mMagicCookie) { err = memFullErr; goto bail; }
            
            err = QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                         kQTSCAudioPropertyID_MagicCookie,
                                         mMagicCookieSize, mMagicCookie, &mMagicCookieSize);
            if (err) goto bail;
        }
        
        // close StdAudio, we don't need it anymore
        CloseComponent(ci);
        ci = NULL;
    
        // *** Create the audio converter and set it up with info retrieved from StdAudio ***/

        if (mInputFormat.mChannelsPerFrame != mOutputFormat.mChannelsPerFrame) {
            // an AudioConverter can't do mixing -- it requires n channels IN equalling n channels OUT
            // therefore we need to alter the input ASBD so Movie Audio Extraction will do the mixing for us
            
            // modify the input ASBD as required
            mInputFormat.mChannelsPerFrame = mOutputFormat.mChannelsPerFrame;
            
            // also need to change the channel layout appropriately
            mChannelLayout = mOutputChannelLayoutPtr;
            mChannelLayoutSize = mOutputChannelLayoutSize;
        }
    
        // create an AudioConverter
        err = AudioConverterNew(&mInputFormat, &mOutputFormat, &mAudioConverter);
        if (err) goto bail;
        
        // set the channel layout
        err = [self setProperty:kAudioConverterOutputChannelLayout :mOutputChannelLayoutSize :mOutputChannelLayoutPtr];
        if (err) goto bail;
        
        // set the render quality for the audio converter
        // if there's no sample rate conversion in the chain a kAudioConverterErr_PropertyNotSupported
        // error would be returned here, this is not a problem so ignore the return value
        // NOTE: remember to also set the same quality value to the Movie Audio Extraction session
        // so that any scaled edits or codec decompressions are done at the same render quality
        // specified in the dialog - we do this ourselves later
        [self setProperty:kAudioConverterSampleRateConverterQuality:sizeof(UInt32):&mRenderQuality];
    
        // A codec that has CodecSpecificSettings might have a MagicCookie as well,
        // but prefer the CodecSpecificSettingsArray for the audio converter if you have both
        if (NULL != mCodecSpecificSettings) {
        
            // set the codec specific settings if we got em or...
            err = [self setProperty:kAudioConverterPropertySettings:sizeof(CFArrayRef):&mCodecSpecificSettings];
            if (err) goto bail;
            
        } else if (NULL != mMagicCookie) {
        
            // ...set the magic cookie if we got it
            err = [self setProperty:kAudioConverterCompressionMagicCookie:mMagicCookieSize:mMagicCookie];
            if (err) goto bail;
        }
        
        return self;
    }
    
bail:
    
    if (NULL != ci) CloseComponent(ci);
    [self release];
    
    *outStatus = err;
    
	return nil;
}

- (void)dealloc
{   
    [self reset];
    
    [super dealloc];
}

#pragma mark ---- reset ----

- (void)reset
{   
    mInputFormat = (AudioStreamBasicDescription){0};
    mOutputFormat = (AudioStreamBasicDescription){0};
        
    mChannelLayout = NULL;
    mChannelLayoutSize = 0;
    mRenderQuality = kRenderQuality_Min;
    mReadInputDataProcPtr = NULL;
    mOutputBufferList = NULL;
    
    if (NULL != mInputChannelLayoutPtr)  { free(mInputChannelLayoutPtr); mInputChannelLayoutPtr = NULL; mInputChannelLayoutSize = 0; }
    if (NULL != mOutputChannelLayoutPtr) { free(mOutputChannelLayoutPtr); mOutputChannelLayoutPtr = NULL; mOutputChannelLayoutSize = 0; }
    
    if (NULL != mCodecSpecificSettings) { CFRelease(mCodecSpecificSettings); mCodecSpecificSettings = NULL; }
    if (NULL != mMagicCookie) { free(mMagicCookie); mMagicCookie = NULL; mMagicCookieSize = 0; }
    
    if (NULL != mAudioConverter) {
        AudioConverterDispose(mAudioConverter);
        mAudioConverter = NULL;
    }
}

#pragma mark ---- convert ----

- (OSStatus)convert:(UInt32 *)ioOutputDataPacketSize :(AudioStreamPacketDescription *)outPacketDescription :(void *)inRefCon
{
    OSStatus err = paramErr;
        
    if (NULL == mAudioConverter || NULL == mReadInputDataProcPtr || NULL == mOutputBufferList) {
        NSLog(@"The AudioConverter Object is Incorrectly Configured!\n");
        return err;
    }
        
    return AudioConverterFillComplexBuffer(mAudioConverter, mReadInputDataProcPtr, inRefCon, ioOutputDataPacketSize, mOutputBufferList, outPacketDescription);
}


#pragma mark ---- properties ----

- (OSStatus)getPropertyInfo:(AudioConverterPropertyID)propertyID :(UInt32 *)propertyDataSize :(Boolean *)writable
{
    return AudioConverterGetPropertyInfo(mAudioConverter, propertyID, propertyDataSize, writable);
}

- (OSStatus)getProperty:(AudioConverterPropertyID) propertyID: (UInt32 *)propertyDataSize: (void *)propertyData;
{
    return AudioConverterGetProperty(mAudioConverter, propertyID, propertyDataSize, propertyData);
}

- (OSStatus)setProperty:(AudioConverterPropertyID) propertyID: (UInt32)propertyDataSize: (const void *)propertyData;
{
    return AudioConverterSetProperty(mAudioConverter, propertyID, propertyDataSize, propertyData);
}

#pragma mark ---- getters ----

- (AudioConverterRef)audioConverter
{
    return mAudioConverter;
}

- (AudioStreamBasicDescription *)inputFormat
{
    return &mInputFormat;
}

- (AudioStreamBasicDescription *)outputFormat
{
    return &mOutputFormat;
}

- (AudioChannelLayout *)channelLayout
{
    return mChannelLayout;
}

- (UInt32)channelLayoutSize
{
    return mChannelLayoutSize;
}

- (UInt32 *)renderQuality
{
    return &mRenderQuality;
}

- (void *)magicCookie
{
    return mMagicCookie;
}

- (UInt32)magicCookieSize
{
    return mMagicCookieSize;
}

#pragma mark ---- setters ----

-(void)setInputDataProc:(AudioConverterComplexInputDataProc)inInputDataProcPtr
{
    mReadInputDataProcPtr = inInputDataProcPtr;
}

-(void)setOutputAudioBufferList:(AudioBufferList *)inOutputAudioBufferList
{
    mOutputBufferList = inOutputAudioBufferList;
}
    
@end
