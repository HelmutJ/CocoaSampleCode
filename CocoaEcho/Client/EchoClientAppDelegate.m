/*
    File:       EchoClientAppDelegate.m

    Contains:   Main app controller.

    Copyright:  Copyright (c) 2005-2012 Apple Inc. All Rights Reserved.

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

#import "EchoClientAppDelegate.h"

@interface NSNetService (QNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr 
    outputStream:(out NSOutputStream **)outputStreamPtr;

@end

@implementation NSNetService (QNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr 
    outputStream:(out NSOutputStream **)outputStreamPtr
    // The following works around three problems with 
    // -[NSNetService getInputStream:outputStream:]:
    //
    // o <rdar://problem/6868813> -- Currently the returns the streams with 
    //   +1 retain count, which is counter to Cocoa conventions and results in 
    //   leaks when you use it in ARC code.
    //
    // o <rdar://problem/9821932> -- If you create two pairs of streams from 
    //   one NSNetService and then attempt to open all the streams simultaneously, 
    //   some of the streams might fail to open.
    //
    // o <rdar://problem/9856751> -- If you create streams using 
    //   -[NSNetService getInputStream:outputStream:], start to open them, and 
    //   then release the last reference to the original NSNetService, the 
    //   streams never finish opening.  This problem is exacerbated under ARC 
    //   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;

    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) ) {
        CFNetServiceRef     netService;

        netService = CFNetServiceCreate(
            NULL, 
            (__bridge CFStringRef) [self domain], 
            (__bridge CFStringRef) [self type], 
            (__bridge CFStringRef) [self name], 
            0
        );
        if (netService != NULL) {
            CFStreamCreatePairWithSocketToNetService(
                NULL, 
                netService, 
                ((inputStreamPtr  != nil) ? &readStream  : NULL), 
                ((outputStreamPtr != nil) ? &writeStream : NULL)
            );
            CFRelease(netService);
        }
        
        // We have failed if the client requested an input stream and didn't 
        // get one, or requested an output stream and didn't get one.  We also 
        // fail if the client requested neither the input nor the output 
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) || 
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}

@end

#pragma mark -
#pragma mark EchoClientAppDelegate class

@interface EchoClientAppDelegate () <NSApplicationDelegate, NSNetServiceBrowserDelegate, NSStreamDelegate>

// stuff for IB

@property (nonatomic, assign, readwrite) IBOutlet NSTextField * responseField;

- (IBAction)requestTextFieldReturnAction:(id)sender;

// stuff for bindings

@property (nonatomic, strong, readwrite) NSMutableArray *       services;           // of NSNetService

// private properties

@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  serviceBrowser;
@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, strong, readwrite) NSMutableData *        inputBuffer;
@property (nonatomic, strong, readwrite) NSMutableData *        outputBuffer;

// forward declarations

- (void)closeStreams;

@end

@implementation EchoClientAppDelegate

@synthesize responseField = _responseField;
@synthesize services = _serviceList;

@synthesize serviceBrowser = _serviceBrowser;
@synthesize inputStream  = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize inputBuffer  = _inputBuffer;
@synthesize outputBuffer = _outputBuffer;

- (void)awakeFromNib {
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.services = [[NSMutableArray alloc] init];
    [self.serviceBrowser setDelegate:self];
    
    [self.serviceBrowser searchForServicesOfType:@"_cocoaecho._tcp." inDomain:@"local"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    #pragma unused(sender)
    return YES;
}

#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

// We broadcast the willChangeValueForKey: and didChangeValueForKey: for the NSTableView binding to work.

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    #pragma unused(aNetServiceBrowser)
    #pragma unused(moreComing)
    if (![self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services addObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    #pragma unused(aNetServiceBrowser)
    #pragma unused(moreComing)
    if ([self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services removeObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
}

#pragma mark -
#pragma mark Stream methods

- (void)openStreamsToNetService:(NSNetService *)netService {
    NSInputStream * istream;
    NSOutputStream * ostream;

    [self closeStreams];

    if ([netService qNetworkAdditions_getInputStream:&istream outputStream:&ostream]) {
        self.inputStream = istream;
        self.outputStream = ostream;
        [self.inputStream  setDelegate:self];
        [self.outputStream setDelegate:self];
        [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream  open];
        [self.outputStream open];
    }
}

- (void)closeStreams {
    [self.inputStream  setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream  close];
    [self.outputStream close];
    [self.inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream  = nil;
    self.outputStream = nil;
    self.inputBuffer  = nil;
    self.outputBuffer = nil;
}

- (void)startOutput
{
    assert([self.outputBuffer length] != 0);
    
    NSInteger actuallyWritten = [self.outputStream write:[self.outputBuffer bytes] maxLength:[self.outputBuffer length]];
    if (actuallyWritten > 0) {
        [self.outputBuffer replaceBytesInRange:NSMakeRange(0, (NSUInteger) actuallyWritten) withBytes:NULL length:0];
        // If we didn't write all the bytes we'll continue writing them in response to the next 
        // has-space-available event.
    } else {
        // A non-positive result from -write:maxLength: indicates a failure of some form; in this 
        // simple app we respond by simply closing down our connection.
        [self closeStreams];
    }
}

- (void)outputText:(NSString *)text
{
    NSData * dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (self.outputBuffer != nil) {
        BOOL wasEmpty = ([self.outputBuffer length] == 0);
        [self.outputBuffer appendData:dataToSend];
        if (wasEmpty) {
            [self startOutput];
        }
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    assert(aStream == self.inputStream || aStream == self.outputStream);
    switch(streamEvent) {
        case NSStreamEventOpenCompleted: {
            // We don't create the input and output buffers until we get the open-completed events. 
            // This is important for the output buffer because -outputText: is a no-op until the 
            // buffer is in place, which avoids us trying to write to a stream that's still in the 
            // process of opening.
            if (aStream == self.inputStream) {
                self.inputBuffer = [[NSMutableData alloc] init];
            } else {
                self.outputBuffer = [[NSMutableData alloc] init];
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            if ([self.outputBuffer length] != 0) {
                [self startOutput];
            }
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
            if (actuallyRead > 0) {
                [self.inputBuffer appendBytes:buffer length:(NSUInteger)actuallyRead];
                // If the input buffer ends with CR LF, show it to the user.
                if ([self.inputBuffer length] >= 2 && memcmp((const char *) [self.inputBuffer bytes] + [self.inputBuffer length] - 2, "\r\n", 2) == 0) {
                    NSString * string = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
                    if (string == nil) {
                        [self.responseField setStringValue:@"response not UTF-8"];
                    } else {
                        [self.responseField setStringValue:string];
                    }
                    [self.inputBuffer setLength:0];
                }
            } else {
                // A non-positive value from -read:maxLength: indicates either end of file (0) or 
                // an error (-1).  In either case we just wait for the corresponding stream event 
                // to come through.
            }
        } break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            [self closeStreams];
        } break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark User interface action methods

- (IBAction)requestTextFieldReturnAction:(id)sender {
    [self outputText:[NSString stringWithFormat:@"%@\r\n", [sender stringValue]]];
}

- (IBAction)serviceTableClickedAction:(id)sender {
    NSTableView * table = (NSTableView *) sender;
    NSInteger selectedRow = [table selectedRow];
    
    if (selectedRow >= 0) {
        NSNetService * selectedService = [self.services objectAtIndex:(NSUInteger) selectedRow];
        [self openStreamsToNetService:selectedService];
    }
}

@end
