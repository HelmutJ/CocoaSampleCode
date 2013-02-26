/*
    File:       FSMegaInfo.c

    Contains:   A program to print information about file system objects.

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

#include <CoreServices/CoreServices.h>

#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "Command.h"

/////////////////////////////////////////////////////////////////
#pragma mark ***** Main Dispatcher

static CommandError HelpCommand(CommandArgsRef args, uint32_t indent, uint32_t verbose);
    // forward declaration

static CommandInfo kHelpCommand = {
    HelpCommand,
    "help",
    "[ commandName ]",
    "Prints help for a command, or general help if no arguments are given.",
    NULL
};

// The master command dispatch table.  First, declare each of the commands as 
// extern.  I used to have these in separate header files but that just made things 
// harder to maintain.

extern CommandInfo kStatCommand;
extern CommandInfo kAccessCommand;
extern CommandInfo kLStatCommand;
extern CommandInfo kStatFSCommand;
extern CommandInfo kLStatFSCommand;
extern CommandInfo kGetFSStatCommand;
extern CommandInfo kGetDirEntriesCommand;
extern CommandInfo kReadDirCommand;
extern CommandInfo kFTSCommand;
extern CommandInfo kListXAttrCommand;
extern CommandInfo kGetXAttrCommand;
extern CommandInfo kPathConfCommand;
extern CommandInfo kGetAttrListCommand;
extern CommandInfo kDADiskCopyDescriptionCommand;
extern CommandInfo kFSGetVolumeInfoCommand;
extern CommandInfo kFSGetVolumeParmsCommand;
#if ! TARGET_RT_64_BIT
    extern CommandInfo kPBHGetVolParmsCommand;
#endif
extern CommandInfo kFSGetVolumeMountInfoCommand;
#if ! TARGET_RT_64_BIT
    extern CommandInfo kPBGetVolMountInfoCommand;
#endif
extern CommandInfo kFSCopyDiskIDForVolumeCommand;
extern CommandInfo kFSCopyURLForVolumeCommand;
extern CommandInfo kFSGetCatalogInfoCommand;
extern CommandInfo kFSGetCatalogInfoBulkCommand;
#if ! TARGET_RT_64_BIT
    extern CommandInfo kPBDTGetCommentCommand;
#endif
extern CommandInfo kFSCopyAliasInfoCommand;
#if ! TARGET_RT_64_BIT
    extern CommandInfo kGetAliasInfoCommand;
#endif
extern CommandInfo kFSFindFolderCommand;

// Second, define a table that references each one.

static const CommandInfo *kCommandInfo[] = {
    &kHelpCommand,
    &kAccessCommand,
    &kStatCommand,
    &kLStatCommand,
    &kStatFSCommand,
    &kLStatFSCommand,
    &kGetFSStatCommand,
    &kGetDirEntriesCommand,
    &kReadDirCommand,
    &kFTSCommand,
    &kListXAttrCommand,
    &kGetXAttrCommand,
    &kPathConfCommand,
    &kGetAttrListCommand,
    &kDADiskCopyDescriptionCommand,
    &kFSGetVolumeInfoCommand,
    &kFSGetVolumeParmsCommand,
    #if ! TARGET_RT_64_BIT
        &kPBHGetVolParmsCommand,
    #endif
    &kFSGetVolumeMountInfoCommand,
    #if ! TARGET_RT_64_BIT
        &kPBGetVolMountInfoCommand,
    #endif
    &kFSCopyDiskIDForVolumeCommand,
    &kFSCopyURLForVolumeCommand,
    &kFSGetCatalogInfoCommand,
    &kFSGetCatalogInfoBulkCommand,
    #if ! TARGET_RT_64_BIT
        &kPBDTGetCommentCommand,
    #endif
    &kFSCopyAliasInfoCommand,
    #if ! TARGET_RT_64_BIT
        &kGetAliasInfoCommand,
    #endif
    &kFSFindFolderCommand
};

static void PrintUsage(uint32_t verbose)
    // Print basic help for the program.
{
    size_t          i;
    size_t          maxNameLen;
    const char *    arch;
    
    arch = "";
    if (verbose > 0) {
        #if TARGET_CPU_PPC
            arch = " (ppc)";
        #elif TARGET_CPU_PPC64
            arch = " (ppc64)";
        #elif TARGET_CPU_X86
            arch = " (i386)";
        #elif TARGET_CPU_X86_64
            arch = " (x86-64)";
        #else
            #error What architecture?
        #endif
    }
    
    fprintf(stderr, "usage: %s [globalOptions] command...%s\n", getprogname(), arch);
    fprintf(stderr, "  globalOptions:\n");
    fprintf(stderr, "    -v Be more verbose; you can specify this multiple times \n");
    fprintf(stderr, "       for increasing levels of verbosity\n");
    fprintf(stderr, "    -l Don't follow leaf symlinks when converting a path to an FSRef\n");
    fprintf(stderr, "  Commands:\n");

    // Print the commands and their usage.  First calculate the maximum 
    // command length.  Then this that value to make sure that the command 
    // output is nicely aligned.
    
    maxNameLen = 0;
    for (i = 0; i < (sizeof(kCommandInfo) / sizeof(kCommandInfo[0])); i++) {
        size_t  nameLen;
        
        nameLen = strlen(kCommandInfo[i]->name);
        if (nameLen > maxNameLen) {
            maxNameLen = nameLen;
        }
    }
    for (i = 0; i < (sizeof(kCommandInfo) / sizeof(kCommandInfo[0])); i++) {
        fprintf(stderr, "     %*s %s\n", (int) maxNameLen, kCommandInfo[i]->name, kCommandInfo[i]->argSummary);
    }
}

static void PrintUsageForCommand(const CommandInfo *command, uint32_t verbose)
    // Print help for a specific command.
{
    size_t  helpIndex;
    
    assert(command != NULL);
    
    fprintf(stderr, "usage: %s [globalOptions] %s %s\n", getprogname(), command->name, command->argSummary);
    fprintf(stderr, "       %s\n", command->description);
    if (command->help != NULL) {
        if (verbose == 0) {
            fprintf(stderr, "\n");
            fprintf(stderr, "       Use the following to get more help:\n");
            fprintf(stderr, "\n");
            fprintf(stderr, "       %s -v help %s\n", getprogname(), command->name);
        } else {
            if (command->help != NULL) {
                helpIndex = 0;
                while (command->help[helpIndex].proc != NULL) {
                    command->help[helpIndex].proc(7, verbose - 1, command->help[helpIndex].param);
                    helpIndex += 1;
                }
            }
        }
    }
}

static CommandError HelpCommand(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the "help" command.
{
    #pragma unused(indent)
    int             err;
    const char *    commandStr;
    size_t          commandIndex;
    
    assert(args != NULL);
    assert(*args != NULL);
    commandIndex = 0;               // quieten warning
    
    err = CommandArgsGetString(args, &commandStr);
    if (err == 0) {
        bool found;
        
        found = false;
        commandIndex = 0;
        while ( ! found && commandIndex < (sizeof(kCommandInfo) / sizeof(kCommandInfo[0])) ) {
            if ( strcasecmp(commandStr, kCommandInfo[commandIndex]->name) == 0) {
                found = true;
            } else {
                commandIndex += 1;
            }
        }
        
        if ( ! found ) {
            err = EUSAGE;
        }
        
    }
    if (err == 0) {
        PrintUsageForCommand(kCommandInfo[commandIndex], verbose);
    } else {
        PrintUsage(verbose);
    }
    return CommandErrorMakeWithErrno(0);
}

int main(int argc, char ** argv)
{
    int             retVal;
    int             ch;
    int             verbose;
    size_t          commandIndex;
    const char **   argCursor;
    
    // Parse the options.
    
    retVal  = EXIT_SUCCESS;
    verbose = 0;
    do {
        ch = getopt(argc, argv, "vl");
        if (ch != -1) {
            switch (ch) {
                default:
                case '?':
                    PrintUsage(verbose);
                    retVal = EXIT_FAILURE;
                    break;
                case 'v':
                    verbose += 1;
                    break;
                case 'l':
                    SetDontFollowLeafSymLinksForFSRefs();
                    break;
            }
        }
    } while ( (retVal == EXIT_SUCCESS) && (ch != -1) );
    
    // If there are no commands, that's an error.
    
    if (retVal == EXIT_SUCCESS) {
        if (argv[optind] == NULL) {
            PrintUsage(verbose);
            retVal = EXIT_FAILURE;
        }
    }
    
    // Process each command in order.
    
    if (retVal == EXIT_SUCCESS) {
        argCursor = ((const char **) argv) + optind;
        do {
            bool found;
            
            // Find the command in the kCommandInfo table.
            
            found = false;
            commandIndex = 0;
            while ( ! found && commandIndex < (sizeof(kCommandInfo) / sizeof(kCommandInfo[0])) ) {
                if ( strcasecmp(*argCursor, kCommandInfo[commandIndex]->name) == 0) {
                    found = true;
                } else {
                    commandIndex += 1;
                }
            }
            
            // Dispatch the command.
            
            if ( ! found ) {
                PrintUsage(verbose);
                exit(EXIT_FAILURE);
            } else {
                CommandError commandErr;
                
                argCursor += 1;
                
                commandErr = kCommandInfo[commandIndex]->proc(&argCursor, 0, verbose);
                
                if ( CommandErrorIsUsage(commandErr) ) {
                    PrintUsageForCommand(kCommandInfo[commandIndex], 0);
                    retVal = EXIT_FAILURE;
                } else if ( ! CommandErrorIsNoError(commandErr) ) {
                    CommandErrorPrint(commandErr, kCommandInfo[commandIndex]->name, 0);
                    retVal = EXIT_FAILURE;
                }
            }
        } while ( (retVal == EXIT_SUCCESS) && (*argCursor != NULL) );
    }
    
    return retVal;
}
