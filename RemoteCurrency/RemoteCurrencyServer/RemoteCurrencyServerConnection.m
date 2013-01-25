/*
    File:       RemoteCurrencyServerConnection.m

    Contains:   Manages the server side of a client-server connection.

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

#import "RemoteCurrencyServerConnection.h"

@interface RemoteCurrencyServerConnection ()

// forward declarations

+ (NSDictionary *)commandDictionary;

@end

@implementation RemoteCurrencyServerConnection

@synthesize serverDelegate = serverDelegate_;

#pragma mark * Overrides

// See comment in header for an explanation of what these routines are about.

- (void)willCloseWithError:(NSError *)error
{
    // error may be nil
    if ([self.serverDelegate respondsToSelector:@selector(remoteCurrencyServerConnection:willCloseWithError:)]) {
        [self.serverDelegate remoteCurrencyServerConnection:self willCloseWithError:error];
    }
    [super willCloseWithError:error];
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
    assert(format != nil);
    if ([self.serverDelegate respondsToSelector:@selector(remoteCurrencyServerConnection:logWithFormat:arguments:)]) {
        [self.serverDelegate remoteCurrencyServerConnection:self logWithFormat:format arguments:argList];
    }
    [super logWithFormat:format arguments:argList];
}

#pragma mark * Send

// IMPORTANT: These routines bypass -[QCommandLineConnection sendCommandLine:] and go  
// straight to -[QCommandConnection sendCommand:] as a trivial optimisation.

- (void)sendString:(NSString *)str
{
    assert(str != nil);
    [self sendCommand:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendResponse:(NSString *)response
{
    assert(response != nil);
    [self sendString:[NSString stringWithFormat:@"+ %@\r\n", response]];
}

- (void)sendResponse:(NSString *)response lines:(NSArray *)lines
{
    NSString *  linesStr;

    assert(response != nil);
    assert(lines != nil);
    
    if ([lines count] == 0) {
        [self sendResponse:response];
    } else {
        linesStr = [NSString stringWithFormat:@"  %@\r\n+ %@\r\n", [lines componentsJoinedByString:@"\r\n  "], response];
        assert(linesStr != nil);
        [self sendString:linesStr];
    }
}

- (void)sendError:(NSString *)response
{
    assert(response != nil);
    [self sendString:[NSString stringWithFormat:@"- %@\r\n", response]];
}

#pragma mark * Commands implemented by the connection

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection helpCommand:(NSScanner *)scanner
    // Implements the 'help' command.
{
    NSMutableArray *    response;
    
    assert(connection == self);
    assert([scanner isAtEnd]);

    response = [NSMutableArray array];
    assert(response != nil);

    for (NSDictionary * commandDict in [[[[self class] commandDictionary] allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"usage" ascending:YES]]]) {
        assert([commandDict isKindOfClass:[NSDictionary class]]);
        [response addObject:[commandDict objectForKey:@"usage"]];
    }

    [self sendResponse:@"OK" lines:response];
}

#pragma mark * Parse

+ (NSDictionary *)commandDictionary
    // Sets up the sCommands global with a dictionary of all the commands 
    // we support.
{
    static NSDictionary *   sCommands;

    if (sCommands == nil) {
        sCommands = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"remoteCurrencyServerConnection:helpCommand:",     @"selector", 
                @"help",                                            @"usage", 
                [NSNumber numberWithBool:YES],                      @"targetSelf", 
                nil
            ], @"help", 
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"remoteCurrencyServerConnection:helloCommand:",    @"selector", 
                @"hello",                                           @"usage", 
                nil
            ], @"hello", 
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"remoteCurrencyServerConnection:goodbyeCommand:",  @"selector", 
                @"goodbye",                                         @"usage", 
                nil
            ], @"goodbye", 
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"remoteCurrencyServerConnection:stopCommand:",     @"selector", 
                @"stop",                                            @"usage", 
                nil
            ], @"stop", 
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"remoteCurrencyServerConnection:convertCommand:",  @"selector", 
                @"convert <name> <value> to <name>",                @"usage", 
                [NSNumber numberWithBool:YES],                      @"hasArguments", 
                nil
            ], @"convert",
            nil
        ];
        assert(sCommands != nil);
    }
    return sCommands;
}

- (void)didReceiveCommandLine:(NSString *)commandLine
    // Called when we receive a command from the client.  This basically 
    // dispatches the command to the relevant method that implements it.
{
    assert(commandLine != nil);
    assert([commandLine length] >= 2);
    
    // If the length is 2, implying that there's just a CR LF, that's a null command 
    // and that's OK.
    
    if ([commandLine length] == 2) {
        assert( [commandLine isEqual:@"\r\n"]);
        [self sendResponse:@"OK"];
    } else {
        BOOL            success;
        NSScanner *     scanner;
        NSString *      commandStr;
        NSDictionary *  commandDict;
        NSString *      commandSelectorName;
        SEL             commandSelector;
        BOOL            commandHasArguments;
        BOOL            commandTargetsSelf;

        // Create a scanner for the command line.  We don't need to strip the trailing 
        // CR LF because NSScanner skips newlines by default.
        
        scanner = [NSScanner scannerWithString:commandLine];
        assert(scanner != nil);
        
        // Grab the first word of the command line.
        
        success = [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&commandStr];
        if (success) {
            commandStr = [commandStr lowercaseString];
            
            commandDict = [[[self class] commandDictionary] objectForKey:commandStr];
            assert( (commandDict == nil) || [commandDict isKindOfClass:[NSDictionary class]] );
            success = (commandDict != nil);
        }
        
        // Use that to look up the command and then dispatch.
        
        if (success) {
            commandSelectorName = [commandDict objectForKey:@"selector"];
            assert([commandSelectorName isKindOfClass:[NSString class]]);
            
            commandSelector = NSSelectorFromString(commandSelectorName);
            assert(commandSelector != nil);
            
            // Note that commandDict might not contain the hasArguments key, which will 
            // result in commandHasArguments being NO.  Likewise for the targetSelf key.
            commandHasArguments = [[commandDict objectForKey:@"hasArguments"] boolValue];
            commandTargetsSelf  = [[commandDict objectForKey:@"targetSelf"] boolValue];
            
            if ( ! commandHasArguments && ! [scanner isAtEnd] ) {
                [self sendError:[NSString stringWithFormat:@"'%@' takes no arguments", commandStr]];
            } else {
                if (commandTargetsSelf) {
                    [self performSelector:commandSelector withObject:self withObject:scanner];
                } else {
                    [self.serverDelegate performSelector:commandSelector withObject:self withObject:scanner];
                }
            }
        }
        if ( ! success ) {
            [self sendError:@"Unknown command"];
        }
    }
}

@end
