//     File: NSXPCConnection+LoginItem.m
// Abstract: Category adding methods to NSXPCConnection for connecting to services hosted by login items
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

#import <ServiceManagement/SMLoginItem.h>
#import "NSXPCConnection+LoginItem.h"

@implementation NSXPCConnection (LoginItem)

- (NSXPCConnection *)initWithLoginItemName:(NSString *)loginItemName error:(NSError **)errorp
{
	NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
	NSURL *loginItemDirURL = [mainBundleURL URLByAppendingPathComponent:@"Contents/Library/LoginItems" isDirectory:YES];
	NSURL *loginItemURL = [loginItemDirURL URLByAppendingPathComponent:loginItemName];
	return [self initWithLoginItemURL:loginItemURL error:errorp];
}

- (NSXPCConnection *)initWithLoginItemURL:(NSURL *)loginItemURL error:(NSError **)errorp
{
	NSBundle *loginItemBundle = [NSBundle bundleWithURL:loginItemURL];
	if (loginItemBundle == nil) {
		if (errorp != NULL) {
			*errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
					NSLocalizedFailureReasonErrorKey: @"failed to load bundle",
					NSURLErrorKey: loginItemURL
				   }];
		}
		return nil;
	}
	
	// Lookup the bundle identifier for the login item.
	// LaunchServices implicitly registers a mach service for the login
	// item whose name is the name as the login item's bundle identifier.
	NSString *loginItemBundleId = [loginItemBundle bundleIdentifier];
	if (loginItemBundleId == nil) {
		if (errorp != NULL) {
			*errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
					NSLocalizedFailureReasonErrorKey: @"bundle has no identifier",
					NSURLErrorKey: loginItemURL
				   }];
		}
		return nil;
	}

	// The login item's file name must match its bundle Id.
	NSString *loginItemBaseName = [[loginItemURL lastPathComponent] stringByDeletingPathExtension];
	if (![loginItemBundleId isEqualToString:loginItemBaseName]) {
		if (errorp != NULL) {
			NSString *message = [NSString stringWithFormat:@"expected bundle identifier \"%@\" for login item \"%@\", got \"%@\"",
					     loginItemBaseName, loginItemURL,loginItemBundleId];
			*errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
					NSLocalizedFailureReasonErrorKey: @"bundle identifier does not match file name",
					NSLocalizedDescriptionKey: message,
					NSURLErrorKey: loginItemURL
				   }];
		}
		return nil;
	}

	// Enable the login item.
	// This will start it running if it wasn't already running.
	if (!SMLoginItemSetEnabled((__bridge CFStringRef)loginItemBundleId, true)) {
		if (errorp != NULL) {
			*errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
				NSLocalizedFailureReasonErrorKey: @"SMLoginItemSetEnabled() failed"
			}];
		}
		return nil;
	}

	return [self initWithMachServiceName:loginItemBundleId options:0];
}


@end
