/*
     File: CDROMSample.c
 Abstract: Command-line tool demonstrating how to use IOKitLib to find CD-ROM media mounted on the
 system. It also shows how to open, read raw sectors from, and close the drive.
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

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <paths.h>
#include <sys/param.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOBSD.h>
#include <IOKit/storage/IOMediaBSDClient.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IOCDTypes.h>
#include <CoreFoundation/CoreFoundation.h>

static kern_return_t FindEjectableCDMedia(io_iterator_t *mediaIterator);
static kern_return_t GetBSDPath(io_iterator_t mediaIterator, char *bsdPath, CFIndex maxPathSize);
static int OpenDrive(const char *bsdPath);
static Boolean ReadSector(int fileDescriptor);
static void CloseDrive(int fileDescriptor);

// Returns an iterator across all CD media (class IOCDMedia). Caller is responsible for releasing
// the iterator when iteration is complete.
kern_return_t FindEjectableCDMedia(io_iterator_t *mediaIterator)
{
    kern_return_t			kernResult; 
    CFMutableDictionaryRef	classesToMatch;
        
    // CD media are instances of class kIOCDMediaClass
    classesToMatch = IOServiceMatching(kIOCDMediaClass); 
    if (classesToMatch == NULL) {
        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
		CFDictionarySetValue(classesToMatch, CFSTR(kIOMediaEjectableKey), kCFBooleanTrue); 
        // Each IOMedia object has a property with key kIOMediaEjectableKey which is true if the
        // media is indeed ejectable. So add this property to the CFDictionary we're matching on. 
    }

    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, mediaIterator);    
    
    return kernResult;
}
    
// Given an iterator across a set of CD media, return the BSD path to the
// next one. If no CD media was found the path name is set to an empty string.
kern_return_t GetBSDPath(io_iterator_t mediaIterator, char *bsdPath, CFIndex maxPathSize)
{
    io_object_t		nextMedia;
    kern_return_t	kernResult = KERN_FAILURE;
    
    *bsdPath = '\0';
    
    nextMedia = IOIteratorNext(mediaIterator);
    if (nextMedia) {
        CFTypeRef	bsdPathAsCFString;
        
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(nextMedia, 
															CFSTR(kIOBSDNameKey), 
															kCFAllocatorDefault, 
															0);
        if (bsdPathAsCFString) {
            strlcpy(bsdPath, _PATH_DEV, maxPathSize);
            
            // Add "r" before the BSD node name from the I/O Registry to specify the raw disk
            // node. The raw disk nodes receive I/O requests directly and do not go through
            // the buffer cache.
            
            strlcat(bsdPath, "r", maxPathSize);
            
            size_t devPathLength = strlen(bsdPath);
            
            if (CFStringGetCString(bsdPathAsCFString,
								   bsdPath + devPathLength,
								   maxPathSize - devPathLength, 
								   kCFStringEncodingUTF8)) {
                printf("BSD path: %s\n", bsdPath);
                kernResult = KERN_SUCCESS;
            }
            
            CFRelease(bsdPathAsCFString);
        }
    
        IOObjectRelease(nextMedia);
    }
    
    return kernResult;
}

// Given the path to a CD drive, open the drive.
// Return the file descriptor associated with the device.
int OpenDrive(const char *bsdPath)
{
    int	fileDescriptor;
    
    // This open() call will fail with a permissions error if the sample has been changed to
    // look for non-removable media. This is because device nodes for fixed-media devices are
    // owned by root instead of the current console user.
	
    fileDescriptor = open(bsdPath, O_RDONLY);
    
    if (fileDescriptor == -1) {
        printf("Error opening device %s: ", bsdPath);
        perror(NULL);
    }
    
    return fileDescriptor;
}

// Given the file descriptor for a whole-media CD device, read a sector from the drive.
// Return true if successful, otherwise false.
Boolean ReadSector(int fileDescriptor)
{
    char		*buffer;
    ssize_t		numBytes;
    u_int32_t	blockSize;
    
    // This ioctl call retrieves the preferred block size for the media. It is functionally
    // equivalent to getting the value of the whole media object's "Preferred Block Size"
    // property from the IORegistry.
    if (ioctl(fileDescriptor, DKIOCGETBLOCKSIZE, &blockSize)) {
        perror("Error getting preferred block size");
        
        // Set a reasonable default if we can't get the actual preferred block size. A real
        // app would probably want to bail at this point.
        blockSize = kCDSectorSizeCDDA;
    }
    
    printf("Media has block size of %d bytes.\n", blockSize);
    
    // Allocate a buffer of the preferred block size. In a real application, performance
    // can be improved by reading as many blocks at once as you can.
    buffer = malloc(blockSize);
    
    // Do the read. Note that we use read() here, not fread(), since this is a raw device
    // node.
    numBytes = read(fileDescriptor, buffer, blockSize);
        
    // Free our buffer. Of course, a real app would do something useful with the data first.
    free(buffer);
    
    return numBytes == blockSize ? true : false;
}

// Given the file descriptor for a device, close that device.
void CloseDrive(int fileDescriptor)
{
    close(fileDescriptor);
}

int main(void)
{
    kern_return_t	kernResult;
    io_iterator_t	mediaIterator = IO_OBJECT_NULL;
    char			bsdPath[ MAXPATHLEN ];
 
    kernResult = FindEjectableCDMedia(&mediaIterator);
    if (KERN_SUCCESS != kernResult) {
        printf("FindEjectableCDMedia returned 0x%08x\n", kernResult);
    }

    kernResult = GetBSDPath(mediaIterator, bsdPath, sizeof(bsdPath));
    if (KERN_SUCCESS != kernResult) {
        printf("GetBSDPath returned 0x%08x\n", kernResult);
    }
    
    // Now open the device we found, read a sector, and close the device
    if (bsdPath[0] != '\0') {
        int fileDescriptor;
        
        fileDescriptor = OpenDrive(bsdPath);
        
        if (ReadSector(fileDescriptor)) {
            printf("Sector read successfully.\n");
        }
        else {
            printf("Could not read sector.\n");
        }
            
        CloseDrive(fileDescriptor);
        printf("Device closed.\n");
    }
    else {
        printf("No ejectable CD media found.\n");
    }

    // Release the iterator.
    if (mediaIterator != IO_OBJECT_NULL) {
        IOObjectRelease(mediaIterator);
		mediaIterator = IO_OBJECT_NULL; // prevent us from inadvertently using the stale iterator later on
    }
        
    return EXIT_SUCCESS;
}
