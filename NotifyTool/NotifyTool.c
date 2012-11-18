/*
    File:       NotifyTool.c

    Contains:   Sample showing how to use the BSD notify API <x-man-page://3/notify>.

    Written by: DTS

    Copyright:  Copyright (c) 2007-2012 Apple Inc. All Rights Reserved.

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

#include <assert.h>
#include <errno.h>
#include <mach/mach.h>
#include <notify.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dispatch/dispatch.h>

#include <CoreFoundation/CoreFoundation.h>

static void PrintUsage(void)
{
    fprintf(stderr, "usage: %s post <name>...\n", getprogname());
    fprintf(stderr, "       %*s listen | listenFD <name>...\n", (int) strlen(getprogname()), "");
    fprintf(stderr, "       %*s listenMach <name>...\n", (int) strlen(getprogname()), "");
    fprintf(stderr, "       %*s listenCF <name>...\n", (int) strlen(getprogname()), "");
    fprintf(stderr, "       %*s listenGCD <name>...\n", (int) strlen(getprogname()), "");
}

static const char * NotifyErrorToString(uint32_t noteErr)
{
    const char *    result;
    static const char * kErrors[] = {
        "NOTIFY_STATUS_OK",
        "NOTIFY_STATUS_INVALID_NAME",
        "NOTIFY_STATUS_INVALID_TOKEN",
        "NOTIFY_STATUS_INVALID_PORT",
        "NOTIFY_STATUS_INVALID_FILE",
        "NOTIFY_STATUS_INVALID_SIGNAL",
        "NOTIFY_STATUS_INVALID_REQUEST",
        "NOTIFY_STATUS_NOT_AUTHORIZED"
    };
    
    if (noteErr < (sizeof(kErrors) / sizeof(*kErrors))) {
        result = kErrors[noteErr];
    } else if (noteErr == NOTIFY_STATUS_FAILED) {
        result = "NOTIFY_STATUS_FAILED";
    } else {
        result = "unknown error";
    }
    return result;
}

static void PrintNotifyError(const char *operation, const char *noteName, uint32_t noteErr)
{
    fprintf(
        stderr, 
        "%s: %s: %s (%u)\n", 
        noteName,
        operation, 
        NotifyErrorToString(noteErr), 
        (unsigned int) noteErr
    );
}

static int PostNotifications(size_t noteCount, const char **noteNames)
    // Implements the "post" command.  Post the noteCount notifications whose 
    // names are in the noteNames array.
{
    int         retVal;
    uint32_t    noteErr;
    size_t      noteIndex;
    
    noteErr = NOTIFY_STATUS_OK;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        noteErr = notify_post(noteNames[noteIndex]);
        if (noteErr != NOTIFY_STATUS_OK) {
            break;
        }
    }
    if (noteErr == NOTIFY_STATUS_OK) {
        retVal = EXIT_SUCCESS;
    } else {
        PrintNotifyError("post failed", noteNames[noteIndex], noteErr);
        retVal = EXIT_FAILURE;
    }
    return retVal;
}

static void PrintToken(
    int             token, 
    size_t          noteCount, 
    const int *     tokens, 
    const char **   noteNames
)
    // For a given token, search the tokens array looking for a match.  If 
    // you find one, print the associated notification name.  If you don't 
    // find one, print a default string.
{
    size_t  noteIndex;
    bool    found;

    found = false;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        if (token == tokens[noteIndex]) {
            fprintf(stdout, "%s (%d)\n", noteNames[noteIndex], token);
            found = true;
        }
    }
    if ( ! found ) {
        fprintf(stdout, "??? (%d)\n", token);
    }
    fflush(stdout);
}

static int ListenUsingFileDescriptor(size_t noteCount, const char **noteNames)
    // Implements the "listenFD" command.  Register for the noteCount 
    // notifications whose names are in the noteNames array.  Then read 
    // the notification file descriptor, printing information about any 
    // notifications that arrive.
{
    int         retVal;
    uint32_t    noteErr;
    size_t      noteIndex;
    int         noteTokens[noteCount];
    int         fd = -1;
    
    // Register.  The first time around this loop fd == -1 and so we don't 
    // specify NOTIFY_REUSE.  notify_register_file_descriptor then allocates 
    // a file descriptor and returns it in fd.  For subsequent iterations 
    // we /do/ specify NOTIFY_REUSE and notify_register_file_descriptor just 
    // reuses the existing fd.
    
    noteErr = NOTIFY_STATUS_OK;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        noteErr = notify_register_file_descriptor(
            noteNames[noteIndex], 
            &fd, 
            (fd == -1) ? 0 : NOTIFY_REUSE, 
            &noteTokens[noteIndex]
        );
        if (noteErr != NOTIFY_STATUS_OK) {
            break;
        }
    }
    if (noteErr != NOTIFY_STATUS_OK) {
        PrintNotifyError("registration failed", noteNames[noteIndex], noteErr);
        retVal = EXIT_FAILURE;
    } else {
    
        // Listen for and print any incoming notifications.
        
        fprintf(stdout, "Listening using a file descriptor:\n");
        fflush(stdout);
        do {
            ssize_t bytesRead;
            int     token;
            
            bytesRead = read(fd, &token, sizeof(token));
            if (bytesRead == 0) {
                fprintf(stderr, "end of file on notify file descriptor\n");
                retVal = EXIT_FAILURE;
                break;
            } else if (bytesRead < 0) {
                fprintf(stderr, "read failed: %s (%d)\n", strerror(errno), errno);
                retVal = EXIT_FAILURE;
                break;
            } else {
                // I'm just not up for handling partial reads at this point.
                
                assert(bytesRead == sizeof(token));
                
                // Have to swap to native endianness <rdar://problem/5352778>.
                
                token = ntohl(token);
                
                // Find the string associated with this token and print it.
                
                PrintToken(token, noteCount, noteTokens, noteNames);
            } 
        } while (true);
    }
    
    return retVal;
}

static int ListenUsingMach(size_t noteCount, const char **noteNames)
    // Implements the "listenMach" command.  Register for the noteCount 
    // notifications whose names are in the noteNames array.  Then read 
    // the notification Mach port, printing information about any 
    // notifications that arrive.
{
    int         retVal;
    uint32_t    noteErr;
    size_t      noteIndex;
    int         noteTokens[noteCount];
    mach_port_t port = MACH_PORT_NULL;
    
    // Register.  The first time around this loop fd == -1 and so we don't 
    // specify NOTIFY_REUSE.  notify_register_mach_port then allocates 
    // a Mach port and returns it in port.  For subsequent iterations 
    // we /do/ specify NOTIFY_REUSE and notify_register_mach_port just 
    // reuses the existing port.

    noteErr = NOTIFY_STATUS_OK;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        noteErr = notify_register_mach_port(
            noteNames[noteIndex], 
            &port, 
            (port == MACH_PORT_NULL) ? 0 : NOTIFY_REUSE, 
            &noteTokens[noteIndex]
        );
        if (noteErr != NOTIFY_STATUS_OK) {
            break;
        }
    }
    if (noteErr != NOTIFY_STATUS_OK) {
        PrintNotifyError("registration failed", noteNames[noteIndex], noteErr);
        retVal = EXIT_FAILURE;
    } else {
        kern_return_t           kr;
        mach_msg_empty_rcv_t    msg;

        // Listen for and print any incoming notifications.
        
        fprintf(stdout, "Listening using Mach:\n");
        fflush(stdout);
        do {
            msg.header.msgh_local_port = port;
            msg.header.msgh_size = sizeof(msg);
            kr = mach_msg_receive(&msg.header);
            if (kr == KERN_SUCCESS) {
                PrintToken(msg.header.msgh_id, noteCount, noteTokens, noteNames);
            }
        } while (kr == KERN_SUCCESS);
        
        fprintf(stderr, "error reading Mach message: %s (0x%x)\n", mach_error_string(kr), kr);
        retVal = EXIT_FAILURE;
    }
    
    return retVal;
}

struct MyCFMachPortCallBackInfo {
    OSType          magic;              // must be 'CFpI'
    size_t          noteCount;
    const int *     noteTokens;
    const char **   noteNames;
};
typedef struct MyCFMachPortCallBackInfo MyCFMachPortCallBackInfo;

static void MyCFMachPortCallBack(
    CFMachPortRef   port, 
    void *          msg, 
    CFIndex         size, 
    void *          info
)
    // The callback associated with the CFMachPort.  This get called out of the 
    // runloop when a message arrives on the notification port.  We just 
    // extrac the token (msgh_id) and call print it.
{
    #pragma unused(port)
    #pragma unused(size)
    const MyCFMachPortCallBackInfo *    myInfo;
    
    myInfo = (const MyCFMachPortCallBackInfo *) info;
    assert(myInfo->magic == 'CFpI');
    
    PrintToken( 
        ((const mach_msg_header_t *) msg)->msgh_id, 
        myInfo->noteCount, 
        myInfo->noteTokens, 
        myInfo->noteNames
    );
}

static int ListenUsingCoreFoundation(size_t noteCount, const char **noteNames)
    // Implements the "listenCF" command.  Register for the noteCount 
    // notifications whose names are in the noteNames array.  Then wrap the 
    // notification Mach port in a CFMachPort and use CF to read the notification 
    // messages, printing the information about any notifications that arrive 
    // from our CFMachPort callback.
{
    int         retVal;
    uint32_t    noteErr;
    size_t      noteIndex;
    int         noteTokens[noteCount];
    mach_port_t port = MACH_PORT_NULL;
    
    // Register.  The first time around this loop fd == -1 and so we don't 
    // specify NOTIFY_REUSE.  notify_register_mach_port then allocates 
    // a Mach port and returns it in port.  For subsequent iterations 
    // we /do/ specify NOTIFY_REUSE and notify_register_mach_port just 
    // reuses the existing port.

    noteErr = NOTIFY_STATUS_OK;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        noteErr = notify_register_mach_port(
            noteNames[noteIndex], 
            &port, 
            (port == MACH_PORT_NULL) ? 0 : NOTIFY_REUSE, 
            &noteTokens[noteIndex]
        );
        if (noteErr != NOTIFY_STATUS_OK) {
            break;
        }
    }
    if (noteErr != NOTIFY_STATUS_OK) {
        PrintNotifyError("registration failed", noteNames[noteIndex], noteErr);
        retVal = EXIT_FAILURE;
    } else {
        MyCFMachPortCallBackInfo    myInfo;
        CFMachPortContext           context = { 0 , NULL, NULL, NULL, NULL };
        CFMachPortRef               cfPort;
        Boolean                     shouldFreeInfo;
        CFRunLoopSourceRef          rls;
        
        // Set up the context structure for MyCFMachPortCallBack.
        
        myInfo.magic      = 'CFpI';
        myInfo.noteCount  = noteCount;
        myInfo.noteTokens = noteTokens;
        myInfo.noteNames  = noteNames;
        
        // Create the CFMachPort.
        
        context.info = &myInfo;
        cfPort = CFMachPortCreateWithPort(
            NULL, 
            port, 
            MyCFMachPortCallBack, 
            &context, 
            &shouldFreeInfo
        );
        assert(cfPort != NULL);
        
        // There can only be one CFMachPort for a given Mach port name.  Thus, 
        // if someone had already created a CFMachPort for "port", CFMachPort 
        // would not create a new CFMachPort but, rather, return the existing 
        // CFMachPort with the retain count bumped.  In that case it hasn't 
        // taken any 'reference' on the data in context; the context.info 
        // on the /previous/ CFMachPort is still in use, but the context.info 
        // that we supply is now superfluous.  In that case it returns 
        // shouldFreeInfo, telling us that we don't need to hold on to this 
        // information.
        //
        // In this specific case no one should have already created a CFMachPort 
        // for "port", so shouldFreeInfo should never be true.  If it is, it's 
        // time to worry!
        
        assert( ! shouldFreeInfo );
        
        // Add it to the run loop.
        
        rls = CFMachPortCreateRunLoopSource(NULL, cfPort, 0);
        assert(rls != NULL);

        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
        
        // Run the run loop.
        
        fprintf(stdout, "Listening using Core Foundation:\n");
        fflush(stdout);
        
        CFRunLoopRun();

        fprintf(stderr, "CFRunLoopRun returned\n");
        retVal = EXIT_FAILURE;
    }
    
    return retVal;
}

static int ListenUsingGCD(size_t noteCount, const char **noteNames)
{
    int         retVal;
    uint32_t    noteErr;
    size_t      noteIndex;
    int         noteTokens[noteCount];
    const int * noteTokensPtr;

    // We need to capture the base of the noteTokens array, but the compiler won't let us do that
    // because it's of variable size.  In our specific case this isn't a problem because, if things
    // go well, we never leave this routine but rather block forever in dispatch_main().  In a real
    // program you'd have to be a bit more careful (but then again, in a real program you wouldn't be
    // registering for an unbounded number of arbitrary notifications :-).
    
    noteTokensPtr = &noteTokens[0];

    noteErr = NOTIFY_STATUS_OK;
    for (noteIndex = 0; noteIndex < noteCount; noteIndex++) {
        noteErr = notify_register_dispatch(noteNames[noteIndex], &noteTokens[noteIndex], dispatch_get_main_queue(), ^(int token) {
            PrintToken(
                token,
                noteCount,
                noteTokensPtr, 
                noteNames
            );
        });
        if (noteErr != NOTIFY_STATUS_OK) {
            break;
        }
    }
    if (noteErr != NOTIFY_STATUS_OK) {
        PrintNotifyError("registration failed", noteNames[noteIndex], noteErr);
        retVal = EXIT_FAILURE;
    } else {
        fprintf(stdout, "Listening using GCD:\n");
        fflush(stdout);
        dispatch_main();
        assert(0);              // dispatch_main() should never return
        retVal = EXIT_FAILURE;
    }
    return retVal;
}

int main(int argc, const char **argv)
{
    int         retVal;
    
    if (argc < 3) {
        PrintUsage();
        retVal = EXIT_FAILURE;
    } else {
        if (strcasecmp(argv[1], "post") == 0) {
            retVal = PostNotifications( ((size_t) argc) - 2, &argv[2]);
        } else if ((strcasecmp(argv[1], "listen") == 0) || (strcasecmp(argv[1], "listenFD") == 0)) {
            retVal = ListenUsingFileDescriptor( ((size_t) argc) - 2, &argv[2]);
        } else if (strcasecmp(argv[1], "listenMach") == 0) {
            retVal = ListenUsingMach( ((size_t) argc) - 2, &argv[2]);
        } else if (strcasecmp(argv[1], "listenCF") == 0) {
            retVal = ListenUsingCoreFoundation( ((size_t) argc) - 2, &argv[2]);
        } else if (strcasecmp(argv[1], "listenGCD") == 0) {
            retVal = ListenUsingGCD( ((size_t) argc) - 2, &argv[2]);
        } else {
            PrintUsage();
            retVal = EXIT_FAILURE;
        }
    }

    return retVal;
}
