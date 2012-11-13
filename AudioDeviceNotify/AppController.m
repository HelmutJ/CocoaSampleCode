/*
     File: AppController.m 
 Abstract: Demonstrates how to enumerate audio devices attached to the system and how to handle device notification 
  Version: 2.0 
  
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

#import <CoreAudio/CoreAudio.h>
#import "AppController.h"


static OSStatus GetAudioDevices( Ptr * devices, UInt16 * devicesAvailable )
{
    OSStatus err = noErr;
    UInt32   theDataSize = 0;
    
    // find out how many audio devices there are, if any
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
                                              kAudioObjectPropertyScopeGlobal,
                                              kAudioObjectPropertyElementMaster };
    

    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &theAddress, 0, NULL, &theDataSize);
    if ( err != noErr ) return err;
   
    // calculate the number of device available
	*devicesAvailable = theDataSize / (UInt32)sizeof(AudioObjectID);						
    if ( *devicesAvailable < 1 ) {
		fprintf( stderr, "No devices\n" );
		return err;
	}
    
    // make space for the devices we are about to get
    *devices = (Ptr)malloc(theDataSize);
    memset( *devices, 0, theDataSize );
    
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &theDataSize, (void *)*devices);

    return err;
}

OSStatus AOPropertyListenerProc(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void* inClientData)
{
	AppController *app = (AppController*)inClientData;
    
    for (UInt32 x=0; x<inNumberAddresses; x++) {
    
        switch (inAddresses[x].mSelector)
        {
    /*
     * These are the other types of notifications we might receive, however, they are beyond
     * the scope of this sample and we ignore them.
     *
            case kAudioHardwarePropertyDefaultInputDevice:
                fprintf(stderr, "AOPropertyListenerProc: default input device changed\n");
            break;
                
            case kAudioHardwarePropertyDefaultOutputDevice:
                fprintf(stderr, "AOPropertyListenerProc: default output device changed\n");
            break;
                
            case kAudioHardwarePropertyDefaultSystemOutputDevice:
                fprintf(stderr, "AOPropertyListenerProc: default system output device changed\n");
            break;
    */
            case kAudioHardwarePropertyDevices:
            {
                fprintf(stderr, "AOPropertyListenerProc: kAudioHardwarePropertyDevices\n");
                [app performSelectorOnMainThread:@selector(updateDeviceList) withObject:nil waitUntilDone:NO];
            }
            break;
                
            default:
                fprintf(stderr, "AOPropertyListenerProc: unknown message\n");
            break;
        }
    }
    
	return noErr;
}

@implementation AppController

-(void) awakeFromNib
{
	// create empty array to hold device info
	deviceArray = [[NSMutableArray alloc] init];
	if(!deviceArray)
		return;

	// generate initial device list
	[self updateDeviceList];
	
	// install kAudioHardwarePropertyDevices notification listener
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
                                              kAudioObjectPropertyScopeGlobal,
                                              kAudioObjectPropertyElementMaster };
    
    AudioObjectAddPropertyListener(kAudioObjectSystemObject, &theAddress, AOPropertyListenerProc, self);
}

- (void)windowWillClose:(NSNotification *)notification
{
	// remove kAudioHardwarePropertyDevices notification listener
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
                                              kAudioObjectPropertyScopeGlobal,
                                              kAudioObjectPropertyElementMaster };
    
    AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &theAddress, AOPropertyListenerProc, self);
}

- (void)updateDeviceList
{
    OSStatus	err = noErr;
    UInt32 		ioSize = 0;
	UInt32      theNumberInputChannels  = 0;
	UInt32      theNumberOutputChannels = 0;
	UInt32      theIndex = 0;
    UInt16		devicesAvailable = 0;
	UInt16		loopCount = 0;
    AudioDeviceID	*devices = NULL;
	AudioBufferList *theBufferList = NULL;
	CFNumberRef		tempNumberRef = NULL;
	CFStringRef		tempStringRef = NULL;
	
	// clear out any current entries in device array
	[deviceArray removeAllObjects];
	
	// fetch a pointer to the list of available devices
	if(GetAudioDevices((Ptr*)&devices, &devicesAvailable) != noErr)
		return;
	
	// iterate over each device gathering information
	for(loopCount = 0; loopCount < devicesAvailable; loopCount++)
	{
		CFMutableDictionaryRef theDict = NULL;
		UInt16 deviceID = devices[loopCount];
		
		// create dictionary to hold device info
		theDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ( theDict == NULL )
		{
			fprintf(stderr, "Dictionary Creation Failed\n" );
			return;
		}

		// save device id
		tempNumberRef = CFNumberCreate(kCFAllocatorDefault,kCFNumberShortType,&deviceID);
		if(tempNumberRef)
		{
			CFDictionarySetValue(theDict, CFSTR("id"), tempNumberRef);
			CFRelease(tempNumberRef);
		}
		
		// get device name
        AudioObjectPropertyAddress theAddress = { kAudioObjectPropertyName,
                                                  kAudioObjectPropertyScopeGlobal,
                                                  kAudioObjectPropertyElementMaster };
                                                  
		ioSize = sizeof(CFStringRef);
        err = AudioObjectGetPropertyData(devices[loopCount], &theAddress, 0, NULL, &ioSize, &tempStringRef);
		if(tempStringRef && noErr == err)
		{
			CFDictionarySetValue(theDict, CFSTR("name"), tempStringRef);
			CFRelease(tempStringRef);
		}
        
        // get number of input channels
        ioSize = 0;
        theNumberInputChannels = 0;
        
        theAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
        theAddress.mScope =  kAudioObjectPropertyScopeInput;
        theAddress.mElement = 0;
        
        err = AudioObjectGetPropertyDataSize(devices[loopCount], &theAddress, 0, NULL, &ioSize);
		if((err == noErr) && (ioSize != 0))
		{
			theBufferList = (AudioBufferList*)malloc(ioSize);
			if(theBufferList != NULL)
			{
				// get the input stream configuration
                err = AudioObjectGetPropertyData(devices[loopCount], &theAddress, 0, NULL, &ioSize, theBufferList);
				if(err == noErr)
				{
					// count the total number of input channels in the stream
					for(theIndex = 0; theIndex < theBufferList->mNumberBuffers; ++theIndex)
                            theNumberInputChannels += theBufferList->mBuffers[theIndex].mNumberChannels;
				}
				free(theBufferList);
				tempNumberRef = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt32Type,&theNumberInputChannels);
				if(tempNumberRef) {
					CFDictionarySetValue(theDict, CFSTR("ich"), tempNumberRef);
                    CFRelease(tempNumberRef);
                }
			}
		}
        
        // get number of output channels
		ioSize = 0;
		theNumberOutputChannels = 0;
        
        theAddress.mScope = kAudioObjectPropertyScopeOutput;
        
        err = AudioObjectGetPropertyDataSize(devices[loopCount], &theAddress, 0, NULL, &ioSize);
		if((err == noErr) && (ioSize != 0))
		{
			theBufferList = (AudioBufferList*)malloc(ioSize);
			if(theBufferList != NULL)
			{
				// get the input stream configuration
                err = AudioObjectGetPropertyData(devices[loopCount], &theAddress, 0, NULL, &ioSize, theBufferList);
				if(err == noErr)
				{
					// count the total number of output channels in the stream
					for(theIndex = 0; theIndex < theBufferList->mNumberBuffers; ++theIndex)
                            theNumberOutputChannels += theBufferList->mBuffers[theIndex].mNumberChannels;
				}
				free(theBufferList);
				tempNumberRef = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt32Type,&theNumberOutputChannels);
				if(tempNumberRef) {
					CFDictionarySetValue(theDict, CFSTR("och"), tempNumberRef);
                    CFRelease(tempNumberRef);
                }
			}
        }
		
		[deviceArray addObject:(NSDictionary*)theDict];
		CFRelease(theDict);
	}
    
	[myTable reloadData];
}

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [deviceArray count];
}

- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
      row:(int)rowIndex
{
	NSDictionary *deviceDict = NULL;
	
	deviceDict = [deviceArray objectAtIndex:rowIndex];
	return [deviceDict objectForKey:[aTableColumn identifier]];
}

@end
