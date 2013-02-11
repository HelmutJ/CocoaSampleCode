//
// File:       data_loader.m
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////


#import <Cocoa/Cocoa.h>

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

static NSAutoreleasePool *pool = 0;

int FindResourcePath(
    const char* acFilename, 
    char** acPathname, unsigned int *uiPathLength)
{
    if(!acFilename || !acPathname)
        return 0;
        
    int i = 0;
    const char* acExt = 0;
    char *acName = (char*)malloc(strlen(acFilename));
    acName[0] = '\0';
    for(i = strlen(acFilename) - 1; i > 0; i--)
    {
        if(acFilename[i] == '.')
        {
            acExt = &acFilename[i+1];
            memcpy(acName, acFilename, i);
            acName[i] = '\0';
        }
    }

    if(!acName || !acExt)
    {
        free(acName);
        return 0;
    }
    
    if(pool == 0)
        pool = [[NSAutoreleasePool alloc] init];
	NSString *file = [[NSString alloc] initWithCString: acName];
	NSString *ext = [[NSString alloc] initWithCString: acExt];
	NSString *path = [[NSBundle mainBundle] pathForResource: file ofType: ext];
    const char * result = [path UTF8String];
    int length = 0;
    if(result)
    {
        length = strlen(result);
        (*acPathname) = (char*)malloc(length+1);
        memcpy((*acPathname), result, length);
       	(*acPathname)[length] = '\0';
        *uiPathLength = length;
    }
    else
    {
        length = strlen(acFilename) + 2;
        (*acPathname) = (char*)malloc(length+1);
        sprintf((*acPathname), "./%s", acFilename);
       	(*acPathname)[length] = '\0';
        *uiPathLength = length;
    }

    free(acName);
    [file release];
    [ext release];
    return length;
}

unsigned char* LoadImageFromFile(const char *acFilename, int *w, int *h) 
{
    if(pool == 0)
        pool = [[NSAutoreleasePool alloc] init];
        
	char *acResource;
    uint uiLength;
    
    int length = FindResourcePath(acFilename, &acResource, &uiLength);
    if(length < 1)
        return 0;
    
	NSString* imageName = [[NSString alloc] initWithCString:acResource];
	NSImage* image = [[NSImage alloc] initWithContentsOfFile:imageName];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

	int width   = [bitmap pixelsWide];
	int height  = [bitmap pixelsHigh];
	int pitch   = [bitmap bytesPerRow];
    unsigned char *im = (unsigned char*) malloc(height*pitch);
	*w = width;
	*h = height;
    memcpy(im, [bitmap bitmapData], height*[bitmap bytesPerRow]);
		
    free(acResource);
	[imageName release];
	[image release];
	return im;
}

int 
LoadTextFromFile(
    const char *file_name, 
    char **result_string,
    size_t *string_len)
{
	int fd;
	unsigned file_len; 
	struct stat file_status;
	int ret;
	
	*string_len = 0;
	fd = open(file_name, O_RDONLY);
	if (fd == -1) 
	{
		printf("Error opening file %s\n", file_name);
		return -1;
	}
	ret = fstat(fd, &file_status);
	if (ret) 
	{
		printf("Error reading status for file %s\n", file_name);
		return -1;
	}
	file_len = file_status.st_size;
	
	*result_string = (char*) malloc(file_len + 1);
	ret = read(fd, *result_string, file_len);
	if (!ret) 
	{
		printf("Error reading from file %s\n", file_name);
		return -1;
	}
	(*result_string)[file_len] = '\0';
	close(fd);
	
	*string_len = file_len;
	return 0;
}
