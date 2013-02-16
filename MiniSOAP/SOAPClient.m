/*
     File: SOAPClient.m
 Abstract: SOAPClient class.
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
 File: SOAPClient.m
 
 Abstract: Implementation for a basic SOAP client class
*/ 

#import "SOAPClient.h"

@interface SOAPConnection : NSURLConnection
{
@private
	NSMutableData*		_data;
	BOOL				_finished;
}
- (void) appendData:(NSData*)data;
- (NSData*) data;
- (void) setFinished:(BOOL)finished;
- (BOOL) isFinished;
@end

@implementation SOAPConnection

- (void) dealloc
{
	[_data release];

	[super dealloc];
}

- (NSData*)data
{
	return _data;
}

- (void) appendData:(NSData*)data
{
	if(_data == nil)
	_data = [NSMutableData new];
	
	[_data appendData:data];
}

- (void) setFinished:(BOOL)finished
{
	_finished = finished;
}

- (BOOL) isFinished
{
	return _finished;
}

@end

@implementation SOAPClient

- (id) initWithServerURL:(NSURL*)url
{
	if(url == nil) {
		[self release];
		return nil;
	}
	
	if(self = [super init])
	_url = [url copy];
	
	return self;
}

- (void) dealloc
{
	[_url release];
	
	[super dealloc];
}

- (NSXMLDocument*) sendMessageAndWaitForReply:(NSXMLDocument*)message timeOut:(NSTimeInterval)timeOut
{
	NSData*					data = [message XMLData];
	NSMutableURLRequest*	request;
	SOAPConnection*			connection;
	NSError*				error;
	NSTimeInterval			startTime;
	
	if(data == nil)
	return nil;
	
	request = [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeOut];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
	connection = [[SOAPConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	if(connection) {
		startTime = [NSDate timeIntervalSinceReferenceDate];
		while(![connection isFinished]) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			
			if([NSDate timeIntervalSinceReferenceDate] >= startTime + timeOut) {
				[connection cancel];
				[connection release];
				connection = nil;
				break;
			}
		}
	}
	
	message = ([connection data] ? [[NSXMLDocument alloc] initWithData:[connection data] options:NSXMLNodeOptionsNone error:&error] : nil);
	
	[connection release];
	
	return [message autorelease];
}

- (void) connection:(SOAPConnection*)connection didReceiveData:(NSData*)data
{
	[connection appendData:data];
}

- (void) connectionDidFinishLoading:(SOAPConnection*)connection
{
	[connection setFinished:YES];
}

- (void) connection:(SOAPConnection*)connection didFailWithError:(NSError*)error
{
	[connection setFinished:YES];
}

@end
