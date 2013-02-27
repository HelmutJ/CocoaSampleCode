/*
	File:		GetMetadataForFile.c

	Version:	1.0

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple's
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 */


#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

static int get_debug_info(char *path, CFMutableDictionaryRef attributes);


Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	int ret = TRUE;
    char path[1024], uti[1024];

    if (   CFStringGetCString(pathToFile, path, sizeof(path), kCFStringEncodingUTF8) == 0
        || CFStringGetCString(contentTypeUTI, uti, sizeof(uti), kCFStringEncodingUTF8) == 0) {

        printf("failed to convert path or uti to a c-string.\n");
        return FALSE;
    }


	if (get_debug_info(path, attributes) != 0) {
	    ret = FALSE;
    }
	
    return ret;
}


static int parse_line(char *buff, char *key, size_t keysz, char *value, size_t valsz);

int
get_debug_info(char *path, CFMutableDictionaryRef attributes)
{
    FILE *fp;
    char buff[1024], key[32], value[1024];
    CFStringRef cfvalue;
   
    fp = fopen(path, "r");
    if (fp == NULL) {
        return -1;
    }

    while ((fgets(buff, sizeof(buff), fp)) != NULL) {

		if (parse_line(buff, key, sizeof(key), value, sizeof(value)) != 0) {
		    continue;
		}

        cfvalue = CFStringCreateWithCString(kCFAllocatorDefault, value, kCFStringEncodingUTF8);

		if (strcasecmp(key, "session") == 0) {

			CFDictionaryAddValue(attributes, CFSTR("com_apple_dbgSessionName"), cfvalue);

	    } else if (strcasecmp(key, "radar") == 0) {

			CFDictionaryAddValue(attributes, CFSTR("com_apple_dbgRadarNumber"), cfvalue);

	    } else if (strcasecmp(key, "keywords") == 0) {
			CFMutableArrayRef keywords;
            keywords = CFArrayCreateMutable(kCFAllocatorDefault, 1, &kCFTypeArrayCallBacks);
						
            CFArrayAppendValue(keywords, (void *)cfvalue);

			CFDictionaryAddValue(attributes, kMDItemKeywords, keywords);

			CFRelease(keywords);
		}
		
		CFRelease(cfvalue);
    }

    fclose(fp);
	CFShow(attributes);
    return 0;
}

static int 
parse_line(char *buff, char *key, size_t keysz, char *value, size_t valsz)
{
	int   len, copy_len;
	char *ptr;
	
	if (buff[0] == '#') {
		return -1;
    }

    len = strlen(buff);
    if (buff[len-1] == '\n') {
        buff[--len] = '\0';
    }

    ptr = strchr(buff, ':');
    if (ptr == NULL) {
        // a malformed line?
		return -1;
    }

    if ((ptr - buff) < keysz) {
        copy_len = (ptr - buff) + 1;
    } else {
        copy_len = keysz - 1;
    }
    strlcpy(key, buff, copy_len);

    ptr += 2;

    strlcpy(value, ptr, valsz);

	return 0;
}
