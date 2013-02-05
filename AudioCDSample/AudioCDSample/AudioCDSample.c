/*
     File: AudioCDSample.c
 Abstract: Command-line tool demonstrating how to discover audio CDs and
 access the TOC information presented by the CD-DA filesystem.
  Version: 1.5
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
*/

#include <CoreFoundation/CoreFoundation.h>
#include <Carbon/Carbon.h>
#include <IOKit/storage/IOCDTypes.h>
#include <string.h>

// Constants
#define kAudioCDFilesystemID		(UInt16)(('J' << 8) | 'H' ) // 'JH'; this avoids compiler warning

// XML property list keys. These constants are not defined in any public header file.
#define kRawTOCDataString			"Format 0x02 TOC Data"
#define kSessionsString				"Sessions"
#define kSessionTypeString			"Session Type"
#define kTrackArrayString			"Track Array"
#define kFirstTrackInSessionString	"First Track"
#define kLastTrackInSessionString	"Last Track"
#define kLeadoutBlockString			"Leadout Block"
#define	kDataKeyString 				"Data"
#define kPointKeyString				"Point"
#define kSessionNumberKeyString		"Session Number"
#define kStartBlockKeyString		"Start Block"

// Disc/session types
#define kDiscTypeCDDA_CDROM			0x00
#define kDiscTypeCD_I				0x10
#define kDiscTypeCDROM_XA			0x20

void PrintTOCData(const FSRef *theFSRef);

void PrintTOCData(const FSRef *theFSRef)
{
    HFSUniStr255		dataForkName;
    OSErr				result;
    FSIORefNum			forkRefNum;
    SInt64				forkSize;
    UInt8				*forkData;
    ByteCount			actualRead;
    CFDataRef			dataRef = 0;
    CFPropertyListRef	propertyListRef = 0;

    // Open the hidden TOC data plist and read the data from it.
	 
	result = FSGetDataForkName(&dataForkName);
    if (result != noErr) {
        fprintf(stderr, "FSGetDataForkName() returned %d\n", result);
        return;
    }
    
    result = FSOpenFork(theFSRef, dataForkName.length, dataForkName.unicode, fsRdPerm, &forkRefNum);
    if (result != noErr) {
        fprintf(stderr, "FSOpenFork() returned %d\n", result);
        return;
    }
    
    // How large is the plist data?
	result = FSGetForkSize(forkRefNum, &forkSize);
    if (result != noErr) {
        fprintf(stderr, "FSGetForkSize() returned %d\n", result);
        return;
    }
    
    // Allocate memory for the plist data.
    forkData = malloc(forkSize);
    if (forkData == NULL) {
        fprintf(stderr, "malloc() returned NULL while allocating memory for plist data\n");
        return;
    }
    
    result = FSReadFork(forkRefNum, fsFromStart, 0, forkSize, forkData, &actualRead);
    if (result != noErr) {
        fprintf(stderr, "FSReadFork() returned %d\n", result);
        
		free(forkData);
		FSCloseFork(forkRefNum);
		return;
    }
    
	// Done with the plist file.
	FSCloseFork(forkRefNum);
    
	// Turn the raw plist data into a CFData object.
	dataRef = CFDataCreate(kCFAllocatorDefault, forkData, forkSize);
    if (dataRef != 0) {
        CFStringRef	errorString;
        
        // Now turn the CFData into a CFPropertyList that we can parse using other CoreFoundation calls.
		propertyListRef = CFPropertyListCreateFromXMLData(kCFAllocatorDefault,
														  dataRef,
														  kCFPropertyListImmutable,
														  &errorString);
														  
        // Ignore the error string if we get one back.
		if (errorString != 0) {
			CFRelease(errorString);
		}
		
		// Now done with the CFData.
		CFRelease(dataRef);
	}
	
	if (propertyListRef != 0) {
        // Now we have the property list in memory. Parse it.
        
        // First, make sure the root item is a CFDictionary. If not, release and bail.
        if (CFGetTypeID(propertyListRef) == CFDictionaryGetTypeID()) {
		
            CFDataRef	theRawTOCDataRef = 0;
            CFArrayRef	theSessionArrayRef = 0;
            CFIndex		numSessions = 0;
            UInt32		index = 0;
            
            // This is how we can get the raw TOC data. You can use the routines in <IOKit/storage/IOCDTypes.h>
			// to access the contents of the raw TOC data.
            theRawTOCDataRef = (CFDataRef) CFDictionaryGetValue(propertyListRef, CFSTR(kRawTOCDataString));
            
            UInt32 descriptorCount = CDTOCGetDescriptorCount((CDTOC *)CFDataGetBytePtr(theRawTOCDataRef));
            printf("Descriptor count = %u\n\n", descriptorCount);
            
            // Get the session array info.
            theSessionArrayRef = (CFArrayRef) CFDictionaryGetValue(propertyListRef, CFSTR(kSessionsString));
            
            // Find out how many sessions there are.
            numSessions = CFArrayGetCount(theSessionArrayRef);
            
            printf("Number of sessions = %u\n\n", (UInt32) numSessions);
            
            // Iterate across the sessions on the disc.
			for (index = 0; index < numSessions; index++) {
                    
                CFDictionaryRef	theSessionDict = 0;
                CFNumberRef		firstTrackNumber = 0;
                CFNumberRef		lastTrackNumber = 0;
                CFNumberRef		leadoutBlock = 0;
                CFNumberRef		sessionNumber = 0;
                CFNumberRef		sessionType = 0;
                CFArrayRef		trackArray = 0;
                CFIndex			numTracks = 0;
                UInt32			trackIndex = 0;
                UInt32			value = 0;
                
                theSessionDict = (CFDictionaryRef) CFArrayGetValueAtIndex(theSessionArrayRef, index);
                firstTrackNumber = (CFNumberRef) CFDictionaryGetValue(theSessionDict, CFSTR(kFirstTrackInSessionString));
                lastTrackNumber = (CFNumberRef) CFDictionaryGetValue(theSessionDict, CFSTR(kLastTrackInSessionString));
                leadoutBlock = (CFNumberRef) CFDictionaryGetValue(theSessionDict, CFSTR(kLeadoutBlockString));
				sessionType = (CFNumberRef) CFDictionaryGetValue(theSessionDict, CFSTR(kSessionTypeString));
				sessionNumber = (CFNumberRef) CFDictionaryGetValue(theSessionDict, CFSTR(kSessionNumberKeyString));
                
                if (CFNumberGetValue(sessionNumber, kCFNumberSInt32Type, &value)) {
                    printf("-----------------------------------\n");
                    printf("Session Number %u\n", value);
                    printf("-----------------------------------\n");
                }
                
                if (CFNumberGetValue(firstTrackNumber, kCFNumberSInt32Type, &value)) {
                    printf("First Track in session = %u\n", value);
                }
                
                if (CFNumberGetValue(lastTrackNumber, kCFNumberSInt32Type, &value)) {
                    printf("Last Track in session = %u\n", value);
                }

                if (CFNumberGetValue(leadoutBlock, kCFNumberSInt32Type, &value)) {
                    printf("Leadout block for session = %u\n", value);
                }

                if (CFNumberGetValue(sessionType, kCFNumberSInt32Type, &value)) {
                    switch (value) {
						case kDiscTypeCDDA_CDROM:
							printf("Session Type is CD-DA or CD-ROM with first track in Mode 1\n");
							break;
						
						case kDiscTypeCD_I:
							printf("Session Type is CD-I\n");
							break;
						
						case kDiscTypeCDROM_XA:
							printf ("Session Type is CD-ROM XA with first track in Mode 2\n");
							break;
						
						default:
							break;
					}
				}
                
                trackArray = (CFArrayRef) CFDictionaryGetValue(theSessionDict, CFSTR(kTrackArrayString));
                numTracks = CFArrayGetCount(trackArray);

                printf ( "\n" );
                
                // Now iterate across the tracks in this session.
				for (trackIndex = 0; trackIndex < numTracks; trackIndex++) {
                        
                    CFDictionaryRef	theTrackDict = 0;
                    CFNumberRef		trackNumber = 0;
                    CFNumberRef		startBlock = 0;
                    CFBooleanRef	isDataTrack = kCFBooleanFalse;
                    
                    theTrackDict = (CFDictionaryRef) CFArrayGetValueAtIndex(trackArray, trackIndex);
					trackNumber = (CFNumberRef) CFDictionaryGetValue(theTrackDict, CFSTR(kPointKeyString));
                    sessionNumber = (CFNumberRef) CFDictionaryGetValue(theTrackDict, CFSTR(kSessionNumberKeyString));
                    startBlock = (CFNumberRef) CFDictionaryGetValue(theTrackDict, CFSTR(kStartBlockKeyString));
					isDataTrack = (CFBooleanRef) CFDictionaryGetValue(theTrackDict, CFSTR(kDataKeyString));
                                                            
                    if (CFNumberGetValue(trackNumber, kCFNumberSInt32Type, &value)) {
                        printf("Track Number = %u\n", value);
                    }
                    
                    if (CFNumberGetValue(sessionNumber, kCFNumberSInt32Type, &value)) {
                        printf("It resides in session %u\n", value);
                    }
                    
                    if (CFNumberGetValue(startBlock, kCFNumberSInt32Type, &value)) {
                        printf("Track starts at block = %u\n", value);
                    }

                    if (isDataTrack == kCFBooleanTrue) {
                        printf("This is a DATA track\n");
                    }
                    else {
                        printf("This is an AUDIO track\n");
                    }

                    printf("\n");
                }
            }
        }

        // Now done with the property list.
		CFRelease(propertyListRef);
    }
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
//	main
//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

int main(int argc, char* argv[])
{
    OSErr		result = noErr;
	ItemCount	volumeIndex;
    
    // Enumerate all of the mounted volumes on the system looking for audio CDs.
	
	for (volumeIndex = 1; result == noErr || result != nsvErr; volumeIndex++) {
        FSVolumeRefNum	actualVolume;
        HFSUniStr255	volumeName;
        FSVolumeInfo	volumeInfo;
		FSRef           rootDirectory;
        
        bzero((void *) &volumeInfo, sizeof(volumeInfo));
        
        // Get the volume info, which includes the filesystem ID.
		result = FSGetVolumeInfo(kFSInvalidVolumeRefNum,
                                 volumeIndex,
                                 &actualVolume,
                                 kFSVolInfoFSInfo,
                                 &volumeInfo,
                                 &volumeName,
                                 &rootDirectory); 
         
        if (result == noErr) {
            // Work around a bug in Mac OS X 10.0.x where the filesystem ID and signature bytes were
            // erroneously swapped. This was fixed in Mac OS X 10.1 (r. 2653443), broken again in Jaguar (r. 3015107),
			// and finally fixed in 10.2.3.
			//
			// This is the same workaround used by iTunes, so if iTunes thinks a disc is an audio CD,
			// so should this sample.
            
			if (volumeInfo.signature == kAudioCDFilesystemID ||
                volumeInfo.filesystemID == kAudioCDFilesystemID) {
                
				// It's an audio CD.
				
                FSRef			tocPlistFSRef;
				OSStatus		status;
				pid_t			dissenter;
                
                // The CD-DA (Digital Audio) filesystem makes every track appear as a separate AIFF audio file.
				// These files can be played using QuickTime or Core Audio.
				// The filesystem also makes the table of contents (TOC) appear as a hidden XML property list file
				// named ".TOC.plist". The plist file contains both the raw and parsed TOC data.
				
				// Create an FSRef referring to the TOC plist file.                                                
                
                const char plistName[] = ".TOC.plist";
                
                CFURLRef rootURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &rootDirectory);
                
                CFURLRef plistURL = CFURLCreateFromFileSystemRepresentationRelativeToBase(kCFAllocatorDefault,
                                                                                          (const UInt8 *)plistName, 
                                                                                          strlen(plistName), 
                                                                                          false, 
                                                                                          rootURL);
                
                if (CFURLGetFSRef(plistURL, &tocPlistFSRef)) {
                    PrintTOCData(&tocPlistFSRef);
                }
                else {
                    printf("CFURLGetFSRef() returned false\n");
				}
                
                CFRelease(plistURL);
                CFRelease(rootURL);
                    
                // Eject the disc.

				status = FSEjectVolumeSync(actualVolume, kNilOptions, &dissenter);               
                if (status != noErr) {
                    printf("FSEjectVolumeSync returned %d\n", status);
				}
            }
        }
    }
    
    return 0;
}