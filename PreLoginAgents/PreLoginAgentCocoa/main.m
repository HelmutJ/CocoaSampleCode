/*
    File:       main.m

    Contains:   Main entry point of the PreLoginAgentCocoa.

    Written by: DTS

    Copyright:  Copyright (c) 2007 Apple Inc. All Rights Reserved.

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

    Change History (most recent first):

$Log$

*/

#import <Cocoa/Cocoa.h>

#include <asl.h>
#include <sys/event.h>

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Common Code

static aslclient    gASLClient;
static aslmsg       gASLMessage;

static void WaitForWindowServerSession(void)
    // This routine waits for the window server to register its per-session 
    // services in our session.  This code was necessary in various pre-release 
    // versions of Mac OS X 10.5, but it is not necessary on the final version. 
    // However, I've left it in, and the option to enable it, to give me the 
    // flexibility to test this edge case.
{
    CFDictionaryRef dict;
    
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "WaitForWindowServerSession begin");
    
    do {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Checking CGSessionCopyCurrentDictionary");
        dict = CGSessionCopyCurrentDictionary();
        if (dict == NULL) {
            (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "No session, sleeping");
            sleep(1);
        }
    } while (dict == NULL);
    if (dict != NULL) {
        CFRelease(dict);
    }
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "WaitForWindowServerSession end");
}

static void HandleSIGTERMFromRunLoop(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void *info);
    // forward declaration

static void InstallHandleSIGTERMFromRunLoop(void)
    // This routine installs HandleSIGTERMFromRunLoop as a SIGTERM handler. 
    // The wrinkle is, HandleSIGTERMFromRunLoop is called from the runloop rather 
    // than as a signal handler.  This means that HandleSIGTERMFromRunLoop is not 
    // limited to calling just the miniscule set of system calls that are safe 
    // from a signal handler.
    // 
    // This routine leaks lots of stuff.  You're only expected to call it once, 
    // from the main thread of your program.
{
    static const CFFileDescriptorContext    kContext = { 0, NULL, NULL, NULL, NULL };
    sig_t                   sigErr;
    int                     kq;
    CFFileDescriptorRef     kqRef;
    CFRunLoopSourceRef      kqSource;
    struct kevent           changes;
    int                     changeCount;
    
    // Ignore SIGTERM.  Even though we've ignored the signal, the kqueue will 
    // still see it.
    
    sigErr = signal(SIGTERM, SIG_IGN);
    assert(sigErr != SIG_ERR);
    
    // Create a kqueue and configure it to listen for the SIGTERM signal.
    
    kq = kqueue();
    assert(kq >= 0);
    
    // Use the new-in-10.5 EV_RECEIPT flag to ensure that we get what we expect.
    
    EV_SET(&changes, SIGTERM, EVFILT_SIGNAL, EV_ADD | EV_RECEIPT, 0, 0, NULL);
    changeCount = kevent(kq, &changes, 1, &changes, 1, NULL);
    assert(changeCount == 1);           // check that we get an event back
    assert(changes.flags & EV_ERROR);   // and that it contains error information
    assert(changes.data == 0);          // with no error
    
    // Wrap the kqueue in a CFFileDescriptor (new in Mac OS X 10.5!).  Then 
    // create a run-loop source from the CFFileDescriptor and add that to the 
    // runloop.
    
    kqRef = CFFileDescriptorCreate(NULL, kq, true, HandleSIGTERMFromRunLoop, &kContext);
    assert(kqRef != NULL);
    
    kqSource = CFFileDescriptorCreateRunLoopSource(NULL, kqRef, 0);
    assert(kqSource != NULL);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), kqSource, kCFRunLoopDefaultMode);
    
    CFFileDescriptorEnableCallBacks(kqRef, kCFFileDescriptorReadCallBack);

    // Clean up.  We can release kqSource and kqRef because they're all being 
    // kept live by the fact that the kqSource is added to the runloop.  We 
    // must not close kq because file descriptors are not reference counted 
    // and kqRef now 'owns' this descriptor.
    
    CFRelease(kqSource);
    CFRelease(kqRef);
}

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Cocoa-Specific Code

static BOOL gForceShow;

static void HandleSIGTERMFromRunLoop(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void *info)
    // Called from the runloop when the process receives a SIGTERM.  We log 
    // this occurence (which is safe to do because we're not in an actual signal 
    // handler, courtesy of the 'magic' in InstallHandleSIGTERMFromRunLoop) 
    // and then tell the app to quit.
{
    #pragma unused(f)
    #pragma unused(callBackTypes)
    #pragma unused(info)
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Got SIGTERM");

    [[NSApplication sharedApplication] terminate:nil];
}

// Declaration of our application delegate object.

@interface Me : NSObject
{
    IBOutlet NSPanel *  panel;
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
@end

@implementation Me

- (void)applicationDidFinishLaunching:(NSNotification *)notification
    // A delegate method called by AppKit when the application is ready to roll. 
    // We respond by showing our window.
{
    #pragma unused(notification)
    
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "-[Me applicationDidFinishLaunching:] begin");

    assert(panel != nil);

    // We have to call -[NSWindow setCanBecomeVisibleWithoutLogin:] to let the 
    // system know that we're not accidentally trying to display a window 
    // pre-login.
    
    [panel setCanBecomeVisibleWithoutLogin:YES];
    
    // Our application is a UI element which never activates, so we want our 
    // panel to show regardless.
    
    [panel setHidesOnDeactivate:NO];

    // Due to an artefact of the relationship between the UI frameworks and the 
    // window server <rdar://problem/5136400>, -[NSWindow orderFront:] is not 
    // sufficient to show the window.  We have to use -[NSWindow orderFrontRegardless].

    if (gForceShow) {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Showing window with extreme prejudice");
        [panel orderFrontRegardless];
    } else {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Showing window normally");
        [panel orderFront:self];
    }

    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "-[Me applicationDidFinishLaunching:] end");
}

@end

int main(int argc, char *argv[])
{
    int             retVal;
    int             argIndex;
    BOOL            delay;
    BOOL            waitForWindowServerSession;
    BOOL            cleanExit;
    
    // Initialise our ASL state.
    
    gASLClient = asl_open(NULL, "PreLoginAgents", 0);
    assert(gASLClient != NULL);
    
    (void) asl_set_filter(gASLClient, ASL_FILTER_MASK_UPTO(ASL_LEVEL_INFO));
    
    gASLMessage = asl_new(ASL_TYPE_MSG);
    assert(gASLMessage != NULL);
    
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Start");
    
    // Parse our arguments.  We support arguments that allow you to turn off 
    // various special cases within the code.  This makes it easy to test whether 
    // the special cases are still required.
    
    delay = NO;
    waitForWindowServerSession = NO;
    gForceShow = YES;
    cleanExit = YES;
    for (argIndex = 1; argIndex < argc; argIndex++) {
        if ( strcasecmp(argv[argIndex], "--nodelay") == 0 ) {
            delay = NO;
        } else if ( strcasecmp(argv[argIndex], "--delay") == 0 ) {
            delay = YES;
        } else if ( strcasecmp(argv[argIndex], "--nowait") == 0 ) {
            waitForWindowServerSession = NO;
        } else if ( strcasecmp(argv[argIndex], "--wait") == 0 ) {
            waitForWindowServerSession = YES;
        } else if ( strcasecmp(argv[argIndex], "--noforce") == 0 ) {
            gForceShow = NO;
        } else if ( strcasecmp(argv[argIndex], "--force") == 0 ) {
            gForceShow = YES;
        } else if ( strcasecmp(argv[argIndex], "--nocleanexit") == 0 ) {
            cleanExit = NO;
        } else if ( strcasecmp(argv[argIndex], "--cleanexit") == 0 ) {
            cleanExit = YES;
        } else {
            (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Unrecognised argument '%s'", argv[argIndex]);
        }
    }
    
    // Handle various options.
    
    if (waitForWindowServerSession) {
        WaitForWindowServerSession();
    } else {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Not waiting for CGSessionCopyCurrentDictionary");
    }
    
    if (delay) {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Delaying");
        
        sleep(3);
    } else {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Not delaying");
    }
    
    // Set up our SIGTERM handler.
    
    if (cleanExit) {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Installing SIGTERM handler");
        InstallHandleSIGTERMFromRunLoop();
    } else {
        (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Not installing SIGTERM handler");
    }
    
    // Go go gadget Cocoa!
    
    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "NSApplicationMain");
    retVal = NSApplicationMain(argc,  (const char **) argv);

    (void) asl_log(gASLClient, gASLMessage, ASL_LEVEL_INFO, "Stop");
    
    return retVal;
}
