/*
    File:       FolderManager.c

    Contains:   Folder Manager command processing.

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

#include <sys/param.h>

#include "FieldPrinter.h"
#include "Command.h"

#pragma mark *     FSFindFolder

const FPEnumDesc kDomainEnums[] = {
    { kOnSystemDisk,        "kOnSystemDisk" },
    { kOnAppropriateDisk,   "kOnAppropriateDisk" },
    { kSystemDomain,        "kSystemDomain" },
    { kLocalDomain,         "kLocalDomain" },
    { kNetworkDomain,       "kNetworkDomain" },
    { kUserDomain,          "kUserDomain" },
    { kClassicDomain,       "kClassicDomain" },
    { 0, NULL }
};

static CommandError PrintFSFindFolder(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Prints a path to a folder found via FSFindFolder.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus            err;
    const char *        domainStr;
    size_t              enumIndex;
    SInt16              domain;
    const char *        typeStr;
    OSType              type;
    FSRef               ref;
    char                path[MAXPATHLEN];

    assert( CommandArgsValid(args) );

    domain = kOnAppropriateDisk;            // quieten warning
    type = 0;

    // Get and parse domain argument.  It can either be one of the constants from 
    // kDomainEnums or a path to an item (in which case we just the volume that 
    // contains the item).
    
    err = CommandArgsGetStringOSStatus(args, &domainStr);
    if (err == noErr) {
        enumIndex = FPFindEnumByName(kDomainEnums, domainStr);
        if (enumIndex != kFPNotFound) {
            domain = kDomainEnums[enumIndex].enumValue;
        } else {
            FSCatalogInfo   catInfo;
            FSRef           volRef;
            
            err = FSPathMakeRef( (const UInt8 *) domainStr, &volRef, NULL);
            if (err == noErr) {
                err = FSGetCatalogInfo(&volRef, kFSCatInfoVolume, &catInfo, NULL, NULL, NULL);
            }
            if (err == noErr) { 
                domain = catInfo.volume;
            }
        }
    }
    
    // Get and parse type argument.
    
    if (err == noErr) {
        err = CommandArgsGetStringOSStatus(args, &typeStr);
    }
    if (err == noErr) {
        if ( strncmp(typeStr, "0x", 2) == 0 ) {
            unsigned int    tmp;
            int             convertedCount;
            
            if ( (sscanf(typeStr, "%x%n", &tmp, &convertedCount) == 1) && ((size_t) convertedCount == strlen(typeStr)) ) {
                type = tmp;
            } else {
                err = kCommandUsageErr;                
            }
        } else {
            CFStringRef     cfStr;
            int             i;
            UInt8 pstr[5] = { 0 };
            
            // The following code is carefully crafted to do UTF-8 -> MacRoman and 
            // handle zero fill at the right, and get the byte order right.
            
            cfStr = CFStringCreateWithCString(NULL, typeStr, kCFStringEncodingUTF8);
            assert(cfStr != NULL);
            
            if ( CFStringGetPascalString(cfStr, pstr, sizeof(pstr), kCFStringEncodingMacRoman) ) {
                for (i = 1; i <= 4; i++) {
                    type = (type << 8) | pstr[i];
                }
            } else {
                err = kCommandUsageErr;
            }
            
            if (cfStr != NULL) {
                CFRelease(cfStr);
            }
        }
    }

    // Call FSFindFolder and print the path
    
    if (err == noErr) {
        fprintf(stdout, "%*sFSFindFolder(%hd, 0x%08x)\n", (int) indent, "", domain, (unsigned int) type);
        err = FSFindFolder(domain, type, true, &ref);
    }
    if (err == noErr) {
        err = FSRefMakePath(&ref, (UInt8 *) path, (UInt32) sizeof(path));
    }
    if (err == noErr) {
        FPCString("path", sizeof(path), &path, indent + kStdIndent, strlen("path"), verbose, NULL);
    }

    return CommandErrorMakeWithOSStatus(err);
}

static const CommandHelpEntry kFSFindFolderCommandHelp[] = {
    {CommandHelpString, "domain  Path to volume or one of the following:"},
    {CommandHelpEnum,   kDomainEnums},
    {CommandHelpString, "type    Folder type in hex (with 0x prefix) or as four character code"},
    {NULL, NULL}
};

const CommandInfo kFSFindFolderCommand = {
    PrintFSFindFolder,
    "FSFindFolder",
    "domain type",
    "Print path to folder obtained via FSFindFolder.",
    kFSFindFolderCommandHelp
};
