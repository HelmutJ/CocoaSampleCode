/*
    File:       Command.c

    Contains:   Utilities for command processing.

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

#include "Command.h"

#include <CoreServices/CoreServices.h>

#include "FieldPrinter.h"

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Errors

extern bool CommandErrorIsNoError(CommandError commandError)
    // See comment in header.
{
    return (  ((commandError.domain == kCommandErrorOSStatus) && (commandError.u.errOSStatus == noErr ))
           || ((commandError.domain == kCommandErrorErrno   ) && (commandError.u.errErrno    == 0     ))
           );
}

extern bool CommandErrorIsUsage(CommandError commandError)
    // See comment in header.
{
    return (  ((commandError.domain == kCommandErrorCustom  ) && (commandError.u.errCustom   == kUsageCustomError))
           || ((commandError.domain == kCommandErrorOSStatus) && (commandError.u.errOSStatus == kCommandUsageErr ))
           || ((commandError.domain == kCommandErrorErrno   ) && (commandError.u.errErrno    == EUSAGE           ))
           );
}

extern CommandError CommandErrorMakeWithCustom(CustomError errNum)
    // See comment in header.
{
    CommandError result;
    
    result.domain = kCommandErrorCustom;
    result.u.errCustom = errNum;
    return result;
}

extern CommandError CommandErrorMakeWithErrno(int errNum)
    // See comment in header.
{
    CommandError result;
    
    if (errNum == EUSAGE) {
        result.domain = kCommandErrorCustom;
        result.u.errCustom = kUsageCustomError;
    } else {
        result.domain = kCommandErrorErrno;
        result.u.errErrno = errNum;
    }
    return result;
}

extern CommandError CommandErrorMakeWithOSStatus(OSStatus errNum)
    // See comment in header.
{
    CommandError result;
    
    if (errNum == kCommandUsageErr) {
        result.domain = kCommandErrorCustom;
        result.u.errCustom = kUsageCustomError;
    } else {
        result.domain = kCommandErrorOSStatus;
        result.u.errOSStatus = errNum;
    }
    return result;
}

extern void CommandErrorPrint(CommandError commandError, const char *operation, uint32_t indent)
    // See comment in header.
{
    assert(operation != NULL);
    
    assert( ! CommandErrorIsUsage(commandError) );
    
    switch (commandError.domain) {
        case kCommandErrorCustom:
            assert(commandError.u.errCustom == kUnavailableCustomError);
            fprintf(
                stderr, 
                "%*s%s failed because the required system functionality is not available.\n", 
                (int) indent, 
                "", 
                operation
            );
            break;
        case kCommandErrorOSStatus:
            if (commandError.u.errOSStatus != noErr) {
                fprintf(
                    stderr, 
                    "%*s%s failed with error %ld.\n", 
                    (int) indent, 
                    "", 
                    operation, 
                    (long) commandError.u.errOSStatus
                );
            }
            break;
        case kCommandErrorErrno:
            if (commandError.u.errErrno != 0) {
                fprintf(
                    stderr, 
                    "%*s%s failed with error '%s' (%d).\n", 
                    (int) indent, 
                    "", 
                    operation, 
                    strerror(commandError.u.errErrno), 
                    commandError.u.errErrno
                );
            }
            break;
        default:
            assert(false);
    }
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Arguments

extern bool CommandArgsValid(CommandArgsRef args)
    // See comment in header.
{
    return (args != NULL) && (*args != NULL);
}

extern errno_t CommandArgsGetString(CommandArgsRef args, const char **strPtr)
    // See comment in header.
{
    int err;
    
    assert( CommandArgsValid(args) );
    assert( strPtr != NULL );
    
    if (**args == NULL) {
        err = EUSAGE;
    } else {
        *strPtr = **args;
        *args += 1;
        err = 0;
    }
    return err;
}

extern OSStatus CommandArgsGetStringOSStatus(CommandArgsRef args, const char **strPtr)
    // See comment in header.
{
    OSStatus err;

    assert( CommandArgsValid(args) );
    assert( strPtr != NULL );
    
    err = noErr;
    if ( CommandArgsGetString(args, strPtr) != 0 ) {
        err = kCommandUsageErr;
    }
    return err;
}

extern OSStatus CommandArgsGetVRefNum(CommandArgsRef args, FSVolumeRefNum *vRefNumPtr)
    // See comment in header.
{
    OSStatus        err;
    const char *    itemPath;
    FSRef           volRef;
    FSCatalogInfo   volCatInfo;

    assert( CommandArgsValid(args) );
    assert( vRefNumPtr != NULL );
    
    err = CommandArgsGetStringOSStatus(args, &itemPath);
    if (err == noErr) {
        err = FSPathMakeRef( (const UInt8 *) itemPath, &volRef, NULL);
    }
    if (err == noErr) {
        err = FSGetCatalogInfo(&volRef, kFSCatInfoVolume, &volCatInfo, NULL, NULL, NULL);
    }
    if (err == noErr) {
        *vRefNumPtr = volCatInfo.volume;
    }
    
    return err;
}

static bool gDontFollowLeafSymLinksForFSRefs;

extern void SetDontFollowLeafSymLinksForFSRefs(void)
    // See comment in header.
{
    gDontFollowLeafSymLinksForFSRefs = true;
}

extern OSStatus CommandArgsGetFSRef(CommandArgsRef args, FSRef *fsRefPtr)
    // See comment in header.
{
    OSStatus        err;
    const char *    itemPath;
    
    assert( CommandArgsValid(args) );
    assert( fsRefPtr != NULL );
    
    err = CommandArgsGetStringOSStatus(args, &itemPath);
    if (err == noErr) {
        if (gDontFollowLeafSymLinksForFSRefs) {
            if (FSPathMakeRefWithOptions == NULL) {
                static bool sHasPrinted;
                
                // If FSPathMakeRefWithOptions is unavailable, just do what 
                // we've always done.  I could work around this (by getting 
                // the FSRef of the parent and iterating the directory looking 
                // for the item of interest), but life is too short.
                
                if ( ! sHasPrinted ) {
                    fprintf(stderr, "Ignoring '-l' option because FSPathMakeRefWithOptions is not available.");
                }
                err = FSPathMakeRef( (const UInt8 *) itemPath, fsRefPtr, NULL);
            } else {
                err = FSPathMakeRefWithOptions( (const UInt8 *) itemPath, kFSPathMakeRefDoNotFollowLeafSymlink, fsRefPtr, NULL);
            }
        } else {
            err = FSPathMakeRef( (const UInt8 *) itemPath, fsRefPtr, NULL);
        }
    }
    return err;
}

extern bool CommandArgsIsOption(CommandArgsRef args)
    // See comment in header.
{
    bool result;

    assert( CommandArgsValid(args) );
    
    result = false;
    if (**args != NULL) {
        result = ((**args)[0] == '-');
    }
    return result;
}

extern bool CommandArgsGetOptionalConstantString(CommandArgsRef args, const char *optionalArg)
    // See comment in header.
{
    bool result;
    
    assert( CommandArgsValid(args) );
    assert( optionalArg != NULL );

    result = false;
    if (**args != NULL) {
        if ( strcasecmp(**args, optionalArg) == 0 ) {
            *args += 1;
            result = true;
        }
    }
    return result;
}

extern bool CommandArgsGetOptionString(CommandArgsRef args, const char **optionArgPtr)
    // See comment in header.
{
    bool result;
    
    assert( CommandArgsValid(args) );
    assert( optionArgPtr != NULL );

    result = false;
    if (**args != NULL) {
        if ((**args)[0] == '-') {
            *optionArgPtr = **args;
            *args += 1;
            result = true;
        }
    }
    return result;
}

static int ParseItemStringForFlags(const char *str, char delimiter, const FPFlagDesc flagList[], uint64_t *resultPtr);
    // forward
    
extern errno_t CommandArgsGetFlagList(CommandArgsRef args, const FPFlagDesc flagList[], uint64_t *resultPtr)
    // See comment in header.
{
    int             err;
    const char *    argStr;
    
    assert( CommandArgsValid(args) );
    assert( flagList != NULL );
    assert( flagList[0].flagName != NULL );
    assert( resultPtr != NULL );

    *resultPtr = 0;

    err = 0;
    if ( CommandArgsGetOptionString(args, &argStr) ) {
        assert( argStr[0] == '-' );
        err = ParseItemStringForFlags(&argStr[1], ',', flagList, resultPtr);
    }

    return err;
}

extern errno_t CommandArgsGetFlagListInt(CommandArgsRef args, const FPFlagDesc flagList[], int *resultPtr)
    // See comment in header.
{
    int         err;
    uint64_t    tmp;

    assert( CommandArgsValid(args) );
    assert( flagList != NULL );
    assert( flagList[0].flagName != NULL );
    assert( resultPtr != NULL );
    
    err = CommandArgsGetFlagList(args, flagList, &tmp);
    *resultPtr = (int) tmp;
    return err;
}

static int CommandArgsGetLongLong(CommandArgsRef args, long long *argPtr)
    // The internal core of CommandArgsGetSizeT and CommandArgsGetInt.
{
    int err;
    
    assert( CommandArgsValid(args) );
    assert( argPtr != NULL );

    err = 0;
    if (**args != NULL) {
        char *  end;
        
        *argPtr = strtoll(**args, &end, 10);
        if ( ((**args)[0] == 0) || (end[0] != 0) ) {
            err = EUSAGE;
        } else {
            *args += 1;
        }
    } else {
        err = EUSAGE;
    }
    return err;
}

extern errno_t CommandArgsGetSizeT(CommandArgsRef args, size_t *argPtr)
    // See comment in header.
{
    int         err;
    long long   tmp;

    assert( CommandArgsValid(args) );
    assert( argPtr != NULL );
    
    err = CommandArgsGetLongLong(args, &tmp);
    if (err == 0) {
        *argPtr = (size_t) tmp;
        if ( (tmp < 0) || ((long long) *argPtr != tmp) ) {
            err = ERANGE;
        }
    }
    return err;
}

extern errno_t CommandArgsGetInt(CommandArgsRef args, int *argPtr)
    // See comment in header.
{
    int         err;
    long long   tmp;

    assert( CommandArgsValid(args) );
    assert( argPtr != NULL );
    
    err = CommandArgsGetLongLong(args, &tmp);
    if (err == 0) {
        *argPtr = (int) tmp;
        if ( (long long) *argPtr != tmp ) {
            err = ERANGE;
        }
    }
    return err;
}

static void SkipSpace(const char **cursorPtr)
    // A helper routine for CommandParseItemString.  Advances *cursorPtr while 
    // **cursorPtr is whitespace.
{
    assert( cursorPtr != NULL);
    assert(*cursorPtr != NULL);
    
    while ( isblank(**cursorPtr) ) {
        *cursorPtr += 1;
    }
}

static int ParseItem(const char **cursorPtr, CommandParseItemStringTester itemTester, void *refCon)
    // A helper routine for CommandParseItemString.  Parses an item (a sequence 
    // of alphanumeric characters, including "_", with leading and trailing whitespace 
    // trimmed) at *cursorPtr, advancing *cursorPtr to reflect the amount parsed, 
    // and verifies the item by calling the itemTester routine.
{
    int     err;
    const char *    itemStart;

    assert( cursorPtr != NULL);
    assert(*cursorPtr != NULL);

    SkipSpace(cursorPtr);

    err = 0;
    itemStart = *cursorPtr;
    while ( isalnum(**cursorPtr) || (**cursorPtr == '_') ) {
        *cursorPtr += 1;
    }
    if (*cursorPtr == itemStart) {
        fprintf(stderr, "No valid characters in item.\n");
        err = EINVAL;
    }
    if (err == 0) {
        size_t      itemNameLen;
        char *      itemName;
        
        itemNameLen = *cursorPtr - itemStart;
        itemName = malloc(itemNameLen + 1);
        if (itemName == NULL) {
            err = ENOMEM;
        } else {
            memcpy(itemName, itemStart, itemNameLen);
            itemName[itemNameLen] = 0;
                
            err = itemTester(itemName, refCon);
        }

        free(itemName);
    }
    if (err == 0) {
        SkipSpace(cursorPtr);
    }
    
    return err;
}

extern errno_t CommandParseItemString(const char *str, char delimiter, CommandParseItemStringTester itemTester, void *refCon)
    // See comment in header.
{
    int             err;
    const char *    cursor;

    assert(str != NULL);
    assert(delimiter != 0);
    assert(itemTester != NULL);
    // nothing to assert about refCon

    cursor = str;
    
    err = noErr;
    
    SkipSpace(&cursor);
    if (*cursor != 0) {
        err = ParseItem(&cursor, itemTester, refCon);
        while ( (err == 0) && (*cursor == delimiter) ) {
            cursor += 1;                    // skip delimiter
            err = ParseItem(&cursor, itemTester, refCon);
        }
        if ( (err == 0) && (*cursor != 0) ) {
            fprintf(stderr, "Unexpected characters at end of string.\n");
            err = EINVAL;
        }
    }
    
    return err;
}

struct FlagItemTesterParam {
    const FPFlagDesc *  flagList;
    uint64_t *          resultPtr;
};
typedef struct FlagItemTesterParam FlagItemTesterParam;

static int FlagItemTester(const char *item, void *refCon)
    // FlagItemTester is the CommandParseItemString used by ParseItemStringForFlags.  
    // It both verifies that the item is one of the flags and sets the flag's value 
    // in the result.
{
    int                     err;
    size_t                  flagIndex;
    FlagItemTesterParam *   fp;
    
    // Extract our params from the refCon.
    
    fp = (FlagItemTesterParam *) refCon;
    assert(fp != NULL);
    assert(fp->flagList != NULL);
    assert(fp->flagList[0].flagName != NULL);
    assert(fp->resultPtr != NULL);
    
    // Find the flag and, if we find it, set the value in the result.
    
    flagIndex = FPFindFlagByName(fp->flagList, item);
    if (flagIndex == kFPNotFound) {
        err = EUSAGE;
    } else {
        *fp->resultPtr |= fp->flagList[flagIndex].flagMask;
        err = 0;
    }
    return err;
}

static int ParseItemStringForFlags(const char *str, char delimiter, const FPFlagDesc flagList[], uint64_t *resultPtr)
    // ParseItemStringForFlags is an internal routine used by CommandArgsGetFlagList. 
    // This used to be exported by it's not needed by other modules at the moment 
    // so I've unexported it again.
{
    FlagItemTesterParam fp;

    assert(str != NULL);
    assert(delimiter != 0);
    assert(flagList != NULL);
    assert(flagList[0].flagName != NULL);
    assert(resultPtr != NULL);

    fp.flagList  = flagList;
    fp.resultPtr = resultPtr;
    return CommandParseItemString(str, delimiter, FlagItemTester, &fp);
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Implementation and Help

extern void CommandHelpString(uint32_t indent, uint32_t verbose, const void *param)
    // See comment in header.
{
    #pragma unused(verbose)

    assert( CommandHelpStandardPreCondition() );

    fprintf(stderr, "%*s%s\n", (int) indent, "", (const char *) param);
}

extern void CommandHelpFlags(uint32_t indent, uint32_t verbose, const void *param)
    // See comment in header.
{
    #pragma unused(verbose)
    const FPFlagDesc *  flags;
    int                 flagIndex;

    assert( CommandHelpStandardPreCondition() );
    assert( param != NULL );
    
    flags = (const FPFlagDesc *) param;
    
    flagIndex = 0;
    while (flags[flagIndex].flagName != NULL) {
        fprintf(stderr, "%*s%s\n", (int) (indent + kStdIndent), "", flags[flagIndex].flagName);
        flagIndex += 1;
    }
}

extern void CommandHelpEnum(uint32_t indent, uint32_t verbose, const void *param)
    // See comment in header.
{
    #pragma unused(verbose)
    const FPEnumDesc *  enums;
    int                 enumIndex;
    
    assert( CommandHelpStandardPreCondition() );
    assert( param != NULL );

    enums = (const FPEnumDesc *) param;
    
    enumIndex = 0;
    while (enums[enumIndex].enumName != NULL) {
        fprintf(stderr, "%*s%s\n", (int) (indent + kStdIndent), "", enums[enumIndex].enumName);
        enumIndex += 1;
    }
}
