/*

File: ImageClient.h

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

#import <Cocoa/Cocoa.h>

@class CFNetworkLoader, NSURLLoader;

@interface ImageClient : NSObject
{
    // Connections to our UI
    IBOutlet NSImageView *imageView;
    IBOutlet NSTextField *urlField;
	
    // Connections to the sheet that prompts for user/pass
    IBOutlet NSWindow *authSheet;

    IBOutlet NSTextField *authPrompt;
    IBOutlet NSTextField *userField;
    IBOutlet NSTextField *passField;
    IBOutlet NSTextField *realmPrompt;
    IBOutlet NSTextField *realmField;
	IBOutlet NSTextField *accountDomainField;
	
	IBOutlet NSButton* saveSwitch;
	
    // Repeating, 15 second timer that causes us to refetch the image displayed
    NSTimer *reloadTimer; 
    
    // Whether to use the CFNetwork loader versus the Foundation Loader
    BOOL useCFNetworkLoader;

    // Whether we're waiting for user credentials
    BOOL waitingForCredentials;

    // The two loader objects
    CFNetworkLoader *cfnetworkLoader;
    NSURLLoader *nsurlLoader;
}

// start and stop the timer
- (void)startTimer;
- (void)stopTimer;

// The timer's callback
- (void)refetch:(NSTimer *)timer;

// action method for the URL text field
- (IBAction)newURL:(id)sender;

// start and stop individual loads
- (void)startLoad;
- (void)cancelLoad;

// Called by the two loaders to report their progress
- (void)setImageData:(NSData *)imageData;
- (void)errorOccurredLoadingImage:(CFNetDiagnosticRef)diagnostics;

// Called by the two loaders to prompt for credentials
- (void)authorizationNeededForRealm:(NSString *)realm onHost:(NSString *)host isProxy:(BOOL)isProxy;

// action method for the buttons on the authentication dialog
- (IBAction)dismissAuthSheet:(id)sender;

// delegate call for the authentication sheet dropped in -authorizationNeededForRealm:onHost:
- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

// Called by the two loaders to get authorization information
- (NSString *)username;
- (NSString *)password;
- (NSString *)accountDomain;

// delegate call for the diagnostic sheet dropped in -errorOccurredLoadingImage:
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (BOOL)saveCredentials;

@end
