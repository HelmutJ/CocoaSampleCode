/*
    File:       QCommandLineConnection.m

    Contains:   Manages a connection consisting of CR LF delimited lines.

    Written by: DTS

    Copyright:  Copyright (c) 2011 Apple Inc. All Rights Reserved.

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

#import "QCommandLineConnection.h"

@implementation QCommandLineConnection

@synthesize commandDelegate = commandDelegate_;

#pragma mark * Overrides

// See comment in header for an explanation of what these routines are about.

- (void)willCloseWithError:(NSError *)error
{
    // error may be nil
    if ([self.commandDelegate respondsToSelector:@selector(commandLineConnection:willCloseWithError:)]) {
        [self.commandDelegate commandLineConnection:self willCloseWithError:error];
    }
    [super willCloseWithError:error];
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
    assert(format != nil);
    if ([self.commandDelegate respondsToSelector:@selector(commandLineConnection:logWithFormat:arguments:)]) {
        [self.commandDelegate commandLineConnection:self logWithFormat:format arguments:argList];
    }
    [super logWithFormat:format arguments:argList];
}

#pragma mark * Send

- (void)sendString:(NSString *)str
{
    assert(str != nil);
    [self sendCommand:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendCommandLine:(NSString *)line
{
    assert(line != nil);
    [self sendString:[NSString stringWithFormat:@"%@\r\n", line]];
}

- (void)sendCommandLines:(NSArray *)lines
{
    NSString *  linesStr;

    assert(lines != nil);
    assert([lines count] != 0);
    
    if ([lines count] == 1) {
        assert( [[lines objectAtIndex:0] isKindOfClass:[NSString class]] );
        [self sendCommandLine:[lines objectAtIndex:0]];
    } else {
        linesStr = [NSString stringWithFormat:@"%@\r\n", [lines componentsJoinedByString:@"\r\n"]];
        assert(linesStr != nil);
        [self sendString:linesStr];
    }
}

#pragma mark * Parse

- (void)didReceiveCommandLine:(NSString *)commandLine
    // See comment in header.
{
    assert(commandLine != nil);
    
    if ( [self.commandDelegate respondsToSelector:@selector(commandLineConnection:didReceiveCommandLine:)] ) {
        [self.commandDelegate commandLineConnection:self didReceiveCommandLine:commandLine];
    }
}

- (NSUInteger)parseCommandData:(NSData *)commandData
    // Called by our superclass when data arrives.  We parse command lines out 
    // of the data buffer and pass them to our delegate, returning the number of 
    // bytes successfully parsed.
    //
    // Note: Earlier versions of this code used to call [super parseCommandData], 
    // to given the super class's delegate a crack at the data before we had a go. 
    // We no longer do this because our super class now fails 
    // kQCommandConnectionInputUnexpectedError if its delegate doesn't implement 
    // -connection:parseCommandData:.
{
    const uint8_t *     bufferBytes;
    NSUInteger          bufferLength;
    NSUInteger          offset;
    NSUInteger          cursor;
    NSError *           error;

    assert(commandData != nil);
    
    bufferBytes  = [commandData bytes];
    bufferLength = [commandData length];

    assert(bufferBytes != nil);
    assert(bufferLength != 0);
    
    offset = 0;
    error  = nil;
    do {
        assert(offset <= bufferLength);
        
        cursor = offset;
        while ( (cursor < bufferLength) && (bufferBytes[cursor] != '\n') ) {
            cursor += 1;
        }
        if (cursor == bufferLength) {
            // We got to the end of the buffer before we found a line ending. 
            // We return in this case.  We'll get called back when more data 
            // arrives (or the connection will fail if the command line is 
            // longer than our input buffer).
            break;
        } else {
            NSString *  commandLine;
            
            cursor += 1;        // include the LF in the command

            // Check that the command string is valid UTF-8 and that it's correctly terminated 
            // by CR LF.  If either of these fails, we just drop the connection.  It's brutal, 
            // but it's the only thing we can do at this layer (because we don't know how to 
            // format a 'you bozo' response and we don't want to pass malformed commands up 
            // to our delegate and an extra delegate callback to deal with this seems somewhat 
            // excessive).
            
            commandLine = [[NSString alloc] initWithBytes:&bufferBytes[offset] length:cursor - offset encoding:NSUTF8StringEncoding];
            if ( (commandLine == nil) || ( ([commandLine length] < 2) || ([commandLine characterAtIndex:[commandLine length] - 2] != '\r') ) ) {
                error = [[self class] errorWithCode:kQCommandConnectionInputCommandMalformedError];
            } else {
                [self didReceiveCommandLine:commandLine];
            }
            [commandLine release];
        
            if (error != nil) {
                break;
            } else {
                offset = cursor;
            }
        }
    } while (YES);

    if (error != nil) {
        [self closeWithError:error];
    }
    
    return offset;
}

@end
