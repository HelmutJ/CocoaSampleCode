/*

File: ImageClient.m

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
#import <sys/socket.h>
#import <netinet/in.h>

const int kCFNetworkIndex = 0;
const int kFoundationIndex = 1;

const NSTimeInterval kRefetchInterval = 15.0;

@implementation ImageClient

- (id)init {
    if (self = [super init]) {
        cfnetworkLoader = [[CFNetworkLoader alloc] initWithImageClient:self];
        nsurlLoader = [[NSURLLoader alloc] initWithImageClient:self];
        useCFNetworkLoader = YES;
        srandomdev(); // Seed the random number generator
    }
    return self;
}

// Included for form's sake; our ImageClient object will be around for as long as the app is running
- (void)dealloc {
    if (reloadTimer) {
        [reloadTimer invalidate];
        [reloadTimer release];
    }
    [cfnetworkLoader release];
    [nsurlLoader release];

    [super dealloc];
}

// Create and start the timer that triggers a refetch every few seconds
- (void)startTimer {
    [self stopTimer];
    reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kRefetchInterval target:self selector:@selector(refetch:) userInfo:nil repeats:YES];
    [reloadTimer retain];
}

// Stop the timer; prevent future loads until startTimer is called again
- (void)stopTimer {
    if (reloadTimer) {
        [reloadTimer invalidate];
        [reloadTimer release];
        reloadTimer = nil;
    }
}

/* Called when the user enters a new URL in the textfield */
- (IBAction)newURL:(id)sender {

    // Clean up any loads in progress & restart the timer
    if (reloadTimer) {
        [self stopTimer];
        [self cancelLoad];
    }

    NSString *urlString = [urlField stringValue];
    if (urlString && [urlString length]) {
        [self startTimer];
        [self startLoad];
    }
}

/* Triggered when the user chooses a different library for loading */ 
- (IBAction)libraryChanged:(id)sender {
    NSSegmentedControl *segControl = sender;
    int selectedLibrary = [segControl selectedSegment];
    if ((selectedLibrary == kCFNetworkIndex && !useCFNetworkLoader) || (selectedLibrary == kFoundationIndex && useCFNetworkLoader)) {
        [self stopTimer];
        [self cancelLoad];
        useCFNetworkLoader = (selectedLibrary == kCFNetworkIndex);

        if ([urlField stringValue] && [[urlField stringValue] length]) {
            [self startTimer];
        [self startLoad];
    }
    }
}

/* The method called by our timer */
- (void)refetch:(NSTimer *)timer {
    [self startLoad];
}

/* Starting and stopping loads */
- (void)startLoad {
    // choose a random picture from among 100
    long randomNum = random();
    int index = randomNum % 100;
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/%d.JPG", [[urlField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]], index]];
    if (useCFNetworkLoader) {
        [cfnetworkLoader loadURL:url];
    } else {
        [nsurlLoader loadURL:url];
    }
    [url release];
}

- (void)cancelLoad {
    if (useCFNetworkLoader) {
        [cfnetworkLoader cancelLoad];
    } else {
        [nsurlLoader cancelLoad];
    }
    [imageView setImage:nil];
}

/* Called by the two loaders to report successful image loads */
- (void)setImageData:(NSData *)imageData {
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    [imageView setImage:image];
    [image release];
}

/* Called by the two loaders to report errors while loading images */
- (void)errorOccurredLoadingImage: (CFNetDiagnosticRef)diagnostics {
    [self stopTimer];
    if (diagnostics) {
        NSBeginAlertSheet(@"Download failure", @"Network Diagnostics...", @"OK", nil, [imageView window], self, @selector(errorSheetDidEnd:returnCode:contextInfo:), NULL, (void*)diagnostics, @"Could not load an image from \"%@\"", [urlField stringValue]);
    } else {
        NSBeginAlertSheet(@"Download failure", @"OK", nil, nil, [imageView window], nil, NULL, NULL, NULL, @"Could not load an image from \"%@\"", [urlField stringValue]);
    }
}

// delegate call for the diagnostic sheet dropped in -errorOccurredLoadingImage:
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	CFNetDiagnosticRef diagnostics = (CFNetDiagnosticRef)contextInfo;

	if (returnCode == NSAlertDefaultReturn) {
		(void)CFNetDiagnosticDiagnoseProblemInteractively(diagnostics);
	}
	CFRelease(diagnostics);
}
@end
