/*

File: CFNetworkLoader.m

Abstract: CFNetwork ImageClient Sample

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright (c) 2005 Apple Computer, Inc., All Rights Reserved

*/ 

#import "ImageClient.h"
#import "CFNetworkLoader.h"
#import "NSURLLoader.h"

#define BUFSIZE 4096

static void handleStreamEvent(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
    CFNetworkLoader *self = (CFNetworkLoader *)clientCallBackInfo;
    [self handleStreamEvent:type];
}

static void proxyChanged(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
    CFNetworkLoader *self = (CFNetworkLoader *)info;
    [self proxyChanged];
}

@implementation CFNetworkLoader

- (id)initWithImageClient:(ImageClient *)imgClient {
    if (self = [super init]) {
        imageClient = imgClient; // No retain because the ImageClient instance is retaining us
        
        // Create the dynamic store, to monitor changes to the proxy dictionary
        SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
        systemDynamicStore = SCDynamicStoreCreate(NULL, CFSTR("ImageClient"), proxyChanged, &context);
        
        // Set up the store to monitor any changes to the proxies
        CFStringRef proxiesKey = SCDynamicStoreKeyCreateProxies(NULL);
        CFArrayRef keyArray = CFArrayCreate(NULL, (const void **)(&proxiesKey), 1, &kCFTypeArrayCallBacks);
        SCDynamicStoreSetNotificationKeys(systemDynamicStore, keyArray, NULL);
        CFRelease(keyArray);
        CFRelease(proxiesKey);
        
        // Add the dyanmic store with the run loop
        CFRunLoopSourceRef storeRLSource = SCDynamicStoreCreateRunLoopSource(NULL, systemDynamicStore, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), storeRLSource, kCFRunLoopCommonModes);
        CFRelease(storeRLSource);
        
        // Preload the proxy dictionary with the current settings
        proxyDictionary = SCDynamicStoreCopyProxies(systemDynamicStore);
		
        authArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
        credentialsDict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)dealloc {
    if (request) CFRelease(request);
    [self cancelLoad];
    
	if (authArray) CFRelease(authArray);
	if (credentialsDict) CFRelease(credentialsDict);
	
    if (proxyDictionary) CFRelease(proxyDictionary);

    // Need to invalidate the dynamic store's run loop source to get the store out of the run loop
    CFRunLoopSourceRef rls = SCDynamicStoreCreateRunLoopSource(NULL, systemDynamicStore, 0);
    CFRunLoopSourceInvalidate(rls);
    CFRelease(rls);
    CFRelease(systemDynamicStore);

    [super dealloc];
}

- (void)loadURL:(NSURL *)url {
    // set the request for the new transaction
    if (request) CFRelease(request);
    request = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (CFURLRef)url, kCFHTTPVersion1_1);
	
	// Check for existing carryover authentication for reuse
	CFHTTPAuthenticationRef authentication = [self findAuthenticationForRequest];

	if (authentication) {
	
		// See if we have credentials already; if so, apply them
		CFMutableDictionaryRef credentials = (CFMutableDictionaryRef)CFDictionaryGetValue(credentialsDict, authentication);
		
		if (!credentials || !CFHTTPMessageApplyCredentialDictionary(request, authentication, credentials, NULL)) {
		
            // Remove an authentication object from authArray and let the request fail to build new
            CFIndex authIndex = CFArrayGetFirstIndexOfValue(authArray, CFRangeMake(0, CFArrayGetCount(authArray)), authentication);
            if (authIndex != kCFNotFound) {
                CFArrayRemoveValueAtIndex(authArray, authIndex);
            }
            
            // Also remove any matching credentials from the credentialDict
            CFDictionaryRemoveValue(credentialsDict, authentication);
		}
	}
	
    // Start the load
    [self loadRequest];
}

- (void)loadRequest {
    // Cancel any load currently in progress
    [self cancelLoad];

    // Start a fresh data to hold the downloaded image
    data = CFDataCreateMutable(NULL, 0);
    
    readStream = CFReadStreamCreateForHTTPRequest(NULL, request);
    
    /* Support for the default proxy - quick and dirty
       The code below would work, but is very expensive for repeated downloads, because each call, it recreates
       the state necessary for communicating with the system configuration server.  Use it for single-shot downloads only;
       for repeated downloads, maintain a dynamic store to watch for changes, as we do
       (see the -initWithImageClient:, above, for the necessary set up)
       
        CFDictionaryRef proxyDict = SCDynamicStoreCopyProxies(NULL);
        CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxyDict);
    */

    // proxyDictionary is maintained by systemDynamicStore and its callback; see the setup in -initWithClient: for details
    CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxyDictionary);
    
    CFStreamClientContext context = {0, self, NULL, NULL, NULL};
    CFReadStreamSetClient(readStream, kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred, handleStreamEvent, &context);
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

    CFReadStreamOpen(readStream);
}

- (void)cancelLoad {
    if (readStream) {
        CFReadStreamClose(readStream);
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(readStream);
        readStream = NULL;
    }
    if (data) {
        CFRelease(data);
        data = NULL;
        
        haveExaminedHeaders = NO;
    }
}

// Callback for CFReadStream
- (void)handleStreamEvent:(CFStreamEventType)event {
    switch (event) {
        case kCFStreamEventHasBytesAvailable: {
            if (!haveExaminedHeaders) {
                haveExaminedHeaders = YES;
                if ([self isAuthorizationFailure]) {
                    [self retryAfterAuthorizationFailure];
                    break;
                }
            }

            UInt8 buffer[BUFSIZE];
            int bytesRead = CFReadStreamRead(readStream, buffer, BUFSIZE);
            if (bytesRead > 0) {
                CFDataAppendBytes(data, buffer, bytesRead);
            }
            // Don't worry about bytesRead <= 0, because those will generate other events
            break;
        }
        case kCFStreamEventEndEncountered: 
            if (!haveExaminedHeaders) {
                haveExaminedHeaders = YES;
                if ([self isAuthorizationFailure]) {
                    [self retryAfterAuthorizationFailure];
                    break;
                }
            }
            [imageClient setImageData:(NSData *)data];
            [self cancelLoad];
            break;
        case kCFStreamEventErrorOccurred: {
            CFNetDiagnosticRef diagnostics = CFNetDiagnosticCreateWithStreams(NULL, readStream, NULL);
            [imageClient errorOccurredLoadingImage:diagnostics];
			[self cancelLoad];
            break;
        }
        default:
            NSLog(@"Received unexpected stream event %d\n", event);
    }
}

// Callback for a change in the proxy dictionary
- (void)proxyChanged {
    CFRelease(proxyDictionary);
    proxyDictionary = SCDynamicStoreCopyProxies(systemDynamicStore);
}

// Examines the server response to determine if it is an authentication challenge
- (BOOL)isAuthorizationFailure {
    CFHTTPMessageRef responseHeaders = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
    if (responseHeaders) {
        // Is the server response an challenge for credentials?
        BOOL isAuthenticationChallenge = (CFHTTPMessageGetResponseStatusCode(responseHeaders) == 401);
        CFRelease(responseHeaders);
        return isAuthenticationChallenge;
    }
    return NO;
}

// Cancels the current load and handles authentication failure
- (void)retryAfterAuthorizationFailure {
    /* Quick and dirty solution - Uncommenting the code below would work (in place of 
       the lengthier code used in this method), but is not as robust.  It would mean 
       that the full (sometimes lengthy) security handshake with the server would take
       place for every request to that server, rather than taking advantage of prior 
       communication with the server.  It would also make it nearly impossible for
       client code to keep track of credentials entered by the user, reapplying them
       if appropriate to future requests.  As if that weren't enough, finally, this API
       does not support authentication schemes that require multiple round-trips to the
       server, which includes NTLM.

        CFHTTPMessageRef responseHeaders = <copy response header from stream>
        if (CFHTTPMessageAddAuthentication(request, responseHeaders, <username>, <password>, NULL, NO) {
            <retry the request>
        } else {
            <failed to apply credentials>;
        }
    */

	CFHTTPAuthenticationRef authentication = [self findAuthenticationForRequest];

	// Need to get the authentication object to be used for authenticating to the server.
	// The same authentication object should be re-used until it goes invalid.
	if (!authentication) {

		// cancelLoad will destroy the readStream, which means we'll lose access to the response header
		// Grab it first.
		CFHTTPMessageRef responseHeader = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
		
		// Get the authentication information from the response.
		authentication = CFHTTPAuthenticationCreateFromResponse(NULL, responseHeader);

		CFRelease(responseHeader);
		
		// If successful in creation, add it to the list for attempting and reusing.
		if (authentication) {
			CFArrayAppendValue(authArray, authentication);
			CFRelease(authentication);
		}
	}
	
    // Check to see if the authentication is valid for use.  If it's not, then something
    // has gone completely sour - either we have the wrong credentials, or CFNetwork doesn't
    // support the type of authentication requested by the server, or CFNetwork could not parse the 
    // server's response
    CFStreamError err;
    if (!authentication || !CFHTTPAuthenticationIsValid(authentication, &err)) {
	
		if (authentication) {
            
            // Remove any matching credentials from the credentialDict
            CFDictionaryRemoveValue(credentialsDict, authentication);
			
            // Remove an invalid authentication object from authArray.
            CFIndex authIndex = CFArrayGetFirstIndexOfValue(authArray, CFRangeMake(0, CFArrayGetCount(authArray)), authentication);
            if (authIndex != kCFNotFound) {
                CFArrayRemoveValueAtIndex(authArray, authIndex);
            }
			
			// Check for bad credentials and treat these separately
			if (err.domain == kCFStreamErrorDomainHTTP && (err.error == kCFStreamErrorHTTPAuthenticationBadUserName || err.error == kCFStreamErrorHTTPAuthenticationBadPassword)) {
				
				// At this point, it had to have been a reused authentication object.  It has now been
				// tossed, and we'll try to create a new one and prompt the user for it.
				[self retryAfterAuthorizationFailure];
				
				return;  // NOTE this early return since the nested retry has done the necessary work.
			}
			else {				
				[imageClient errorOccurredLoadingImage:NULL];
			}
		}
		
		else {			
            [imageClient errorOccurredLoadingImage:NULL];
		}
		
		// Cancel the current load
		[self cancelLoad];
    }
	
	// Authentication is good.  Deal with it.
	else {
		
		// Cancel the current load
		[self cancelLoad];
		
		// See if we have credentials already; if so, apply them
		CFMutableDictionaryRef credentials = (CFMutableDictionaryRef)CFDictionaryGetValue(credentialsDict, authentication);
		
		// Have already prompted for credentials.  Just keep re-using them until the 
		// server denies them.  Some authentication methods require multiple trips
		// until the connection is authenticated.  Until that point, the server will
		// still return a 401 or 407.  CFHTTPAuthentication will recognize and go bad
		// when the server denies the credentials.
		if (credentials) {
			[self resumeWithCredentials];
		}
		
		// Do we need username & password?  Not all authentication types require them.
		else if (CFHTTPAuthenticationRequiresUserNameAndPassword(authentication)) {
			
			CFStringRef realm = NULL;
			CFURLRef url = CFHTTPMessageCopyRequestURL(request);
			
			// Do we need an account domain (used currently for NTLM only).  NTLM does not
			// specify a realm the same as Basic and Digest, so use this to know to display
			// certain UI elements in the sheet.  Realm could be used for NTLM but it will
			// specify the requested domain.
			if (!CFHTTPAuthenticationRequiresAccountDomain(authentication))
				realm = CFHTTPAuthenticationCopyRealm(authentication);
				
			[imageClient authorizationNeededForRealm: (NSString*)realm onHost: [(NSURL*)url host]];
			
			if (realm) CFRelease(realm);
			CFRelease(url);
		}
		
		// Authentication schemes not requiring credentials go straight through.
		else {
			[self resumeWithCredentials];
		}
	}
}

- (void)resumeWithCredentials {

	CFHTTPAuthenticationRef authentication = [self findAuthenticationForRequest];

	// See if we have credentials already; if so, apply them
	CFMutableDictionaryRef credentials = (CFMutableDictionaryRef)CFDictionaryGetValue(credentialsDict, authentication);
	
	if (!credentials) {
	
		// Build the credentials dictionary
		credentials = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		// Need to add the vital bits
		if (CFHTTPAuthenticationRequiresUserNameAndPassword(authentication)) {
		
			// Get the entered username and password
			CFStringRef user = (CFStringRef)[imageClient username];
			CFStringRef pass = (CFStringRef)[imageClient password];
			
			// Guarantee values
			if (!user) user = (CFStringRef)@"";
			if (!pass) pass = (CFStringRef)@"";
			
			CFDictionarySetValue(credentials, kCFHTTPAuthenticationUsername, user);
			CFDictionarySetValue(credentials, kCFHTTPAuthenticationPassword, pass);
			
			// Do we need an account domain (used currently for NTLM only)
			if (CFHTTPAuthenticationRequiresAccountDomain(authentication)) {
				CFStringRef domain = (CFStringRef)[imageClient accountDomain];
				if (!domain) domain = (CFStringRef)@"";
				CFDictionarySetValue(credentials, kCFHTTPAuthenticationAccountDomain, domain);
			}
		}
		
		CFDictionarySetValue(credentialsDict, authentication, credentials);
		CFRelease(credentials); // It's retained in the dictionary now
	}
	
	// Apply whatever credentials we've built up to the old request
	if (!CFHTTPMessageApplyCredentialDictionary(request, authentication, credentials, NULL)) {
		[imageClient errorOccurredLoadingImage:NULL];
	} else {
		// Now that we've updated our request, retry the load
		[self loadRequest];
	}
}

- (CFHTTPAuthenticationRef)findAuthenticationForRequest {

	// As you can imagine, this is not necessarily the fastest way to find the matching
	// authentication object.  Many schemes could be used in order to produce a faster
	// model.  A tree using the domain and realm components of the authentication object
	// could be used to produce a more efficient search.  The point of this exercise is
	// to show the reuse though.

    int i, c = CFArrayGetCount(authArray);
    for (i = 0; i < c; i ++) {
        CFHTTPAuthenticationRef auth = (CFHTTPAuthenticationRef)CFArrayGetValueAtIndex(authArray, i);
        if (CFHTTPAuthenticationAppliesToRequest(auth, request)) {
            return auth;
        }
    }
	
	return NULL;
}

@end
