/*	Copyright � 2007 Apple Inc. All Rights Reserved.
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
			Apple Inc. ("Apple") in consideration of your agreement to the
			following terms, and your use, installation, modification or
			redistribution of this Apple software constitutes acceptance of these
			terms.  If you do not agree with these terms, please do not use,
			install, modify or redistribute this Apple software.
			
			In consideration of your agreement to abide by the following terms, and
			subject to these terms, Apple grants you a personal, non-exclusive
			license, under Apple's copyrights in this original Apple software (the
			"Apple Software"), to use, reproduce, modify and redistribute the Apple
			Software, with or without modifications, in source and/or binary forms;
			provided that if you redistribute the Apple Software in its entirety and
			without modifications, you must retain this notice and the following
			text and disclaimers in all such redistributions of the Apple Software. 
			Neither the name, trademarks, service marks or logos of Apple Inc. 
			may be used to endorse or promote products derived from the Apple
			Software without specific prior written permission from Apple.  Except
			as expressly stated in this notice, no other rights or licenses, express
			or implied, are granted by Apple herein, including but not limited to
			any patent rights that may be infringed by your derivative works or by
			other works in which the Apple Software may be incorporated.
			
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
*/
#include <AudioToolbox/AudioToolbox.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "CAAudioUnit.h"

void UsageString(int exitCode)
{
	printf ("Usage: PlayFile /path/to/file\n");
	exit(exitCode);
}

// helper functions
double PrepareFileAU (CAAudioUnit &au, CAStreamBasicDescription &fileFormat, AudioFileID audioFile);
void MakeSimpleGraph (AUGraph &theGraph, CAAudioUnit &fileAU, CAStreamBasicDescription &fileFormat, AudioFileID audioFile);


int main (int argc, char * const argv[]) 
{
	if (argc < 2) UsageString(1);

	AudioFileID audioFile;
	
	const char* inputFile = argv[1];

	CFURLRef theURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8*)inputFile, strlen(inputFile), false);
    XThrowIfError (!theURL, "CFURLCreateFromFileSystemRepresentation");
	
    OSStatus err = AudioFileOpenURL (theURL, kAudioFileReadPermission, 0, &audioFile);
    CFRelease(theURL);
	XThrowIfError (err, "AudioFileOpenURL");
			
			// get the number of channels of the file
	CAStreamBasicDescription fileFormat;
	UInt32 propsize = sizeof(CAStreamBasicDescription);
	XThrowIfError (AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat, &propsize, &fileFormat), "AudioFileGetProperty");
	
	printf ("playing file: %s\n", inputFile);
	printf ("format: "); fileFormat.Print();


// lets set up our playing state now
	AUGraph theGraph;
	CAAudioUnit fileAU;

// this makes the graph, the file AU and sets it all up for playing
	MakeSimpleGraph (theGraph, fileAU, fileFormat, audioFile);
		

// now we load the file contents up for playback before we start playing
// this has to be done the AU is initialized and anytime it is reset or uninitialized
	Float64 fileDuration = PrepareFileAU (fileAU, fileFormat, audioFile);
		printf ("file duration: %f secs\n", fileDuration);

// start playing
	XThrowIfError (AUGraphStart (theGraph), "AUGraphStart");
	
// sleep until the file is finished
	usleep ((int)(fileDuration * 1000. * 1000.));

// lets clean up
	XThrowIfError (AUGraphStop (theGraph), "AUGraphStop");
	XThrowIfError (AUGraphUninitialize (theGraph), "AUGraphUninitialize");
	XThrowIfError (AudioFileClose (audioFile), "AudioFileClose");
	XThrowIfError (AUGraphClose (theGraph), "AUGraphClose");
	
	return 0;
}	

double PrepareFileAU (CAAudioUnit &au, CAStreamBasicDescription &fileFormat, AudioFileID audioFile)
{	
// 
		// calculate the duration
	UInt64 nPackets;
	UInt32 propsize = sizeof(nPackets);
	XThrowIfError (AudioFileGetProperty(audioFile, kAudioFilePropertyAudioDataPacketCount, &propsize, &nPackets), "kAudioFilePropertyAudioDataPacketCount");
		
	Float64 fileDuration = (nPackets * fileFormat.mFramesPerPacket) / fileFormat.mSampleRate;

	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = audioFile;
	rgn.mLoopCount = 1;
	rgn.mStartFrame = 0;
	rgn.mFramesToPlay = UInt32(nPackets * fileFormat.mFramesPerPacket);
		
		// tell the file player AU to play all of the file
	XThrowIfError (au.SetProperty (kAudioUnitProperty_ScheduledFileRegion, 
			kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)), "kAudioUnitProperty_ScheduledFileRegion");
	
		// prime the fp AU with default values
	UInt32 defaultVal = 0;
	XThrowIfError (au.SetProperty (kAudioUnitProperty_ScheduledFilePrime, 
			kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)), "kAudioUnitProperty_ScheduledFilePrime");

		// tell the fp AU when to start playing (this ts is in the AU's render time stamps; -1 means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	XThrowIfError (au.SetProperty(kAudioUnitProperty_ScheduleStartTimeStamp, 
			kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)), "kAudioUnitProperty_ScheduleStartTimeStamp");

	return fileDuration;
}



void MakeSimpleGraph (AUGraph &theGraph, CAAudioUnit &fileAU, CAStreamBasicDescription &fileFormat, AudioFileID audioFile)
{
	XThrowIfError (NewAUGraph (&theGraph), "NewAUGraph");
	
	CAComponentDescription cd;

	// output node
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_DefaultOutput;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;

	AUNode outputNode;
	XThrowIfError (AUGraphAddNode (theGraph, &cd, &outputNode), "AUGraphAddNode");
	
	// file AU node
	AUNode fileNode;
	cd.componentType = kAudioUnitType_Generator;
	cd.componentSubType = kAudioUnitSubType_AudioFilePlayer;
	
	XThrowIfError (AUGraphAddNode (theGraph, &cd, &fileNode), "AUGraphAddNode");
	
	// connect & setup
	XThrowIfError (AUGraphOpen (theGraph), "AUGraphOpen");
	
	// install overload listener to detect when something is wrong
	AudioUnit anAU;
	XThrowIfError (AUGraphNodeInfo(theGraph, fileNode, NULL, &anAU), "AUGraphNodeInfo");
	
	fileAU = CAAudioUnit (fileNode, anAU);

// prepare the file AU for playback
// set its output channels
	XThrowIfError (fileAU.SetNumberChannels (kAudioUnitScope_Output, 0, fileFormat.NumberChannels()), "SetNumberChannels");

// set the output sample rate of the file AU to be the same as the file:
	XThrowIfError (fileAU.SetSampleRate (kAudioUnitScope_Output, 0, fileFormat.mSampleRate), "SetSampleRate");

// load in the file 
	XThrowIfError (fileAU.SetProperty(kAudioUnitProperty_ScheduledFileIDs, 
						kAudioUnitScope_Global, 0, &audioFile, sizeof(audioFile)), "SetScheduleFile");


	XThrowIfError (AUGraphConnectNodeInput (theGraph, fileNode, 0, outputNode, 0), "AUGraphConnectNodeInput");

// AT this point we make sure we have the file player AU initialized
// this also propogates the output format of the AU to the output unit
	XThrowIfError (AUGraphInitialize (theGraph), "AUGraphInitialize");
	
	// workaround a race condition in the file player AU
	usleep (10 * 1000);

// if we have a surround file, then we should try to tell the output AU what the order of the channels will be
	if (fileFormat.NumberChannels() > 2) {
		UInt32 layoutSize = 0;
		OSStatus err;
		XThrowIfError (err = AudioFileGetPropertyInfo (audioFile, kAudioFilePropertyChannelLayout, &layoutSize, NULL),
								"kAudioFilePropertyChannelLayout");
		
		if (!err && layoutSize) {
			char* layout = new char[layoutSize];
			
			err = AudioFileGetProperty(audioFile, kAudioFilePropertyChannelLayout, &layoutSize, layout);
			XThrowIfError (err, "Get Layout From AudioFile");
			
			// ok, now get the output AU and set its layout
			XThrowIfError (AUGraphNodeInfo(theGraph, outputNode, NULL, &anAU), "AUGraphNodeInfo");
			
			err = AudioUnitSetProperty (anAU, kAudioUnitProperty_AudioChannelLayout, 
							kAudioUnitScope_Input, 0, layout, layoutSize);
			XThrowIfError (err, "kAudioUnitProperty_AudioChannelLayout");
			
			delete [] layout;
		}
	}
}