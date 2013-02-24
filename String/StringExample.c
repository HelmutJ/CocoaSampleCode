/*
     File: StringExample.c
 Abstract: Simple CFString example program.
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdlib.h>


// This function will print the provided arguments (printf style varargs) out to the console.
// Note that the CFString formatting function accepts "%@" as a way to display CF types.
// For types other than CFString and CFNumber, the result of %@ is mostly for debugging
// and can differ between releases and different platforms.

void show(CFStringRef formatString, ...) {
    CFStringRef resultString;
    CFDataRef data;
    va_list argList;

    va_start(argList, formatString);
    resultString = CFStringCreateWithFormatAndArguments(NULL, NULL, formatString, argList);
    va_end(argList);

    data = CFStringCreateExternalRepresentation(NULL, resultString, CFStringGetSystemEncoding(), '?');

    if (data != NULL) {
        printf ("%.*s\n\n", (int)CFDataGetLength(data), CFDataGetBytePtr(data));
        CFRelease(data);
    }

    CFRelease(resultString);
}


void simpleStringExample(void) {

    CFStringRef str;
    CFDataRef data;
    char *bytes;

    // Create a simple immutable string from a Pascal string and convert it to Unicode

    str = CFStringCreateWithPascalString(NULL, "\pFoo Bar", kCFStringEncodingASCII);

    // Create the Unicode representation of the string
    // "0", lossByte, indicates that if there's a conversion error, fail (and return NULL)

    data = CFStringCreateExternalRepresentation(NULL, str, kCFStringEncodingUnicode, 0);

    show(CFSTR("String       : %@"), str);
    show(CFSTR("Unicode data : %@"), data);

    CFRelease(str);
 
    // Create a string from the Unicode data...

    str = CFStringCreateFromExternalRepresentation(NULL, data, kCFStringEncodingUnicode);

    show(CFSTR("String Out   : %@"), str);

    CFRelease(str);

    // Create a string for which you already have some allocated contents which you want to 
    // pass ownership of to the CFString. The last argument, "NULL," indicates that the default allocator
    // should be used to free the contents when the CFString is freed (or you can pass in CFAllocatorGetDefault()).

    bytes = CFAllocatorAllocate(CFAllocatorGetDefault(), 6, 0);
    strlcpy(bytes, "Hello", 6);

    str = CFStringCreateWithCStringNoCopy(NULL, bytes, kCFStringEncodingASCII, NULL);
    CFRelease(str);

    // Now create a string with a Pascal string which is not copied, and not freed when the string is
    // This is an advanced usage; obviously you need to guarantee that the string bytes do not go away
    // before the CFString does. 

    str = CFStringCreateWithPascalStringNoCopy(NULL, "\pFoo Bar", kCFStringEncodingASCII, kCFAllocatorNull);
    CFRelease(str);
}



void stringGettingContentsAsCStringExample(void) {

    CFStringRef str;
    CFDataRef data;
    CFRange rangeToProcess;
    const char *bytes;

    // Create some test CFString
    // Note that in general the string might contain Unicode characters which cannot
    // be converted to a 8-bit character encoding

    str = CFStringCreateWithCString(NULL, "Hello World", kCFStringEncodingASCII);

    // First, the fast but unpredictable way to get at the C String contents...
    // This is O(1), meaning it takes constant time.
    // This might return NULL!

    bytes = CFStringGetCStringPtr(str, kCFStringEncodingASCII);

    // If that fails, you can try to get the contents by copying it out

    if (bytes == NULL) {
	char localBuffer[10];
        Boolean success;

	// This might also fail, either if you provide a buffer that is too small, 
	// or the string cannot be converted into the specified encoding

  	success = CFStringGetCString(str, localBuffer, 10, kCFStringEncodingASCII);
    }
    
    // A pretty simple solution is to use a CFData; this frees you from guessing at the buffer size
    // But it does allocate a CFData...

    data = CFStringCreateExternalRepresentation(NULL, str, kCFStringEncodingASCII, 0);
    if (data) {
        bytes = (const char *)CFDataGetBytePtr(data);
    }

    // More complicated but efficient solution is to use a fixed size buffer, and put a loop in

    rangeToProcess = CFRangeMake(0, CFStringGetLength(str));

    while (rangeToProcess.length > 0) {
        UInt8 localBuffer[100];
        CFIndex usedBufferLength;
        CFIndex numChars = CFStringGetBytes(str, rangeToProcess, kCFStringEncodingASCII, 0, FALSE, (UInt8 *)localBuffer, 100, &usedBufferLength);

        if (numChars == 0) break;	// Means we failed to convert anything...

        // Otherwise we converted some stuff; process localBuffer containing usedBufferLength bytes
		// Note that the bytes in localBuffer are not NULL terminated
		
        // Update the remaining range to continue looping
        rangeToProcess.location += numChars;
        rangeToProcess.length -= numChars;
    }
}


void stringGettingAtCharactersExample(void) {

    CFStringRef str;
    const UniChar *chars;

    // Create some test CFString

    str = CFStringCreateWithCString(NULL, "Hello World", kCFStringEncodingASCII);

    // The fastest way to get the contents; this might return NULL though
    // depending on the system, the release, etc, so don't depend on it 
    // (unless you used CFStringCreateMutableWithExternalCharactersNoCopy())

    chars = CFStringGetCharactersPtr(str);

    // If that fails, you can try copying the UniChars out
    // either into some stack buffer or some allocated piece of memory...
    // Using the former is fine, but you need to know the size; the latter
    // always works but requires allocating some memory; not too efficient.

    if (chars == NULL) {
	CFIndex length = CFStringGetLength(str);
        UniChar *buffer = malloc(length * sizeof(UniChar));
        CFStringGetCharacters(str, CFRangeMake(0, length), buffer);
	// Process the chars...
        free(buffer);
    }

    // You can use CFStringGetCharacterAtIndex() to get at the characters one at a time,
    // but doing a lot of characters this way might get slow...
    // An option is to use "inline buffer" functionality which mixes the convenience of
    // one-at-a-time char access with efficiency of bulk access

    {
        CFStringInlineBuffer inlineBuffer;
        CFIndex length = CFStringGetLength(str);
  	CFIndex cnt;

	CFStringInitInlineBuffer(str, &inlineBuffer, CFRangeMake(0, length));

	for (cnt = 0; cnt < length; cnt++) {
            UniChar ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
	    // Process character...
	    (void)ch;   // Dummy processing to prevent compiler warning...
	}
    }
    
}


void stringWithExternalContentsExample(void) {
#define BufferSize 1000
    CFMutableStringRef mutStr;
    UniChar *myBuffer;

    // Allocate a contents store that is empty (but has space for BufferSize chars)...
    myBuffer = malloc(BufferSize * sizeof(UniChar));

    // Now create a mutable CFString which uses this buffer
    // The 0 and BufferSize indicate the length and capacity (in UniChars)
    // The kCFAllocatorNull indicates how the CFString should reallocate or free this buffer (in this case, do nothing)

    mutStr = CFStringCreateMutableWithExternalCharactersNoCopy(NULL, myBuffer, 0, BufferSize, kCFAllocatorNull);
    CFStringAppend(mutStr, CFSTR("Appended string... "));
    CFStringAppend(mutStr, CFSTR("More stuff... "));
    CFStringAppendPascalString(mutStr, "\pA pascal string. ", kCFStringEncodingASCII);
    CFStringAppendFormat(mutStr, NULL, CFSTR("%d %4.2f %@..."), 42, -3.14, CFSTR("Hello"));
    
    show(CFSTR("String: %@"), mutStr);

    CFRelease(mutStr);
    free(myBuffer);

    // Now create a similar string, but give CFString the ability to reallocate or free the buffer
    // The last "NULL" argument specifies that the default allocator should be used
    // Here we provide an initial buffer of 32 characters, but if it grows beyond this, it's OK
    // (unlike the previous example, where if the string grew beyond 1000, it's an error)

    myBuffer = CFAllocatorAllocate(CFAllocatorGetDefault(), 32 * sizeof(UniChar), 0);
    mutStr = CFStringCreateMutableWithExternalCharactersNoCopy(NULL, myBuffer, 0, 32, NULL);

    CFStringAppend(mutStr, CFSTR("Appended string... "));
    CFStringAppend(mutStr, CFSTR("Appended string... "));
    CFStringAppend(mutStr, CFSTR("Appended string... "));
    CFStringAppend(mutStr, CFSTR("Appended string... "));
    CFStringAppend(mutStr, CFSTR("Appended string... "));

    show(CFSTR("String: %@"), mutStr);

    CFRelease(mutStr);
    // Here we don't free the buffer, as CFString does that

}



int main () {
    simpleStringExample();
    stringGettingContentsAsCStringExample();
    stringGettingAtCharactersExample();
    stringWithExternalContentsExample();
    
    return 0;
}


