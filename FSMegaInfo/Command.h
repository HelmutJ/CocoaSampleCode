/*
    File:       Command.h

    Contains:   Declarations and utilities for command processing.

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

#ifndef _COMMAND_H
#define _COMMAND_H

/////////////////////////////////////////////////////////////////

// System interfaces

#include <CoreServices/CoreServices.h>

// Project interfaces

#include "FieldPrinter.h"

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Errors

typedef int errno_t;

#define EUSAGE 666
enum {
    kCommandUsageErr = 666
};

enum CommandErrorDomain {
    kCommandErrorCustom,
    kCommandErrorErrno,
    kCommandErrorOSStatus
};
typedef enum CommandErrorDomain CommandErrorDomain;

enum CustomError {
    kUsageCustomError,
    kUnavailableCustomError
};
typedef enum CustomError CustomError;

struct CommandError {
    CommandErrorDomain  domain;
    union {
        CustomError     errCustom;
        errno_t         errErrno;
        OSStatus        errOSStatus;
    } u;
};
typedef struct CommandError CommandError;

extern CommandError CommandErrorMakeWithCustom(CustomError errNum);
extern CommandError CommandErrorMakeWithErrno(int errNum);
extern CommandError CommandErrorMakeWithOSStatus(OSStatus errNum);
    // Makes one of the three flavours of command error.

extern bool CommandErrorIsNoError(CommandError commandError);
extern bool CommandErrorIsUsage(CommandError commandError);
    // Returns true if the error is no error or a usage error, respectively.

extern void CommandErrorPrint(CommandError commandError, const char *operation, uint32_t indent);
    // Prints a message explaining that an error occurred.

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Arguments

typedef const char ***CommandArgsRef;
    // CommandArgsRef is a reference to the arguments of the command.  It's best 
    // not to try to interpret this value yourself; rather, call one of the 
    // accessor routines below.

extern bool CommandArgsValid(CommandArgsRef args);
    // Returns true if args looks reasonable.

// IMPORTANT:
// None of these routines require you to 'free' the returned value in any way.

extern errno_t  CommandArgsGetString(CommandArgsRef args, const char **strPtr);
    // Returns and consumes an argument string, or returns EUSAGE if none is available.
extern OSStatus CommandArgsGetStringOSStatus(CommandArgsRef args, const char **strPtr);
    // Returns and consumes an argument string, or returns kCommandUsageErr if none is available.

extern OSStatus CommandArgsGetVRefNum(CommandArgsRef args, FSVolumeRefNum *vRefNumPtr);
    // Consumes an argument denoting a volume (as a name) and returns the vRefNum.
extern OSStatus CommandArgsGetFSRef(CommandArgsRef args, FSRef *fsRefPtr);
    // Consumes an argument denoting a file system object (as a full path) and returns the FSRef.

extern void     SetDontFollowLeafSymLinksForFSRefs(void);
    // Controls whether CommandArgsGetFSRef follows leaf symlinks or not.  By default 
    // it does.  The main program calls this routine if the user specifies an argument 
    // to inhibit that behaviour.

extern bool     CommandArgsIsOption(CommandArgsRef args);
    // Returns true if the next argument represents an option (that is, starts with 
    // "-").  Does not consume the argument.

extern bool     CommandArgsGetOptionString(CommandArgsRef args, const char **optionArgPtr);
    // Returns true if the next argument is an option string (that is, it starts with 
    // "-").  If it returns true, it also returns and consumes that argument.

extern bool     CommandArgsGetOptionalConstantString(CommandArgsRef args, const char *optionalArg);
    // Returns true if the next argument is the value specified in optionalArg.  If 
    // it returns true, it also consumes that argument.

extern errno_t  CommandArgsGetFlagList(CommandArgsRef args, const FPFlagDesc flagList[], uint64_t *resultPtr);
    // Given a null-terminated array of flags, this routines checks to see if the 
    // next argument is an option (that is, it starts with "-") and, if it is, 
    // parsing the remaining characters in the string as a set of comma separated 
    // flags.  Returns the value of the flags, combined, in *resultPtr.
extern errno_t  CommandArgsGetFlagListInt(CommandArgsRef args, const FPFlagDesc flagList[], int *resultPtr);
    // As CommandArgsGetFlagList, but returns the flags in an int.

extern errno_t  CommandArgsGetSizeT(CommandArgsRef args, size_t *argPtr);
    // Consumes an argument and returns its value as a size_t.
extern errno_t  CommandArgsGetInt(CommandArgsRef args, int *argPtr);
    // Consumes an argument and returns its value as an int.

typedef errno_t (*CommandParseItemStringTester)(const char *item, void *refCon);
    // The callback for CommandParseItemString.  Checks that the specified item 
    // is valid.
    
extern errno_t CommandParseItemString(const char *str, char delimiter, CommandParseItemStringTester itemTester, void *refCon);
    // Parses a string as a list of items separated by delimeter.  Calls itemTester
    // to verify that each item is valid.

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Implementation and Help

typedef CommandError (*CommandProc)(CommandArgsRef args, uint32_t indent, uint32_t verbose);
    // CommandProc represents the implementation entry point for each command. 
    // Discussed in more detail below.

// Each command has an optional array of help entries that provide help about that command. 
// Each help entry contains a pointer to a help printing routine and a parameter for that 
// routine.  This allows most help to be printer by a few standard routines, declared below.

typedef void (*CommandHelpProc)(uint32_t indent, uint32_t verbose, const void *param);
    // CommandHelpProc represents a help printing entry point.

// CommandHelpStandardPreCondition is a macro that you can assert in your help 
// routines to check their incoming parameters.  It's a macro so that it can 
// access the parameters by name.

#define CommandHelpStandardPreCondition()   \
    (true)                                      // nothing to check at the moment

struct CommandHelpEntry {
    CommandHelpProc proc;
    const void *    param;
};
typedef struct CommandHelpEntry CommandHelpEntry;

extern void CommandHelpString(uint32_t indent, uint32_t verbose, const void *param);
    // Prints a constant string help item.  param is a pointer to that string.
extern void CommandHelpFlags(uint32_t indent, uint32_t verbose, const void *param);
    // Prints a flags help item.  params is a pointer to a null-terminated FPFlagDesc array.
extern void CommandHelpEnum(uint32_t indent, uint32_t verbose, const void *param);
    // Prints an enum help item.  params is a pointer to a null-terminated FPEnumDesc array.

// The CommandInfo structure describes a particular command, including a pointer 
// to the routine that implements the command, the short name of the command, 
// the argument summary (for printing usage), a one-line command description, 
// and an array of help entries that provide multi-line help.
// proc to call, the name of the proc, and the usage.

struct CommandInfo {
    CommandProc                 proc;
    const char *                name;
    const char *                argSummary;
    const char *                description;
    const CommandHelpEntry *    help;
};
typedef struct CommandInfo CommandInfo;

#endif
