/*

File: startup.js

Abstract:  startup script.  This script is run 
in the main Controller's JavaScript context when the program starts
up (and again if the user chooses to re-evaluate the script).  JavaScript
functions defined in this file are called as a part of processing different
actions in the program and they can be customized as needed.

In most Applications, the controller decides what the application
will do.  In this app, the controller is just a thin shell that
calls functions defined in this JavaScript and those functions
tell the application what to do.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

	/* called when the program begins loading a url
	in the browser window.  Here, we turn on the progress bar,
	add a message to the console log, and set the url text
	in the main window. */
function loading( theURL ) {

		 /* display the progress bar */
	browser.progress = true
	
		/* add a message to the console window */
	console.log("loading url '" + theURL + "'")
	
		/* set the url text field to the new url */
	browser.url = theURL
}



	/* called when the program has finished loading
	a specific url.  Here, we add a message to the console
	and turn off the progress bar. */
function complete( theURL ) {

		/* add a note to console */
	console.log("finished loading url '" + theURL + "'")
	
		/* call our ShowPageInfoInConsole() function that we installed
		in the web page's context in our pageload.js JavaScript. */
	browser.eval("ShowPageInfoInConsole()")
	
		/* hide the progress bar */
	browser.progress = false
}



	/* called when the mouse rolls over a link in the browser
	window. */
function mouseover( theURL ) {

		/* add a note to console */
	console.log("mouse rolled over '" + theURL + "'")
	
	browser.eval("window.status = '" + theURL + "'")
}



	/* called during a page load to inform us of the title of the
	page being loaded.  Here, we set the browser window's title and
	record the title in the console log. */
function title( theTitle ) {
		
		/* note the title change in the console */
	console.log( "setting window title to '" + theTitle + "'" )
	
		/* change the window's title. */
	browser.title = theTitle
}



	/* called if any errors happen while a page is being loaded.
	We don't stop for errors, but we record them in the console
	log. */
function error( errorMessage ) {

		/* note the error in the console log */
	console.log( "error while loading page: '" + errorMessage + "'" )
}



	/* this url filter function is called before any url is loaded into
	the browser window.  In this function we use the regular expression
	pattern matching on the built in String class to filter out any urls
	that do not match a particular pattern. */
function filter( theURL ) {

		/* test the url with our pattern */
	if ( theURL.match(/http:\/\/[a-z0-9_]+\.apple\.com/i) ) {
	
			/* note the accepted url in the console.log */
		console.log( "url OK: " + theURL )
		
			/* return "false" meaning "don't filter out this url" */
		return false
		
	} else {
	
			/* the url failed to match our pattern, so we're going
			to filter it out.  Before we do, we'll make sure the console
			is visible and we'll type an explanation there. */
		console.show();
		console.log( "url filtered: " + theURL + " - can't go there" )
		console.log( "NOTE: filtering all non apple.com urls" )
		
			/* return "true" meaning "filter this url" */
		return true
	}
}



	/* called when the web page being loaded into the browser
	window attempts to set the browser's message field.  Usually,
	this would be a JavaScript in the page attempting to set the
	window.message field.  In this function, we set the message field
	and record the call in the console log. */
function message( theMessage ) {
		
		/* make a note of the new message in the console log */
	console.log( "setting window message to '" + theMessage + "'" )
	
		/* set the message - a NSTextField at the bottom of the browser
		window to the right of the progress bar. */ 
	browser.message = theMessage
}



	/* this function is called when a JavaScript in a page being loaded
	in the browser calls the JavaScript alert() function.  Here, we call
	our own custom messagebox function to display the message. */
function displayalert( alertMessage ) {
		
		/* display the console log and make a note of the alert message
		in the console log. */
	console.show();
	console.log( "displaying alert message '" + alertMessage + "'" )
	
		/* display the alert message using our custom messagebox function
		defined in Functions.h/m */
	messagebox( "in page alert: " + alertMessage );
}



	/* called when the back button is clicked in the browser window.
	Here, we record the event in the console log and call the browser
	object's back method. */
function back( theURL, theTitle ) {
		
		/* note the command in the console log */
	console.log( "going back to " + browser.backlink
					+ " (" + theTitle + ")" )
		
		/* call the browser object's back method */
	browser.back()
}



	/* called when the forward button is clicked in the browser window.
	Here, we record the event in the console log and call the browser
	object's forward method. */
function forward( theURL, theTitle ) {

		/* note the command in the console log */
	console.log( "going forward to " + browser.forwardlink
					+ " (" + theTitle + ")" )
	
		/* call the browser object's forward method */
	browser.forward()
}



	/* called when the go button is clicked in the browser window.
	Here, we record the event in the console log and ask the browser
	to load the url. */
function goto( theURL ) {

		/* note the request in the console log */
	console.log("request for " + theURL + " received")
	
		/* make sure there's a 'http://' at the beginning of the
		url.  This is an added convenience allowing the user to
		simply type the address.  Note, we don't do any additional
		url checking here as we do all of our url filtering
		inside of our filter function */
	if ( theURL.match( /http:\/\//i ) ) {
		browser.load( theURL )
	} else {
		console.log( "fixup url as: http://" + theURL)
		browser.load( "http://" + theURL )
		
	}
}


	/* called when when the reload button is clicked.  Here, we reload
	the page currently displayed in the browser. */
function reload() {
	browser.load( browser.url )
}


	/* called when either the user asks to open the console window
	either by menu command or by clicking the button in the
	bottom of the window. */
function openconsole() {
	console.show()
}



	/* called when either the user asks to open the page load window
	either by menu command or by clicking the button in the
	bottom of the window. */
function openpageload() {
	pageload.show()
}



	/* called when either the user asks to open the startup script window
	either by menu command or by clicking the button in the
	bottom of the window. */
function openstartup() {
	startup.show()
}



	/* called when the Run Script button is clicked in the console
	window.  Here, we evaluate the contents of the console's script
	field and then we add the result to the console log. */
function evalconsole() {
	console.log( "script result = " + console.eval( console.script ) )
}



	/* called when the re-evaluate button is clicked in the startup script
	window.  Here, we evaluate the contents of the startup script window
	and then we add the result to the console log. */
function reevalstartup() {
	console.log( "startup script result = " + console.eval( startup.script ) )
}


	/* final startup sequence.  This JavaScript runs at startup so after
	setting up our various handlers we can instruct the program to do
	whatever we require.  In this sample, display a welcome message
	in the console window and load the developer website.  */
	
	/* print a welcome message in the console window. */
console.show()
console.text = "" /* clear the console */
console.log( "Welcome to " + program + " " + version )

	/* start loading the ADC website. */
goto( "developer.apple.com" )




