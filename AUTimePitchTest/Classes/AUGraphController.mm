/*
        File: AUGraphController.mm
    Abstract: Demonstrates using the AUTimePitch.
     Version: 1.0.1
    
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

#import "AUGraphController.h"

#pragma mark- Render

// render some silence
static void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}

// audio render procedure to render our client data format
// 2 ch interleaved 'lpcm' platform Canonical format - this is the mClientFormat data, see CAStreamBasicDescription SetCanonical()
// note that this format can differ between platforms so be sure of the data type you're working with,
// for example AudioSampleType may be Float32 or may be SInt16
static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    SourceAudioBufferDataPtr userData = (SourceAudioBufferDataPtr)inRefCon;
    
    AudioSampleType *in = userData->soundBuffer[inBusNumber].data;
    AudioSampleType *out = (AudioSampleType *)ioData->mBuffers[0].mData;
    
    UInt32 sample = userData->frameNum * userData->soundBuffer[inBusNumber].asbd.mChannelsPerFrame;
    
    // make sure we don't attempt to render more data than we have available in the source buffer
    if ((userData->frameNum + inNumberFrames) > userData->soundBuffer[inBusNumber].numFrames) {
        UInt32 offset = (userData->frameNum + inNumberFrames) - userData->soundBuffer[inBusNumber].numFrames;
        if (offset < inNumberFrames) {
            // copy the last bit of source
            SilenceData(ioData);
            memcpy(out, &in[sample], ((inNumberFrames - offset) * userData->soundBuffer[inBusNumber].asbd.mBytesPerFrame));
        }
    } else {
        memcpy(out, &in[sample], ioData->mBuffers[0].mDataByteSize);
    }

    // in the iPhone sample using the iPodEQ, a graph notification was used to count rendered source samples at output to know when to loop the source
    // because there is time compression/expansion AU being used in this sample as well as rate conversion, you can't really use a render notification
    // on the output of the graph since you can't assume the graph is producing output at the same rate that it is consuming input
    // therefore, this kind of sample counting needs to happen somewhere upstream of the timepich AU and in this case the AUConverter
    // ** doing it here is the place for it **
    userData->frameNum += inNumberFrames;
    if (userData->frameNum >= userData->maxNumFrames) {
        userData->frameNum = 0;
    }
    
    //printf("render input bus %u sample %u\n", inBusNumber, sample);
    
    return noErr;
}

#pragma mark- AUGraphController

@interface AUGraphController (hidden)
 
- (void)loadSpeechTrack:(Float64)inGraphSampleRate;
 
@end

@implementation AUGraphController

- (void)dealloc
{    
    printf("AUGraphController dealloc\n");
    
    DisposeAUGraph(mGraph);
    
    free(mUserData.soundBuffer[0].data);
    
    CFRelease(sourceURL);
    
	[super dealloc];
}

- (void)awakeFromNib
{
    printf("AUGraphController awakeFromNib\n");
    
    // clear the mSoundBuffer struct
	memset(&mUserData.soundBuffer, 0, sizeof(mUserData.soundBuffer));
    
    // create the URL we'll use for source
    
    // AAC demo track
    NSString *source = [[NSBundle mainBundle] pathForResource:@"SpeechTrack" ofType:@"mp4"];
    
    sourceURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)source, kCFURLPOSIXPathStyle, false);
}

- (void)initializeAUGraph:(Float64)inSampleRate
{
    printf("initializeAUGraph\n");
    
    AUNode outputNode;
    AUNode timePitchNode;
	AUNode mixerNode;
    AUNode converterNode;
    AudioUnit converterAU;
    
    printf("create client format ASBD\n");
    
    // client format audio going into the converter
    mClientFormat.SetCanonical(2, true);						
    mClientFormat.mSampleRate = 22050.0; // arbitrary sample rate chosen to demonstrate working with 3 different sample rates
                                         // 1) the rate passed in which ends up being the the graph rate (in this sample the arbitrary choice of 11KHz)
                                         // 2) the rate of the original file which in this case is 44.1kHz (rate conversion to client format of 22k is done by ExtAudioFile)
                                         // 3) the rate we want for our source data which in this case is 22khz (AUConverter taking care of conversion to Graph Rate)
                                         // File @ 44.1kHz - > ExtAudioFile - > Client Format @ 22kHz - > AUConverter graph @ 11kHz -> Output
                                         // while this type of multiple rate conversions isn't what you'd probably want to do in your application, this sample simply demonstrates
                                         // this flexibility -- where you perform rate conversions is important and some thought should be put into the decision
    mClientFormat.Print();
    
    printf("create output format ASBD\n");
    
    // output format
    mOutputFormat.SetAUCanonical(2, false);						
	mOutputFormat.mSampleRate = inSampleRate;
    mOutputFormat.Print();
	
	OSStatus result = noErr;
    
    // load up the demo audio data
    [self loadSpeechTrack: inSampleRate];
    
    printf("-----------\n");
    printf("new AUGraph\n");
    
    // create a new AUGraph
	result = NewAUGraph(&mGraph);
    if (result) { printf("NewAUGraph result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
	
    // create four CAComponentDescription for the AUs we want in the graph
    
    // output unit
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_DefaultOutput, kAudioUnitManufacturer_Apple);
    
    // timePitchNode unit
    CAComponentDescription timePitch_desc(kAudioUnitType_FormatConverter, kAudioUnitSubType_TimePitch, kAudioUnitManufacturer_Apple);
    
    // multichannel mixer unit
	CAComponentDescription mixer_desc(kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer, kAudioUnitManufacturer_Apple);
    
    // AU Converter
    CAComponentDescription converter_desc(kAudioUnitType_FormatConverter, kAudioUnitSubType_AUConverter, kAudioUnitManufacturer_Apple);
    
    printf("add nodes\n");

    // create a node in the graph that is an AudioUnit, using the supplied component description to find and open that unit
	result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
	if (result) { printf("AUGraphNewNode 1 result %lu %4.4s\n", (unsigned long)result, (char *)&result); return; }
    
    result = AUGraphAddNode(mGraph, &timePitch_desc, &timePitchNode);
    if (result) { printf("AUGraphNewNode 2 result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }

	result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
	if (result) { printf("AUGraphNewNode 3 result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }
    
	result = AUGraphAddNode(mGraph, &converter_desc, &converterNode);
	if (result) { printf("AUGraphNewNode 3 result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }

    // connect a node's output to a node's input
    // au converter -> mixer -> timepitch -> output
    
    result = AUGraphConnectNodeInput(mGraph, converterNode, 0, mixerNode, 0);
	if (result) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }
    
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, timePitchNode, 0);
	if (result) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }
	
    result = AUGraphConnectNodeInput(mGraph, timePitchNode, 0, outputNode, 0);
    if (result) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)result, (char*)&result); return; }
    
    // open the graph -- AudioUnits are open but not initialized (no resource allocation occurs here)
	result = AUGraphOpen(mGraph);
	if (result) { printf("AUGraphOpen result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
	
    // grab audio unit instances from the nodes
    result = AUGraphNodeInfo(mGraph, converterNode, NULL, &converterAU);
    if (result) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }

	result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    if (result) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    result = AUGraphNodeInfo(mGraph, timePitchNode, NULL, &mTimeAU);
    if (result) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // set bus count
	UInt32 numbuses = 1;
	
    printf("set input bus count %lu\n", (unsigned long)numbuses);
	
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // enable metering
    UInt32 onValue = 1;
    
    printf("enable metering for input bus 0\n");
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, 0, &onValue, sizeof(onValue));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // setup render callback struct
    AURenderCallbackStruct rcbs;
    rcbs.inputProc = &renderInput;
    rcbs.inputProcRefCon = &mUserData;
    
    printf("set AUGraphSetNodeInputCallback\n");
    
    // set a callback for the specified node's specified input bus (bus 1)
    result = AUGraphSetNodeInputCallback(mGraph, converterNode, 0, &rcbs);
    if (result) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    printf("set converter input bus %d client kAudioUnitProperty_StreamFormat\n", 0);
    
    // set the input stream format, this is the format of the audio for the converter input bus (bus 1)
    result = AudioUnitSetProperty(converterAU, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mClientFormat, sizeof(mClientFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // in an au graph, each nodes output stream format (including sample rate) needs to be set explicitly
    // this stream format is propagated to its destination's input stream format
    
    printf("set converter output kAudioUnitProperty_StreamFormat\n");
    
    // set the output stream format of the converter
	result = AudioUnitSetProperty(converterAU, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mOutputFormat, sizeof(mOutputFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }

    printf("set mixer output kAudioUnitProperty_StreamFormat\n");
 
    // set the output stream format of the mixer
	result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mOutputFormat, sizeof(mOutputFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    printf("set timepitch output kAudioUnitProperty_StreamFormat\n");
    
    // set the output stream format of the timepitch unit
	result = AudioUnitSetProperty(mTimeAU, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mOutputFormat, sizeof(mOutputFormat));
    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    printf("AUGraphInitialize\n");
								
    // now that we've set everything up we can initialize the graph, this will also validate the connections
	result = AUGraphInitialize(mGraph);
    if (result) { printf("AUGraphInitialize result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    CAShow(mGraph);
}

// load up audio data from the demo file into mSoundBuffer.data which is then used in the render proc as the source data to render
- (void)loadSpeechTrack:(Float64)inGraphSampleRate
{
    mUserData.frameNum = 0;
    mUserData.maxNumFrames = 0;
        
    printf("loadSpeechTrack, %d\n", 1);
    
    ExtAudioFileRef xafref = 0;
    
    // open one of the two source files
    OSStatus result = ExtAudioFileOpenURL(sourceURL, &xafref);
    if (result || !xafref) { printf("ExtAudioFileOpenURL result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // get the file data format, this represents the file's actual data format, we need to know the actual source sample rate
    // note that the client format set on ExtAudioFile is the format of the date we really want back
    CAStreamBasicDescription fileFormat;
    UInt32 propSize = sizeof(fileFormat);
    
    result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
    if (result) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    printf("file %d, native file format\n", 1);
    fileFormat.Print();
        
    // get the file's length in sample frames
    UInt64 numFrames = 0;
    propSize = sizeof(numFrames);
    result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
    if (result) { printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    // account for any sample rate conversion between the file and client sample rates
    double rateRatio = mClientFormat.mSampleRate / fileFormat.mSampleRate;
    numFrames *= rateRatio;
    
    // set the client format to be what we want back -- this is the same format audio we're giving to the input callback
    result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, sizeof(mClientFormat), &mClientFormat);
    if (result) { printf("ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }

    // set up and allocate memory for the source buffer
    mUserData.soundBuffer[0].numFrames = numFrames;
    mUserData.soundBuffer[0].asbd = mClientFormat;

    UInt32 samples = numFrames * mUserData.soundBuffer[0].asbd.mChannelsPerFrame;
    mUserData.soundBuffer[0].data = (AudioSampleType *)calloc(samples, sizeof(AudioSampleType));
    
    // set up a AudioBufferList to read data into
    AudioBufferList bufList;
    bufList.mNumberBuffers = 1;
    bufList.mBuffers[0].mNumberChannels = mUserData.soundBuffer[0].asbd.mChannelsPerFrame;
    bufList.mBuffers[0].mData = mUserData.soundBuffer[0].data;
    bufList.mBuffers[0].mDataByteSize = samples * sizeof(AudioSampleType);

    // perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
    UInt32 numPackets = numFrames;
    result = ExtAudioFileRead(xafref, &numPackets, &bufList);
    if (result) {
        printf("ExtAudioFileRead result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); 
        free(mUserData.soundBuffer[0].data);
        mUserData.soundBuffer[0].data = 0;
        return;
    }
    
    // update after the read to reflect the real number of frames read into the buffer
    // note that ExtAudioFile will automatically trim the 2112 priming frames off the AAC demo source
    mUserData.soundBuffer[0].numFrames = numPackets;
    
    // maxNumFrames is used to know when we need to loop the source
    mUserData.maxNumFrames = mUserData.soundBuffer[0].numFrames;
    
    // close the file and dispose the ExtAudioFileRef
    ExtAudioFileDispose(xafref);
}

#pragma mark-

// enable or disables a specific bus
- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue
{
    printf("BUS %ld isON %f\n", (long)inputNum, isONValue);
         
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }

}

// sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value
{
    printf("BUS %ld volume %f\n", (long)inputNum, value);
    
	OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
}

// sets the overall mixer output volume
- (void)setOutputVolume:(AudioUnitParameterValue)value
{
    printf("Output volume %f\n", value);
        
	OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
}

// sets the rate of the timepitch Audio Unit
- (void)setTimeRate:(AudioUnitParameterValue)value
{
    printf("Set rate %f\n", value);
    
    OSStatus result = AudioUnitSetParameter(mTimeAU, kTimePitchParam_Rate, kAudioUnitScope_Global, 0, value, 0);
    if (result) { printf("AudioUnitSetParameter kTimePitchParam_Rate Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
}

// return the levels from the multichannel mixer
- (Float32)getMeterLevel
{
    Float32 value = -120.0;
    
    OSStatus result = AudioUnitGetParameter(mMixer, kMultiChannelMixerParam_PostAveragePower, kAudioUnitScope_Input, 0, &value);
    if (result) { printf("AudioUnitGetParameter kMultiChannelMixerParam_PostAveragePower Input result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
    
    return value;
}

// start or stop graph
- (void)runAUGraph
{
    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if (result) { printf("AUGraphIsRunning result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    
    if (isRunning) {
        printf("STOP\n");
        
        result = AUGraphStop(mGraph);
        if (result) { printf("AUGraphStop result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    } else {
        printf("PLAY\n");
    
        result = AUGraphStart(mGraph);
        if (result) { printf("AUGraphStart result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); return; }
    }
}

@end