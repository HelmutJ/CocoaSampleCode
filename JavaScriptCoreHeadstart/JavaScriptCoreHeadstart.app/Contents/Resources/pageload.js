/*

File: pageload.js

Abstract: pageload script.  This script is run in the WebView's JavaScript
context every time a new web page is loaded into the browser window.  It
is run at a time during the loading process when it is safe to add
additional JavaScript definitions to the page's JavaScript context
but before any scripts contained in the page start to run.  This
is a good time to add in your own functions that you would like to
run in the page after it is fully loaded.

As in the startup script, the console, startup, pageload, and browser
objects have already been added to the context so you can use those
objects in the scripts in this file.

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


	/* add some functions to the page that we can call */

	/* define a function to display some informaiton about the page
	in the console window. */
function ShowPageInfoInConsole() {

	console.log( "this page contains: "
		+ window.document.anchors.length + " anchors, "
		+ window.document.images.length + " images, and "
		+ window.document.links.length + " links." )
		
	console.log( "the document url is: " + window.document.URL )
	
	console.log( "the document title is: " + window.document.title )

}




	/* final page load sequence.  This JavaScript runs at as we're loading
	a page.  In this sample we put a message in the console so we can
	tell that the page load completed.  Later, when we receive a notification
	that the page has finished loading (in the complete() function
	defined in the startup.js script), we call the ShowPageInfoInConsole()
	function defined above to display some information about the page using
	the browser.eval() method.  */
	
	
	/* print a welcome message in the console window. */
console.log("page load for " + program + " " + version)


