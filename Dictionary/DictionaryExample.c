/*
     File: DictionaryExample.c
 Abstract: Simple CFDictionary example program, also showing property list functionality.
  Version: 1.1
 
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


void simpleDictionaryExample(void) {

    CFMutableDictionaryRef dict;
    CFTypeRef value;
    Boolean booleanResult;
    CFNumberRef number;
    int someInt = 42;
    
    // Create a pretty standard mutable dictionary: CF type keys, CF type values.
    // If you only have a few values to initialize with, it might also make sense to use an immutable
    // dictionary, which is more efficient.
    
    // With the standard callbacks used below, the keys and values will be retained/released as they
    // are added to and removed from the CFDictionary. CFHash() and CFEqual() will be called 
    // on the keys to determine matches.
    
    // If you are using just CFStrings as keys, it might also make sense to use kCFCopyStringDictionaryKeyCallBacks
    // for the key callbacks. This callback set will copy the keys, which is more safe. (Note that copying is
    // fast for strings if the string is actually immutable, so there's no performance hit.)
    
    dict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    // Put some stuff in the dictionary
    
    CFDictionarySetValue(dict, CFSTR("A String Key"), CFSTR("A String Value"));
    
    // Use a CFNumber() as a value, also as a key

    number = CFNumberCreate(NULL, kCFNumberIntType, &someInt);
    
    CFDictionarySetValue(dict, CFSTR("Another string key"), number);
    CFDictionarySetValue(dict, number, CFSTR("Another string value"));

    // Because inserting the CFNumber in the CFDictionary retains it,
    // we can give up ownership and the number will be properly released
    // when the dictionary is released...
    
    CFRelease(number);
    
    // Now print the dictionary and do some queries...

    show(CFSTR("Dictionary: %@"), dict);

    // Should find the CFString "A String Value"
    // Note that the keys don't just have to be ==, because CFEqual() compares values of CFTypes
    // Also note that the returned value should not be freed, as it is owned by the dictionary
    
    value = CFDictionaryGetValue(dict, CFSTR("A String Key"));

    show(CFSTR("Value for key \"A String Key\": %@"), value);

    // Other ways to look up (in order to distinguish NULL value from whether the key is there at all...)
    
    booleanResult = CFDictionaryContainsKey(dict, CFSTR("A String Key"));

    booleanResult = CFDictionaryGetValueIfPresent(dict, CFSTR("A String Key"), &value);

    // Should return NULL, as this key doesn't exist
    
    value = CFDictionaryGetValue(dict, CFSTR("This key isn't in the dictionary"));

    // Now free the dictionary along with all the keys and values

    CFRelease(dict);
}


void propertyListExample(void) {

    CFMutableDictionaryRef dict;
    CFNumberRef num;
    CFArrayRef array;
    CFDataRef data;
    #define NumKids 2
    CFStringRef kidsNames[] = {CFSTR("John"), CFSTR("Kyra")};
    #define NumPets 0
    int yearOfBirth = 1965;
    #define NumBytesInPic 10
    const unsigned char pic[NumBytesInPic] = {0x3c, 0x42, 0x81, 0xa5, 0x81, 0xa5, 0x99, 0x81, 0x42, 0x3c};
    CFDataRef xmlPropertyListData;
    CFStringRef xmlAsString;

    // Create and populate a pretty standard mutable dictionary: CFString keys, CF type values.
    // To be written out as a "propertyList", the tree of CF types can contain only:
    //   CFDictionary, CFArray, CFString, CFData, CFNumber, and CFDate.
    // In addition, the keys of the dictionaries should be CFStrings.

    dict = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFDictionarySetValue(dict, CFSTR("Name"), CFSTR("John Doe"));

    CFDictionarySetValue(dict, CFSTR("City of Birth"), CFSTR("Springfield"));

    num = CFNumberCreate(NULL, kCFNumberIntType, &yearOfBirth);
    CFDictionarySetValue(dict, CFSTR("Year Of Birth"), num);
    CFRelease(num);

    array = CFArrayCreate(NULL, (const void **)kidsNames, 2, &kCFTypeArrayCallBacks); 
    CFDictionarySetValue(dict, CFSTR("Kids Names"), array);
    CFRelease(array);

    array = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
    CFDictionarySetValue(dict, CFSTR("Pets Names"), array);
    CFRelease(array);

    data = CFDataCreate(NULL, pic, NumBytesInPic);
    CFDictionarySetValue(dict, CFSTR("Picture"), data);
    CFRelease(data);

    // We now have a dictionary which contains everything we want to know about
    // John Doe; let's show it first:

    show(CFSTR("John Doe info dictionary: %@"), dict);

    // Now create a "property list", which is a flattened, XML version of the
    // dictionary:

    xmlPropertyListData = CFPropertyListCreateXMLData(NULL, dict);

   // The return value is a CFData containing the XML file; show the data

    show(CFSTR("Shown as XML property list (bytes): %@"), xmlPropertyListData);

    // Given CFDatas are shown as ASCII versions of their hex contents, we can also
    // attempt to show the contents of the XML, assuming it was encoded in UTF8
    // (This is the case for XML property lists generated by CoreFoundation currently)

    xmlAsString = CFStringCreateFromExternalRepresentation(NULL, xmlPropertyListData, kCFStringEncodingUTF8);

    show(CFSTR("The XML property list contents: %@"), xmlAsString);

    CFRelease(dict);
    CFRelease(xmlAsString);
    CFRelease(xmlPropertyListData);
}


/* Let's say you want to put some custom structs in the dictionary, and use integers as keys. (You can use any pointer-sized
element as keys or values). The following callback functions let you achieve these.
*/

// Definitions and callbacks for the custom struct type, to be used as values...

typedef struct {
    int someInt;
    float someFloat;
} MyStructType;

const void *myStructRetain(CFAllocatorRef allocator, const void *ptr) {
    MyStructType *newPtr = (MyStructType *)CFAllocatorAllocate(allocator, sizeof(MyStructType), 0);
    newPtr->someInt = ((MyStructType *)ptr)->someInt;
    newPtr->someFloat = ((MyStructType *)ptr)->someFloat;
    return newPtr;
}

void myStructRelease(CFAllocatorRef allocator, const void *ptr) {
    CFAllocatorDeallocate(allocator, (MyStructType *)ptr);
}

// This callback is optional; it's used if you want to find an entry by value

Boolean myStructEqual(const void *ptr1, const void *ptr2) {
    MyStructType *p1 = (MyStructType *)ptr1;
    MyStructType *p2 = (MyStructType *)ptr2;
    return (p1->someInt == p2->someInt) && (p1->someFloat == p2->someFloat);
}

// This callback is optional; it's used if you want to print dictionaries out when debugging

CFStringRef myStructCopyDescription(const void *ptr) {
    MyStructType *p = (MyStructType *)ptr;
    return CFStringCreateWithFormat(NULL, NULL, CFSTR("[%d, %f]"), p->someInt, p->someFloat);
}



// Functions to treat ints as keys
// Note that the following invariant must hold: If two things are equal, then their hash values must be the same

Boolean	intEqual(const void *ptr1, const void *ptr2) {
    return ptr1 == ptr2;
}

CFHashCode intHash(const void *ptr) {
    return (CFHashCode)(ptr);	// Not a very exciting hash
}

// This callback is optional; it's used if you want to print dictionaries out when debugging

CFStringRef intCopyDescription(const void *ptr) {
    return CFStringCreateWithFormat(NULL, NULL, CFSTR("%lu"), (unsigned long)ptr);
}



void customCallBackDictionaryExample(void) {

    CFDictionaryKeyCallBacks intKeyCallBacks = {0, NULL, NULL, intCopyDescription, intEqual, intHash};
    CFDictionaryValueCallBacks myStructValueCallBacks = {0, myStructRetain, myStructRelease, myStructCopyDescription, myStructEqual};
    MyStructType localStruct;
    CFMutableDictionaryRef dict;
    CFTypeRef value;
    
    // Create a mutable dictionary with int keys and custom struct values
    // whose ownership is transferred to and from the dictionary
        
    dict = CFDictionaryCreateMutable(NULL, 0, &intKeyCallBacks, &myStructValueCallBacks);
    
    // Put some stuff in the dictionary
    // Because the values are copied by our retain function, we just set some local struct
    // and pass that in as the value...
    
    localStruct.someInt = 1000; localStruct.someFloat = -3.14;
    CFDictionarySetValue(dict, (void *)42, &localStruct);
    
    localStruct.someInt = -1000; localStruct.someFloat = -3.14;
    CFDictionarySetValue(dict, (void *)43, &localStruct);

    // Because the same key is used, this next call ends up replacing the earlier value (which is freed)
     
    localStruct.someInt = 44; localStruct.someFloat = -3.14;
    CFDictionarySetValue(dict, (void *)42, &localStruct);
        
    // Now print the dictionary, then do some queries...

    show(CFSTR("Dictionary: %@"), dict);

    value = CFDictionaryGetValue(dict, (void *)43);
    
    if (value) {
        MyStructType result = *(MyStructType *)value;	// Copies value out; or can reference with just a pointer
	    CFStringRef description = myStructCopyDescription(&result);
	    
        show(CFSTR("Value for key 43: %@"), description);

        CFRelease(description);
    }

    // Now free the dictionary and all the values in it
    
    CFRelease(dict);
}


int main (int argc, const char *argv[]) {
    simpleDictionaryExample();
    propertyListExample();
    customCallBackDictionaryExample();

    return 0;
}


