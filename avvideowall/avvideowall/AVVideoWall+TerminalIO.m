/*
     File: AVVideoWall+TerminalIO.m
 Abstract: An AVVideoWall category, responsible for setting up terminal I/O for the command line application
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "AVVideoWall+TerminalIO.h"

#include <termios.h>

@implementation AVVideoWall (TerminalIO)

struct termios	termsettings_orig;
struct termios	termsettings_cbreak;

static void restoreTermIOState(void)
{
	tcsetattr(0, TCSANOW, &termsettings_orig);
}

static void signalHandler(int sig)
{
	restoreTermIOState();
}

- (BOOL)run
{
	__block  BOOL quit = NO;
	dispatch_queue_t keyboardInputQueue = dispatch_queue_create("keyboard input queue", DISPATCH_QUEUE_SERIAL);
    // Start running the capture session
	[_session startRunning];
	
	dispatch_async(keyboardInputQueue, ^(void) {
		atexit(restoreTermIOState);
		signal(SIGHUP, signalHandler);
		signal(SIGINT, signalHandler);
		
		// stash current termios state, switch to cbreak mode
		tcgetattr(0, &termsettings_orig);
		termsettings_cbreak = termsettings_orig;
		termsettings_cbreak.c_lflag &= ~(ICANON | ECHO); // non-canonical mode, disable echo
		termsettings_cbreak.c_cc[VTIME] = 0; // tenths of seconds between bytes
		termsettings_cbreak.c_cc[VMIN] = 1; // num of chars received before returning
		tcsetattr(0, TCSANOW, &termsettings_cbreak);
		
		while ( !quit ) {
			int curChar = getchar();
			switch (curChar) {
				case ' ':
                    // If the layers are flying around
					if ( _spinningLayers ) {
						dispatch_async(dispatch_get_main_queue(), ^(void) {
							_spinningLayers = NO;
                            // Reset the layers
							[self sendLayersHome];
						});
					}
                    // If the layers are at their initial positions
					else {
						dispatch_async(dispatch_get_main_queue(), ^(void) {
							_spinningLayers = YES;
                            // Spin the layers
							[self spinLayers];
						});
					}
					break;
				case 'q':
				case 'Q':
					quit = YES;
					break;
					
				default:
					break;
			}
		}
	});
	
	while ( !quit ) {
		NSDate* halfASecondFromNow = [[NSDate alloc] initWithTimeIntervalSinceNow:.5];
		[[NSRunLoop currentRunLoop] runUntilDate:halfASecondFromNow];
        [halfASecondFromNow release];
		halfASecondFromNow = nil;
	}
	NSLog(@"Quitting");
    // Stop running the capture session
	[_session stopRunning];
	dispatch_release(keyboardInputQueue);
	return YES;
}

@end
