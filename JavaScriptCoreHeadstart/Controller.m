/*
     File: Controller.m 
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



#import "Controller.h"
#import "Console.h"
#import "Browser.h"
#import "Startup.h"
#import "PageLoad.h"
#import "Functions.h"
#import "NSTextViewExtras.h"



@implementation Controller


	/* synthesized Objective-C 2.0 property accessors */
@synthesize consoleWindow, scriptText, consoleText, goBack, goForward, jsWrapper;
@synthesize goTo, theURL, messageText, progressBar, theWebView, urlOfLoadingPage;
@synthesize mainJSContext, startupWindow, startupScriptText, browserWindow;
@synthesize mouseOverURL, pageloadWindow, pageloadScriptText, isLoadingPage;



	/* called after our nib has been loaded */
- (void)awakeFromNib {
	
		/* special font for our text fields */
    [self.startupScriptText setFont:[NSFont fontWithName:@"Courier" size:12]];
    [self.scriptText setFont:[NSFont fontWithName:@"Courier" size:12]];
    [self.consoleText setFont:[NSFont fontWithName:@"Courier" size:12]];
    [self.messageText setFont:[NSFont fontWithName:@"Geneva" size:10]];
	
		/* set the delegte methods for the main WebView */
	[self.theWebView setUIDelegate: self ];
	[self.theWebView setFrameLoadDelegate: self ];
	[self.theWebView setResourceLoadDelegate: self];
	[self.theWebView setPolicyDelegate: self ];
	[self.theWebView setUIDelegate: self ];

		/* add web page loading notifications. */
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(webLoadComplete:) 
		name:WebViewProgressFinishedNotification
		object: self.theWebView];
	
		/* create the Controller's JavaScript context */
	self.mainJSContext = JSGlobalContextCreate( NULL );
	
		/* initialize our javascript calling utility object */
	self.jsWrapper = [[[JSWrappers alloc] initWithContext: self.mainJSContext] autorelease];

		/* add some pre-defined methods to the context */

		/* add a program and version properties read from the info-plist*/
	[self.jsWrapper addGlobalStringProperty:@"version" withValue:
		[[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString*) kCFBundleVersionKey]];
	[self.jsWrapper addGlobalStringProperty:@"program" withValue:
		[[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString*) kCFBundleNameKey]];

		/* Add a our messagbox function definition to the global object. */
	[self.jsWrapper addGlobalFunctionProperty:@"messagebox" withCallback: MessagBoxFunction];

		/* add the console, startup, and browsers objects. */
	[self.jsWrapper addGlobalObject:@"console" ofClass: ConsoleClass() withPrivateData: self];
	[self.jsWrapper addGlobalObject:@"startup" ofClass: StartupClass() withPrivateData: self];
	[self.jsWrapper addGlobalObject:@"browser" ofClass: BrowserClass() withPrivateData: self];
	[self.jsWrapper addGlobalObject:@"pageload" ofClass: PageLoadClass() withPrivateData: self];


		/* load the startup script and the pageload script using the
		-loadResourceJavaScript: method from the NSTextView category
		defined in NSTextViewExtras.h/m */
	[self.startupScriptText loadResourceJavaScript:@"startup"];
	[self.pageloadScriptText loadResourceJavaScript:@"pageload"];

		
		/* Run the startup script.  use the performSelector:withObject:afterDelay: so that the
		script will run in the next event cycle after the nib loading process has finished.
		this will allow proper window re-ordering in case the startup JavaScript opens any
		windows. */
	[self performSelector:@selector(runStartupScript) withObject:self afterDelay:0];
}



	/* a separate method for running the startup script.  We call this method from the
	-awakeFromNib method using performSelector:withObject:afterDelay: to ensure that it
	happens on the very next event cycle after nib initialization is complete. This allows
	JavaScripts to open separate windows. */
- (void)runStartupScript {

		/* evaluate the script */
	NSString *result = [self.jsWrapper evaluateJavaScript: [[self.startupScriptText textStorage] string]];
		/* if we received a result... */
	if ( result != nil ) {
	
			/* call javascript to display the result in the console log */
		[self appendMessageToConsole:
			[NSString stringWithFormat:@"startup result: %@", result]];
	}
}



	/* utility method for adding some text to the console text field in the
	console window. */
-(void)appendMessageToConsole:(NSString *)theMessage {
    if ( theMessage != NULL ) {
		NSUInteger p = [[[self.consoleText textStorage] string] length];
		[self.consoleText setSelectedRange:NSMakeRange(p, p)];
		[self.consoleText insertText: theMessage];
		[self.consoleText insertText: @"\n"];
	}
}



	/* NSApplication delegate methods */

	/* So the sample will automatically quit after the main window is closed.  */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}



	/* NSWindow delegate methods */

	/* quit when the main window is closed.  */
- (void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate: self];
}




	/* WebUIDelegate delegate methods for the main WebView. */

	/* -webView:setStatusText: is called when a javascript in the page
	being displayed in the WebView sets the window status message.
	Usually, a script like: window.status = 'message'
	
	In in the startup.js JavaScript, the message() function is defined as follows:
	
		function message( theMessage ) {
			console.log( "setting window message to '" + theMessage + "'" )
			browser.message = theMessage
		}
		
	- it prints a message in the console indicating the command and then
	it sets the message property on the browser object.
	*/
- (void)webView:(WebView *)sender setStatusText:(NSString *)text {

		/* call the message function in the startup JavaScript */
	[self.jsWrapper callJSFunction: @"message" withParameters: text, nil];
}



	/* -webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame: is
	called when a javascript in the page being displayed calls
	the JavaScript alert function.  Rather than displaying an alert box
	here, we call the displayalert() function in the startup JavaScript
	and that script, in turn, calls our built in messagebox function that
	we have defined in our runtime JavaScript context.	
	
	In in the startup.js JavaScript, the displayalert() function is defined as follows:
	
		function displayalert( alertMessage ) {
			console.show();
			console.log( "displaying alert message '" + alertMessage + "'" )
			messagebox( "in page alert: ", alertMessage );
		}
		
	- it calls the show() method on the console object to display the console
	window, writes the alert message in the console log, and then calls
	the custom messagebox() function to display the message on the screen.
	*/
- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message
					initiatedByFrame:(WebFrame *)frame {

		/* call the displayalert function in the startup JavaScript */
	[self.jsWrapper callJSFunction: @"displayalert" withParameters: message, nil];
}



			
	/* -webView:mouseDidMoveOverElement:modifierFlags: is called when the mouse
	moves over an element.  In this method, we query the element that the mouse
	has rolled over to see if it has a link url associated with it.  If the link
	url has changed since the last time we were called, then we call the mouseover()
	function defined in the startup JavaScript.  We call the mouseover() function with an
	empty string to let it know when the mouse has moved away from an item with a link url
	associated with it.
	
	In in the startup.js JavaScript, the mouseover() function is defined as follows:
	
		function mouseover( theURL ) {
			console.log("mouse rolled over '" + theURL + "'")
			browser.eval("window.status = '" + theURL + "'")
		}
		
	- it adds a message to the console log recording the roll over message
	and then it asks the browser to evaluate a JavaScript in the context of
	the current web page that will update the window's status message.  Of course,
	that script will in turn call our -webView:setStatusText: method defined
	above to set the status message (as you can see, this shows JavaScriptCore
	deals well with re-entrancy).
	*/
- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation
			modifierFlags:(NSUInteger)modifierFlags {
			
		/* get the url under the mouse.  for no url, use the empty string. */
	NSString *urlUnderTheMouse = [[elementInformation objectForKey:WebElementLinkURLKey] absoluteString];
	
		/* convert nil values to empty strings - our logic uses strings. */
	if ( urlUnderTheMouse == nil ) urlUnderTheMouse = @"";
	if ( self.mouseOverURL == nil ) self.mouseOverURL = @"";
	
		/* if the url under the mouse has changed... */
	if ( ! [urlUnderTheMouse isEqual: self.mouseOverURL] ) {
			
			/* call the mouseover function in the startup JavaScript */
		[self.jsWrapper callJSFunction: @"mouseover" withParameters: urlUnderTheMouse, nil];
		
			/* update the internal copy of the url of the link under the mouse. */
		self.mouseOverURL = urlUnderTheMouse;
	}
}



	/* WebFrameLoadDelegate delegate methods for the main WebView. */

	/* -webView:didReceiveTitle:forFrame: is called as the page is
	being loaded at the time when WebKit has determined what the
	page's title is.  If the call is for the main frame, then we
	call the title() function in the startup JavaScript to announce
	the page title.
	
	In in the startup.js JavaScript, the title() function is defined as follows:
	
		function title( theTitle ) {
			console.log( "setting window title to '" + theTitle + "'" )
			browser.title = theTitle
		}
		
	- it adds a message to the console log recording the new title and then sets
	the title property of the browser object to the new title (this sets the title
	of the browser window).
	*/
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {

		/* if we're loading the main frame... */
	if ( [self.theWebView mainFrame] == frame ) {
	
			/* call the title function in the startup JavaScript */
		[self.jsWrapper callJSFunction: @"title" withParameters: title, nil];
	}
}



	/* -webView:didFailProvisionalLoadWithError:forFrame: is called when a
	provisional load fails for a request.  Name lookups usually fail here and
	other errors that occur while preparing for a transmission are reported here.	
	
	In in the startup.js JavaScript, the error() function is defined as follows:
	
		function error( errorMessage ) {
			console.log( "error while loading page: '" + errorMessage + "'" )
		}
		
	- it adds a message to the console log recording the error
	*/
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error
			forFrame:(WebFrame *)frame {

		/* call the error function in the startup JavaScript. */
	[self.jsWrapper callJSFunction: @"error" withParameters:
				[NSString stringWithFormat: @"provisional error: %@", error], nil];
}



	/* -webView:didFailLoadWithError:forFrame: is called when a load fails for a
	request.  Communication errors that occur during transmission are reported here.	
	
	In in the startup.js JavaScript, the error() function is defined as follows:
	
		function error( errorMessage ) {
			console.log( "error while loading page: '" + errorMessage + "'" )
		}
		
	- it adds a message to the console log recording the error
	*/
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {

		/* call the error function in the startup JavaScript. */
	[self.jsWrapper callJSFunction: @"error" withParameters:
				[NSString stringWithFormat: @"error: %@", error], nil];
}



	/* -webView:windowScriptObjectAvailable: is called when the page has been
	loaded and the JavaScript context is ready.  Here we add in the same
	properties and objects we added to the main Controller's JavaScript
	context and then we evaluate the pageload.js script in the
	WebView's JavaScript context.  Rather than loading the pageload.js
	file every time, we simply use the contents of the page load window.
	This allows for tinkering with the script while the program is running. */
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {

		/* allocate a wrapper object for the web page's JavaScript context. */
	JSWrappers *localWrapper = [[[JSWrappers alloc]
			initWithContext:[[webView mainFrame] globalContext]] autorelease];

		/* add a global property for the program version read from the info-plist */
	[localWrapper addGlobalStringProperty:@"version" withValue:
		[[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString*) kCFBundleVersionKey]];
	[localWrapper addGlobalStringProperty:@"program" withValue:
		[[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString*) kCFBundleNameKey]];

		/* add the console object for accessing the console window. */
	[localWrapper addGlobalObject:@"console" ofClass: ConsoleClass() withPrivateData: self];
	[localWrapper addGlobalObject:@"startup" ofClass: StartupClass() withPrivateData: self];
	[localWrapper addGlobalObject:@"browser" ofClass: BrowserClass() withPrivateData: self];
	[localWrapper addGlobalObject:@"pageload" ofClass: PageLoadClass() withPrivateData: self];
	
		/* run the page load script */
	[windowScriptObject evaluateWebScript: [[self.pageloadScriptText textStorage] string]];
}



	/* WebResourceLoadDelegate delegate method for the main WebView. */

	/* -webView:resource:willSendRequest:redirectResponse:fromDataSource: is 
	called just before WebKit starts loading a new URL.  We take this opportunity to
	reset some of our state variables and notify the startup JavaScript that a new
	page is loading by calling the loading() function defined in the startup script.
	
	In in the startup.js JavaScript, the loading() function is defined as follows:
	
		function loading( theURL ) {
			browser.progress = true
			console.log("loading url '" + theURL + "'")
			browser.url = theURL
		}
		
	- it turns on the progress bar in the browser window, adds a note to the console
	log about the new load operation, and sets the browser's url text field to the 
	url that is being loaded.
	*/
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier
			willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
			fromDataSource:(WebDataSource *)dataSource {
	
		/* if we are not currently loading a web page... */
	if ( self.urlOfLoadingPage == nil ) {
	
			/* reset the mouseover url */
		self.mouseOverURL = nil;
	
			/* save a copy of the page's url */
		self.urlOfLoadingPage = [[request URL] absoluteString];
		
			/* set the loading flag */
		self.isLoadingPage = YES;
		
			/* call through to the loading function in the startup JavaScript
			to let the custom script know that a new web page is being loaded. */
		[self.jsWrapper callJSFunction: @"loading" withParameters: self.urlOfLoadingPage, nil];

	}
		/* return the request */
	return request;
}



	/* WebPolicyDelegate delegate method for the main WebView. */

	/* -webView:decidePolicyForNavigationAction:request:frame:decisionListener: is
	called before webkit begins processing to allow the application to decide
	if the url should be loaded or not.  Here, we ask the filter() function defined
	in the startup JavaScript if we should load the url and then we act on that
	result.
	
	In in the startup.js JavaScript, the filter() function is defined as follows:
	
		function filter( theURL ) {
			if ( theURL.match(/http:\/\/[a-z0-9_]+\.apple\.com/i) ) {
				console.log( "url OK: " + theURL )
				return false
			} else {
				console.show();
				console.log( "url filtered: " + theURL + " - can't go there" )
				console.log( "NOTE: filtering all non apple.com urls" )
				return true
			}
		}
		
	- this filter function allows urls that match a particular regular expression to
	to load, while displaying a message in the console for urls that do not match
	the regular expression.
	*/
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
			request:(NSURLRequest *)request frame:(WebFrame *)frame
			decisionListener:(id<WebPolicyDecisionListener>)listener {
												  
	if ( [self.jsWrapper callBooleanJSFunction: @"filter"
				withParameters: [[request URL] absoluteString], nil] ) {
		[listener ignore];
	} else {
		[listener use];
	}
}



	/* NSNotification methods related to the WebView */

	/* WebViewProgressFinishedNotification method for the main WebView.  
	-webLoadComplete: is called whenever a web page load finishes.
	Here, we update some of our internal state variables and then
	we call the complete() function in the startup JavaScript
	to notify it about the finished page load.
	
	In in the startup.js JavaScript, the complete() function is
	defined as follows:
	
		function complete( theURL ) {
			console.log("finished loading url '" + theURL + "'")
			browser.eval("ShowPageInfoInConsole()")
			browser.progress = false
		}
		
	- it puts a note in the console log, asks the browser object to
	evaluate a JavaScript in WebView's JavaScript context, and turns
	off the progress indicator in the browser window.  You will notice
	that the script calls the ShowPageInfoInConsole() function that was
	installed in our pageload.js JavaScript that was run when
	-webView:windowScriptObjectAvailable: (defined above) was called
	while the page was being loaded.
	
	In in the pageload.js JavaScript, the ShowPageInfoInConsole() function
	is defined as follows:
	
		function ShowPageInfoInConsole() {

			console.log( "this page contains: "
				+ window.document.anchors.length + " anchors, "
				+ window.document.images.length + " images, and "
				+ window.document.links.length + " links." )
				
			console.log( "the document url is: " + window.document.URL )
			
			console.log( "the document title is: " + window.document.title )

		}
		
	- it prints some basic information about the web page to the console log.
	*/
- (void)webLoadComplete:(NSNotification *)aNotification {
			
		/* we're done, so stop loading */
	[self.theWebView stopLoading:self];
	
		/* reset the flag */
	NSString *urlThatWasLoading = self.urlOfLoadingPage;
	
		/* reset the loading state vars */
	self.urlOfLoadingPage = nil;
	self.isLoadingPage = NO;
	
		/* adjust the back and forward buttons */
	[self.goForward setEnabled: ([[self.theWebView backForwardList] forwardItem ] ? YES : NO)];
	[self.goBack setEnabled: ([[self.theWebView backForwardList] backItem ] ? YES : NO)];

		/* tell JavaScript that the load is complete */
	[self.jsWrapper callJSFunction: @"complete" withParameters: urlThatWasLoading, nil];
}




	/* Interface Builder Action methods. */

	/* -goBackAction: is called when the user clicks on the back button
	in the browser window.  Here, if there is an item to go back to
	in the browser's history, then we call the back() function in the
	startup JavaScript.
	
	In in the startup.js JavaScript, the back() function is defined as follows:
	
		function back( theURL, theTitle ) {
			console.log( "going back to " + browser.backlink
							+ " (" + theTitle + ")" )
			browser.back()
		}
		
	- it prints a message in the console indicating the command and then
	it calls the back method on the browser object.
	*/
- (IBAction)goBackAction:(id)sender {
	WebHistoryItem *backItem = [[self.theWebView backForwardList] backItem];
	if ( backItem != nil ) {
		[self.jsWrapper callJSFunction: @"back" 
			withParameters: [backItem URLString], [backItem title], nil];
	}
}



	/* -goForwardAction: is called when the user clicks on the forward
	button in the browser window.  Here, if there is an item to go
	forward to in the browser's history, then we call the forward()
	function in the startup JavaScript.
	
	In in the startup.js JavaScript, the forward() function is defined as follows:
	
		function forward( theURL, theTitle ) {
			console.log( "going forward to " + browser.forwardlink
							+ " (" + theTitle + ")" )
			browser.forward()
		}
		
	- it prints a message in the console indicating the command and then
	it calls the forward method on the browser object.
	*/
- (IBAction)goForwardAction:(id)sender {
	WebHistoryItem *forwardItem = [[self.theWebView backForwardList] forwardItem ];
	if ( forwardItem != nil ) {
		[self.jsWrapper callJSFunction: @"forward" 
			withParameters: [forwardItem URLString], [forwardItem title], nil];
	}
}



	/* -goToAction: is called when the user clicks on the Go! button
	in the browser window.  Here, we call the goto() function in the
	startup JavaScript.
	
	In in the startup.js JavaScript, the goto() function is defined as follows:
	
		function goto( theURL ) {
			console.log("request for " + theURL + " received")
			if ( theURL.match( /http:\/\//i ) ) {
				browser.load( theURL )
			} else {
				console.log( "fixup url as: http://" + theURL)
				browser.load( "http://" + theURL )
				
			}
		}
		
	- it prints a message in the console indicating the command and then
	checks the url to make sure that it has a http:// prefix at the beginning.
	If there is no prefix, if adds one and makes a note in the console log
	about that.  Then, it asks the browser object to load the url by calling
	it's load() method.
	*/
- (IBAction)goToAction:(id)sender {
	[self.jsWrapper callJSFunction: @"goto" 
		withParameters: [self.theURL stringValue], nil];
}




	/* -reloadAction: is called when the user clicks on the reload button
	in the browser window.  Here, we call the reload() function in the
	startup JavaScript.
	
	In in the startup.js JavaScript, the reload() function is defined as follows:
	
		function reload() {
			browser.load( browser.url )
		}
		
	- it asks the browser object to load whatever url is being displayed in
	the url field in the browser window.
	*/
- (IBAction)reloadAction:(id)sender {
	[self.jsWrapper callJSFunction: @"reload" 
		withParameters: [self.theURL stringValue], nil];
}



	/* -openConsoleWindowAction: is called when the user clicks on the show
	console button in the browser window or selects the Console... command
	in the file menu.   Here, we call the openconsole() function in the
	startup JavaScript.  The console window allows the user to view and
	edit the console log and run small JavaScripts.
	
	In in the startup.js JavaScript, the openconsole() function is defined as follows:
	
		function openconsole() {
			console.show()
		}
		
	- it asks the console object to show the console window by calling its
	show() method.
	*/
- (IBAction)openConsoleWindowAction:(id)sender {
	[self.jsWrapper callJSFunction: @"openconsole" withParameters: nil];
}



	/* -openPageLoadWindowAction: is called when the user clicks on the show page
	load button in the browser window or selects the Page Load... command
	in the file menu.   Here, we call the openpageload() function in the
	startup JavaScript.  The pageLoad window allows the user to view and
	edit the pageload.js JavaScript.
	
	In in the startup.js JavaScript, the openpageload() function is defined as follows:
	
		function openpageload() {
			pageload.show()
		}
		
	- it asks the pageload object to show its associated window by calling its
	show() method.  The pageload script is evaluated in the WebView's JavaScript
	context, not the main Controller's JavaScript context.
	*/
- (IBAction)openPageLoadWindowAction:(id)sender {
	[self.jsWrapper callJSFunction: @"openpageload" withParameters: nil];
}



	/* -openStartupScriptWindowAction: is called when the user clicks on the show
	startup button in the browser window or selects the Startup... command
	in the file menu.   Here, we call the openstartup() function in the
	startup JavaScript.  The startup window allows the user to view, edit,
	and re-evaluate the startup.js JavaScript.
	
	In in the startup.js JavaScript, the openstartup() function is defined as follows:
	
		function openstartup() {
			startup.show()
		}
		
	- it asks the startup object to show its associated window by calling its
	show() method.  
	*/
- (IBAction)openStartupScriptWindowAction:(id)sender {
	[self.jsWrapper callJSFunction: @"openstartup" withParameters: nil];
}



	/* -evaluateConsoleScriptAction: is called when the user clicks on the Run Script
	button in the console window.   Here, we call the evalconsole()
	function in the startup JavaScript.
		
	In in the startup.js JavaScript, the evalconsole() function is defined as follows:
	
		function evalconsole() {
			console.log( "script result = ", console.eval( console.script ) )
		}
		
	- it asks the console object to evaluate the contents of the script field
	in the console window and then prints the result in the console log.  The script
	is evaluated in the Controller's JavaScript context, not the WebView's
	JavaScript context.
	*/
- (IBAction)evaluateConsoleScriptAction:(id)sender {
	[self.jsWrapper callJSFunction: @"evalconsole" withParameters: nil];
}



	/* -evaluateStartupScriptAction: is called when the user clicks on
	the re-evaluate button in the startup script window.   Here, we call
	the reevalstartup() function in the startup JavaScript.
		
	In in the startup.js JavaScript, the reevalstartup() function is defined as follows:
	
		function reevalstartup() {
			console.log( "startup script result = ", console.eval( startup.script ) )
		}
		
	- it asks the console object to evaluate the contents of the script field
	in the startup window and then prints the result in the console log.  The script
	will be evaluated in the Controller's JavaScript context, not the WebView's
	JavaScript context.
	*/
- (IBAction)evaluateStartupScriptAction:(id)sender {
	[self.jsWrapper callJSFunction: @"reevalstartup" withParameters: nil];
}



@end

