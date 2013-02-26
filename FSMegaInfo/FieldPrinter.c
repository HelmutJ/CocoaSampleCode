/*
    File:       FieldPrinter.c

    Contains:   Routines to pretty print structures.

    Written by: DTS

    Copyright:  Copyright (c) 2008 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

/////////////////////////////////////////////////////////////////

// Our prototypes

#include "FieldPrinter.h"

// System interfaces

#include <assert.h>
#include <dirent.h>
#include <grp.h>
#include <inttypes.h>
#include <membership.h>
#include <netdb.h>
#include <netinet/in.h>
#include <paths.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>

/////////////////////////////////////////////////////////////////
#pragma mark ***** Utilities

extern char *   FPPStringToUTFCString(ConstStr255Param pstr, CFStringEncoding pstrEncoding)
    // See comment in header.
{
    CFStringRef     str;
    CFIndex         strBufLen;
    char *          strBuf;
    Boolean         success;
    
    assert(pstr != NULL);
    
    strBuf = NULL;
    
    str = CFStringCreateWithPascalString(NULL, pstr, pstrEncoding);
    assert(str != NULL);

    if (str != NULL) {
        strBufLen = CFStringGetMaximumSizeForEncoding(CFStringGetLength(str), kCFStringEncodingUTF8) + 1;       // + 1 for null terminator
        strBuf = (char *) malloc(strBufLen);
        assert(strBuf != NULL);

        if (strBuf != NULL) {
            success = CFStringGetCString(str, strBuf, strBufLen, kCFStringEncodingUTF8);
            assert(success);
            
            if ( ! success ) {
                free(strBuf);
                strBuf = NULL;
            }
        }

        CFRelease(str);
    }
    return strBuf;
}

extern void FPPrintFlags(unsigned long long flags, const FPFlagDesc *flagList, size_t nameWidth, uint32_t indent)
    // See comment in header.
{
    int     flagIndex;
    size_t  thisLen;

    assert(flagList != NULL);

    // Calculate the length of the longest flag name (unless the caller 
    // specified one).
    
    if (nameWidth == 0) {
        flagIndex = 0;
        while (flagList[flagIndex].flagName != NULL) {
            thisLen = strlen(flagList[flagIndex].flagName);
            if (thisLen > nameWidth) {
                nameWidth = thisLen;
            }
            flagIndex += 1;
        }
    }
    
    // Print each matching flag, clearing each flag that we recognise.
    
    flagIndex = 0;
    while (flagList[flagIndex].flagName != NULL) {
        fprintf(stdout, "%*s%-*s = %s\n", (int) indent, "", (int) nameWidth, flagList[flagIndex].flagName, (flags & flagList[flagIndex].flagMask) ? "YES" : "NO");
        flags &= ~flagList[flagIndex].flagMask;
        flagIndex += 1;
    }
    
    // If any flags remain unrecognised, tell the user.
    
    if (flags != 0) {
        fprintf(stdout, "%*s... and others (0x%llx)\n", (int) indent, "", flags);
    }
}

extern size_t FPFindFlagByName(const FPFlagDesc *flagList, const char *flagName)
    // See comment in header.
{
    bool                found;
    size_t              flagIndex;
    
    found = false;
    flagIndex = 0;
    while ( ! found && (flagList[flagIndex].flagName != NULL) ) {
        found = (strcasecmp(flagName, flagList[flagIndex].flagName) == 0);
        if ( ! found ) {
            flagIndex += 1;
        }
    }
    
    if ( ! found ) {
        flagIndex = kFPNotFound;
    }
    return flagIndex;
}

extern size_t FPFindEnumByValue(const FPEnumDesc enumList[], int enumValue)
    // See comment in header.
{
    bool        found;
    size_t      enumIndex;
    
    found = false;
    enumIndex = 0;
    while ( ! found && (enumList[enumIndex].enumName != NULL) ) {
        found = (enumList[enumIndex].enumValue == enumValue);
        if ( ! found ) {
            enumIndex += 1;
        }
    }
    
    if ( ! found ) {
        enumIndex = kFPNotFound;
    }
    return enumIndex;
}

extern size_t FPFindEnumByName(const FPEnumDesc enumList[], const char *enumName)
    // See comment in header.
{
    bool        found;
    size_t      enumIndex;
    
    found = false;
    enumIndex = 0;
    while ( ! found && (enumList[enumIndex].enumName != NULL) ) {
        found = (strcasecmp(enumList[enumIndex].enumName, enumName) == 0);
        if ( ! found ) {
            enumIndex += 1;
        }
    }
    
    if ( ! found ) {
        enumIndex = kFPNotFound;
    }
    return enumIndex;
}

static void FPPrintFieldsCore(const FPFieldDesc fields[], const void *fieldBuf, size_t fieldBufSize, uint32_t indent, uint32_t verbose, FPEndian endian)
{
    #pragma unused(fieldBufSize)
    size_t          nameWidth;
    size_t          nameLen;
    size_t          fieldIndex;
    FPPrinter       printer;
    const void *    info;
    
    assert(fields != NULL);
    assert(fieldBuf != NULL);

    // Calculate the maximum field of the field names.
    
    nameWidth  = 0;
    fieldIndex = 0;
    while (fields[fieldIndex].fieldName != NULL) {
        nameLen = strlen(fields[fieldIndex].fieldName);
        if (nameLen > nameWidth) {
            nameWidth = nameLen;
        }
        fieldIndex += 1;
    }
    
    // Print each field.
    
    fieldIndex = 0;
    while (fields[fieldIndex].fieldName != NULL) {
    
        // Make sure the field is within the structure.
        
        assert( fields[fieldIndex].fieldOffset < fieldBufSize );
        assert( (fields[fieldIndex].fieldOffset + fields[fieldIndex].fieldSize) <= fieldBufSize);
    
        // Process any endian override requested by the caller.
        
        printer = fields[fieldIndex].fieldPrinter;
        info    = fields[fieldIndex].fieldInfo;
        switch (endian) {
            case kFPValueHostEndian:
                // do nothing
                break;
            case kFPValueBigEndian:
                if ( (printer == FPHex) || (printer == FPSDec) || (printer == FPUDec) || (printer == FPSignature) ) {
                    info = (const void *) (uintptr_t) endian;
                } else if (printer == FPFlags) {
                    printer = FPFlagsBE;
                } else {
                    assert(false);
                }
                break;
            case kFPValueLittleEndian:
                assert(false);
                break;
            default:
                assert(false);
                break;
        }
        
        // Call the printer routine.
    
        printer(
            fields[fieldIndex].fieldName, 
            fields[fieldIndex].fieldSize, 
            (((char *) fieldBuf) + fields[fieldIndex].fieldOffset), 
            indent, 
            nameWidth, 
            verbose,
            info
        );
        fieldIndex += 1;
    }
}

extern void FPPrintFields(const FPFieldDesc fields[], const void *fieldBuf, size_t fieldBufSize, uint32_t indent, uint32_t verbose)
    // See comments in header.
{
    FPPrintFieldsCore(fields, fieldBuf, fieldBufSize, indent, verbose, kFPValueHostEndian);
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Field Printer Routines

extern void FPNull(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints nothing, in about 20 lines )-:
    //
    // See definition of FPPrinter for a parameter description.
{
    // Can't use FPStandardPreCondition because fieldSize is allowed to be 
    // zero in this case.
    
    assert( fieldName != NULL );
    // assert( fieldSize > 0 );
    assert( fieldPtr != NULL ); 
    assert( (nameWidth > 0) && ( ((size_t) nameWidth) >= strlen(fieldName) ) );

    #pragma unused(fieldName)
    #pragma unused(fieldSize)
    #pragma unused(fieldPtr)
    #pragma unused(indent)
    #pragma unused(nameWidth)
    #pragma unused(verbose)
    #pragma unused(info)

    // do nothing
}

extern void FPCString(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a C string field.  The field is assumed to be UTF-8.
    //
    // See definition of FPPrinter for a parameter description.
{
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );

    fprintf(stdout, "%*s%-*s = '%s'\n", (int) indent, "", (int) nameWidth, fieldName, (const char *) fieldPtr);
}

extern void FPCStringPtr(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a C string pointer field.  The encoding is assumed to be UTF-8.
    //
    // See definition of FPPrinter for a parameter description.
{
    const char *    strPtr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(const char *));
    
    strPtr = *((const char **) fieldPtr);
    assert(strPtr != NULL);
    
    fprintf(stdout, "%*s%-*s = %p ('%s')\n", (int) indent, "", (int) nameWidth, fieldName, strPtr, strPtr);
}

extern void FPPString(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a Pascal string field.  info supplies the text encoding.
    //
    // See definition of FPPrinter for a parameter description.
{
    char *              strBuf;

    #pragma unused(fieldSize)
    #pragma unused(verbose)
    assert( FPStandardPreCondition() );

    strBuf = FPPStringToUTFCString(fieldPtr, (CFStringEncoding) (uintptr_t) info);
    assert(strBuf != NULL);
    
    if (strBuf != NULL) {
        fprintf(stdout, "%*s%-*s = '%s'\n", (int) indent, "", (int) nameWidth, fieldName, strBuf);
    }

    free(strBuf);
}

extern void FPCFString(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a CFString field.
    //
    // See definition of FPPrinter for a parameter description.
{
    CFStringRef             str;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(CFStringRef));
    
    str = *( (CFStringRef *) fieldPtr );
    assert(str != NULL);
    assert( CFGetTypeID(str) == CFStringGetTypeID() );

    FPCFType(fieldName, sizeof(str), &str, indent, (int) nameWidth, verbose, NULL);
}

extern void FPCFType(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a CFType field.
    //
    // See definition of FPPrinter for a parameter description.
{
    CFTypeRef               value;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(CFTypeRef));
    
    value = *( (CFTypeRef *) fieldPtr );
    assert(value != NULL);

    // First handle the compound types, CFDictionary and CFArray.
    
    if ( CFGetTypeID(value) == CFDictionaryGetTypeID() ) {
        FPCFDictionary(fieldName, sizeof(value), &value, indent, nameWidth, verbose, NULL);
    } else if ( CFGetTypeID(value) == CFArrayGetTypeID() ) {
        // FPCFArray(fieldName, sizeof(value), &value, indent, nameWidth, verbose, NULL);
        fprintf(stderr, "*** CFArray skipped\n");
    } else {
        const char *            quoteStr;
        CFStringRef             str;
        CFIndex                 strBufLen;
        char *                  strBuf;
        Boolean                 success;
        
        // Handle everything else, which hopefully can be converted to a string 
        // using CFStringCreateWithFormat.
        
        quoteStr = "";
        if ( CFGetTypeID(value) == CFStringGetTypeID() ) {
            quoteStr = "'";
        }
        
        str = CFStringCreateWithFormat(NULL, NULL, CFSTR("%@"), value);
        assert(str != NULL);
        if (str != NULL) {
            strBufLen = CFStringGetMaximumSizeForEncoding(CFStringGetLength(str), kCFStringEncodingUTF8) + 1;       // + 1 for null terminator
            strBuf = (char *) malloc(strBufLen);
            assert(strBuf != NULL);

            if (strBuf != NULL) {
                success = CFStringGetCString(str, strBuf, strBufLen, kCFStringEncodingUTF8);
                assert(success);

                if (success) {
                    fprintf(stdout, "%*s%-*s = %s%s%s\n", (int) indent, "", (int) nameWidth, fieldName, quoteStr, strBuf, quoteStr);
                }
            }

            free(strBuf);
            CFRelease(str);
        }
    }
}

static int KeyCompare(const void *left, const void *right)
    // Comparison callback for sorting an array of CFDictionary keys.
{
    CFStringRef     leftString;
    CFStringRef     rightString;
    
    assert(left != NULL);
    assert(right != NULL);
    
    leftString  = *(CFStringRef *) left;
    rightString = *(CFStringRef *) right;

    assert(leftString != NULL);
    assert(rightString != NULL);
    
    return (int) CFStringCompare(leftString, rightString, 0);
}

extern void FPCFDictionary(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a CFDictionary field.
    //
    // See definition of FPPrinter for a parameter description.
{
    CFDictionaryRef         dict;
    CFIndex                 dictCount;
    CFIndex                 dictIndex;
    Boolean                 success;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(CFDictionaryRef));
    
    dict = *( (CFDictionaryRef *) fieldPtr );
    assert(dict != NULL);
    assert( CFGetTypeID(dict) == CFDictionaryGetTypeID() );

    fprintf(stdout, "%*s%-*s = {\n", (int) indent, "", (int) nameWidth, fieldName);
    
    dictCount = CFDictionaryGetCount(dict);
    if (dictCount > 0) {
        CFTypeRef *         keys;
        CFIndex             keyWidth;
        char *              keyBuf;
        CFIndex             keyBufSize;
        
        keys = malloc(dictCount * sizeof(CFTypeRef));
        assert(keys != NULL);

        CFDictionaryGetKeysAndValues(dict, (const void **) keys, NULL);
        
        // Sort the keys so that we get consistent results for the benefit of the 
        // test script.
        
        qsort(keys, dictCount, sizeof(*keys), KeyCompare);
        
        // Calculate the maximum length of the keys.  This is somewhat bogus because 
        // we're counting in Unicode characters, not UTF-8, but it will work for the 
        // common case where the keys are all ASCII.
        
        keyWidth = 0;
        for (dictIndex = 0; dictIndex < dictCount; dictIndex++) {
            assert( CFGetTypeID(keys[dictIndex]) == CFStringGetTypeID() );
            if ( CFStringGetLength(keys[dictIndex]) > keyWidth ) {
                keyWidth = CFStringGetLength(keys[dictIndex]);
            }
        }
        
        // Once we know the maximum key width, we can use it to allocate a buffer that's 
        // big enough to hold the UTF-8 representation of that width.
        
        keyBufSize = CFStringGetMaximumSizeForEncoding(keyWidth, kCFStringEncodingUTF8) + 1;
        keyBuf = malloc(keyBufSize);
        assert(keyBuf != NULL);
        
        // Now go through and print each field.
        
        for (dictIndex = 0; dictIndex < dictCount; dictIndex++) {
            CFTypeRef   thisValue;

            success = CFStringGetCString(keys[dictIndex], keyBuf, keyBufSize, kCFStringEncodingUTF8);
            assert(success);

            thisValue = CFDictionaryGetValue(dict, keys[dictIndex]);

            FPCFType(keyBuf, sizeof(thisValue), &thisValue, indent + kStdIndent, keyWidth, verbose, NULL);
        }
        
        free(keyBuf);
        free(keys);
    }

    fprintf(stdout, "%*s}\n", (int) indent, "");
}

extern void HFSUniStr255FieldPrinter(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an HFSUniStr255 field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const HFSUniStr255 *    hfsStr;
    CFStringRef             str;
    
    #pragma unused(fieldSize)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(HFSUniStr255));
    
    hfsStr = (const HFSUniStr255 *) fieldPtr;
    assert(hfsStr != NULL);
    
    str = CFStringCreateWithCharacters(NULL, hfsStr->unicode, hfsStr->length);
    assert(str != NULL);

    if (str != NULL) {
        FPCFString(fieldName, sizeof(str), &str, indent, nameWidth, verbose, info);
    }
    
    CFRelease(str);
}

extern void FPPtr(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a generic pointer field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const void *    ptr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(void *));
    
    ptr = *((const void **) fieldPtr);
    
    fprintf(stdout, "%*s%-*s = %p\n", (int) indent, "", (int) nameWidth, fieldName, ptr);
}

extern void FPBoolean(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a Boolean field.
    //
    // See definition of FPPrinter for a parameter description.
{
    Boolean b;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(Boolean));
    
    b = *((Boolean *) fieldPtr);
    
    fprintf(stdout, "%*s%-*s = %s\n", (int) indent, "", (int) nameWidth, fieldName, b ? "YES" : "NO");
}

static bool SwapIt(const void *info)
{
    FPEndian    endian;
    bool        swap;

    endian = (FPEndian) (uintptr_t) info;
    swap = false;
    switch (endian) {
        case kFPValueHostEndian:
            break;
        case kFPValueBigEndian:
            #if TARGET_RT_LITTLE_ENDIAN
                swap = true;
            #endif
            break;
        case kFPValueLittleEndian:
            #if TARGET_RT_BIG_ENDIAN
                swap = true;
            #endif
            break;
        default:
            assert(false);
            break;
    }
    return swap;
}

static uint16_t Swap16(const void *fieldPtr, const void *info)
{
    uint16_t    x;
    
    x = * (uint16_t *) fieldPtr;
    if ( SwapIt(info) ) {
        x = OSSwapInt16(x);
    }
    return x;
}

static uint32_t Swap32(const void *fieldPtr, const void *info)
{
    uint32_t    x;
    
    x = * (uint32_t *) fieldPtr;
    if ( SwapIt(info) ) {
        x = OSSwapInt32(x);
    }
    return x;
}

static uint64_t Swap64(const void *fieldPtr, const void *info)
{
    uint64_t    x;
    
    x = * (uint64_t *) fieldPtr;
    if ( SwapIt(info) ) {
        x = OSSwapInt64(x);
    }
    return x;
}

extern void FPHex(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a field in hex.  There's special case code for each common size 
    // (8 bits, 16 bits, 32 bits, and 64 bits), and generic code for large sizes.
    //
    // See definition of FPPrinter for a parameter description.
{
    size_t      i;
    
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );

    switch (fieldSize) {
        case sizeof(uint8_t):
            fprintf(stdout, "%*s%-*s = 0x%02"  PRIx8  "\n", (int) indent, "", (int) nameWidth, fieldName, *((uint8_t *) fieldPtr) );
            break;
        case sizeof(uint16_t):
            fprintf(stdout, "%*s%-*s = 0x%04"  PRIx16 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap16(fieldPtr, info)  );
            break;
        case sizeof(uint32_t):
            fprintf(stdout, "%*s%-*s = 0x%08"  PRIx32 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap32(fieldPtr, info)  );
            break;
        case sizeof(uint64_t):
            fprintf(stdout, "%*s%-*s = 0x%016" PRIx64 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap64(fieldPtr, info)  );
            break;
        default:
            if (fieldSize > sizeof(uint64_t)) {
                fprintf(stdout, "%*s%-*s = ", (int) indent, "", (int) nameWidth, fieldName);

                i = 0;
                while (i < fieldSize) {
                    do {
                        fprintf(stdout, "%02" PRIx8 " ", ((uint8_t *) fieldPtr)[i]);
                        i += 1;
                    } while ( (i < fieldSize) && ((i % 16) != 0) );
                    fprintf(stdout, "\n");
                    
                    if (i < fieldSize) {
                        fprintf(stdout, "%*s%*s   ", (int) indent, "", (int) nameWidth, "");
                    }
                }
            } else {
                assert(false);
            }
            break;
    }
}

extern void FPSDec(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a field as a signed decimal.  There's special case code for each common 
    // size (8 bits, 16 bits, 32 bits, and 64 bits), and other sizes are printed as 
    // a hex dump.
    //
    // See definition of FPPrinter for a parameter description.
{
    assert( FPStandardPreCondition() );

    switch (fieldSize) {
        case sizeof(int8_t):
            fprintf(stdout, "%*s%-*s = %" PRId8  "\n", (int) indent, "", (int) nameWidth, fieldName, *((int8_t *)  fieldPtr)              );
            break;
        case sizeof(int16_t):
            fprintf(stdout, "%*s%-*s = %" PRId16 "\n", (int) indent, "", (int) nameWidth, fieldName, (int16_t) Swap16(fieldPtr, info) );
            break;
        case sizeof(int32_t):
            fprintf(stdout, "%*s%-*s = %" PRId32 "\n", (int) indent, "", (int) nameWidth, fieldName, (int32_t) Swap32(fieldPtr, info) );
            break;
        case sizeof(int64_t):
            fprintf(stdout, "%*s%-*s = %" PRId64 "\n", (int) indent, "", (int) nameWidth, fieldName, (int64_t) Swap64(fieldPtr, info) );
            break;
        default:
            FPHex(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info);
            break;
    }
}

extern void FPUDec(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a field as an unsigned decimal.  There's special case code for each common 
    // size (8 bits, 16 bits, 32 bits, and 64 bits), and other sizes are printed as 
    // a hex dump.
    //
    // See definition of FPPrinter for a parameter description.
{
    #pragma unused(info)
    assert( FPStandardPreCondition() );

    switch (fieldSize) {
        case sizeof(uint8_t):
            fprintf(stdout, "%*s%-*s = %" PRIu8  "\n", (int) indent, "", (int) nameWidth, fieldName, *((uint8_t *)  fieldPtr)   );
            break;
        case sizeof(uint16_t):
            fprintf(stdout, "%*s%-*s = %" PRIu16 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap16(fieldPtr, info) );
            break;
        case sizeof(uint32_t):
            fprintf(stdout, "%*s%-*s = %" PRIu32 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap32(fieldPtr, info) );
            break;
        case sizeof(uint64_t):
            fprintf(stdout, "%*s%-*s = %" PRIu64 "\n", (int) indent, "", (int) nameWidth, fieldName, Swap64(fieldPtr, info) );
            break;
        default:
            FPHex(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info);
            break;
    }
}

extern void FPSize(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a field in decimal along with an interpretation of the field as 
    // bytes, KB, MB, or GB.  In addition, if info is not NULL then it describes 
    // another field that holds the units of the value.  For example, if fieldPtr 
    // points to the disk size in blocks, info describes the field that holds the 
    // block size, so that this routine can calculate the size in bytes.
    //
    // See definition of FPPrinter for a parameter description.
{
    uint64_t                fieldValue;
    uint64_t                fieldValueInBytes;
    const FPSizeMultiplier *  multiplier;
    const void *            multiplierPtr;
    uint64_t                unitDivisor;
    const char *            unitStr;
    
    #pragma unused(verbose)
    assert( FPStandardPreCondition() );

    // Get the value of the field itself.  Note that we only handle 32 bit 
    // and 64 bit fields because that's all that cropped up in this program.
    
    switch (fieldSize) {
        case sizeof(uint32_t):
            fieldValue = *((uint32_t *) fieldPtr);
            break;
        case sizeof(uint64_t):
            fieldValue = *((uint64_t *) fieldPtr);
            break;
        default:
            assert(false);
            fieldValue = 0;
            break;
    }
    
    // If there's a multiplier, get its value (again, we only support 32 bit 
    // and 64 bit multipliers) and use it to calculate the total size in bytes.
    
    if (info != NULL) {
        multiplier = (const FPSizeMultiplier *) info;
        
        multiplierPtr = ((const char *) fieldPtr) + multiplier->multiplierOffset;
        
        switch (multiplier->multiplierSize) {
            case sizeof(uint32_t):
                fieldValueInBytes = fieldValue * *((uint32_t *) multiplierPtr);
                break;
            case sizeof(uint64_t):
                fieldValueInBytes = fieldValue * *((uint64_t *) multiplierPtr);
                break;
            default:
                assert(false);
                fieldValueInBytes = 0;
                break;
        }
    } else {
        fieldValueInBytes = fieldValue;
    }

    // Work out the units for printing fieldValueInBytes.
    
    if (fieldValueInBytes > (1024LL * 1024 * 1024)) {
        unitDivisor = 1024LL * 1024 * 1024;
        unitStr = "GB";
    } else if (fieldValueInBytes > (1024LL * 1024)) {
        unitDivisor = 1024LL * 1024;
        unitStr = "MB";
    } else if (fieldValueInBytes > 1024LL) {
        unitDivisor = 1024LL;
        unitStr = "KB";
    } else {
        unitDivisor = 1;
        if (fieldValueInBytes == 1) {
            unitStr = "byte";
        } else {
            unitStr = "bytes";
        }
    }

    // Print the raw field value and its pretty value.
    
    fprintf(stdout, "%*s%-*s = %" PRIu64 " (%" PRIu64 " %s)\n", (int) indent, "", (int) nameWidth, fieldName, fieldValue, fieldValueInBytes / unitDivisor, unitStr);
}

extern void FPSignature(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a signature field (that is, a generalised form of OSType, where 
    // each byte is interpreted as a character).  Made more complicated by the 
    // fact that OSType-bytes are generally considered to be in MacRoman.  Oh yeah, 
    // and byte order.
    //
    // See definition of FPPrinter for a parameter description.
{
    uint16_t    sig16;
    uint32_t    sig32;
    char        tmp[5] = { 0 };
    char        strBuf[64];
    size_t      i;
    Boolean     success;
    CFStringRef str;
    FPEndian    endian;
    bool        swap;
    
    #pragma unused(verbose)
    assert( FPStandardPreCondition() );
    assert( (fieldSize == 2) || (fieldSize == 4) );

    // Generate a UTF-8 C string from the data.  This is way more complex that 
    // you'd think (-:
    
    // We want the input data for the string to be big endian.  So, we swap it 
    // around if its little endian, or host endian on a little endian machine.
    
    endian = (FPEndian) (uintptr_t) info;
    swap = (endian == kFPValueLittleEndian);
    #if TARGET_RT_LITTLE_ENDIAN
        if (endian == kFPValueHostEndian) {
            swap = true;
        }
    #endif

    for (i = 0; i < fieldSize; i++) {
        uint8_t     b;
        
        b = ((const uint8_t *) fieldPtr)[i];
        if ( (b < ' ') || (b == 0x7f) ) {
            b = '?';
        }
        if (swap) {
            tmp[fieldSize - 1 - i] = b;
        } else {
            tmp[i] = b;
        }
    }

    str = CFStringCreateWithCString(NULL, tmp, kCFStringEncodingMacRoman);
    assert(str != NULL);

    success = CFStringGetCString(str, strBuf, sizeof(strBuf), kCFStringEncodingUTF8);
    assert(success);
        
    CFRelease(str);
    
    switch (fieldSize) {
        case sizeof(uint16_t):
            sig16 = Swap16(fieldPtr, info);
            fprintf(stdout, "%*s%-*s = 0x%04" PRIx16 " ('%s')\n", (int) indent, "", (int) nameWidth, fieldName, sig16, strBuf);
            break;
        case sizeof(uint32_t):
            sig32 = Swap32(fieldPtr, info);
            fprintf(stdout, "%*s%-*s = 0x%08" PRIx32 " ('%s')\n", (int) indent, "", (int) nameWidth, fieldName, sig32, strBuf);
            break;
        default:
            assert(false);
            break;
    }
}

static const char * FindDevString(dev_t dev)
    // Searches "/dev" for a device node whose dev_t matches dev.
    // 
    // On success, the result is a C string that contains the Posix
    // path to the dev node.  The caller is responsible for disposing 
    // of this string using "free".  On error, the result is NULL.
{
    int             err;
    int             junk;
    const char *    result;
    DIR *           dir;
    struct dirent * thisDirEnt;
    char            thisDirEntPath[MAXPATHLEN];
    struct stat     sb;
    
    result = NULL;

    dir = opendir(_PATH_DEV);
    
    if (dir != NULL) {
        do {
            thisDirEnt = readdir(dir);
            
            if (thisDirEnt != NULL) {

                // Only interested in character or block device drivers.
                
                if ( (thisDirEnt->d_type == DT_CHR) || (thisDirEnt->d_type == DT_BLK) ) {
                    
                    // Construct the full path to the dev node.
                    
                    snprintf(thisDirEntPath, sizeof(thisDirEntPath), _PATH_DEV "%.*s", thisDirEnt->d_namlen, thisDirEnt->d_name);
                    
                    err = stat(thisDirEntPath, &sb);
                    if (err == 0) {
                        // fprintf(stdout, "%s %08x\n", thisDirEntPath, sb.st_rdev);
                        if (sb.st_rdev == dev) {
                            char * tmp;
                            
                            // We have a match.  Allocate a C string, copy 
                            // the name into it, and set up to the return it 
                            // to our caller.  We can't use strdup because 
                            // there's no guarantee that thisDirEnt->d_name is 
                            // null terminated.
                            
                            tmp = (char *) malloc(thisDirEnt->d_namlen + 1);
                            assert(tmp != NULL);
                            
                            memcpy(tmp, thisDirEnt->d_name, thisDirEnt->d_namlen);
                            tmp[thisDirEnt->d_namlen] = 0;
                            
                            result = tmp;
                        }
                    }
                }
            }
        } while ( (result == NULL) && (thisDirEnt != NULL) );

        junk = closedir(dir);
        assert(junk == 0);
    }

    return result;
}

extern void FPDevT(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a dev_t field, looking up the value in "/dev" to see if 
    // we can work out what the corresponding device node is called.
    //
    // See definition of FPPrinter for a parameter description.
{
    dev_t           dev;
    const char *    devStr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(dev_t));
    dev = *( (dev_t *) fieldPtr );
    
    devStr = FindDevString(dev);

    if (devStr == NULL) {
        fprintf(stdout, "%*s%-*s = 0x%08lx (major=%ld, minor=%ld)\n", (int) indent, "", (int) nameWidth, fieldName, (long ) dev, (long) major(dev), (long) minor(dev));
    } else {
        fprintf(stdout, "%*s%-*s = 0x%08lx (major=%ld, minor=%ld, %s)\n", (int) indent, "", (int) nameWidth, fieldName, (long ) dev, (long) major(dev), (long) minor(dev), devStr);
    }
    
    free( (char *) devStr);
}

extern void FPUID(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a uid_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    uid_t           uid;
    struct passwd * pw;
    const char *    uidStr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(uid_t));
    
    uid = *((uid_t *) fieldPtr);

    pw = getpwuid(uid);
    if (pw == NULL) {
        uidStr = "???";
    } else {
        uidStr = pw->pw_name;
    }

    fprintf(stdout, "%*s%-*s = %ld (%s)\n", (int) indent, "", (int) nameWidth, fieldName, (long) uid, uidStr);
}

extern void FPGID(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a gid_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    gid_t           gid;
    struct group *  gr;
    const char *    gidStr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(gid_t));
    
    gid = *((gid_t *) fieldPtr);

    gr = getgrgid(gid);
    if (gr == NULL) {
        gidStr = "???";
    } else {
        gidStr = gr->gr_name;
    }

    fprintf(stdout, "%*s%-*s = %ld (%s)\n", (int) indent, "", (int) nameWidth, fieldName, (long) gid, gidStr);
}

extern void FPGUID(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a GUID field.  Prints both the raw hex and the corresponding 
    // user/group name.
    //
    // See definition of FPPrinter for a parameter description.
{
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    int                 err;
    const guid_t *      guidPtr;
    uuid_t              uuid;
    int                 idType;
    uid_t               id;
    const char *        idTypeStr;
    const char *        idStr;
    struct passwd *     pw;
    struct group *      gr;
    static const guid_t kNullGUID = { { 0 } };
    
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(*guidPtr));
    
    guidPtr = (const guid_t *) fieldPtr;
    
    assert( sizeof(uuid) == sizeof(*guidPtr) );
    memcpy( uuid, guidPtr, sizeof(uuid) );

    // First test for a null GUID.
    
    if ( memcmp(guidPtr, &kNullGUID, sizeof(kNullGUID) ) == 0 ) {
        fprintf(
            stdout, 
            "%*s%-*s = 00000000-0000-0000-0000-000000000000 (null)\n", 
            (int) indent, 
            "", 
            (int) nameWidth,
            fieldName
        );
    } else {
        // It's not null, we'll want to map it to a user or group
        
        // Prepare for failure.
        
        idTypeStr = "???";
        idStr = "???";

        // Map the GUID to an id type (user/group) and ID.
        
        err = mbr_uuid_to_id(uuid, &id, &idType);
        
        // Convert the results to strings.
        
        if (err == 0) {
            switch (idType) {
                case ID_TYPE_UID:
                    idTypeStr = "user";
         
                    pw = getpwuid(id);
                    if (pw != NULL) {
                        idStr = pw->pw_name;
                    }
                    
                    break;
                case ID_TYPE_GID:
                    idTypeStr = "group";
                    
                    gr = getgrgid( (gid_t) id );
                    if (gr != NULL) {
                        idStr = gr->gr_name;
                    }
                    break;
                default:
                    assert(false);
                    err = -1;
                    break;
            }
        }
        
        // Print the GUID and its mapping.
        
        fprintf(
            stdout, 
            "%*s%-*s = %02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X (%s:%s)\n", 
            (int) indent, 
            "", 
            (int) nameWidth,
            fieldName, 
            guidPtr->g_guid[0],
            guidPtr->g_guid[1],
            guidPtr->g_guid[2],
            guidPtr->g_guid[3],
            guidPtr->g_guid[4],
            guidPtr->g_guid[5],
            guidPtr->g_guid[6],
            guidPtr->g_guid[7],
            guidPtr->g_guid[8],
            guidPtr->g_guid[9],
            guidPtr->g_guid[10],
            guidPtr->g_guid[11],
            guidPtr->g_guid[12],
            guidPtr->g_guid[13],
            guidPtr->g_guid[14],
            guidPtr->g_guid[15],
            idTypeStr,
            idStr
        );
    }
}

extern void FPModeT(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a mode_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    mode_t          fieldValue;
    unsigned long   tmp;
    char            modeStr[12];
    
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );

    switch (fieldSize) {
        case sizeof(mode_t):
            fieldValue = *( (mode_t *) fieldPtr );
            break;
        case sizeof(uint32_t):                 // getattrlist returns mode_t's as uint32_t
            tmp = *( (uint32_t *) fieldPtr );
            fieldValue = tmp;
            break;
        default:
            assert(false);
            fieldValue = 0;
            break;
    }
    
    strmode(fieldValue, modeStr);

    // Remove trailing blank if present.  This indicates the absence of an ACL, 
    // which is the most common case.  The trailing blank looks ugly when we 
    // enclose the string in parens.

    if (modeStr[10] == ' ') {
        modeStr[10] = 0;
    }
    
    fprintf(stdout, "%*s%-*s = 0x%08lx (%s)\n", (int) indent, "", (int) nameWidth, fieldName, (long) fieldValue, modeStr);
}

extern void FPEnum(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an enumeration value field.  info points to an array of FPEnumDesc 
    // that describes the known values of the enumeration.
    //
    // See definition of FPPrinter for a parameter description.
{
    const FPEnumDesc *    enumList;
    int                 fieldValue;
    int                 enumIndex;
    const char *        enumStr;

    #pragma unused(fieldSize)
    #pragma unused(verbose)
    assert( FPStandardPreCondition() );
    assert(info != NULL);
    enumList = (const FPEnumDesc *) info;
    
    // Get the field value.
    
    switch (fieldSize) {
        case sizeof(int8_t):
            fieldValue = *( (const int8_t *) fieldPtr );
            break;
        case sizeof(int16_t):
            fieldValue = *( (const int16_t *) fieldPtr );
            break;
        case sizeof(int32_t):
            fieldValue = *( (const int32_t *) fieldPtr );
            break;
        default:
            assert(false);
            fieldValue = -1;
            break;
    }
    
    // Search enumList for fieldValue.

    enumIndex = 0;
    while ( (enumList[enumIndex].enumName != NULL) && (enumList[enumIndex].enumValue != fieldValue) ) {
        enumIndex += 1;
    }
    enumStr = enumList[enumIndex].enumName;
    if (enumStr == NULL) {
        enumStr = "???";
    }
    
    fprintf(stdout, "%*s%-*s = %d (%s)\n", (int) indent, "", (int) nameWidth, fieldName, fieldValue, enumStr);
}

static void FPFlagsCore(
    const char *        fieldName, 
    size_t              fieldSize, 
    const void *        fieldPtr, 
    uint32_t            indent, 
    size_t              nameWidth, 
    uint32_t            verbose, 
    const void *        info,
    const FPFlagDesc    flagList[]
)
    // *** Prints a flags field.  info is a pointer to an array of FPFlagDesc 
    // describing the known flags in the field.
    //
    // See definition of FPPrinter for a parameter description.
{
    unsigned long long flags;
    
    assert( FPStandardPreCondition() );
    assert(flagList != NULL);
    
    // First print the flag word in hex.
    
    FPHex(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info);
    
    // Then extract the flags word and print the individual flags, as long 
    // as we're in verbose mode.
    
    if (verbose > 0) {
        switch (fieldSize) {
            case sizeof(uint8_t):
                flags = *((uint8_t *) fieldPtr);
                break;
            case sizeof(uint16_t):
                flags = Swap16(fieldPtr, info);
                break;
            case sizeof(uint32_t):
                flags = Swap32(fieldPtr, info);
                break;
            case sizeof(uint64_t):
                flags = Swap64(fieldPtr, info);
                break;
            default:
                assert(false);
                flags = 0;
                break;
        }
        FPPrintFlags(flags, flagList, 0, indent + kStdIndent);
    }
}

extern void FPFlags(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
{
    assert( FPStandardPreCondition() );
    assert(info != NULL);
    
    FPFlagsCore(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, NULL, (const FPFlagDesc *) info);
}

extern void FPFlagsBE(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
{
    assert( FPStandardPreCondition() );
    assert(info != NULL);
    
    FPFlagsCore(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, (const void *) (uintptr_t) kFPValueBigEndian, (const FPFlagDesc *) info);
}

extern void FPVerboseFlags(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Just like FPFlags except that the full dump of 
    // all the flags is only printed if we're in really verbose mode.
    //
    // See definition of FPPrinter for a parameter description.
{
    assert( FPStandardPreCondition() );
    assert(info != NULL);

    if (verbose > 0) {
        verbose -= 1;
    }
    FPFlags(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info);
}

extern void FPUTCDateTime(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a UTCDateTime field.
    //
    // See definition of FPPrinter for a parameter description.
{
    static CFDateFormatterRef   sFormatter;
    static CFLocaleRef          sLocale;
    const UTCDateTime *         dateTime;
    CFStringRef                 dateTimeStr;
    CFAbsoluteTime              absoluteTime;
    Boolean                     success;
    static char                 dateTimeBuf[1024];

    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(UTCDateTime));
    dateTime = (const UTCDateTime *) fieldPtr;
    
    dateTimeStr = NULL;

    success = false;
    
    // Create the statics if they haven't been initialised yet.
    
    if (sLocale == NULL) {
        sLocale = CFLocaleCopyCurrent();
    }
    if ( (sLocale != NULL) && (sFormatter == NULL) ) {
        sFormatter = CFDateFormatterCreate(NULL, sLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle);
    }

    // Convert dateTime to a C string using the formatter, defaulting to "???" if 
    // something goes wrong.
    
    success = (UCConvertUTCDateTimeToCFAbsoluteTime(dateTime, &absoluteTime) == noErr);

    if ( (sFormatter != NULL) && success ) {
        dateTimeStr = CFDateFormatterCreateStringWithAbsoluteTime(NULL, sFormatter, absoluteTime);
    }
    if (dateTimeStr != NULL) {
        success = CFStringGetCString(dateTimeStr, dateTimeBuf, sizeof(dateTimeBuf), kCFStringEncodingUTF8);
    }
    if ( ! success ) {
        strcpy(dateTimeBuf, "???");
    }

    fprintf(stdout, "%*s%-*s = %" PRIu16 ".%" PRIu32 ".%" PRIu16 " (%s)\n", 
        (int) indent, "", 
        (int) nameWidth, fieldName, 
        dateTime->highSeconds,  
        (uint32_t) dateTime->lowSeconds,  
        dateTime->fraction,
        dateTimeBuf
    );

    // Clean up.  We don't release the statics (sLocale and sFormatter); rather, we 
    // cache them for the next time we're called.
    
    if (dateTimeStr != NULL) {
        CFRelease(dateTimeStr);
    }
}

extern void FPTimeSpec(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a timespec field.
    //
    // See definition of FPPrinter for a parameter description.
{
    size_t                  junkSize;
    const struct timespec * timeSpec;
    char                    timeBuf[256];
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(struct timespec));
    timeSpec = (const struct timespec *) fieldPtr;

    junkSize = strftime(timeBuf, sizeof(timeBuf), "%c", gmtime(&timeSpec->tv_sec));
    assert(junkSize > 0);
    
    fprintf(stdout, "%*s%-*s = %ld.%ld (%s)\n", 
        (int) indent, "", (int) nameWidth,
        fieldName, 
        timeSpec->tv_sec,
        timeSpec->tv_nsec,
        timeBuf
    );
}

static const FPFlagDesc kFinderFlags[] = {
    {kIsOnDesk,      "kIsOnDesk"},
    {kIsShared,      "kIsShared"},
    {kHasNoINITs,    "kHasNoINITs"},
    {kHasBeenInited, "kHasBeenInited"},
    {kHasCustomIcon, "kHasCustomIcon"},
    {kIsStationery,  "kIsStationery"},
    {kNameLocked,    "kNameLocked"},
    {kHasBundle,     "kHasBundle"},
    {kIsInvisible,   "kIsInvisible"},
    {kIsShared,      "kIsShared"},
    {kIsAlias,       "kIsAlias"},
    { 0, NULL }
};

static const FPFlagDesc kExtendedFinderFlags[] = {
    {kExtendedFlagsAreInvalid,    "kExtendedFlagsAreInvalid"},
    {kExtendedFlagHasCustomBadge, "kExtendedFlagHasCustomBadge"},
    {kExtendedFlagObjectIsBusy,   "kExtendedFlagObjectIsBusy"},
    {kExtendedFlagHasRoutingInfo, "kExtendedFlagHasRoutingInfo"},
    { 0, NULL }
};

static const FPFieldDesc kFileInfoFieldDesc[] = {
    {"fileType",        offsetof(FileInfo, fileType),       sizeof(OSType),    FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {"fileCreator",     offsetof(FileInfo, fileCreator),    sizeof(OSType),    FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {"finderFlags",     offsetof(FileInfo, finderFlags),    sizeof(UInt16),    FPFlags, kFinderFlags},
    {"location.v",      offsetof(FileInfo, location.v),     sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"location.h",      offsetof(FileInfo, location.h),     sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reservedField",   offsetof(FileInfo, reservedField),  sizeof(UInt16),    FPUDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kExtendedFileInfoFieldDesc[] = {
    {"reserved1[1]",        offsetof(ExtendedFileInfo, reserved1[0]),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reserved1[2]",        offsetof(ExtendedFileInfo, reserved1[1]),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reserved1[3]",        offsetof(ExtendedFileInfo, reserved1[2]),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reserved1[4]",        offsetof(ExtendedFileInfo, reserved1[3]),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"extendedFinderFlags", offsetof(ExtendedFileInfo, extendedFinderFlags),    sizeof(UInt16),    FPFlags, kExtendedFinderFlags},
    {"reserved2",           offsetof(ExtendedFileInfo, reserved2),              sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"putAwayFolderID",     offsetof(ExtendedFileInfo, putAwayFolderID),        sizeof(UInt32),    FPUDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFolderInfoFieldDesc[] = {
    {"windowBounds.top",    offsetof(FolderInfo, windowBounds.top),     sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"windowBounds.left",   offsetof(FolderInfo, windowBounds.left),    sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"windowBounds.bottom", offsetof(FolderInfo, windowBounds.bottom),  sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"windowBounds.right",  offsetof(FolderInfo, windowBounds.right),   sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"finderFlags",         offsetof(FolderInfo, finderFlags),          sizeof(UInt16),    FPFlags, kFinderFlags},
    {"location.v",          offsetof(FolderInfo, location.v),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"location.h",          offsetof(FolderInfo, location.h),           sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reservedField",       offsetof(FolderInfo, reservedField),        sizeof(UInt16),    FPUDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kExtendedFolderInfoFieldDesc[] = {
    {"scrollPosition.v",    offsetof(ExtendedFolderInfo, scrollPosition.v),     sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"scrollPosition.h",    offsetof(ExtendedFolderInfo, scrollPosition.h),     sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"reserved1",           offsetof(ExtendedFolderInfo, reserved1),            sizeof(SInt32),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"extendedFinderFlags", offsetof(ExtendedFolderInfo, extendedFinderFlags),  sizeof(UInt16),    FPFlags, kExtendedFinderFlags},
    {"reserved2",           offsetof(ExtendedFolderInfo, reserved2),            sizeof(SInt16),    FPSDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {"putAwayFolderID",     offsetof(ExtendedFolderInfo, putAwayFolderID),      sizeof(UInt32),    FPUDec, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kVolumeFinderInfoFieldDesc[] = {
    {"finderInfo[0]",   0 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // dirID of active System Folder
    {"finderInfo[1]",   1 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // dirID of startup application, obsolete
    {"finderInfo[2]",   2 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // dirID of first open Finder window, mostly obsolete
    {"finderInfo[3]",   3 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // dirID of traditional Mac OS System Folder
    {"finderInfo[4]",   4 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // reserved
    {"finderInfo[5]",   5 * sizeof(UInt32), sizeof(UInt32), FPUDec, (const void *) (uintptr_t) kFPValueHostEndian}, // dirID of Mac OS X System Folder
    {"finderInfo[6:7]", 6 * sizeof(UInt32), sizeof(UInt64), FPHex,  (const void *) (uintptr_t) kFPValueHostEndian}, // GUID
    {NULL, 0, 0, NULL, NULL}
};

static void FPFinderInfoCore(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info,
    FPEndian        endian
)
    // Prints a Finder info field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const uint32_t * finderInfo;

    assert( FPStandardPreCondition() );
    assert( (fieldSize == 32) || (fieldSize == 16) );
    
    if (verbose == 0) {
        FPHex(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info);
    } else {
        FinderInfoFlavour           flavour;

        fprintf(stdout, "%*s%s:\n", (int) indent, "", fieldName);
        
        flavour = (FinderInfoFlavour) (uintptr_t) info;
        switch (flavour) {
            case kVolumeInfo:
                assert(fieldSize == 32);
                finderInfo = (const uint32_t *) fieldPtr;
                FPPrintFieldsCore(kVolumeFinderInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFileInfo:
                assert(fieldSize == 16);
                FPPrintFieldsCore(kFileInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFileInfoExtended:
                assert(fieldSize == 16);
                FPPrintFieldsCore(kExtendedFileInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFileInfoCombined:
                assert(fieldSize == 32);
                FPPrintFieldsCore(kFileInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                FPPrintFieldsCore(kExtendedFileInfoFieldDesc, ((const char *) fieldPtr) + 16, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFolderInfo:
                assert(fieldSize == 16);
                FPPrintFieldsCore(kFolderInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFolderInfoExtended:
                assert(fieldSize == 16);
                FPPrintFieldsCore(kExtendedFolderInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            case kFolderInfoCombined:
                assert(fieldSize == 32);
                FPPrintFieldsCore(kFolderInfoFieldDesc, fieldPtr, fieldSize, indent + kStdIndent, verbose - 1, endian);
                FPPrintFieldsCore(kExtendedFolderInfoFieldDesc, ((const char *) fieldPtr) + 16, fieldSize, indent + kStdIndent, verbose - 1, endian);
                break;
            default:
                assert(false);
                break;
        }
    }
}

extern void FPFinderInfo(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
{
    FPFinderInfoCore(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info, kFPValueHostEndian);
}

extern void FPFinderInfoBE(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
{
    FPFinderInfoCore(fieldName, fieldSize, fieldPtr, indent, nameWidth, verbose, info, kFPValueBigEndian);
}
