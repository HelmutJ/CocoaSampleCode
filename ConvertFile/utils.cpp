/*	Copyright � 2010 Apple Inc. All Rights Reserved.
	
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

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <AudioToolbox/AudioToolbox.h>
#else
	#include "AudioToolbox.h"
	#include <stdlib.h>
	#include <QTML.h>
	#include "QTLicensedTech.h" // So we can access the AAC aenc
	#include "CAWindows.h"
#endif

#include "CAXException.h"
#include "CAStreamBasicDescription.h"

// external to this file the following function needs to be defined
int ConvertFile (CFURLRef					inputFileURL, 
				CAStreamBasicDescription	&inputFormat,
				CFURLRef					outputFileURL,
				AudioFileTypeID				outputFileType, 
				CAStreamBasicDescription	&outputFormat,
				UInt32                      outputBitRate);


void UsageString(int exitCode)
{
	printf ("Usage: ConvertFile /path/to/input/file [-d formatID] [-r sampleRate] [-bd bitDepth] [-f fileType] [-b bitrate] [-h]\n");
	printf ("    output file written is /tmp/outfile.<EXT FOR FORMAT>\n");
	printf ("    if -d is specified, out file is written with that format\n");
	printf ("       if no format is specified and input file is 'lpcm', IMA is written\n");
	printf ("       if input file is compressed (ie. not 'lpcm'), then 'lpcm' is written\n");
	printf ("    if -r is specified, input file's format must be ('lpcm') and output ('lpcm') is written with new sample rate\n");
	printf ("    if -bd is specified, input file's format must be compressed (ie. not 'lpcm') and output is written with new bit depth\n");
	printf ("    if -f is not specified, CAF File is written ('caff')\n");
	printf ("    if -b is specified, the bit rate for the output file when using a VBR encoder\n");
	printf ("    if -h is specified, will print out this usage message\n");
	exit(exitCode);
}

void str2OSType (const char * inString, OSType &outType)
{
	if (inString == NULL) {
		outType = 0;
		return;
	}
	
	size_t len = strlen(inString);
	if (len <= 4) {
		char workingString[5];
		
		workingString[4] = 0;
		workingString[0] = workingString[1] = workingString[2] = workingString[3] = ' ';
		memcpy (workingString, inString, strlen(inString));
		outType = 	*(workingString + 0) <<	24	|
					*(workingString + 1) <<	16	|
					*(workingString + 2) <<	8	|
					*(workingString + 3);
		return;
	}

	if (len <= 8) {
		int32_t tmp;
		if (sscanf (inString, "%x", &tmp) == 0) {
			printf ("* * Bad conversion for OSType\n"); 
			UsageString(1);
		}
		outType = tmp;
		
		return;
	}
	printf ("* * Bad conversion for OSType\n"); 
	UsageString(1);
}

void ParseArgs (int argc, char * const argv[], 
					AudioFileTypeID	&	outFormat, 
					Float64	&			outSampleRate,
					OSType	&			outFileType,
					CFURLRef&			outInputFileURL,
					CFURLRef&			outOutputFileURL,
					UInt32  &			outBitDepth,
					UInt32  &			outBitRate)
{
	if (argc < 2) {
		printf ("No Input File specified\n");
		UsageString(1);
	}
	
	// support "ConvertFile -h" usage
	if (argc == 2 && !strcmp("-h", argv[1])) {
		UsageString(0);
	}
	
	// first validate our initial condition
	const char* inputFileName = argv[1];
	
	outInputFileURL = CFURLCreateFromFileSystemRepresentation (kCFAllocatorDefault, (const UInt8 *)inputFileName, strlen(inputFileName), false);
	if (!outInputFileURL) {
		printf ("* * Bad input file path\n"); 
		UsageString(1);
    }
	
	outBitRate = 0;
	outBitDepth = 0;
	
	// look to see if a format or different file output has been specified
	for (int i = 2; i < argc; ++i) {
		if (!strcmp ("-d", argv[i])) {
			str2OSType (argv[++i], outFormat);
			outSampleRate = 0;
		}
		else if (!strcmp ("-r", argv[i])) {
			sscanf (argv[++i], "%lf", &outSampleRate);
			outFormat = 0;
		}
		else if (!strcmp("-bd", argv[i])) {
			int temp;
			sscanf (argv[++i], "%d", &temp);
			outBitDepth = temp;
		}
		else if (!strcmp ("-f", argv[i])) {
			str2OSType (argv[++i], outFileType);
		}
		else if (!strcmp ("-b", argv[i])) {
			int temp;
			sscanf (argv[++i], "%u", &temp);
			outBitRate = temp;
		}
		else if (!strcmp ("-h", argv[i])) {
			UsageString(0);
		}
		else {
			printf ("* * Unknown command: %s\n", argv[i]); 
			UsageString(1);
		}
	}
	
// output file
	UInt32 size = sizeof(CFArrayRef);
	CFArrayRef extensions;
	OSStatus err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_ExtensionsForType,
				sizeof(OSType), &outFileType,
                &size, &extensions);	
	XThrowIfError (err, "Getting the file extensions for file type");

	// just take the first extension
	CFStringRef ext = (CFStringRef)CFArrayGetValueAtIndex(extensions, 0);
	char extstr[32];
	Boolean res = CFStringGetCString(ext, extstr, 32, kCFStringEncodingUTF8);
	XThrowIfError (!res, "CFStringGetCString");
	
	// release the array as we're done with this now
	CFRelease (extensions);

	char outFname[256];
#if TARGET_OS_WIN32
	char drive[3], dir[256];
	_splitpath_s(inputFileName, drive, 3, dir, 256, NULL, 0, NULL, 0);
	_makepath_s(outFname, 256, drive, dir, "outfile", extstr);
#else
//	char outFname[64];
	sprintf (outFname, "/tmp/outfile.%s", extstr);
#endif
	outOutputFileURL = CFURLCreateFromFileSystemRepresentation (kCFAllocatorDefault, (const UInt8 *)outFname, strlen(outFname), false);
	if (!outOutputFileURL) {
		printf ("* * Bad output file path\n"); 
		UsageString(1);
    }
}

void	GetFormatFromInputFile (AudioFileID inputFile, CAStreamBasicDescription & inputFormat)
{
	bool doPrint = true;
	UInt32 size;
	XThrowIfError(AudioFileGetPropertyInfo(inputFile, 
								kAudioFilePropertyFormatList, &size, NULL), "couldn't get file's format list info");
	UInt32 numFormats = size / sizeof(AudioFormatListItem);
	AudioFormatListItem *formatList = new AudioFormatListItem [ numFormats ];

	XThrowIfError(AudioFileGetProperty(inputFile, 
								kAudioFilePropertyFormatList, &size, formatList), "couldn't get file's data format");
	numFormats = size / sizeof(AudioFormatListItem); // we need to reassess the actual number of formats when we get it
	if (numFormats == 1) {
			// this is the common case
		inputFormat = formatList[0].mASBD;
	} else {
		if (doPrint) {
			printf ("File has a %d layered data format:\n", (int)numFormats);
			for (unsigned int i = 0; i < numFormats; ++i)
				CAStreamBasicDescription(formatList[i].mASBD).Print();
			printf("\n");
		}
		// now we should look to see which decoders we have on the system
		XThrowIfError(AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size), "couldn't get decoder id's");
		UInt32 numDecoders = size / sizeof(OSType);
		OSType *decoderIDs = new OSType [ numDecoders ];
		XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDs), "couldn't get decoder id's");			
		unsigned int i = 0;
		for (; i < numFormats; ++i) {
			OSType decoderID = formatList[i].mASBD.mFormatID;
			bool found = false;
			for (unsigned int j = 0; j < numDecoders; ++j) {
				if (decoderID == decoderIDs[j]) {
					found = true;
					break;
				}
			}
			if (found) break;
		}
		delete [] decoderIDs;
		
		if (i >= numFormats) {
			fprintf (stderr, "Cannot play any of the formats in this file\n");
			throw kAudioFileUnsupportedDataFormatError;
		}
		inputFormat = formatList[i].mASBD;
	}
	delete [] formatList;
}


void	ConstructOutputFormatFromArgs (	CFURLRef inputFileURL, 
										OSType fileType, OSType format, Float64 sampleRate, 
										CAStreamBasicDescription &inputFormat, 
										UInt32 bitDepth, 
										CAStreamBasicDescription &outputFormat)
{
	AudioFileID infile;	
	OSStatus err = AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &infile);
	XThrowIfError (err, "AudioFileOpen");
	
// get the input file format
	GetFormatFromInputFile (infile, inputFormat);

	if (inputFormat.mFormatID != kAudioFormatLinearPCM && sampleRate > 0) {
		printf ("Can only specify sample rate with linear pcm input file\n");
		UsageString(1);
	}
	
// set up the output file format
	if (!format) {
		if (sampleRate > 0) {
			outputFormat = inputFormat;
			outputFormat.mSampleRate = sampleRate;
		} else {
			if (inputFormat.mFormatID != kAudioFormatLinearPCM)
				format = kAudioFormatLinearPCM;
			else
				format = kAudioFormatAppleIMA4;
		}
	}
		
	if (format) {
		if (format == kAudioFormatLinearPCM) {
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
			outputFormat.mBitsPerChannel = (bitDepth) ? bitDepth : 16;

			outputFormat.mBytesPerPacket = inputFormat.mChannelsPerFrame * (outputFormat.mBitsPerChannel / 8);
			outputFormat.mFramesPerPacket = 1;
			outputFormat.mBytesPerFrame = outputFormat.mBytesPerPacket;
	
			if (fileType == kAudioFileWAVEType)
				outputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger
								| kLinearPCMFormatFlagIsPacked;
			else
				outputFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian
									| kLinearPCMFormatFlagIsSignedInteger
									| kLinearPCMFormatFlagIsPacked;
			
		
		} else {
			// need to set at least these fields for kAudioFormatProperty_FormatInfo
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
			
		// use AudioFormat API to fill out the rest.
			UInt32 size = sizeof(outputFormat);
			err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &outputFormat);
            XThrowIfError (err, "AudioFormatGetProperty kAudioFormatProperty_FormatInfo");
		}
	}
	AudioFileClose (infile);
}

int main (int argc, char * const argv[]) 
{
#if TARGET_OS_WIN32
  	QTLicenseRef aacEncoderLicenseRef = nil;
  	QTLicenseRef amrEncoderLicenseRef = nil;
	OSErr localerr;
#endif
	int result = 0;
	CFURLRef inputFileURL = NULL;
	CFURLRef outputFileURL = NULL;

#if TARGET_OS_WIN32
	InitializeQTML(0L);
	{
		OSErr localerr;
		const char *licenseDesc = "AAC Encode License Verification";
		const char *amrLicenseDesc = "AMR Encode License Verification";

		localerr = QTRequestLicensedTechnology("com.apple.quicktimeplayer","com.apple.aacencoder",
					(void *)licenseDesc,strlen(licenseDesc),&aacEncoderLicenseRef);
		localerr = QTRequestLicensedTechnology("com.apple.quicktimeplayer","1D07EB75-3D5E-4DA6-B749-D497C92B06D8",
					(void *)amrLicenseDesc,strlen(amrLicenseDesc),&amrEncoderLicenseRef);
	}
#endif
	
	try {
		OSType format = 0;
		Float64 sampleRate = 0;
		AudioFileTypeID outputFileType = kAudioFileCAFType;
 	  	UInt32 outputBitRate = 0;
		UInt32 outputBitDepth = 0;
		
		ParseArgs (argc, argv, format, sampleRate, outputFileType, inputFileURL, outputFileURL, outputBitDepth, outputBitRate);

	//	printf ("args:%4.4s, sample rate:%.1f, outputFileType: %4.4s\n", (char*)&format, sampleRate, (char*)&outputFileType);

		CAStreamBasicDescription inputFormat;	
		CAStreamBasicDescription outputFormat;	
		ConstructOutputFormatFromArgs (inputFileURL, outputFileType, format, sampleRate, inputFormat, outputBitDepth, outputFormat);
		
		printf ("Source File format:\n\t"); inputFormat.Print();
		printf ("Dest File format:\n\t"); outputFormat.Print();
		
		result = ConvertFile (inputFileURL, inputFormat, outputFileURL, outputFileType, outputFormat, outputBitRate);

		CFStringRef path = CFURLCopyPath(outputFileURL);
		printf("done: "); fflush(stdout); CFShow(path);
		if (path) CFRelease(path);

	} catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error in: %s\nException thrown: %s\n", e.mOperation, e.FormatError(buf));
		result = 1;
	} catch (...) {
		fprintf(stderr, "Unspecified exception\n");
		result = 1;
	}
	if (inputFileURL) CFRelease(inputFileURL);
	if (outputFileURL) CFRelease(outputFileURL);
	
#if TARGET_OS_WIN32
	TerminateQTML();
 	if (aacEncoderLicenseRef)
	{
		localerr = QTReleaseLicensedTechnology(aacEncoderLicenseRef);
		aacEncoderLicenseRef = nil;
	}
	if(amrEncoderLicenseRef)
	{
		localerr = QTReleaseLicensedTechnology(amrEncoderLicenseRef);
		amrEncoderLicenseRef = nil;
	}
#endif	
	return result;
}

