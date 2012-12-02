//     File: DecisionAgent.m
// Abstract: Implementation of the Agent protocol.
//  Version: 1.1
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2012 Apple Inc. All Rights Reserved.
// 

#import <Foundation/Foundation.h>
#import "DecisionAgent.h"

#include <stdlib.h>

@implementation DecisionAgent

#pragma mark -
#pragma mark NSXPCConnection method overrides

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
	// This method is called by the NSXPCListener to filter/configure
	// incoming connections.
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Agent)];
	newConnection.exportedObject = self;
	
	// Start processing incoming messages.
	[newConnection resume];

	return YES;
}

#pragma mark -
#pragma mark Public interface

static BOOL
looksLikeAQuestion(NSString *query)
{
	NSRange questionMark = [query rangeOfString:@"?"];
	return questionMark.location != NSNotFound;
}

static BOOL
couldBeBooleanQuestion(NSString *query)
{
	static NSPredicate *interrogatives;
	static dispatch_once_t once;

	dispatch_once(&once, ^{
		interrogatives = [NSPredicate predicateWithFormat:
				  @"SELF BEGINSWITH[c] 'who' OR "
				   "SELF BEGINSWITH[c] 'whom' OR "
				   "SELF BEGINSWITH[c] 'what' OR "
				   "SELF BEGINSWITH[c] 'which' OR "
				   "SELF BEGINSWITH[c] 'when' OR "
				   "SELF BEGINSWITH[c] 'where' OR "
				   "SELF BEGINSWITH[c] 'why' OR "
				   "SELF BEGINSWITH[c] 'how'"];
	});
	return ![interrogatives evaluateWithObject:query];
}

static NSString *
randomSelection(NSArray *options)
{
	NSUInteger numOptions = [options count];
	NSUInteger selectedOption = arc4random_uniform((u_int32_t)numOptions);
	return [options objectAtIndex:selectedOption];
}

- (void)adviseOn:(NSString *)query reply:(void (^)(NSString *advice))reply
{
	query = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if (!looksLikeAQuestion(query)) {
		reply(@"Please re-phrase in the form of a question.");
	} else if (!couldBeBooleanQuestion(query)) {
		reply(@"I can only answer yes/no questions.");
	} else {
		reply(randomSelection(@[
			@"It is certain.",
			@"It is decidedly so.",
			@"Without a doubt.",
			@"Yes – definitely.",
			@"You may rely on it.",
			@"As I see it, yes.",
			@"Most likely.",
			@"Outlook good.",
			@"Yes.",
			@"Signs point to yes.",
			@"Reply hazy, try again.",
			@"Ask again later.",
			@"Better not tell you now.",
			@"Cannot predict now.",
			@"Concentrate and ask again.",
			@"Don't count on it.",
			@"My reply is no.",
			@"My sources say no.",
			@"Outlook not so good.",
			@"Very doubtful."
		]));
	}
}

@end
