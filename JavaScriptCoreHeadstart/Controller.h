/*
     File: Controller.h
 Abstract: Main controller class for the application.
 This class is very similar to a controller that you would find in any
 other application with the exception that it dispatches most of
 command processing to functions defined in the startup JavaScript
 where the actual decisions about how to handle the various commands
 received from the GUI are made.
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


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSWrappers.h"


@interface Controller : NSObject {
	
		/* IB objects for the main browser window. */
    IBOutlet NSWindow *browserWindow;
    IBOutlet NSTextField *theURL;
    IBOutlet WebView *theWebView;
    IBOutlet NSButton *goBack;
    IBOutlet NSButton *goForward;
    IBOutlet NSButton *goTo;
    IBOutlet NSTextField *messageText;
    IBOutlet NSProgressIndicator *progressBar;

		/* IB objects for the JavaScript Console window. */
    IBOutlet NSWindow *consoleWindow;
    IBOutlet NSTextView *consoleText;
    IBOutlet NSTextView *scriptText;
	
		/* IB objects for the startup script window. */
    IBOutlet NSWindow *startupWindow;
    IBOutlet NSTextView *startupScriptText;
	
		/* IB objects for the page load script window. */
    IBOutlet NSWindow *pageloadWindow;
    IBOutlet NSTextView *pageloadScriptText;
	
		/* reference to the wrapper convenience class */
    JSWrappers *jsWrapper;
	
		/* reference to the Controller's JavaScript context */
	JSGlobalContextRef mainJSContext;

		/* internal state variables */
	NSString *mouseOverURL; /* url under the mouse */
	NSString *urlOfLoadingPage; /* url of page being loaded, while loading */
	BOOL isLoadingPage; /* true while loading a page */
}

	/* property definitions for browser window objects */
@property(retain, readwrite) NSWindow *browserWindow;
@property(retain, readwrite) NSTextField *theURL;
@property(retain, readwrite) WebView *theWebView;
@property(retain, readwrite) NSButton *goBack;
@property(retain, readwrite) NSButton *goForward;
@property(retain, readwrite) NSButton *goTo;
@property(retain, readwrite) NSTextField *messageText;
@property(retain, readwrite) NSProgressIndicator *progressBar;

	/* property definitions for the JavaScript Console window. */
@property(retain, readwrite) NSWindow *consoleWindow;
@property(retain, readwrite) NSTextView *consoleText;
@property(retain, readwrite) NSTextView *scriptText;

	/* property definitions for the startup script window. */
@property(retain, readwrite) NSWindow *startupWindow;
@property(retain, readwrite) NSTextView *startupScriptText;

	/* property definitions for the startup script window. */
@property(retain, readwrite) NSWindow *pageloadWindow;
@property(retain, readwrite) NSTextView *pageloadScriptText;

	/* property definition for the wrapper convenience class */
@property(retain, readwrite) JSWrappers *jsWrapper;

	/* property definition for the Controller's JavaScript context */
@property(assign, readwrite) JSGlobalContextRef mainJSContext;

	/* property definitions forinternal state variables */
@property(retain, readwrite) NSString *urlOfLoadingPage;
@property(retain, readwrite) NSString *mouseOverURL;
@property(assign, readwrite) BOOL isLoadingPage;

	/* nib initialization */
- (void)awakeFromNib;

	/* add a message to the bottom of the console
	text in the console window.  The message is scrolled
	into view and displayed as a separate line of text. */
- (void)appendMessageToConsole:(NSString *)theMessage;

	/* IB Actions */
	
	/* Four browser window actions.
	- Go back and forward in the browser history.
	- Go to the url displayed in the url field.
	- reload the current page.  See the extended comments
	in the file Controller.m for more information about
	these methods.  */
- (IBAction)goBackAction:(id)sender;
- (IBAction)goForwardAction:(id)sender;
- (IBAction)goToAction:(id)sender;
- (IBAction)reloadAction:(id)sender;

	/* two console window actions.
	- display the console window
	- evaluate the JavaScript in the script field in the
	console window.  See the extended comments
	in the file Controller.m for more information about
	these methods.  */
- (IBAction)openConsoleWindowAction:(id)sender;
- (IBAction)evaluateConsoleScriptAction:(id)sender;


	/* two console window actions.
	- display the startup javascript window
	- re-evaluate the JavaScript in the script field in the startup
	script window.  See the extended comments
	in the file Controller.m for more information about
	these methods.  */
- (IBAction)openStartupScriptWindowAction:(id)sender;
- (IBAction)evaluateStartupScriptAction:(id)sender;

	/* open the page load script window.  See the extended comments
	in the file Controller.m for more information about
	this method.  */
- (IBAction)openPageLoadWindowAction:(id)sender;



@end
