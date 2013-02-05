/*
File: SandboxedFetchAppDelegate.m
Abstract: Definitions for the SandboxedFetchAppDelegate object.
Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2011 Apple Inc. All Rights Reserved.
*/


#import "SandboxedFetchAppDelegate.h"

#import <errno.h>
#import <fcntl.h>


@implementation SandboxedFetchAppDelegate

@synthesize window;

@synthesize sourceURL;
@synthesize statusMessage;
@synthesize compressCheckbox;
@synthesize fetchButton;

@synthesize progressIndicator;
@synthesize progressCancelButton;
@synthesize progressPanel;
@synthesize progressMessage;

@synthesize errorAlert;

- (xpc_connection_t) _connectionForServiceNamed:(const char *)serviceName
                       connectionInvalidHandler:(dispatch_block_t)handler
{
    __block xpc_connection_t serviceConnection =
        xpc_connection_create(serviceName, dispatch_get_main_queue());

    if (!serviceConnection) {
        NSLog(@"Can't connect to XPC service");
        self.statusMessage = @"Can't connect to XPC service";
        return (NULL);
    }

    self.statusMessage = @"Created connection to XPC service";

    xpc_connection_set_event_handler(serviceConnection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);

        if (type == XPC_TYPE_ERROR) {

            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                // The service has either cancaled itself, crashed, or been
                // terminated.  The XPC connection is still valid and sending a
                // message to it will re-launch the service.  If the service is
                // state-full, this is the time to initialize the new service.

                self.statusMessage = @"Interrupted connection to XPC service";
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                // The service is invalid. Either the service name supplied to
                // xpc_connection_create() is incorrect or we (this process) have
                // canceled the service; we can do any cleanup of appliation
                // state at this point.
                self.statusMessage = @"Connection Invalid error for XPC service";
                xpc_release(serviceConnection);
                if (handler) {
                    handler();
                }
            } else {
                self.statusMessage = @"Unexpected error for XPC service";
            }
        } else {
            self.statusMessage = @"Received unexpected event for XPC service";
        }
    });

    // Need to resume the service in order for it to process messages.
    xpc_connection_resume(serviceConnection);
    return (serviceConnection);
}

static void 
_copy_file(int infd, int outfd, void(^errhandler)(NSString*, int))
{
    ssize_t n;
    uint8_t buf[4096];

    while((n = read(infd, buf, sizeof(buf))) > 0) {
        uint8_t *bp = buf;
        ssize_t r;

        while (n > 0 && (r = write(outfd, bp, n)) > 0) {
            bp += r;
            n -= r;
        }
        if (r <= 0) {
            if (r == 0) {
                errhandler(@"Write returned EOF", EIO);
                return;
            }
            errhandler(@"Can't write outfd", errno);
            return;
        }
    }
    if (n < 0) {
        errhandler(@"Can't read infd", errno);
        return;
    }
}

static void
_compress_file(xpc_connection_t connection, int infd, int outfd,
               void(^errhandler)(const char*, int))
{
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    assert(message != NULL);

    xpc_dictionary_set_fd(message, "infd", infd);
    xpc_dictionary_set_fd(message, "outfd", outfd);

    assert(connection != NULL);
    xpc_connection_send_message_with_reply(connection, message,
                                           dispatch_get_main_queue(),
                                           ^(xpc_object_t event) {
        int64_t errcode = xpc_dictionary_get_int64(event, "errcode");

        if (errcode) {
            const char *errmsg = xpc_dictionary_get_string(event, "errmsg");
            if (errmsg)
                errhandler(errmsg, (int)errcode);
            else
                errhandler("Unknown error", (int)errcode);
        }
    });
}

#pragma mark Error Alert Sheet
- (void) showErrorAlert: (NSString*) title  additionalInfo: (NSString*) info
{

	self.errorAlert = [NSAlert alertWithMessageText: title
                                      defaultButton: @"Continue"
                                    alternateButton: nil
                                        otherButton: nil
                          informativeTextWithFormat: info];
	[errorAlert beginSheetModalForWindow: window
                           modalDelegate: self
                          didEndSelector: @selector(errorAlertDidEnd:returnCode:contextInfo:)
                             contextInfo: nil];
	[NSApp runModalForWindow: errorAlert.window];
}

- (void) errorAlertDidEnd: (NSAlert*) alert returnCode: (NSInteger) returnCode
              contextInfo: (void*) contextInfo
{
	if (returnCode < 0) return;

	[NSApp stopModal];
	self.errorAlert = nil;
}

#pragma mark Progress Panel Sheet
- (void) startIndeterminateProgressPanel:(NSString *)message
{
    // Display a progress panel as a sheet
    self.progressMessage = message;
    [progressIndicator setIndeterminate: YES];
    [progressIndicator startAnimation: self];
    [progressCancelButton setEnabled: NO];
    [NSApp beginSheet: progressPanel
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(progressDidEnd: returnCode: contextInfo:)
          contextInfo: NULL];
}

- (xpc_connection_t) startProgressPanel:(NSString *)message
{
    dispatch_queue_t listener_queue =
        dispatch_queue_create("com.apple.SandboxedFetch.ProgressQueue", NULL);
    assert(listener_queue != NULL);

    // Create an anonymous listener connection that collects progress updates.
    xpc_connection_t connection = xpc_connection_create(NULL, listener_queue);

    if (connection == NULL) {
        NSLog(@"Couldn't create progress connection");
        return (NULL);
    }

    // Display a progress panel as a sheet
    self.progressMessage = message;
    [progressIndicator setIndeterminate: NO];
    [progressIndicator setDoubleValue: 0.0];
    [progressIndicator startAnimation: self];
    [progressCancelButton setEnabled: YES];
    [NSApp beginSheet: progressPanel
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(progressDidEnd: returnCode: contextInfo:)
          contextInfo: connection];

    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);

        if (type == XPC_TYPE_ERROR) {
            if (event == XPC_ERROR_TERMINATION_IMMINENT) {
                NSLog(@"received XPC_ERROR_TERMINATION_IMMINENT");
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSLog(@"progress connection is closed");
            }
        } else if (XPC_TYPE_CONNECTION == type) {
            xpc_connection_t peer = (xpc_connection_t)event;

            char *queue_name = NULL;
            asprintf(&queue_name, "%s-peer-%d", "com.apple.sandboxedFetch.ProgressPanel",
                     xpc_connection_get_pid(peer));
            dispatch_queue_t peer_event_queue = dispatch_queue_create(queue_name, NULL);
            assert(peer_event_queue != NULL);
            free(queue_name);

            xpc_connection_set_target_queue(peer, peer_event_queue);
            xpc_connection_set_event_handler(peer, ^(xpc_object_t nevent) {
                xpc_type_t ntype = xpc_get_type(nevent);

                if (XPC_TYPE_DICTIONARY == ntype) {
                    double progressValue = xpc_dictionary_get_double(nevent, "progressValue");
                    if (progressValue != NAN) {
                        [progressIndicator setDoubleValue: progressValue];
                    }
                }
            });
            xpc_connection_resume(peer);
        }
    });
    xpc_connection_resume(connection);

    return (connection);
}

- (void) stopProgressPanel
{

    [progressPanel orderOut: self];
    [NSApp endSheet: progressPanel returnCode: 0];
}

- (IBAction)cancelAction:(id)sender {

    [progressPanel orderOut: self];
    [NSApp endSheet: progressPanel returnCode: 1];
}

- (void) progressDidEnd:(NSWindow *)panel returnCode:(int)returnCode contextInfo:(void *)context
{
    xpc_connection_t connection = (xpc_connection_t)context;

    if (returnCode != 0) {
        // The cancel button was pressed.
        NSBeep();
    }

    if (connection != NULL) {
        // Cancel and release the anonymous connection which signals the remote
        // service to stop, if working.
        xpc_connection_cancel(connection);
        xpc_release(connection);
    }
}

#pragma mark Save Panel Sheet
- (void) saveFile
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];

    NSString *fileName = [[NSURL URLWithString:sourceURL] lastPathComponent];
    if ([compressCheckbox state] == NSOffState)
        [savePanel setNameFieldStringValue:fileName];
    else
        [savePanel setNameFieldStringValue:[fileName stringByAppendingPathExtension:@"gz"]];

    [savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSOKButton) {
            [savePanel orderOut:self];

            int outfd = open([[[savePanel URL] path] UTF8String], O_WRONLY | O_CREAT | O_TRUNC, 0600);

            if (outfd != -1) {
                if ([compressCheckbox state] == NSOffState) {
                    [self startIndeterminateProgressPanel:@"Copying..."];
                    _copy_file(_fetchedFileDescriptor, outfd, ^(NSString *error, int errnum) {
                        NSString *errStr = [[NSString alloc] initWithUTF8String:strerror(errnum)];
                        [self showErrorAlert:error additionalInfo: errStr];
                        [errStr release];
                    });
                    [self stopProgressPanel];
                } else {
                    [self startIndeterminateProgressPanel:@"Compressing..."];
                    _compress_file(self->_zipServiceConnection, _fetchedFileDescriptor, outfd,
                                   ^(const char *error, int errnum) {
                        NSString *errMsgStr = [[NSString alloc] initWithUTF8String:error];
                        NSString *errNumStr = [NSString stringWithFormat:@"(zlib error code: %d)", errnum];
                        [self showErrorAlert:errMsgStr additionalInfo:errNumStr];
                        [errMsgStr release];
                    });
                    [self stopProgressPanel];
                }
                close(outfd);
                close(_fetchedFileDescriptor);
                _fetchedFileDescriptor = -1;
            } else {
                NSString *errStr = [[NSString alloc] initWithUTF8String:strerror(errno)];
                [self showErrorAlert:@"Can't open selected file to save" additionalInfo: errStr];
                [errStr release];
            }
        } else {
            close(_fetchedFileDescriptor);
            _fetchedFileDescriptor = -1;
        }

        // Reset URL and status mesage
        self.sourceURL = @"";
        self.statusMessage = @"Enter source URL";
    }];
}

#pragma mark Fetch Button Action
- (IBAction) fetchAction:(id)sender
{
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    assert(message != NULL);

    xpc_dictionary_set_string(message, "url", [sourceURL UTF8String]);
    xpc_object_t progressConn = [self startProgressPanel:@"Downloading..."];

    if (progressConn != NULL)
        xpc_dictionary_set_connection(message, "connection", progressConn);

    assert(self->_fetchServiceConnection != NULL);
    xpc_connection_send_message_with_reply(self->_fetchServiceConnection, message,
                                           dispatch_get_main_queue(), ^(xpc_object_t event) {
        assert(xpc_dictionary_get_value(event, "errcode") != NULL);
        int64_t errcode = xpc_dictionary_get_int64(event, "errcode");

        [self stopProgressPanel];

        if (errcode != 0) {
            self.statusMessage = @"Fetch XPC service failed";
            NSString *errCodeInfo = [NSString stringWithFormat:@"(Error code: %ld)", errcode];
            const char *errmsg = xpc_dictionary_get_string(event, "errmsg");
            if (errmsg != NULL) {
                NSString *errMessage = [[NSString alloc] initWithUTF8String:errmsg];
                [self showErrorAlert: errMessage additionalInfo: errCodeInfo];
                [errMessage release];
            } else {
                [self showErrorAlert: @"Unknown error" additionalInfo: errCodeInfo];
            }
        } else {
            if ((_fetchedFileDescriptor = xpc_dictionary_dup_fd(event, "fd")) != -1) {
                self.statusMessage = @"Saving fetched file";
                [self saveFile];
            } else {
                [self showErrorAlert:@"Invalid file descriptor"
                      additionalInfo:@"returned by fetch service"];
                // Reset URL and status mesage
                self.sourceURL = @"";
                self.statusMessage = @"Enter source URL";
            }

        }
    });
}

#pragma mark KVO Delegation
- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object
                         change: (NSDictionary*) change context: (void*) context
{
    BOOL fetchEnabled = NO;
    NSString *fetchKey = @"";

    if (self.sourceURL.length > 4) {
        NSRange range = [sourceURL rangeOfString:@"http"
                                         options: NSCaseInsensitiveSearch|NSAnchoredSearch];
        if (range.length == 0) {
            self.statusMessage = @"Only the HTTP protocol is supported";
        } else {
            NSString *fileName = [[NSURL URLWithString:sourceURL] lastPathComponent];
            if (fileName.length > 0 && ![fileName isEqualToString:@"/"]) {
                fetchEnabled = YES;
                fetchKey = @"\r";
            }
        }
    } else {
        self.statusMessage = @"Enter source URL";
    }

    [self.fetchButton setEnabled: fetchEnabled];
    [self.fetchButton setKeyEquivalent: fetchKey];
}

#pragma mark Application Delegations
- (void) applicationWillFinishLaunching: (NSNotification*) aNotification
{
    [self addObserver: self forKeyPath: @"sourceURL" options: NSKeyValueObservingOptionNew context: NULL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusMessage = @"Enter source URL";

    // Prep XPC services.
    self->_fetchServiceConnection = [self _connectionForServiceNamed:"com.apple.SandboxedFetch.fetch-service"
                                            connectionInvalidHandler:^{
        self->_fetchServiceConnection = NULL;
    }];
    assert(self->_fetchServiceConnection != NULL);

    self->_zipServiceConnection = [self _connectionForServiceNamed:"com.apple.SandboxedFetch.zip-service"
                                          connectionInvalidHandler:^{
        self->_zipServiceConnection = NULL;
    }];
    assert(self->_zipServiceConnection != NULL);
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) theApplication
{

    return (YES);
}

@end
