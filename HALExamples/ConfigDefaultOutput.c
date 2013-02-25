/*	Copyright © 2007 Apple Inc. All Rights Reserved.
	
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
#include <stdio.h>

#include <CoreAudio/CoreAudio.h>

static void usage()
{
	fprintf(stderr,
			"Usage:\n"
			"%s [option...] input_file output_file\n\n"
			"Options: (may appear before or after arguments)\n"
			"  {-a | --all}\n"
			"  {-d | --device} DEVICE\n"
			"    set DEVICE as the default output device\n"
			"    print all known devices on the system\n"
			"  {-v | --volume} VOLUME\n"
			"    set the volume for the default output device\n"
			"  {-m | --mute} MUTE\n"
			"    set mute on (1) or off (0) for the default output device\n"
			"  {-h | --help}\n"
			"    print help\n"
			, "ConfigDefaultOutput");
	exit(1);
}

void	MissingArgument()
{
	fprintf(stderr, "Missing argument\n");
	usage();
}

int main (int argc, const char * argv[]) 
{
	OSStatus result = noErr;
	Float32 theVolume = 0.0;
	UInt32	theMute = 0;
	Boolean doSetMute = false, doPrintDeviceList = false;
	const char* theNewDefaultDeviceString = NULL;
	Boolean didFindNewDevice = false;
	CFStringRef theNewDefaultDeviceName = 0;
	
	for (int i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		if (arg[0] != '-') {
			usage();
		} else {
			arg += 1;
			if (arg[0] == 'v' || !strcmp(arg, "-volume")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];
				sscanf(arg, "%f", &theVolume);
			} else if (arg[0] == 'm' || !strcmp(arg, "-mute")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];
				doSetMute = true;
				sscanf(arg, "%d", &theMute);
			} else if (arg[0] == 'd' || !strcmp(arg, "-device")) {
				if (++i == argc)
					MissingArgument();
				theNewDefaultDeviceString = argv[i];
				theNewDefaultDeviceName = CFStringCreateWithCString(kCFAllocatorDefault, theNewDefaultDeviceString, CFStringGetSystemEncoding());
			} else if (arg[0] == 'a' || !strcmp(arg, "-all")) {
				doPrintDeviceList = true;
			} else if (arg[0] == 'h' || !strcmp(arg, "-help")) {
				usage();
			} else {
				fprintf(stderr, "unknown argument: %s\n\n", arg - 1);
				usage();
			}
		}
	}
	UInt32 thePropSize;
	AudioDeviceID *theDeviceList = NULL;
	UInt32 theNumDevices = 0;	
	
	if (doPrintDeviceList || theNewDefaultDeviceString)
	{
		// get the device list	
		AudioObjectPropertyAddress thePropertyAddress = { kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
		result = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &thePropSize);
		if (result) { printf("Error in AudioObjectGetPropertyDataSize: %d\n", result); goto end; }
		
		// Find out how many devices are on the system
		theNumDevices = thePropSize / sizeof(AudioDeviceID);
		theDeviceList = (AudioDeviceID*)calloc(theNumDevices, sizeof(AudioDeviceID));
		
		result = AudioObjectGetPropertyData(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &thePropSize, theDeviceList);
		if (result) { printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end; }
		
		CFStringRef theDeviceName;		
		for (UInt32 i=0; i < theNumDevices; i++)
		{
			// get the device name
			thePropSize = sizeof(CFStringRef);
			thePropertyAddress.mSelector = kAudioObjectPropertyName;
			thePropertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
			thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
			
			result = AudioObjectGetPropertyData(theDeviceList[i], &thePropertyAddress, 0, NULL, &thePropSize, &theDeviceName);
			if (result) { printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end; }
			
			if (doPrintDeviceList)
				CFShow(theDeviceName);
			
			if (theNewDefaultDeviceString)
			{
				if (CFStringCompare(theDeviceName, theNewDefaultDeviceName, 0) == kCFCompareEqualTo)
				{
					// we found the device, now it as the default output device
					thePropertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
					thePropertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
					thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
					
					result = AudioObjectSetPropertyData(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, sizeof(AudioDeviceID), &theDeviceList[i]);
					if (result) { printf("Error in AudioObjectSetPropertyData: kAudioHardwarePropertyDefaultOutputDevice: %d\n", result); goto end; }
					else
					{
						didFindNewDevice = true;
						printf("\tSuccessfully changed default output device to %s\n", theNewDefaultDeviceString);
						if (!doPrintDeviceList) break;
					}
				}
			}
			
			CFRelease(theDeviceName);		
		}
		
		if (theNewDefaultDeviceString) 
		{
			if (!didFindNewDevice)
				printf("Error! Could not find specified device %s. Using current default output device\n", theNewDefaultDeviceString);
							
			CFRelease(theNewDefaultDeviceName);
		}
		
	}
		
	if (doSetMute || theVolume > 0.)
	{
		AudioDeviceID theDefaultOutputDeviceID;
		thePropSize = sizeof(theDefaultOutputDeviceID);
		CFStringRef theDefaultOutputDeviceName;
		 
		AudioObjectPropertyAddress thePropertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };

		// get the ID of the default output device
		result = AudioObjectGetPropertyData(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &thePropSize, &theDefaultOutputDeviceID);
		if (result) { printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end; }

		thePropSize = sizeof(CFStringRef);
		thePropertyAddress.mSelector = kAudioObjectPropertyName;
		thePropertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
		thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;

		// get the name of the default output device
		result = AudioObjectGetPropertyData(theDefaultOutputDeviceID, &thePropertyAddress, 0, NULL, &thePropSize, &theDefaultOutputDeviceName);
		if (result) { printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end; }
		
		const char* theDefaultOutputDeviceString = CFStringGetCStringPtr(theDefaultOutputDeviceName, CFStringGetSystemEncoding());
		
		if (doSetMute)
		{
			thePropSize = sizeof(theMute);
			thePropertyAddress.mSelector = kAudioDevicePropertyMute;
			thePropertyAddress.mScope = kAudioDevicePropertyScopeOutput;	
			thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
			
			// check if the device supports setting mute		
			if (AudioObjectHasProperty(theDefaultOutputDeviceID, &thePropertyAddress))
			{
				printf("\tSetting %s mute %s\n", theDefaultOutputDeviceString, (theMute) ? "on" : "off");
				// if so then set it
				result = AudioObjectSetPropertyData(theDefaultOutputDeviceID, &thePropertyAddress, 0, NULL, thePropSize, &theMute);
				if (result) { printf("Error in AudioObjectSetPropertyData: %d\n", result); goto end; }
			}
			
			else
			{
				// if the device does not support master mute control, do nothing
				printf("Error: the default output device does not support mute control\n");
			}
		}
		
		if (theVolume > 0.)
		{
			thePropSize = sizeof(theVolume);
			thePropertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
			thePropertyAddress.mScope = kAudioDevicePropertyScopeOutput;	
			thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
			// see if the device supports volume control, if so, then set the user specified volume
			if (AudioObjectHasProperty(theDefaultOutputDeviceID, &thePropertyAddress))
			{
				printf("\tSetting %s volume to %g\n", theDefaultOutputDeviceString, theVolume);
				result = AudioObjectSetPropertyData(theDefaultOutputDeviceID, &thePropertyAddress, 0, NULL, thePropSize, &theVolume);
				if (result) { printf("Error in AudioObjectSetPropertyData: %d\n", result); goto end; }
			}
			else
			{
				// if the device does not support master volume control, do nothing
				printf("Error: the default output device does not support volume control\n");
			}
		}
		
		CFRelease(theDefaultOutputDeviceName);
	}
	
end:
	if (theDeviceList)
		free(theDeviceList);
   
	 return result;
}
