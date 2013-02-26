/*
    File:       FieldPrinter.h

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

#ifndef _FIELDPRINTER_H
#define _FIELDPRINTER_H

/////////////////////////////////////////////////////////////////

// System interfaces

#include <CoreServices/CoreServices.h>

/////////////////////////////////////////////////////////////////
#pragma mark ***** Parameters

enum {
    kStdIndent = 4
};

/////////////////////////////////////////////////////////////////
#pragma mark ***** FieldPrinter Infrastructure

typedef void (*FPPrinter)(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
);
    // FPPrinter represents a routine that is called to print a structure field. 
    //
    // fieldName is the name of the field.
    //
    // fieldSize and fieldPtr describe the memory that holds the field value. 
    //
    // indent is the number of spaces to print before each line.
    //
    // nameWidth is the required total width when printing fieldName.  If this is 0, 
    // an appropriate default is used.
    //
    // verbose describes the level of verbosity; it starts at 0 and is incremented 
    // for each "-v" on the command line
    //
    // info is a routine-specific parameter

// FPStandardPreCondition is a macro that you can assert in your field printer 
// routines to check their incoming parameters.  It's a macro so that it can 
// access the parameters by name.

#define FPStandardPreCondition()                                    \
    (                                                               \
       ( fieldName != NULL )                                        \
    && ( fieldSize != 0 )                                           \
    && ( fieldPtr != NULL )                                         \
    && ( (nameWidth != 0) && (nameWidth >= strlen(fieldName)) )     \
    )

/////////////////////////////////////////////////////////////////
#pragma mark ***** Utilities

extern char *   FPPStringToUTFCString(ConstStr255Param pstr, CFStringEncoding pstrEncoding);
    // Returns a UTF-8 encoded C string that represents the input 
    // Pascal string (pstr, encoded using pstrEncoding).
    // The caller is responsible for disposing of the C string 
    // using "free".

// Forward declarations.  See the full description below.

typedef struct FPFlagDesc FPFlagDesc;
typedef struct FPEnumDesc FPEnumDesc;

extern void FPPrintFlags(unsigned long long flags, const FPFlagDesc *flagList, size_t nameWidth, uint32_t indent);
    // Prints information about a set of flags in a flags word.  flagList is 
    // an array of FPFlagDesc that describes the flags in the word.  nameWidth 
    // is the width to use when printing the name field, unless it's 0 in 
    // which cause the routine automatically calculates the width based 
    // on the longest name of the flags to be printed. indent is the number 
    // of spaces to print before each line.

// FPFieldDesc allows you to specify the fields to be printed by FPPrintFields.  
// An array of FPFieldDesc is used to hold information about all of the fields 
// in a particular structure.  The array is terminated by an entry with a NULL 
// name.

struct FPFieldDesc {
    const char *    fieldName;
    size_t          fieldOffset;
    size_t          fieldSize;
    FPPrinter       fieldPrinter;       // routine to print this field
    const void *    fieldInfo;          // parameter for the fieldPrinter
};
typedef struct FPFieldDesc FPFieldDesc;

extern void FPPrintFields(const FPFieldDesc fields[], const void *fieldBuf, size_t fieldBufSize, uint32_t indent, uint32_t verbose);
    // Prints the fields of a particular structure, as defined by the 
    // fields array.  fieldBuf is a pointer to a the structure.  
    // fieldBufSize is the size of that structure (which is used 
    // solely for debugging).  indent is the number of spaces to 
    // print before each line.  See FPPrinter for a description 
    // of the verbose parameter.

// FPSizeMultiplier allows you to specify a size multiplier field when using the 
// SizeFieldPrinter routine.  You pass a pointer to a FPSizeMultiplier structure 
// as the info parameter to SizeFieldPrinter.  This tells SizeFieldPrinter 
// about another field that holds the size multiplier for this field.  For 
// example, in structure S, if field A represents the disk free space in blocks 
// and field B is an int holding the block size in bytes, when printing A you 
// would pass a FPSizeMultiplier whose multiplierOffset is 
// offsetof(S, B) - offsetof(S, A) and whose multiplierSize field is sizeof(int)

struct FPSizeMultiplier {
    size_t      multiplierOffset;               // offset from the fieldPtr to the multiplier field
    size_t      multiplierSize;                 // size of the multiplier field
};
typedef struct FPSizeMultiplier FPSizeMultiplier;

// FPEnumDesc allows you to specify the known values when using the EnumFieldPrinter 
// routine.  You pass a pointer to an array of FPEnumDesc as the info parameter to 
// EnumFieldPrinter.  The array is terminated by an entry with a NULL name.  
// Note that the array does not have to be sorted by enumValue.
//
// This implicitly assumes that int is large enough to hold all 
// likely enumerated values.  This has proved to be the case so far.

struct FPEnumDesc {
    int             enumValue;
    const char *    enumName;
};

// FPFlagDesc allows you to specify the known flags when using the FlagsFieldPrinter 
// routine.  You pass a pointer to an array of FPFlagDesc as the info parameter to 
// FlagsFieldPrinter.  The array is terminated by an entry with a NULL 
// name.

struct FPFlagDesc {
    unsigned long long  flagMask;
    const char *        flagName;
};

enum {
    kFPNotFound = ((size_t) -1)
};

extern size_t FPFindFlagByName(const FPFlagDesc flagList[], const char *flagName);
extern size_t FPFindEnumByValue(const FPEnumDesc enumList[], int enumValue);
extern size_t FPFindEnumByName(const FPEnumDesc enumList[], const char *enumName);
    // returns index into array, or kFPNotFound if not found

// Flags for the info parameters of FPHex, FPSDec, FPUDec, FPSignature.

enum FPEndian {
    kFPValueHostEndian   = 0,
    kFPValueBigEndian    = 1,
    kFPValueLittleEndian = 2
};
typedef enum FPEndian FPEndian;

/////////////////////////////////////////////////////////////////
#pragma mark ***** Field Printers

extern void FPNull(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints nothing.  Useful if you want to pad out the nameWidth of a group of fields.
extern void FPCString(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a C string field, assumed to be encoded as UTF-8.
extern void FPCStringPtr(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a C string pointer field, assumed to be encoded as UTF-8.
extern void FPPString(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a Pascal string field; info is the text encoding.
extern void FPCFString(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a CFStringRef field.
extern void FPCFDictionary(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a CFDictionaryRef field.
extern void FPCFType(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a CFTypeRef field.  known to work well with CFNumber, CFBoolean, CFUUID and CFURL.
extern void HFSUniStr255FieldPrinter(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints an HFSUniStr255 field.
extern void FPPtr(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints generic pointer field.
extern void FPBoolean(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a Boolean field.
extern void FPHex(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a field in hex.
extern void FPSDec(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a signed decimal field.
extern void FPUDec(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints an unsigned decimal field.
extern void FPSize(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a field that holds a size in bytes (if info is NULL) or in the units specified 
    // by the FPSizeMultiplier pointed to be info.
extern void FPSignature(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints an OSType field.
extern void FPDevT(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a dev_t field.
extern void FPUID(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a uid_t field.
extern void FPGID(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a gid_t field.
extern void FPGUID(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a guid_t field representing a user or group.
extern void FPModeT(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a mode_t field.
extern void FPEnum(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints an enumerated type field; info is a pointer to an array of FPEnumDesc.
extern void FPFlags(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a bitfield of flags; info is a pointer to an array of FPFlagDesc.  Only prints the 
    // individual flags is verbose is greater than zero.
extern void FPFlagsBE(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
extern void FPVerboseFlags(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Like FPFlags, but verbose has to be greater than 1 to get the individual flags.
extern void FPUTCDateTime(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a UTCDateTime field.
extern void FPTimeSpec(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a (struct timespec) field.

enum FinderInfoFlavour {
    kVolumeInfo,
    kFileInfo,
    kFileInfoExtended,
    kFileInfoCombined,
    kFolderInfo,
    kFolderInfoExtended,
    kFolderInfoCombined
};
typedef enum FinderInfoFlavour FinderInfoFlavour;

extern void FPFinderInfo(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
extern void FPFinderInfoBE(const char *, size_t, const void *, uint32_t, size_t, uint32_t, const void *);
    // Prints a 32-byte Finder info field.  The info parameter controls how the Finder 
    // info is printed; it must be one of the FinderInfoFlavour values.

#endif
