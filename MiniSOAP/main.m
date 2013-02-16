/*
     File: main.m
 Abstract: Main file.
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

/*
 File: server_main.m
 
 Abstract: Main program for SOAP server.
*/ 

#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"


@interface SOAPServer : NSObject {
    HTTPServer *httpServ;
}
@end


int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    SOAPServer *server = [[SOAPServer alloc] initWithName:@"SOAP adder"];
    [[NSRunLoop currentRunLoop] run]; // this will not return
    [server release];
    [pool release];
    exit(0);
}


@implementation SOAPServer

- (id)initWithName:(NSString *)name {
    httpServ = [[HTTPServer alloc] init];
    [httpServ setPort:54000];
	[httpServ setType:@"_http._tcp."];
    [httpServ setName:name];
    [httpServ setDelegate:self];
    NSError *error = nil;
    if (![httpServ start:&error]) {
        NSLog(@"Error starting server: %@", error);
    } else {
        NSLog(@"Starting server on port %d", [httpServ port]);
    }
    return self;
}

- (void)dealloc {
    [httpServ release];
    [super dealloc];
}

- (NSNumber *)add:(NSNumber *)num1 to:(NSNumber *)num2 {
    return [NSNumber numberWithDouble:[num1 doubleValue] + [num2 doubleValue]];
}

- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess {
    CFHTTPMessageRef request = [mess request];

    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, vers ? (CFStringRef)vers : kCFHTTPVersion1_0); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

    NSString *method = [(id)CFHTTPMessageCopyRequestMethod(request) autorelease];
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

#if 0
    // useful for testing with Safari
    if ([method isEqual:@"GET"]) {
        [[conn server] setDocumentRoot:[NSURL fileURLWithPath:@"/"]];
        [conn performDefaultRequestHandling:mess];
        return;
    }
#endif

    if ([method isEqual:@"POST"]) {
        NSError *error = nil;
        NSData *data = [(id)CFHTTPMessageCopyBody(request) autorelease];
        NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:&error] autorelease];
        NSArray *array = [doc nodesForXPath:@"soap:Envelope/soap:Body/ex:MethodName" error:&error];
        NSString *selName = [[array objectAtIndex:0] objectValue];

        // Recognize each method that is supported (only one), unpack the arguments,
        // perform the service, package up the result, and set the response.
        if ([selName isEqual:@"add:to:"]) {
            NSArray *array = [doc nodesForXPath:@"soap:Envelope/soap:Body/ex:Parameters/ex:Parameter" error:&error];
            if (2 != [array count]) {
                CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
                [mess setResponse:response];
                CFRelease(response);
                return;
            }
            
            NSXMLNode *node1 = [array objectAtIndex:0];
            NSNumber *num1 = [NSNumber numberWithDouble:[[node1 objectValue] doubleValue]];
            NSXMLNode *node2 = [array objectAtIndex:1];
            NSNumber *num2 = [NSNumber numberWithDouble:[[node2 objectValue] doubleValue]];
            NSNumber *ret = [self add:num1 to:num2];
            NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?> <soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:ex=\"http://www.apple.com/namespaces/cocoa/soap/example\"> <soap:Body> <ex:Result>%@</ex:Result> </soap:Body> </soap:Envelope>", ret];
            NSError *error = nil;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
            NSData *data = [doc XMLData];
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
            CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
            CFHTTPMessageSetBody(response, (CFDataRef)data);
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
        
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
    [mess setResponse:response];
    CFRelease(response);
}

@end

