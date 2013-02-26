/*
    File:       AliasManager.c

    Contains:   Alias Manager command processing.

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

#include "FieldPrinter.h"
#include "Command.h"

#pragma mark *     GetAliasInfo

#if ! TARGET_RT_64_BIT

enum AliasFieldIndex {
    kZoneName,
    kServerName,
    kVolumeName,
    kAliasName,
    kParentName,
    kPathElements
};
typedef enum AliasFieldIndex AliasFieldIndex;

typedef unsigned int AliasFieldMask;

static const char kGetAliasInfoFieldSpacer[32] = "asiServerName";

static OSStatus PrintAliasField(AliasHandle aliasH, SInt16 infoIndex, const char *name, uint32_t indent, uint32_t verbose)
    // Print a value (as determined by infoIndex, for example asiZoneName) from an alias.
{
    OSStatus    err;
    Str63       fieldStr;
    
    assert(aliasH != NULL);
    
    err = GetAliasInfo(aliasH, infoIndex, fieldStr);
    
    if (err == noErr) {
        // kCFStringEncodingMacRoman is a guess because there's no good way to tell 
        // what the text encoding is.
        
        FPPString(name, sizeof(fieldStr), fieldStr, indent, strlen(kGetAliasInfoFieldSpacer), verbose, kCFStringEncodingMacRoman);
    }
    
    return err;
}

static OSStatus PrintAliasWholePath(AliasHandle aliasH, uint32_t indent, uint32_t verbose)
    // Print the path from the alias.
{
    OSStatus    err;
    SInt16      infoIndex;
    Str255      fieldStr;
    char        name[32];

    fprintf(stdout, "%*sPath Elements\n", (int) indent, "");
    infoIndex = asiAliasName;
    do {
        err = GetAliasInfo(aliasH, infoIndex, fieldStr);
        if (err != noErr) {
            break;
        }
        if (fieldStr[0] == 0) {
            break;
        }
        snprintf(name, sizeof(name), "[%d]", infoIndex);
        FPPString(name, sizeof(fieldStr), fieldStr, indent + kStdIndent, 7, verbose, kCFStringEncodingMacRoman);
        infoIndex += 1;
    } while (true);
    
    return err;
}

static const FPFlagDesc kAliasFields[] = {
    { 1 << kZoneName,     "asiZoneName" },
    { 1 << kServerName,   "asiServerName" },
    { 1 << kVolumeName,   "asiVolumeName" },
    { 1 << kAliasName,    "asiAliasname" },
    { 1 << kParentName,   "asiParentName" },
    { 1 << kPathElements, "asiPathElements" },
    { 0, NULL }
};

static CommandError PrintGetAliasinfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses GetAliasInfo to get information about the 
    // specified item and prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus            err;
    AliasFieldMask      optionsMask;
    FSRef               itemRef;
    AliasHandle         itemAlias;
    
    optionsMask = 0;            // quiten warning
    itemAlias = NULL;
    
    if ( CommandArgsIsOption(args) ) {
        uint64_t    result;

        err = CommandArgsGetFlagList(args, kAliasFields, &result);
        if ( (err == noErr) && (result != 0) ) {
            optionsMask = (AliasFieldMask) result;
        } else {
            err = kCommandUsageErr;
        }
    } else {
        optionsMask =
               (1 << kZoneName)
             | (1 << kServerName)
             | (1 << kVolumeName)
             | (1 << kPathElements);
        err = noErr;
    }
    
    // Make an alias to the item.
    
    if (err == noErr) {
        err = CommandArgsGetFSRef(args, &itemRef);
    }
    if (err == noErr) {
        err = FSNewAlias(NULL, &itemRef, &itemAlias);
    }
    
    // Get and print info about it.
    
    if ( (err == 0) && (optionsMask & (1 << kZoneName)) ) {
        err = PrintAliasField(itemAlias, asiZoneName,   "asiZoneName",   indent + kStdIndent, verbose);
    }
    if ( (err == 0) && (optionsMask & (1 << kServerName)) ) {
        err = PrintAliasField(itemAlias, asiServerName, "asiServerName", indent + kStdIndent, verbose);
    }
    if ( (err == 0) && (optionsMask & (1 << kVolumeName)) ) {
        err = PrintAliasField(itemAlias, asiVolumeName, "asiVolumeName", indent + kStdIndent, verbose);
    }
    if ( (err == 0) && (optionsMask & (1 << kPathElements)) ) {
        err = PrintAliasWholePath(itemAlias, indent + kStdIndent, verbose);
    } else {
        if ( (err == 0) && (optionsMask & (1 << kAliasName)) ) {
            err = PrintAliasField(itemAlias, asiAliasName,  "asiAliasName",  indent + kStdIndent, verbose);
        }
        if ( (err == 0) && (optionsMask & (1 << kParentName)) ) {
            err = PrintAliasField(itemAlias, asiParentName, "asiParentName", indent + kStdIndent, verbose);
        }
    }
    
    // Clean up.
    
    if (itemAlias != NULL) {
        DisposeHandle( (Handle) itemAlias);
        assert(MemError() == noErr);
    }
    
    return CommandErrorMakeWithOSStatus(err);
}

static const CommandHelpEntry kGetAliasInfoCommandHelp[] = {
    {CommandHelpString, "-indexList Alias information to get; defaults to asiZoneName,"},
    {CommandHelpString, "           asiServerName,asiVolumeName,asiPathElements"},
    {CommandHelpFlags,  kAliasFields},
    {NULL, NULL}
};

const CommandInfo kGetAliasInfoCommand = {
    PrintGetAliasinfo,
    "GetAliasInfo",
    "[ -indexList ] itemPath",
    "Print information from GetAliasinfo.",
    kGetAliasInfoCommandHelp
};

#endif

#pragma mark *     FSCopyAliasInfo

// The fields of the FSAliasInfo structure.  These are broken up into three 
// groups because FSCopyAliasInfo does not always return all information for 
// a given alias.

static const char kFSAliasInfoFieldSpacer[32] = "volumeHasPersistentFileIDs";

static const FPFieldDesc kFSAliasInfoFieldDescVolumeCreateDate[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"volumeCreateDate",            offsetof(FSAliasInfo, volumeCreateDate),            sizeof(UTCDateTime),    FPUTCDateTime, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescTargetCreateDate[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"targetCreateDate",            offsetof(FSAliasInfo, targetCreateDate),            sizeof(UTCDateTime),    FPUTCDateTime, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescFinderInfo[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"fileType",                    offsetof(FSAliasInfo, fileType),                    sizeof(OSType),         FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {"fileCreator",                 offsetof(FSAliasInfo, fileCreator),                 sizeof(OSType),         FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescFSInfo[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"filesystemID",                offsetof(FSAliasInfo, filesystemID),                sizeof(UInt16),         FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {"signature",                   offsetof(FSAliasInfo, signature),                   sizeof(UInt16),         FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescIDs[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"parentDirID",                 offsetof(FSAliasInfo, parentDirID),                 sizeof(UInt32),         FPUDec, NULL},
    {"nodeID",                      offsetof(FSAliasInfo, nodeID),                      sizeof(UInt32),         FPUDec, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescVolumeFlags[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"volumeIsBootVolume",          offsetof(FSAliasInfo, volumeIsBootVolume),          sizeof(Boolean),        FPBoolean, NULL},
    {"volumeIsAutomounted",         offsetof(FSAliasInfo, volumeIsAutomounted),         sizeof(Boolean),        FPBoolean, NULL},
    {"volumeIsEjectable",           offsetof(FSAliasInfo, volumeIsEjectable),           sizeof(Boolean),        FPBoolean, NULL},
    {"volumeHasPersistentFileIDs",  offsetof(FSAliasInfo, volumeHasPersistentFileIDs),  sizeof(Boolean),        FPBoolean, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kFSAliasInfoFieldDescIsDirectory[] = { 
    {kFSAliasInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"isDirectory",                 offsetof(FSAliasInfo, isDirectory),                 sizeof(Boolean),        FPBoolean, NULL},
    {NULL, 0, 0, NULL, NULL}
};

enum {
    kRequestTargetName = (1 << 0),
    kRequestVolumeName = (1 << 1),
    kRequestPathString = (1 << 2),
    kRequestInfo       = (1 << 4),
    
    kRequestEverything = 
          kRequestTargetName
        | kRequestVolumeName
        | kRequestPathString
        | kRequestInfo
};

static const FPFlagDesc kRequestFlags[] = {
    { kRequestTargetName,       "targetName" },
    { kRequestVolumeName,       "volumeName" },
    { kRequestPathString,       "pathString" },
    { kRequestInfo,             "info" },
    { 0, NULL }
};

static int AliasInfoBitMapTester(const char *item, void *refCon)
    // A CommandParseItemString that tests whether the item is in kRequestFlags 
    // and, if so, set this corresponding bit in *refCon.
{
    int         err;
    uint32_t *  requestedInfoPtr;
    size_t      flagIndex;

    assert(item != NULL);
    requestedInfoPtr = (uint32_t *) refCon;
    assert(requestedInfoPtr != NULL);
    
    flagIndex = FPFindFlagByName(kRequestFlags, item);
    if (flagIndex == kFPNotFound) {
        err = EUSAGE;
    } else {
        *requestedInfoPtr |= (uint32_t) kRequestFlags[flagIndex].flagMask;
        err = 0;
    }
    
    return err;
}

static CommandError PrintFSCopyAliasInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses FSCopyAliasInfo to get information about the 
    // specified item and prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus            err;
    const char *        optionsStr;
    FSRef               itemRef;
    AliasHandle         itemAlias;
    uint32_t            requestedInfo;
    FSAliasInfoBitmap   returnedInInfo;
    HFSUniStr255        targetName;
    HFSUniStr255        volumeName;
    CFStringRef         pathString;
    FSAliasInfo         info;
    
    itemAlias = NULL;
    pathString = NULL;

    err = noErr;
    if ( CommandArgsGetOptionString(args, &optionsStr) ) {
        requestedInfo = 0;
        
        assert(optionsStr[0] == '-');
        if ( CommandParseItemString(&optionsStr[1], ',', AliasInfoBitMapTester, &requestedInfo) != 0 ) {
            err = kCommandUsageErr;
        }
    } else {
        requestedInfo = kRequestEverything;
    }
    
    // Make an alias to the item.
    
    if (err == noErr) {
        err = CommandArgsGetFSRef(args, &itemRef);
    }
    if (err == noErr) {
        err = FSNewAlias(NULL, &itemRef, &itemAlias);
    }
    
    // Get info about it.
    
    if (err == noErr) {
        err = FSCopyAliasInfo(
            itemAlias,
            (requestedInfo & kRequestTargetName) ? &targetName     : NULL,
            (requestedInfo & kRequestVolumeName) ? &volumeName     : NULL,
            (requestedInfo & kRequestPathString) ? &pathString     : NULL,
            (requestedInfo & kRequestInfo)       ? &returnedInInfo : NULL,
            (requestedInfo & kRequestInfo)       ? &info           : NULL
        );
    }
    
    // Print that info.
    
    if (err == noErr) {
        if (requestedInfo & kRequestTargetName) {
            HFSUniStr255FieldPrinter("targetName", sizeof(targetName), &targetName, indent, strlen(kFSAliasInfoFieldSpacer), verbose, NULL);
        }
        if (requestedInfo & kRequestVolumeName) {
            HFSUniStr255FieldPrinter("volumeName", sizeof(volumeName), &volumeName, indent, strlen(kFSAliasInfoFieldSpacer), verbose, NULL);
        }
        if (requestedInfo & kRequestPathString) {
            FPCFString("pathString", sizeof(pathString), &pathString, indent, strlen(kFSAliasInfoFieldSpacer), verbose, NULL);
        }
        if (requestedInfo & kRequestInfo) {
            if (returnedInInfo & kFSAliasInfoVolumeCreateDate) {
                FPPrintFields(kFSAliasInfoFieldDescVolumeCreateDate, &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoTargetCreateDate) {
                FPPrintFields(kFSAliasInfoFieldDescTargetCreateDate, &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoFinderInfo) {
                FPPrintFields(kFSAliasInfoFieldDescFinderInfo,       &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoIsDirectory) {
                FPPrintFields(kFSAliasInfoFieldDescIsDirectory,      &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoIDs) {
                FPPrintFields(kFSAliasInfoFieldDescIDs,              &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoFSInfo) {
                FPPrintFields(kFSAliasInfoFieldDescFSInfo,           &info, sizeof(info), indent, verbose);
            }
            if (returnedInInfo & kFSAliasInfoVolumeFlags) {
                FPPrintFields(kFSAliasInfoFieldDescVolumeFlags,      &info, sizeof(info), indent, verbose);
            }
        }
    }

    if (pathString != NULL) {
        CFRelease(pathString);
    }
    if (itemAlias != NULL) {
        DisposeHandle( (Handle) itemAlias);
        assert(MemError() == noErr);
    }
    
    return CommandErrorMakeWithOSStatus(err);
}

static const CommandHelpEntry kFSCopyAliasInfoCommandHelp[] = {
    {CommandHelpString, "-paramList Alias information to get; defaults to everything"},
    {CommandHelpFlags,  kRequestFlags},
    {NULL, NULL}
};

const CommandInfo kFSCopyAliasInfoCommand = {
    PrintFSCopyAliasInfo,
    "FSCopyAliasInfo",
    "[ -paramList ] itemPath",
    "Print information from FSCopyAliasInfo.",
    kFSCopyAliasInfoCommandHelp
};
