/*
    File:       DiskArb.c

    Contains:   Disk Arbitration command processing.

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

#include <DiskArbitration/DiskArbitration.h>

#include "FieldPrinter.h"
#include "Command.h"

#pragma mark *     DADiskCopyDescription

static CommandError PrintDADiskCopyDescription(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Prints results of DADiskCopyDescription.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    int                 err;
    const char *        bsdName;
    DASessionRef        session;
    DADiskRef           disk;
    CFDictionaryRef     descDict;

    assert( CommandArgsValid(args) );

    session  = NULL;
    disk     = NULL;
    descDict = NULL;
    
    err = CommandArgsGetString(args, &bsdName);
    if (err == 0) {
        session = DASessionCreate(NULL);
        if (session == NULL) {
            err = EINVAL;
        }
    }
    if (err == 0) {
        disk = DADiskCreateFromBSDName(NULL, session, bsdName);
        if (disk == NULL) {
            err = EINVAL;
        }
    }
    if (err == 0) {
        descDict = DADiskCopyDescription(disk);
        if (descDict == NULL) {
            err = EINVAL;
        }
    }
    if (err == 0) {
        FPCFDictionary("description", sizeof(descDict), &descDict, indent, strlen("description"), verbose, NULL);
    }

    // Clean up.

    if (descDict != NULL) {
        CFRelease(descDict);
    }
    if (disk != NULL) {
        CFRelease(disk);
    }
    if (session != NULL) {
        CFRelease(session);
    }

    return CommandErrorMakeWithErrno(err);
}

const CommandInfo kDADiskCopyDescriptionCommand = {
    PrintDADiskCopyDescription,
    "DADiskCopyDescription",
    "bsdDeviceName",
    "Print results of DADiskCopyDescription.",
    NULL
};
